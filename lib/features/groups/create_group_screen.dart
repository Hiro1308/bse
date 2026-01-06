import 'package:bse/core/supabase.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repos/groups_repo.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final repo = GroupsRepo();
  final _name = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Poné un nombre');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final s = AppSupabase.client.auth.currentSession;
print('session: ${s?.accessToken.substring(0, 20)}');
print('uid: ${AppSupabase.client.auth.currentUser?.id}');

      final id = await repo.createGroup(name: name);
      if (mounted) context.go('/groups/$id');
    } catch (e) {
      print(e);
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear grupo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre del grupo'),
          ),
          const SizedBox(height: 12),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crear'),
            ),
          ),
        ],
      ),
    );
  }
}
