import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/clean_item.dart';

class StorageRingWidget extends StatefulWidget {
  final StorageInfo storageInfo;
  const StorageRingWidget({super.key, required this.storageInfo});

  @override
  State<StorageRingWidget> createState() => _StorageRingWidgetState();
}

class _StorageRingWidgetState extends State<StorageRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _RingPainter(
            usedPercent: widget.storageInfo.usedPercent * _animation.value,
          ),
          child: SizedBox(
            width: 220,
            height: 220,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(widget.storageInfo.usedPercent * _animation.value * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'использовано',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.storageInfo.formattedFree} свободно',
                      style: const TextStyle(
                        color: AppTheme.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double usedPercent;
  _RingPainter({required this.usedPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 16.0;

    // Background ring
    final bgPaint =
        Paint()
          ..color = AppTheme.bgSurface
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Used ring with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: [AppTheme.accentCyan, AppTheme.accentPurple, AppTheme.accentCyan],
      stops: const [0.0, 0.5, 1.0],
    );
    final usedPaint =
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * usedPercent,
      false,
      usedPaint,
    );

    // Glow effect on the tip
    if (usedPercent > 0.02) {
      final angle = -pi / 2 + 2 * pi * usedPercent;
      final tipX = center.dx + radius * cos(angle);
      final tipY = center.dy + radius * sin(angle);
      final glowPaint =
          Paint()
            ..color = AppTheme.accentCyan.withOpacity(0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(tipX, tipY), 10, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.usedPercent != usedPercent;
}
