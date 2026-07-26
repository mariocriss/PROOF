import 'package:flutter/foundation.dart';
import 'package:proof/shared/models/skill_model.dart';

/// Deduplicates skills by Firestore document ID, preserving first-seen order.
///
/// Logs duplicate IDs in debug builds so upstream merge bugs can be spotted.
List<SkillModel> uniqueSkillsById(Iterable<SkillModel> skills) {
  final seen = <String>{};
  final unique = <SkillModel>[];
  for (final skill in skills) {
    if (skill.id.isEmpty) continue;
    if (!seen.add(skill.id)) {
      assert(() {
        debugPrint(
          'Duplicate skill id in dropdown source: ${skill.id} '
          '(${skill.name})',
        );
        return true;
      }());
      continue;
    }
    unique.add(skill);
  }
  return unique;
}

/// Returns [selectedId] only when it appears exactly once in [skills].
String? resolvedSkillDropdownValue({
  required String? selectedId,
  required List<SkillModel> skills,
}) {
  if (selectedId == null || selectedId.isEmpty) return null;
  var matches = 0;
  for (final skill in skills) {
    if (skill.id == selectedId) matches++;
  }
  return matches == 1 ? selectedId : null;
}

SkillModel? skillById(List<SkillModel> skills, String? id) {
  if (id == null || id.isEmpty) return null;
  for (final skill in skills) {
    if (skill.id == id) return skill;
  }
  return null;
}
