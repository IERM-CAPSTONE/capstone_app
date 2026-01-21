import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';

/// AuthService using google_sign_in with Firebase Auth
class AuthService {
  final _auth = FirebaseAuth.instance;

  // GoogleSignIn without serverClientId - let it use default from google-services.json
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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

  /// Sign in with Google using native google_sign_in plugin
  Future<User?> signInWithGoogle() async {
    try {
      print('🔄 Starting native Google Sign-In...');

      // Step 1: Sign out first to clear any corrupted state
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Step 2: Perform Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print(' Google sign-in cancelled by user');
        return null;
      }

      print(' Got Google account: ${googleUser.email}');

      // Step 3: Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print(' Got Google auth tokens');

      // Step 4: Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 5: Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      print(' Firebase sign-in successful: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      print(' Google sign-in error: $e');
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
  Future<Map<String, dynamic>> verifyFirebaseTokenWithBackend(
      String idToken) async {
    try {
      print('Verifying Firebase token with backend...');

      final response = await _dio.post(
        '/auth/firebase/login',
        data: {
          'idToken': idToken,
        },
        options: Options(
          // Bypass auth interceptor for login endpoint
          extra: {'requiresAuth': false},
        ),
      );

      print('Backend response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
            'Backend authentication failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Dio error: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      print('Response body: ${e.response?.data}');
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
      await _prefs.setString(_userKey, jsonEncode(user.toJson()));
      print('User data saved successfully');
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  /// Get saved user data
  Future<UserModel?> getSavedUserData() async {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
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
