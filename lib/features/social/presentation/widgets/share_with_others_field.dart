import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/providers/gym_providers.dart';

/// Opt-in control for a single proof upload.
///
/// [initialValue] is always false. Callers must keep the checkbox in widget
/// state and must not persist it.
class ShareWithOthersField extends StatelessWidget {
  const ShareWithOthersField({
    super.key,
    required this.value,
    required this.enabled,
    this.onChanged,
    this.gymIds = const [],
    this.selectedGymId,
    this.onGymChanged,
  });

  static const bool initialValue = false;

  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final List<String> gymIds;
  final String? selectedGymId;
  final ValueChanged<String>? onGymChanged;

  @override
  Widget build(BuildContext context) {
    final caption = enabled
        ? 'Share this achievement with other members of your gym.'
        : 'Sharing requires an approved gym membership. You can still save this proof privately.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: enabled && value,
          onChanged: enabled && onChanged != null
              ? (next) => onChanged!(next ?? false)
              : null,
          title: Text(
            'Share with others',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: enabled ? AppColors.ink : AppColors.inkMuted,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
          ),
        ),
        if (enabled && value && gymIds.length > 1) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('share-gym-${selectedGymId ?? 'none'}'),
            initialValue:
                selectedGymId != null && gymIds.contains(selectedGymId)
                    ? selectedGymId
                    : null,
            decoration: const InputDecoration(labelText: 'Gym'),
            items: [
              for (final gymId in gymIds)
                DropdownMenuItem(
                  value: gymId,
                  child: _GymMenuName(gymId: gymId),
                ),
            ],
            onChanged: onGymChanged == null
                ? null
                : (gymId) {
                    if (gymId != null) onGymChanged!(gymId);
                  },
          ),
        ],
      ],
    );
  }
}

class _GymMenuName extends ConsumerWidget {
  const _GymMenuName({required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(gymProvider(gymId)).valueOrNull?.name;
    return Text(
      name == null || name.isEmpty ? 'Your gym' : name,
      overflow: TextOverflow.ellipsis,
    );
  }
}
