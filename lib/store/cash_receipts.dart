import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state.dart';
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
      itemBuilder: (_, receipt, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.task_alt),
          title: Text(money(amount(receipt['amount']))),
          subtitle: Text(
            '${receipt['id']}\n${DateTime.tryParse('${receipt['received_at']}')?.toLocal().toString().split('.').first ?? ''}',
          ),
        ),
      ),
    );
  }
}

class CashReceiptHistoryScreen extends StatelessWidget {
  final int employeeId;
  const CashReceiptHistoryScreen({super.key, required this.employeeId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cash handover receipts')),
    body: CashReceiptList(employeeId: employeeId),
  );
}
