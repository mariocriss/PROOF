import 'package:flutter/material.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';

/// Compact proof identity before stamp — documentary, not badge-like.
class ProofRecordCard extends StatelessWidget {
  const ProofRecordCard({
    super.key,
    required this.skillName,
    required this.result,
    this.unit = '',
    this.compact = false,
  });

  final String skillName;
  final String result;
  final String unit;
  final bool compact;

  String get _formatted {
    final r = result.trim();
    final u = unit.trim();
    if (r.isEmpty) return 'Proof recorded';
    if (u.isEmpty) return r;
    return '$r $u';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Proof: $skillName, $_formatted',
      child: Container(
        width: compact ? 200 : 260,
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: ExperienceTokens.paperBackground,
          borderRadius: BorderRadius.circular(ExperienceTokens.cornerRadiusSoft),
          border: Border.all(
            color: ExperienceTokens.recordInk.withValues(alpha: 0.10),
          ),
          boxShadow: ExperienceTokens.contactShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skillName.isEmpty ? 'Skill' : skillName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: ExperienceTokens.identityInk.withValues(alpha: 0.55),
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            Text(
              _formatted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: ExperienceTokens.recordInk,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
