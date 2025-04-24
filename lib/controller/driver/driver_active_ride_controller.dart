// lib/controller/driver/driver_active_ride_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tariqi/const/class/request_state.dart';
import 'package:tariqi/services/driver_service.dart';
import 'dart:math';

// Global variable to hold route data
RxList<dynamic> routes = <dynamic>[].obs;

class DriverActiveRideController extends GetxController {
  final DriverService _driverService = DriverService();
  final Rx<RequestState> requestState = RequestState.online.obs;
  final RxList<Map<String, dynamic>> passengers = <Map<String, dynamic>>[].obs;
  final RxBool hasPendingRequest = false.obs;
  final RxMap<String, dynamic> pendingRequest = <String, dynamic>{}.obs;

  // Ride info
  late String destination = "";
  late int etaMinutes = 0;
  late double distanceKm = 0.0;
  late LatLng currentLocation = LatLng(0.0,0.0);
  late LatLng destinationLocation = LatLng(0.0,0.0);

  // Map controllers
  late MapController mapController;
  final List<Marker> markers = [];
  final List<Polyline> routePolyline = [];

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    _waitForRouteAndInitialize();
    simulateRideUpdates();
    simulateRideRequests();
  }

  void _waitForRouteAndInitialize() {
    // Convert routes to an Rx observable
    final rxRoutes = RxList<dynamic>(routes);

    // Use ever with the Rx observable
    ever(rxRoutes, (_) {
      if (routes.length >= 2) {
        initializeRideFromRoute();
      }
    });

    // Initial check
    if (routes.length >= 2) {
      initializeRideFromRoute();
    }
  }

  void initializeRideFromRoute() {
    // Parse stored global routes
    final points = routes.map((pt) {
      final m = pt as Map<String, dynamic>;
      return LatLng(m['lat'] as double, m['lng'] as double);
    }).toList();

    // Assign start & destination
    currentLocation = points[0];
    destinationLocation = points[1];

    // Compute distance (km) via haversine
    distanceKm = _computeDistanceKm(currentLocation, destinationLocation);
    // Estimate ETA (minutes) assuming 30 km/h average
    const avgSpeedKmh = 30.0;
    etaMinutes = (distanceKm / avgSpeedKmh * 60).round();

    // Human-readable destination string
    destination = '${destinationLocation.latitude.toStringAsFixed(4)}, '
        '${destinationLocation.longitude.toStringAsFixed(4)}';

    // Add map markers
    markers.clear();
    markers.addAll([
      Marker(
        point: currentLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
      ),
      Marker(
        point: destinationLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ),
    ]);

    // Add route polyline
    routePolyline.clear();
    routePolyline.add(Polyline(
      points: [currentLocation, destinationLocation],
      color: Colors.blue,
      strokeWidth: 4,
    ));

    update();
  }

  void simulateRideUpdates() {
    Future.delayed(const Duration(seconds: 5), () {
      if (etaMinutes > 0) {
        etaMinutes -= 1;
        distanceKm = (distanceKm - 0.2).clamp(0.0, double.infinity);
        update();
        simulateRideUpdates();
      } else {
        Get.back();
        Get.snackbar('Ride Completed', 'You have reached the destination');
      }
    });
  }

  void simulateRideRequests() {
    Future.delayed(const Duration(seconds: 10), () {
      if (passengers.length < 4) {
        hasPendingRequest.value = true;
        pendingRequest.value = {
          'id': 'req_\${DateTime.now().millisecondsSinceEpoch}',
          'name': 'John Doe',
          'rating': 4.5,
          'profilePic': 'https://example.com/profile.jpg',
          'pickup': '123 Main St',
        };
        Future.delayed(const Duration(seconds: 30), () {
          if (hasPendingRequest.value) declineRequest();
        });
      }
    });
  }

  Future<void> acceptRequest() async {
    try {
      requestState.value = RequestState.loading;
      await _driverService.acceptRideRequest(pendingRequest['id']);
      passengers.add(pendingRequest);
      hasPendingRequest.value = false;
      requestState.value = RequestState.online;
      Future.delayed(const Duration(seconds: 15), simulateRideRequests);
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar('Error', 'Failed to accept request');
    }
  }

  Future<void> declineRequest() async {
    try {
      requestState.value = RequestState.loading;
      await _driverService.declineRideRequest(pendingRequest['id']);
      hasPendingRequest.value = false;
      requestState.value = RequestState.online;
      Future.delayed(const Duration(seconds: 10), simulateRideRequests);
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar('Error', 'Failed to decline request');
    }
  }

  double _computeDistanceKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);
    final h = sinDLat * sinDLat +
        cos(_toRad(a.latitude)) *
            cos(_toRad(b.latitude)) *
            sinDLng * sinDLng;
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;
}


