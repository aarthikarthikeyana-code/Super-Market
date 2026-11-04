import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state.dart';
import 'admin_dashboard.dart';
import 'models.dart';
import 'paged_feed.dart';

class CashReceiptList extends ConsumerWidget {
  final int? employeeId;
  final Widget? header;
  const CashReceiptList({super.key, this.employeeId, this.header});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(storeApiProvider);
    return PagedFeed<Map<String, dynamic>>(
      queryKey: (
        'receipts',
        employeeId,
        employeeId == null ? api.deliveryToken : api.adminToken,
      ),
      changes: api.feedChanges,
      header: header,
      load: (cursor) => api.receiptPage(employeeId: employeeId, cursor: cursor),
      identity: (r) => '${r['id']}',
      emptyTitle: 'No handover receipts yet',
      emptyMessage: 'Confirmed cash receipts will appear here.',
      itemBuilder: (_, receipt, _) => OpsPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AdminIcon(
                  Icons.receipt_long_outlined,
                  background: opsInfoBg,
                  color: opsInfo,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    money(amount(receipt['amount'])),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const AdminStatusBadge('Received'),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Receipt ${receipt['id']}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              opsTime(receipt['received_at']),
              style: const TextStyle(fontSize: 11, color: opsMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class CashReceiptHistoryScreen extends StatelessWidget {
  final int employeeId;
  const CashReceiptHistoryScreen({super.key, required this.employeeId});
  @override
  Widget build(BuildContext context) => Theme(
    data: operationsTheme(),
    child: Scaffold(
      appBar: AppBar(title: const Text('Cash handover receipts')),
      body: AdminCanvas(child: CashReceiptList(employeeId: employeeId)),
    ),
  );
}
