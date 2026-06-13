/// Connection details for ActivHealth's OWN Supabase project
/// (`activhealth-prod`, ref lmzzfmpbnodbpozkdmbo) — a separate database in
/// the shared org, isolated from dittopix-prod.
///
/// Both values are PUBLIC client credentials: the publishable key is meant
/// to ship in the app and is protected by Row Level Security. The
/// service-role key must NEVER appear in the client.
///
/// Override at build time if needed:
///   flutter build ipa --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lmzzfmpbnodbpozkdmbo.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_KdicLb4CYQMz-z8MMPIzBw_hOjsnVPp',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  /// Deep-link the OAuth / magic-link flow returns to. Registered natively
  /// (iOS CFBundleURLTypes + Android intent-filter) and must be added to the
  /// Supabase Auth "Redirect URLs" allow-list.
  static const String authRedirect = 'activhealth://login-callback/';
}
