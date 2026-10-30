import 'package:flutter/material.dart';
import '../../core/theme/numma_theme.dart';
import '../widgets/numma_common_widgets.dart';

class Numma15ProfileScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onLogout;

  const Numma15ProfileScreen({
    super.key,
    this.onBack,
    this.onLogout,
  });

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.bold, color: NummaColors.error),
        ),
        content: const Text('Are you sure you want to log out from AGARAM Supermarket Admin Panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: NummaColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NummaColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onLogout?.call();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'My Profile',
              leading: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                      onPressed: onBack,
                    )
                  : null,
            ),

            // Profile info & settings
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NummaColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: NummaColors.lightGreen,
                          child: const Icon(
                            Icons.person,
                            color: NummaColors.primaryGreen,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin User',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: NummaColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'admin@nummakadai.com',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: NummaColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: NummaColors.lightGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Super Admin',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: NummaColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu Options
                  _buildMenuItem(Icons.edit_outlined, 'Edit Profile'),
                  _buildMenuItem(Icons.lock_outline, 'Change Password'),
                  _buildMenuItem(Icons.group_outlined, 'Manage Users'),
                  _buildMenuItem(Icons.history, 'Activity Log'),
                  _buildMenuItem(Icons.headset_mic_outlined, 'Help & Support'),
                  _buildMenuItem(Icons.info_outline, 'About AGARAM Supermarket'),
                  const SizedBox(height: 24),

                  // Red Bordered Logout Button per design specification
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: NummaColors.error,
                      side: const BorderSide(color: NummaColors.error, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout, color: NummaColors.error),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: NummaColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NummaColors.border),
      ),
      child: ListTile(
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
        onTap: () {},
      ),
    );
  }
}
