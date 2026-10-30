import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/customer_theme.dart';
import 'providers/customer_providers.dart';
import 'screens/screen_01_splash.dart';
import 'screens/screen_02_login.dart';
import 'screens/screen_03_otp.dart';
import 'screens/screen_04_home.dart';
import 'screens/screen_05_categories.dart';
import 'screens/screen_06_brands.dart';
import 'screens/screen_07_product_details.dart';
import 'screens/screen_08_cart.dart';
import 'screens/screen_09_address.dart';
import 'screens/screen_10_delivery_slot.dart';
import 'screens/screen_11_payment.dart';
import 'screens/screen_12_order_success.dart';
import 'screens/screen_13_my_orders.dart';
import 'screens/screen_14_account.dart';
import 'screens/screen_15_logout.dart';

class NummaCustomerFlowShell extends ConsumerStatefulWidget {
  const NummaCustomerFlowShell({super.key});

  @override
  ConsumerState<NummaCustomerFlowShell> createState() => _NummaCustomerFlowShellState();
}

class _NummaCustomerFlowShellState extends ConsumerState<NummaCustomerFlowShell> {
  void _navigateToScreen(int screenNumber) {
    ref.read(customerFlowStepProvider.notifier).setStep(screenNumber);
    if (screenNumber == 4) {
      ref.read(customerBottomNavProvider.notifier).setIndex(0);
    } else if (screenNumber == 5) {
      ref.read(customerBottomNavProvider.notifier).setIndex(1);
    } else if (screenNumber == 8) {
      ref.read(customerBottomNavProvider.notifier).setIndex(2);
    } else if (screenNumber == 13) {
      ref.read(customerBottomNavProvider.notifier).setIndex(3);
    } else if (screenNumber == 14) {
      ref.read(customerBottomNavProvider.notifier).setIndex(4);
    }
  }

  void _handleBottomNavTap(int index) {
    ref.read(customerBottomNavProvider.notifier).setIndex(index);
    switch (index) {
      case 0:
        _navigateToScreen(4);
        break;
      case 1:
        _navigateToScreen(5);
        break;
      case 2:
        _navigateToScreen(8);
        break;
      case 3:
        _navigateToScreen(13);
        break;
      case 4:
        _navigateToScreen(14);
        break;
    }
  }

  void _confirmLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: NummaCustomerColors.darkText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: NummaCustomerColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NummaCustomerColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToScreen(15);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreenWidget(int currentScreen) {
    switch (currentScreen) {
      case 1:
        return Customer01SplashScreen(
          onContinue: () => _navigateToScreen(2),
        );
      case 2:
        return Customer02LoginScreen(
          onContinue: () => _navigateToScreen(3),
        );
      case 3:
        return Customer03OtpScreen(
          onVerifySuccess: () => _navigateToScreen(4),
          onBack: () => _navigateToScreen(2),
        );
      case 4:
        return Customer04HomeScreen(
          onOpenDrawer: () {},
          onOpenCategories: () => _navigateToScreen(5),
          onOpenOffers: () {},
          onSelectProduct: (p) => _navigateToScreen(7),
        );
      case 5:
        return Customer05CategoriesScreen(
          onBack: () => _navigateToScreen(4),
          onSelectCategory: (c) => _navigateToScreen(6),
        );
      case 6:
        return Customer06BrandsScreen(
          onBack: () => _navigateToScreen(5),
          onSelectBrand: (b) => _navigateToScreen(7),
        );
      case 7:
        return Customer07ProductSelectionScreen(
          onBack: () => _navigateToScreen(4),
          onAddToCartSuccess: () => _navigateToScreen(8),
        );
      case 8:
        return Customer08CartScreen(
          onBack: () => _navigateToScreen(4),
          onProceedToCheckout: () => _navigateToScreen(9),
        );
      case 9:
        return Customer09AddressScreen(
          onBack: () => _navigateToScreen(8),
          onContinue: () => _navigateToScreen(10),
        );
      case 10:
        return Customer10DeliverySlotScreen(
          onBack: () => _navigateToScreen(9),
          onContinue: () => _navigateToScreen(11),
        );
      case 11:
        return Customer11PaymentReviewScreen(
          onBack: () => _navigateToScreen(10),
          onChangeAddress: () => _navigateToScreen(9),
          onChangeSlot: () => _navigateToScreen(10),
          onPlaceOrderSuccess: () => _navigateToScreen(12),
        );
      case 12:
        return Customer12OrderSuccessScreen(
          onViewOrderDetails: () => _navigateToScreen(13),
          onContinueShopping: () => _navigateToScreen(4),
        );
      case 13:
        return Customer13MyOrdersScreen(
          onBack: () => _navigateToScreen(4),
        );
      case 14:
        return Customer14AccountScreen(
          onBack: () => _navigateToScreen(4),
          onOpenOrders: () => _navigateToScreen(13),
          onOpenAddresses: () => _navigateToScreen(9),
          onLogout: () => _confirmLogoutDialog(context),
        );
      case 15:
        return Customer15LogoutScreen(
          onLoginAgain: () => _navigateToScreen(2),
        );
      default:
        return Customer04HomeScreen(
          onOpenDrawer: () {},
          onOpenCategories: () => _navigateToScreen(5),
          onOpenOffers: () {},
          onSelectProduct: (p) => _navigateToScreen(7),
        );
    }
  }

  void _showScreenSelectorModal(BuildContext context) {
    const titles = [
      '1. Splash Screen',
      '2. Login / Sign Up',
      '3. OTP Verification',
      '4. Home Screen',
      '5. Categories',
      '6. Brand List',
      '7. Product Details',
      '8. Cart',
      '9. Delivery Address',
      '10. Delivery Slot',
      '11. Payment & Review',
      '12. Order Success',
      '13. My Orders',
      '14. Account',
      '15. Logout Screen',
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
                      'AGARAM Customer - Jump to Screen',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: NummaCustomerColors.darkText),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/admin');
                      },
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: NummaCustomerColors.darkGreen),
                      label: const Text('Admin App', style: TextStyle(color: NummaCustomerColors.darkGreen, fontWeight: FontWeight.bold)),
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
                        backgroundColor: NummaCustomerColors.lightGreen,
                        child: Text('$num', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: NummaCustomerColors.darkGreen)),
                      ),
                      title: Text(titles[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NummaCustomerColors.darkText)),
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
    final currentScreen = ref.watch(customerFlowStepProvider);
    final bottomNavIndex = ref.watch(customerBottomNavProvider);

    // Persistent Bottom Navigation on main tabs (Home, Categories, Cart, Orders, Account)
    final showBottomNav = currentScreen >= 4 && currentScreen <= 8 || currentScreen == 13 || currentScreen == 14;

    return Theme(
      data: NummaCustomerTheme.lightTheme,
      child: Scaffold(
        backgroundColor: NummaCustomerColors.creamBg,
        body: _buildCurrentScreenWidget(currentScreen),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: NummaCustomerColors.darkGreen,
          elevation: 3,
          onPressed: () => _showScreenSelectorModal(context),
          icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
          label: const Text(
            'Jump Screen (1-15)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),

        // Persistent Bottom Navigation Bar
        bottomNavigationBar: showBottomNav
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: NummaCustomerColors.border, width: 1)),
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
                  selectedItemColor: NummaCustomerColors.darkGreen,
                  unselectedItemColor: NummaCustomerColors.secondaryText,
                  selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.grid_view_outlined),
                      activeIcon: Icon(Icons.grid_view_rounded),
                      label: 'Categories',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.shopping_bag_outlined),
                      activeIcon: Icon(Icons.shopping_bag_rounded),
                      label: 'Cart',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_outlined),
                      activeIcon: Icon(Icons.receipt_long_rounded),
                      label: 'Orders',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline_rounded),
                      activeIcon: Icon(Icons.person_rounded),
                      label: 'Account',
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

