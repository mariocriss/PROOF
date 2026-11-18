import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/experience/application/experience_coordinator.dart';
import 'package:proof/features/experience/application/experience_diagnostics.dart';
import 'package:proof/features/experience/application/experience_providers.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_message_resolver.dart';
import 'package:proof/features/experience/domain/experience_playback_settings.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';
import 'package:proof/features/experience/domain/passport_stamp.dart';
import 'package:proof/features/experience/media/experience_sound_service.dart';
import 'package:proof/features/experience/presentation/experience_overlay_controller.dart';
import 'package:proof/features/experience/presentation/widgets/experience_stage.dart';
import 'package:proof/features/experience/presentation/widgets/passport_book.dart';
import 'package:proof/features/experience/presentation/widgets/proof_record_card.dart';
import 'package:proof/features/experience/presentation/widgets/registrar_panel.dart';

/// Hosts experience overlays above the app without trapping navigation.
class ExperienceOverlayHost extends ConsumerWidget {
  const ExperienceOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(experienceOverlayControllerProvider);
    final request = controller.request;
    final mq = MediaQuery.maybeOf(context);
    final osReduce = mq?.disableAnimations ?? false;
    final playback = ref.watch(experiencePlaybackSettingsProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (request != null)
          Positioned.fill(
            child: ExperienceMomentSurface(
              request: request.copyWithOsReduceMotion(osReduce),
              controller: controller,
              playback: playback,
            ),
          ),
      ],
    );
  }
}

extension on ExperiencePresentationRequest {
  ExperiencePresentationRequest copyWithOsReduceMotion(bool osReduce) {
    if (!osReduce) return this;
    return ExperiencePresentationRequest(
      event: event,
      definition: definition,
      preferences: preferences.copyWith(
        motion: preferences.motion.copyWith(reduceMotion: true),
      ),
      flags: flags,
      reduceMotion: true,
    );
  }
}

class ExperienceMomentSurface extends ConsumerStatefulWidget {
  const ExperienceMomentSurface({
    super.key,
    required this.request,
    required this.controller,
    required this.playback,
  });

  final ExperiencePresentationRequest request;
  final ExperienceOverlayController controller;
  final ExperiencePlaybackSettings playback;

  @override
  ConsumerState<ExperienceMomentSurface> createState() =>
      _ExperienceMomentSurfaceState();
}

class _ExperienceMomentSurfaceState
    extends ConsumerState<ExperienceMomentSurface> {
  static final _dateFormat = DateFormat.yMMMd();
  final _resolver = const ExperienceMessageResolver();

  bool _passportOpened = false;
  bool _showProofCard = false;
  bool _showPassportPage = false;
  bool _stampVisible = false;
  bool _witnessVisible = false;
  bool _showInvitation = false;
  bool _showCopy = false;
  bool _showCta = false;
  bool _effectsAtStamp = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(experienceDiagnosticsProvider).log(
            ExperienceDiagnosticKind.overlayShown,
            eventId: widget.request.event.id,
          );
    });

    if (widget.playback.simulatePresentationException) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.complete(ExperiencePresentationOutcome.failed);
      });
      return;
    }
    _timeout = Timer(ExperienceTokens.safeAnimationTimeout, () {
      if (mounted) widget.controller.skip();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSequence());
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  Duration _d(Duration base) => widget.playback.scale(base);

  Future<void> _delay(Duration d) async {
    if (d <= Duration.zero || !mounted) return;
    await Future<void>.delayed(d);
  }

  Future<void> _runSequence() async {
    final type = widget.request.event.type;
    final reduce = widget.request.reduceMotion;
    final hold = widget.playback.silentMomentDuration;

    try {
      if (widget.playback.simulateSourceMissing &&
          type != ExperienceEventType.onboardingCompleted) {
        setState(() {
          _showCopy = true;
          _showCta = true;
        });
        return;
      }

      switch (type) {
        case ExperienceEventType.onboardingCompleted:
          if (reduce) {
            setState(() {
              _passportOpened = true;
              _showCopy = true;
              _showCta = true;
            });
            await _playIssuanceEffects();
          } else {
            setState(() => _showInvitation = true);
          }
        case ExperienceEventType.firstProofCreated:
          setState(() => _showProofCard = true);
          if (!reduce) await _delay(hold);
          if (!mounted) return;
          setState(() {
            _showPassportPage = true;
            _showProofCard = false;
          });
          if (!reduce) await _delay(_d(const Duration(milliseconds: 360)));
          if (!mounted) return;
          setState(() => _stampVisible = true);
          await _playStampEffects();
          if (!mounted) return;
          await _delay(_d(ExperienceTokens.breath));
          if (!mounted) return;
          setState(() {
            _showCopy = true;
            _showCta = true;
          });
        case ExperienceEventType.coachVerified:
          setState(() => _showPassportPage = true);
          setState(() => _stampVisible = true);
          if (!reduce) await _delay(hold);
          if (!mounted) return;
          setState(() => _witnessVisible = true);
          await _playWitnessEffects();
          if (!mounted) return;
          await _delay(_d(ExperienceTokens.breath));
          if (!mounted) return;
          setState(() {
            _showCopy = true;
            _showCta = true;
          });
        default:
          setState(() {
            _showCopy = true;
            _showCta = true;
          });
      }
    } catch (_) {
      if (mounted) {
        widget.controller.complete(ExperiencePresentationOutcome.failed);
      }
    }
  }

  Future<void> _openPassport() async {
    if (_passportOpened) return;
    setState(() {
      _passportOpened = true;
      _showInvitation = false;
    });
    await _playIssuanceEffects();
    if (!mounted) return;
    await _delay(_d(const Duration(milliseconds: 480)));
    if (!mounted) return;
    setState(() => _showCopy = true);
    await _delay(_d(ExperienceTokens.breath));
    if (!mounted) return;
    setState(() => _showCta = true);
  }

  Future<void> _playIssuanceEffects() async {
    if (_effectsAtStamp) return;
    _effectsAtStamp = true;
    await widget.controller.haptics?.play(widget.request.definition.haptic);
    await _playSound(widget.request.definition.sound);
  }

  Future<void> _playStampEffects() async {
    if (_effectsAtStamp) return;
    _effectsAtStamp = true;
    await widget.controller.haptics?.play(widget.request.definition.haptic);
    await _playSound(widget.request.definition.sound);
  }

  Future<void> _playWitnessEffects() async {
    if (_effectsAtStamp) return;
    _effectsAtStamp = true;
    await widget.controller.haptics?.play(widget.request.definition.haptic);
    await _playSound(widget.request.definition.sound);
  }

  Future<void> _playSound(ExperienceSoundKind kind) async {
    if (widget.playback.simulateSoundFailure) return;
    await widget.controller.sound?.play(kind);
  }

  void _finish(ExperiencePresentationOutcome outcome, {String? route}) {
    _timeout?.cancel();
    widget.controller.complete(outcome);
    if (route != null && mounted) {
      try {
        context.go(route);
      } catch (_) {}
    }
  }

  String? _ctaRoute() {
    final type = widget.request.event.type;
    final proofId = widget.request.event.context.proofId;
    return switch (type) {
      ExperienceEventType.onboardingCompleted => '/skills',
      ExperienceEventType.firstProofCreated => '/passport',
      ExperienceEventType.coachVerified =>
        proofId.isNotEmpty ? '/proofs' : '/passport',
      _ => null,
    };
  }

  Widget _fadeIn({required bool visible, required Widget child}) {
    if (widget.request.reduceMotion) {
      return visible ? child : const SizedBox.shrink();
    }
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: _d(ExperienceTokens.breath),
      curve: ExperienceTokens.primaryCurve,
      child: visible ? child : const SizedBox.shrink(),
    );
  }

  double get _bookWidth {
    final screen = MediaQuery.sizeOf(context).width;
    return (screen * 0.58).clamp(200.0, 240.0);
  }

  double get _spreadWidth {
    final screen = MediaQuery.sizeOf(context).width;
    return (screen * 0.88).clamp(300.0, 380.0);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final ctx = req.event.context;
    final messages = _resolver.resolve(type: req.event.type, context: ctx);
    final guideOn = req.flags.guideEnabled && req.preferences.guideEnabled;
    final reduce = req.reduceMotion;
    final type = req.event.type;
    final playback = widget.playback;
    final isIssuance = type == ExperienceEventType.onboardingCompleted;
    final openCtaVisible = isIssuance && !_passportOpened && !_showCta;

    Widget focal = _buildFocal(type, ctx, reduce, messages);

    if (playback.deviceWidth != null) {
      focal = SizedBox(width: playback.deviceWidth, child: focal);
    }

    focal = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(playback.textScale),
      ),
      child: focal,
    );

    if (playback.showAnimationBounds) {
      focal = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: focal,
      );
    }

    return ExperienceStage(
      skippable: req.definition.skippable,
      onSkip: () => _finish(ExperiencePresentationOutcome.dismissed),
      ctaLabel: messages.ctaLabel,
      ctaVisible: _showCta,
      onCta: () => _finish(
        ExperiencePresentationOutcome.completed,
        route: _ctaRoute(),
      ),
      secondaryAction: openCtaVisible
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ExperienceTokens.spacingLg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ExperienceTokens.identityInk,
                    side: BorderSide(
                      color: ExperienceTokens.identityInk.withValues(alpha: 0.25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _openPassport,
                  child: const Text('Open Passport'),
                ),
              ),
            )
          : null,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showInvitation && !_passportOpened)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: guideOn
                  ? const RegistrarPanel(
                      primary: 'Your passport is ready.',
                      compact: true,
                    )
                  : Text(
                      'Your passport is ready.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ExperienceTokens.identityInk,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
            ),
          _fadeIn(
            visible: _showCopy,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: _buildCopy(guideOn, messages, ctx, type),
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: focal,
      ),
    );
  }

  Widget _buildFocal(
    ExperienceEventType type,
    ExperienceContext ctx,
    bool reduce,
    ExperienceResolvedMessages messages,
  ) {
    switch (type) {
      case ExperienceEventType.onboardingCompleted:
        return PassportBookVisual(
          displayName: ctx.displayName,
          opened: _passportOpened || reduce,
          reduceMotion: reduce,
          onTapClosed: _openPassport,
          width: _bookWidth,
        );
      case ExperienceEventType.firstProofCreated:
        if (!_showPassportPage && !_showProofCard && !reduce) {
          return const SizedBox(height: 200);
        }
        if (!_showPassportPage || reduce && !_stampVisible) {
          return _fadeIn(
            visible: _showProofCard || reduce,
            child: ProofRecordCard(
              skillName: ctx.skillName,
              result: ctx.proofResult,
              unit: ctx.proofUnit,
            ),
          );
        }
        return PassportRecordMoment(
          displayName: ctx.displayName.isNotEmpty ? ctx.displayName : 'Athlete',
          proofSummary: ProofRecordCard(
            skillName: ctx.skillName,
            result: ctx.proofResult,
            unit: ctx.proofUnit,
            compact: true,
          ),
          stampSlotVisible: !_stampVisible && !reduce,
          stamp: _stampVisible || reduce
              ? _buildStamp(type, ctx, reduce, witnessed: false)
              : null,
          width: _spreadWidth,
          reduceMotion: reduce,
        );
      case ExperienceEventType.coachVerified:
        return PassportRecordMoment(
          displayName: ctx.displayName.isNotEmpty ? ctx.displayName : 'Athlete',
          proofSummary: ProofRecordCard(
            skillName: ctx.skillName,
            result: ctx.proofResult,
            unit: ctx.proofUnit,
            compact: true,
          ),
          stamp: _stampVisible || reduce
              ? _buildStamp(
                  type,
                  ctx,
                  reduce,
                  witnessed: _witnessVisible || reduce,
                )
              : null,
          width: _spreadWidth,
          reduceMotion: reduce,
        );
      default:
        return const SizedBox(height: 48);
    }
  }

  Widget _buildCopy(
    bool guideOn,
    ExperienceResolvedMessages messages,
    ExperienceContext ctx,
    ExperienceEventType type,
  ) {
    if (widget.playback.simulateSourceMissing &&
        type != ExperienceEventType.onboardingCompleted) {
      return Text(
        'This moment could not load its source record. You can continue safely.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ExperienceTokens.recordInk,
            ),
      );
    }

    if (guideOn) {
      return RegistrarPanel(
        primary: messages.primary,
        secondary: messages.secondary,
      );
    }

    final essential = switch (type) {
      ExperienceEventType.onboardingCompleted => ctx.displayName.isNotEmpty
          ? ctx.displayName
          : 'Your physical identity record',
      ExperienceEventType.firstProofCreated => ctx.formattedResult.isNotEmpty
          ? 'First proof: ${ctx.formattedResult}'
          : 'Your first proof',
      ExperienceEventType.coachVerified => ctx.coachName.isNotEmpty
          ? '${ctx.coachName} verified this.'
          : 'Your coach verified this.',
      _ => messages.primary,
    };

    return Text(
      essential,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ExperienceTokens.identityInk,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildStamp(
    ExperienceEventType type,
    ExperienceContext ctx,
    bool reduce, {
    required bool witnessed,
  }) {
    final showWitness = type == ExperienceEventType.coachVerified && witnessed;
    final def = showWitness
        ? PassportStampDefinition.coachWitnessed
        : PassportStampDefinition.selfReportedCircle;
    final date = showWitness
        ? (ctx.verificationDate ?? ctx.proofDate)
        : (ctx.proofDate ?? ctx.verificationDate);

    final instance = PassportStampInstance(
      definition: def,
      label: ctx.formattedResult.isNotEmpty ? ctx.formattedResult : 'Proof',
      descriptor: ctx.skillName,
      dateLabel: date != null ? _dateFormat.format(date) : '',
      witnessLabel: showWitness
          ? (ctx.coachInitials.isNotEmpty
              ? ctx.coachInitials
              : (ctx.coachName.isNotEmpty
                  ? _initials(ctx.coachName)
                  : 'CV'))
          : '',
      semanticsLabel: _stampSemantics(ctx, showWitness),
    );

    final stamp = passportPageStamp(
      instance: instance,
      animateIn: !reduce && (_stampVisible || _witnessVisible),
      reduceMotion: reduce,
      size: 88,
    );

    if (widget.playback.showSemanticLabels) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          stamp,
          const SizedBox(height: 4),
          Text(
            instance.accessibleLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return stamp;
  }

  String _stampSemantics(ExperienceContext ctx, bool witnessed) {
    final parts = <String>[
      if (ctx.skillName.isNotEmpty) ctx.skillName,
      if (ctx.formattedResult.isNotEmpty) ctx.formattedResult,
      if (ctx.proofDate != null) _dateFormat.format(ctx.proofDate!),
      if (witnessed && ctx.coachName.isNotEmpty)
        'Verified by ${ctx.coachName}',
    ];
    return parts.join('. ');
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length.clamp(0, 2)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
