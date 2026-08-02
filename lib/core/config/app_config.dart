class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const String notesBoxName = 'notes';
  static const String queueBoxName = 'sync_queue';
  static const String appTitle = 'Note Book';
}
