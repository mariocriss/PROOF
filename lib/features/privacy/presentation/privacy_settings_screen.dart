import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/constants/legal_constants.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/legal_link.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  PhysicalIdentity? _identity;
  bool _isPublic = true;
  bool _isSaving = false;

  void _init(PhysicalIdentity identity) {
    if (_identity != null) return;
    _identity = identity;
    _isPublic = identity.isPublic;
  }

  Future<void> _save() async {
    final identity = _identity;
    if (identity == null) return;

    setState(() => _isSaving = true);
    try {
      final updated = identity.copyWith(
        isPublic: _isPublic,
        updatedAt: DateTime.now(),
      );
      await ref.read(firestoreServiceProvider).updateIdentity(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(physicalIdentityProvider);

    return identityAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (identity) {
        if (identity == null) {
          return Scaffold(
            appBar: ProofAppBar(
              title: 'Privacy',
              leading: BackButton(onPressed: () => context.pop()),
            ),
            body: const Center(child: Text('Create your identity first.')),
          );
        }

        _init(identity);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ProofAppBar(
            title: 'Privacy',
            leading: BackButton(onPressed: () => context.pop()),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Public profile'),
                subtitle: const Text(
                  'When off, your passport link is hidden and you are removed from people search.',
                ),
                value: _isPublic,
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _isPublic = value),
              ),
              const SizedBox(height: 8),
              Text(
                'Friends can still see profile details based on your connection. '
                'Blocking and reporting are available from user profiles.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 24),
              ProofButton(
                label: 'Save privacy settings',
                isLoading: _isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: 32),
              Text(
                'LEGAL',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.2,
                      color: AppColors.inkSecondary,
                    ),
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
            ],
          ),
        );
      },
    );
  }
}
