import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/format.dart';
import '../../data/repos/balances_repo.dart';
import '../../data/repos/expenses_repo.dart';
import '../../data/repos/groups_repo.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final expensesRepo = ExpensesRepo();
  final balancesRepo = BalancesRepo();
  final groupsRepo = GroupsRepo();

  late Future<List<Map<String, dynamic>>> _expensesF;
  late Future<List<Map<String, dynamic>>> _balancesF;
  late Future<List<Map<String, dynamic>>> _membersF;

  // ✅ filtros / agrupación de gastos
  bool groupByPerson = false;
  String query = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _expensesF = expensesRepo.listExpenses(widget.groupId);
    _balancesF = balancesRepo.getGroupBalances(widget.groupId);
    _membersF = groupsRepo.listMembers(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grupo ${Fmt.shortId(widget.groupId)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ✅ NUEVO: Tu resumen (usa expenses + balances)
          _YourSummaryCard(
            expensesFuture: _expensesF,
            balancesFuture: _balancesF,
          ),
          const SizedBox(height: 12),

          // ✅ NUEVO: Balance por persona en card aparte
          _BalancesByPersonCard(
            groupId: widget.groupId,
            balancesFuture: _balancesF,
            debtsFuture: balancesRepo.getGroupDebts(widget.groupId), // 👈 nuevo
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _MembersChips(membersFuture: _membersF)),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/groups/${widget.groupId}/members/add'),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Agregar'),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text('Gastos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await context.push('/groups/${widget.groupId}/expense/create');
                if (context.mounted) setState(_refresh);
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar gasto'),
            ),
          ),

          const SizedBox(height: 12),

          const SizedBox(height: 8),

          // ✅ buscador + toggle
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar gasto…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Por persona'),
                selected: groupByPerson,
                onSelected: (v) => setState(() => groupByPerson = v),
              ),
            ],
          ),
          const SizedBox(height: 8),

          FutureBuilder(
            future: _expensesF,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) return Text('Error: ${snap.error}');
              final items = snap.data ?? const [];

              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Todavía no hay gastos')),
                );
              }

              String payerName(Map<String, dynamic> e) {
                final who = (e['profiles'] as Map?)?['display_name'];
                return (who ?? 'Alguien').toString();
              }

              bool matchesFilters(Map<String, dynamic> e) {
                if (query.isEmpty) return true;
                final desc = (e['description'] ?? '').toString().toLowerCase();
                final who = payerName(e).toLowerCase();
                return desc.contains(query) || who.contains(query);
              }

              final filtered = items.where(matchesFilters).toList();

              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No hay resultados con esos filtros')),
                );
              }

              // ✅ lista plana
              if (!groupByPerson) {
                return Column(
                  children: filtered.map((e) {
                    final who = payerName(e);
                    return Card(
                      child: ListTile(
                        title: Text(e['description'] ?? 'Gasto'),
                        subtitle: Text('Pagó: $who'),
                        trailing: Text(Fmt.money(e['total'] ?? 0)),
                      ),
                    );
                  }).toList(),
                );
              }

              // ✅ agrupado por persona
              final Map<String, List<Map<String, dynamic>>> grouped = {};
              for (final e in filtered) {
                final who = payerName(e);
                grouped.putIfAbsent(who, () => []).add(e);
              }

              final persons = grouped.keys.toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

              return Column(
                children: persons.map((person) {
                  final list = grouped[person]!;
                  final totalPerson = list.fold<num>(
                    0,
                    (a, e) => a + ((e['total'] as num?) ?? 0),
                  );

                  return Card(
                    child: ExpansionTile(
                      title: Text(person),
                      subtitle: Text('${list.length} gasto(s) • Total: ${Fmt.money(totalPerson)}'),
                      children: list.map((e) {
                        return ListTile(
                          dense: true,
                          title: Text(e['description'] ?? 'Gasto'),
                          trailing: Text(Fmt.money(e['total'] ?? 0)),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ✅ CARD 1: Tu resumen
class _YourSummaryCard extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> expensesFuture;
  final Future<List<Map<String, dynamic>>> balancesFuture;

  const _YourSummaryCard({
    required this.expensesFuture,
    required this.balancesFuture,
  });

  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([expensesFuture, balancesFuture]),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text('Cargando tu resumen…'),
                ],
              ),
            ),
          );
        }

        if (snap.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error resumen: ${snap.error}'),
            ),
          );
        }

        final expenses = (snap.data?[0] as List<Map<String, dynamic>>?) ?? const [];
        final balances = (snap.data?[1] as List<Map<String, dynamic>>?) ?? const [];

        final totalGroup = expenses.fold<num>(
          0,
          (a, e) => a + ((e['total'] as num?) ?? 0),
        );

        // ✅ TU ESQUEMA: paid_by
        final youPaid = (uid == null)
            ? 0
            : expenses.fold<num>(0, (a, e) {
                final paidBy = e['paid_by']?.toString();
                final amount = (e['total'] as num?) ?? 0;
                return a + (paidBy == uid ? amount : 0);
              });

        // ✅ TU RPC: user_id
        final me = (uid == null)
            ? null
            : balances.cast<Map<String, dynamic>?>().firstWhere(
                  (r) => r != null && r['user_id']?.toString() == uid,
                  orElse: () => null,
                );

        final yourBalance = (me == null) ? 0 : ((me['balance'] as num?) ?? 0);

        // ✅ Convención correcta: balance positivo = a favor (te deben)
        final teDeben = yourBalance > 0 ? yourBalance : 0;
        final tenesQuePoner = yourBalance < 0 ? yourBalance.abs() : 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu resumen', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _Metric(label: 'Total del grupo', value: Fmt.money(totalGroup))),
                    const SizedBox(width: 12),
                    Expanded(child: _Metric(label: 'Vos pusiste', value: Fmt.money(youPaid))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _Metric(label: 'Te deben', value: Fmt.money(teDeben))),
                    const SizedBox(width: 12),
                    Expanded(child: _Metric(label: 'Tenés que poner', value: Fmt.money(tenesQuePoner))),
                  ],
                ),
                const SizedBox(height: 12),
                // si querés mantenerlo como antes:
                Row(
                  children: [
                    Expanded(child: _Metric(label: 'Tu balance', value: Fmt.money(yourBalance))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ✅ CARD 2: Balance por persona
class _BalancesByPersonCard extends StatelessWidget {
  final String groupId;
  final Future<List<Map<String, dynamic>>> balancesFuture;
  final Future<List<Map<String, dynamic>>> debtsFuture;

  const _BalancesByPersonCard({
    required this.groupId,
    required this.balancesFuture,
    required this.debtsFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([balancesFuture, debtsFuture]),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text('Cargando balances…'),
                ],
              ),
            ),
          );
        }

        if (snap.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error balances: ${snap.error}'),
            ),
          );
        }

        final balances = (snap.data?[0] as List<Map<String, dynamic>>?) ?? const [];
        final debts = (snap.data?[1] as List<Map<String, dynamic>>?) ?? const [];

        // Mapa uid -> nombre (desde balances)
        final nameById = <String, String>{};
        for (final b in balances) {
          final uid = b['user_id']?.toString();
          if (uid == null) continue;
          nameById[uid] = (b['display_name'] ?? 'User').toString();
        }

        // Para cada persona, armamos lista "debe a" y "le deben"
        final owesTo = <String, List<_DebtLine>>{};
        final owedBy = <String, List<_DebtLine>>{};

        for (final d in debts) {
          final from = d['from_user']?.toString();
          final to = d['to_user']?.toString();
          final amount = (d['amount'] as num?) ?? 0;
          if (from == null || to == null || amount <= 0) continue;

          final toName = nameById[to] ?? to;     // fallback uid si falta
          final fromName = nameById[from] ?? from;

          owesTo.putIfAbsent(from, () => []).add(_DebtLine(userId: to, name: toName, amount: amount));
          owedBy.putIfAbsent(to, () => []).add(_DebtLine(userId: from, name: fromName, amount: amount));
        }

        // orden amigable
        for (final k in owesTo.keys) {
          owesTo[k]!.sort((a, b) => b.amount.compareTo(a.amount));
        }
        for (final k in owedBy.keys) {
          owedBy[k]!.sort((a, b) => b.amount.compareTo(a.amount));
        }

        final debtTextStyle = Theme.of(context).textTheme.bodySmall;
        final owesColor = Colors.red;
        final owedColor = Colors.green;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance por persona', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),

                ...balances.map((b) {
                  final uid = b['user_id']?.toString() ?? '';
                  final name = (b['display_name'] ?? 'User').toString();
                  final bal = (b['balance'] as num?) ?? 0;

                  final lines = bal < 0 ? (owesTo[uid] ?? const []) : (owedBy[uid] ?? const []);
                  final title = bal < 0 ? 'Debe a' : 'Le deben';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              Fmt.money(bal),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: bal >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),

                        if (bal != 0) ...[
                          const SizedBox(height: 6),
                          if (lines.isEmpty)
                            Text(
                              '$title: —',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$title:',
                                  style: debtTextStyle?.copyWith(
                                    color: bal < 0 ? owesColor : owedColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...lines.map((l) => Padding(
  padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
  child: InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: () {
      final isOwing = bal < 0; // esta persona "debe"
      final fromUser = isOwing ? uid : l.userId; // quien debe
      final toUser   = isOwing ? l.userId : uid; // a quien le deben

      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _DebtExplainSheet(
          groupId: groupId,
          fromUser: fromUser,
          toUser: toUser,
          fromName: nameById[fromUser] ?? 'User',
          toName: nameById[toUser] ?? 'User',
          netAmount: l.amount,
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '• ${l.name}',
              style: debtTextStyle?.copyWith(color: bal < 0 ? Colors.red : Colors.green),
            ),
          ),
          Text(
            Fmt.money(l.amount),
            style: debtTextStyle?.copyWith(
              color: bal < 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 18, color: (bal < 0 ? Colors.red : Colors.green)),
        ],
      ),
    ),
  ),
)),

                              ],
                            ),
                        ],

                        const SizedBox(height: 8),
                        const Divider(height: 1),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DebtLine {
  final String userId;
  final String name;
  final num amount;
  _DebtLine({required this.userId, required this.name, required this.amount});
}


class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MembersChips extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> membersFuture;
  const _MembersChips({required this.membersFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: membersFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
        if (snap.hasError) return Text('Error miembros: ${snap.error}');
        final rows = snap.data ?? const [];

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rows.map((r) {
            final profile = (r['profiles'] as Map?) ?? {};
            final name = (profile['display_name'] ?? 'User').toString();
            final role = (r['role'] ?? 'member').toString();
            return Chip(label: Text(role == 'owner' ? '👑 $name' : name));
          }).toList(),
        );
      },
    );
  }
}

class _DebtExplainSheet extends StatefulWidget {
  final String groupId;
  final String fromUser;
  final String toUser;
  final String fromName;
  final String toName;
  final num netAmount;

  const _DebtExplainSheet({
    required this.groupId,
    required this.fromUser,
    required this.toUser,
    required this.fromName,
    required this.toName,
    required this.netAmount,
  });

  @override
  State<_DebtExplainSheet> createState() => _DebtExplainSheetState();
}

class _DebtExplainSheetState extends State<_DebtExplainSheet> {
  late final Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    final repo = BalancesRepo();

    // debug
    debugPrint('PAIR DETAIL -> gid=${widget.groupId} a=${widget.fromUser} b=${widget.toUser}');

    _future = repo
        .getPairDebtDetail(groupId: widget.groupId, a: widget.fromUser, b: widget.toUser)
        .timeout(const Duration(seconds: 12));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            // 👇 esto te confirma si está “waiting” infinito
            debugPrint('PAIR SNAP state=${snap.connectionState} hasData=${snap.hasData} hasError=${snap.hasError}');

            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No pude cargar el detalle', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(snap.error.toString()),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              );
            }

            final rows = snap.data ?? const <Map<String, dynamic>>[];

            if (rows.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detalle', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('No hay items entre estas dos personas (o quedó neteado en 0).'),
                  ],
                ),
              );
            }

            // --------- tu lógica actual (owes/counter) ----------
            final owes = <Map<String, dynamic>>[];
            final counter = <Map<String, dynamic>>[];

            for (final r in rows) {
              final fu = r['from_user']?.toString();
              final tu = r['to_user']?.toString();
              if (fu == widget.fromUser && tu == widget.toUser) {
                owes.add(r);
              } else if (fu == widget.toUser && tu == widget.fromUser) {
                counter.add(r);
              }
            }

            num sumOwes = owes.fold<num>(0, (a, r) => a + ((r['amount'] as num?) ?? 0));
            num sumCounter = counter.fold<num>(0, (a, r) => a + ((r['amount'] as num?) ?? 0));
            final computedNet = (sumOwes - sumCounter);

            return ListView(
              shrinkWrap: true,
              children: [
                Text('Detalle de deuda', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                // Relación
                Text(
                  '${widget.fromName} a ${widget.toName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),

                // Monto protagonista
                Center(
                  child: Column(
                    children: [
                      Text(
                        Fmt.money(widget.netAmount),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.red, // si querés, luego lo hacemos dinámico
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deuda neta',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),


                const SizedBox(height: 10),
                if (owes.isNotEmpty) ...[
                  Text('Gastos donde ${widget.toName} pagó y ${widget.fromName} participó',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  ...owes.map((r) => _DebtExpenseRow(
                        description: (r['description'] ?? 'Gasto').toString(),
                        date: (r['expense_date'] ?? '').toString(),
                        amount: (r['amount'] as num?) ?? 0,
                        color: Colors.red,
                      )),
                ],

                const SizedBox(height: 10),
                if (counter.isNotEmpty) ...[
                  Text('Gastos donde ${widget.fromName} pagó y ${widget.toName} participó (compensa)',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  ...counter.map((r) => _DebtExpenseRow(
                        description: (r['description'] ?? 'Gasto').toString(),
                        date: (r['expense_date'] ?? '').toString(),
                        amount: (r['amount'] as num?) ?? 0,
                        color: Colors.green,
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}


class _DebtExpenseRow extends StatelessWidget {
  final String description;
  final String date;
  final num amount;
  final Color color;

  const _DebtExpenseRow({
    required this.description,
    required this.date,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.bodySmall;
    return Card(
      child: ListTile(
        dense: true,
        title: Text(description),
        subtitle: Text(date, style: s),
        trailing: Text(
          Fmt.money(amount),
          style: s?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

