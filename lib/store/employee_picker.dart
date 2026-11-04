import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state.dart';
import 'admin_dashboard.dart';
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
    return Theme(
      data: operationsTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Assign delivery employee')),
        body: AdminCanvas(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Select one verified employee. Check their current workload before assigning. This order will appear in their delivery app.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: opsMuted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
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
                  itemBuilder: (_, person, _) => OpsPanel(
                    padding: const EdgeInsets.all(14),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, person),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: opsGlassMint,
                                child: Text(
                                  opsInitial('${person['name'] ?? ''}'),
                                  style: const TextStyle(color: opsForestGreen),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${person['name']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${person['employee_code'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: opsMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_circle_right_outlined,
                                color: opsForestGreen,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${person['phone']} · ${person['active_orders']} active orders',
                            style: const TextStyle(
                              fontSize: 12,
                              color: opsMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              const AdminStatusBadge('Verified'),
                              AdminStatusBadge(
                                '${person['status'] ?? 'Ready for assignment'}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> showAdminEmployeePicker(BuildContext context) =>
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: opsBaseCream,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: const EmployeePickerScreen(),
      ),
    );
