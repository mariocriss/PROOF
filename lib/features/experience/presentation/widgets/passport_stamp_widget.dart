import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:proof/features/experience/domain/experience_tokens.dart';
import 'package:proof/features/experience/domain/passport_stamp.dart';

/// Native Flutter stamp primitive — trust via ink/emboss, not rarity color.
class PassportStampWidget extends StatelessWidget {
  const PassportStampWidget({
    super.key,
    required this.instance,
    this.size = 120,
    this.animateIn = false,
    this.reduceMotion = false,
  });

  final PassportStampInstance instance;
  final double size;
  final bool animateIn;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final stamp = _StampVisual(instance: instance, size: size);
    final labeled = Semantics(
      label: instance.accessibleLabel,
      child: stamp,
    );
    if (!animateIn || reduceMotion) return labeled;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: ExperienceTokens.breath,
      curve: ExperienceTokens.settleCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: ((value - 0.85) / 0.15).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: Transform.scale(scale: value, child: child),
          ),
        );
      },
      child: labeled,
    );
  }
}

class _StampVisual extends StatelessWidget {
  const _StampVisual({required this.instance, required this.size});

  final PassportStampInstance instance;
  final double size;

  @override
  Widget build(BuildContext context) {
    final def = instance.definition;
    return CustomPaint(
      size: Size(size, size),
      painter: _StampPainter(
        ink: def.inkColor,
        embossed: def.embossed,
        showWitnessBar: def.showWitnessBar,
        shape: def.shape,
        label: instance.label,
        dateLabel: instance.dateLabel,
        descriptor: instance.descriptor,
        witnessLabel: instance.witnessLabel,
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  _StampPainter({
    required this.ink,
    required this.embossed,
    required this.showWitnessBar,
    required this.shape,
    required this.label,
    required this.dateLabel,
    required this.descriptor,
    required this.witnessLabel,
  });

  final Color ink;
  final bool embossed;
  final bool showWitnessBar;
  final PassportStampShape shape;
  final String label;
  final String dateLabel;
  final String descriptor;
  final String witnessLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 4;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = embossed ? 2.4 : 1.6;

    if (embossed) {
      final shadow = Paint()
        ..color = ink.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(center.translate(0, 1.5), radius * 0.92, shadow);
      final fill = Paint()
        ..color = ink.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.92, fill);
    }

    switch (shape) {
      case PassportStampShape.circle:
        canvas.drawCircle(center, radius, stroke);
      case PassportStampShape.circleNotched:
        canvas.drawCircle(center, radius, stroke);
        canvas.drawLine(
          Offset(center.dx + radius * 0.7, center.dy - radius * 0.7),
          Offset(center.dx + radius * 0.95, center.dy - radius * 0.95),
          stroke,
        );
      case PassportStampShape.wideRectangle:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: size.width * 0.9,
            height: size.height * 0.55,
          ),
          const Radius.circular(ExperienceTokens.cornerRadiusStamp),
        );
        canvas.drawRRect(rect, stroke);
      case PassportStampShape.hexagon:
        canvas.drawPath(_hexPath(center, radius), stroke);
      case PassportStampShape.perforatedRectangle:
        final rect = Rect.fromCenter(
          center: center,
          width: size.width * 0.85,
          height: size.height * 0.6,
        );
        _drawDashedRect(canvas, rect, stroke);
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    );

    void drawCentered(String text, double y, double fontSize, FontWeight w) {
      if (text.isEmpty) return;
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: ink,
          fontSize: fontSize,
          fontWeight: w,
          letterSpacing: 0.4,
        ),
      );
      textPainter.layout(maxWidth: size.width * 0.72);
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, y),
      );
    }

    drawCentered(label, center.dy - 14, size.width * 0.09, FontWeight.w700);
    drawCentered(
      descriptor,
      center.dy + 4,
      size.width * 0.07,
      FontWeight.w500,
    );
    drawCentered(
      dateLabel,
      center.dy + radius * 0.55,
      size.width * 0.055,
      FontWeight.w400,
    );

    if (showWitnessBar && witnessLabel.isNotEmpty) {
      final barY = center.dy + radius * 0.78;
      final barPaint = Paint()
        ..color = ink
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(center.dx - radius * 0.55, barY),
        Offset(center.dx + radius * 0.55, barY),
        barPaint,
      );
      drawCentered(witnessLabel, barY + 4, size.width * 0.05, FontWeight.w600);
    }
  }

  Path _hexPath(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final p = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;
    void dashLine(Offset a, Offset b) {
      final total = (b - a).distance;
      if (total == 0) return;
      final dir = (b - a) / total;
      var drawn = 0.0;
      while (drawn < total) {
        final endDist = math.min(drawn + dash, total);
        canvas.drawLine(a + dir * drawn, a + dir * endDist, paint);
        drawn += dash + gap;
      }
    }

    dashLine(rect.topLeft, rect.topRight);
    dashLine(rect.topRight, rect.bottomRight);
    dashLine(rect.bottomRight, rect.bottomLeft);
    dashLine(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(covariant _StampPainter oldDelegate) {
    return oldDelegate.ink != ink ||
        oldDelegate.embossed != embossed ||
        oldDelegate.label != label ||
        oldDelegate.witnessLabel != witnessLabel;
  }
}
