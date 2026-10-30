from django.urls import path
from . import views

urlpatterns = [
    # Customer APIs
    path('products/', views.get_products, name='get_products'),
    path('products/<str:pk>/', views.get_product_detail, name='get_product_detail'),
    path('orders/', views.create_customer_order, name='create_customer_order'),
    path('orders/<str:order_id>/track/', views.track_order, name='track_order'),
    path('requests/', views.submit_new_item_request, name='submit_new_item_request'),

    # Admin APIs
    path('admin/login/', views.admin_login, name='admin_login'),
    path('admin/dashboard/', views.admin_dashboard, name='admin_dashboard'),
    path('admin/orders/', views.admin_orders_list, name='admin_orders_list'),
    path('admin/orders/<str:order_id>/', views.admin_order_detail, name='admin_order_detail'),
    path('admin/orders/<str:order_id>/pack/', views.admin_pack_order, name='admin_pack_order'),
    path('admin/orders/<str:order_id>/assign/', views.admin_assign_delivery, name='admin_assign_delivery'),
    path('admin/orders/<str:order_id>/dispatch/', views.admin_dispatch_order, name='admin_dispatch_order'),
    path('admin/stock/', views.admin_stock_management, name='admin_stock_management'),
    path('admin/requests/', views.admin_new_item_requests, name='admin_new_item_requests'),
    path('admin/delivery-personnel/', views.admin_delivery_personnel, name='admin_delivery_personnel'),
    path('admin/reports/', views.admin_reports, name='admin_reports'),
]
