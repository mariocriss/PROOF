import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/router/router_keys.dart';
import 'package:proof/core/utils/onboarding_paths.dart';
import 'package:proof/features/auth/presentation/auth_screens.dart';
import 'package:proof/features/dashboard/presentation/dashboard_screen.dart';
import 'package:proof/features/account/presentation/account_screens.dart';
import 'package:proof/features/identity/presentation/identity_screens.dart';
import 'package:proof/features/coach_tools/presentation/coach_tools_screens.dart';
import 'package:proof/features/coaches/presentation/coach_profile_screen.dart';
import 'package:proof/features/coaches/presentation/coaches_screen.dart';
import 'package:proof/features/friends/presentation/friends_screen.dart';
import 'package:proof/features/gyms/presentation/gym_manager_screens.dart';
import 'package:proof/features/gyms/presentation/gyms_screen.dart';
import 'package:proof/features/onboarding/presentation/onboarding_screens.dart';
import 'package:proof/features/people/presentation/person_profile_screen.dart';
import 'package:proof/features/people/presentation/request_screens.dart';
import 'package:proof/features/more/presentation/more_screen.dart';
import 'package:proof/features/passport/presentation/my_passport_tab.dart';
import 'package:proof/features/passport/presentation/passport_screen.dart';
import 'package:proof/features/proof_stack/presentation/proof_stack_screen.dart';
import 'package:proof/features/proof_stack/presentation/skill_proof_stack_screen.dart';
import 'package:proof/features/proofs/presentation/proofs_screens.dart';
import 'package:proof/features/settings/presentation/settings_screens.dart';
import 'package:proof/features/shell/presentation/deferred_shell_tab.dart';
import 'package:proof/features/shell/presentation/app_shell.dart';
import 'package:proof/features/skills/presentation/skills_screens.dart';
import 'package:proof/features/timeline/presentation/timeline_screens.dart';
import 'package:proof/features/legal/presentation/legal_screens.dart';
import 'package:proof/features/privacy/presentation/privacy_settings_screen.dart';
import 'package:proof/features/verification/presentation/verification_requests_screen.dart';
import 'package:proof/shared/models/onboarding_step.dart';
import 'package:proof/shared/providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.valueOrNull;
      final isAuth = user != null;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' || location == '/register';
      final isLegalRoute =
          location == '/privacy-policy' || location == '/terms';
      final isPublicPassport =
          location.startsWith('/passport/') && location != '/passport';
      final isOnboardingRoute = OnboardingPaths.isOnboardingRoute(location);
      final isLegacyOnboarding =
          location == '/create-identity' || location == '/onboarding';

      if (location == '/profile') {
        return '/dashboard';
      }

      if (location == '/profile/edit') {
        return '/edit-profile';
      }

      if (!isAuth && !isAuthRoute && !isPublicPassport && !isLegalRoute) {
        return '/login';
      }

      final isGymManagerRoute = location.startsWith('/gym-manager');

      if (isAuth && !isPublicPassport) {
        final userState = ref.read(currentUserProvider);
        if (userState.isLoading) return null;

        final userModel = userState.valueOrNull;
        // Profile still loading after auth (e.g. right after sign-in).
        if (userModel == null) return null;

        final onboardingComplete = userModel.onboardingCompleted;
        final managedGymId = userModel.managedGymIds.firstOrNull;

        if (!onboardingComplete) {
          if (isGymManagerRoute && managedGymId != null) return null;

          final target = OnboardingPaths.routeForUser(
            step: userModel.onboardingStep,
            onboardingCompleted: false,
            role: userModel.accountType,
            managedGymId: managedGymId,
          );

          if (isAuthRoute || isLegacyOnboarding) return target;
          if (isOnboardingRoute) return null;
          return target;
        }

        if (onboardingComplete) {
          if (isAuthRoute || isOnboardingRoute || isLegacyOnboarding) {
            return OnboardingPaths.routeForUser(
              step: OnboardingStep.completed,
              onboardingCompleted: true,
              role: userModel.accountType,
              managedGymId: managedGymId,
            );
          }
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
        redirect: (_, __) => OnboardingPaths.athleteIdentity,
      ),
      GoRoute(
        path: '/onboarding',
        redirect: (_, __) => OnboardingPaths.accountType,
      ),
      GoRoute(
        path: '/onboarding/account-type',
        builder: (context, state) => const ChooseAccountTypeScreen(),
      ),
      GoRoute(
        path: '/onboarding/athlete-identity',
        builder: (context, state) => const AthleteIdentityOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/coach-profile',
        builder: (context, state) => const CoachProfileOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/gym-profile',
        builder: (context, state) => const GymProfileOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/select-gym',
        builder: (context, state) => const SelectGymOnboardingScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) =>
            state.uri.path == '/profile' ? '/dashboard' : null,
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
                builder: (context, state) => DeferredShellTab(
                  tabIndex: 0,
                  builder: (_, __) => const DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/skills',
                builder: (context, state) => DeferredShellTab(
                  tabIndex: 1,
                  builder: (_, __) =>
                      const SkillsScreen(showBackButton: false),
                ),
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
                builder: (context, state) => DeferredShellTab(
                  tabIndex: 2,
                  builder: (_, __) =>
                      const TimelineScreen(showBackButton: false),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/passport',
                builder: (context, state) => DeferredShellTab(
                  tabIndex: 3,
                  builder: (_, __) => const MyPassportTab(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => DeferredShellTab(
                  tabIndex: 4,
                  builder: (_, __) => const MoreScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/proofs',
        parentNavigatorKey: rootNavigatorKey,
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
        parentNavigatorKey: rootNavigatorKey,
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
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/faq',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/friends',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return FriendsScreen(initialTab: tab.clamp(0, 2));
        },
      ),
      GoRoute(
        path: '/people/:handle',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final handle = state.pathParameters['handle']!;
          return PersonProfileScreen(handle: handle);
        },
      ),
      GoRoute(
        path: '/coaches',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CoachesScreen(),
        routes: [
          GoRoute(
            path: ':handle',
            builder: (context, state) {
              final handle = state.pathParameters['handle']!;
              return CoachProfileScreen(
                handle: handle,
                gymId: state.uri.queryParameters['gymId'],
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/gyms',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GymsScreen(),
      ),
      GoRoute(
        path: '/gym-manager',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GymManagerHubScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateGymScreen(),
          ),
          GoRoute(
            path: ':gymId',
            builder: (context, state) {
              final gymId = state.pathParameters['gymId']!;
              return GymManagerDashboardScreen(gymId: gymId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final gymId = state.pathParameters['gymId']!;
                  return GymEditProfileScreen(gymId: gymId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/verification-requests',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const VerificationRequestsScreen(),
      ),
      GoRoute(
        path: '/friend-requests',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      GoRoute(
        path: '/coach-requests',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CoachRequestsScreen(),
      ),
      GoRoute(
        path: '/account',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/coach/verification-queue',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CoachVerificationQueueScreen(),
      ),
      GoRoute(
        path: '/coach/athletes',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CoachAthletesScreen(),
      ),
      GoRoute(
        path: '/coach/verified-proofs',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CoachVerifiedProofsScreen(),
      ),
      GoRoute(
        path: '/privacy-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/passport/:handle',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final handle = state.pathParameters['handle']!;
          return PassportScreen(handle: handle);
        },
      ),
    ],
  );

  ref.listen(authStateProvider, (previous, next) {
    final previousUid = previous?.valueOrNull?.uid;
    final nextUid = next.valueOrNull?.uid;
    if (previousUid != nextUid) {
      router.refresh();
    }
  });
  ref.listen(currentUserProvider, (previous, next) {
    final previousId = previous?.valueOrNull?.id;
    final nextId = next.valueOrNull?.id;
    if (previousId != nextId) {
      router.refresh();
      return;
    }

    final wasComplete = previous?.valueOrNull?.onboardingCompleted;
    final isComplete = next.valueOrNull?.onboardingCompleted;
    if (wasComplete != isComplete) {
      router.refresh();
    }
  });
  ref.onDispose(router.dispose);

  return router;
});
