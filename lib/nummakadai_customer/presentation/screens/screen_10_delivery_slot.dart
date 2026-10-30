import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../../data/models/customer_models.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common_widgets.dart';

class Customer10DeliverySlotScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback onContinue;

  const Customer10DeliverySlotScreen({
    super.key,
    this.onBack,
    required this.onContinue,
  });

  @override
  ConsumerState<Customer10DeliverySlotScreen> createState() => _Customer10DeliverySlotScreenState();
}

class _Customer10DeliverySlotScreenState extends ConsumerState<Customer10DeliverySlotScreen> {
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = 0;

  final List<Map<String, String>> _dates = [
    {'day': 'Today', 'date': '22 Oct'},
    {'day': 'Tomorrow', 'date': '23 Oct'},
    {'day': 'Fri', 'date': '24 Oct'},
    {'day': 'Sat', 'date': '25 Oct'},
  ];

  final List<String> _timeSlots = [
    '10:00 AM – 12:00 PM',
    '12:00 PM – 02:00 PM',
    '04:00 PM – 06:00 PM',
    '06:00 PM – 08:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            CustomerAppBar(
              title: 'Select Delivery Slot',
              onBack: widget.onBack,
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  // Top date selectors
                  Text(
                    'Select Day',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: NummaCustomerColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: List.generate(_dates.length, (index) {
                      final item = _dates[index];
                      final isSelected = _selectedDateIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDateIndex = index),
                          child: Container(
                            margin: EdgeInsets.only(right: index < _dates.length - 1 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? NummaCustomerColors.darkGreen : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? NummaCustomerColors.darkGreen : NummaCustomerColors.border,
                              ),
                              boxShadow: isSelected ? NummaCustomerColors.lightShadow : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  item['day']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : NummaCustomerColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['date']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : NummaCustomerColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Delivery Time Header
                  Text(
                    'Delivery Time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: NummaCustomerColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Selectable Time Slots
                  ...List.generate(_timeSlots.length, (index) {
                    final slot = _timeSlots[index];
                    final isSelected = _selectedTimeIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTimeIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? NummaCustomerColors.lightGreen : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? NummaCustomerColors.darkGreen : NummaCustomerColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? NummaCustomerColors.darkGreen : NummaCustomerColors.secondaryText,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              slot,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: NummaCustomerColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Bottom illustration: Delivery rider / scooter
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NummaCustomerColors.border),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: NummaCustomerColors.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.two_wheeler_rounded, color: NummaCustomerColors.darkGreen, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Express Scheduled Delivery',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: NummaCustomerColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Fresh groceries picked and delivered in your chosen slot',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: NummaCustomerColors.secondaryText,
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

            // Continue CTA Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomerPrimaryButton(
                text: 'Continue',
                onPressed: () {
                  ref.read(selectedDeliverySlotProvider.notifier).setSlot(
                        CustomerDeliverySlot(
                          dateLabel: _dates[_selectedDateIndex]['day']!,
                          dateNum: _dates[_selectedDateIndex]['date']!,
                          timeRange: _timeSlots[_selectedTimeIndex],
                        ),
                      );
                  widget.onContinue();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

