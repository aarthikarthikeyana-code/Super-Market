import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'state.dart';
import 'api.dart';
import 'models.dart';
import 'widgets.dart';
import 'paged_feed.dart';
import 'loading.dart';
import 'cash_receipts.dart';
import 'delivery_tracking.dart';

void refreshDelivery(WidgetRef ref) {
  ref.read(storeApiProvider).feedChanges.value++;
  ref.invalidate(deliveryWorkProvider);
  ref.invalidate(deliverySummaryProvider);
}

class DeliveryConsoleScreen extends ConsumerStatefulWidget {
  final String? initialEmployeeCode;
  final VoidCallback? onExit;
  const DeliveryConsoleScreen({
    super.key,
    this.initialEmployeeCode,
    this.onExit,
  });
  @override
  ConsumerState<DeliveryConsoleScreen> createState() => _DeliveryConsoleState();
}

class _DeliveryConsoleState extends ConsumerState<DeliveryConsoleScreen> {
  final _code = TextEditingController(), _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _signedIn = false, _busy = false, _history = false;
  bool _obscurePassword = true;
  late final StoreApi _api;
  int _tab = 0;
  String? _error;
  Timer? _poll;
  @override
  void initState() {
    super.initState();
    _code.text = widget.initialEmployeeCode ?? '';
    _api = ref.read(storeApiProvider);
    // An admin preview must sign in as the selected employee explicitly.
    _signedIn =
        widget.initialEmployeeCode == null && _api.deliveryToken != null;
    _api.staffChanges.addListener(_staffChanged);
    if (_signedIn) ref.read(deliveryTrackerProvider).syncActiveTrips();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_signedIn) {
        refreshDelivery(ref);
        ref.read(deliveryTrackerProvider).syncActiveTrips();
      }
    });
  }

  @override
  void dispose() {
    _api.staffChanges.removeListener(_staffChanged);
    _poll?.cancel();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _staffChanged() {
    if (mounted && _api.deliveryToken == null) {
      setState(() => _signedIn = false);
    }
  }

  Future<void> _login() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(storeApiProvider)
          .deliveryLogin(_code.text, _password.text);
      if (!mounted) return;
      _password.clear();
      refreshDelivery(ref);
      await ref.read(deliverySummaryProvider.future);
      if (!mounted) return;
      setState(() => _signedIn = true);
      ref.read(deliveryTrackerProvider).syncActiveTrips();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    ref.read(deliveryTrackerProvider).stop();
    try {
      await ref.read(storeApiProvider).deliveryLogout();
    } catch (_) {
      /* Local session is cleared even when the service is unavailable. */
    }
    if (mounted) {
      setState(() => _signedIn = false);
      refreshDelivery(ref);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorMsg;
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: storeGlassMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: storeGreen, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Change Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set a new password for your employee account.',
                  style: TextStyle(fontSize: 12, color: storeGrey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: oldCtrl,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 19),
                      onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 19),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 19),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMsg!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: storeGreen),
              onPressed: saving
                  ? null
                  : () async {
                      final n = newCtrl.text.trim();
                      final c = confirmCtrl.text.trim();
                      if (n.length < 4) {
                        setDialogState(() => errorMsg = 'Password must be at least 4 characters.');
                        return;
                      }
                      if (n != c) {
                        setDialogState(() => errorMsg = 'New passwords do not match.');
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        errorMsg = null;
                      });
                      try {
                        await _api.deliveryChangePassword(n, oldPassword: oldCtrl.text.trim());
                        if (!mounted) return;
                        if (ctx.mounted) Navigator.pop(ctx);
                        await showSmoothSuccessDialog(
                          context: context,
                          title: 'Password Updated! 🔒',
                          message: 'Your employee login password has been changed successfully. Use it on your next login.',
                          icon: Icons.check_circle_outline,
                          iconColor: const Color(0xFF16A34A),
                        );
                      } catch (e) {
                        setDialogState(() {
                          saving = false;
                          errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('FormatException: ', '');
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Password'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_signedIn || (_tab == 0 && !Navigator.canPop(context)),
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      if (_tab != 0) {
        setState(() => _tab = 0);
        return;
      }
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/');
      }
    },
    child: Theme(
      data: storeTheme(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !_signedIn,
          leading: (_signedIn && _tab != 0)
              ? IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _tab = 0),
                )
              : widget.onExit != null
              ? IconButton(
                  tooltip: 'Return to admin',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _busy
                      ? null
                      : () async {
                          await _logout();
                          await _api.useAdminWorkspace();
                          if (mounted) widget.onExit?.call();
                        },
                )
              : (Navigator.canPop(context))
              ? IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Text(
            _signedIn ? 'Agaram Delivery' : 'Delivery employee login',
          ),
          actions: [
            if (_signedIn) ...[
              IconButton(
                tooltip: 'Change password',
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.key_rounded),
              ),
              IconButton(
                tooltip: 'Refresh work',
                onPressed: () => refreshDelivery(ref),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ],
        ),
        body: !_signedIn
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.delivery_dining,
                            size: 52,
                            color: storeGreen,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Your route.\nYour deliveries.',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: storeGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Use your employee ID or registered mobile number, and the password set by your administrator.',
                            style: TextStyle(height: 1.6),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _code,
                            enabled: !_busy,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Employee ID or mobile number',
                              hintText: 'BB2026001 or registered mobile',
                            ),
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? 'Enter your employee ID or mobile number'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: _obscurePassword,
                            keyboardType: TextInputType.visiblePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (v) => (v?.isEmpty ?? true)
                                ? 'Enter your password'
                                : null,
                            onFieldSubmitted: (_) => _login(),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _login,
                              child: Text(
                                _busy ? 'Signing in…' : 'Sign in to deliveries',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Forgot your password? Ask your store administrator to reset it.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : _tab == 0
            ? _work()
            : _cash(),
        bottomNavigationBar: !_signedIn
            ? null
            : NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (v) => setState(() => _tab = v),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.local_shipping_outlined),
                    label: 'My deliveries',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.payments_outlined),
                    label: 'My cash',
                  ),
                ],
              ),
      ),
    ),
  );

  Widget _work() => Column(
    children: [
      DataView(
        loading: const AppSkeleton(kind: SkeletonKind.summary),
        retainOnRefresh: true,
        value: ref.watch(deliverySummaryProvider),
        onRetry: () => ref.invalidate(deliverySummaryProvider),
        builder: (summary) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Hello, ${summary['employee']['name']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _showChangePasswordDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: storeGreen.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: storeGreen.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock_reset_rounded, size: 15, color: storeGreen),
                          SizedBox(width: 4),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: storeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${summary['assigned']} active deliveries · ${money(amount(summary['cash_to_collect']))} to collect',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.route, color: storeGreen),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '1 Pick up  →  2 Navigate  →  3 Deliver\nCollect exact cash + customer’s 5-digit code.',
                        style: TextStyle(height: 1.6, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: ref.watch(deliveryTrackerProvider),
                builder: (context, _) {
                  final tracker = ref.read(deliveryTrackerProvider);
                  if (tracker.orders.isEmpty && tracker.error == null) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.my_location, color: storeGreen),
                    title: Text(
                      tracker.orders.isEmpty
                          ? 'Live tracking needs attention'
                          : 'Sharing ${tracker.orders.length} active trips',
                    ),
                    subtitle: Text(
                      tracker.error ?? 'Keep location enabled. Sharing stops when each delivery closes.',
                    ),
                  );
                },
              ),
              if (summary['employee']['documents_verified'] != true)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Your onboarding documents need admin verification before you can start deliveries.',
                    style: TextStyle(color: Color(0xFF9B5B13)),
                  ),
                ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Active'),
              selected: !_history,
              onSelected: (_) => setState(() => _history = false),
            ),
            const SizedBox(width: 10),
            ChoiceChip(
              label: const Text('Completed'),
              selected: _history,
              onSelected: (_) => setState(() => _history = true),
            ),
          ],
        ),
      ),
      Expanded(
        child: PagedFeed<StoreOrder>(
          queryKey: (
            'deliveryWork',
            ref.watch(storeApiProvider).deliveryToken,
            _history,
          ),
          changes: ref.watch(storeApiProvider).feedChanges,
          load: (cursor) => ref
              .read(storeApiProvider)
              .orderPage(cursor: cursor, employee: true, history: _history),
          identity: (o) => o.id,
          emptyTitle: _history
              ? 'No completed deliveries yet'
              : 'You are up to date',
          emptyMessage: _history
              ? 'Completed and cancelled assignments appear here. Cash receipts are under My cash.'
              : 'Ask your administrator to assign a packed order to your employee ID. Pull down to refresh, then open an order to pick it up.',
          itemBuilder: (_, order, _) => OrderSummaryCard(
            order: order,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeliveryOrderScreen(initialOrder: order),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _cash() => DataView(
    retainOnRefresh: true,
    value: ref.watch(deliverySummaryProvider),
    onRetry: () => ref.invalidate(deliverySummaryProvider),
    builder: (data) => CashReceiptList(
      header: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your cash account',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Card(
              color: storeGreen,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cash to hand over to store',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money(amount(data['cash_to_handover'])),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Give the collected cash to your administrator. Your balance clears after the store confirms receipt.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Total cash collected'),
              trailing: Text(money(amount(data['cash_collected']))),
            ),
            ListTile(
              title: const Text('Cash still to collect on orders'),
              trailing: Text(money(amount(data['cash_to_collect']))),
            ),
            const SizedBox(height: 24),
            const Text(
              'Handover receipts',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}

class DeliveryOrderScreen extends ConsumerStatefulWidget {
  final StoreOrder initialOrder;
  const DeliveryOrderScreen({super.key, required this.initialOrder});
  @override
  ConsumerState<DeliveryOrderScreen> createState() => _DeliveryOrderState();
}

class _DeliveryOrderState extends ConsumerState<DeliveryOrderScreen> {
  late StoreOrder _order;
  bool _busy = false;
  String? _loadError;
  Timer? _poll;
  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _reload();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_busy) _reload();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    try {
      final order = await ref.read(storeApiProvider).deliveryOrder(_order.id);
      if (mounted) {
        setState(() {
          _order = order;
          _loadError = null;
        });
        if (order.status != 'Out for Delivery') {
          ref.read(deliveryTrackerProvider).finish(order.id);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  Future<void> _action(String status) async {
    if (_busy) return;
    Map<String, dynamic>? extra = {};
    if (status == 'Delivered') {
      extra = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => OrderActionDialog(
          kind: _order.paymentStatus == 'cod' ? 'cash' : 'delivery',
          total: _order.total,
        ),
      );
    }
    if (!mounted) return;
    if (status == 'Delivery Attempted') {
      extra = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => const OrderActionDialog(kind: 'attempt'),
      );
    }
    if (!mounted) return;
    if (status == 'Out for Delivery') {
      final pickup = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start this delivery?'),
          content: const Text(
            'Check every packed item and confirm pickup. Live location is shared with the store and this customer only while this delivery is active. Enable location permission to start.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Go back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Items picked up'),
            ),
          ],
        ),
      );
      if (pickup != true) return;
      if (!mounted) return;
      try {
        await ref.read(deliveryTrackerProvider).ensureLocationPermission();
      } catch (e) {
        if (mounted) showStoreError(context, e);
        return;
      }
    }
    if (extra == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final order = await ref.read(storeApiProvider).updateDelivery(_order.id, {
        'status': status,
        ...extra,
      });
      if (!mounted) return;
      if (mounted) setState(() => _order = order);
      if (status == 'Out for Delivery') {
        try {
          await ref.read(deliveryTrackerProvider).start(order);
        } catch (e) {
          if (mounted) showStoreError(context, e);
        }
      } else {
        ref.read(deliveryTrackerProvider).finish(order.id);
      }
      refreshDelivery(ref);
      if (status == 'Delivered' && mounted) {
        await showSmoothSuccessDialog(
          context: context,
          title: 'Delivery Completed! 🎉',
          message: 'Order has been delivered successfully to customer doorstep.',
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF0F7645),
          iconBg: const Color(0xFFE8F7EE),
          customContent: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Order', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    Text(
                      order.shortId,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F7645)),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Customer', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    Text(
                      '${order.data['customer_name'] ?? 'Customer'}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                if (order.paymentStatus == 'cod') ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cash Collected', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      Text(
                        money(order.total),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F7645)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          buttonText: 'Back to Deliveries',
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showStoreError(context, e);
      if (mounted) await _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My delivery'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loadError != null
        ? EmptyPanel(
            icon: Icons.lock_outline,
            title: 'Delivery unavailable',
            message: _loadError!,
            action: 'Refresh assigned delivery',
            onAction: _reload,
          )
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Delivery ${_order.shortId}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(_order.status),
                  StatusChip(_order.paymentStatus),
                ],
              ),
              const SizedBox(height: 18),
              CodPaymentCard(order: _order),
              const SizedBox(height: 18),
              OrderJourney(order: _order),
              if (_order.status == 'Out for Delivery') ...[
                ListenableBuilder(
                  listenable: ref.watch(deliveryTrackerProvider),
                  builder: (context, _) {
                    final tracker = ref.read(deliveryTrackerProvider);
                    final active = tracker.orders.contains(_order.id);
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          active
                              ? Icons.my_location
                              : Icons.location_off_outlined,
                          color: storeGreen,
                        ),
                        title: Text(
                          active
                              ? 'Trip location sharing is on'
                              : 'Share this delivery trip',
                        ),
                        subtitle: Text(
                          tracker.error ?? 'Share only during an active delivery. Android uses a visible trip notification. iOS/web need the app open.',
                        ),
                        trailing: active
                            ? null
                            : IconButton(
                                icon: Icon(Icons.play_circle_outline),
                                onPressed: () async {
                                  try {
                                    await tracker.start(_order);
                                  } catch (e) {
                                    if (context.mounted) {
                                      showStoreError(context, e);
                                    }
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
                DeliveryTrackingCard(orderId: _order.id, employee: true),
              ],
              // Modern Zomato / Rapido Style Action Hub
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDDE8E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE9F8EF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_pin_circle_rounded,
                            color: Color(0xFF16A05D),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_order.data['customer_name']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF15211A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_order.data['customer_phone']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF69756F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF16A05D),
                          ),
                          icon: const Icon(
                            Icons.call_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => openDeliveryLink(
                            context,
                            Uri(
                              scheme: 'tel',
                              path: '${_order.data['customer_phone']}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      '${_order.data['delivery_address']}',
                      style: const TextStyle(
                        height: 1.5,
                        fontSize: 13.5,
                        color: Color(0xFF15211A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Zomato/Rapido Google Maps Turn-by-Turn Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.directions_bike_rounded,
                          size: 22,
                        ),
                        label: const Text(
                          'Turn-by-Turn GPS Navigation',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => openDeliveryLink(
                          context,
                          directionsForOrder(_order),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final item in _order.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(productLabel(item)),
                  subtitle: Text('${item['quantity']} × ${item['unit']}'),
                  trailing: Text(money(amount(item['total_price']))),
                ),
              const SizedBox(height: 18),
              if (['Packed', 'Delivery Attempted'].contains(_order.status))
                FilledButton.icon(
                  onPressed: _busy ? null : () => _action('Out for Delivery'),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text(
                    _order.status == 'Packed'
                        ? 'Pick up & start delivery'
                        : 'Retry assigned delivery',
                  ),
                ),
              if (_order.status == 'Out for Delivery') ...[
                FilledButton.icon(
                  onPressed: _busy ? null : () => _action('Delivered'),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Verify customer code & collect cash'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : () => _action('Delivery Attempted'),
                  child: const Text('Delivery could not be completed'),
                ),
              ],
              if (['New', 'Preparing'].contains(_order.status))
                const Text(
                  'Your store is preparing this order. Pick up is available after packing is complete.',
                ),
              if (_order.paymentStatus == 'collected')
                Text(
                  _order.data['cash_handover'] == null &&
                          _order.data['cash_received_directly'] != true
                      ? 'Cash received. Hand this amount over to your store administrator.'
                      : 'Cash handover acknowledged by your store.',
                  style: const TextStyle(color: storeGreen, height: 1.6),
                ),
              const SizedBox(height: 24),
              const Text(
                'Delivery activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              for (final event in _order.events)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${event['status']}'),
                  subtitle: Text('${event['note']}'),
                ),
            ],
          ),
  );
}
