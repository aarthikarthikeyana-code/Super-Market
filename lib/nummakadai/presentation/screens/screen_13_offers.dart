import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma13OffersScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const Numma13OffersScreen({super.key, this.onBack});

  @override
  ConsumerState<Numma13OffersScreen> createState() => _Numma13OffersScreenState();
}

class _Numma13OffersScreenState extends ConsumerState<Numma13OffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddBannerDialog({NummaBanner? banner}) {
    final isEditing = banner != null;
    final titleController = TextEditingController(text: banner?.title ?? '');
    final subtitleController = TextEditingController(text: banner?.subtitle ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edit Banner' : 'Add New Banner',
            style: const TextStyle(fontWeight: FontWeight.bold, color: NummaColors.textMain),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Banner Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Everyday Essentials',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Subtitle / Offer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: subtitleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Up to 50% OFF',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: NummaColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NummaColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  if (isEditing) {
                    ref.read(nummaBannersProvider.notifier).updateBanner(
                          banner.id,
                          titleController.text.trim(),
                          subtitleController.text.trim(),
                        );
                  } else {
                    ref.read(nummaBannersProvider.notifier).addBanner(
                          NummaBanner(
                            id: 'BN_${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text.trim(),
                            subtitle: subtitleController.text.trim(),
                            tag: 'Special Offer',
                            imageUrl: 'assets/images/splash_harvest_basket.jpg',
                            isActive: true,
                          ),
                        );
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(nummaBannersProvider);

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'Offers & Banners',
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                      onPressed: widget.onBack,
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.local_offer_outlined, color: NummaColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Tabs Bar (Banners / Offers & Coupons)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NummaColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: NummaColors.primaryGreen,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: NummaColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Banners'),
                  Tab(text: 'Offers & Coupons'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Banners
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      ...banners.map((b) => _buildBannerCard(b)),
                      const SizedBox(height: 12),

                      // Add New Banner Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NummaColors.primaryGreen,
                          side: const BorderSide(color: NummaColors.primaryGreen, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _showAddBannerDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Banner', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                  // Tab 2: Offers & Coupons
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildCouponCard('WELCOME50', 'Flat 50% OFF on first order above ₹500', 'Expires in 12 days'),
                      _buildCouponCard('FREEDEL', 'Free Delivery on grocery carts above ₹299', 'Active'),
                      _buildCouponCard('FESTIVE20', '20% OFF on all Dals & Masala Combos', 'Valid till Sunday'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard(NummaBanner banner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NummaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner graphical preview
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [
                  NummaColors.darkGreen,
                  NummaColors.primaryGreen,
                  NummaColors.orangeAccent.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 16,
                  top: 24,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: NummaColors.yellowAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          banner.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: NummaColors.textMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  top: 12,
                  child: Image.asset(
                    banner.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.shopping_basket, size: 60, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          // Banner controls footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  banner.isActive ? 'Active' : 'Disabled',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: banner.isActive ? NummaColors.success : NummaColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: banner.isActive,
                  activeColor: NummaColors.primaryGreen,
                  onChanged: (val) {
                    ref.read(nummaBannersProvider.notifier).toggleBanner(banner.id);
                  },
                ),
                const Spacer(),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NummaColors.primaryGreen,
                    side: const BorderSide(color: NummaColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showAddBannerDialog(banner: banner),
                  child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: NummaColors.error),
                  onPressed: () => ref.read(nummaBannersProvider.notifier).deleteBanner(banner.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(String code, String desc, String expiry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NummaColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: NummaColors.lightGreen,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NummaColors.primaryGreen, style: BorderStyle.solid),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: NummaColors.primaryGreen,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: NummaColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expiry,
                  style: const TextStyle(
                    fontSize: 11,
                    color: NummaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
