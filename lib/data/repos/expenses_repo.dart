import '../../core/supabase.dart';

class ExpensesRepo {
  Future<List<Map<String, dynamic>>> listExpenses(String groupId) async {
    final rows = await AppSupabase.client
        .from('expenses')
        .select('id, description, total, currency, expense_date, paid_by, profiles:profiles!expenses_paid_by_fkey(display_name)')
        .eq('group_id', groupId)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<String> createExpense({
    required String groupId,
    required String description,
    required String paidBy,
    required String currency,
    required num total,
    required DateTime expenseDate,
    required Map<String, num> sharesByUser, // user_id -> share
  }) async {
    AppSupabase.requireAuth();
    final uid = AppSupabase.uid!;

    // 1) insert expense
    final expense = await AppSupabase.client
        .from('expenses')
        .insert({
          'group_id': groupId,
          'created_by': uid,
          'paid_by': paidBy,
          'description': description,
          'currency': currency,
          'total': total,
          'expense_date': expenseDate.toIso8601String().substring(0, 10),
        })
        .select('id')
        .single();

    final expenseId = expense['id'] as String;

    // 2) insert shares
    final rows = sharesByUser.entries.map((e) {
      return {
        'expense_id': expenseId,
        'user_id': e.key,
        'share': e.value,
      };
    }).toList();

    await AppSupabase.client.from('expense_shares').insert(rows);

    return expenseId;
  }
}
