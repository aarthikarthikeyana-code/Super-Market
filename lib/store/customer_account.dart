import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'state.dart';
import 'models.dart';
import 'widgets.dart';
import 'paged_feed.dart';

import 'login_screen.dart';
import 'api.dart';
import 'delivery_tracking.dart';

class DeliveryAddressData extends ChangeNotifier {
  final line1 = TextEditingController(),
      line2 = TextEditingController(),
      pincode = TextEditingController(),
      city = TextEditingController(),
      state = TextEditingController(),
      landmark = TextEditingController();
  LatLng? pin;
  double? accuracy;
  String source = 'map', legacy = '';
  bool restoring = false, dirty = false, savedPin = false;
  Map<String, dynamic> get value => {
    'address_line1': line1.text.trim(),
    'address_line2': line2.text.trim(),
    'pincode': pincode.text.trim(),
    'city': city.text.trim(),
    'state': state.text.trim(),
    'landmark': landmark.text.trim(),
    if (pin != null) ...{
      'latitude': pin!.latitude.toStringAsFixed(6),
      'longitude': pin!.longitude.toStringAsFixed(6),
      'location_source': source,
      if (accuracy != null) 'location_accuracy': accuracy,
    },
  };
  String get formatted => [
    line1.text.trim(),
    if (line2.text.trim().isNotEmpty) line2.text.trim(),
    'Landmark: ${landmark.text.trim()}',
    city.text.trim(),
    state.text.trim(),
    pincode.text.trim(),
  ].where((s) => s.isNotEmpty).join(', ');
  void restore(Map<String, dynamic> profile) {
    if (dirty) return;
    restoring = true;
    final details = Map<String, dynamic>.from(profile['address_details'] ?? {});
    legacy = details.isEmpty ? '${profile['address'] ?? ''}' : '';
    line1.text = '${details['address_line1'] ?? legacy}';
    line2.text = '${details['address_line2'] ?? ''}';
    pincode.text = '${details['pincode'] ?? ''}';
    city.text = '${details['city'] ?? ''}';
    state.text = '${details['state'] ?? ''}';
    landmark.text = '${details['landmark'] ?? ''}';
    final lat = double.tryParse('${details['latitude']}'),
        lng = double.tryParse('${details['longitude']}');
    pin = lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180
        ? LatLng(lat, lng)
        : null;
    accuracy = double.tryParse('${details['location_accuracy']}');
    source = '${details['location_source'] ?? 'map'}';
    savedPin = pin != null;
    restoring = false;
    notifyListeners();
  }

  void edited() {
    dirty = true;
    if (savedPin) {
      pin = null;
      accuracy = null;
      savedPin = false;
      notifyListeners();
    }
  }

  void setPin(LatLng point, {double? accuracy, String source = 'map'}) {
    pin = point;
    this.accuracy = accuracy;
    this.source = source;
    savedPin = false;
    dirty = true;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in [line1, line2, pincode, city, state, landmark]) {
      c.dispose();
    }
    super.dispose();
  }
}

class StructuredAddressFields extends ConsumerStatefulWidget {
  final DeliveryAddressData address;
  final bool enabled;
  const StructuredAddressFields({
    super.key,
    required this.address,
    this.enabled = true,
  });
  @override
  ConsumerState<StructuredAddressFields> createState() =>
      _StructuredAddressFieldsState();
}

class _StructuredAddressFieldsState
    extends ConsumerState<StructuredAddressFields> {
  Timer? _debounce;
  int _generation = 0;
  bool _looking = false, _locating = false;
  String? _postalHint, _notFound;
  List<String> _offices = [];
  DeliveryAddressData get a => widget.address;
  @override
  void initState() {
    super.initState();
    a.addListener(_changed);
    a.pincode.addListener(_queue);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _queue() {
    if (a.restoring) return;
    _generation++;
    _debounce?.cancel();
    setState(() {
      _notFound = null;
      _postalHint = null;
      _offices = [];
      _looking = false;
    });
    final pin = a.pincode.text.trim();
    if (RegExp(r'^[1-9][0-9]{5}$').hasMatch(pin)) {
      _debounce = Timer(const Duration(milliseconds: 400), () => _lookup(pin));
    }
  }

  Future<void> _lookup(String pincode) async {
    final generation = ++_generation;
    final oldCity = a.city.text, oldState = a.state.text;
    setState(() => _looking = true);
    try {
      final result = await ref.read(storeApiProvider).lookupPincode(pincode);
      if (!mounted ||
          generation != _generation ||
          a.pincode.text.trim() != pincode) {
        return;
      }
      if (result['matched'] == true) {
        if (a.city.text == oldCity) a.city.text = '${result['district'] ?? ''}';
        if (a.state.text == oldState) a.state.text = '${result['state'] ?? ''}';
        setState(() {
          _offices = List<String>.from(result['offices'] ?? []);
          _postalHint =
              'Postal district and state filled. Check or edit your city/town.';
        });
      } else {
        setState(() => _notFound = pincode);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _postalHint =
              'PIN lookup is unavailable. Enter city/town and state manually.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _looking = false);
      }
    }
  }

  Future<void> _locate() async {
    if (_locating || !widget.enabled) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StoreException(
          'Turn on device location, or choose your delivery pin on the map.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StoreException(
          'Location permission was not granted. You can select a pin on the map or enter the address manually.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      if (position.isMocked || position.accuracy > 1000) {
        throw StoreException(
          'The GPS fix is not accurate enough. Choose your exact delivery point on the map.',
        );
      }
      await _choosePin(
        candidate: LatLng(position.latitude, position.longitude),
        candidateAccuracy: position.accuracy,
        candidateSource: 'gps',
      );
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _choosePin({
    LatLng? candidate,
    double? candidateAccuracy,
    String candidateSource = 'map',
  }) async {
    if (!widget.enabled) return;
    LatLng? selected = candidate ?? a.pin;
    final original = selected;
    final result = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * .76,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose delivery location',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Move and zoom the map. Tap your building entrance, then confirm the pin.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter:
                              original ?? const LatLng(20.5937, 78.9629),
                          initialZoom: original == null ? 4 : 17,
                          onTap: (_, point) => update(() => selected = point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: const String.fromEnvironment(
                              'MAP_TILE_URL',
                              defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            userAgentPackageName: 'com.agaram.supermarket',
                          ),
                          if (selected != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: selected!,
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: storeGreen,
                                    size: 42,
                                  ),
                                ),
                              ],
                            ),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                                onTap: () => openDeliveryLink(
                                  ctx,
                                  Uri.parse(
                                    'https://www.openstreetmap.org/copyright',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selected == null
                        ? 'No delivery pin selected yet.'
                        : 'Selected: ${selected!.latitude.toStringAsFixed(6)}, ${selected!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: selected == null
                          ? null
                          : () => Navigator.pop(ctx, selected),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm delivery pin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      final unchanged =
          original != null &&
          original.latitude == result.latitude &&
          original.longitude == result.longitude;
      a.setPin(
        result,
        accuracy: unchanged
            ? (candidate != null ? candidateAccuracy : a.accuracy)
            : null,
        source: unchanged
            ? (candidate != null ? candidateSource : a.source)
            : 'map',
      );
      // Amazon/Zomato style: automatically fetch street, area, city, pincode from pin
      _fetchAddressDetailsForPoint(result);
    }
  }

  Future<void> _fetchAddressDetailsForPoint(LatLng point) async {
    try {
      final details = await ref
          .read(storeApiProvider)
          .reverseGeocode(point.latitude, point.longitude);
      if (!mounted) return;
      if (details['line1'] != null && details['line1'].toString().isNotEmpty) {
        if (a.line1.text.trim().isEmpty) {
          a.line1.text = details['line1'].toString();
        }
      }
      if (details['line2'] != null && details['line2'].toString().isNotEmpty) {
        if (a.line2.text.trim().isEmpty) {
          a.line2.text = details['line2'].toString();
        }
      }
      if (details['city'] != null && details['city'].toString().isNotEmpty) {
        a.city.text = details['city'].toString();
      }
      if (details['state'] != null && details['state'].toString().isNotEmpty) {
        a.state.text = details['state'].toString();
      }
      if (details['pincode'] != null && details['pincode'].toString().isNotEmpty) {
        a.pincode.text = details['pincode'].toString();
      }
      if (details['landmark'] != null && details['landmark'].toString().isNotEmpty) {
        if (a.landmark.text.trim().isEmpty) {
          a.landmark.text = details['landmark'].toString();
        }
      }
      setState(() {
        _postalHint = 'Address and pincode automatically detected from GPS location.';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    a.removeListener(_changed);
    a.pincode.removeListener(_queue);
    super.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool optional = false,
    int maxLength = 200,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: widget.enabled,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        helperMaxLines: 2,
        counterText: '',
      ),
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => a.edited(),
      validator: (s) =>
          !optional && (s?.trim().length ?? 0) < (controller == a.line1 ? 3 : 2)
          ? 'Enter $label'
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery pin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                a.pin == null
                    ? 'Add a pin to help the employee find your entrance. You can also enter the address manually.'
                    : '${a.source == 'gps' ? 'GPS location' : 'Selected map pin'}${a.accuracy == null ? '' : ' · accuracy ±${a.accuracy!.round()} m'}\nCheck the pin matches your delivery address.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: !widget.enabled || _locating ? null : _locate,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: Text(
                      _locating
                          ? 'Finding location...'
                          : 'Use current location',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: !widget.enabled || _locating ? null : _choosePin,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(a.pin == null ? 'Select on map' : 'Adjust pin'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      if (a.legacy.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            'Your saved address uses the earlier format. Confirm the separate fields below.\n${a.legacy}',
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ),
      _field(a.line1, 'Address 1', hint: 'House / flat number and street'),
      _field(
        a.line2,
        'Address 2 (optional)',
        hint: 'Apartment, building or area',
        optional: true,
      ),
      TextFormField(
        controller: a.pincode,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Pincode',
          helperText: _looking ? 'Looking up city and state...' : _postalHint,
          helperMaxLines: 3,
          suffixIcon: _looking
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.local_post_office_outlined),
        ),
        onChanged: (_) => a.edited(),
        validator: (s) => !RegExp(r'^[1-9][0-9]{5}$').hasMatch(s ?? '')
            ? 'Enter a 6-digit Indian PIN'
            : _notFound == s
            ? 'PIN was not found. Check the number.'
            : null,
      ),
      if (_offices.length > 1)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: !widget.enabled
                ? null
                : () async {
                    final office = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      builder: (ctx) => SafeArea(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Choose your postal area',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            for (final office in _offices)
                              ListTile(
                                title: Text(office),
                                onTap: () => Navigator.pop(ctx, office),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (office != null && mounted) {
                      a.city.text = office;
                      a.edited();
                    }
                  },
            child: const Text('Choose a postal area for this PIN'),
          ),
        ),
      const SizedBox(height: 8),
      _field(
        a.city,
        'City / town',
        hint: 'Check the postal suggestion and edit if needed',
        maxLength: 80,
      ),
      _field(a.state, 'State', maxLength: 80),
      _field(
        a.landmark,
        'Landmark',
        hint: 'A nearby place that helps identify your building',
        maxLength: 160,
      ),
    ],
  );
}

Future<bool> ensureCustomerAccount(BuildContext context, WidgetRef ref) async {
  try {
    final account = await ref.read(customerAccountProvider.future);
    if (account != null) return true;
    if (!context.mounted) return false;
    return await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
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
  late final TextEditingController _name, _notes;
  final _deliveryAddress = DeliveryAddressData();
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile['name']);
    _deliveryAddress.restore(widget.profile);
    _notes = TextEditingController(
      text: widget.profile['delivery_instructions'],
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _deliveryAddress.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(storeApiProvider).saveCustomerProfile({
        'name': _name.text.trim(),
        'address': _deliveryAddress.formatted,
        'address_details': _deliveryAddress.value,
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
              StructuredAddressFields(
                address: _deliveryAddress,
                enabled: !_busy,
              ),
              TextFormField(
                controller: _notes,
                enabled: !_busy,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Note for delivery employee (optional)',
                  helperText:
                      'Gate access, floor, or call-on-arrival instructions.',
                  helperMaxLines: 2,
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
