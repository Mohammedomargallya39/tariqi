import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/request_state.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tariqi/controller/auth_controllers/auth_controller.dart'; // Import AuthController

class LoginController extends GetxController {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  Rx<RequestState> requestState = RequestState.none.obs;
  RxBool showPassword = true.obs;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Handle login functionality
  loginFunc() async {
    if (formKey.currentState!.validate()) {
      requestState.value = RequestState.loading;

      try {
        final response = await http.post(
          Uri.parse('http://localhost:5000/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "email": emailController.text,
            "password": passwordController.text,
          }),
        );

        final data = jsonDecode(response.body);
        final authController = Get.find<AuthController>();
        if (response.statusCode == 200 && data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await authController.saveToken(data['token']);
          await prefs.setString('authToken', data['token']);
          requestState.value = RequestState.success;

          // Check user role and navigate accordingly
          if (data['role'] == 'client') {
          Get.offNamed(AppRoutesNames.homeScreen);
          } else {
            
             Get.offNamed(AppRoutesNames.driverHomeScreen);
          }
        } else {
          requestState.value = RequestState.error;
          Get.snackbar("Login Failed", data['message'] ?? 'Unknown error');
        }
      } catch (e) {
        requestState.value = RequestState.error;
        Get.snackbar("Error", "Login failed: ${e.toString()}");
      }
    }
  }

  toggleShowPass() {
    showPassword.value = !showPassword.value;
  }

  goToSignUpPage() {
    Get.offNamed(AppRoutesNames.signupScreen);
  }

  initControllers() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  disposeControllers() {
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  void onInit() {
    super.onInit();
    initControllers();
  }

  @override
  void onClose() {
    disposeControllers();
    super.onClose();
  }
}
