from datetime import timedelta

from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone

from api.models import DeliveryLocation


class Command(BaseCommand):
    help = 'Delete old GPS fixes from closed delivery trips; default retention is 7 days.'

    def add_arguments(self, parser):
        parser.add_argument('--days', type=int, default=7)
        parser.add_argument('--dry-run', action='store_true')

    def handle(self, *args, **options):
        days = options['days']
        if not 1 <= days <= 30:
            raise CommandError('Choose a retention period between 1 and 30 days.')
        points = DeliveryLocation.objects.filter(
            received_at__lt=timezone.now() - timedelta(days=days),
            order__status__in=['Delivered', 'Cancelled'],
        )
        count = points.count()
        if not options['dry_run']:
            points.delete()
        self.stdout.write(f'{count} old location fixes ' + ('would be removed.' if options['dry_run'] else 'removed.'))
