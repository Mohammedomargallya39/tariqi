// lib/const/api_endpoints.dart
class ApiEndpoints {
  static const String baseUrl = 'http://localhost:5000/api';
  
  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String signup = '$baseUrl/auth/signup';
  // Driver endpoints
  static const String driverProfile = '$baseUrl/driver/get/info';
  static const String driverStartRide = '$baseUrl/driver/create/ride';
  static const String driverAcceptRequest = '$baseUrl/driver/accept-request';
  static const String driverDeclineRequest = '$baseUrl/driver/decline-request';
}