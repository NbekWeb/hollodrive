class PreferencesConstants {
  // Display options (for UI)
  static const List<String> chattingOptions = [
    'No Communication',
    'Light Chat',
    'Friendly Chat',
  ];

  static const List<String> temperatureOptions = [
    'Warm',
    'Comfortable',
    'Cool',
    'Cold',
  ];

  static const List<String> musicOptions = [
    'Pop',
    'Rock',
    'Jazz',
    'Classical',
    'Hip Hop',
    'Electronic',
    'Country',
    'No Music',
  ];

  static const List<String> volumeOptions = [
    'Low',
    'Medium',
    'High',
    'Mute',
  ];

  // Default values
  static const String defaultChatting = 'No Communication';
  static const String defaultTemperature = 'Warm';
  static const String defaultMusic = 'Pop';
  static const String defaultVolume = 'Low';

  // Map display values to API values
  static String getChattingApiValue(String displayValue) {
    switch (displayValue) {
      case 'No Communication':
        return 'no_communication';
      case 'Light Chat':
        return 'casual';
      case 'Friendly Chat':
        return 'friendly';
      default:
        return 'no_communication';
    }
  }

  static String getTemperatureApiValue(String displayValue) {
    switch (displayValue) {
      case 'Warm':
        return 'warm';
      case 'Comfortable':
        return 'comfortable';
      case 'Cool':
        return 'cool';
      case 'Cold':
        return 'cold';
      default:
        return 'warm';
    }
  }

  static String getMusicApiValue(String displayValue) {
    switch (displayValue) {
      case 'Pop':
        return 'pop';
      case 'Rock':
        return 'rock';
      case 'Jazz':
        return 'jazz';
      case 'Classical':
        return 'classical';
      case 'Hip Hop':
        return 'hip_hop';
      case 'Electronic':
        return 'electronic';
      case 'Country':
        return 'country';
      case 'No Music':
        return 'no_music';
      default:
        return 'pop';
    }
  }

  static String getVolumeApiValue(String displayValue) {
    switch (displayValue) {
      case 'Low':
        return 'low';
      case 'Medium':
        return 'medium';
      case 'High':
        return 'high';
      case 'Mute':
        return 'mute';
      default:
        return 'low';
    }
  }
}
