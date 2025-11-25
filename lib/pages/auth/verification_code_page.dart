import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../colors.dart';
import '../../components/auth/auth_app_bar.dart';
import '../../components/auth/or_separator.dart';
import '../../components/usefull/custom_toast.dart';
import '../../services/api/auth.dart';
import '../../services/api/base_api.dart';
import '../../services/api/user.dart';
import 'login_with_password_page.dart';
import 'preferences_page.dart';
import 'edit_profile_page.dart';
import '../dashboard/home_page.dart';

class VerificationCodePage extends StatefulWidget {
  final String phoneNumber;

  const VerificationCodePage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );
  Timer? _resendTimer;
  int _resendSeconds = 30;
  bool _canResend = false;
  CodeState _codeState = CodeState.defaultState;
  bool _isVerifying = false;
  String? _registrationType;

  @override
  void initState() {
    super.initState();
    _loadRegistrationType();
    _startResendTimer();
    _focusNodes[0].requestFocus();
  }

  Future<void> _loadRegistrationType() async {
    try {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _registrationType = prefs.getString('typeRegis');
    });
    } catch (e) {
      print('Error loading typeRegis from SharedPreferences: $e');
      // Continue with default behavior if SharedPreferences fails
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _canResend = false;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _onCodeChanged(int index, String value) async {
    // Only allow single digit
    if (value.length > 1) {
      _controllers[index].text = value.substring(0, 1);
      value = value.substring(0, 1);
    }
    
    // Move to next field if digit entered
    if (value.isNotEmpty && index < 3) {
      // Use Future.microtask to ensure focus happens after the current frame
      Future.microtask(() {
        if (mounted) {
          _focusNodes[index + 1].requestFocus();
        }
      });
    }
    
    // Handle backspace: if text becomes empty and not first field, move to previous
    if (value.isEmpty && index > 0) {
      Future.microtask(() {
        if (mounted && _controllers[index].text.isEmpty) {
          _focusNodes[index - 1].requestFocus();
        }
      });
    }
    
    // Check if all fields are filled
    await _updateCodeState();
  }

  Future<void> _updateCodeState() async {
    final code = _controllers.map((c) => c.text).join();
    
    if (code.length == 4) {
      // If registration type is byemail, verify with API
      if (_registrationType == 'byemail') {
        setState(() {
          _isVerifying = true;
        });
        
        // For email verification, phoneNumber parameter contains the email
        final email = widget.phoneNumber;
        
        try {
          final response = await AuthApi.checkGmailCode(
            email: email,
            code: code,
          );
          
          // Extract access token from response
          if (response.data is Map) {
            final data = response.data['data'];
            if (data != null && data['access_token'] != null) {
              // Save access token to localStorage
              await ApiService.setToken(data['access_token'], persist: true);
              
              // Clear user cache to ensure fresh data is fetched for new user
              UserApi.clearCache();
              print('VerificationCodePage: Token saved, user cache cleared');
              
              setState(() {
                _codeState = CodeState.correct;
              });
              
              // Check preferences and navigate accordingly
              Future.delayed(const Duration(milliseconds: 500), () async {
                if (!mounted) return;
                
                try {
                  // First check preferences
                  final prefResponse = await UserApi.getPreferences();
                  
                  if (prefResponse.statusCode == 404) {
                    // No preferences, navigate to preferences page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PreferencesPage()),
                    );
                  } else {
                    // Preferences exist, check user data
                    final userResponse = await UserApi.getUser();
                    if (userResponse.data is Map) {
                      final userData = userResponse.data['data'];
                      final phoneNumber = userData?['phone_number'];
                      final email = userData?['email'];
                      
                      if (phoneNumber == null || phoneNumber.toString().isEmpty ||
                          email == null || email.toString().isEmpty) {
                        // Phone or email is empty, navigate to edit profile
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfilePage()),
                        );
                      } else {
                        // All good, navigate to home page
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      }
                    } else {
                      // Default to home page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                    }
                  }
                } catch (error) {
                  print('Error checking preferences/user: $error');
                  // On error, navigate to preferences page
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PreferencesPage()),
                    );
                  }
                }
              });
              return;
            }
          }
          
          // If no access token, show error
          print('Error: No access token in response');
          print('Response data: ${response.data}');
          setState(() {
            _codeState = CodeState.incorrect;
            _isVerifying = false;
          });
        } on DioException catch (error) {
          print('DioException occurred:');
          print('Error type: ${error.type}');
          print('Error message: ${error.message}');
          print('Error response status: ${error.response?.statusCode}');
          
          // Print error response data more safely
          if (error.response?.data != null) {
            print('Error response data: ${error.response!.data}');
            print('Error response data type: ${error.response!.data.runtimeType}');
          } else {
            print('Error response data: null');
          }
          
          print('Error request path: ${error.requestOptions.path}');
          print('Error request data: ${error.requestOptions.data}');
          
          setState(() {
            _codeState = CodeState.incorrect;
            _isVerifying = false;
          });
          
          String? message;
          if (error.response?.data != null && error.response!.data is Map) {
            final data = error.response!.data as Map;
            print('Parsing error data: $data');
            
            // Check for errors object with field-specific messages
            if (data['errors'] != null && data['errors'] is Map) {
              final errors = data['errors'] as Map;
              print('Found errors object: $errors');
              // Get first error message from any field
              for (var fieldErrors in errors.values) {
                if (fieldErrors is List && fieldErrors.isNotEmpty) {
                  message = fieldErrors[0].toString();
                  print('Extracted error message from errors: $message');
                  break;
                }
              }
            }
            
            // Fallback to detail or message
            if (message == null) {
              message = data['detail']?.toString() ?? data['message']?.toString();
              print('Using fallback message: $message');
            }
          }
          
          message ??= 'Invalid code. Please try again.';
          
          print('Final user-friendly error message: $message');
          
          if (mounted) {
            CustomToast.showError(context, message);
          }
        } catch (error, stackTrace) {
          print('Unexpected error occurred:');
          print('Error: $error');
          print('Stack trace: $stackTrace');
          
          setState(() {
            _codeState = CodeState.incorrect;
            _isVerifying = false;
          });
          
          if (mounted) {
            CustomToast.showError(context, 'Verification failed. Please try again.');
          }
        }
      } else {
        // Default behavior for phone verification
        if (code == '1234') {
          setState(() {
            _codeState = CodeState.correct;
          });
          // Navigate to map page after successful verification
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          });
        } else {
          setState(() {
            _codeState = CodeState.incorrect;
          });
        }
      }
    } else {
      setState(() {
        _codeState = CodeState.defaultState;
      });
    }
  }

  Future<void> _resendCode() async {
    // Reset all fields
    for (var controller in _controllers) {
      controller.clear();
    }
    for (var focusNode in _focusNodes) {
      focusNode.unfocus();
    }
    _focusNodes[0].requestFocus();
    
    setState(() {
      _codeState = CodeState.defaultState;
    });
    
    // Send verification code based on registration type
    if (_registrationType == 'byemail') {
      // For email registration, send only email
      try {
        final email = widget.phoneNumber; // phoneNumber contains email in this case
        await AuthApi.sendVerificationCode(email: email);
        
        if (mounted) {
          CustomToast.showSuccess(context, 'Verification code sent to your email');
        }
      } catch (error) {
        print('Error resending verification code: $error');
        if (mounted) {
          CustomToast.showError(context, 'Failed to resend code. Please try again.');
        }
      }
    } else {
      // For phone registration, send phone number
      // Here you would typically send a new SMS code
      // await AuthApi.sendVerificationCode(phoneNumber: widget.phoneNumber);
    }
    
    _startResendTimer();
  }

  Color _getFieldColor(int index) {
    if (_codeState == CodeState.correct) {
      return const Color(0xFF28A745).withValues(alpha: 0.2); // Green 20% opacity
    } else if (_codeState == CodeState.incorrect) {
      return const Color(0xFFE52A00).withValues(alpha: 0.2); // Red 20% opacity
    }
    return const Color(0xFF262626); // Default dark grey
  }

  Color _getBorderColor(int index) {
    if (_codeState == CodeState.correct) {
      return const Color(0xFF28A745); // Green
    } else if (_codeState == CodeState.incorrect) {
      return const Color(0xFFE52A00); // Red
    }
    return const Color(0xFF262626); // Default dark grey
  }

  Color _getTextColor(int index) {
    if (_codeState == CodeState.correct) {
      return const Color(0xFF28A745); // Green
    } else if (_codeState == CodeState.incorrect) {
      return const Color(0xFFE52A00); // Red
    }
    return Colors.white; // Default white
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const AuthAppBar(actionText: 'Login'),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Hide keyboard when tapping outside input fields
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Title
              const Text(
                'Verification Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                _registrationType == 'byemail'
                    ? 'Enter the code we\'ve sent to your email ${widget.phoneNumber}'
                    : 'Enter the code we\'ve sent to your phone number ${widget.phoneNumber}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: EdgeInsets.only(
                      right: index < 3 ? 8 : 0,
                    ),
                    width: 79.75,
                    height: 50,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                        style: TextStyle(
                          color: _getTextColor(index),
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _getFieldColor(index),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _getBorderColor(index),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _getBorderColor(index),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _getBorderColor(index),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (value) {
                        if (!_isVerifying) {
                          _onCodeChanged(index, value);
                        }
                      },
                      enabled: !_isVerifying,
                      onTap: () {
                        // Select all text when tapped
                        _controllers[index].selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _controllers[index].text.length,
                        );
                      },
                      onSubmitted: (_) {
                        // Move to next field on submit
                        if (index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Resend timer
              if (!_canResend)
                Center(
                  child: Text(
                    'Resend code in ${_formatTimer(_resendSeconds)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              // Resend code link
              if (_canResend) ...[
                Center(
                  child: GestureDetector(
                    onTap: _resendCode,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(text: 'Didn\'t receive code? '),
                          TextSpan(
                            text: 'Resend Code',
                            style: TextStyle(
                              color: AppColors.getErrorColor(brightness),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Separator
              const OrSeparator(),
              const SizedBox(height: 24),
              // Login with password button
              SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginWithPasswordPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF262626),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login with password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

enum CodeState {
  defaultState,
  correct,
  incorrect,
}

