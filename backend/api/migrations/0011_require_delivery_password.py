from django.db import migrations


def revoke_previous_delivery_sessions(apps, schema_editor):
    Employee = apps.get_model('api', 'DeliveryPersonnel')
    Token = apps.get_model('authtoken', 'Token')
    database = schema_editor.connection.alias
    users = Employee.objects.using(database).filter(user__is_staff=False, user__is_superuser=False).values_list('user_id', flat=True)
    Token.objects.using(database).filter(user_id__in=users).delete()


class Migration(migrations.Migration):
    dependencies = [
        ('api', '0010_employee_code_sequence'),
        ('authtoken', '0001_initial'),
    ]

    operations = [migrations.RunPython(revoke_previous_delivery_sessions, migrations.RunPython.noop)]
