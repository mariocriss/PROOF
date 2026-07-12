import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/onboarding_paths.dart';
import 'package:proof/core/utils/validators.dart';
import 'package:proof/features/gyms/domain/gym_search.dart';
import 'package:proof/features/gyms/presentation/widgets/gym_manager_widgets.dart';
import 'package:proof/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:proof/shared/models/coach_profile.dart';
import 'package:proof/shared/models/gym_model.dart';
import 'package:proof/shared/models/onboarding_draft.dart';
import 'package:proof/shared/models/onboarding_step.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/user_role.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

// ── Choose account type ─────────────────────────────────────────────────────

class ChooseAccountTypeScreen extends ConsumerStatefulWidget {
  const ChooseAccountTypeScreen({super.key});

  @override
  ConsumerState<ChooseAccountTypeScreen> createState() =>
      _ChooseAccountTypeScreenState();
}

class _ChooseAccountTypeScreenState
    extends ConsumerState<ChooseAccountTypeScreen> {
  UserRole? _selected;
  bool _isLoading = false;

  Future<void> _continue() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an account type')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final firestore = ref.read(firestoreServiceProvider);
      final userModel = ref.read(currentUserProvider).valueOrNull;
      final selected = _selected!;

      if (userModel?.accountType == selected &&
          userModel?.onboardingStep != OnboardingStep.chooseAccountType) {
        if (!mounted) return;
        context.go(OnboardingPaths.routeForStep(userModel!.onboardingStep));
        return;
      }

      await firestore.setAccountType(
        userId: user.uid,
        accountType: selected,
      );
      if (!mounted) return;
      context.go(OnboardingPaths.routeForStep(
        OnboardingStep.initialStepFor(selected),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSignup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel signup?'),
        content: const Text(
          'Your account will be removed so you can register again with the same email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel signup'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(signupServiceProvider).abandonIncompleteSignup();
      if (!mounted) return;
      context.go('/register');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'requires-recent-login'
                ? 'Sign out, sign in again, then cancel signup.'
                : (e.message ?? 'Could not cancel signup'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel signup: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueLater() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue later?'),
        content: const Text(
          'Your email stays registered. Sign in later to resume onboarding. '
          'To register again with this email, use Cancel signup instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final current = user?.accountType;

    return OnboardingScaffold(
      title: 'Choose account type',
      subtitle:
          'Pick how you will use PROOF. You can change this until onboarding is complete.',
      onBack: _cancelSignup,
      trailing: TextButton(
        onPressed: _isLoading ? null : _continueLater,
        child: const Text('Continue later'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...UserRole.accountTypeOptions.map(
            (role) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AccountTypeCard(
                role: role,
                selected: (_selected ?? current) == role,
                onTap: () => setState(() => _selected = role),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ProofButton(
            label: 'Continue',
            isLoading: _isLoading,
            onPressed: _continue,
          ),
          const SizedBox(height: 12),
          ProofButton(
            label: 'Cancel signup',
            isOutlined: true,
            isLoading: _isLoading,
            onPressed: _cancelSignup,
          ),
        ],
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle, color: AppColors.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Athlete physical identity ───────────────────────────────────────────────

class AthleteIdentityOnboardingScreen extends ConsumerStatefulWidget {
  const AthleteIdentityOnboardingScreen({super.key});

  @override
  ConsumerState<AthleteIdentityOnboardingScreen> createState() =>
      _AthleteIdentityOnboardingScreenState();
}

class _AthleteIdentityOnboardingScreenState
    extends ConsumerState<AthleteIdentityOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _handleController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();
  final _qualificationsController = TextEditingController();
  File? _avatarFile;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _handleController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  void _loadDraft(UserRole accountType, OnboardingDraft draft) {
    if (_initialized) return;
    _initialized = true;
    final pi = draft.physicalIdentity;
    final cp = draft.coachProfile;
    _displayNameController.text =
        OnboardingDraft.string(pi, 'displayName') ?? '';
    _handleController.text = OnboardingDraft.string(pi, 'handle') ?? '';
    _countryController.text = OnboardingDraft.string(pi, 'country') ?? '';
    _bioController.text = OnboardingDraft.string(pi, 'bio') ?? '';
    if (accountType == UserRole.athleteAndCoach) {
      _qualificationsController.text =
          OnboardingDraft.string(cp, 'qualifications') ?? '';
    }
  }

  Future<void> _saveDraft(UserRole accountType) async {
    final user = ref.read(authServiceProvider).currentUser!;
    final userModel = ref.read(currentUserProvider).valueOrNull;
    var draft = OnboardingDraft(
      physicalIdentity: {
        'displayName': _displayNameController.text.trim(),
        'handle': _handleController.text.trim(),
        'country': _countryController.text.trim(),
        'bio': _bioController.text.trim(),
      },
      selectedGymId: userModel?.onboardingDraft.selectedGymId,
    );
    if (accountType == UserRole.athleteAndCoach) {
      draft = draft.copyWith(
        coachProfile: {
          'displayName': _displayNameController.text.trim(),
          'handle': _handleController.text.trim(),
          'country': _countryController.text.trim(),
          'bio': _bioController.text.trim(),
          'qualifications': _qualificationsController.text.trim(),
        },
      );
    }
    await ref.read(firestoreServiceProvider).saveOnboardingDraft(
          userId: user.uid,
          draft: draft,
        );
  }

  Future<void> _back(UserRole accountType) async {
    await navigateOnboardingBack(
      ref: ref,
      context: context,
      currentStep: OnboardingStep.createPhysicalIdentity,
      accountType: accountType,
      saveDraft: () => _saveDraft(accountType),
    );
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null) setState(() => _avatarFile = File(image.path));
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final firestore = ref.read(firestoreServiceProvider);
      final userModel = ref.read(currentUserProvider).valueOrNull;
      final accountType = userModel?.accountType ?? UserRole.athlete;
      final handle = _handleController.text.trim().toLowerCase();

      if (!(userModel?.hasIdentity ?? false)) {
        final available =
            await firestore.isHandleAvailableForUser(handle, user.uid);
        if (!available) {
          setState(() => _error = 'This handle is already taken');
          return;
        }
      }

      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await ref.read(storageServiceProvider).uploadAvatar(
              userId: user.uid,
              file: _avatarFile!,
            );
      } else if (userModel?.hasIdentity ?? false) {
        avatarUrl = (await firestore.getIdentity(user.uid))?.avatarUrl;
      }

      final now = DateTime.now();
      final identity = PhysicalIdentity(
        userId: user.uid,
        displayName: _displayNameController.text.trim(),
        handle: handle,
        bio: _bioController.text.trim(),
        location: _countryController.text.trim(),
        avatarUrl: avatarUrl,
        createdAt: now,
        updatedAt: now,
      );

      await firestore.createPhysicalIdentityDuringOnboarding(
        identity: identity,
        accountType: accountType,
      );

      if (accountType == UserRole.athleteAndCoach) {
        await firestore.createCoachProfileDuringOnboarding(
          userId: user.uid,
          profile: CoachProfile(
            userId: user.uid,
            handle: handle,
            displayName: identity.displayName,
            specialty: 'Coach',
            bio: _bioController.text.trim(),
            avatarUrl: avatarUrl,
            country: _countryController.text.trim(),
            qualifications: _qualificationsController.text.trim(),
            updatedAt: DateTime.now(),
          ),
          accountType: accountType,
          reserveHandle: false,
        );
      }

      if (!mounted) return;
      context.go(OnboardingPaths.selectGym);
    } catch (e) {
      setState(() => _error = 'Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = ref.watch(currentUserProvider).valueOrNull;
    final accountType = userModel?.accountType ?? UserRole.athlete;
    final isDualRole = accountType == UserRole.athleteAndCoach;
    if (userModel != null) {
      _loadDraft(accountType, userModel.onboardingDraft);
    }

    return OnboardingScaffold(
      title: isDualRole ? 'Create Your Profile' : 'Create Physical Identity',
      subtitle: isDualRole
          ? 'One profile for your athlete and coach activity — name, handle, and coaching details.'
          : 'Your public athlete profile — display name, handle, and country.',
      onBack: () => _back(accountType),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surface,
                  backgroundImage:
                      _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null
                      ? const Icon(Icons.add_a_photo, color: AppColors.inkMuted)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Avatar (optional)',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
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
              controller: _countryController,
              label: 'Country',
              validator: (v) => Validators.required(v, field: 'Country'),
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _bioController,
              label: isDualRole ? 'Bio' : 'Bio',
              maxLines: 3,
            ),
            if (isDualRole) ...[
              const SizedBox(height: 24),
              Text(
                'Coaching',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ProofTextField(
                controller: _qualificationsController,
                label: 'Qualifications (optional)',
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 32),
            ProofButton(
              label: 'Continue',
              isLoading: _isLoading,
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coach profile ───────────────────────────────────────────────────────────

class CoachProfileOnboardingScreen extends ConsumerStatefulWidget {
  const CoachProfileOnboardingScreen({super.key});

  @override
  ConsumerState<CoachProfileOnboardingScreen> createState() =>
      _CoachProfileOnboardingScreenState();
}

class _CoachProfileOnboardingScreenState
    extends ConsumerState<CoachProfileOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();
  final _qualificationsController = TextEditingController();
  File? _avatarFile;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  void _loadDraft(OnboardingDraft draft) {
    if (_initialized) return;
    _initialized = true;
    final cp = draft.coachProfile;
    _nameController.text = OnboardingDraft.string(cp, 'displayName') ?? '';
    _handleController.text = OnboardingDraft.string(cp, 'handle') ?? '';
    _countryController.text = OnboardingDraft.string(cp, 'country') ?? '';
    _bioController.text = OnboardingDraft.string(cp, 'bio') ?? '';
    _qualificationsController.text =
        OnboardingDraft.string(cp, 'qualifications') ?? '';
  }

  Future<void> _saveDraft() async {
    final user = ref.read(authServiceProvider).currentUser!;
    final userModel = ref.read(currentUserProvider).valueOrNull;
    final draft = (userModel?.onboardingDraft ?? const OnboardingDraft())
        .copyWith(
      coachProfile: {
        'displayName': _nameController.text.trim(),
        'handle': _handleController.text.trim(),
        'country': _countryController.text.trim(),
        'bio': _bioController.text.trim(),
        'qualifications': _qualificationsController.text.trim(),
      },
    );
    await ref.read(firestoreServiceProvider).saveOnboardingDraft(
          userId: user.uid,
          draft: draft,
        );
  }

  Future<void> _back() async {
    await navigateOnboardingBack(
      ref: ref,
      context: context,
      currentStep: OnboardingStep.createCoachProfile,
      accountType: UserRole.coach,
      saveDraft: _saveDraft,
    );
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null) setState(() => _avatarFile = File(image.path));
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final firestore = ref.read(firestoreServiceProvider);
      final userModel = ref.read(currentUserProvider).valueOrNull;
      final accountType = userModel?.accountType ?? UserRole.coach;
      final handle = _handleController.text.trim().toLowerCase();
      final hasIdentity = userModel?.hasIdentity ?? false;

      if (!hasIdentity) {
        final available =
            await firestore.isHandleAvailableForUser(handle, user.uid);
        if (!available) {
          setState(() => _error = 'This handle is already taken');
          return;
        }
      }

      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await ref.read(storageServiceProvider).uploadAvatar(
              userId: user.uid,
              file: _avatarFile!,
            );
      } else if (hasIdentity) {
        avatarUrl = (await firestore.getIdentity(user.uid))?.avatarUrl;
      }

      final profile = CoachProfile(
        userId: user.uid,
        handle: handle,
        displayName: _nameController.text.trim(),
        specialty: 'Coach',
        bio: _bioController.text.trim(),
        avatarUrl: avatarUrl,
        country: _countryController.text.trim(),
        qualifications: _qualificationsController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await firestore.createCoachProfileDuringOnboarding(
        userId: user.uid,
        profile: profile,
        accountType: accountType,
        reserveHandle: !hasIdentity,
      );

      if (!mounted) return;
      context.go(OnboardingPaths.selectGym);
    } catch (e) {
      setState(() => _error = 'Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = ref.watch(currentUserProvider).valueOrNull;
    final accountType = userModel?.accountType ?? UserRole.coach;

    if (accountType == UserRole.athleteAndCoach) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(OnboardingPaths.selectGym);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userModel != null) _loadDraft(userModel.onboardingDraft);

    return OnboardingScaffold(
      title: 'Create Coach Profile',
      subtitle:
          'Tell athletes about your coaching. You will choose your primary gym next.',
      onBack: _back,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surface,
                  backgroundImage:
                      _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null
                      ? const Icon(Icons.add_a_photo, color: AppColors.inkMuted)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ProofTextField(
              controller: _nameController,
              label: 'Full name',
              validator: (v) => Validators.required(v, field: 'Full name'),
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
              controller: _countryController,
              label: 'Country',
              validator: (v) => Validators.required(v, field: 'Country'),
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _bioController,
              label: 'Coaching bio',
              maxLines: 3,
              validator: (v) => Validators.required(v, field: 'Coaching bio'),
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _qualificationsController,
              label: 'Qualifications (optional)',
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ProofButton(
              label: 'Continue',
              isLoading: _isLoading,
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gym profile ─────────────────────────────────────────────────────────────

class GymProfileOnboardingScreen extends ConsumerStatefulWidget {
  const GymProfileOnboardingScreen({super.key});

  @override
  ConsumerState<GymProfileOnboardingScreen> createState() =>
      _GymProfileOnboardingScreenState();
}

class _GymProfileOnboardingScreenState
    extends ConsumerState<GymProfileOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _managerController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _logoFile;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _managerController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadDraft(OnboardingDraft draft) {
    if (_initialized) return;
    _initialized = true;
    final g = draft.gymProfile;
    _nameController.text = OnboardingDraft.string(g, 'name') ?? '';
    _handleController.text = OnboardingDraft.string(g, 'handle') ?? '';
    _countryController.text = OnboardingDraft.string(g, 'country') ?? '';
    _cityController.text = OnboardingDraft.string(g, 'city') ?? '';
    _addressController.text = OnboardingDraft.string(g, 'address') ?? '';
    _websiteController.text = OnboardingDraft.string(g, 'website') ?? '';
    _emailController.text = OnboardingDraft.string(g, 'contactEmail') ?? '';
    _descriptionController.text = OnboardingDraft.string(g, 'description') ?? '';
    _managerController.text = OnboardingDraft.string(g, 'managerName') ?? '';
    _phoneController.text = OnboardingDraft.string(g, 'phone') ?? '';
  }

  Future<void> _saveDraft() async {
    final user = ref.read(authServiceProvider).currentUser!;
    final userModel = ref.read(currentUserProvider).valueOrNull;
    final draft = (userModel?.onboardingDraft ?? const OnboardingDraft())
        .copyWith(
      gymProfile: {
        'name': _nameController.text.trim(),
        'handle': _handleController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'website': _websiteController.text.trim(),
        'contactEmail': _emailController.text.trim(),
        'description': _descriptionController.text.trim(),
        'managerName': _managerController.text.trim(),
        'phone': _phoneController.text.trim(),
      },
    );
    await ref.read(firestoreServiceProvider).saveOnboardingDraft(
          userId: user.uid,
          draft: draft,
        );
  }

  Future<void> _back() async {
    await navigateOnboardingBack(
      ref: ref,
      context: context,
      currentStep: OnboardingStep.createGymProfile,
      accountType: UserRole.gymManager,
      saveDraft: _saveDraft,
    );
  }

  Future<void> _pickLogo() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null) setState(() => _logoFile = File(image.path));
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final firestore = ref.read(firestoreServiceProvider);
      final handle = _handleController.text.trim().toLowerCase();

      final existingGymId =
          ref.read(currentUserProvider).valueOrNull?.managedGymIds.firstOrNull;
      if (existingGymId == null) {
        final available = await firestore.isGymHandleAvailable(handle);
        if (!available) {
          setState(() => _error = 'This gym handle is already taken');
          return;
        }
      }

      String? logoUrl;
      if (_logoFile != null) {
        try {
          final tempId = existingGymId ?? 'pending_${user.uid}';
          logoUrl = await ref.read(storageServiceProvider).uploadGymLogo(
                gymId: tempId,
                file: _logoFile!,
              );
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Logo upload failed. Creating gym without a logo.',
              ),
            ),
          );
        }
      }

      final gym = GymModel(
        id: existingGymId ?? '',
        name: _nameController.text.trim(),
        handle: handle,
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim(),
        description: _descriptionController.text.trim(),
        contactEmail: _emailController.text.trim(),
        managerName: _managerController.text.trim(),
        phone: _phoneController.text.trim(),
        logoUrl: logoUrl,
        status: GymStatus.active,
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      final gymId = await firestore.completeGymOnboarding(
        createdBy: user.uid,
        gym: gym,
      );

      if (!mounted) return;
      context.go('/gym-manager/$gymId');
    } on FirebaseException catch (e) {
      setState(() {
        _error = e.code == 'permission-denied'
            ? 'Permission denied. Deploy the latest Firestore rules, then try again.'
            : (e.message ?? 'Failed to create gym (${e.code}).');
      });
    } catch (e) {
      setState(() => _error = 'Failed to create gym: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = ref.watch(currentUserProvider).valueOrNull;
    if (userModel != null) _loadDraft(userModel.onboardingDraft);

    return OnboardingScaffold(
      title: 'Create Gym Profile',
      subtitle:
          'Set up your gym identity. You will be added as the approved manager.',
      onBack: _back,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surface,
                  backgroundImage:
                      _logoFile != null ? FileImage(_logoFile!) : null,
                  child: _logoFile == null
                      ? const Icon(Icons.add_a_photo, color: AppColors.inkMuted)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Gym logo (optional)',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            ProofTextField(
              controller: _nameController,
              label: 'Gym name',
              validator: (v) => Validators.required(v, field: 'Gym name'),
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _handleController,
              label: 'Gym handle',
              prefixText: '@',
              validator: Validators.handle,
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _countryController,
              label: 'Country',
              validator: (v) => Validators.required(v, field: 'Country'),
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _cityController,
              label: 'City',
              validator: (v) => Validators.required(v, field: 'City'),
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _addressController,
              label: 'Address',
              validator: (v) => Validators.required(v, field: 'Address'),
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _websiteController,
              label: 'Website (optional)',
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _emailController,
              label: 'Contact email',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
              validator: (v) => Validators.required(v, field: 'Description'),
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _managerController,
              label: 'Primary manager name',
              validator: (v) =>
                  Validators.required(v, field: 'Primary manager name'),
            ),
            const SizedBox(height: 16),
            ProofTextField(
              controller: _phoneController,
              label: 'Phone (optional)',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            ProofButton(
              label: 'Create gym',
              isLoading: _isLoading,
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Select gym (Athlete + Coach) ────────────────────────────────────────────

class SelectGymOnboardingScreen extends ConsumerStatefulWidget {
  const SelectGymOnboardingScreen({super.key});

  @override
  ConsumerState<SelectGymOnboardingScreen> createState() =>
      _SelectGymOnboardingScreenState();
}

class _SelectGymOnboardingScreenState
    extends ConsumerState<SelectGymOnboardingScreen> {
  final _search = TextEditingController();
  String? _selectedGymId;
  GymModel? _handleMatch;
  bool _handleLookupInFlight = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _lookupHandle(String query) async {
    final handle = GymSearch.handleFromQuery(query);
    final shouldLookup = query.trim().startsWith('@') && handle.isNotEmpty;
    if (!shouldLookup) {
      if (_handleMatch != null || _handleLookupInFlight) {
        setState(() {
          _handleMatch = null;
          _handleLookupInFlight = false;
        });
      }
      return;
    }

    setState(() => _handleLookupInFlight = true);
    final gym =
        await ref.read(firestoreServiceProvider).getGymByHandle(handle);
    if (!mounted) return;
    setState(() {
      _handleMatch = gym;
      _handleLookupInFlight = false;
    });
  }

  Future<void> _saveDraft() async {
    final user = ref.read(authServiceProvider).currentUser!;
    final userModel = ref.read(currentUserProvider).valueOrNull;
    final draft = (userModel?.onboardingDraft ?? const OnboardingDraft())
        .copyWith(selectedGymId: _selectedGymId);
    await ref.read(firestoreServiceProvider).saveOnboardingDraft(
          userId: user.uid,
          draft: draft,
        );
  }

  Future<void> _back(UserRole accountType) async {
    await navigateOnboardingBack(
      ref: ref,
      context: context,
      currentStep: OnboardingStep.selectGym,
      accountType: accountType,
      saveDraft: _saveDraft,
    );
  }

  Future<void> _continue({bool skip = false}) async {
    if (!skip && _selectedGymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a primary gym or continue without one'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final firestore = ref.read(firestoreServiceProvider);
      final accountType =
          ref.read(currentUserProvider).valueOrNull?.accountType ??
              UserRole.athlete;

      if (!skip && _selectedGymId != null) {
        await firestore.completeGymSelection(
          userId: user.uid,
          gymId: _selectedGymId!,
          accountType: accountType,
        );
      } else {
        await firestore.completeOnboarding(userId: user.uid);
      }

      if (!mounted) return;
      context.go('/dashboard');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = ref.watch(currentUserProvider).valueOrNull;
    final accountType = userModel?.accountType ?? UserRole.athlete;
    _selectedGymId ??= userModel?.onboardingDraft.selectedGymId;
    final gymsAsync = ref.watch(activeGymsProvider);
    final query = _search.text;

    final title = switch (accountType) {
      UserRole.coach => 'Select your primary gym',
      UserRole.athleteAndCoach => 'Select your primary gym',
      _ => 'Select your primary gym',
    };
    final subtitle = switch (accountType) {
      UserRole.coach =>
        'Search for the gym where you coach. Approval is required before you can verify proofs.',
      UserRole.athleteAndCoach =>
        'Search for the gym where you train and coach. You can request both athlete and coach membership.',
      _ =>
        'Search for the gym where you train. You can join more gyms later from More → Gyms.',
    };

    return OnboardingScaffold(
      title: title,
      subtitle: subtitle,
      onBack: () => _back(accountType),
      child: gymsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Could not load gyms: $e'),
        data: (gyms) {
          final filtered = GymSearch.mergeResults(
            filtered: GymSearch.filterActiveGyms(gyms, query),
            handleMatch: _handleMatch,
          );
          final searching = GymSearch.shouldSearch(query);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GymSearchField(
                controller: _search,
                hint: 'Search gyms or @handle',
                onChanged: (value) {
                  setState(() {});
                  _lookupHandle(value);
                },
              ),
              if (_handleLookupInFlight) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!searching)
                Text(
                  'Type at least 2 characters or an @handle to search.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                )
              else if (filtered.isEmpty && !_handleLookupInFlight)
                Text(
                  'No gyms found. Try another name, city, or @handle.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                )
              else
                _GymPicker(
                  gyms: filtered,
                  selectedGymId: _selectedGymId,
                  onSelected: (id) => setState(() => _selectedGymId = id),
                ),
              const SizedBox(height: 32),
              ProofButton(
                label: 'Continue',
                isLoading: _isLoading,
                onPressed: () => _continue(),
              ),
              const SizedBox(height: 12),
              ProofButton(
                label: 'Continue without gym',
                isOutlined: true,
                isLoading: _isLoading,
                onPressed: () => _continue(skip: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _GymPicker extends StatelessWidget {
  const _GymPicker({
    required this.gyms,
    required this.selectedGymId,
    required this.onSelected,
  });

  final List<GymModel> gyms;
  final String? selectedGymId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (gyms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No gyms registered yet. You can join one later from More → Gyms.',
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
                  onTap: () => onSelected(
                    selectedGymId == gym.id ? null : gym.id,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedGymId == gym.id
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gym.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (gym.handle.isNotEmpty)
                                Text(
                                  '@${gym.handle}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.accent),
                                ),
                              if (gym.country.isNotEmpty)
                                Text(
                                  gym.country,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                            ],
                          ),
                        ),
                        if (selectedGymId == gym.id)
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
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
  }
}
