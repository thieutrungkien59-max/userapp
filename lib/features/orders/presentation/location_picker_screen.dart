import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/shipping_fee_api.dart';
import '../data/shipping_quote_model.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initialLocation,
    this.routeStartLocation,
  });

  final String title;
  final LatLng? initialLocation;

  /// Khi chọn điểm giao, truyền điểm lấy vào đây để vẽ tuyến đường bộ.
  final LatLng? routeStartLocation;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(10.7769, 106.7009);

  late LatLng selectedLocation;

  ShippingQuote? _routePreview;
  bool _loadingRoute = false;
  int _routeRequestId = 0;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation ?? _defaultCenter;

    if (widget.routeStartLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRoutePreview(selectedLocation);
      });
    }
  }

  Future<void> _loadRoutePreview(LatLng destination) async {
    final start = widget.routeStartLocation;

    if (start == null) {
      return;
    }

    final requestId = ++_routeRequestId;

    setState(() => _loadingRoute = true);

    try {
      final result = await shippingFeeApi.calculate(
        pickup: start,
        delivery: destination,
      );

      if (!mounted || requestId != _routeRequestId) return;

      setState(() {
        _routePreview = result;
        _loadingRoute = false;
      });
    } catch (_) {
      if (!mounted || requestId != _routeRequestId) return;

      setState(() {
        _routePreview = null;
        _loadingRoute = false;
      });
    }
  }

  void _confirm() {
    Navigator.of(context).pop(selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(onPressed: _confirm, child: const Text('Xác nhận')),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 15,
              onTap: (_, point) {
                setState(() => selectedLocation = point);
                _loadRoutePreview(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.userapp',
              ),
              if (_routePreview != null &&
                  _routePreview!.routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePreview!.routePoints,
                      strokeWidth: 5,
                      color: Colors.blue,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (widget.routeStartLocation != null)
                    Marker(
                      point: widget.routeStartLocation!,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.inventory_2,
                        size: 38,
                        color: Colors.green,
                      ),
                    ),
                  Marker(
                    point: selectedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Card(
                elevation: 4,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Chạm vào bản đồ để đặt ghim đúng vị trí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _loadingRoute
                              ? 'Đang tính tuyến đường bộ...'
                              : _routePreview != null
                              ? 'Quãng đường: ${_routePreview!.distanceKm.toStringAsFixed(2)} km\n'
                                    'Dự kiến: ${_routePreview!.durationMinutes} phút'
                              : 'Vĩ độ: ${selectedLocation.latitude.toStringAsFixed(6)}\n'
                                    'Kinh độ: ${selectedLocation.longitude.toStringAsFixed(6)}',
                        ),
                      ),
                      FilledButton(
                        onPressed: _confirm,
                        child: const Text('Dùng vị trí này'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
