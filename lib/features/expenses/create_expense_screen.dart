import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/format.dart';
import '../../core/supabase.dart';
import '../../data/repos/expenses_repo.dart';
import '../../data/repos/groups_repo.dart';

enum SplitPreset { all, meOnly, some }

class CreateExpenseScreen extends StatefulWidget {
  final String groupId;
  const CreateExpenseScreen({super.key, required this.groupId});

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final expensesRepo = ExpensesRepo();
  final groupsRepo = GroupsRepo();

  final _desc = TextEditingController();
  final _total = TextEditingController(text: '0');
  DateTime _date = DateTime.now();
  String _currency = 'UYU';

  bool _equalSplit = true;
  bool _loading = false;
  String? _error;

  List<_Member> _members = [];
  String? _paidBy;

  // ✅ NUEVO: preset amigable
  SplitPreset _preset = SplitPreset.all;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _desc.dispose();
    _total.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final rows = await groupsRepo.listMembers(widget.groupId);
    final mems = rows.map((r) {
      final uid = r['user_id'] as String;
      final name = ((r['profiles'] as Map?)?['display_name'] ?? 'User').toString();
      return _Member(userId: uid, name: name);
    }).toList();

    setState(() {
      _members = mems;
      _paidBy ??= AppSupabase.uid ?? (mems.isNotEmpty ? mems.first.userId : null);

      for (final m in _members) {
        m.included = true; // por defecto todos incluidos
        m.customShare = 0;
      }
    });

    _applyPreset(_preset, recalc: true);
  }

  num _parseTotal() {
    final t = _total.text.trim().replaceAll(',', '.');
    return num.tryParse(t) ?? 0;
  }

  _Member? _me() {
    final uid = AppSupabase.uid;
    if (uid == null) return null;
    try {
      return _members.firstWhere((m) => m.userId == uid);
    } catch (_) {
      return null;
    }
  }

  List<_Member> _includedMembers() => _members.where((m) => m.included).toList();

  void _recalcEqual() {
    if (!_equalSplit) return;
    final total = _parseTotal();
    final included = _includedMembers();
    if (included.isEmpty) return;

    // reparto simple (si querés, luego le metemos redondeo fino)
    final per = total / included.length;
    for (final m in _members) {
      m.customShare = m.included ? per : 0;
    }
    setState(() {});
  }

  num _sumShares() {
    return _members.fold<num>(0, (a, m) => a + (m.included ? m.customShare : 0));
  }

  void _selectAll() {
    setState(() {
      for (final m in _members) {
        m.included = true;
      }
      _preset = SplitPreset.all;
    });
    if (_equalSplit) _recalcEqual();
  }

  void _selectNone() {
    setState(() {
      for (final m in _members) {
        m.included = false;
        m.customShare = 0;
      }
      _preset = SplitPreset.some;
    });
    if (_equalSplit) setState(() {});
  }

  void _selectMeOnly() {
    final me = _me();
    if (me == null) return;

    setState(() {
      for (final m in _members) {
        m.included = false;
        m.customShare = 0;
      }
      me.included = true;
      _preset = SplitPreset.meOnly;
      _equalSplit = true; // para que el share sea automático y simple
    });

    // si solo soy yo: mi share = total
    final total = _parseTotal();
    setState(() {
      me.customShare = total;
    });
  }

  void _applyPreset(SplitPreset p, {bool recalc = false}) {
    setState(() => _preset = p);

    switch (p) {
      case SplitPreset.all:
        _selectAll();
        break;
      case SplitPreset.meOnly:
        _selectMeOnly();
        break;
      case SplitPreset.some:
        // no tocamos selección (deja al usuario elegir)
        // pero si estaba "all" y pasa a "some" no cambiamos nada
        break;
    }

    if (recalc && _equalSplit) _recalcEqual();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final desc = _desc.text.trim();
    final total = _parseTotal();
    final paidBy = _paidBy;

    if (desc.isEmpty) {
      setState(() => _error = 'Poné una descripción');
      return;
    }
    if (paidBy == null) {
      setState(() => _error = 'Seleccioná quién pagó');
      return;
    }
    if (total <= 0) {
      setState(() => _error = 'Total debe ser > 0');
      return;
    }

    final included = _includedMembers();
    if (included.isEmpty) {
      setState(() => _error = 'Incluí al menos 1 participante');
      return;
    }

    // Si es "solo yo", aseguramos share exacto = total
    if (_preset == SplitPreset.meOnly) {
      final me = _me();
      if (me != null) {
        for (final m in _members) {
          m.customShare = (m.userId == me.userId && m.included) ? total : 0;
        }
      }
    }

    final sum = _sumShares();
    final diff = (sum - total).abs();
    if (diff > 0.01) {
      setState(() => _error = 'La suma (${Fmt.money(sum)}) no coincide con el total (${Fmt.money(total)})');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final shares = <String, num>{};
      for (final m in included) {
        shares[m.userId] = m.customShare;
      }

      await expensesRepo.createExpense(
        groupId: widget.groupId,
        description: desc,
        paidBy: paidBy,
        currency: _currency,
        total: total,
        expenseDate: _date,
        sharesByUser: shares,
      );

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _parseTotal();
    final sumShares = _sumShares();
    final included = _includedMembers();
    final paidByName = _members
        .where((m) => m.userId == _paidBy)
        .map((m) => m.name)
        .cast<String?>()
        .firstWhere((x) => x != null, orElse: () => null);

    final me = _me();
    final iAmIncluded = me?.included == true;

    num perHead = 0;
    if (_equalSplit && included.isNotEmpty) {
      perHead = total / included.length;
    }

    String presetLabel(SplitPreset p) {
      switch (p) {
        case SplitPreset.all:
          return 'Entre todos';
        case SplitPreset.meOnly:
          return 'Solo yo';
        case SplitPreset.some:
          return 'Solo algunos';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo gasto')),
      body: _members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _total,
                  decoration: const InputDecoration(labelText: 'Total'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    if (_preset == SplitPreset.meOnly) {
                      // si es "solo yo", mi share = total
                      final me = _me();
                      if (me != null) {
                        setState(() {
                          for (final m in _members) {
                            m.customShare = 0;
                          }
                          me.customShare = _parseTotal();
                        });
                      }
                      return;
                    }
                    _equalSplit ? _recalcEqual() : setState(() {});
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _currency,
                        items: const [
                          DropdownMenuItem(value: 'UYU', child: Text('UYU')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                        ],
                        onChanged: (v) => setState(() => _currency = v ?? 'UYU'),
                        decoration: const InputDecoration(labelText: 'Moneda'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _paidBy,
                  decoration: const InputDecoration(labelText: 'Pagó'),
                  items: _members.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.name))).toList(),
                  onChanged: (v) => setState(() => _paidBy = v),
                ),

                const SizedBox(height: 16),

                // ✅ NUEVO: presets amigables
                Text('¿A quiénes afecta?', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SplitPreset.values.map((p) {
                    return ChoiceChip(
                      label: Text(presetLabel(p)),
                      selected: _preset == p,
                      onSelected: (_) => _applyPreset(p, recalc: true),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Split igual/custom (si es "solo yo", lo dejamos igual y bloqueamos el concepto)
                SwitchListTile(
                  title: const Text('Split igual'),
                  subtitle: Text(
                    _preset == SplitPreset.meOnly
                        ? 'Este gasto queda solo para vos'
                        : (_equalSplit ? 'Divide el total entre participantes' : 'Editá montos por persona'),
                  ),
                  value: _equalSplit,
                  onChanged: (_preset == SplitPreset.meOnly)
                      ? null
                      : (v) {
                          setState(() => _equalSplit = v);
                          if (v) _recalcEqual();
                        },
                ),

                const SizedBox(height: 8),
                Text('Participantes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                ..._members.map(
                  (m) => Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: m.included,
                        onChanged: (v) {
                          setState(() => m.included = v ?? false);

                          // si cambiás manualmente, pasamos a "solo algunos"
                          if (_preset != SplitPreset.some) {
                            setState(() => _preset = SplitPreset.some);
                          }

                          if (_equalSplit) _recalcEqual();
                        },
                      ),
                      title: Text(m.name),
                      subtitle: !_equalSplit
                          ? TextField(
                              decoration: const InputDecoration(labelText: 'Monto', isDense: true),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: m.included,
                              onChanged: (val) {
                                final parsed = num.tryParse(val.replaceAll(',', '.')) ?? 0;
                                setState(() => m.customShare = parsed);
                              },
                            )
                          : Text(m.included ? 'Share: ${Fmt.money(m.customShare)}' : 'No participa'),
                      trailing: !_equalSplit && m.included ? Text(Fmt.money(m.customShare)) : null,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ NUEVO: resumen más humano
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumen', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 6),
                        Text('Total: ${Fmt.money(total)}'),
                        Text('Pagó: ${paidByName ?? '—'}'),
                        Text('Participan: ${included.length}'),
                        if (_equalSplit && included.isNotEmpty)
                          Text('A cada uno le toca: ${Fmt.money(perHead)}'),
                        const SizedBox(height: 8),
                        Text('Suma shares: ${Fmt.money(sumShares)}'),
                        const SizedBox(height: 6),
                        Text(
                          iAmIncluded ? '✅ Este gasto te afecta' : 'ℹ️ Este gasto no te afecta',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Member {
  final String userId;
  final String name;
  bool included = true;
  num customShare = 0;

  _Member({required this.userId, required this.name});
}
