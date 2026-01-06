import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  static SupabaseClient get client => Supabase.instance.client;

  static String? get uid => client.auth.currentUser?.id;

  static void requireAuth() {
    if (uid == null) throw StateError('User not authenticated');
  }
}
