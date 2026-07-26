import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/constants/legal_constants.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/auth/presentation/reauth_dialog.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/legal_link.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen>
    with WidgetsBindingObserver {
  final _specialtyController = TextEditingController();
  bool _isCoach = false;
  bool _loaded = false;
  bool _deleteInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshVerification();
  }

  Future<void> _refreshVerification() async {
    await ref.read(authServiceProvider).reloadCurrentUser();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _resendVerification() async {
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification email sent')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authServiceProvider).mapAuthError(e) ??
                'Could not send verification email',
          ),
        ),
      );
    }
  }

  Future<void> _deleteAccount(String userId) async {
    if (_deleteInFlight) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently removes your sign-in, profile, proofs, friendships, '
          'and gym memberships. Gyms you created will be closed for all members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final password = await showDialog<String>(
      context: context,
      builder: (context) => const ReauthDialog(),
    );
    if (password == null || password.isEmpty || !mounted) return;

    setState(() => _deleteInFlight = true);
    try {
      final result = await ref
          .read(accountDeletionServiceProvider)
          .deleteAccount(userId: userId, password: password);
      if (!mounted) return;

      if (result.isSuccess) {
        context.go('/register');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.userMessage ??
                'Account deletion was not completed. Your account is still active.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deleteInFlight = false);
      } else {
        _deleteInFlight = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final auth = ref.watch(authServiceProvider);
    final emailVerified = auth.isEmailVerified;

    if (user != null && !_loaded) {
      _isCoach = user.isCoach;
      _specialtyController.text = user.specialty;
      _loaded = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Account',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            emailVerified ? 'Email verified' : 'Email not verified',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: emailVerified ? AppColors.accent : AppColors.inkMuted,
            ),
          ),
          if (!emailVerified) ...[
            const SizedBox(height: 12),
            ProofButton(
              label: 'Resend verification email',
              isOutlined: true,
              onPressed: _resendVerification,
            ),
            const SizedBox(height: 8),
            ProofButton(
              label: 'Refresh verification status',
              isOutlined: true,
              onPressed: _refreshVerification,
            ),
          ],
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I am a coach'),
            subtitle: Text(
              user?.role.isGymManager == true
                  ? 'Gym manager accounts keep their gym role. Specialty only applies if you also coach.'
                  : 'Enable coach tools and appear in coach discovery',
            ),
            value: _isCoach,
            onChanged: user?.role.isGymManager == true
                ? null
                : (value) => setState(() => _isCoach = value),
          ),
          if (_isCoach) ...[
            const SizedBox(height: 12),
            ProofTextField(
              controller: _specialtyController,
              label: 'Specialty',
              hint: 'e.g. Strength Coach',
            ),
          ],
          const SizedBox(height: 24),
          ProofButton(
            label: 'Save account',
            onPressed: user == null
                ? null
                : () async {
                    await ref
                        .read(firestoreServiceProvider)
                        .updateCoachPreference(
                          userId: user.id,
                          currentRole: user.role,
                          enableCoach: _isCoach,
                          specialty: _specialtyController.text.trim(),
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account updated')),
                      );
                    }
                  },
          ),
          const SizedBox(height: 16),
          ProofButton(
            label: 'Privacy settings',
            isOutlined: true,
            onPressed: () => context.push('/privacy-settings'),
          ),
          const SizedBox(height: 12),
          LegalLinkButton(
            label: 'Privacy Policy',
            route: LegalConstants.privacyPolicyRoute,
          ),
          const SizedBox(height: 12),
          LegalLinkButton(
            label: 'Terms of Service',
            route: LegalConstants.termsOfServiceRoute,
          ),
          const SizedBox(height: 16),
          ProofButton(
            label: 'Sign out',
            isOutlined: true,
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
          const SizedBox(height: 12),
          ProofButton(
            label: _deleteInFlight ? 'Deleting…' : 'Delete account',
            isOutlined: true,
            onPressed: (user == null || _deleteInFlight)
                ? null
                : () => _deleteAccount(user.id),
          ),
        ],
      ),
    );
  }
}
