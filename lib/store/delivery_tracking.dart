import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'models.dart';
import 'state.dart';
import 'widgets.dart';

Future<void> openDeliveryLink(BuildContext context, Uri uri) async {
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StoreException(
        'Could not open this link. Check that a suitable app is installed.',
      );
    }
  } catch (e) {
    if (context.mounted) showStoreError(context, e);
  }
}

Uri directionsTo(String address) => Uri.https('www.google.com', '/maps/dir/', {
  'api': '1',
  'destination': address,
  'travelmode': 'driving',
});

Uri directionsForOrder(StoreOrder order) {
  final address = order.data['address_details'] as Map?;
  final lat = double.tryParse('${address?['latitude']}'),
      lng = double.tryParse('${address?['longitude']}');
  return directionsTo(
    lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180
        ? '$lat,$lng'
        : '${order.data['delivery_address']}',
  );
}

final deliveryTrackerProvider = Provider<DeliveryTracker>((ref) {
  final tracker = DeliveryTracker(ref.read(storeApiProvider));
  ref.onDispose(tracker.dispose);
  return tracker;
});

class DeliveryTracker extends ChangeNotifier {
  final StoreApi api;
  final Set<String> orders = {};
  StreamSubscription<Position>? _stream;
  Timer? _heartbeat;
  Position? _position;
  bool _sending = false, _sampling = false, _disposed = false;
  DateTime? lastSent;
  String? error;
  DeliveryTracker(this.api) {
    api.staffChanges.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    if (api.deliveryToken == null) stop();
  }

  Future<void> ensureLocationPermission({bool request = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StoreException(
        'Turn on device location to share your delivery trip.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StoreException(
        'Location permission is needed for trip sharing. Enable it in app settings, then tap Share trip location.',
      );
    }
  }

  bool _syncing = false;
  Future<void> syncActiveTrips() async {
    if (_disposed || _syncing || api.deliveryToken == null) return;
    _syncing = true;
    final token = api.deliveryToken;
    final trackedAtStart = orders.toSet();
    try {
      final active = <StoreOrder>[];
      String? cursor;
      final seen = <String>{};
      do {
        final page = await api.orderPage(
          employee: true,
          status: 'Out for Delivery',
          cursor: cursor,
        );
        if (_disposed || api.deliveryToken != token) return;
        active.addAll(
          page.items.where((order) => order.status == 'Out for Delivery'),
        );
        cursor = page.nextCursor;
      } while (cursor != null && seen.add(cursor));
      final ids = active.map((order) => order.id).toSet();
      for (final id in trackedAtStart) {
        if (!ids.contains(id)) finish(id);
      }
      for (final order in active) {
        if (!orders.contains(order.id)) {
          await start(order, requestPermission: false);
        }
      }
      if (active.isEmpty && error != null) {
        error = null;
        _notify();
      }
    } catch (_) {
      if (!_disposed && api.deliveryToken == token) {
        error = 'Live tracking needs location permission and a connection. Open your active delivery to retry.';
        _notify();
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> start(StoreOrder order, {bool requestPermission = true}) async {
    if (order.status != 'Out for Delivery' || orders.contains(order.id)) return;
    final token = api.deliveryToken;
    await ensureLocationPermission(request: requestPermission);
    if (_disposed || token == null || api.deliveryToken != token) return;
    orders.add(order.id);
    error = null;
    if (_stream == null) {
      final LocationSettings settings =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
              intervalDuration: const Duration(seconds: 5),
              foregroundNotificationConfig: const ForegroundNotificationConfig(
                notificationTitle: 'Agaram delivery in progress',
                notificationText: 'Sharing location for active deliveries. Stops when each delivery closes.',
                enableWakeLock: true,
              ),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            );
      _stream = Geolocator.getPositionStream(locationSettings: settings).listen(
        (position) {
          _position = position;
          error = null;
          _publish();
        },
        onError: (Object e) {
          error = 'GPS unavailable. Check location permission and keep the app running.';
          _notify();
        },
      );
      _heartbeat = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _sampleAndPublish(),
      );
    }
    _notify();
    _sampleAndPublish();
  }

  Future<void> _sampleAndPublish() async {
    if (_disposed || _sampling || orders.isEmpty || api.deliveryToken == null) {
      return;
    }
    _sampling = true;
    try {
      if (_position == null ||
          DateTime.now().difference(_position!.timestamp).inSeconds > 10) {
        final fresh = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        if (_disposed || orders.isEmpty || api.deliveryToken == null) return;
        _position = fresh;
      }
      await _publish();
    } catch (_) {
      error = 'Waiting for a fresh GPS fix. Check device location and keep the trip running.';
      _notify();
    } finally {
      _sampling = false;
    }
  }

  Future<void> _publish() async {
    final position = _position;
    if (_disposed ||
        _sending ||
        position == null ||
        orders.isEmpty ||
        api.deliveryToken == null) {
      return;
    }
    if (position.isMocked ||
        position.accuracy > 1000 ||
        DateTime.now().difference(position.timestamp).inSeconds.abs() > 110) {
      error = 'Waiting for a fresh, accurate device location.';
      _notify();
      return;
    }
    if (lastSent != null &&
        DateTime.now().difference(lastSent!).inSeconds < 5) {
      return;
    }
    _sending = true;
    try {
      for (final id in orders.toList()) {
        if (!orders.contains(id) || api.deliveryToken == null) continue;
        try {
          await api.shareDeliveryLocation(id, {
            'latitude': position.latitude.toStringAsFixed(6),
            'longitude': position.longitude.toStringAsFixed(6),
            'accuracy': position.accuracy,
            'captured_at': position.timestamp.toUtc().toIso8601String(),
          });
          lastSent = DateTime.now();
          error = null;
        } catch (e) {
          if (e is StoreException && [401, 403, 404].contains(e.statusCode)) {
            finish(id);
            continue;
          }
          error = 'Location update not sent. Check your connection; the map shows the last received fix.';
          // Recheck server status: completed, returned and reassigned trips must stop.
          try {
            final current = await api.deliveryOrder(id);
            if (current.status != 'Out for Delivery') finish(id);
          } catch (e) {
            if (e is StoreException && [401, 403, 404].contains(e.statusCode)) {
              finish(id);
            }
          }
        }
      }
    } finally {
      _sending = false;
      _notify();
    }
  }

  void finish(String id) {
    orders.remove(id);
    if (orders.isEmpty) {
      stop();
    } else {
      _notify();
    }
  }

  void stop() {
    orders.clear();
    _stream?.cancel();
    _stream = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _position = null;
    lastSent = null;
    error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    api.staffChanges.removeListener(_sessionChanged);
    stop();
    super.dispose();
  }
}

LatLng? _trackingCoordinate(dynamic value) {
  if (value is! Map) return null;
  final latitude = double.tryParse('${value['latitude']}');
  final longitude = double.tryParse('${value['longitude']}');
  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180) {
    return null;
  }
  return LatLng(latitude, longitude);
}

class DeliveryTrackingCard extends ConsumerStatefulWidget {
  final String orderId;
  final bool admin, employee;
  const DeliveryTrackingCard({
    super.key,
    required this.orderId,
    this.admin = false,
    this.employee = false,
  });
  @override
  ConsumerState<DeliveryTrackingCard> createState() =>
      _DeliveryTrackingCardState();
}

class _DeliveryTrackingCardState extends ConsumerState<DeliveryTrackingCard> {
  Timer? _timer;
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final data = await ref
          .read(storeApiProvider)
          .deliveryTracking(
            widget.orderId,
            admin: widget.admin,
            employee: widget.employee,
          );
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not refresh trip location.');
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawPoints = _data?['points'];
    final points = [
      if (rawPoints is List)
        for (final point in rawPoints)
          if (_trackingCoordinate(point) != null) point as Map,
    ];
    final locations = points
        .map((point) => _trackingCoordinate(point)!)
        .toList();
    final stale = _data?['stale'] != false || _error != null;
    final home = _trackingCoordinate(_data?['destination']);
    final mapPoints = <LatLng>[...locations, ?home];
    final canFitBounds =
        mapPoints.length >= 2 &&
        mapPoints.any(
          (point) =>
              point.latitude != mapPoints.first.latitude ||
              point.longitude != mapPoints.first.longitude,
        );
    final last = points.isEmpty ? null : points.last;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              Icons.route,
              color: stale ? Colors.orange.shade800 : storeGreen,
            ),
            title: const Text(
              'Delivery trip',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              _error ??
                  (locations.isEmpty
                      ? 'Waiting for the employee to share device location.'
                      : '${_data?['active'] == true ? (stale ? 'Last known location' : 'Recent location') : 'Recorded trip'} · ${DateTime.tryParse('${last?['captured_at']}')?.toLocal().toString().split('.').first ?? ''}'),
            ),
            trailing: IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ),
          if (mapPoints.isNotEmpty) ...[
            SizedBox(
              height: 220,
              child: FlutterMap(
                key: ValueKey(
                  '${widget.orderId}:${mapPoints.first}:${mapPoints.last}',
                ),
                options: MapOptions(
                  initialCenter: locations.isNotEmpty ? locations.last : home!,
                  initialZoom: 15,
                  initialCameraFit: canFitBounds
                      ? CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(mapPoints),
                          padding: const EdgeInsets.all(35),
                          maxZoom: 16,
                        )
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: const String.fromEnvironment(
                      'MAP_TILE_URL',
                      defaultValue:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    userAgentPackageName: 'com.agaram.supermarket',
                  ),
                  if (locations.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: locations,
                          strokeWidth: 4,
                          color: storeGreen,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (locations.isNotEmpty)
                        Marker(
                          point: locations.first,
                          width: 32,
                          height: 32,
                          child: const Icon(
                            Icons.flag_circle,
                            color: storeGreen,
                            size: 30,
                          ),
                        ),
                      if (locations.isNotEmpty)
                        Marker(
                          point: locations.last,
                          width: 42,
                          height: 42,
                          child: const CircleAvatar(
                            backgroundColor: storeGreen,
                            child: Icon(
                              Icons.two_wheeler_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (home != null)
                        Marker(
                          point: home,
                          width: 38,
                          height: 38,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFD94A4A),
                            size: 36,
                          ),
                        ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => openDeliveryLink(
                          context,
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (last != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Recorded GPS fixes · accuracy ±${(last['accuracy'] as num?)?.round() ?? '?'} m. The line connects recorded fixes.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            TextButton.icon(
              onPressed: () => openDeliveryLink(
                context,
                Uri.https('www.google.com', '/maps/search/', {
                  'api': '1',
                  'query':
                      '${mapPoints.last.latitude},${mapPoints.last.longitude}',
                }),
              ),
              icon: const Icon(Icons.map_outlined),
              label: Text(
                home != null
                    ? 'View delivery pin in Google Maps'
                    : 'View employee location in Google Maps',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
