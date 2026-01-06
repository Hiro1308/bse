import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/format.dart';
import '../../data/repos/auth_repo.dart';
import '../../data/repos/groups_repo.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final groupsRepo = GroupsRepo();
  final authRepo = AuthRepo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis grupos'),
        actions: [
          IconButton(
            tooltip: 'Personalizar tu avatar',
            icon: const Icon(Icons.face_retouching_natural),
            onPressed: () => context.push('/avatar'),
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () => context.push('/friends'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authRepo.signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/groups/create'),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: groupsRepo.listMyGroups(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('Todavía no tenés grupos'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final g = (items[i]['groups'] as Map<String, dynamic>);
              final id = g['id'] as String;
              final name = (g['name'] ?? 'Grupo') as String;

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('ID: ${Fmt.shortId(id)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/groups/$id'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
