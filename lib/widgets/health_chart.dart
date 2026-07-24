import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/health_record.dart';

/// A line-chart visualization for health records (§8), drawn with a
/// hand-rolled [CustomPainter] so the project stays free of charting
/// dependencies. Supports two modes:
///
/// - **Single line** for height/weight (one value per date).
/// - **Dual line** for blood pressure (systolic solid + diastolic
///   dashed, sharing the same Y axis).
///
/// Records are filtered by [metricType] internally — pass the full
/// list and the chart keeps only matching entries. Records that
/// arrive from §8.2 / §8.3 are already sorted DESC by date; we
/// re-sort ASC here for left-to-right chronological plotting.
///
/// Visual palette matches the rest of the app's warm/wood aesthetic:
/// `AppColors.primary` for the main line, `AppColors.sage` for the
/// optional second line, soft gradient fill below the curve.
class HealthChart extends StatelessWidget {
  final List<HealthRecord> records;
  final HealthMetricType metricType;

  /// Total widget height (chart canvas + stats summary row). The
  /// chart canvas reserves 180px; the stats row below consumes the
  /// rest at the bottom.
  final double height;

  const HealthChart({
    super.key,
    required this.records,
    required this.metricType,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filterAndSort(records, metricType);

    if (filtered.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.healthChartEmpty,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.inkFaded,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (filtered.length == 1) {
      return SizedBox(
        height: height,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.healthChartSinglePoint,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.inkFaded,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomPaint(
              painter: _HealthChartPainter(
                records: filtered,
                metricType: metricType,
                zoneLabels: metricType == HealthMetricType.bloodPressure
                    ? {
                        'normal': l10n.healthChartBpZoneNormal,
                        'elevated': l10n.healthChartBpZoneElevated,
                        'high': l10n.healthChartBpZoneHigh,
                        'diastolicCap': l10n.healthChartBpDiastolicCap,
                      }
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _StatsSummary(
            records: filtered,
            metricType: metricType,
          ),
        ],
      ),
    );
  }

  static List<HealthRecord> _filterAndSort(
    List<HealthRecord> records,
    HealthMetricType metricType,
  ) {
    final list = records
        .where((r) => r.metricType == metricType)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return list;
  }
}

class _StatsSummary extends StatelessWidget {
  final List<HealthRecord> records;
  final HealthMetricType metricType;

  const _StatsSummary({required this.records, required this.metricType});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = _computeStats(records, metricType);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatCell(
          label: l10n.healthChartLatest,
          value: _formatValue(metricType, stats.latest),
          color: AppColors.primary,
        ),
        _StatCell(
          label: l10n.healthChartMin,
          value: _formatValue(metricType, stats.minRecord),
          color: AppColors.inkFaded,
        ),
        _StatCell(
          label: l10n.healthChartMax,
          value: _formatValue(metricType, stats.maxRecord),
          color: AppColors.inkFaded,
        ),
        _StatCell(
          label: l10n.healthChartAverage,
          value: _formatAvg(metricType, stats.average),
          color: AppColors.inkFaded,
        ),
      ],
    );
  }

  static String _formatValue(HealthMetricType t, HealthRecord r) {
    switch (t) {
      case HealthMetricType.height:
        return '${r.value.toStringAsFixed(1)} cm';
      case HealthMetricType.weight:
        return '${r.value.toStringAsFixed(1)} kg';
      case HealthMetricType.bloodPressure:
        if (r.valueSecondary != null) {
          return '${r.value.toInt()}/${r.valueSecondary!.toInt()}';
        }
        return '${r.value.toInt()} mmHg';
    }
  }

  static String _formatAvg(HealthMetricType t, double avg) {
    switch (t) {
      case HealthMetricType.height:
        return '${avg.toStringAsFixed(1)} cm';
      case HealthMetricType.weight:
        return '${avg.toStringAsFixed(1)} kg';
      case HealthMetricType.bloodPressure:
        return '${avg.toStringAsFixed(0)} mmHg';
    }
  }

  /// Computes min / max / latest / average for the displayed metric.
  /// For blood pressure, both systolic and diastolic are tracked
  /// separately (the min/max pick the more extreme sample, not a
  /// mix of the two).
  static _Stats _computeStats(
    List<HealthRecord> records,
    HealthMetricType t,
  ) {
    final sorted = List<HealthRecord>.from(records)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    double minVal = double.infinity;
    double maxVal = -double.infinity;
    HealthRecord minRec = records.first;
    HealthRecord maxRec = records.first;
    double sum = 0;
    int count = 0;

    for (final r in records) {
      final v = r.value;
      sum += v;
      count++;
      if (v < minVal) {
        minVal = v;
        minRec = r;
      }
      if (v > maxVal) {
        maxVal = v;
        maxRec = r;
      }
      if (t == HealthMetricType.bloodPressure && r.valueSecondary != null) {
        // For BP, treat systolic + diastolic as a single combined
        // metric; min/max pick whichever extreme any sample reached.
        final d = r.valueSecondary!;
        if (d < minVal) {
          minVal = d;
          minRec = r;
        }
        if (d > maxVal) {
          maxVal = d;
          maxRec = r;
        }
      }
    }

    return _Stats(
      latest: sorted.first,
      minRecord: minRec,
      maxRecord: maxRec,
      average: count == 0 ? 0 : sum / count,
    );
  }
}

class _Stats {
  final HealthRecord latest;
  final HealthRecord minRecord;
  final HealthRecord maxRecord;
  final double average;

  const _Stats({
    required this.latest,
    required this.minRecord,
    required this.maxRecord,
    required this.average,
  });
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.inkFaded,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _HealthChartPainter extends CustomPainter {
  final List<HealthRecord> records;
  final HealthMetricType metricType;

  /// Localized zone labels for the BP chart. `null` for non-BP
  /// metrics — zone rendering is BP-only. The painter itself can't
  /// reach `AppLocalizations` (it's drawn outside any BuildContext),
  /// so the parent widget pulls the strings and hands them in.
  final Map<String, String>? zoneLabels;

  _HealthChartPainter({
    required this.records,
    required this.metricType,
    this.zoneLabels,
  });

  // Layout constants — kept conservative so a single chart works on
  // both a wide web canvas and a narrow phone screen.
  static const double _leftAxisWidth = 36;
  static const double _rightPadding = 8;
  static const double _topPadding = 12;
  static const double _bottomAxisHeight = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(
      _leftAxisWidth,
      _topPadding,
      size.width - _leftAxisWidth - _rightPadding,
      size.height - _topPadding - _bottomAxisHeight,
    );

    // BP zones are drawn FIRST so the grid, axes, and line all paint
    // on top of them — the bands are background context, not data.
    if (metricType == HealthMetricType.bloodPressure) {
      _drawBpZones(canvas, chartRect);
    }
    _drawGrid(canvas, chartRect);
    _drawAxesLabels(canvas, chartRect, size);
    if (metricType == HealthMetricType.bloodPressure) {
      _drawDiastolicThreshold(canvas, chartRect);
    }

    if (metricType == HealthMetricType.bloodPressure) {
      _drawDualLine(canvas, chartRect);
    } else {
      _drawSingleLine(canvas, chartRect);
    }
  }

  void _drawGrid(Canvas canvas, Rect chartRect) {
    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 0.6;

    // 4 horizontal grid lines (5 segments → 5/4 of value range per line).
    for (var i = 0; i <= 4; i++) {
      final y = chartRect.top +
          (chartRect.height * i / 4);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }
  }

  void _drawAxesLabels(Canvas canvas, Rect chartRect, Size size) {
    final valueRange = _computeValueRange();

    // Y-axis labels (min, max on the side, mid optional).
    void drawYLabel(double value, double y) {
      final tp = TextPainter(
        text: TextSpan(
          text: _formatAxisValue(value),
          style: TextStyle(
            fontSize: 10,
            color: AppColors.inkFaded,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _leftAxisWidth - 4);
      tp.paint(
        canvas,
        Offset(
          chartRect.left - tp.width - 2,
          y - tp.height / 2,
        ),
      );
    }

    drawYLabel(valueRange.max, chartRect.top);
    drawYLabel(valueRange.min, chartRect.bottom);

    // X-axis: first and last date.
    void drawXLabel(String text, double x, {bool center = false}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.inkFaded,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      tp.paint(
        canvas,
        Offset(
          center
              ? x - tp.width / 2
              : x - (center ? 0 : tp.width),
          chartRect.bottom + 4,
        ),
      );
    }

    if (records.length >= 2) {
      drawXLabel(_shortDate(records.first.recordedAt), chartRect.left);
      drawXLabel(
        _shortDate(records.last.recordedAt),
        chartRect.right,
      );
    }
  }

  _ValueRange _computeValueRange() {
    double minV = double.infinity;
    double maxV = -double.infinity;

    for (final r in records) {
      if (r.value < minV) minV = r.value;
      if (r.value > maxV) maxV = r.value;
      if (metricType == HealthMetricType.bloodPressure &&
          r.valueSecondary != null) {
        if (r.valueSecondary! < minV) minV = r.valueSecondary!;
        if (r.valueSecondary! > maxV) maxV = r.valueSecondary!;
      }
    }

    // For BP, the visible range always covers the full clinical
    // spectrum (50 → 160) so the Normal / Elevated / High zone
    // bands stay readable even when a user is consistently
    // hypertensive or consistently normal. Real readings outside
    // this bracket (e.g. a hypertensive crisis above 160) still
    // appear correctly because we union with the data range
    // below rather than clamping the data itself.
    if (metricType == HealthMetricType.bloodPressure) {
      const minRangeLow = 50.0;
      const minRangeHigh = 160.0;
      if (minV == double.infinity) {
        // No data — pure range.
        return _ValueRange(minRangeLow, minRangeHigh);
      }
      if (minV > minRangeLow) minV = minRangeLow;
      if (maxV < minRangeHigh) maxV = minRangeHigh;
      // Skip the 8% padding for BP — the canonical range already
      // gives breathing room and extra padding would push the
      // zone bands off-screen.
      return _ValueRange(minV, maxV);
    }

    // Pad 8% on each side so the line never touches the edges —
    // visual breathing room, also helps when all values are equal.
    if (minV == maxV) {
      // All samples the same — pad ±5% of the value (or 1 unit if 0).
      final pad = minV == 0 ? 1.0 : (minV.abs() * 0.05).clamp(0.5, 5.0);
      return _ValueRange(minV - pad, maxV + pad);
    }
    final range = maxV - minV;
    final pad = range * 0.08;
    return _ValueRange(minV - pad, maxV + pad);
  }

  /// Draws the colored Normal / Elevated / High zone bands behind
  /// the BP chart. Bands are clipped to the visible chart rect so
  /// a band that extends beyond [50, 160] (the canonical range)
  /// still terminates at the chart edge instead of bleeding out.
  ///
  /// Thresholds follow the standard adult classification (AHA
  /// 2017 + Chinese Hypertension League equivalent):
  ///   - 60 → 120 : Normal (covers both normal diastolic 60-80
  ///                and normal systolic 90-120 — simplified into a
  ///                single contiguous band for readability)
  ///   - 120 → 140: Elevated / Hypertension Stage 1
  ///   - 140 → ∞  : Hypertension Stage 2+
  void _drawBpZones(Canvas canvas, Rect chartRect) {
    final range = _computeValueRange();

    final bands = <_BpBand>[
      _BpBand(60, 120, AppColors.success, zoneLabels?['normal']),
      _BpBand(120, 140, AppColors.warning, zoneLabels?['elevated']),
      _BpBand(140, range.max + 1, AppColors.danger, zoneLabels?['high']),
    ];

    for (final band in bands) {
      final yTop = _yForValue(band.maxValue, range, chartRect);
      final yBottom = _yForValue(band.minValue, range, chartRect);
      // Clip to chart bounds — out-of-range bands shouldn't draw.
      final topClamped = yTop.clamp(chartRect.top, chartRect.bottom);
      final bottomClamped = yBottom.clamp(chartRect.top, chartRect.bottom);
      if (bottomClamped <= topClamped) continue;

      final rect = Rect.fromLTRB(
        chartRect.left,
        topClamped,
        chartRect.right,
        bottomClamped,
      );
      final paint = Paint()..color = band.color.withValues(alpha: 0.18);
      canvas.drawRect(rect, paint);

      // Right-edge label, vertically centered in the band, only
      // when the band is wide enough to hold the text (~12px tall).
      final label = band.label;
      if (label != null && (bottomClamped - topClamped) >= 14) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: band.color.withValues(alpha: 0.85),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: chartRect.width);
        // Anchor the label to the right edge of the band with a
        // small inner padding. Right-to-left languages would flip
        // this, but our 6 locales are all LTR.
        final tx = chartRect.right - tp.width - 4;
        final ty = (topClamped + bottomClamped) / 2 - tp.height / 2;
        tp.paint(canvas, Offset(tx, ty));
      }
    }
  }

  /// Dashed reference line at y=80 (the upper bound of normal
  /// diastolic BP) — the boundary every well-controlled BP
  /// reading should keep diastolic under. Has its own localized
  /// label so users remember what the dashed line means.
  void _drawDiastolicThreshold(Canvas canvas, Rect chartRect) {
    const threshold = 80.0;
    final range = _computeValueRange();
    if (threshold < range.min || threshold > range.max) return;

    final y = _yForValue(threshold, range, chartRect);
    final paint = Paint()
      ..color = AppColors.inkFaded.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    _drawHorizontalDashed(canvas, chartRect.left, chartRect.right, y, paint);

    final label = zoneLabels?['diastolicCap'];
    if (label != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 9,
            fontStyle: FontStyle.italic,
            color: AppColors.inkFaded.withValues(alpha: 0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: chartRect.width);
      // Place label just above the dashed line so it doesn't
      // collide with the y=80 axis tick on the left.
      tp.paint(canvas, Offset(chartRect.left + 4, y - tp.height - 2));
    }
  }

  void _drawHorizontalDashed(
    Canvas canvas,
    double x1,
    double x2,
    double y,
    Paint paint,
  ) {
    const dashLen = 4.0;
    const gapLen = 3.0;
    var x = x1;
    while (x < x2) {
      final segEnd = (x + dashLen).clamp(x1, x2);
      canvas.drawLine(Offset(x, y), Offset(segEnd.toDouble(), y), paint);
      x += dashLen + gapLen;
    }
  }

  double _yForValue(double value, _ValueRange range, Rect chartRect) {
    final t = (value - range.min) / (range.max - range.min);
    return chartRect.bottom - t * chartRect.height;
  }

  double _xForIndex(int i, Rect chartRect) {
    if (records.length == 1) return chartRect.center.dx;
    return chartRect.left +
        (i / (records.length - 1)) * chartRect.width;
  }

  void _drawSingleLine(Canvas canvas, Rect chartRect) {
    final range = _computeValueRange();
    final points = <Offset>[];
    for (var i = 0; i < records.length; i++) {
      points.add(
        Offset(
          _xForIndex(i, chartRect),
          _yForValue(records[i].value, range, chartRect),
        ),
      );
    }

    _drawLineWithFill(canvas, points, chartRect, AppColors.primary);
    _drawDataPoints(canvas, points, AppColors.primary);
  }

  void _drawDualLine(Canvas canvas, Rect chartRect) {
    final range = _computeValueRange();

    // Systolic (solid).
    final systolic = <Offset>[];
    for (var i = 0; i < records.length; i++) {
      systolic.add(
        Offset(
          _xForIndex(i, chartRect),
          _yForValue(records[i].value, range, chartRect),
        ),
      );
    }
    _drawLineWithFill(canvas, systolic, chartRect, AppColors.primary);
    _drawDataPoints(canvas, systolic, AppColors.primary);

    // Diastolic (dashed).
    final diastolic = <Offset>[];
    for (var i = 0; i < records.length; i++) {
      final v = records[i].valueSecondary;
      if (v == null) continue;
      diastolic.add(
        Offset(
          _xForIndex(i, chartRect),
          _yForValue(v, range, chartRect),
        ),
      );
    }
    if (diastolic.length >= 2) {
      _drawDashedLine(canvas, diastolic, AppColors.sage);
    } else if (diastolic.length == 1) {
      _drawDataPoints(canvas, diastolic, AppColors.sage);
    }
  }

  void _drawLineWithFill(
    Canvas canvas,
    List<Offset> points,
    Rect chartRect,
    Color color,
  ) {
    if (points.isEmpty) return;

    final linePath = _buildSmoothPath(points);
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();

    // Soft gradient fill below the line.
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    // The line itself.
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
  }

  void _drawDashedLine(Canvas canvas, List<Offset> points, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      _drawDashedSegment(canvas, points[i], points[i + 1], paint);
    }
  }

  void _drawDashedSegment(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var traveled = 0.0;
    while (traveled < total) {
      final segEnd = (traveled + dashLen).clamp(0.0, total);
      canvas.drawLine(
        a + dir * traveled,
        a + dir * segEnd.toDouble(),
        paint,
      );
      traveled += dashLen + gapLen;
    }
  }

  void _drawDataPoints(Canvas canvas, List<Offset> points, Color color) {
    final fillPaint = Paint()..color = color;
    final strokePaint = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 3.4, fillPaint);
      canvas.drawCircle(p, 3.4, strokePaint);
    }
  }

  /// Builds a smoothed path through [points] using a simple
  /// quadratic-bezier-midpoint algorithm: each segment connects two
  /// midpoints with a quadratic curve whose control point is the
  /// shared original point. Smoother than straight lines without
  /// requiring Catmull-Rom conversion.
  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      if (i == 1) {
        path.lineTo(mid.dx, mid.dy);
      } else {
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
    }
    // Final segment: bezier from the last midpoint to the actual
    // last point (otherwise the last sample's dot is "off the line").
    final lastMid = Offset(
      (points[points.length - 2].dx + points.last.dx) / 2,
      (points[points.length - 2].dy + points.last.dy) / 2,
    );
    path.quadraticBezierTo(
      points[points.length - 2].dx,
      points[points.length - 2].dy,
      lastMid.dx,
      lastMid.dy,
    );
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  String _formatAxisValue(double v) {
    if (metricType == HealthMetricType.bloodPressure) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1);
  }

  String _shortDate(String yyyyMmDd) {
    // Convert "2026-07-14" → "7/14" (Latin) or "7/14" too — the
    // compact axis label just needs to fit in ~40px.
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return yyyyMmDd;
    final m = int.tryParse(parts[1]) ?? 1;
    final d = int.tryParse(parts[2]) ?? 1;
    return '$m/$d';
  }

  @override
  bool shouldRepaint(covariant _HealthChartPainter old) {
    return old.records != records || old.metricType != metricType;
  }
}

class _ValueRange {
  final double min;
  final double max;
  const _ValueRange(this.min, this.max);
}

/// One clinical zone band drawn behind the BP chart. `maxValue`
/// exclusive at the top (e.g. `60 → 120`); for the topmost band
/// use a value safely above `range.max + 1` so the clipping still
/// draws it up to the chart top edge.
class _BpBand {
  final double minValue;
  final double maxValue;
  final Color color;
  final String? label;

  const _BpBand(this.minValue, this.maxValue, this.color, this.label);
}