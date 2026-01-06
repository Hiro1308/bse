import '../../core/supabase.dart';

class FriendsRepo {
  Future<Map<String, dynamic>> sendRequestByEmail(String email) async {
    final res = await AppSupabase.client.rpc('send_friend_request', params: {'email_to': email});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> acceptRequest(String requestId) async {
    final res = await AppSupabase.client.rpc('accept_friend_request', params: {'request_id': requestId});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<List<Map<String, dynamic>>> listAcceptedFriends() async {
    final rows = await AppSupabase.client
        .from('v_my_friends')
        .select('friend_id, display_name, email, friendship_id')
        .order('display_name', ascending: true);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listIncomingPending() async {
    final uid = AppSupabase.uid!;
    final rows = await AppSupabase.client
        .from('friendships')
        .select('id, requester, addressee, status, created_at, profiles!friendships_requester_fkey(display_name, email)')
        .eq('addressee', uid)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }
}
