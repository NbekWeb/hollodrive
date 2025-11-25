import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../colors.dart';
import '../../components/auth/auth_app_bar.dart';
import '../../components/auth/custom_input_field.dart';
import '../../components/usefull/custom_toast.dart';
import '../../services/api/auth.dart';
import 'login_page.dart';
import 'verification_code_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sendEmailPromo = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_onInputChanged);
    _emailController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
    _confirmPasswordController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    setState(() {});
  }

  bool get _isFormValid {
    return _fullNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _sendEmailPromo;
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_onInputChanged);
    _emailController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _confirmPasswordController.removeListener(_onInputChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleCreateAccount() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

    if (!formState.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthApi.registerEmail(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      
      // Save typeRegis to localStorage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('typeRegis', 'byemail');
      } catch (e) {
        print('Error saving typeRegis to SharedPreferences: $e');
        // Continue even if SharedPreferences fails
      }
      
      // Navigate to verification code page
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
          builder: (_) => VerificationCodePage(
            phoneNumber: _emailController.text.trim(),
          ),
        ),
      );
    } on DioException catch (error) {
      print('DioException occurred during registration:');
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
      
      message ??= 'Registration failed. Please try again.';
      
      print('Final user-friendly error message: $message');
      
      if (mounted) {
        CustomToast.showError(context, message);
      }
    } catch (error, stackTrace) {
      print('Unexpected error occurred during registration:');
      print('Error: $error');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        CustomToast.showError(context, 'Unexpected error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);
    final errorColor = AppColors.getErrorColor(brightness);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const AuthAppBar(actionText: 'Registration'),
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
                  'Create an Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Center(
                  child: Text(
                    'Create Hola account and get early access of our best products, inspiration and many more',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Full Name input
                CustomInputField(
                  label: 'Full Name *',
                  hintText: 'Your full name',
                  controller: _fullNameController,
                  validator: _validateFullName,
                ),
                const SizedBox(height: 16),
                // Email input
                CustomInputField(
                  label: 'Email address *',
                  hintText: 'Your email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                // Password input
                CustomInputField(
                  label: 'Password *',
                  hintText: 'Your password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                // Confirm Password input
                CustomInputField(
                  label: 'Confirm Password *',
                  hintText: 'Confirm your password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 16),
                // Checkbox for email promo
                Row(
                  children: [
                    Checkbox(
                      value: _sendEmailPromo,
                      onChanged: (value) {
                        setState(() {
                          _sendEmailPromo = value ?? false;
                        });
                      },
                      activeColor: errorColor,
                      checkColor: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        'Send me email to get promo, offers and more',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Login link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Create Account button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || !_isFormValid) ? null : _handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid
                          ? errorColor
                          : errorColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Footer text
                Center(
                  child: Text(
                    'by creating an account, you agree to our\'s Privacy Policy and Terms of Use.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
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
