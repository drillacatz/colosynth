class AppConfig {
  AppConfig._();

  static const String env = String.fromEnvironment('ENV', defaultValue: 'development');
  static bool get isProduction => env == 'production';

  static const String hmacSecret = String.fromEnvironment('HMAC_SECRET');

  static const String firebaseAndroidApiKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const String firebaseAndroidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  
  static const String firebaseWebOAuthClientId = String.fromEnvironment('FIREBASE_WEB_OAUTH_CLIENT_ID');

  static const String revenueCatGoogleApiKey = String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY');



  static void validate() {
    if (isProduction) {
      final missingKeys = <String>[];
      if (hmacSecret.isEmpty) missingKeys.add('HMAC_SECRET');
      if (firebaseAndroidApiKey.isEmpty) missingKeys.add('FIREBASE_ANDROID_API_KEY');
      if (firebaseAndroidAppId.isEmpty) missingKeys.add('FIREBASE_ANDROID_APP_ID');
      if (firebaseProjectId.isEmpty) missingKeys.add('FIREBASE_PROJECT_ID');
      if (revenueCatGoogleApiKey.isEmpty) missingKeys.add('REVENUECAT_GOOGLE_API_KEY');

      if (missingKeys.isNotEmpty) {
        throw StateError(
          'FATAL: Colosynth production launch aborted due to missing critical environment secrets: '
          '${missingKeys.join(", ")}. '
          'Please ensure these keys are securely provided via --dart-define during compilation.',
        );
      }
    }
  }
}
