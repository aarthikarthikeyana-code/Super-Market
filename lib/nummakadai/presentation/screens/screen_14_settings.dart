import 'package:flutter/material.dart';
import '../../core/theme/numma_theme.dart';
import '../widgets/numma_common_widgets.dart';

class Numma14SettingsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenProfile;

  const Numma14SettingsScreen({
    super.key,
    this.onBack,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'Settings',
              leading: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                      onPressed: onBack,
                    )
                  : null,
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: onOpenProfile ?? () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.group_outlined,
                    title: 'Manage Users',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Activity Log',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.headset_mic_outlined,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About AGARAM Supermarket',
                    onTap: () => _showAboutDialog(context),
                  ),
                  const SizedBox(height: 20),

                  // Bottom decoration grocery banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NummaColors.lightGreen,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NummaColors.primaryGreen.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco, color: NummaColors.primaryGreen, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'AGARAM Supermarket Admin v2.4.0',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: NummaColors.textMain,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Fresh Groceries For a Better Tomorrow',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: NummaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NummaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: NummaColors.lightGreen,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Icon(icon, color: NummaColors.primaryGreen, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: NummaColors.textMain,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: NummaColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About AGARAM Supermarket', style: TextStyle(fontWeight: FontWeight.bold, color: NummaColors.darkGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('AGARAM Supermarket Admin Portal', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Manage products, orders, categories, deliveries, and business analytics seamlessly with authentic grocery e-commerce design.'),
            SizedBox(height: 10),
            Text('Version: 2.4.0 (Production Build)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: NummaColors.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
