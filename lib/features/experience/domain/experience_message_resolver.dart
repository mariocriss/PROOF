import 'package:intl/intl.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';

class ExperienceResolvedMessages {
  const ExperienceResolvedMessages({
    required this.primary,
    this.secondary,
    required this.ctaLabel,
    this.secondaryCtaLabel,
  });

  final String primary;
  final String? secondary;
  final String ctaLabel;
  final String? secondaryCtaLabel;
}

/// Centralized, non-generated copy for experience moments.
class ExperienceMessageResolver {
  const ExperienceMessageResolver();

  static final _dateFormat = DateFormat.yMMMd();

  ExperienceResolvedMessages resolve({
    required ExperienceEventType type,
    required ExperienceContext context,
    String? ctaOverride,
    String? secondaryCtaOverride,
  }) {
    switch (type) {
      case ExperienceEventType.onboardingCompleted:
        return ExperienceResolvedMessages(
          primary: 'Your physical identity record begins today.',
          secondary:
              'You do not need to record everything. Only what deserves to be remembered.',
          ctaLabel: ctaOverride ?? 'Build My Identity',
        );
      case ExperienceEventType.firstProofCreated:
        return ExperienceResolvedMessages(
          primary: 'Your first proof. Everything else builds from here.',
          secondary:
              'The first piece of evidence is now on your record.',
          ctaLabel: ctaOverride ?? 'View My Passport',
        );
      case ExperienceEventType.coachVerified:
        return ExperienceResolvedMessages(
          primary: _coachPrimary(context),
          secondary: 'Someone else believes this belongs in your story.',
          ctaLabel: ctaOverride ?? 'View Verified Proof',
          secondaryCtaLabel: secondaryCtaOverride ?? 'Share This Chapter',
        );
      case ExperienceEventType.silentMoment:
        return const ExperienceResolvedMessages(
          primary: '',
          ctaLabel: 'Continue',
        );
      case ExperienceEventType.whisper:
        return ExperienceResolvedMessages(
          primary: context.extra['whisper'] ?? 'A quiet note.',
          ctaLabel: ctaOverride ?? 'Continue',
        );
      case ExperienceEventType.momentDemo:
        return const ExperienceResolvedMessages(
          primary: 'A moment worth pausing for.',
          secondary: 'Gallery preview only.',
          ctaLabel: 'Continue',
        );
      case ExperienceEventType.landmarkDemo:
        return const ExperienceResolvedMessages(
          primary: 'A landmark in your physical life.',
          secondary: 'Gallery preview only.',
          ctaLabel: 'Continue',
        );
      default:
        return const ExperienceResolvedMessages(
          primary: 'Something meaningful happened.',
          ctaLabel: 'Continue',
        );
    }
  }

  String _coachPrimary(ExperienceContext context) {
    final name = context.coachName.trim();
    final date = context.verificationDate;
    final dateLabel = date != null ? _dateFormat.format(date) : '';
    if (name.isNotEmpty && dateLabel.isNotEmpty) {
      return '$name verified this on $dateLabel. It is witnessed now.';
    }
    if (name.isNotEmpty) {
      return '$name verified this. It is witnessed now.';
    }
    return 'Your coach verified this. It is witnessed now.';
  }

  /// Alternate primary lines for A/B or gallery — not generated.
  List<String> alternatePrimaries(ExperienceEventType type) {
    return switch (type) {
      ExperienceEventType.onboardingCompleted => const [
          'Your passport is ready.',
          'The first page is yours.',
          'Whenever you are ready, it is yours.',
        ],
      ExperienceEventType.firstProofCreated => const [
          'Your story has begun.',
        ],
      ExperienceEventType.coachVerified => const [
          'Someone else believes this belongs in your story.',
        ],
      _ => const <String>[],
    };
  }
}
