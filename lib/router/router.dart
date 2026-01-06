import 'dart:async';
import 'package:bse/avatar/avatar_profile_screen.dart';
import 'package:bse/features/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/register_screen.dart';
import '../features/groups/groups_screen.dart';
import '../features/groups/create_group_screen.dart';
import '../features/groups/group_detail_screen.dart';
import '../features/expenses/create_expense_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/groups/add_members_screen.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = Supabase.instance.client.auth;
  final stream = ref.watch(authStateProvider.stream);

  return GoRouter(
    initialLocation: '/groups',
    refreshListenable: GoRouterRefreshStream(stream),
    redirect: (context, state) {
      final session = auth.currentSession;
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (session == null && !loggingIn) return '/login';
      if (session != null && loggingIn) return '/groups';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/groups', builder: (_, __) => const GroupsScreen()),
      GoRoute(path: '/groups/create', builder: (_, __) => const CreateGroupScreen()),
      GoRoute(path: '/friends', builder: (_, __) => const FriendsScreen()),
      GoRoute(
        path: '/groups/:id/members/add',
        builder: (_, s) => AddMembersScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (_, s) => GroupDetailScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/:id/expense/create',
        builder: (_, s) => CreateExpenseScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/avatar',
        builder: (context, state) => const AvatarProfileScreen(), // o AvatarEditorScreen
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
