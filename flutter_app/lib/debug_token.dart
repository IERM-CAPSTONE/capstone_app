import 'package:shared_preferences/shared_preferences.dart';

Future<void> debugToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  print('=== DEBUG TOKEN ===');
  print('Token exists: ${token != null}');
  if (token != null) {
    print('Token (first 50 chars): ${token.length > 50 ? token.substring(0, 50) : token}...');
    print('Token length: ${token.length}');
  } else {
    print('NO TOKEN FOUND IN SHARED PREFERENCES!');
  }
  print('==================');
}
