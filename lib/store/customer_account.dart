import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state.dart';
import 'models.dart';
import 'widgets.dart';
import 'paged_feed.dart';

Future<bool> ensureCustomerAccount(BuildContext context, WidgetRef ref) async {
  try {
    final account = await ref.read(customerAccountProvider.future);
    if (account != null) return true;
    if (!context.mounted) return false;
    return await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const CustomerPhoneSignInScreen()),
        ) ==
        true;
  } catch (e) {
    if (context.mounted) showStoreError(context, e);
    return false;
  }
}

class CustomerPhoneSignInScreen extends ConsumerStatefulWidget {
  const CustomerPhoneSignInScreen({super.key});
  @override
  ConsumerState<CustomerPhoneSignInScreen> createState() => _PhoneSignInState();
}

class _PhoneSignInState extends ConsumerState<CustomerPhoneSignInScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  Map<String, dynamic>? _challenge;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(storeApiProvider);
      if (_challenge == null) {
        final challenge = await api.requestCustomerCode(_phone.text);
        if (mounted) setState(() => _challenge = challenge);
        return;
      }
      await api.verifyCustomerCode(_challenge!['challenge_id'], _code.text);
      if (!mounted) return;
      ref.invalidate(customerAccountProvider);
      ref.invalidate(customerProfileProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(wishlistProvider);
      ref.invalidate(wishlistIdsProvider);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Theme(
      data: storeTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Your mobile number')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: storeGreen,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Make yourself at home.',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Continue with your mobile number to save your delivery address and keep track of your orders.',
                      style: TextStyle(height: 1.6, color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _phone,
                      enabled: !_busy && _challenge == null,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational,
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        prefixText: '+91 ',
                        hintText: '10-digit mobile number',
                      ),
                      validator: (v) =>
                          RegExp(r'^[6-9][0-9]{9}$').hasMatch(v ?? '')
                          ? null
                          : 'Enter a valid 10-digit mobile number',
                      onFieldSubmitted: (_) => _continue(),
                    ),
                    if (_challenge != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F1E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DEMO VERIFICATION',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: storeGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_challenge!['demo_code']}',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter this code below. Valid for 5 minutes. This is a test code displayed here; no SMS is sent.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _code,
                        autofocus: true,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        decoration: const InputDecoration(
                          labelText: '5-digit verification code',
                        ),
                        validator: (v) =>
                            RegExp(r'^[0-9]{5}$').hasMatch(v ?? '')
                            ? null
                            : 'Enter the 5-digit code shown above',
                        onFieldSubmitted: (_) => _continue(),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _challenge = null;
                                _code.clear();
                                _error = null;
                                _form.currentState?.reset();
                              }),
                        child: const Text('Change number / request a new code'),
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _continue,
                        child: Text(
                          _busy
                              ? 'Please wait...'
                              : _challenge == null
                              ? 'Get demo code'
                              : 'Verify & sign in',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'You will stay signed in until you log out or change your number.',
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class CustomerWishlistScreen extends ConsumerStatefulWidget {
  const CustomerWishlistScreen({super.key});
  @override
  ConsumerState<CustomerWishlistScreen> createState() => _WishlistState();
}

class _WishlistState extends ConsumerState<CustomerWishlistScreen> {
  final Set<String> _busy = {};
  Future<void> _remove(String id) async {
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      await ref.read(storeApiProvider).setWishlist(id, false);
      ref.invalidate(wishlistProvider);
      ref.invalidate(wishlistIdsProvider);
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My wishlist')),
    body: PagedFeed<StoreProduct>(
      queryKey: (
        'wishlist',
        ref.watch(customerAccountProvider).asData?.value?['phone'],
      ),
      changes: ref.watch(storeApiProvider).feedChanges,
      load: ref.read(storeApiProvider).wishlistPage,
      identity: (p) => p.id,
      emptyTitle: 'Save your favourites',
      emptyMessage: 'Tap the heart on a product to keep it here for later.',
      itemBuilder: (_, product, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: ProductPhoto(product.imageUrl, height: 80),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text('${money(product.price)} / ${product.unit}'),
                      TextButton.icon(
                        onPressed: !product.available
                            ? null
                            : () async {
                                if (await ensureCustomerAccount(context, ref) &&
                                    mounted) {
                                  ref
                                      .read(storeCartProvider.notifier)
                                      .add(product);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to cart'),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: Text(
                          product.available ? 'Add to cart' : 'Out of stock',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove from wishlist',
                  onPressed: _busy.contains(product.id)
                      ? null
                      : () => _remove(product.id),
                  icon: const Icon(Icons.favorite, color: storeGreen),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class CustomerAccountScreen extends ConsumerStatefulWidget {
  const CustomerAccountScreen({super.key});
  @override
  ConsumerState<CustomerAccountScreen> createState() => _CustomerAccountState();
}

class _CustomerAccountState extends ConsumerState<CustomerAccountScreen> {
  bool _busy = false;
  Future<void> _removeNumber({bool change = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          change ? 'Change your mobile number?' : 'Log out of this account?',
        ),
        content: const Text(
          'Saved addresses and orders stay with this mobile number. This device will be signed out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(change ? 'Change number' : 'Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final cart = ref.read(storeCartProvider.notifier);
      cart.clear();
      await cart.flush();
      await ref.read(storeApiProvider).logoutCustomer();
      if (!mounted) return;
      ref.invalidate(customerAccountProvider);
      ref.invalidate(customerProfileProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(wishlistProvider);
      ref.invalidate(wishlistIdsProvider);
      ref.invalidate(storeCartProvider);
      if (change) await ensureCustomerAccount(context, ref);
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DataView(
    retainOnRefresh: false,
    value: ref.watch(customerAccountProvider),
    onRetry: () => ref.invalidate(customerAccountProvider),
    builder: (account) {
      if (account == null) {
        return EmptyPanel(
          icon: Icons.person_outline,
          title: 'Your Agaram account',
          message:
              'Save your address and see your orders with your mobile number.',
          action: 'Enter mobile number',
          onAction: () => ensureCustomerAccount(context, ref),
        );
      }
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'My account',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _removeNumber(),
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
          Expanded(
            child: DataView(
              value: ref.watch(customerProfileProvider),
              onRetry: () => ref.invalidate(customerProfileProvider),
              builder: (profile) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE5F1E9),
                        child: Icon(Icons.person, color: storeGreen),
                      ),
                      title: Text(
                        (profile['name'] as String).isEmpty
                            ? 'Your account'
                            : profile['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(profile['phone']),
                      trailing: TextButton(
                        onPressed: _busy
                            ? null
                            : () => _removeNumber(change: true),
                        child: const Text('Change'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.favorite_border,
                        color: storeGreen,
                      ),
                      title: const Text('My wishlist'),
                      subtitle: const Text(
                        'Products saved to your mobile account',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerWishlistScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Saved delivery address',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (profile['address'] as String).isEmpty
                                ? 'Add an address for your next delivery.'
                                : profile['address'],
                            style: const TextStyle(height: 1.6),
                          ),
                          if ((profile['delivery_instructions'] as String)
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                profile['delivery_instructions'],
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final saved = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CustomerAddressEditor(
                                          profile: profile,
                                        ),
                                      ),
                                    );
                                    if (saved == true && mounted) {
                                      ref.invalidate(customerProfileProvider);
                                      ref.invalidate(customerAccountProvider);
                                    }
                                  },
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(
                              (profile['address'] as String).isEmpty
                                  ? 'Add address'
                                  : 'Edit address',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your address is saved to this mobile account and will be filled in at your next checkout.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class CustomerAddressEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic> profile;
  const CustomerAddressEditor({super.key, required this.profile});
  @override
  ConsumerState<CustomerAddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends ConsumerState<CustomerAddressEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _address, _notes;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile['name']);
    _address = TextEditingController(text: widget.profile['address']);
    _notes = TextEditingController(
      text: widget.profile['delivery_instructions'],
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(storeApiProvider).saveCustomerProfile({
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'delivery_instructions': _notes.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Theme(
      data: storeTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Delivery address')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Account: ${widget.profile['phone']}',
                style: const TextStyle(
                  color: storeGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    (v?.trim().length ?? 0) < 2 ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                enabled: !_busy,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Full address, landmark and pincode',
                ),
                validator: (v) => (v?.trim().length ?? 0) < 12
                    ? 'Enter your complete delivery address'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                enabled: !_busy,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Delivery instructions (optional)',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Saving...' : 'Save address'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
