import '../../core/supabase.dart';

class GroupsRepo {
  Future<List<Map<String, dynamic>>> listMyGroups() async {
    AppSupabase.requireAuth();
    final uid = AppSupabase.uid!;

    final rows = await AppSupabase.client
        .from('group_members')
        .select('group_id, joined_at, groups(id, name, created_at)')
        .eq('user_id', uid)
        .order('joined_at', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<String> createGroup({required String name}) async {
    AppSupabase.requireAuth();

    final dbg = await AppSupabase.client.rpc('debug_auth');
    print('DEBUG_AUTH => $dbg');

    final group = await AppSupabase.client
        .from('groups')
        .insert({'name': name})
        .select('id')
        .single();

    final groupId = group['id'] as String;

    return groupId;
  }

  Future<List<Map<String, dynamic>>> listMembers(String groupId) async {
    final rows = await AppSupabase.client
        .from('group_members')
        .select('user_id, role, profiles(display_name)')
        .eq('group_id', groupId)
        .order('role', ascending: true);

    return (rows as List).cast<Map<String, dynamic>>();
  }
}
