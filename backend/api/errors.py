import logging
from rest_framework.exceptions import APIException
from rest_framework.views import exception_handler as drf_exception_handler

logger = logging.getLogger(__name__)

class ServiceUnavailable(APIException):
    status_code = 503
    default_detail = 'The service is temporarily unavailable. Please try again.'

def exception_handler(exc, context):
    response = drf_exception_handler(exc, context)
    if response is not None:
        return response
    logger.exception('Unhandled API error', exc_info=exc)
    return None
