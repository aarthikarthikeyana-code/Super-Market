import os
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.password_validation import validate_password

class Command(BaseCommand):
    help = 'Create the initial store administrator from backend environment variables.'
    def handle(self, *args, **options):
        email, password = os.getenv('ADMIN_EMAIL', '').strip(), os.getenv('ADMIN_PASSWORD', '')
        if not email or not password:
            raise CommandError('Set ADMIN_EMAIL and ADMIN_PASSWORD in the backend environment.')
        users = get_user_model()
        if users.objects.filter(username=email).exists():
            self.stdout.write('Administrator already exists; password left unchanged.')
            return
        validate_password(password)
        users.objects.create_superuser(username=email, email=email, password=password, first_name='Agaram', last_name='Administrator')
        self.stdout.write(self.style.SUCCESS('Store administrator created.'))
