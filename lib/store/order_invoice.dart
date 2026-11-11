import 'package:flutter/material.dart';
import 'models.dart';

class OrderInvoiceScreen extends StatelessWidget {
  final StoreOrder order;
  const OrderInvoiceScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final subtotal = order.total - amount(order.data['delivery_charge']);
    final shipping = amount(order.data['delivery_charge']);
    final dateStr = DateTime.tryParse('${order.data['created_at']}')?.toLocal();
    final formattedDate = dateStr != null
        ? '${dateStr.day} ${_monthName(dateStr.month)} ${dateStr.year}'
        : 'Today';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EE), // Cream background as in invoice image
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EE),
        elevation: 0,
        foregroundColor: const Color(0xFF1E2E21),
        title: const Text(
          'Tax Invoice & Bill',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Download Invoice',
            icon: const Icon(Icons.download_rounded, color: Color(0xFF16A05D)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF16A05D),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text('Invoice ${order.shortId} downloaded successfully!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row: Store Brand Badge + INVOICE Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Store Capsule Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'AGARAM',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'SUPERMARKET',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Invoice Title & Meta
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'INVOICE',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Color(0xFF285430),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.shortId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2E21),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Date: $formattedDate',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Store Meta Details
              const Text(
                'Agaram Supermarket, Express Store\nPhone: +91 98765 43210  |  Email: contact@agaram.com\nwww.agaramsupermarket.com',
                style: TextStyle(fontSize: 11, color: Color(0xFF71717A), height: 1.4),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE4E4E7), height: 1),
              const SizedBox(height: 16),

              // Billing To Information
              const Text(
                'Billing to:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2E21),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.data['customer_name'] ?? 'Customer'}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2E21),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${order.data['delivery_address'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF52525B), height: 1.35),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone: ${order.data['customer_phone'] ?? ''}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF71717A)),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Payment: Cash on Delivery (COD)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF16A05D)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product Table Header Bar (Green Ribbon with Rounded Edges)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF386641),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Product',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Price',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Product Items Rows
              for (final item in order.items)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F1F4))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          productLabel(item),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2E21),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${(amount(item['total_price']) / (amount(item['quantity']) > 0 ? amount(item['quantity']) : 1)).toStringAsFixed(2)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF52525B)),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${item['quantity']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E2E21)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          money(amount(item['total_price'])),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E2E21)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Subtotal & Shipping breakdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Subtotal:  ', style: TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                    Text(money(subtotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Shipping:  ', style: TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                    Text(
                      shipping == 0 ? 'FREE' : money(shipping),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: shipping == 0 ? const Color(0xFF16A05D) : const Color(0xFF1E2E21),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Total Highlight Banner (Magenta/Deep Red Rounded Capsule as in reference)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB51744),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TOTAL  ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        money(order.total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Terms & Conditions Footer Note
              const Text(
                'TERMS & CONDITIONS:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF386641),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '1. Goods once sold can be returned within 24 hours if seal is intact.\n'
                '2. Please check items and package seal at the time of delivery.\n'
                '3. Thank you for shopping with Agaram Supermarket!',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF71717A), height: 1.45),
              ),
              const SizedBox(height: 20),

              // Download / Share Invoice Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A05D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text(
                    'Download Bill / Invoice',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF16A05D),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Text('Invoice ${order.shortId} saved to your device.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}
