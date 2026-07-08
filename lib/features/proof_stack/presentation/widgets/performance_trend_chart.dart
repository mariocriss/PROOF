import 'package:flutter/material.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/proof_stack/domain/performance_chart_data.dart';

class PerformanceTrendSection extends StatelessWidget {
  const PerformanceTrendSection({
    super.key,
    required this.chart,
  });

  final PerformanceChartView chart;

  @override
  Widget build(BuildContext context) {
    if (!chart.isUnlocked) {
      return _PerformanceTrendLocked(count: chart.plottableCount);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PerformanceTrendChart(
          points: chart.points,
          trend: chart.trend!,
        ),
      ],
    );
  }
}

class _PerformanceTrendLocked extends StatelessWidget {
  const _PerformanceTrendLocked({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final remaining =
        (PerformanceChartView.defaultUnlockThreshold - count).clamp(0, 10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.show_chart_outlined,
            size: 32,
            color: AppColors.inkMuted.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Continue documenting to see a trend in your performance.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.45,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '$count of ${PerformanceChartView.defaultUnlockThreshold} proofs',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$remaining more to unlock',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accent,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class PerformanceTrendChart extends StatelessWidget {
  const PerformanceTrendChart({
    super.key,
    required this.points,
    required this.trend,
  });

  final List<PerformanceChartPoint> points;
  final PerformanceTrendLine trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(
        painter: _PerformanceTrendPainter(
          points: points,
          trend: trend,
          accentColor: AppColors.accent,
          gridColor: AppColors.border,
          trendColor: AppColors.confidenceEstablished,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PerformanceTrendPainter extends CustomPainter {
  _PerformanceTrendPainter({
    required this.points,
    required this.trend,
    required this.accentColor,
    required this.gridColor,
    required this.trendColor,
  });

  final List<PerformanceChartPoint> points;
  final PerformanceTrendLine trend;
  final Color accentColor;
  final Color gridColor;
  final Color trendColor;

  static const _leftPad = 36.0;
  static const _bottomPad = 28.0;
  static const _topPad = 12.0;
  static const _rightPad = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartWidth = size.width - _leftPad - _rightPad;
    final chartHeight = size.height - _topPad - _bottomPad;

    final values = points.map((p) => p.value).toList();
    final trendValues = List.generate(
      points.length,
      (i) => trend.valueAtIndex(i),
    );

    var minY = [...values, ...trendValues].reduce((a, b) => a < b ? a : b);
    var maxY = [...values, ...trendValues].reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    } else {
      final padding = (maxY - minY) * 0.12;
      minY -= padding;
      maxY += padding;
    }

    double xForIndex(int index) {
      if (points.length == 1) return _leftPad + chartWidth / 2;
      return _leftPad + (index / (points.length - 1)) * chartWidth;
    }

    double yForValue(double value) {
      final ratio = (value - minY) / (maxY - minY);
      return _topPad + chartHeight - (ratio * chartHeight);
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = _topPad + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(size.width - _rightPad, y),
        gridPaint,
      );
    }

    final labelStyle = TextStyle(
      color: AppColors.inkMuted,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    for (var i = 0; i <= 3; i++) {
      final value = maxY - ((maxY - minY) / 3) * i;
      final text = _formatAxisValue(value);
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(0, _topPad + (chartHeight / 3) * i - tp.height / 2),
      );
    }

    if (points.length >= 2) {
      final firstDate = points.first.date;
      final lastDate = points.last.date;
      for (final entry in [
        (0, firstDate),
        if (points.length > 2) (points.length ~/ 2, points[points.length ~/ 2].date),
        (points.length - 1, lastDate),
      ]) {
        final tp = TextPainter(
          text: TextSpan(
            text: ProofDateUtils.formatDate(entry.$2),
            style: labelStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: chartWidth / 2);
        tp.paint(
          canvas,
          Offset(
            xForIndex(entry.$1) - tp.width / 2,
            size.height - _bottomPad + 6,
          ),
        );
      }
    }

    final trendPath = Path();
    for (var i = 0; i < points.length; i++) {
      final point = Offset(xForIndex(i), yForValue(trend.valueAtIndex(i)));
      if (i == 0) {
        trendPath.moveTo(point.dx, point.dy);
      } else {
        trendPath.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      trendPath,
      Paint()
        ..color = trendColor.withValues(alpha: 0.85)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    final dataPath = Path();
    for (var i = 0; i < points.length; i++) {
      final point = Offset(xForIndex(i), yForValue(points[i].value));
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = accentColor.withValues(alpha: 0.25)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    final dotPaint = Paint()..color = accentColor;
    for (var i = 0; i < points.length; i++) {
      final point = Offset(xForIndex(i), yForValue(points[i].value));
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = accentColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  String _formatAxisValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _PerformanceTrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.trend != trend;
  }
}
