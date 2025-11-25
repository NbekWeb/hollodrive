import 'package:flutter/material.dart';
import 'custom_dropdown.dart';
import 'preferences_constants.dart';

class PreferencesForm extends StatelessWidget {
  final String chattingPreference;
  final String temperaturePreference;
  final String musicPreference;
  final String volumeLevel;
  final Color surfaceColor;
  final ValueChanged<String> onChattingChanged;
  final ValueChanged<String> onTemperatureChanged;
  final ValueChanged<String> onMusicChanged;
  final ValueChanged<String> onVolumeChanged;

  const PreferencesForm({
    super.key,
    required this.chattingPreference,
    required this.temperaturePreference,
    required this.musicPreference,
    required this.volumeLevel,
    required this.surfaceColor,
    required this.onChattingChanged,
    required this.onTemperatureChanged,
    required this.onMusicChanged,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chatting Preferences
        CustomDropdown<String>(
          label: 'Chatting Preferences',
          value: chattingPreference,
          items: PreferencesConstants.chattingOptions,
          getLabel: (item) => item,
          onChanged: (value) => onChattingChanged(value!),
          backgroundColor: surfaceColor,
        ),
        const SizedBox(height: 16),
        // Temperature Preferences
        CustomDropdown<String>(
          label: 'Temperature Preferences',
          value: temperaturePreference,
          items: PreferencesConstants.temperatureOptions,
          getLabel: (item) => item,
          onChanged: (value) => onTemperatureChanged(value!),
          backgroundColor: surfaceColor,
        ),
        const SizedBox(height: 16),
        // Music Preferences
        CustomDropdown<String>(
          label: 'Music Preferences',
          value: musicPreference,
          items: PreferencesConstants.musicOptions,
          getLabel: (item) => item,
          onChanged: (value) => onMusicChanged(value!),
          backgroundColor: surfaceColor,
        ),
        const SizedBox(height: 16),
        // Volume Level
        CustomDropdown<String>(
          label: 'Volume Level',
          value: volumeLevel,
          items: PreferencesConstants.volumeOptions,
          getLabel: (item) => item,
          onChanged: (value) => onVolumeChanged(value!),
          backgroundColor: surfaceColor,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
