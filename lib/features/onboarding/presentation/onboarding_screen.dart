import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/models/gym_membership_model.dart';
import 'package:proof/shared/models/user_role.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  UserRole? _selectedRole;
  String? _selectedGymId;
  bool _isLoading = false;

  Future<void> _complete({bool skipGym = false}) async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your account role')),
      );
      return;
    }

    final wantsGym = _selectedRole!.isAthlete && !skipGym;
    if (wantsGym && _selectedGymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a gym, or tap “Continue without gym” to join one later.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final firestore = ref.read(firestoreServiceProvider);

      await firestore.updateUserProfile(
        userId: user.uid,
        role: _selectedRole,
        primaryGymId: _selectedGymId,
        onboardingCompleted: true,
      );

      if (wantsGym && _selectedGymId != null) {
        await firestore.requestGymMembership(
          gymId: _selectedGymId!,
          userId: user.uid,
          type: GymMembershipType.athlete,
        );
      }

      if (_selectedRole!.isCoach || _selectedRole == UserRole.athleteAndCoach) {
        await firestore.ensureCoachProfile(user.uid);
      }

      if (!mounted) return;
      context.go('/dashboard');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final gymsAsync = ref.watch(activeGymsProvider);
    final showGymSection = _selectedRole?.isAthlete == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _signOut,
            child: Text(
              'Sign out',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set up your account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role. Gym membership is optional — you can join a gym later from More → Gyms.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: 32),
              Text('Account role', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              ...UserRole.values.map(
                (role) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RoleCard(
                    role: role,
                    selected: _selectedRole == role,
                    onTap: () => setState(() {
                      _selectedRole = role;
                      if (!role.isAthlete) _selectedGymId = null;
                    }),
                  ),
                ),
              ),
              if (showGymSection) ...[
                const SizedBox(height: 24),
                Text(
                  'Your gym (optional)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Coach verification requires an approved gym membership. You can skip this and join later.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 12),
                gymsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Could not load gyms: $e'),
                  data: (gyms) {
                    if (gyms.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'No gyms registered yet. Continue without a gym — you can request membership later from More → Gyms.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    return Column(
                      children: gyms
                          .map(
                            (gym) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedGymId = gym.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedGymId == gym.id
                                            ? AppColors.accent
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                gym.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              if (gym.country.isNotEmpty)
                                                Text(
                                                  gym.country,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            AppColors.inkMuted,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (_selectedGymId == gym.id)
                                          const Icon(
                                            Icons.check_circle,
                                            color: AppColors.accent,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
              ProofButton(
                label: 'Continue',
                isLoading: _isLoading,
                onPressed: () => _complete(),
              ),
              if (showGymSection) ...[
                const SizedBox(height: 12),
                ProofButton(
                  label: 'Continue without gym',
                  isOutlined: true,
                  isLoading: _isLoading,
                  onPressed: () => _complete(skipGym: true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  role.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
