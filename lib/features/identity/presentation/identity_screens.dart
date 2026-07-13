import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proof/core/constants/app_constants.dart';
import 'package:proof/core/constants/app_features.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/validators.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class CreateIdentityScreen extends ConsumerStatefulWidget {
  const CreateIdentityScreen({super.key});

  @override
  ConsumerState<CreateIdentityScreen> createState() =>
      _CreateIdentityScreenState();
}

class _CreateIdentityScreenState extends ConsumerState<CreateIdentityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _handleController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final firestore = ref.read(firestoreServiceProvider);
      final handle = _handleController.text.trim().toLowerCase();

      await firestore.ensureUserDocument(
        userId: user.uid,
        email: user.email ?? '',
      );

      final available = await firestore.isHandleAvailable(handle);
      if (!available) {
        setState(() => _error = 'This handle is already taken');
        return;
      }

      final now = DateTime.now();
      await firestore.createIdentity(PhysicalIdentity(
        userId: user.uid,
        displayName: _displayNameController.text.trim(),
        handle: handle,
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        createdAt: now,
        updatedAt: now,
      ));

      if (mounted) context.go('/onboarding');
    } on FirebaseException catch (e) {
      setState(() => _error = _mapFirestoreError(e));
    } catch (e) {
      setState(() => _error = 'Failed to create identity. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firestore permission denied. Deploy security rules in Firebase Console (see README).';
      case 'unavailable':
        return 'Could not reach Firestore. Check your internet connection.';
      default:
        return e.message ?? 'Failed to create identity (${e.code}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Create your\nPhysical Identity',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'This is your physical passport — who you are in the real world.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(height: 16),
                ],
                ProofTextField(
                  controller: _displayNameController,
                  label: 'Display name',
                  validator: Validators.displayName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                ProofTextField(
                  controller: _handleController,
                  label: 'Handle',
                  prefixText: '@',
                  hint: 'your_handle',
                  validator: Validators.handle,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                ProofTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'City, Country',
                  validator: (v) => Validators.required(v, field: 'Location'),
                ),
                const SizedBox(height: 16),
                ProofTextField(
                  controller: _bioController,
                  label: 'Bio',
                  hint: 'A brief statement about who you are',
                  maxLines: 3,
                  maxLength: AppConstants.bioMaxLength,
                ),
                const SizedBox(height: 32),
                ProofButton(
                  label: 'Create identity',
                  isLoading: _isLoading,
                  onPressed: _create,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(physicalIdentityProvider);
    final skillsAsync = ref.watch(skillsProvider);
    final proofsAsync = ref.watch(proofsProvider);

    return identityAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (identity) {
        if (identity == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final skills = skillsAsync.valueOrNull ?? [];
        final proofs = proofsAsync.valueOrNull ?? [];

        return Scaffold(
          appBar: ProofAppBar(
            title: AppConstants.appName,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(identity: identity),
                const SizedBox(height: 32),
                _StatsRow(skills: skills.length, proofs: proofs.length),
                const SizedBox(height: 32),
                SectionHeader(
                  title: 'NAVIGATION',
                  action: TextButton(
                    onPressed: () => context.push('/edit-profile'),
                    child: const Text('Edit'),
                  ),
                ),
                _NavTile(
                  icon: Icons.psychology_outlined,
                  title: 'Skills',
                  subtitle: '${skills.length} registered',
                  onTap: () => context.push('/skills'),
                ),
                _NavTile(
                  icon: Icons.verified_outlined,
                  title: 'Proofs',
                  subtitle: '${proofs.length} documented',
                  onTap: () => context.push('/proofs'),
                ),
                _NavTile(
                  icon: Icons.layers_outlined,
                  title: 'Proof Stack',
                  subtitle: 'View by skill',
                  onTap: () => context.push('/proof-stack'),
                ),
                _NavTile(
                  icon: Icons.timeline_outlined,
                  title: 'Timeline',
                  subtitle: 'Identity history',
                  onTap: () => context.push('/timeline'),
                ),
                _NavTile(
                  icon: Icons.badge_outlined,
                  title: 'Public Passport',
                  subtitle: '@${identity.handle}',
                  onTap: () => context.push('/passport/${identity.handle}'),
                ),
                const SizedBox(height: 40),
                const Divider(color: AppColors.border),
                const SizedBox(height: 32),
                const ProofMotto(),
                const SizedBox(height: 28),
                FooterLink(
                  title: 'Settings',
                  onTap: () => context.push('/settings'),
                ),
                FooterLink(
                  title: 'FAQ',
                  onTap: () => context.push('/faq'),
                ),
                FooterLink(
                  title: 'About',
                  onTap: () => context.push('/about'),
                ),
                const SizedBox(height: 16),
                Text(
                  '${AppConstants.appName} · Physical Identity',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.identity});

  final PhysicalIdentity identity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IdentityAvatar(
          avatarUrl: identity.avatarUrl,
          displayName: identity.displayName,
          radius: 48,
        ),
        const SizedBox(height: 16),
        Text(
          identity.displayName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '@${identity.handle}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.accent,
              ),
        ),
        if (identity.location.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.inkMuted),
              const SizedBox(width: 4),
              Text(identity.location, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
        if (identity.bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            identity.bio,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.skills, required this.proofs});

  final int skills;
  final int proofs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Skills', value: '$skills')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Proofs', value: '$proofs')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _handleController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  bool _isLoading = false;
  String? _error;
  File? _avatarFile;
  PhysicalIdentity? _original;
  String? _initializedForUserId;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _handleController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initFromIdentity(PhysicalIdentity identity) {
    if (_initializedForUserId == identity.userId) return;
    _initializedForUserId = identity.userId;
    _original = identity;
    _displayNameController.text = identity.displayName;
    _handleController.text = identity.handle;
    _bioController.text = identity.bio;
    _locationController.text = identity.location;
  }

  Future<void> _pickAvatar() async {
    if (!AppFeatures.cloudStorageEnabled) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _original == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firestore = ref.read(firestoreServiceProvider);
      final handle = _handleController.text.trim().toLowerCase();

      if (handle != _original!.handle) {
        final available = await firestore.isHandleAvailable(handle);
        if (!available) {
          setState(() => _error = 'This handle is already taken');
          return;
        }
      }

      final updated = _original!.copyWith(
        displayName: _displayNameController.text.trim(),
        handle: handle,
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await firestore.updateIdentity(updated);
      if (mounted) context.pop();
    } catch (_) {
      setState(() => _error = 'Failed to update profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          return const Scaffold(body: Center(child: Text('No identity found')));
        }
        _initFromIdentity(identity);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ProofAppBar(
            title: 'Edit profile',
            leading: BackButton(onPressed: () => context.pop()),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: AppFeatures.cloudStorageEnabled ? _pickAvatar : null,
                      child: Stack(
                        children: [
                          if (_avatarFile != null)
                            CircleAvatar(
                              radius: 48,
                              backgroundImage: FileImage(_avatarFile!),
                            )
                          else
                            IdentityAvatar(
                              avatarUrl: identity.avatarUrl,
                              displayName: identity.displayName,
                              radius: 48,
                            ),
                          if (AppFeatures.cloudStorageEnabled)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'These details appear on your passport and in people search '
                    'when your profile is public.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 16),
                  ],
                  ProofTextField(
                    controller: _displayNameController,
                    label: 'Display name',
                    validator: Validators.displayName,
                  ),
                  const SizedBox(height: 16),
                  ProofTextField(
                    controller: _handleController,
                    label: 'Handle',
                    prefixText: '@',
                    validator: Validators.handle,
                  ),
                  const SizedBox(height: 16),
                  ProofTextField(
                    controller: _locationController,
                    label: 'Location',
                    validator: (v) => Validators.required(v, field: 'Location'),
                  ),
                  const SizedBox(height: 16),
                  ProofTextField(
                    controller: _bioController,
                    label: 'Bio',
                    maxLines: 3,
                    maxLength: AppConstants.bioMaxLength,
                  ),
                  const SizedBox(height: 32),
                  ProofButton(
                    label: 'Save changes',
                    isLoading: _isLoading,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 16),
                  ProofButton(
                    label: 'Privacy settings',
                    isOutlined: true,
                    onPressed: () => context.push('/privacy-settings'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
