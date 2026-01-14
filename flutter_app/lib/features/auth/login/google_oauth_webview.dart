import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/env.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../config/dependency_injection.dart';

class GoogleOAuthWebView extends StatefulWidget {
  final Function(UserModel) onSuccess;
  final Function(String) onError;

  const GoogleOAuthWebView({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<GoogleOAuthWebView> createState() => _GoogleOAuthWebViewState();
}

class _GoogleOAuthWebViewState extends State<GoogleOAuthWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasCompleted = false;
  int _extractRetryCount = 0;
  static const int _maxExtractRetries = 3;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _openBrowserForWeb();
    } else {
      // Use WebView with proper User-Agent to avoid Google's "disallowed_useragent" error
      _initializeWebView();
    }
  }

  Future<void> _openBrowserForWeb() async {
    final googleAuthUrl = '${Env.apiBaseUrl}/auth/google';
    final uri = Uri.parse(googleAuthUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      // For web, we can't easily capture the callback
    } else {
      widget.onError('Không thể mở browser');
    }
  }

  void _initializeWebView() {
    final googleAuthUrl = '${Env.apiBaseUrl}/auth/google';
    
    print('Debug: Initializing WebView with URL: $googleAuthUrl');
    
    // Set User-Agent to Chrome to avoid Google's "disallowed_useragent" error
    final userAgent = Platform.isAndroid
        ? 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36'
        : 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            final uri = Uri.parse(url);
            print('Debug: Navigation request to: $url');

            // Only rewrite when the actual host of the URL is localhost/127 and path is the callback.
            final isLocalHost =
                uri.host == 'localhost' || uri.host == '127.0.0.1';
            final isCallback = uri.path.contains('/auth/google/callback');

            if (isLocalHost && isCallback) {
              final newUri = uri.replace(host: '10.0.2.2');
              print(
                  'Debug: Intercepting localhost callback, redirecting to: ${newUri.toString()}');

              Future.microtask(() {
                _controller.loadRequest(newUri);
              });
              return NavigationDecision.prevent;
            }

            // Allow all other navigation
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            print('Debug: Page started loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
            
            // Check if this is the callback URL
            if (url.contains('/auth/google/callback')) {
              print('Debug: Callback URL detected: $url');
              // Don't call _handleCallback here, wait for page to finish loading
            }
          },
          onPageFinished: (String url) {
            print('Debug: Page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            
            // Check if this is the callback URL
            if (url.contains('/auth/google/callback') && !_hasCompleted) {
              print('Debug: Processing callback URL: $url');
              _handleCallback(url);
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('Debug: Web resource error: ${error.description}');
            print('Debug: Error code: ${error.errorCode}');
            print('Debug: Error URL: ${error.url}');
            
            // Check if it's connection error
            if (error.description.contains('ERR_CONNECTION_REFUSED') ||
                error.description.contains('ERR_CONNECTION_TIMED_OUT') ||
                error.description.contains('ERR_NAME_NOT_RESOLVED')) {
              widget.onError('Lỗi kết nối: ${error.description}. Vui lòng kiểm tra backend có đang chạy trên port 3002 không.');
            } else if (error.description.contains('disallowed_useragent')) {
              widget.onError('Lỗi: ${error.description}');
            } else if (error.errorCode == -2) {
              // -2 usually means network error
              widget.onError('Lỗi mạng: Không thể kết nối đến server. Vui lòng kiểm tra kết nối internet và backend.');
            } else {
              widget.onError('Lỗi: ${error.description} (Code: ${error.errorCode})');
            }
          },
          onProgress: (int progress) {
            // Update loading state based on progress
            if (progress == 100 && mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(googleAuthUrl));
  }

  Future<void> _handleCallback(String url) async {
    if (_hasCompleted) {
      print('Debug: Callback already handled, skipping...');
      return;
    }
    
    print('Debug: Handling callback for URL: $url');
    
    try {
      // Wait longer for the page to fully load and JavaScript to execute
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Check again if completed (might have been set by another callback)
      if (_hasCompleted) {
        print('Debug: Already completed during delay, skipping extract...');
        return;
      }
      
      // Extract the response from the page
      await _extractResponseFromPage();
    } catch (e) {
      print('Debug: Error in _handleCallback: $e');
      if (!_hasCompleted && mounted) {
        widget.onError('Lỗi xử lý phản hồi: ${e.toString()}');
      }
    }
  }

  Future<void> _extractResponseFromPage() async {
    try {
      // First, wait for page to be ready
      await _controller.runJavaScript('''
        (function() {
          return new Promise(function(resolve) {
            if (document.readyState === 'complete') {
              resolve(true);
            } else {
              window.addEventListener('load', function() {
                resolve(true);
              });
            }
          });
        })();
      ''');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use JavaScript to get the response from various sources
      final script = '''
        (function() {
          try {
            // Method 1: Try to get from window.loginResponse (set by backend script)
            if (window.loginResponse && typeof window.loginResponse === 'object') {
              if (window.loginResponse.user) {
                return JSON.stringify(window.loginResponse);
              }
            }
            
            // Method 2: Try to call window.getLoginResponse() if available
            if (typeof window.getLoginResponse === 'function') {
              var response = window.getLoginResponse();
              if (response && response.user) {
                return JSON.stringify(response);
              }
            }
            
            // Method 3: Try to get from script tag with id="loginData" (type="application/json")
            var scriptTag = document.getElementById('loginData');
            if (scriptTag && scriptTag.textContent) {
              try {
                var json = JSON.parse(scriptTag.textContent);
                if (json.user) {
                  return JSON.stringify(json);
                }
              } catch(e) {
                // Continue to next method
              }
            }
            
            // Method 4: Try to get from pre tag with id="responseData"
            var pre = document.getElementById('responseData');
            if (pre) {
              var text = pre.textContent || pre.innerText || '';
              if (text.trim()) {
                try {
                  var json = JSON.parse(text);
                  if (json.user) {
                    return JSON.stringify(json);
                  }
                } catch(e) {
                  // Continue to next method
                }
              }
            }
            
            // Method 5: Try to get from all pre tags
            var preTags = document.querySelectorAll('pre');
            for (var i = 0; i < preTags.length; i++) {
              var text = preTags[i].textContent || preTags[i].innerText || '';
              if (text.trim()) {
                try {
                  var json = JSON.parse(text);
                  if (json.user) {
                    return JSON.stringify(json);
                  }
                } catch(e) {
                  continue;
                }
              }
            }
            
            // Method 6: Try to find JSON in body text
            if (document.body) {
              var bodyText = document.body.innerText || document.body.textContent || '';
              if (bodyText) {
                // Try to find JSON object with "user" field
                var jsonMatch = bodyText.match(/\\{[\\s\\S]*?"user"[\\s\\S]*?\\}/);
                if (jsonMatch) {
                  try {
                    var json = JSON.parse(jsonMatch[0]);
                    if (json.user) {
                      return JSON.stringify(json);
                    }
                  } catch(e) {
                    // Continue
                  }
                }
              }
            }
            
            // Return error message for debugging
            return JSON.stringify({
              error: 'Could not extract login data',
              methods: {
                windowLoginResponse: !!window.loginResponse,
                getLoginResponse: typeof window.getLoginResponse === 'function',
                scriptTag: !!document.getElementById('loginData'),
                preTag: !!document.getElementById('responseData'),
                preCount: document.querySelectorAll('pre').length,
                bodyExists: !!document.body
              },
              bodyPreview: document.body ? document.body.innerText.substring(0, 200) : 'No body'
            });
          } catch(e) {
            return JSON.stringify({error: 'JavaScript error: ' + e.toString(), stack: e.stack});
          }
        })();
      ''';
      
      final result = await _controller.runJavaScriptReturningResult(script);
      
      if (result.toString().isNotEmpty) {
        String jsonString = result.toString();
        print('Debug: Raw JavaScript result: $jsonString');
        
        // Remove outer quotes if present (JSON string returned as string)
        if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
          jsonString = jsonString.substring(1, jsonString.length - 1);
          // Unescape the JSON string
          jsonString = jsonString.replaceAll('\\"', '"');
          jsonString = jsonString.replaceAll('\\n', '');
          jsonString = jsonString.replaceAll('\\\\', '\\');
        }
        
        print('Debug: Cleaned JSON string: $jsonString');
        
        // Try to parse JSON (may need to parse twice if double-encoded)
        try {
          dynamic parsed = json.decode(jsonString);
          
          // If the parsed result is still a string, parse it again
          if (parsed is String) {
            print('Debug: First parse returned string: $parsed');
            print('Debug: Parsing again...');
            try {
              parsed = json.decode(parsed);
              print('Debug: Second parse successful');
            } catch (e2) {
              print('Debug: Second parse failed: $e2');
              // Try to find JSON in the string - use a more flexible regex
              final jsonMatch = RegExp(r'\{[\s\S]*?"user"[\s\S]*?\}').firstMatch(parsed as String);
              if (jsonMatch != null) {
                try {
                  parsed = json.decode(jsonMatch.group(0)!);
                  print('Debug: Extracted JSON from string using regex');
                } catch (e3) {
                  print('Debug: Failed to parse extracted JSON: $e3');
                  // Try manual extraction of user data
                  final userMatch = RegExp(r'"user"\s*:\s*\{[\s\S]*?\}').firstMatch(parsed as String);
                  if (userMatch != null) {
                    // Create a minimal JSON structure with user data
                    final userJson = '{"user": ${userMatch.group(0)!.substring(7)}}';
                    try {
                      parsed = json.decode(userJson);
                      print('Debug: Extracted user JSON manually');
                    } catch (e4) {
                      throw e2;
                    }
                  } else {
                    throw e2;
                  }
                }
              } else {
                throw e2;
              }
            }
          }
          
          final responseData = parsed as Map<String, dynamic>;
          print('Debug: Parsed response data keys: ${responseData.keys.toList()}');
          print('Debug: Response data content: $responseData');
          
          // Check if there's an error in the response (for debugging)
          if (responseData.containsKey('error')) {
            print('Debug: Error extracting data: ${responseData['error']}');
            if (responseData.containsKey('methods')) {
              print('Debug: Methods checked: ${responseData['methods']}');
            }
            if (responseData.containsKey('bodyPreview')) {
              print('Debug: Body preview: ${responseData['bodyPreview']}');
            }
            
            // Try one more time after additional delay (with retry limit)
            if (_extractRetryCount < _maxExtractRetries) {
              _extractRetryCount++;
              print('Debug: Retrying extract (attempt $_extractRetryCount/$_maxExtractRetries)...');
              await Future.delayed(const Duration(milliseconds: 1000));
              return await _extractResponseFromPage();
            } else {
              widget.onError('Không thể trích xuất dữ liệu từ phản hồi sau $_maxExtractRetries lần thử. Vui lòng thử lại.');
              return;
            }
          }
          
          if (responseData.containsKey('user')) {
            print('Debug: Found user in response! Processing login...');
            
            // Success! Extract user data and tokens
            final authService = DependencyInjection.get<AuthService>();
            
            // Get cookies from WebView using JavaScript
            final cookieScript = '''
              (function() {
                var cookies = document.cookie.split(';');
                var result = {};
                for (var i = 0; i < cookies.length; i++) {
                  var cookie = cookies[i].trim();
                  var eqPos = cookie.indexOf('=');
                  if (eqPos > 0) {
                    var name = cookie.substring(0, eqPos);
                    var value = cookie.substring(eqPos + 1);
                    result[name] = value;
                  }
                }
                return JSON.stringify(result);
              })();
            ''';
            
            try {
              final cookiesResult = await _controller.runJavaScriptReturningResult(cookieScript);
              String? cookiesJson;
              
              cookiesJson = cookiesResult.toString();
              if (cookiesJson.startsWith('"') && cookiesJson.endsWith('"')) {
                cookiesJson = cookiesJson.substring(1, cookiesJson.length - 1);
                cookiesJson = cookiesJson.replaceAll('\\"', '"');
              }
              
              // Parse cookies
              final cookieMap = json.decode(cookiesJson) as Map<String, dynamic>;
              final accessToken = cookieMap['accessToken'] as String?;
              final refreshToken = cookieMap['refreshToken'] as String?;
              
              if (accessToken != null) {
                await authService.saveTokens(accessToken, refreshToken);
                print('Debug: Saved tokens successfully');
              }
            } catch (e) {
              print('Debug: Could not get cookies: $e');
              // If we can't get cookies, tokens might be in response headers
              // We'll need to handle this differently
            }
            
            // Save user data
            final userData = responseData['user'] as Map<String, dynamic>;
            final user = UserModel.fromJson({
              'id': userData['id'],
              'email': userData['email'],
              'name': userData['fullName'],
              'role': userData['role'],
            });
            
            print('Debug: User data extracted: ${user.email}, role: ${user.role}');
            
            try {
              await authService.saveUserData(user);
              print('Debug: Saved user data successfully');
            } catch (e) {
              print('Debug: Error saving user data: $e');
              // Continue anyway - we can still proceed with login
            }
            
            // Mark as completed BEFORE calling onSuccess
            // This ensures we don't try to setState after widget is disposed
            // and prevents multiple callbacks
            if (!_hasCompleted) {
              _hasCompleted = true;
              if (mounted) {
                setState(() {
                  _hasCompleted = true;
                });
              }
              
              // Call success callback - this will close WebView and navigate
              // Do this last, as it may dispose the widget
              print('Debug: Calling onSuccess callback');
              if (mounted) {
                widget.onSuccess(user);
              }
            } else {
              print('Debug: Already completed, skipping onSuccess callback');
            }
            return;
          }
        } catch (e) {
          print('Debug: Exception during JSON parsing: $e');
          print('Debug: JSON string that failed to parse: $jsonString');
          
          // If JSON parsing fails, try to find JSON in the string using more flexible regex
          try {
            // Try to extract JSON object from escaped string
            final jsonMatch = RegExp(r'\{[\s\S]*?"user"[\s\S]*?\}').firstMatch(jsonString);
            if (jsonMatch != null) {
              final matchedJson = jsonMatch.group(0);
              print('Debug: Found JSON match: $matchedJson');
              try {
                final responseData = json.decode(matchedJson!) as Map<String, dynamic>;
                print('Debug: Successfully parsed extracted JSON, keys: ${responseData.keys.toList()}');
                if (responseData.containsKey('user')) {
                  print('Debug: Found user in extracted JSON!');
                  final authService = DependencyInjection.get<AuthService>();
                  final userData = responseData['user'] as Map<String, dynamic>;
              final user = UserModel.fromJson({
                'id': userData['id'],
                'email': userData['email'],
                'name': userData['fullName'],
                'role': userData['role'],
              });
              await authService.saveUserData(user);
              
              // Mark as completed and call success callback
              if (!_hasCompleted) {
                _hasCompleted = true;
                if (mounted) {
                  setState(() {
                    _hasCompleted = true;
                  });
                }
                
                // Call success callback - this will close WebView and navigate
                print('Debug: Calling onSuccess callback from catch block');
                if (mounted) {
                  widget.onSuccess(user);
                }
              } else {
                print('Debug: Already completed, skipping onSuccess callback from catch block');
              }
              return;
                }
              } catch (e2) {
                print('Debug: Failed to parse extracted JSON: $e2');
              }
            }
          } catch (e3) {
            print('Debug: Exception during regex extraction: $e3');
          }
        }
      }
      
      // If we still can't extract, show error with more details
      if (result.toString().isNotEmpty) {
        print('Debug: Failed to extract data. Response: ${result.toString()}');
      } else {
        print('Debug: Failed to extract data. Empty response from JavaScript.');
      }
      
      if (_extractRetryCount < _maxExtractRetries) {
        _extractRetryCount++;
        print('Debug: Retrying extract (attempt $_extractRetryCount/$_maxExtractRetries)...');
        await Future.delayed(const Duration(milliseconds: 1500));
        return await _extractResponseFromPage();
      } else {
        widget.onError('Không thể trích xuất dữ liệu từ phản hồi sau $_maxExtractRetries lần thử. Vui lòng kiểm tra backend và thử lại.');
      }
    } catch (e) {
      print('Debug: Exception during extract: $e');
      if (_extractRetryCount < _maxExtractRetries) {
        _extractRetryCount++;
        print('Debug: Retrying extract after exception (attempt $_extractRetryCount/$_maxExtractRetries)...');
        await Future.delayed(const Duration(milliseconds: 1500));
        return await _extractResponseFromPage();
      } else {
        widget.onError('Lỗi: ${e.toString()}');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đăng nhập với Google'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang mở browser để đăng nhập...'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập với Google'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

