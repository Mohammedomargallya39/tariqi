import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  RxString token = ''.obs;
  RxBool isLoggedIn = false.obs;

  Future<void> saveToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', newToken);
    token.value = newToken;
    isLoggedIn.value = true;
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token.value = prefs.getString('authToken') ?? '';
    isLoggedIn.value = token.isNotEmpty;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    token.value = '';
    isLoggedIn.value = false;
  }

  @override
  void onInit() {
    loadToken();
    super.onInit();
  }
}
