import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/gyms/presentation/widgets/gym_manager_widgets.dart';
import 'package:proof/shared/models/user_role.dart';
import 'package:proof/shared/providers/app_providers.dart';
import 'package:proof/shared/providers/gym_providers.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

export 'package:proof/features/gyms/presentation/gym_manager_dashboard.dart';

class GymManagerHubScreen extends ConsumerWidget {
  const GymManagerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymsAsync = ref.watch(managedGymsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProofAppBar(
        title: 'Gym Manager',
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/gym-manager/create'),
          ),
        ],
      ),
      body: gymsAsync.when(
        loading: () => const GymManagerSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (gyms) {
          if (gyms.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyState(
                title: 'No gyms managed',
                message:
                    'Create a gym to approve athlete and coach memberships.',
                action: ProofButton(
                  label: 'Create gym',
                  onPressed: () => context.push('/gym-manager/create'),
                ),
              ),
            );
          }
          if (gyms.length == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/gym-manager/${gyms.first.id}');
            });
            return const GymManagerSkeleton();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: gyms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final gym = gyms[index];
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => context.push('/gym-manager/${gym.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
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
                              Text(
                                '@${gym.handle}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CreateGymScreen extends ConsumerStatefulWidget {
  const CreateGymScreen({super.key});

  @override
  ConsumerState<CreateGymScreen> createState() => _CreateGymScreenState();
}

class _CreateGymScreenState extends ConsumerState<CreateGymScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _countryController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final firestore = ref.read(firestoreServiceProvider);
      final gymId = await firestore.createGym(
        createdBy: user.uid,
        name: _nameController.text.trim(),
        handle: _handleController.text.trim(),
        country: _countryController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      await firestore.updateUserProfile(
        userId: user.uid,
        role: UserRole.gymManager,
        primaryGymId: gymId,
      );
      if (!mounted) return;
      context.go('/gym-manager/$gymId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProofAppBar(
        title: 'Create gym',
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ProofTextField(
                controller: _nameController,
                label: 'Gym name',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ProofTextField(
                controller: _handleController,
                label: 'Handle',
                prefixText: '@',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ProofTextField(controller: _countryController, label: 'Country'),
              const SizedBox(height: 16),
              ProofTextField(controller: _addressController, label: 'Address'),
              const SizedBox(height: 16),
              ProofTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ProofButton(
                label: 'Create gym',
                isLoading: _isLoading,
                onPressed: _create,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
