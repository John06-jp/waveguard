abstract final class AppConfig {
  static const firebaseEnabled = bool.fromEnvironment('USE_FIREBASE');
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const emergencyPhone = String.fromEnvironment('MDRRMO_PHONE');
  static const coastGuardPhone = String.fromEnvironment('COAST_GUARD_PHONE');
  static const policePhone = String.fromEnvironment('PNP_PHONE');
  static const healthUnitPhone = String.fromEnvironment('HEALTH_UNIT_PHONE');
  static const tileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static const tileAttribution = String.fromEnvironment(
    'MAP_ATTRIBUTION',
    defaultValue: '© OpenStreetMap contributors',
  );
  static const tileAttributionUrl = String.fromEnvironment(
    'MAP_ATTRIBUTION_URL',
    defaultValue: 'https://www.openstreetmap.org/copyright',
  );
  static const freshnessMinutes = int.fromEnvironment(
    'FRESHNESS_MINUTES',
    defaultValue: 60,
  );
}
