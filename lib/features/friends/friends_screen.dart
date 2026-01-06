import 'package:flutter/material.dart';
import '../../data/repos/friends_repo.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final repo = FriendsRepo();
  final emailCtrl = TextEditingController();
  bool loading = false;
  String? msg;

  late Future<List<Map<String, dynamic>>> incomingF;
  late Future<List<Map<String, dynamic>>> acceptedF;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    incomingF = repo.listIncomingPending();
    acceptedF = repo.listAcceptedFriends();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() { loading = true; msg = null; });
    try {
      final res = await repo.sendRequestByEmail(email);
      setState(() => msg = (res['ok'] == true) ? 'Solicitud enviada' : 'Error: ${res['error']}');
      setState(_refresh);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _accept(String id) async {
    setState(() { loading = true; msg = null; });
    try {
      final res = await repo.acceptRequest(id);
      setState(() => msg = (res['ok'] == true) ? 'Amigo agregado' : 'Error: ${res['error']}');
      setState(_refresh);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amigos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Agregar por email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading ? null : _send,
              child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enviar solicitud'),
            ),
          ),
          if (msg != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(msg!)),
          const SizedBox(height: 18),

          Text('Solicitudes pendientes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder(
            future: incomingF,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final items = snap.data!;
              if (items.isEmpty) return const Text('No tenés solicitudes');
              return Column(
                children: items.map((r) {
                  final id = r['id'] as String;
                  final prof = (r['profiles'] as Map?) ?? {};
                  final name = (prof['display_name'] ?? r['requester']).toString();
                  final email = (prof['email'] ?? '').toString();
                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: email.isEmpty ? null : Text(email),
                      trailing: FilledButton(
                        onPressed: loading ? null : () => _accept(id),
                        child: const Text('Aceptar'),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 18),
          Text('Mis amigos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder(
            future: acceptedF,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final items = snap.data!;
              if (items.isEmpty) return const Text('Todavía no tenés amigos aceptados');
              return Column(
                children: items.map((f) {
                  return Card(
                    child: ListTile(
                      title: Text((f['display_name'] ?? 'Amigo').toString()),
                      subtitle: Text((f['email'] ?? '').toString()),
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
