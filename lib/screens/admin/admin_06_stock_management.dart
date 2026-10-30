import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin06StockManagement extends StatelessWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> stockData;
  final Function(String) onToggleStock;

  const Admin06StockManagement({
    super.key,
    required this.onBack,
    required this.stockData,
    required this.onToggleStock,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'id': 'prod_tomato', 'name': 'தக்காளி', 'english': 'Tomato'},
      {'id': 'prod_onion', 'name': 'வெங்காயம்', 'english': 'Onion'},
      {'id': 'prod_potato', 'name': 'உருளைக்கிழங்கு', 'english': 'Potato'},
      {'id': 'prod_carrot', 'name': 'கேரட்', 'english': 'Carrot'},
      {'id': 'prod_brinjal', 'name': 'கத்திரிக்காய்', 'english': 'Brinjal'},
      {'id': 'prod_drumstick', 'name': 'முருங்கைக்காய்', 'english': 'Drumstick'},
      {'id': 'prod_beans', 'name': 'பீன்ஸ்', 'english': 'Beans'},
      {'id': 'prod_mint', 'name': 'புதினா', 'english': 'Mint'},
    ];

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Stock Management',
              onBack: onBack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryGreenLight, size: 22),
                  onPressed: () {},
                ),
              ],
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final id = item['id']!;
                  final current = stockData[id] ?? {'stock': 20, 'inStock': true};
                  final inStock = current['inStock'] as bool;
                  final stockKg = current['stock'];

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                item['english']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$stockKg Kg',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => onToggleStock(id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: inStock
                                  ? AppColors.badgeBg
                                  : AppColors.outOfStockBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: inStock
                                    ? AppColors.primaryGreen
                                    : AppColors.outOfStockText,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              inStock ? 'In Stock' : 'Out of Stock',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: inStock
                                    ? AppColors.badgeText
                                    : AppColors.outOfStockText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const StepFooterBadge(
              number: '06',
              title: 'Stock Management',
            ),
          ],
        ),
      ),
    );
  }
}
