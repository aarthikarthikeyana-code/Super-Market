from django.core.management.base import BaseCommand
from api.commerce import expire_pending_orders

class Command(BaseCommand):
    help = 'Release stock reserved by unpaid checkouts older than 30 minutes.'
    def handle(self, *args, **options):
        expire_pending_orders()
        self.stdout.write('Expired checkout reservations processed.')
