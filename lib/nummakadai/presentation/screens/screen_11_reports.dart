import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/numma_theme.dart';
import '../widgets/numma_common_widgets.dart';

class Numma11ReportsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const Numma11ReportsScreen({super.key, this.onBack});

  @override
  ConsumerState<Numma11ReportsScreen> createState() => _Numma11ReportsScreenState();
}

class _Numma11ReportsScreenState extends ConsumerState<Numma11ReportsScreen> {
  final String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'Reports & Analytics',
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                      onPressed: widget.onBack,
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_download_outlined, color: NummaColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Filter Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NummaColors.border),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.calendar_month_outlined, size: 18, color: NummaColors.primaryGreen),
                          SizedBox(width: 8),
                          Text(
                            '01 Oct 2024 - 31 Oct 2024',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: NummaColors.textMain,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.keyboard_arrow_down, size: 18, color: NummaColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top 3 Metric Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Sales',
                            value: '₹2,48,320',
                            change: '+18%',
                            icon: Icons.currency_rupee,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Orders',
                            value: '520',
                            change: '+12%',
                            icon: Icons.receipt_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'New Customers',
                            value: '186',
                            change: '+20%',
                            icon: Icons.person_add_alt_1_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Sales Trend Chart Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NummaColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Sales Trend',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: NummaColors.textMain,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: NummaColors.lightGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedPeriod,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: NummaColors.primaryGreen,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 16, color: NummaColors.primaryGreen),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // fl_chart LineChart
                          SizedBox(
                            height: 190,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 20000,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: NummaColors.border.withOpacity(0.5),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 34,
                                      interval: 20000,
                                      getTitlesWidget: (val, meta) {
                                        if (val == 0) return const SizedBox.shrink();
                                        return Text(
                                          '${(val / 1000).toInt()}k',
                                          style: const TextStyle(fontSize: 10, color: NummaColors.textSecondary),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      interval: 1,
                                      getTitlesWidget: (val, meta) {
                                        switch (val.toInt()) {
                                          case 0:
                                            return const Text('1 Oct', style: TextStyle(fontSize: 10, color: NummaColors.textSecondary));
                                          case 2:
                                            return const Text('8 Oct', style: TextStyle(fontSize: 10, color: NummaColors.textSecondary));
                                          case 4:
                                            return const Text('15 Oct', style: TextStyle(fontSize: 10, color: NummaColors.textSecondary));
                                          case 6:
                                            return const Text('22 Oct', style: TextStyle(fontSize: 10, color: NummaColors.textSecondary));
                                          case 8:
                                            return const Text('31 Oct', style: TextStyle(fontSize: 10, color: NummaColors.textSecondary));
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 8,
                                minY: 0,
                                maxY: 70000,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: const [
                                      FlSpot(0, 24000),
                                      FlSpot(1, 32000),
                                      FlSpot(2, 28000),
                                      FlSpot(3, 45000),
                                      FlSpot(4, 38000),
                                      FlSpot(5, 52000),
                                      FlSpot(6, 48000),
                                      FlSpot(7, 62000),
                                      FlSpot(8, 58000),
                                    ],
                                    isCurved: true,
                                    curveSmoothness: 0.35,
                                    color: NummaColors.primaryGreen,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                        radius: 3.5,
                                        color: Colors.white,
                                        strokeWidth: 2,
                                        strokeColor: NummaColors.primaryGreen,
                                      ),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          NummaColors.primaryGreen.withOpacity(0.28),
                                          NummaColors.primaryGreen.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Top Categories Section
                    const Text(
                      'Top Categories',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: NummaColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NummaColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildCategoryRow('assets/images/products/rice.png', 'அரிசி', 0.28, '28%'),
                          const Divider(height: 18, color: NummaColors.border),
                          _buildCategoryRow('assets/images/products/dal.png', 'பருப்பு வகைகள்', 0.22, '22%'),
                          const Divider(height: 18, color: NummaColors.border),
                          _buildCategoryRow('assets/images/products/oil.png', 'எண்ணெய் வகைகள்', 0.18, '18%'),
                          const Divider(height: 18, color: NummaColors.border),
                          _buildCategoryRow('assets/images/products/masala.png', 'மசாலா பொருட்கள்', 0.12, '12%'),
                          const Divider(height: 18, color: NummaColors.border),
                          _buildCategoryRow('assets/images/products/vegetables.png', 'காய்கறிகள்', 0.08, '8%'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: NummaColors.lightGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NummaColors.primaryGreen.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: NummaColors.primaryGreen),
              Text(
                change,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: NummaColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: NummaColors.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: NummaColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String imagePath, String nameTa, double percentage, String label) {
    return Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: NummaProductImage(imageUrl: imagePath, width: 28, height: 28),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nameTa,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: NummaColors.textMain,
                ),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: NummaColors.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: NummaColors.creamBg,
            valueColor: const AlwaysStoppedAnimation<Color>(NummaColors.primaryGreen),
          ),
        ),
      ],
    );
  }
}
