import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../components/auth/auth_app_bar.dart';
import '../../components/auth/custom_input_field.dart';
import 'link_sent_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
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

  void _handleResetPassword() {
    if (_formKey.currentState!.validate() && _isEmailValid) {
      // Navigate to link sent page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LinkSentPage(email: _emailController.text),
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
                  'Reset password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'Enter your email to reset password',
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
                const SizedBox(height: 32),
                // Reset password button
                Center(
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isEmailValid ? _handleResetPassword : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEmailValid ? errorColor : disabledColor,
                        disabledBackgroundColor: disabledColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Reset password',
                        style: TextStyle(
                          color: _isEmailValid 
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
    );
  }
}

