import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../colors.dart';
import '../../components/auth/auth_app_bar.dart';
import '../../components/auth/preferences_header.dart';
import '../../components/auth/preferences_form.dart';
import '../../components/auth/preferences_actions.dart';
import '../../components/auth/preferences_constants.dart';
import '../../components/usefull/custom_toast.dart';
import '../../services/api/base_api.dart';
import '../../services/api/user.dart';
import 'edit_profile_page.dart';
import 'register_page.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  String _chattingPreference = PreferencesConstants.defaultChatting;
  String _temperaturePreference = PreferencesConstants.defaultTemperature;
  String _musicPreference = PreferencesConstants.defaultMusic;
  String _volumeLevel = PreferencesConstants.defaultVolume;
  bool _isSubmitting = false;

  Future<void> _handleNextOrSkip() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Check if token exists before making request
      final hasToken = await ApiService.hasToken();
      print('PreferencesPage: Has token: $hasToken');
      
      if (!hasToken) {
        if (mounted) {
          CustomToast.showError(context, 'Session expired. Please login again.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          );
        }
        return;
      }

      // Convert display values to API values
      final chattingApi = PreferencesConstants.getChattingApiValue(_chattingPreference);
      final temperatureApi = PreferencesConstants.getTemperatureApiValue(_temperaturePreference);
      final musicApi = PreferencesConstants.getMusicApiValue(_musicPreference);
      final volumeApi = PreferencesConstants.getVolumeApiValue(_volumeLevel);

      print('PreferencesPage: Sending preferences to API');
      print('Chatting: $chattingApi, Temperature: $temperatureApi, Music: $musicApi, Volume: $volumeApi');

      // Send preferences to API
      await UserApi.createOrUpdatePreferences(
        chattingPreference: chattingApi,
        temperaturePreference: temperatureApi,
        musicPreference: musicApi,
        volumeLevel: volumeApi,
      );

      // Navigate to edit profile page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EditProfilePage(fromPreferences: true),
          ),
        );
      }
    } catch (e) {
      print('Error saving preferences: $e');
      
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to save preferences';
        
        // Extract error message from response
        if (responseData is Map) {
          if (responseData['errors'] != null) {
            final errors = responseData['errors'];
            if (errors is Map) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError[0].toString();
              } else if (firstError is String) {
                errorMessage = firstError;
              }
            }
          } else if (responseData['detail'] != null) {
            errorMessage = responseData['detail'].toString();
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          }
        }
        
        if (mounted) {
          CustomToast.showError(context, errorMessage);
        }
      } else {
        if (mounted) {
          CustomToast.showError(context, 'Failed to save preferences. Please try again.');
        }
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AuthAppBar(
        actionText: 'Registration',
        onBackPressed: () async {
          // Clear access token and navigate to register page
          await ApiService.clearToken();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            );
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PreferencesHeader(),
                    PreferencesForm(
                      chattingPreference: _chattingPreference,
                      temperaturePreference: _temperaturePreference,
                      musicPreference: _musicPreference,
                      volumeLevel: _volumeLevel,
                      surfaceColor: surfaceColor,
                      onChattingChanged: (value) {
                        setState(() {
                          _chattingPreference = value;
                        });
                      },
                      onTemperatureChanged: (value) {
                        setState(() {
                          _temperaturePreference = value;
                        });
                      },
                      onMusicChanged: (value) {
                        setState(() {
                          _musicPreference = value;
                        });
                      },
                      onVolumeChanged: (value) {
                        setState(() {
                          _volumeLevel = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            PreferencesActions(
              isSubmitting: _isSubmitting,
              backgroundColor: backgroundColor,
              errorColor: errorColor,
              onNextOrSkip: _handleNextOrSkip,
            ),
          ],
        ),
      ),
    );
  }
}
