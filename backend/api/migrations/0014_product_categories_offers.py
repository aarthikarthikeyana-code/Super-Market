from django.db import migrations, models
from django.db.models import F


def prepare_catalog(apps, schema_editor):
    alias = schema_editor.connection.alias
    Category = apps.get_model('api', 'ProductCategory')
    names = ['Rice', 'Grains', 'Atta', 'Flours', 'Dals', 'Pulses', 'Cooking Oil',
             'Ghee', 'Sugar', 'Salt', 'Spices', 'Masalas', 'Tea', 'Coffee',
             'Biscuits', 'Cookies', 'Snacks', 'Noodles', 'Dairy Products', 'Chocolates']
    for position, name in enumerate(names):
        Category.objects.using(alias).get_or_create(name=name, defaults={'position': position})
    Product = apps.get_model('api', 'Product')
    for name in Product.objects.using(alias).exclude(category='').values_list('category', flat=True).distinct():
        Category.objects.using(alias).get_or_create(name=name)
    Product.objects.using(alias).update(base_price=F('price'))
    last = 0
    for sku in Product.objects.using(alias).values_list('sku', flat=True):
        if sku.startswith('agmp') and sku[4:].isdigit():
            last = max(last, int(sku[4:]))
    apps.get_model('api', 'ProductCodeSequence').objects.using(alias).get_or_create(pk=1, defaults={'last_number': last})


class Migration(migrations.Migration):
    dependencies = [('api', '0013_structured_delivery_address')]
    operations = [
        migrations.CreateModel(name='ProductCategory', fields=[
            ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
            ('name', models.CharField(max_length=60, unique=True)),
            ('position', models.PositiveIntegerField(default=100)),
        ], options={'ordering': ['position', 'id']}),
        migrations.CreateModel(name='ProductCodeSequence', fields=[
            ('id', models.PositiveSmallIntegerField(default=1, primary_key=True, serialize=False)),
            ('last_number', models.PositiveIntegerField(default=0)),
        ]),
        migrations.AddField(model_name='product', name='base_price', field=models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True)),
        migrations.AddField(model_name='product', name='offer_percent', field=models.DecimalField(decimal_places=2, default=0, max_digits=5)),
        migrations.RunPython(prepare_catalog, migrations.RunPython.noop),
    ]
