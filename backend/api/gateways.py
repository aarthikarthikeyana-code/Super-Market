import logging

from django.conf import settings
from .errors import ServiceUnavailable

logger = logging.getLogger(__name__)


def lookup_pincode(pincode):
    import json
    import re
    from urllib.request import Request, urlopen
    from django.core.cache import cache
    from rest_framework.exceptions import ValidationError
    if not re.fullmatch(r'[1-9][0-9]{5}', pincode):
        raise ValidationError({'pincode': 'Enter a valid six-digit Indian PIN code.'})
    key = 'postal-address-v1:' + pincode
    cached = cache.get(key)
    if cached is not None:
        return cached
    try:
        request = Request('https://api.postalpincode.in/pincode/' + pincode, headers={'User-Agent': 'AgaramSupermarket/1.0', 'Accept': 'application/json'})
        with urlopen(request, timeout=6) as response:
            data = json.loads(response.read(1024 * 1024))
        record = data[0]
        offices = record.get('PostOffice') or []
        offices = [office for office in offices if str(office.get('Pincode')) == pincode]
        result = {'pincode': pincode, 'matched': bool(offices), 'district': str(offices[0].get('District') or '') if offices else '',
                  'state': str(offices[0].get('State') or '') if offices else '',
                  'offices': sorted(set(str(office['Name']) for office in offices if office.get('Name')))}
        cache.set(key, result, 86400 if offices else 300)
        return result
    except Exception:
        raise ServiceUnavailable('PIN lookup is temporarily unavailable. Enter your city/town and state manually.') from None


def upload_image(file):
    import cloudinary
    import cloudinary.uploader
    from cloudinary.exceptions import AuthorizationRequired, NotAllowed
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
    except NotAllowed:
        logger.warning('Cloudinary rejected product upload: missing asset create permission.')
        raise ServiceUnavailable(
            'Photo storage denied the upload. The store administrator must enable '
            'asset create/upload permission for the backend Cloudinary API key.'
        ) from None
    except AuthorizationRequired:
        logger.warning('Cloudinary rejected product upload credentials.')
        raise ServiceUnavailable(
            'Photo storage authentication failed. The store administrator must check '
            'the backend Cloudinary cloud name, API key and API secret.'
        ) from None
    except Exception as exc:
        # Cloudinary exception text can contain signed parameters. Do not expose it.
        logger.warning('Cloudinary product upload failed (%s).', type(exc).__name__)
        raise ServiceUnavailable('Product photo upload failed. Please try again.') from None


def _employee_cloud():
    import cloudinary
    if not all([settings.CLOUDINARY_CLOUD_NAME, settings.CLOUDINARY_API_KEY, settings.CLOUDINARY_API_SECRET]):
        raise ServiceUnavailable('Private employee document storage is not configured.')
    cloudinary.config(cloud_name=settings.CLOUDINARY_CLOUD_NAME, api_key=settings.CLOUDINARY_API_KEY,
                      api_secret=settings.CLOUDINARY_API_SECRET, secure=True)


def upload_employee_document(file):
    import uuid
    import cloudinary.uploader
    from PIL import Image, UnidentifiedImageError
    from rest_framework.exceptions import ValidationError
    if file.size > 8 * 1024 * 1024:
        raise ValidationError({'document': 'Use a document photo smaller than 8 MB.'})
    try:
        image = Image.open(file)
        if image.format not in ['JPEG', 'PNG', 'WEBP'] or image.width * image.height > 25_000_000:
            raise ValidationError({'document': 'Use a JPEG, PNG or WebP photo up to 25 megapixels.'})
        image.verify()
        file.seek(0)
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError):
        raise ValidationError({'document': 'Choose a valid document photo.'}) from None
    _employee_cloud()
    try:
        result = cloudinary.uploader.upload(file, public_id='agaram/private-employees/' + uuid.uuid4().hex,
                                            resource_type='image', type='authenticated', overwrite=False, allowed_formats=['jpg', 'png', 'webp'])
        if result.get('type') != 'authenticated':
            raise ValueError('Private storage was not confirmed')
        return result
    except Exception:
        raise ServiceUnavailable('Private document upload failed. Check Cloudinary upload permissions. No public upload is used.') from None


def employee_document_url(document):
    import time
    import cloudinary.utils
    _employee_cloud()
    return cloudinary.utils.private_download_url(document.public_id, document.format, resource_type='image',
                                                 type='authenticated', expires_at=int(time.time()) + 60, attachment=False)


def delete_employee_document(document):
    import cloudinary.uploader
    _employee_cloud()
    try:
        result = cloudinary.uploader.destroy(document.public_id, resource_type='image', type='authenticated', invalidate=True)
        if result.get('result') not in ['ok', 'not found']:
            raise ValueError('Delete was not confirmed')
    except Exception:
        raise ServiceUnavailable('Private document could not be deleted. Please try again.') from None
