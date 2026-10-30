import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/numma_theme.dart';
import '../data/models/numma_models.dart';
import 'providers/numma_providers.dart';
import 'screens/screen_01_login.dart';
import 'screens/screen_02_dashboard.dart';
import 'screens/screen_03_products_list.dart';
import 'screens/screen_04_add_product.dart';
import 'screens/screen_05_inventory.dart';
import 'screens/screen_06_orders_list.dart';
import 'screens/screen_07_order_details.dart';
import 'screens/screen_08_categories.dart';
import 'screens/screen_09_brands.dart';
import 'screens/screen_10_customers.dart';
import 'screens/screen_11_reports.dart';
import 'screens/screen_12_delivery.dart';
import 'screens/screen_13_offers.dart';
import 'screens/screen_14_settings.dart';
import 'screens/screen_15_profile.dart';

class NummaAdminFlowShell extends ConsumerStatefulWidget {
  const NummaAdminFlowShell({super.key});

  @override
  ConsumerState<NummaAdminFlowShell> createState() => _NummaAdminFlowShellState();
}

class _NummaAdminFlowShellState extends ConsumerState<NummaAdminFlowShell> {
  NummaOrder? _selectedOrder;

  void _navigateToScreen(int screenNumber) {
    ref.read(nummaStepProvider.notifier).setStep(screenNumber);
    if (screenNumber == 2) {
      ref.read(nummaBottomNavProvider.notifier).setIndex(0);
    } else if (screenNumber == 3) {
      ref.read(nummaBottomNavProvider.notifier).setIndex(1);
    } else if (screenNumber == 6) {
      ref.read(nummaBottomNavProvider.notifier).setIndex(2);
    } else if (screenNumber == 10) {
      ref.read(nummaBottomNavProvider.notifier).setIndex(3);
    } else if (screenNumber == 14) {
      ref.read(nummaBottomNavProvider.notifier).setIndex(4);
    }
  }

  void _handleBottomNavTap(int index) {
    ref.read(nummaBottomNavProvider.notifier).setIndex(index);
    switch (index) {
      case 0:
        _navigateToScreen(2);
        break;
      case 1:
        _navigateToScreen(3);
        break;
      case 2:
        _navigateToScreen(6);
        break;
      case 3:
        _navigateToScreen(10);
        break;
      case 4:
        _navigateToScreen(14);
        break;
    }
  }

  Widget _buildCurrentScreenWidget(int currentScreen) {
    final orders = ref.watch(nummaOrdersProvider);
    final activeOrder = _selectedOrder ?? (orders.isNotEmpty ? orders.first : null);

    switch (currentScreen) {
      case 1:
        return Numma01LoginScreen(
          onLoginSuccess: () => _navigateToScreen(2),
        );
      case 2:
        return Numma02DashboardScreen(
          onOpenProducts: () => _navigateToScreen(3),
          onOpenOrders: () => _navigateToScreen(6),
          onOpenCustomers: () => _navigateToScreen(10),
          onOpenReports: () => _navigateToScreen(11),
          onOpenSettings: () => _navigateToScreen(14),
          onNavigateToScreen: (num) => _navigateToScreen(num),
        );
      case 3:
        return Numma03ProductsListScreen(
          onAddProduct: () => _navigateToScreen(4),
          onSelectProduct: (p) => _navigateToScreen(5),
        );
      case 4:
        return Numma04AddProductScreen(
          onBack: () => _navigateToScreen(3),
          onSaved: () => _navigateToScreen(3),
        );
      case 5:
        return Numma05InventoryScreen(
          onBack: () => _navigateToScreen(2),
        );
      case 6:
        return Numma06OrdersListScreen(
          onSelectOrder: (order) {
            setState(() => _selectedOrder = order);
            _navigateToScreen(7);
          },
          onBack: () => _navigateToScreen(2),
        );
      case 7:
        if (activeOrder == null) {
          return const Center(child: Text('No order selected'));
        }
        return Numma07OrderDetailsScreen(
          order: activeOrder,
          onBack: () => _navigateToScreen(6),
        );
      case 8:
        return Numma08CategoriesScreen(
          onBack: () => _navigateToScreen(2),
        );
      case 9:
        return Numma09BrandsScreen(
          onBack: () => _navigateToScreen(2),
        );
      case 10:
        return Numma10CustomersScreen(
          onBack: () => _navigateToScreen(2),
        );
      case 11:
        return Numma11ReportsScreen(
          onBack: () => _navigateToScreen(2),
        );
      case 12:
        return Numma12DeliveryScreen(
          onBack: () => _navigateToScreen(2),
        );
      case 13:
        return Numma13OffersScreen(
          onBack: () => _navigateToScreen(2),
        );
      case 14:
        return Numma14SettingsScreen(
          onBack: () => _navigateToScreen(2),
          onOpenProfile: () => _navigateToScreen(15),
        );
      case 15:
        return Numma15ProfileScreen(
          onBack: () => _navigateToScreen(14),
          onLogout: () => _navigateToScreen(1),
        );
      default:
        return Numma02DashboardScreen(
          onOpenProducts: () => _navigateToScreen(3),
          onOpenOrders: () => _navigateToScreen(6),
          onOpenCustomers: () => _navigateToScreen(10),
          onOpenReports: () => _navigateToScreen(11),
          onOpenSettings: () => _navigateToScreen(14),
        );
    }
  }

  void _showScreenSelectorModal(BuildContext context) {
    const titles = [
      '1. Admin Login',
      '2. Dashboard Overview',
      '3. Products List',
      '4. Add Product',
      '5. Inventory Management',
      '6. Orders List',
      '7. Order Details',
      '8. Manage Categories',
      '9. Manage Brands',
      '10. Customers',
      '11. Reports & Analytics',
      '12. Delivery Management',
      '13. Offers & Banners',
      '14. Settings',
      '15. Admin Profile / Logout',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AGARAM Admin - Jump to Screen',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: NummaColors.textMain),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/customer');
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: NummaColors.primaryGreen),
                      label: const Text('Customer App', style: TextStyle(color: NummaColors.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: titles.length,
                  itemBuilder: (_, i) {
                    final num = i + 1;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: NummaColors.lightGreen,
                        child: Text('$num', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: NummaColors.primaryGreen)),
                      ),
                      title: Text(titles[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NummaColors.textMain)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateToScreen(num);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = ref.watch(nummaStepProvider);
    final bottomNavIndex = ref.watch(nummaBottomNavProvider);

    // Show persistent bottom navigation on main screens
    final showBottomNav = currentScreen != 1 && currentScreen != 4 && currentScreen != 7;

    return Theme(
      data: NummaTheme.lightTheme,
      child: Scaffold(
        backgroundColor: NummaColors.creamBg,
        body: _buildCurrentScreenWidget(currentScreen),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: NummaColors.darkGreen,
          elevation: 3,
          onPressed: () => _showScreenSelectorModal(context),
          icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
          label: const Text(
            'Jump Screen (1-15)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),

        // Bottom Navigation Bar per reference design
        bottomNavigationBar: showBottomNav
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: bottomNavIndex,
                  onTap: _handleBottomNavTap,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: NummaColors.darkGreen,
                  unselectedItemColor: NummaColors.textSecondary,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2_outlined),
                      activeIcon: Icon(Icons.inventory_2),
                      label: 'Products',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_outlined),
                      activeIcon: Icon(Icons.receipt_long),
                      label: 'Orders',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people_outline),
                      activeIcon: Icon(Icons.people),
                      label: 'Customers',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.grid_view_outlined),
                      activeIcon: Icon(Icons.grid_view),
                      label: 'More',
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
