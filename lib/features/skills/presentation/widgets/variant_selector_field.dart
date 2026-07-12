import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/shared/models/skill_catalog_entry.dart';
import 'package:proof/shared/models/skill_catalog_variant.dart';

class VariantSelectorField extends StatefulWidget {
  const VariantSelectorField({
    super.key,
    required this.entry,
    required this.selectedVariantId,
    required this.customVariantName,
    required this.onChanged,
  });

  final SkillCatalogEntry entry;
  final String? selectedVariantId;
  final String customVariantName;
  final void Function(String? variantId, String variantName) onChanged;

  @override
  State<VariantSelectorField> createState() => _VariantSelectorFieldState();
}

class _VariantSelectorFieldState extends State<VariantSelectorField> {
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(text: widget.customVariantName);
  }

  @override
  void didUpdateWidget(covariant VariantSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customVariantName != widget.customVariantName &&
        widget.customVariantName != _customController.text) {
      _customController.text = widget.customVariantName;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  bool get _isOther =>
      widget.selectedVariantId == SkillCatalogVariant.otherId;

  Future<void> _openSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Text(
                      'Variation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...widget.entry.variants.map(
                    (variant) => ListTile(
                      title: Text(variant.name),
                      trailing: widget.selectedVariantId == variant.id
                          ? const Icon(Icons.check, color: AppColors.accent)
                          : null,
                      onTap: () => Navigator.pop(context, variant.id),
                    ),
                  ),
                  ListTile(
                    title: const Text('Other'),
                    trailing: _isOther
                        ? const Icon(Icons.check, color: AppColors.accent)
                        : null,
                    onTap: () =>
                        Navigator.pop(context, SkillCatalogVariant.otherId),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected == null || !mounted) return;

    if (selected == SkillCatalogVariant.otherId) {
      widget.onChanged(SkillCatalogVariant.otherId, _customController.text.trim());
      return;
    }

    final variant = widget.entry.findVariant(selected);
    widget.onChanged(selected, variant?.name ?? selected);
  }

  String get _displayLabel {
    if (_isOther) {
      final custom = widget.customVariantName.trim();
      return custom.isEmpty ? 'Other' : custom;
    }
    final variant = widget.entry.findVariant(widget.selectedVariantId);
    return variant?.name ?? 'Select variation';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _openSheet,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Variation',
              suffixIcon: Icon(Icons.expand_more),
            ),
            child: Text(
              _displayLabel,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        if (_isOther) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _customController,
            decoration: const InputDecoration(
              labelText: 'Custom variation name',
              hintText: 'Optional',
            ),
            onChanged: (value) {
              widget.onChanged(SkillCatalogVariant.otherId, value.trim());
            },
          ),
        ],
      ],
    );
  }
}

String? resolveVariantIdForSave({
  required SkillCatalogEntry entry,
  required String? selectedVariantId,
  required String customVariantName,
}) {
  if (!entry.supportsVariants) return null;

  final id = selectedVariantId?.trim();
  if (id == null || id.isEmpty) return null;

  if (id == SkillCatalogVariant.otherId) {
    final name = customVariantName.trim();
    if (name.isEmpty) return SkillCatalogVariant.otherId;
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '${SkillCatalogVariant.otherId}:$slug';
  }
  return id;
}

String? resolveVariantNameForSave({
  required SkillCatalogEntry entry,
  required String? selectedVariantId,
  required String customVariantName,
}) {
  if (!entry.supportsVariants) return null;

  final id = selectedVariantId?.trim();
  if (id == null || id.isEmpty) return null;

  if (id == SkillCatalogVariant.otherId) {
    final name = customVariantName.trim();
    return name.isEmpty ? 'Other' : name;
  }

  return entry.findVariant(id)?.name;
}

String? validateVariantSelection({
  required SkillCatalogEntry entry,
  required String? selectedVariantId,
}) {
  if (!entry.supportsVariants) return null;
  if (selectedVariantId == null || selectedVariantId.isEmpty) {
    return 'Select a variation';
  }
  return null;
}
