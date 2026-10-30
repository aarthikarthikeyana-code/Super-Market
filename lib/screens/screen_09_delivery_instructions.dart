import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class Screen09DeliveryInstructions extends StatefulWidget {
  final String initialInstructions;
  final Function(String) onSaveInstructions;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const Screen09DeliveryInstructions({
    super.key,
    required this.initialInstructions,
    required this.onSaveInstructions,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<Screen09DeliveryInstructions> createState() =>
      _Screen09DeliveryInstructionsState();
}

class _Screen09DeliveryInstructionsState
    extends State<Screen09DeliveryInstructions> {
  late TextEditingController _controller;
  final int _maxLength = 200;

  final List<String> _quickOptions = [
    'Cut vegetables',
    'Leave at door',
    'Call before delivery',
    'Ring bell once',
    'Fragile items care',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialInstructions);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _appendQuickOption(String option) {
    setState(() {
      if (_controller.text.isEmpty) {
        _controller.text = option;
      } else if (!_controller.text.contains(option)) {
        _controller.text = '${_controller.text}, $option';
      }
    });
    widget.onSaveInstructions(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Delivery Instructions',
              onBack: widget.onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Any specific instructions for delivery partner?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Instructions Text Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.surfaceBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.primaryGreen,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Special Notes (Optional)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _controller,
                            maxLength: _maxLength,
                            maxLines: 5,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.4,
                            ),
                            onChanged: (val) {
                              setState(() {});
                              widget.onSaveInstructions(val);
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Cut vegetables, leave at door, call before delivery, etc.',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              '${_controller.text.length}/$_maxLength',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Chips Suggestions
                    Text(
                      'Quick Suggestions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickOptions.map((opt) {
                        return GestureDetector(
                          onTap: () => _appendQuickOption(opt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.surfaceBorderLight,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: AppColors.primaryGreenLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  opt,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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
                  label: 'Select Delivery Date',
                  onPressed: widget.onContinue,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '09',
              title: 'Delivery Instructions (Optional)',
            ),
          ],
        ),
      ),
    );
  }
}
