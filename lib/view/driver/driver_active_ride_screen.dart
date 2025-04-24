// lib/view/driver/driver_active_ride_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/driver/driver_active_ride_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';

class DriverActiveRideScreen extends StatelessWidget {
  const DriverActiveRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(DriverActiveRideController());

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(controller),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildRideInfoSheet(controller),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(DriverActiveRideController controller) {
    return GetBuilder<DriverActiveRideController>(
      builder: (controller) => FlutterMap(
        mapController: controller.mapController,
        options: MapOptions(
          initialCenter: controller.currentLocation ?? const LatLng(0, 0),
          initialZoom: 15.0,
        ),
        children: [
          HandlingView(
            requestState: controller.requestState.value,
            widget: TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
          ),
          MarkerLayer(markers: controller.markers),
          PolylineLayer(polylines: controller.routePolyline),
        ],
      ),
    );
  }

  Widget _buildRideInfoSheet(DriverActiveRideController controller) {
    return Container(
      height: ScreenSize.screenHeight! * 0.35,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blackColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Fixed header
          const Text(
            "Active Ride",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Destination:", controller.destination),
                  _buildInfoRow("ETA:", "${controller.etaMinutes} minutes"),
                  _buildInfoRow("Distance:", "${controller.distanceKm} km"),
                  const SizedBox(height: 10),
                  const Text(
                    "Passengers:",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Obx(() => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.passengers.length,
                    separatorBuilder: (context, index) =>
                    const Divider(color: Colors.grey, height: 1),
                    itemBuilder: (context, index) {
                      final passenger = controller.passengers[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(passenger['profilePic']),
                        ),
                        title: Text(
                          passenger['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Rating: ${passenger['rating']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    },
                  )),
                ],
              ),
            ),
          ),

          // Ride request dialog (fixed at bottom)
          Obx(() => controller.hasPendingRequest.value
              ? Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildRideRequestDialog(controller),
          )
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequestDialog(DriverActiveRideController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "New Ride Request",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(
                    controller.pendingRequest.value['profilePic']),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.pendingRequest.value['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Rating: ${controller.pendingRequest.value['rating']}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Pickup: ${controller.pendingRequest.value['pickup']}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(120, 45),
                ),
                onPressed: () => controller.declineRequest(),
                child: const Text("Decline"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(120, 45),
                ),
                onPressed: () => controller.acceptRequest(),
                child: const Text("Accept"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}