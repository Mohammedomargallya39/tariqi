// lib/controller/driver/driver_home_controller.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tariqi/const/class/request_state.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/services/driver_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:tariqi/const/api_links_keys/api_links_keys.dart';
class DriverHomeController extends GetxController {
  final DriverService _driverService = DriverService();
  final Rx<RequestState> requestState = RequestState.online.obs;
  final RxBool isLocationDisabled = false.obs;
  final RxBool isReadyToStart = false.obs;
  final RxInt maxPassengers = 4.obs;
  
  // Driver info
  final RxString driverEmail = ''.obs;
  final RxString driverProfilePic = ''.obs;
  final RxString carMake = ''.obs;
  final RxString carModel = ''.obs;
  final RxString licensePlate = ''.obs;
  final RxString drivingLicense = ''.obs;

  // Map controllers
  late MapController mapController;
  LatLng? userPosition;
  final List<Marker> markers = [];
  final List<Polyline> routePolyline = [];

  // Text controllers
  final TextEditingController destinationController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    getUserLocation();
    checkLocationStatus();
    getDriverInfo(); 
  }

  Future<void> getDriverInfo() async {
    try {
      requestState.value = RequestState.loading;

      // Fetch driver info from the API
      final driverInfo = await _driverService.getDriverProfile();
      print("Driver Info Response: $driverInfo"); 
      // Parse and update driver details
      driverEmail.value = driverInfo['email'] ?? '';
      driverProfilePic.value = driverInfo['profilePic'] ?? ''; 

      // Check if carDetails exists and is not null
      final carDetails = driverInfo['carDetails'];
      if (carDetails != null) {
        carMake.value = carDetails['make'] ?? '';
        carModel.value = carDetails['model'] ?? '';
        licensePlate.value = carDetails['licensePlate'] ?? '';
      } else {
        carMake.value = '';
        carModel.value = '';
        licensePlate.value = '';
      }

      drivingLicense.value = driverInfo['drivingLicense'] ?? '';

      requestState.value = RequestState.online;
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar('Error', 'Failed to load driver info: $e');
    }
  }

  Future<void> getUserLocation() async {
    try {
      requestState.value = RequestState.loading;
      // Replace with actual location service call
      userPosition = const LatLng(24.7136, 46.6753); // Example coordinates
      markers.add(Marker(
        point: userPosition!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
      ));
      requestState.value = RequestState.online;
      update();
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar('Error', 'Failed to get location');
    }
  }

  void checkLocationStatus() {
    // Replace with actual location status check
    isLocationDisabled.value = false;
  }

  void setMaxPassengers(int value) {
    maxPassengers.value = value;
    checkReadyStatus();
  }

  Future<void> getDestinationLocation({required String location}) async {
    try {
      requestState.value = RequestState.loading;

      // 1. Geocode the destination address to get coordinates
      final geocodeResponse = await http.get(Uri.parse(
        'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(location)}&key=93fd15d37b984bebb7692752a1bc6d14',
      ));

      if (geocodeResponse.statusCode != 200) {
        throw Exception('Failed to geocode destination');
      }

      final geocodeData = jsonDecode(geocodeResponse.body);
      if (geocodeData['results'].isEmpty) {
        throw Exception('No results found for destination');
      }

      final destLat = geocodeData['results'][0]['geometry']['lat'];
      final destLng = geocodeData['results'][0]['geometry']['lng'];
      final destination = LatLng(destLat, destLng);

      // 2. Add destination marker
      if (markers.length > 1) {
        markers.removeAt(1);
      }
      markers.add(Marker(
        point: destination,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ));

      // 3. Get route polyline from OpenRouteService
      if (userPosition != null) {
        final routeResponse = await http.post(
          Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson'),
          headers: {
            'Authorization': '5b3ce3597851110001cf6248bb9ac1f42e9a4c27a6e95c89f7c3985f',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "coordinates": [
              [userPosition!.longitude, userPosition!.latitude],
              [destLng, destLat]
            ]
          }),
        );

        if (routeResponse.statusCode != 200) {
          throw Exception('Failed to get route');
        }

        final routeData = jsonDecode(routeResponse.body);
        final coords = routeData['features'][0]['geometry']['coordinates'] as List;
        final polylinePoints = coords
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();

        routePolyline.clear();
        routePolyline.add(Polyline(
          points: polylinePoints,
          color: Colors.blue,
          strokeWidth: 4,
        ));
      }

      // 4. Update destination text field
     destinationController.text = await getLocationName(lat: destLat, long: destLng);

      requestState.value = RequestState.online;
      checkReadyStatus();
      update();
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar('Error', 'Failed to find destination: $e');
    }
  }


  void setDestinationFromMap(LatLng latlng) async{
    // Remove previous destination marker if it exists (assume first marker is user, second is destination)
    if (markers.length > 1) {
      markers.removeAt(1);
    }
    // Add new destination marker
    markers.add(
      Marker(
        point: latlng,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ),
    );
    // Update destination text field
    destinationController.text = await getLocationName(lat: latlng.latitude, long: latlng.longitude);
    endLat = latlng.latitude;
    endLong = latlng.longitude;
    // Update route polyline
    routePolyline.clear();
    if (userPosition != null) {
        final routeResponse = await http.post(
          Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson'),
          headers: {
            'Authorization': '5b3ce3597851110001cf6248bb9ac1f42e9a4c27a6e95c89f7c3985f',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "coordinates": [
              [userPosition!.longitude, userPosition!.latitude],
              [latlng.longitude, latlng.latitude]
            ]
          }),
        );

        if (routeResponse.statusCode != 200) {
          throw Exception('Failed to get route');
        }

        final routeData = jsonDecode(routeResponse.body);
        final coords = routeData['features'][0]['geometry']['coordinates'] as List;
        final polylinePoints = coords
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();

        routePolyline.clear();
        routePolyline.add(Polyline(
          points: polylinePoints,
          color: Colors.blue,
          strokeWidth: 4,
        ));
      }
    checkReadyStatus();
    update(); // Notify GetBuilder to rebuild
  }
  Future<String> getLocationName({
    required double lat,
    required double long,
  }) async {
    final geoCodeKey = ApiLinksKeys.geoCodingKey;
    final url = Uri.parse(
      '${ApiLinksKeys.baseUrl}?q=$lat+$long&key=$geoCodeKey&pretty=1',
    );
    try {
      requestState.value = RequestState.loading;
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];
        if (results.isNotEmpty) {
          final locationName = results[0]['formatted'];

          requestState.value = RequestState.success;

          return locationName;
        } else {
          requestState.value = RequestState.failed;
        }
      } else {
        requestState.value = RequestState.failed;
      }
    } on TimeoutException catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Request timeout: $e');
    } on SocketException catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Network error: $e');
    } on HandshakeException catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Handshake error: $e');
    } on Exception catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Failed to get location: $e');
    }
    throw Exception('Failed to get location name');
  }

  void checkReadyStatus() {
    isReadyToStart.value = destinationController.text.isNotEmpty && 
        userPosition != null && 
        markers.length >= 2;
  }

  Future<void> startRide() async {
    try {

      requestState.value = RequestState.loading;
      // Replace with actual API call to start ride
      await _driverService.startRide(
        startLocation: userPosition!,
        destination: destinationController.text,
        maxPassengers: maxPassengers.value,
      );
      Get.toNamed(AppRoutesNames.driverActiveRideScreen);
      requestState.value = RequestState.online;
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar('Error', 'Failed to start ride');
    }
  }

  void logout() {
    // Replace with actual logout logic
    Get.offAllNamed(AppRoutesNames.loginScreen);
  }
}

Widget _buildDriverInfo(DriverHomeController controller) {
  return Obx(() {
    if (controller.requestState.value == RequestState.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (controller.requestState.value == RequestState.failed) {
      return const Center(
        child: Text(
          "Failed to load driver info",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: controller.driverProfilePic.value.isNotEmpty
              ? NetworkImage(controller.driverProfilePic.value)
              : null,
          child: controller.driverProfilePic.value.isEmpty
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          controller.driverEmail.value,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          "${controller.carMake.value} ${controller.carModel.value}",
          style: const TextStyle(color: Colors.white),
        ),
        Text(
          "License: ${controller.licensePlate.value}",
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  });
}

double endLat = 0.0;
double endLong = 0.0;