import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'login_state.dart';
import 'google_oauth_webview.dart';
import '../../../core/routes/app_routes.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>(
  (ref) => LoginController(),
);

class LoginController extends StateNotifier<LoginState> {
  LoginController() : super(const LoginState());

  void selectCampus(String campus) {
    state = state.copyWith(selectedCampus: campus);
  }

  void clearCampus() {
    state = state.copyWith(selectedCampus: null);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    if (!state.canLogin) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      // Show Google OAuth WebView
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      
      await navigator.push(
        MaterialPageRoute(
          builder: (webViewContext) => GoogleOAuthWebView(
            onSuccess: (user) {
              // Login successful, navigate based on role
              // Close WebView first, then navigate
              Future.microtask(() {
                if (navigator.canPop()) {
                  navigator.pop();
                }
                
                // Wait a bit for WebView to close, then navigate
                Future.delayed(const Duration(milliseconds: 300), () {
                  // If user is student, redirect to homepage
                  if (user.role?.toLowerCase() == 'student') {
                    // Use GoRouter to navigate
                    if (context.mounted) {
                      context.go(AppRoutes.home);
                    }
                  } else if (user.role?.toLowerCase() == 'proctor') {
                    // Navigate to proctor home or profile
                    if (context.mounted) {
                      context.go(AppRoutes.home); // For now, same home, but can change later
                    }
                  } else {
                    // For other roles, default to home
                    if (context.mounted) {
                      context.go(AppRoutes.home);
                    }
                  }
                });
              });
            },
            onError: (error) {
              // Show error message
              // Close WebView first, then show error
              Future.microtask(() {
                if (navigator.canPop()) {
                  navigator.pop();
                }
                
                // Wait a bit for WebView to close, then show error
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (context.mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
              });
            },
          ),
        ),
      );
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

