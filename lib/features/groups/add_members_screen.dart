import 'package:flutter/material.dart';
import '../../data/repos/friends_repo.dart';
import '../../data/repos/group_members_repo.dart';

class AddMembersScreen extends StatefulWidget {
  final String groupId;
  const AddMembersScreen({super.key, required this.groupId});

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final friendsRepo = FriendsRepo();
  final membersRepo = GroupMembersRepo();

  late Future<List<Map<String, dynamic>>> friendsF;
  String? msg;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    friendsF = friendsRepo.listAcceptedFriends();
  }

  Future<void> _add(String userId) async {
    setState(() { loading = true; msg = null; });
    try {
      final res = await membersRepo.addMember(widget.groupId, userId);
      setState(() => msg = (res['ok'] == true) ? 'Agregado ✅' : 'Error: ${res['error']}');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar miembros')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (msg != null) Text(msg!),
          const SizedBox(height: 8),
          FutureBuilder(
            future: friendsF,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final friends = snap.data!;
              if (friends.isEmpty) return const Text('No tenés amigos aceptados todavía.');
              return Column(
                children: friends.map((f) {
                  final uid = f['friend_id'] as String;
                  final name = (f['display_name'] ?? 'Amigo').toString();
                  final email = (f['email'] ?? '').toString();
                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: email.isEmpty ? null : Text(email),
                      trailing: FilledButton(
                        onPressed: loading ? null : () => _add(uid),
                        child: const Text('Agregar'),
                      ),
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
