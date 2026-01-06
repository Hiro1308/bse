import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';

class AuthRepo {
  Future<void> signIn(String email, String password) async {
    await AppSupabase.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp(String name, String email, String password) async {
    await AppSupabase.client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': name.trim()},
    );
  }

  Future<void> signOut() async {
    await AppSupabase.client.auth.signOut();
  }
}
