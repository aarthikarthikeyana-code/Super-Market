import requests
from django.conf import settings
from .errors import ServiceUnavailable


def razorpay_request(method, path, data=None):
    if not settings.PAYMENT_GATEWAY_ENABLED or not settings.RAZORPAY_KEY_ID or not settings.RAZORPAY_KEY_SECRET:
        raise ServiceUnavailable('Online payments are currently unavailable. Choose cash on delivery or try later.')
    try:
        response = requests.request(
            method, 'https://api.razorpay.com/v1/' + path,
            auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET), json=data, timeout=(5, 20),
        )
        response.raise_for_status()
        return response.json()
    except (requests.RequestException, ValueError):
        raise ServiceUnavailable('Payment provider is unavailable. No payment has been confirmed. Please retry.') from None


def upload_image(file):
    import cloudinary
    import cloudinary.uploader
    from PIL import Image, UnidentifiedImageError
    from rest_framework.exceptions import ValidationError
    if file.size > 8 * 1024 * 1024:
        raise ValidationError({'image': 'Choose an image smaller than 8 MB.'})
    try:
        image = Image.open(file)
        if image.format not in ['JPEG', 'PNG', 'WEBP'] or image.width * image.height > 25_000_000:
            raise ValidationError({'image': 'Use a JPEG, PNG or WebP photo, up to 25 megapixels.'})
        image.verify()
        file.seek(0)
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError):
        raise ValidationError({'image': 'This file is not a valid product photo.'}) from None
    if not all([settings.CLOUDINARY_CLOUD_NAME, settings.CLOUDINARY_API_KEY, settings.CLOUDINARY_API_SECRET]):
        raise ServiceUnavailable('Product photo storage is not configured.')
    cloudinary.config(cloud_name=settings.CLOUDINARY_CLOUD_NAME, api_key=settings.CLOUDINARY_API_KEY,
                      api_secret=settings.CLOUDINARY_API_SECRET, secure=True)
    try:
        return cloudinary.uploader.upload(file, folder='agaram/products', resource_type='image',
                                         unique_filename=True, overwrite=False, allowed_formats=['jpg', 'png', 'webp'])
    except Exception:
        raise ServiceUnavailable('Product photo upload failed. Please try again.') from None
