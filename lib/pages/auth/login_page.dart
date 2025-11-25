import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../components/auth/auth_app_bar.dart';
import '../../components/auth/phone_input_field.dart';
import '../../components/auth/social_login_button.dart';
import '../../components/auth/or_separator.dart';
import 'verification_code_page.dart';
import 'login_with_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isPhoneValid = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _handlePhoneValidationChanged(bool isValid) {
    setState(() {
      _isPhoneValid = isValid;
    });
  }

  void _handleLogin() {
    if (_isPhoneValid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationCodePage(
            phoneNumber: _phoneController.text,
          ),
        ),
      );
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
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Title
              const Text(
                'Enter your number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'We will send a code to verify your mobile number',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              // Phone number input
              PhoneInputField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                onValidationChanged: _handlePhoneValidationChanged,
              ),
              const SizedBox(height: 24),
              // Login button
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPhoneValid ? _handleLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPhoneValid ? errorColor : disabledColor,
                    disabledBackgroundColor: disabledColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: _isPhoneValid
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Separator
              const OrSeparator(),
              const SizedBox(height: 24),
              // Login with email link
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginWithPasswordPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Login with email',
                    style: TextStyle(
                      color: errorColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: errorColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Social login buttons
              SocialLoginButton(
                iconPath: 'assets/svg/google.svg',
                text: 'Continue with Google',
                onPressed: () {
                  // Handle Google login
                },
              ),
              const SizedBox(height: 12),
              SocialLoginButton(
                iconPath: 'assets/svg/facebook.svg',
                text: 'Continue with Facebook',
                onPressed: () {
                  // Handle Facebook login
                },
              ),
              const SizedBox(height: 12),
              SocialLoginButton(
                iconPath: 'assets/svg/apple.svg',
                text: 'Continue with Apple',
                onPressed: () {
                  // Handle Apple login
                },
              ),
              const SizedBox(height: 24),
              // Divider
              Divider(
                color: Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
              const SizedBox(height: 16),
              // Register link
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      children: [
                        const TextSpan(text: 'Don\'t have an account? '),
                        TextSpan(
                          text: 'Register',
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
              // Footer links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      // Navigate to privacy policy
                    },
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    ' • ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to terms of service
                    },
                    child: Text(
                      'Terms of Service',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

