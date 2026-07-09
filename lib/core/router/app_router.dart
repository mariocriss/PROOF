import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/features/auth/presentation/auth_screens.dart';
import 'package:proof/features/dashboard/presentation/dashboard_screen.dart';
import 'package:proof/features/identity/presentation/identity_screens.dart';
import 'package:proof/features/account/presentation/account_screens.dart';
import 'package:proof/features/coach_tools/presentation/coach_tools_screens.dart';
import 'package:proof/features/coaches/presentation/coach_profile_screen.dart';
import 'package:proof/features/coaches/presentation/coaches_screen.dart';
import 'package:proof/features/friends/presentation/friends_screen.dart';
import 'package:proof/features/gyms/presentation/gyms_screen.dart';
import 'package:proof/features/people/presentation/request_screens.dart';
import 'package:proof/features/more/presentation/more_screen.dart';
import 'package:proof/features/passport/presentation/my_passport_tab.dart';
import 'package:proof/features/passport/presentation/passport_screen.dart';
import 'package:proof/features/proof_stack/presentation/proof_stack_screen.dart';
import 'package:proof/features/proof_stack/presentation/skill_proof_stack_screen.dart';
import 'package:proof/features/proofs/presentation/proofs_screens.dart';
import 'package:proof/features/settings/presentation/settings_screens.dart';
import 'package:proof/features/shell/presentation/app_shell.dart';
import 'package:proof/features/skills/presentation/skills_screens.dart';
import 'package:proof/features/timeline/presentation/timeline_screens.dart';
import 'package:proof/features/verification/presentation/verification_requests_screen.dart';
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
      final isPublicPassport =
          location.startsWith('/passport/') && location != '/passport';

      if (location == '/profile') {
        return '/dashboard';
      }

      if (!isAuth && !isAuthRoute && !isPublicPassport) {
        return '/login';
      }

      if (isAuth && isAuthRoute) {
        return '/dashboard';
      }

      if (isAuth && !isPublicPassport) {
        if (userState.isLoading) return null;

        final userModel = userState.valueOrNull;
        final hasIdentity = userModel?.hasIdentity ?? false;

        if (!hasIdentity && !isCreateIdentity) {
          return '/create-identity';
        }

        if (hasIdentity && isCreateIdentity) {
          return '/dashboard';
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
        redirect: (_, __) => '/dashboard',
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/skills',
                builder: (context, state) =>
                    const SkillsScreen(showBackButton: false),
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
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timeline',
                builder: (context, state) =>
                    const TimelineScreen(showBackButton: false),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/passport',
                builder: (context, state) => const MyPassportTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/proofs',
        builder: (context, state) => const ProofsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) {
              final query = state.uri.queryParameters;
              return AddProofScreen(
                skillId: query['skillId'],
                initialResult: query['result'],
                initialUnit: query['unit'],
                isFirstProof: query['first'] == 'true',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/proof-stack',
        builder: (context, state) => const ProofStackScreen(),
        routes: [
          GoRoute(
            path: ':skillId',
            builder: (context, state) {
              final skillId = state.pathParameters['skillId']!;
              return SkillProofStackScreen(skillId: skillId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/coaches',
        builder: (context, state) => const CoachesScreen(),
        routes: [
          GoRoute(
            path: ':handle',
            builder: (context, state) {
              final handle = state.pathParameters['handle']!;
              return CoachProfileScreen(handle: handle);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/gyms',
        builder: (context, state) => const GymsScreen(),
      ),
      GoRoute(
        path: '/verification-requests',
        builder: (context, state) => const VerificationRequestsScreen(),
      ),
      GoRoute(
        path: '/friend-requests',
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      GoRoute(
        path: '/coach-requests',
        builder: (context, state) => const CoachRequestsScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/coach/verification-queue',
        builder: (context, state) => const CoachVerificationQueueScreen(),
      ),
      GoRoute(
        path: '/coach/athletes',
        builder: (context, state) => const CoachAthletesScreen(),
      ),
      GoRoute(
        path: '/coach/verified-proofs',
        builder: (context, state) => const CoachVerifiedProofsScreen(),
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
