import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:dio/dio.dart';
import '../../colors.dart';
import '../../components/auth/auth_app_bar.dart';
import '../../components/auth/custom_input_field.dart';
import '../../components/auth/profile_picture_picker.dart';
import '../../components/auth/phone_input_field.dart';
import '../../components/auth/custom_dropdown.dart';
import '../../components/usefull/custom_toast.dart';
import '../../services/api/user.dart';
import '../dashboard/home_page.dart';

class EditProfilePage extends StatefulWidget {
  final bool fromPreferences;
  
  const EditProfilePage({
    super.key,
    this.fromPreferences = false,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailValid = false;
  bool _isSubmitting = false;
  File? _selectedAvatar;
  String? _avatarUrl; // Store avatar URL from API
  bool _hasPhoneNumber = false; // Track if phone number exists

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await UserApi.getUser();
      if (response.data is Map) {
        final userData = response.data['data'];
        if (userData != null) {
          setState(() {
            _fullNameController.text = userData['full_name']?.toString() ?? '';
            _emailController.text = userData['email']?.toString() ?? '';
            
            // Check if phone number exists
            final phoneNumber = userData['phone_number']?.toString();
            if (phoneNumber != null && phoneNumber.isNotEmpty && phoneNumber != 'null') {
              _phoneController.text = phoneNumber;
              _hasPhoneNumber = true;
            } else {
              _hasPhoneNumber = false;
            }
            
            _selectedGender = userData['gender']?.toString();
            if (userData['date_of_birth'] != null) {
              _dateOfBirthController.text = userData['date_of_birth'].toString();
            }
            // Load avatar URL
            if (userData['avatar'] != null && userData['avatar'].toString().isNotEmpty) {
              _avatarUrl = userData['avatar'].toString();
            }
          });
        }
      }
    } catch (error) {
      print('Error loading user data: $error');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
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

  bool get _isFormValid {
    // Phone number is required only if it doesn't exist yet
    final phoneRequired = !_hasPhoneNumber;
    
    // Check if phone number is fully entered (10 digits for Canada)
    bool phoneValid = true;
    if (phoneRequired) {
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      phoneValid = phoneDigits.length == 10; // Full phone number must be 10 digits
    }
    
    return _fullNameController.text.isNotEmpty &&
        _selectedGender != null &&
        _dateOfBirthController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _isEmailValid &&
        phoneValid;
  }

  String? _formatDateOfBirth(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    // Remove dashes and spaces to get pure digits
    final cleaned = dateStr.replaceAll(RegExp(r'[^\d]'), '');
    
    // Must be exactly 8 digits (DDMMYYYY)
    if (cleaned.length != 8) {
      print('Warning: Date must be 8 digits (DD-MM-YYYY), got: ${cleaned.length}');
      return null;
    }
    
    final day = cleaned.substring(0, 2);
    final month = cleaned.substring(2, 4);
    final year = cleaned.substring(4, 8);
    
    // Validate day (01-31)
    final dayInt = int.tryParse(day);
    if (dayInt == null || dayInt < 1 || dayInt > 31) {
      print('Warning: Invalid day: $day');
      return null;
  }

    // Validate month (01-12)
    final monthInt = int.tryParse(month);
    if (monthInt == null || monthInt < 1 || monthInt > 12) {
      print('Warning: Invalid month: $month');
      return null;
    }
    
    // Validate year (1920 to current year)
    final yearInt = int.tryParse(year);
    final currentYear = DateTime.now().year;
    if (yearInt == null || yearInt < 1920 || yearInt > currentYear) {
      print('Warning: Invalid year: $year (must be between 1920 and $currentYear)');
      return null;
    }
    
    // Validate day for specific month (e.g., February can't have 31 days)
    final daysInMonth = DateTime(yearInt, monthInt + 1, 0).day;
    if (dayInt > daysInMonth) {
      print('Warning: Invalid day $dayInt for month $month (max: $daysInMonth)');
      return null;
    }
    
    // Convert DD-MM-YYYY to YYYY-MM-DD
    return '$year-$month-$day';
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate() || !_isFormValid || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Format date of birth from DD-MM-YYYY to YYYY-MM-DD
      final formattedDateOfBirth = _formatDateOfBirth(_dateOfBirthController.text.trim());
      
      print('Original date: ${_dateOfBirthController.text.trim()}');
      print('Formatted date: $formattedDateOfBirth');
      
      // Update profile with or without avatar
      await UserApi.updateProfile(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: formattedDateOfBirth,
        phoneNumber: _phoneController.text.trim(),
        avatar: _selectedAvatar, // Will be null if no avatar selected
      );

      if (mounted) {
        // Clear user cache after profile update
        UserApi.clearCache();
        
        CustomToast.showSuccess(context, 'Profile updated successfully');
      // Navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
      }
    } catch (e) {
      print('Error updating profile: $e');
      print('Error type: ${e.runtimeType}');
      
      String errorMessage = 'Failed to update profile. Please try again.';
      
      if (e is DioException && e.response != null) {
        print('DioException details:');
        print('Status code: ${e.response!.statusCode}');
        print('Response data: ${e.response!.data}');
        print('Response data type: ${e.response!.data.runtimeType}');
        print('Response headers: ${e.response!.headers}');
        
        final responseData = e.response!.data;
        if (responseData is Map) {
          print('Response data keys: ${responseData.keys.toList()}');
          
          if (responseData['errors'] != null) {
            print('Errors found: ${responseData['errors']}');
            final errors = responseData['errors'];
            if (errors is Map) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError[0].toString();
              } else if (firstError is String) {
                errorMessage = firstError;
              }
            } else if (errors is String) {
              errorMessage = errors;
            }
          } else if (responseData['detail'] != null) {
            errorMessage = responseData['detail'].toString();
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          } else {
            // Print full response for debugging
            errorMessage = 'Error: ${responseData.toString()}';
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      }
      
      print('Final error message: $errorMessage');
      
      if (mounted) {
        CustomToast.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);
    final errorColor = AppColors.getErrorColor(brightness);
    final surfaceColor = AppColors.getSurfaceColor(brightness);
    final disabledColor = const Color(0xFF262626);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AuthAppBar(
        actionText: 'Edit profile',
        onBackPressed: () {
          // Always go back to previous page (normal navigation)
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Subtitle
                      Center(
                        child: Text(
                          'Customize your profile by adding a photo, updating your personal details.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Profile picture picker
                      ProfilePicturePicker(
                        initialImageUrl: _avatarUrl,
                        onImageSelected: (image) {
                          setState(() {
                            _selectedAvatar = image;
                            // Clear avatar URL when new image is selected
                            if (image != null) {
                              _avatarUrl = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      // Full Name input
                      CustomInputField(
                        label: 'Full Name',
                        hintText: 'First and last name',
                        controller: _fullNameController,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      // Gender and Date of Birth in one row
                      Row(
                        children: [
                          Expanded(
                            child: CustomDropdown<String>(
                              label: 'Gender',
                              value: _selectedGender,
                              items: _genderOptions,
                              getLabel: (item) => item,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                              backgroundColor: surfaceColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateOfBirthField(surfaceColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Email input (disabled - cannot be changed)
                      CustomInputField(
                        label: 'Email address',
                        hintText: 'Your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: false, // Email cannot be changed
                        onChanged: (_) {
                          _validateEmail();
                          setState(() {});
                        },
                        suffixIcon: _isEmailValid
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF28A745),
                                size: 24,
                              )
                            : null,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Phone Number input (enabled only if phone_number is null)
                      PhoneInputField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        enabled: !_hasPhoneNumber, // Enabled only if phone number doesn't exist
                        onChanged: (_) => setState(() {}), // Update form validation in real-time
                        onValidationChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      // Note about phone number
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Your phone number can\'t be changed. If you want to link your account to another phone number, please contact ',
                              ),
                              TextSpan(
                                text: 'Customer Support',
                                style: TextStyle(
                                  color: errorColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: errorColor,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Handle customer support link
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            // Fixed bottom button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isFormValid && !_isSubmitting) ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid ? errorColor : disabledColor,
                    disabledBackgroundColor: disabledColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                    'Continue',
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
          ],
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField(Color surfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _dateOfBirthController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              _DateInputFormatter(),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'DD-MM-YYYY',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: Icon(
                Icons.calendar_today,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 8 digits (DDMMYYYY)
    if (digitsOnly.length > 8) {
      return oldValue;
    }

    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '-';
      }
      
      final digit = digitsOnly[i];
      
      // Validate as user types
      if (i == 0) {
        // First digit of day: 0-3
        if (int.tryParse(digit) != null && int.parse(digit) > 3) {
          return oldValue; // Invalid first digit for day
        }
      } else if (i == 1) {
        // Second digit of day: validate with first digit
        final day = digitsOnly.substring(0, 2);
        final dayInt = int.tryParse(day);
        if (dayInt != null && dayInt > 31) {
          return oldValue; // Day can't be > 31
        }
      } else if (i == 2) {
        // First digit of month: 0-1
        if (int.tryParse(digit) != null && int.parse(digit) > 1) {
          return oldValue; // Invalid first digit for month
        }
      } else if (i == 3) {
        // Second digit of month: validate with first digit
        final month = digitsOnly.substring(2, 4);
        final monthInt = int.tryParse(month);
        if (monthInt != null && monthInt > 12) {
          return oldValue; // Month can't be > 12
        }
      } else if (i == 4) {
        // First digit of year: must be 1 or 2 (for 1920-2024 range)
        if (int.tryParse(digit) != null && int.parse(digit) < 1) {
          return oldValue;
        }
      } else if (i == 5) {
        // Second digit of year: validate with first digit
        final yearStart = digitsOnly.substring(4, 6);
        final yearStartInt = int.tryParse(yearStart);
        if (yearStartInt != null) {
          // Year must start with 19 or 20 (for 1920-2024 range)
          if (yearStartInt < 19 || yearStartInt > 20) {
            return oldValue;
          }
        }
      } else if (i == 6) {
        // Third digit of year: validate
        final yearStart = digitsOnly.substring(4, 7);
        final yearStartInt = int.tryParse(yearStart);
        if (yearStartInt != null) {
          // If year starts with 19, third digit can be 2-9 (for 1920-1999)
          // If year starts with 20, third digit can be 0-4 (for 2000-2024)
          if (digitsOnly[4] == '1') {
            // Year starts with 19
            if (yearStartInt < 192) {
              return oldValue; // Must be at least 192
            }
            if (int.parse(digit) < 2 || int.parse(digit) > 9) {
              return oldValue;
            }
          } else if (digitsOnly[4] == '2') {
            // Year starts with 20
            if (int.parse(digit) < 0 || int.parse(digit) > 4) {
              return oldValue;
            }
          }
        }
      } else if (i == 7) {
        // Fourth digit of year: validate full year
        final year = digitsOnly.substring(4, 8);
        final yearInt = int.tryParse(year);
        final currentYear = DateTime.now().year;
        if (yearInt != null) {
          if (yearInt < 1920) {
            return oldValue; // Year must be at least 1920
          }
          if (yearInt > currentYear) {
            return oldValue; // Year can't be in the future
          }
        }
      }
      
      formatted += digit;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

