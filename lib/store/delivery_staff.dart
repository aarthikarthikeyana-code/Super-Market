import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'state.dart';
import 'models.dart';
import 'widgets.dart';
import 'paged_feed.dart';
import 'cash_receipts.dart';

const employeeDocuments = {
  'identity': 'Identity proof (masked Aadhaar / other ID)',
  'address': 'Address proof',
  'licence': 'Driving licence',
  'registration': 'Vehicle registration (RC)',
  'insurance': 'Vehicle insurance',
  'photo': 'Employee photograph',
};

class EmployeeEditorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? person;
  const EmployeeEditorScreen({super.key, this.person});
  @override
  ConsumerState<EmployeeEditorScreen> createState() => _EmployeeEditorState();
}

class _EmployeeEditorState extends ConsumerState<EmployeeEditorScreen> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  Map<String, dynamic>? _person;
  bool _busy = false, _active = true, _consent = false, _verified = false;
  String _vehicle = 'bicycle', _idType = '', _kind = 'identity';
  int _setupStep = 0;
  final _scroll = ScrollController();
  final _keys = [
    'name',
    'phone',
    'email',
    'password',
    'address',
    'city',
    'pincode',
    'emergency_contact_name',
    'emergency_contact_phone',
    'vehicle_number',
    'licence_number',
    'licence_expiry',
    'joining_date',
    'id_last_four',
  ];
  bool get _motor => ['motorcycle', 'car', 'van'].contains(_vehicle);
  @override
  void initState() {
    super.initState();
    _person = widget.person;
    if (_person?['ready_for_deliveries'] == true) _setupStep = 2;
    for (final key in _keys) {
      _fields[key] = TextEditingController(text: '${_person?[key] ?? ''}');
    }
    _fields['joining_date']!.text =
        _person?['joining_date'] ??
        DateTime.now().toIso8601String().split('T').first;
    _active = _person?['is_active'] ?? true;
    _consent = _person?['document_consent'] ?? false;
    _verified = _person?['documents_verified'] ?? false;
    _vehicle = _person?['vehicle_type'] ?? 'bicycle';
    _idType = _person?['id_proof_type'] ?? '';
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final data = <String, dynamic>{
        for (final key in _keys)
          if (key != 'password' &&
              key != 'licence_expiry' &&
              key != 'joining_date')
            key: _fields[key]!.text.trim(),
        if (_fields['password']!.text.isNotEmpty)
          'password': _fields['password']!.text,
        'licence_expiry': _fields['licence_expiry']!.text.isEmpty
            ? null
            : _fields['licence_expiry']!.text,
        'joining_date': _fields['joining_date']!.text.isEmpty
            ? null
            : _fields['joining_date']!.text,
        'is_active': _active,
        'vehicle_type': _vehicle,
        'id_proof_type': _idType,
        'document_consent': _consent,
        'documents_verified': _verified,
      };
      final person = await ref
          .read(storeApiProvider)
          .savePerson(data, id: _person?['id']);
      if (!mounted) return;
      setState(() {
        _person = person;
        _fields['password']!.clear();
      });
      ref.invalidate(deliveryTeamProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Employee ${person['employee_code']} saved. Login uses this ID or mobile number and the employee password.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reloadDocuments() async {
    final person = await ref
        .read(storeApiProvider)
        .employeeRecord(_person!['id']);
    if (!mounted) return;
    setState(() {
      _person = person;
      _verified = person['documents_verified'];
    });
    ref.invalidate(deliveryTeamProvider);
  }

  Future<void> _upload() async {
    if (_busy || _person == null) return;
    if (!_consent || _person!['document_consent'] != true) {
      showStoreError(
        context,
        'Save the employee consent before uploading documents.',
      );
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 90,
    );
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(storeApiProvider)
          .uploadEmployeeDocument(
            _person!['id'],
            _kind,
            await file.readAsBytes(),
            file.name,
          );
      await _reloadDocuments();
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _view(Map document) async {
    String? url;
    try {
      url = await ref
          .read(storeApiProvider)
          .employeeDocumentUrl(_person!['id'], '${document['id']}');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * .75,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Private employee document'),
                  trailing: IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: Image.network(
                      url!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'This private link expired or the document could not load. Close and open it again.',
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
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (url != null) await NetworkImage(url).evict();
    }
  }

  Future<void> _delete(Map document) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this document?'),
        content: const Text(
          'The private stored copy will be deleted. The employee will need document verification again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(storeApiProvider)
          .deleteEmployeeDocument(_person!['id'], '${document['id']}');
      await _reloadDocuments();
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _heading(String label) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 14),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: storeGreen,
      ),
    ),
  );
  Widget _field(
    String key,
    String label, {
    bool required = false,
    bool phone = false,
    bool secret = false,
    int lines = 1,
    int? length,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: _fields[key],
      enabled: !_busy,
      obscureText: secret,
      maxLines: lines,
      maxLength: length,
      keyboardType: phone
          ? TextInputType.phone
          : key == 'pincode'
          ? TextInputType.number
          : key == 'email'
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (required && v.isEmpty) return 'Enter $label';
        if (secret &&
            (v.isNotEmpty || _person?['has_login'] != true) &&
            v.length < 8) {
          return 'Use at least 8 characters';
        }
        if (phone &&
            v.isNotEmpty &&
            !RegExp(r'^(\+91)?[6-9][0-9]{9}$')
                .hasMatch(v.replaceAll(RegExp(r'[\s()-]'), ''))) {
          return 'Enter a valid Indian mobile number';
        }
        if (key == 'pincode' && !RegExp(r'^[1-9][0-9]{5}$').hasMatch(v)) {
          return 'Enter a 6-digit pincode';
        }
        if (key == 'id_last_four' &&
            v.isNotEmpty &&
            !RegExp(r'^[a-zA-Z0-9]{4}$').hasMatch(v)) {
          return 'Enter only the last four characters';
        }
        return null;
      },
    ),
  );
  Widget _date(String key, String label, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: _fields[key],
      enabled: !_busy,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      validator: (v) =>
          required && (v?.isEmpty ?? true) ? 'Choose a date' : null,
      onTap: () async {
        final now = DateTime.now();
        final current = DateTime.tryParse(_fields[key]!.text) ?? now;
        final date = await showDatePicker(
          context: context,
          initialDate: current,
          firstDate: DateTime(2000),
          lastDate: DateTime(now.year + 30),
        );
        if (date != null && mounted) {
          _fields[key]!.text = date.toIso8601String().split('T').first;
        }
      },
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          _person == null
              ? 'Create delivery employee'
              : 'Manage delivery employee',
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Create a login, record work details, then verify and activate.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        children: [
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: i <= _setupStep
                                  ? storeGreen
                                  : const Color(0xFFE0E6E1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              '1 Login',
                              '2 Work details',
                              '3 Verify & activate',
                            ][i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == _setupStep
                                  ? FontWeight.w800
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (_person?['employee_code'] != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined, color: storeGreen),
                  title: SelectableText(
                    '${_person!['employee_code']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    _person!['ready_for_deliveries'] == true
                        ? 'Verified · ready for delivery assignments'
                        : 'Complete onboarding and verification before dispatch',
                  ),
                ),
              ),
            if (_setupStep == 0) ...[
              _heading('1. Employee contact & login'),
              _field('name', 'Full name', required: true, length: 100),
              _field('phone', 'Mobile number', required: true, phone: true),
              _field('email', 'Email (optional)'),
              _field(
                'password',
                _person?['has_login'] == true
                    ? 'New password (leave blank to keep)'
                    : 'Create employee password',
                secret: true,
                required: _person?['has_login'] != true,
              ),
              Text(
                'Employee ID or mobile number + password is required. Password resets sign out existing employee sessions.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (_setupStep == 1) ...[
              _heading('2. Address & work details'),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Private staff records help your store contact the employee and check delivery readiness. Customers only see their assigned employee’s name and phone.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
              _field('address', 'Full address', required: true, lines: 3),
              _field('city', 'City / town', required: true),
              _field('pincode', 'Pincode', required: true, length: 6),
              _heading('Emergency contact'),
              _field(
                'emergency_contact_name',
                'Emergency contact name',
                required: true,
              ),
              _field(
                'emergency_contact_phone',
                'Emergency contact mobile',
                required: true,
                phone: true,
              ),
              _heading('Work and vehicle'),
              _date('joining_date', 'Joining date'),
              DropdownButtonFormField<String>(
                initialValue: _vehicle,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Delivery mode'),
                items: [
                  for (final entry in {
                    'walking': 'Walking',
                    'bicycle': 'Bicycle',
                    'motorcycle': 'Motorcycle / scooter',
                    'car': 'Car',
                    'van': 'Van',
                  }.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: _busy ? null : (v) => setState(() => _vehicle = v!),
              ),
              const SizedBox(height: 14),
              if (_motor) ...[
                _field(
                  'vehicle_number',
                  'Vehicle registration number',
                  required: true,
                ),
                _field(
                  'licence_number',
                  'Driving licence number',
                  required: true,
                ),
                _date(
                  'licence_expiry',
                  'Driving licence expiry',
                  required: true,
                ),
              ],
            ],
            if (_setupStep == 2) ...[
              _heading('3. Verify identity & activate'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Review employee details',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_fields['name']!.text}\n${_fields['phone']!.text}\n${_fields['city']!.text} · ${_fields['pincode']!.text}',
                        style: const TextStyle(fontSize: 12, height: 1.7),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Role: Delivery employee${_person?['employee_code'] == null ? ' · ID generated after saving' : ' · ${_person!['employee_code']}'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _idType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'ID proof type'),
                items: [
                  for (final entry in {
                    '': 'Not provided yet',
                    'masked_aadhaar': 'Masked Aadhaar (optional)',
                    'voter_id': 'Voter ID',
                    'passport': 'Passport',
                    'driving_licence': 'Driving licence',
                    'other': 'Other government ID',
                  }.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: _busy ? null : (v) => setState(() => _idType = v!),
              ),
              const SizedBox(height: 14),
              _field(
                'id_last_four',
                'ID last four characters (optional)',
                length: 4,
              ),
              const Text(
                'Use masked Aadhaar or another accepted ID. Do not enter a full Aadhaar number. Upload document photos only with employee consent.',
                style: TextStyle(
                  height: 1.5,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consent,
                title: const Text(
                  'Employee consent recorded for storing onboarding documents',
                ),
                onChanged: _busy
                    ? null
                    : (v) => setState(() {
                        _consent = v!;
                        if (!_consent) _verified = false;
                      }),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _verified,
                title: const Text(
                  'I have checked the original ID and applicable vehicle documents',
                ),
                subtitle: const Text(
                  'New or removed document copies require another admin check.',
                ),
                onChanged: _busy || !_consent
                    ? null
                    : (v) => setState(() => _verified = v!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                title: const Text('Employee account active'),
                subtitle: const Text(
                  'Reassign open orders and receive cash before deactivating.',
                ),
                onChanged: _busy ? null : (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(
                  _busy
                      ? 'Please wait…'
                      : _person == null
                      ? 'Create employee account'
                      : 'Save employee details',
                ),
              ),
              if (_person?['has_login'] == true)
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => Navigator.pop(context, _person),
                  icon: const Icon(Icons.login),
                  label: const Text('Open employee sign-in'),
                ),
              _heading('Private document photos'),
              if (_person == null)
                const Text(
                  'Save the employee account first, then upload private document photos.',
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: _kind,
                  isExpanded: true,
                  items: [
                    for (final entry in employeeDocuments.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _kind = v!),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _upload,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Upload document photo'),
                ),
                for (final document in _person!['documents'] ?? [])
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(
                        employeeDocuments[document['kind']] ?? document['kind'],
                      ),
                      subtitle: const Text('Private · admin access only'),
                      onTap: _busy ? null : () => _view(document),
                      trailing: IconButton(
                        tooltip: 'Delete private document',
                        onPressed: _busy ? null : () => _delete(document),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                _heading('Cash handovers'),
                Text(
                  '${money(amount(_person!['cash_to_handover']))} to receive from this employee',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EmployeeCashScreen(person: _person!),
                            ),
                          );
                          await _reloadDocuments();
                        },
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Manage cash handovers'),
                ),
              ],
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                if (_setupStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() => _setupStep--);
                              _scroll.jumpTo(0);
                            },
                      child: const Text('Back'),
                    ),
                  ),
                if (_setupStep > 0) const SizedBox(width: 12),
                if (_setupStep < 2)
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : () {
                              if (_form.currentState!.validate()) {
                                setState(() => _setupStep++);
                                _scroll.jumpTo(0);
                              }
                            },
                      child: Text(
                        _setupStep == 0
                            ? 'Continue to work details'
                            : 'Continue to verification',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

class EmployeeCashScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> person;
  const EmployeeCashScreen({super.key, required this.person});
  @override
  ConsumerState<EmployeeCashScreen> createState() => _EmployeeCashState();
}

class _EmployeeCashState extends ConsumerState<EmployeeCashScreen> {
  final _selected = <String, int>{};
  String _receiptKey = newUuid();
  int _revision = 0;
  bool _busy = false;
  int _view = 0;
  Map<String, dynamic> _ledger = {};
  String? _cashTotal;
  Future<void> _receive() async {
    if (_busy || _selected.isEmpty) return;
    final total =
        _selected.values.fold(0, (int sum, cents) => sum + cents) / 100;
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => OrderActionDialog(kind: 'handover', total: total),
    );
    if (values == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final receipt = await ref.read(storeApiProvider).receiveCash(
        widget.person['id'],
        {
          'idempotency_key': _receiptKey,
          'order_ids': _selected.keys.toList(),
          'amount': values['cash_collected_amount'],
        },
      );
      if (!mounted) return;
      ref.invalidate(deliveryTeamProvider);
      ref.invalidate(adminDashboardProvider);
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cash received by store'),
          content: SelectableText(
            '${money(amount(receipt['amount']))}\nReceipt: ${receipt['id']}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) {
        setState(() {
          _selected.clear();
          _receiptKey = newUuid();
          _revision++;
        });
      }
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showDelivered(StoreOrder order) {
    final received =
        order.data['cash_handover'] != null ||
        order.data['cash_received_directly'] == true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .65,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                order.shortId,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${order.data['customer_name'] ?? ''}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                order.paymentStatus != 'collected'
                    ? 'No COD cash collected for this order.'
                    : '${money(amount(order.data['cash_collected_amount']))} collected. ${received ? 'Cash is already confirmed by the store.' : 'Cash is still with this employee.'}',
                style: const TextStyle(height: 1.7, color: storeGreen),
              ),
              const Divider(height: 28),
              for (final item in order.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(productLabel(item)),
                  subtitle: Text('${item['unit']} x ${item['quantity']}'),
                  trailing: Text(money(amount(item['total_price']))),
                ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Order total'),
                trailing: Text(
                  money(order.total),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (order.data['cash_handover'] != null)
                SelectableText(
                  'Handover receipt: ${order.data['cash_handover']}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(storeApiProvider);
    final total =
        _selected.values.fold(0, (int sum, cents) => sum + cents) / 100;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text('${widget.person['name']} | cash')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Employee cash account',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final entry in <(String, String)>[
                            ('With employee', 'cash_to_handover'),
                            ('Received by store', 'cash_received_by_store'),
                            ('Total collected', 'cash_collected'),
                          ])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _ledger[entry.$2] == null
                                            ? (entry.$2 == 'cash_to_handover' &&
                                                      _cashTotal != null
                                                  ? money(amount(_cashTotal))
                                                  : 'Loading')
                                            : money(amount(_ledger[entry.$2])),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: storeGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      entry.$1,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_ledger['pending_orders'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            '${_ledger['pending_orders']} delivered orders awaiting handover',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          ['To receive', 'Delivered', 'Receipts'][i],
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: _view == i,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _view = i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _view == 2
                  ? CashReceiptList(employeeId: widget.person['id'] as int)
                  : _view == 1
                  ? PagedFeed<StoreOrder>(
                      queryKey: (
                        'employeeDelivered',
                        widget.person['id'],
                        api.adminToken,
                        _revision,
                      ),
                      changes: api.feedChanges,
                      load: (cursor) => api.orderPage(
                        cursor: cursor,
                        admin: true,
                        status: 'Delivered',
                        assigned: '${widget.person['id']}',
                      ),
                      identity: (order) => order.id,
                      emptyTitle: 'No delivered orders yet',
                      emptyMessage: 'Delivered orders assigned to this employee will appear here.',
                      itemBuilder: (_, order, _) => OrderSummaryCard(
                        order: order,
                        onTap: () => _showDelivered(order),
                      ),
                    )
                  : PagedFeed<Map<String, dynamic>>(
                      queryKey: (
                        'cashDue',
                        widget.person['id'],
                        api.adminToken,
                        _revision,
                      ),
                      changes: api.feedChanges,
                      load: (cursor) =>
                          api.cashDuePage(widget.person['id'], cursor),
                      identity: (o) => '${o['order_id']}',
                      onMetadata: (data) {
                        if (mounted) {
                          setState(() {
                            _cashTotal = '${data['cash_to_handover']}';
                            _ledger = data;
                          });
                        }
                      },
                      header: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Count physical cash, select the delivered orders it covers, then confirm receipt. Already received cash is excluded.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_selected.length} selected | ${money(total)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _busy || _selected.isEmpty
                                    ? null
                                    : _receive,
                                child: Text(
                                  _busy
                                      ? 'Recording receipt...'
                                      : 'Receive selected cash',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      emptyTitle: 'No cash handover is outstanding',
                      emptyMessage: 'Open Delivered to review orders or Receipts to check cash already received.',
                      itemBuilder: (_, order, _) => Card(
                        child: CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _selected.containsKey(order['order_id']),
                          onChanged:
                              _busy ||
                                  (_selected.length >= 200 &&
                                      !_selected.containsKey(order['order_id']))
                              ? null
                              : (selected) => setState(() {
                                  if (selected == true) {
                                    _selected[order['order_id']] =
                                        (amount(order['amount']) * 100).round();
                                  } else {
                                    _selected.remove(order['order_id']);
                                  }
                                  _receiptKey = newUuid();
                                }),
                          title: Text(
                            '${order['customer_name'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${order['order_id']}\n${List<Map<String, dynamic>>.from(order['items'] ?? []).map((item) => '${productLabel(item)} x ${item['quantity']}').join(', ')}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          secondary: Text(
                            money(amount(order['amount'])),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
