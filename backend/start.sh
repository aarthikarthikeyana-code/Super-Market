#!/usr/bin/env bash
set -o errexit
python manage.py migrate --noinput
python manage.py bootstrap_admin
exec gunicorn supermarket_backend.wsgi:application --bind "0.0.0.0:${PORT:-8000}" --workers 2 --timeout 120 --access-logfile -
