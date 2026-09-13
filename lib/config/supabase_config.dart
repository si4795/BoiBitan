import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  /// Supabase project URL. Can be passed via --dart-define=SUPABASE_URL=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://boibitan-library.supabase.co',
  );

  /// Supabase anon public key. Can be passed via --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvaWJpdGFuLWxpYnJhcnkiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTcwMDAwMDAwMCwiZXhwIjoyMDAwMDAwMDAwfQ.dummy_anon_key_for_boibitan',
  );

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('dummy');

  /// Safely initialize Supabase client.
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('Supabase initialized successfully: $supabaseUrl');
    } catch (e) {
      debugPrint(
        'Supabase init notice (operating in local resilient mode): $e',
      );
    }
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
