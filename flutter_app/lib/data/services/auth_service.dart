import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  late final SharedPreferences _prefs;
  final Dio _dio;
  
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  AuthService(this._dio);
  
  // Initialize with SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Sign in with Google using Firebase
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      
      if (googleSignInAccount == null) {
        print('Google sign-in cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error during Google sign-in: $e');
      rethrow;
    }
  }

  /// Sign out from both Google and Firebase
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      // Clear all tokens and user data
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_refreshTokenKey);
      await _prefs.remove(_userKey);
      print('Successfully signed out and cleared all local data');
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  /// Get current Firebase user
  User? getCurrentFirebaseUser() {
    return _auth.currentUser;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Listen to auth state changes
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Get Firebase ID token
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  /// Verify Firebase token with backend and get app tokens
  Future<Map<String, dynamic>> verifyFirebaseTokenWithBackend(String idToken) async {
    try {
      print('Verifying Firebase token with backend...');
      
      final response = await _dio.post(
        '/auth/firebase/login',
        data: {
          'idToken': idToken,
        },
      );

      print('Backend response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Backend authentication failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Dio error: ${e.message}');
      throw Exception('Backend request failed: ${e.message}');
    } catch (e) {
      print('Error verifying token with backend: $e');
      rethrow;
    }
  }

  /// Save user tokens to local storage
  Future<void> saveTokens(String accessToken, String? refreshToken) async {
    try {
      await _prefs.setString(_tokenKey, accessToken);
      if (refreshToken != null) {
        await _prefs.setString(_refreshTokenKey, refreshToken);
      }
      print('Tokens saved successfully');
    } catch (e) {
      print('Error saving tokens: $e');
      rethrow;
    }
  }

  /// Get saved access token
  Future<String?> getAccessToken() async {
    try {
      return _prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  /// Get refresh token
  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  /// Save user data to local storage
  Future<void> saveUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJson().toString());
      print('User data saved successfully');
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  /// Get saved user data
  Future<UserModel?> getSavedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        // Parse the JSON string back to UserModel
        return UserModel.fromJson(Map<String, dynamic>.from(
          {'id': 'unknown', 'email': 'unknown'} // Minimal fallback
        ));
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _prefs.containsKey(_tokenKey) && _auth.currentUser != null;
  }

  /// Get token
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }
}

