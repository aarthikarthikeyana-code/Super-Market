from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('api', '0012_deliverylocation_order_delivery_code_attempts_and_more')]
    operations = [
        migrations.AddField(model_name='customerprofile', name='address_details', field=models.JSONField(default=dict, blank=True)),
        migrations.AddField(model_name='order', name='address_details', field=models.JSONField(default=dict, blank=True)),
    ]
