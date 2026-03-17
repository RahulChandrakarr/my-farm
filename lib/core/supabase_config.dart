/// Project URL + anon (publishable) key. Override with --dart-define if needed.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://crhcncqlezwlkgqtirau.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'sb_publishable_jKneqsBzC8Prh9vZqAgPUQ_Nh1lBnpQ',
  );

  static bool get isConfigured =>
      url.startsWith('https://') && anonKey.isNotEmpty;
}
