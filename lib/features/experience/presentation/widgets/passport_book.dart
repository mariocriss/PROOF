import 'package:flutter/material.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';
import 'package:proof/features/experience/domain/passport_stamp.dart';
import 'package:proof/features/experience/presentation/widgets/passport_stamp_widget.dart';

/// Closed passport cover — portrait book with spine and embossed mark.
class PassportBookClosed extends StatelessWidget {
  const PassportBookClosed({
    super.key,
    this.displayName = '',
    this.onTap,
    this.width = 220,
  });

  final String displayName;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.38;
    final name = displayName.trim();

    return Semantics(
      label: 'Closed physical identity passport. Tap to open.',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width + 14,
          height: height + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Contact shadow
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ExperienceTokens.passportVolumeShadow,
                  ),
                ),
              ),
              // Spine edge
              Positioned(
                left: 0,
                top: 4,
                child: Container(
                  width: 12,
                  height: height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E342B),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        offset: const Offset(2, 0),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              // Cover
              Positioned(
                left: 8,
                top: 0,
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: ExperienceTokens.passportCover,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ExperienceTokens.passportCover,
                        const Color(0xFF243F34),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EmbossedMark(size: width * 0.22),
                        const Spacer(),
                        Text(
                          'PROOF',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ExperienceTokens.paperBackground
                                    .withValues(alpha: 0.45),
                                letterSpacing: 3,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (name.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: ExperienceTokens.paperBackground
                                      .withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w600,
                                  height: 1.15,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmbossedMark extends StatelessWidget {
  const _EmbossedMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ExperienceTokens.paperBackground.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'P',
        style: TextStyle(
          color: ExperienceTokens.paperBackground.withValues(alpha: 0.35),
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Open two-page spread with identity left and record/stamp right.
class PassportBookSpread extends StatelessWidget {
  const PassportBookSpread({
    super.key,
    required this.displayName,
    this.stamp,
    this.stampSlotVisible = false,
    this.proofSummary,
    this.width,
    this.animateOpen = false,
    this.reduceMotion = false,
  });

  final String displayName;
  final Widget? stamp;
  final bool stampSlotVisible;
  final Widget? proofSummary;
  final double? width;
  final bool animateOpen;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final spreadWidth = width ?? 340;
    final spreadHeight = spreadWidth * 0.62;
    final name = displayName.trim().isEmpty ? 'Your name' : displayName.trim();

    Widget spread = _SpreadBody(
      width: spreadWidth,
      height: spreadHeight,
      name: name,
      stamp: stamp,
      stampSlotVisible: stampSlotVisible,
      proofSummary: proofSummary,
    );

    if (animateOpen && !reduceMotion) {
      spread = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: ExperienceTokens.settleCurve,
        builder: (context, value, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY((1 - value) * -0.08),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: spread,
      );
    }

    return Semantics(
      label: 'Open passport spread for $name',
      child: spread,
    );
  }
}

class _SpreadBody extends StatelessWidget {
  const _SpreadBody({
    required this.width,
    required this.height,
    required this.name,
    this.stamp,
    required this.stampSlotVisible,
    this.proofSummary,
  });

  final double width;
  final double height;
  final String name;
  final Widget? stamp;
  final bool stampSlotVisible;
  final Widget? proofSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: ExperienceTokens.passportVolumeShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(child: _IdentityPage(name: name)),
            Container(width: 2, color: ExperienceTokens.identityInk.withValues(alpha: 0.12)),
            Expanded(
              child: _RecordPage(
                stamp: stamp,
                stampSlotVisible: stampSlotVisible,
                proofSummary: proofSummary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityPage extends StatelessWidget {
  const _IdentityPage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBF9F4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHYSICAL IDENTITY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ExperienceTokens.identityInk.withValues(alpha: 0.45),
                  letterSpacing: 1.2,
                  fontSize: 9,
                ),
          ),
          const Spacer(),
          Text(
            name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ExperienceTokens.identityInk,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            width: 48,
            color: ExperienceTokens.identityInk.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}

class _RecordPage extends StatelessWidget {
  const _RecordPage({
    this.stamp,
    required this.stampSlotVisible,
    this.proofSummary,
  });

  final Widget? stamp;
  final bool stampSlotVisible;
  final Widget? proofSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ExperienceTokens.paperBackground,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECORD',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ExperienceTokens.recordInk.withValues(alpha: 0.45),
                  letterSpacing: 1.2,
                  fontSize: 9,
                ),
          ),
          if (proofSummary != null) ...[
            const SizedBox(height: 8),
            proofSummary!,
          ],
          const Spacer(),
          if (stampSlotVisible || stamp != null)
            Align(
              alignment: Alignment.bottomRight,
              child: stampSlotVisible && stamp == null
                  ? _StampSlot()
                  : stamp ?? const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _StampSlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ExperienceTokens.recordInk.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'STAMP',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ExperienceTokens.recordInk.withValues(alpha: 0.25),
              letterSpacing: 1,
              fontSize: 8,
            ),
      ),
    );
  }
}

/// Convenience wrapper for issuance moment animations.
class PassportBookVisual extends StatelessWidget {
  const PassportBookVisual({
    super.key,
    required this.displayName,
    this.opened = false,
    this.reduceMotion = false,
    this.onTapClosed,
    this.stamp,
    this.stampSlotVisible = false,
    this.proofSummary,
    this.width,
  });

  final String displayName;
  final bool opened;
  final bool reduceMotion;
  final VoidCallback? onTapClosed;
  final Widget? stamp;
  final bool stampSlotVisible;
  final Widget? proofSummary;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final bookWidth = width ?? 220;
    if (!opened) {
      return PassportBookClosed(
        displayName: displayName,
        onTap: onTapClosed,
        width: bookWidth,
      );
    }
    return PassportBookSpread(
      displayName: displayName,
      stamp: stamp,
      stampSlotVisible: stampSlotVisible,
      proofSummary: proofSummary,
      width: (bookWidth * 1.45).clamp(300, 380),
      animateOpen: !reduceMotion,
      reduceMotion: reduceMotion,
    );
  }
}

/// Record page with embedded stamp for first proof / coach verify.
class PassportRecordMoment extends StatelessWidget {
  const PassportRecordMoment({
    super.key,
    required this.displayName,
    required this.proofSummary,
    this.stamp,
    this.stampSlotVisible = false,
    this.width,
    this.reduceMotion = false,
  });

  final String displayName;
  final Widget proofSummary;
  final Widget? stamp;
  final bool stampSlotVisible;
  final double? width;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return PassportBookSpread(
      displayName: displayName,
      proofSummary: proofSummary,
      stamp: stamp,
      stampSlotVisible: stampSlotVisible,
      width: width ?? 340,
      animateOpen: false,
      reduceMotion: reduceMotion,
    );
  }
}

/// Builds a stamp widget sized for passport record page.
Widget passportPageStamp({
  required PassportStampInstance instance,
  bool animateIn = false,
  bool reduceMotion = false,
  double size = 88,
}) {
  return PassportStampWidget(
    instance: instance,
    size: size,
    animateIn: animateIn,
    reduceMotion: reduceMotion,
  );
}
