import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://apnbsrqudsektmzulfbv.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwbmJzcnF1ZHNla3RtenVsZmJ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwODYzMTAsImV4cCI6MjA4NzY2MjMxMH0.DXzPFUQtONceMOqs-NJH0sxfDXws2TRXfzL_RTWXSdE';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
