import '../../core/supabase.dart';

class GroupMembersRepo {
  Future<Map<String, dynamic>> addMember(String groupId, String userId) async {
    final res = await AppSupabase.client.rpc('add_group_member', params: {
      'gid': groupId,
      'member_id': userId,
    });
    return Map<String, dynamic>.from(res as Map);
  }
}
