import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  late final PocketBase pb;

  PocketBaseService() {
    final String baseUrl = _getPocketBaseUrl();
    pb = PocketBase(baseUrl);
  }

  String _getPocketBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8090'; // URL for web
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8090'; // Use this for Android Emulator
    } else {
      return 'http://localhost:8090';
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final authData = await pb.collection('users').authWithPassword(email, password);
      print('Login successful: ${authData.token}');
    } catch (e) {
      print('Login error: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      pb.authStore.clear(); // Clear the authentication state
      print('Logout successful');
    } catch (e) {
      print('Logout error: ${e.toString()}');
      rethrow;
    }
  }
}
