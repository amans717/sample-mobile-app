class SupabaseConstants {
  // Replace these with your actual Supabase project credentials
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-id.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );

  // Storage Bucket
  static const String storageBucket = 'call-recordings';

  // Database Tables
  static const String recordingsTable = 'call_recordings';

  // Check if credentials have been replaced with real credentials
  static bool get isConfigured {
    return !supabaseUrl.contains('your-project-id') &&
        !supabaseAnonKey.contains('your-anon-key-here') &&
        supabaseUrl.startsWith('https://');
  }
}
