class AppConstants {
  static const String appName = 'OctetPulse';
  static const String appTagline = 'Enterprise Workforce & Encrypted VoIP';
  static const String appVersion = '1.0.0+1';

  // HQ Geofence Coordinates (Lahore Tech Corridor - Arfa Software Technology Park)
  static const double hqLatitude = 31.4754;
  static const double hqLongitude = 74.3436;
  static const double hqGeofenceRadiusMeters = 150.0;
  static const String hqLocationName = 'Lahore ASTP HQ';

  // VoIP Channel Identifiers
  static const String voipControlChannel = 'com.safeer.octetpulse/voip_control';
  static const String voipTelemetryChannel = 'com.safeer.octetpulse/voip_telemetry';

  // Currency Exchange Rate (Mock USD to PKR)
  static const double usdToPkrRate = 278.50;

  // SharedPreferences Keys
  static const String prefThemeMode = 'octet_theme_mode';
  static const String prefSimulatedLatencyMs = 'octet_sim_latency_ms';
  static const String prefForce503Error = 'octet_force_503';
  static const String prefCurrencyIsUsd = 'octet_currency_is_usd';
}
