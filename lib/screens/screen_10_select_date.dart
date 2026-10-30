import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class Screen10SelectDate extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const Screen10SelectDate({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<Screen10SelectDate> createState() => _Screen10SelectDateState();
}

class _Screen10SelectDateState extends State<Screen10SelectDate> {
  late DateTime _currentMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _selectedDay = widget.selectedDate.day;
  }

  @override
  Widget build(BuildContext context) {
    const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // April 2025 starts on Tuesday (offset = 2)
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Select Delivery Date',
              onBack: widget.onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Calendar Container Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.surfaceBorder,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Month Selector Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                                  });
                                },
                              ),
                              Text(
                                'April 2025',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Days of Week Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: daysOfWeek.map((day) {
                              return SizedBox(
                                width: 36,
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.surfaceBorder, height: 1),
                          const SizedBox(height: 12),

                          // Calendar Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 35, // 5 weeks
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 6,
                            ),
                            itemBuilder: (context, index) {
                              final dayNumber = index - firstDayWeekday + 1;
                              if (dayNumber < 1 || dayNumber > daysInMonth) {
                                return const SizedBox.shrink();
                              }

                              final isSelected = dayNumber == _selectedDay;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDay = dayNumber;
                                  });
                                  widget.onDateSelected(
                                    DateTime(_currentMonth.year, _currentMonth.month, dayNumber),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : Colors.transparent,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryGreen.withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$dayNumber',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.black
                                            : (dayNumber < 10
                                                ? AppColors.textMuted
                                                : Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Delivery Promise Note
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorderLight, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primaryGreenLight,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Selected Delivery: April $_selectedDay, 2025',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: double.infinity,
                child: CoralButton(
                  label: 'Select Time Slot',
                  onPressed: widget.onContinue,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '10',
              title: 'Select Delivery Date',
            ),
          ],
        ),
      ),
    );
  }
}
