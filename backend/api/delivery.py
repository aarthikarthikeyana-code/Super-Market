"""Customer-only delivery codes and authenticated, trip-scoped location updates."""
import secrets
import uuid
from datetime import timedelta

from django.db import transaction
from django.utils import timezone
from django.utils.crypto import salted_hmac
from rest_framework import serializers
from rest_framework.exceptions import ValidationError

from .models import DeliveryLocation, Order


class InvalidDeliveryCode(ValidationError):
    """Committed failed-attempt counter; no order or cash transition is committed."""


def issue_code(order):
    order.delivery_code_nonce = uuid.uuid4()
    order.delivery_code_expires_at = timezone.now() + timedelta(hours=24)
    order.delivery_code_attempts = 0
    order.delivery_code_verified_at = None


def code_value(order):
    digest = salted_hmac('agaram.delivery.v1', f'{order.pk}:{order.delivery_code_nonce}', algorithm='sha256').hexdigest()
    return str(10000 + int(digest, 16) % 90000)


def customer_confirmation(order):
    active = (order.status in ['New', 'Preparing', 'Packed', 'Out for Delivery', 'Delivery Attempted'] and order.delivery_code_nonce
              and order.delivery_code_expires_at and order.delivery_code_expires_at > timezone.now()
              and order.delivery_code_attempts < 5 and not order.delivery_code_verified_at)
    return {'code': code_value(order) if active else None,
            'expires_at': order.delivery_code_expires_at if active else None,
            'can_refresh': order.status in ['New', 'Preparing', 'Packed', 'Out for Delivery', 'Delivery Attempted'] and not active,
            'message': 'Share only after receiving your groceries and paying the cash due.'}


def verify_code(order, supplied):
    if order.status != 'Out for Delivery':
        raise ValidationError({'delivery_code': 'Start the assigned delivery before verifying the customer code.'})
    if not customer_confirmation(order)['code']:
        raise ValidationError({'delivery_code': 'Ask the customer to refresh their delivery code in their order screen.'})
    if not isinstance(supplied, str) or not secrets.compare_digest(code_value(order), supplied.strip()):
        order.delivery_code_attempts += 1
        order.save(update_fields=['delivery_code_attempts'])
        remaining = max(0, 5 - order.delivery_code_attempts)
        raise InvalidDeliveryCode({'delivery_code': f'Incorrect delivery code. {remaining} attempts remaining. Ask the customer to check their order screen.'})


class LocationInput(serializers.Serializer):
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6, min_value=-90, max_value=90)
    longitude = serializers.DecimalField(max_digits=10, decimal_places=6, min_value=-180, max_value=180)
    accuracy = serializers.FloatField(min_value=0, max_value=1000)
    captured_at = serializers.DateTimeField()

    def validate_accuracy(self, value):
        import math
        if not math.isfinite(value):
            raise ValidationError('Use a finite GPS accuracy value.')
        return value

    def validate_captured_at(self, value):
        age = (timezone.now() - value).total_seconds()
        if age < -15 or age > 120:
            raise ValidationError('Send a fresh device location, no older than two minutes.')
        return value


@transaction.atomic
def record_location(order_id, user, data):
    order = Order.objects.select_for_update().select_related('assigned_to__user').get(order_id=order_id)
    person = order.assigned_to
    if (order.status != 'Out for Delivery' or not person or person.user_id != user.pk
            or not person.ready_for_deliveries):
        raise ValidationError({'detail': 'Location can only be shared for your active, assigned delivery.'})
    if order.dispatched_at and data['captured_at'] < order.dispatched_at:
        raise ValidationError({'captured_at': 'Send a GPS fix captured after this delivery started.'})
    last = order.locations.order_by('-captured_at', '-pk').first()
    if last and data['captured_at'] <= last.captured_at:
        return
    if last and (data['captured_at'] - last.captured_at).total_seconds() < 5:
        return
    DeliveryLocation.objects.create(order=order, employee=person, **data)
    # Bound per-order storage while retaining the original pickup fix.
    first = order.locations.order_by('captured_at', 'pk').first()
    cutoff = list(order.locations.order_by('-captured_at', '-pk').values_list('pk', flat=True)[999:1000])
    if cutoff:
        order.locations.filter(pk__lt=cutoff[0]).exclude(pk=first.pk).delete()


def tracking_payload(order, *, customer=False):
    if order.status != 'Out for Delivery':
        return {'points': [], 'active': False, 'stale': True}
    points = order.locations.filter(employee_id=order.assigned_to_id)
    # Hide an old trip after reassignment or a delivery retry.
    if order.dispatched_at:
        points = points.filter(captured_at__gte=order.dispatched_at)
    first = points.order_by('captured_at', 'pk').first()
    recent = list(points.order_by('-captured_at', '-pk')[:299])
    recent.reverse()
    if first and (not recent or first.pk != recent[0].pk):
        recent.insert(0, first)
    last = recent[-1] if recent else None
    return {'active': order.status == 'Out for Delivery',
            'destination': {key: order.address_details[key] for key in ['latitude', 'longitude'] if key in order.address_details},
            'stale': not last or (timezone.now() - last.captured_at).total_seconds() > 30,
            'points': [{'latitude': str(p.latitude), 'longitude': str(p.longitude),
                        'accuracy': p.accuracy, 'captured_at': p.captured_at} for p in recent]}
