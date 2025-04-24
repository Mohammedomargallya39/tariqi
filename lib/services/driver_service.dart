// lib/services/driver/driver_service.dart
import 'dart:developer';

import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tariqi/const/api_endpoints.dart';
import 'package:tariqi/controller/auth_controllers/auth_controller.dart';
import 'package:tariqi/controller/driver/driver_home_controller.dart';

import '../controller/driver/driver_active_ride_controller.dart';

class DriverService extends GetConnect {
  Future<Map<String, dynamic>> getDriverProfile() async {
    final response = await get(
      ApiEndpoints.driverProfile, // Replace with the actual endpoint
      headers: {
        'Authorization': 'Bearer ${Get.find<AuthController>().token.value}', // Add token for authentication
      },
    );

    if (response.status.hasError) {
      throw Exception('Failed to fetch driver profile: ${response.bodyString}');
    }

    return response.body;
  }

  Future<void> startRide({
    required LatLng startLocation,
    required String destination,
    required int maxPassengers,
  }) async {
    final body =
    {
    "route":
      [
        { "lat": startLocation.latitude, "lng": startLocation.longitude },  // Driver Pickup
        { "lat": endLat, "lng": endLong }   // Driver Dropoff
      ],
      "availableSeats": 4,
      "rideTime": "2025-04-24T07:48:05.400Z"
    };

    log("🚀 Starting ride with body: $body");
    log("sdfgjklsdghjjkldfsg");

    final response = await post(
      ApiEndpoints.driverStartRide,
      body,
      headers: {
        'Authorization' : 'Bearer ${Get.find<AuthController>().token.value}',
      },
    );

    log("sdfgjklsdghjjkldfsg");

    log("← Response status: ${response.statusCode}");
    log("← Response body:   ${response.bodyString}");

    if (response.status.hasError) {
      log("❌ API error: ${response.statusCode} ${response.statusText}");
      throw Exception('Failed to start ride: ${response.bodyString}');
    }
    routes = response.body["ride"]["route"];
    return response.body;
  }



  Future<void> acceptRideRequest(String requestId) async {
    // Replace with actual API call
    final response = await post(
      '${ApiEndpoints.driverAcceptRequest}/$requestId', {});
    if (response.status.hasError) {
      throw response.statusText!;
    }
  }

  Future<void> declineRideRequest(String requestId) async {
    // Replace with actual API call
    final response = await post(
      '${ApiEndpoints.driverDeclineRequest}/$requestId', {});
    if (response.status.hasError) {
      throw response.statusText!;
    }
  }
}