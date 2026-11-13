import 'dart:async';

import 'package:dio/dio.dart';
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

class DeliveryAddressData extends ChangeNotifier {
  final line1 = TextEditingController(),
      line2 = TextEditingController(),
      pincode = TextEditingController(),
      city = TextEditingController(),
      state = TextEditingController(),
      landmark = TextEditingController();
  LatLng? pin;
  double? accuracy;
  String source = 'gps', legacy = '';
  String mode = 'current'; // 'current', 'pin', 'manual'
  String detectedAddress = '';
  bool restoring = false, dirty = false, savedPin = false;

  Map<String, dynamic> get value => {
    'delivery_mode': mode,
    'detected_address': detectedAddress,
    'address_line1': mode == 'manual'
        ? line1.text.trim()
        : (line1.text.trim().isNotEmpty
            ? line1.text.trim()
            : (detectedAddress.isNotEmpty ? detectedAddress : 'Doorstep GPS delivery')),
    'address_line2': mode == 'manual' ? line2.text.trim() : line2.text.trim(),
    'pincode': (pincode.text.trim().isNotEmpty && RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode.text.trim()))
        ? pincode.text.trim()
        : '636001',
    'city': city.text.trim().isNotEmpty ? city.text.trim() : 'Salem',
    'state': state.text.trim().isNotEmpty ? state.text.trim() : 'Tamil Nadu',
    'landmark': landmark.text.trim().isNotEmpty
        ? landmark.text.trim()
        : (detectedAddress.isNotEmpty ? detectedAddress : 'Near delivery location'),
    if (pin != null) ...{
      'latitude': pin!.latitude.toStringAsFixed(6),
      'longitude': pin!.longitude.toStringAsFixed(6),
      'location_source': source,
      if (accuracy != null) 'location_accuracy': accuracy,
    },
  };

  String get formatted {
    if (mode != 'manual' && detectedAddress.isNotEmpty) {
      return '📍 $detectedAddress';
    }
    return [
      line1.text.trim(),
      if (line2.text.trim().isNotEmpty) line2.text.trim(),
      if (landmark.text.trim().isNotEmpty) 'Landmark: ${landmark.text.trim()}',
      city.text.trim(),
      state.text.trim(),
      pincode.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
  }
  void restore(Map<String, dynamic> profile) {
    if (dirty) return;
    restoring = true;
    final details = Map<String, dynamic>.from(profile['address_details'] ?? {});
    mode = '${details['delivery_mode'] ?? (details['latitude'] != null ? 'pin' : (details['address_line1'] != null && details['address_line1'].toString().trim().isNotEmpty ? 'manual' : 'current'))}';
    detectedAddress = '${details['detected_address'] ?? ''}';
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
    final LatLng startPoint = candidate ?? a.pin ?? const LatLng(11.6643, 78.1460);
    final original = a.pin;

    final result = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ZomatoLocationPickerModal(
        initialPoint: startPoint,
        api: ref.read(storeApiProvider),
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
      setState(() {
        a.mode = (candidateSource == 'gps') ? 'current' : 'pin';
        a.dirty = true;
      });
      // Amazon/Zomato style: automatically fetch street, area, city, pincode from pin
      _fetchAddressDetailsForPoint(result);
    }
  }

  Future<String?> _refineIndianPincode(List<String> localities, String city) async {
    final dio = Dio();
    for (final loc in localities) {
      if (loc.trim().length < 3) continue;
      final parts = loc
          .split(RegExp(r'[,-/]'))
          .map((s) => s.trim())
          .where((s) => s.length >= 3 && !RegExp(r'^\d+$').hasMatch(s));
      for (final part in parts) {
        try {
          final res = await dio.get(
            'https://api.postalpincode.in/postoffice/${Uri.encodeComponent(part)}',
            options: Options(receiveTimeout: const Duration(milliseconds: 2500)),
          );
          if (res.statusCode == 200 && res.data is List && (res.data as List).isNotEmpty) {
            final entry = (res.data as List)[0];
            if (entry is Map && entry['Status'] == 'Success' && entry['PostOffice'] is List) {
              final poList = entry['PostOffice'] as List;
              final targetCity = city.trim().toLowerCase();
              for (final po in poList) {
                if (po is Map) {
                  final poDist = (po['District'] ?? '').toString().toLowerCase();
                  if (targetCity.isEmpty || targetCity.contains(poDist) || poDist.contains(targetCity)) {
                    final pin = po['Pincode']?.toString();
                    if (pin != null && RegExp(r'^[1-9][0-9]{5}$').hasMatch(pin)) {
                      return pin;
                    }
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> _fetchAddressDetailsForPoint(LatLng point) async {
    try {
      final details = await ref
          .read(storeApiProvider)
          .reverseGeocode(point.latitude, point.longitude);
      if (!mounted) return;
      final l1 = '${details['line1'] ?? ''}'.trim();
      final l2 = '${details['line2'] ?? ''}'.trim();
      final fullLoc = [l1, l2].where((s) => s.isNotEmpty).join(', ');
      if (fullLoc.isNotEmpty) {
        a.detectedAddress = fullLoc;
      }
      if (l1.isNotEmpty) {
        a.line1.text = l1;
      }
      if (l2.isNotEmpty) {
        a.line2.text = l2;
      }
      final cityName = details['city']?.toString() ?? '';
      if (cityName.isNotEmpty) {
        a.city.text = cityName;
      }
      if (details['state'] != null && details['state'].toString().isNotEmpty) {
        a.state.text = details['state'].toString();
      }
      if (details['landmark'] != null && details['landmark'].toString().isNotEmpty) {
        if (a.landmark.text.trim().isEmpty) {
          a.landmark.text = details['landmark'].toString();
        }
      }

      // Check authoritative India Post PIN if locality is known (e.g., Mamangam -> 636302)
      String? finalPin = details['pincode']?.toString();
      final candidateLocalities = [l2, l1].where((s) => s.isNotEmpty).toList();
      final refined = await _refineIndianPincode(
        candidateLocalities,
        a.city.text.isNotEmpty ? a.city.text : cityName,
      );
      if (refined != null && refined.isNotEmpty) {
        finalPin = refined;
      }
      if (finalPin != null && finalPin.isNotEmpty) {
        a.pincode.text = finalPin;
      }

      setState(() {
        _postalHint = 'Address and pincode automatically detected from location.';
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
  Widget build(BuildContext context) {
    final hasPin = a.pin != null;
    final isManual = a.mode == 'manual';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Professional Modern Delivery Selection Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F7645).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF0F7645),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Select your location for fast, accurate delivery',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3-Way Segmented Mode Buttons: [GPS Location] [Set on Map] [Type Address]
              Row(
                children: [
                  Expanded(
                    child: _modeButton(
                      title: 'GPS',
                      subtitle: 'Auto-detect',
                      icon: Icons.gps_fixed_rounded,
                      iconColor: const Color(0xFF0F7645),
                      iconBg: const Color(0xFFE8F7EE),
                      selected: a.mode == 'current',
                      isLoading: _locating,
                      onTap: () {
                        setState(() => a.mode = 'current');
                        _locate();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modeButton(
                      title: 'Set on Map',
                      subtitle: 'Drag pin',
                      icon: Icons.pin_drop_rounded,
                      iconColor: const Color(0xFF4F46E5),
                      iconBg: const Color(0xFFEEF2FF),
                      selected: a.mode == 'pin',
                      onTap: () {
                        setState(() => a.mode = 'pin');
                        _choosePin();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modeButton(
                      title: 'Manual',
                      subtitle: 'Type address',
                      icon: Icons.home_rounded,
                      iconColor: const Color(0xFFEA580C),
                      iconBg: const Color(0xFFFFF7ED),
                      selected: a.mode == 'manual',
                      onTap: () {
                        setState(() {
                          a.mode = 'manual';
                          a.dirty = true;
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Active Location Card (Shown when Current Location or Pin is active)
              if (!isManual) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasPin ? const Color(0xFFC7EBD4) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        hasPin ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: hasPin ? const Color(0xFF0F7645) : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasPin
                                  ? (a.mode == 'current'
                                      ? 'GPS Location Selected'
                                      : 'Pin Location Confirmed')
                                  : 'Tap "Current" or "Adjust Pin" to set location',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: hasPin ? const Color(0xFF0F7645) : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.detectedAddress.isNotEmpty
                                  ? a.detectedAddress
                                  : (hasPin
                                      ? '${a.pin!.latitude.toStringAsFixed(5)}, ${a.pin!.longitude.toStringAsFixed(5)}'
                                      : 'Address 1 & 2 are automatically detected from your map point.'),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ONLY SHOW MANUAL INPUT FIELDS (ADDRESS, PINCODE, CITY) WHEN USER CHOOSES MANUAL MODE
        if (isManual) ...[
          _field(a.line1, 'Address 1', hint: 'House / flat number and street'),
          _field(
            a.line2,
            'Address 2 (optional)',
            hint: 'Apartment, building or area',
            optional: true,
          ),
          // Pincode with lookup (Manual mode only)
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
            optional: true,
          ),
        ],
      ],
    );
  }

  Widget _modeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool selected,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled && !isLoading ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0F7645) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFF0F7645) : const Color(0xFFE2E8F0),
              width: selected ? 1.8 : 1.2,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: const Color(0xFF0F7645).withOpacity(0.24),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.22) : iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          icon,
                          size: 20,
                          color: selected ? Colors.white : iconColor,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white.withOpacity(0.85) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ZomatoLocationPickerModal extends StatefulWidget {
  final LatLng initialPoint;
  final StoreApi api;

  const ZomatoLocationPickerModal({
    super.key,
    required this.initialPoint,
    required this.api,
  });

  @override
  State<ZomatoLocationPickerModal> createState() => _ZomatoLocationPickerModalState();
}

class _ZomatoLocationPickerModalState extends State<ZomatoLocationPickerModal> {
  late final MapController _mapController;
  late LatLng _currentCenter;
  String _areaTitle = 'Locating address...';
  String _subAddress = 'Move the map to set your exact location';
  bool _isLocatingGps = false;
  bool _isDragging = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.initialPoint;
    _lookupAddress(_currentCenter);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _currentCenter = camera.center;
    if (hasGesture) {
      if (!_isDragging) {
        setState(() {
          _isDragging = true;
          _areaTitle = 'Locating address...';
        });
      }
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 380), () {
        if (mounted) {
          setState(() => _isDragging = false);
          _lookupAddress(_currentCenter);
        }
      });
    }
  }

  Future<void> _lookupAddress(LatLng point) async {
    try {
      final details = await widget.api.reverseGeocode(point.latitude, point.longitude);
      if (!mounted) return;
      final l1 = '${details['line1'] ?? ''}'.trim();
      final l2 = '${details['line2'] ?? ''}'.trim();
      final city = '${details['city'] ?? ''}'.trim();
      final state = '${details['state'] ?? ''}'.trim();
      final pin = '${details['pincode'] ?? ''}'.trim();

      String title = l2.isNotEmpty ? l2 : (l1.isNotEmpty ? l1 : (city.isNotEmpty ? city : 'Selected Location'));
      String subtitle = [l1, l2, city, state, pin].where((s) => s.isNotEmpty && s != title).join(', ');

      setState(() {
        _areaTitle = title;
        _subAddress = subtitle.isNotEmpty
            ? subtitle
            : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _areaTitle = 'Selected Location';
          _subAddress = '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        });
      }
    }
  }

  Future<void> _locateMe() async {
    if (_isLocatingGps) return;
    setState(() => _isLocatingGps = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StoreException('Please enable location on your device.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw StoreException('Location permission was denied.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final newPoint = LatLng(pos.latitude, pos.longitude);
      _mapController.move(newPoint, 17.5);
      _currentCenter = newPoint;
      _lookupAddress(newPoint);
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Modern CartoDB Voyager Map (Zomato / Rapido style)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 17.0,
              minZoom: 4,
              maxZoom: 19,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'com.agaram.supermarket',
              ),
            ],
          ),

          // 2. Top Floating Header Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: const CircleBorder(),
                  color: Colors.white,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.near_me_rounded, color: Color(0xFF0F7645), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Drag map to position pin',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Center Fixed Floating Pin (Zomato / Rapido interactive style)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tooltip badge
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Order will be delivered here',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated Pin
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.translationValues(0, _isDragging ? -12 : 0, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE23744), Color(0xFFC61C2C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE23744).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shopping_bag_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -6),
                        child: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Color(0xFFC61C2C),
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                // Ground dot shadow
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _isDragging ? 8 : 12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(_isDragging ? 0.15 : 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // 4. Floating GPS Re-center Button
          Positioned(
            right: 16,
            bottom: 215,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _locateMe,
                child: Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(12),
                  child: _isLocatingGps
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0F7645),
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF0F7645),
                          size: 24,
                        ),
                ),
              ),
            ),
          ),

          // 5. Zomato Bottom Delivery Confirmation Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F7EE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF0F7645),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _areaTitle,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _subAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F7645),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, _currentCenter),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirm Location',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    final confirmed = change
        ? await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Change your mobile number?'),
              content: const Text(
                'Saved addresses and orders stay with this mobile number.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Change number'),
                ),
              ],
            ),
          )
        : await showLogoutConfirmationDialog(context);
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
      if (change) {
        await ensureCustomerAccount(context, ref);
      } else {
        showLogoutSuccessSnackBar(context);
      }
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
