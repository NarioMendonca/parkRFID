import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';


class AnimatedSuccessCheck extends StatefulWidget {
  const AnimatedSuccessCheck({
    super.key,
    this.size = 112,
    this.color = AppTheme.success,
    this.onCompleted,
  });


  final double size;
  final Color color;
  final VoidCallback? onCompleted;

  @override
  State<AnimatedSuccessCheck> createState() => _AnimatedSuccessCheckState();
}

class _AnimatedSuccessCheckState extends State<AnimatedSuccessCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _circle = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.38, curve: Curves.easeOutBack),
  );
  late final Animation<double> _ripple = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.12, 0.62, curve: Curves.easeOut),
  );
  late final Animation<double> _check = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.32, 0.68, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _burst = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
  );

  bool _vibrou = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!_vibrou && _controller.value >= 0.68) {
        _vibrou = true;
        HapticFeedback.mediumImpact();
      }
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted?.call();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.size * 2;
    return Semantics(
      label: 'Concluído com sucesso',
      child: RepaintBoundary(
        child: SizedBox(
          width: area,
          height: area,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _SuccessPainter(
                color: widget.color,
                radius: widget.size / 2,
                circle: _circle.value,
                ripple: _ripple.value,
                check: _check.value,
                burst: _burst.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  _SuccessPainter({
    required this.color,
    required this.radius,
    required this.circle,
    required this.ripple,
    required this.check,
    required this.burst,
  });

  final Color color;
  final double radius;
  final double circle;
  final double ripple;
  final double check;
  final double burst;

  static const _particleColors = [AppTheme.accent, AppTheme.primary, AppTheme.success, AppTheme.skyBlue];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);


    if (ripple > 0 && ripple < 1) {
      canvas.drawCircle(
        center,
        radius * (1 + 0.65 * ripple),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.08 * (1 - ripple)
          ..color = color.withValues(alpha: 0.45 * (1 - ripple)),
      );
    }


    if (burst > 0 && burst < 1) {
      const count = 12;
      for (var i = 0; i < count; i++) {
        final angle = (i / count) * 2 * math.pi + (i.isEven ? 0.0 : 0.18);
        final distance = radius * (1.12 + (i.isEven ? 0.62 : 0.45) * burst);
        final dotRadius = radius * (i.isEven ? 0.07 : 0.05) * (1 - burst * 0.7);
        final offset = center + Offset(math.cos(angle), math.sin(angle)) * distance;
        canvas.drawCircle(
          offset,
          dotRadius,
          Paint()..color = _particleColors[i % _particleColors.length].withValues(alpha: 1 - burst),
        );
      }
    }


    final r = radius * circle.clamp(0.0, 1.2);
    if (r > 0) {
      canvas.drawCircle(
        center + Offset(0, radius * 0.08),
        r,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18),
      );
      canvas.drawCircle(center, r, Paint()..color = color);
    }


    if (check > 0) {
      final path = Path()
        ..moveTo(center.dx - radius * 0.40, center.dy + radius * 0.02)
        ..lineTo(center.dx - radius * 0.12, center.dy + radius * 0.30)
        ..lineTo(center.dx + radius * 0.44, center.dy - radius * 0.28);

      final drawn = Path();
      final metrics = path.computeMetrics().toList();
      final total = metrics.fold<double>(0, (s, PathMetric m) => s + m.length);
      var remaining = total * check;
      for (final m in metrics) {
        if (remaining <= 0) break;
        drawn.addPath(m.extractPath(0, math.min(remaining, m.length)), Offset.zero);
        remaining -= m.length;
      }

      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.15
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessPainter old) =>
      old.circle != circle || old.ripple != ripple || old.check != check || old.burst != burst || old.color != color;
}
