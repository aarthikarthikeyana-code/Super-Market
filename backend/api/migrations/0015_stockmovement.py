from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('api', '0014_product_categories_offers'),
    ]

    operations = [
        migrations.CreateModel(
            name='StockMovement',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('delta', models.DecimalField(decimal_places=2, max_digits=12)),
                ('unit', models.CharField(max_length=40)),
                ('movement_type', models.CharField(choices=[('opening', 'Opening stock'), ('restock', 'Stock received'), ('adjustment', 'Stock adjustment'), ('sale', 'Order reserved'), ('return', 'Stock returned')], max_length=16)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('order', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='stock_movements', to='api.order')),
                ('product', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='stock_movements', to='api.product')),
            ],
        ),
        migrations.AddIndex(
            model_name='stockmovement',
            index=models.Index(fields=['movement_type', '-created_at'], name='stock_move_type_date_idx'),
        ),
        migrations.AddIndex(
            model_name='stockmovement',
            index=models.Index(fields=['product', '-created_at'], name='stock_move_product_date_idx'),
        ),
    ]