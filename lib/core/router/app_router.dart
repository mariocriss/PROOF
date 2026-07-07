import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/features/auth/presentation/auth_screens.dart';
import 'package:proof/features/identity/presentation/identity_screens.dart';
import 'package:proof/features/proofs/presentation/proofs_screens.dart';
import 'package:proof/features/skills/presentation/skills_screens.dart';
import 'package:proof/features/timeline/presentation/timeline_screens.dart';
import 'package:proof/shared/providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.valueOrNull;
      final isAuth = user != null;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' || location == '/register';
      final isCreateIdentity = location == '/create-identity';
      final isPublicPassport = location.startsWith('/passport/');

      if (!isAuth && !isAuthRoute && !isPublicPassport) {
        return '/login';
      }

      if (isAuth && isAuthRoute) {
        return '/profile';
      }

      if (isAuth && !isPublicPassport) {
        if (userState.isLoading) return null;

        final userModel = userState.valueOrNull;
        final hasIdentity = userModel?.hasIdentity ?? false;

        if (!hasIdentity && !isCreateIdentity) {
          return '/create-identity';
        }

        if (hasIdentity && isCreateIdentity) {
          return '/profile';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/create-identity',
        builder: (context, state) => const CreateIdentityScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/skills',
        builder: (context, state) => const SkillsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddSkillScreen(),
          ),
          GoRoute(
            path: ':skillId',
            builder: (context, state) {
              final skillId = state.pathParameters['skillId']!;
              return SkillDetailScreen(skillId: skillId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/proofs',
        builder: (context, state) => const ProofsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddProofScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/proof-stack',
        builder: (context, state) => const ProofStackScreen(),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        path: '/passport/:handle',
        builder: (context, state) {
          final handle = state.pathParameters['handle']!;
          return PassportScreen(handle: handle);
        },
      ),
    ],
  );
});
