import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state.dart';
import 'paged_feed.dart';

class EmployeePickerScreen extends ConsumerStatefulWidget {
  const EmployeePickerScreen({super.key});
  @override
  ConsumerState<EmployeePickerScreen> createState() => _EmployeePickerState();
}

class _EmployeePickerState extends ConsumerState<EmployeePickerScreen> {
  String _search = '';
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(storeApiProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Assign delivery employee')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search employee name, ID or phone',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (text) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) setState(() => _search = text.trim());
                });
              },
            ),
          ),
          Expanded(
            child: PagedFeed<Map<String, dynamic>>(
              queryKey: ('readyEmployees', api.adminToken, _search),
              changes: api.feedChanges,
              load: (cursor) => api.employeePage(
                cursor: cursor,
                search: _search,
                ready: true,
              ),
              identity: (p) => '${p['id']}',
              emptyTitle: 'No verified employees found',
              emptyMessage: 'Complete employee onboarding and verification in Delivery team, then try again.',
              itemBuilder: (_, person, _) => Card(
                child: ListTile(
                  title: Text('${person['name']}'),
                  subtitle: Text(
                    '${person['employee_code']} · ${person['phone']}\n${person['active_orders']} active orders',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, person),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
