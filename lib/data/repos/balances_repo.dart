import '../../core/supabase.dart';

class BalancesRepo {
  Future<List<Map<String, dynamic>>> getGroupBalances(String groupId) async {
    final res = await AppSupabase.client.rpc('get_group_balances', params: {'gid': groupId});
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getGroupDebts(String groupId) async {
    final res = await AppSupabase.client.rpc('get_group_debts', params: {'gid': groupId});
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPairDebtDetail({
    required String groupId,
    required String a,
    required String b,
  }) async {
    final res = await AppSupabase.client.rpc(
      'get_pair_debt_detail',
      params: {'gid': groupId, 'a': a, 'b': b},
    );
    return (res as List).cast<Map<String, dynamic>>();
  }

}
