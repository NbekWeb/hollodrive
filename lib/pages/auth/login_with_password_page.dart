import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../colors.dart';
import '../../components/auth/auth_app_bar.dart';
import '../../components/auth/custom_input_field.dart';
import '../../components/auth/forget_password_link.dart';
import '../../components/usefull/custom_toast.dart';
import '../../services/api/auth.dart';
import 'reset_password_page.dart';
import 'verification_code_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginWithPasswordPage extends StatefulWidget {
  const LoginWithPasswordPage({super.key});

  @override
  State<LoginWithPasswordPage> createState() => _LoginWithPasswordPageState();
}

class _LoginWithPasswordPageState extends State<LoginWithPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    final isValid = email.isNotEmpty &&
        email.contains('@') &&
        email.contains('.') &&
        email.indexOf('@') < email.lastIndexOf('.') &&
        email.indexOf('@') > 0 &&
        email.length > email.lastIndexOf('.') + 1;
    
    if (_isEmailValid != isValid) {
      setState(() {
        _isEmailValid = isValid;
      });
    }
  }

  void _validatePassword() {
    final password = _passwordController.text;
    final isValid = password.length >= 6;
    
    if (_isPasswordValid != isValid) {
      setState(() {
        _isPasswordValid = isValid;
      });
    }
  }

  bool get _isFormValid {
    return _isEmailValid && _isPasswordValid;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || !_isFormValid || _isLoggingIn) {
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Call login API
      final response = await AuthApi.login(
        email: email,
        password: password,
      );

      if (response.statusCode == 200) {
        // Save registration type as 'byemail' for email verification
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('typeRegis', 'byemail');
        
        // Login successful, navigate to verification code page
        if (mounted) {
      Navigator.pushReplacement(
        context,
            MaterialPageRoute(
              builder: (_) => VerificationCodePage(
                phoneNumber: email, // Pass email as phoneNumber parameter (it's used for email verification)
              ),
            ),
          );
        }
      } else {
        // Unexpected response
        if (mounted) {
          CustomToast.showError(context, 'Login failed. Please try again.');
        }
      }
    } catch (e) {
      print('Error during login: $e');
      
      String errorMessage = 'Login failed. Please check your credentials.';
      
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          // Check for errors object
          if (responseData['errors'] != null) {
            final errors = responseData['errors'];
            if (errors is Map) {
              // Check for non_field_errors
              if (errors['non_field_errors'] != null) {
                final nonFieldErrors = errors['non_field_errors'];
                if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
                  errorMessage = nonFieldErrors[0].toString();
                } else if (nonFieldErrors is String) {
                  errorMessage = nonFieldErrors;
                }
              } else {
                // Get first error from any field
                final firstError = errors.values.first;
                if (firstError is List && firstError.isNotEmpty) {
                  errorMessage = firstError[0].toString();
                } else if (firstError is String) {
                  errorMessage = firstError;
                }
              }
            } else if (errors is String) {
              errorMessage = errors;
            }
          } else if (responseData['detail'] != null) {
            errorMessage = responseData['detail'].toString();
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      }
      
      if (mounted) {
        CustomToast.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);
    final errorColor = AppColors.getErrorColor(brightness);
    final disabledColor = const Color(0xFF262626);

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
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Title
                const Text(
                  'Login with password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'Enter your email and password',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                // Email input
                CustomInputField(
                  label: 'Email address',
                  hintText: 'Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _validateEmail(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password input
                CustomInputField(
                  label: 'Password',
                  hintText: '8 Character',
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: (_) => _validatePassword(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Forget password link
                Center(
                  child: ForgetPasswordLink(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResetPasswordPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Login button
                Center(
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isFormValid && !_isLoggingIn) ? _handleLogin : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid ? errorColor : disabledColor,
                        disabledBackgroundColor: disabledColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoggingIn
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                        'Login',
                        style: TextStyle(
                          color: _isFormValid
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
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
      ),
    );
  }
}

