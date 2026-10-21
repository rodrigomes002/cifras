import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CifrasLogo extends StatelessWidget {
  const CifrasLogo({super.key, this.size = 36, this.cornerRadius = 12});

  final double size;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.68),
        painter: _MusicMarkPainter(
          foreground: colorScheme.onPrimary,
          accent: AppColors.amber,
        ),
      ),
    );
  }
}

class _MusicMarkPainter extends CustomPainter {
  const _MusicMarkPainter({required this.foreground, required this.accent});

  final Color foreground;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);

    final staffPaint = Paint()
      ..color = foreground.withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (final y in [6.0, 10.0, 14.0, 18.0]) {
      canvas.drawLine(Offset(3, y), Offset(21, y), staffPaint);
    }

    final notePaint = Paint()
      ..color = accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(11, 7), const Offset(11, 18), notePaint);
    canvas.drawLine(const Offset(18, 4), const Offset(18, 15), notePaint);
    canvas.drawLine(const Offset(11, 4), const Offset(18, 4), notePaint);

    final noteHeadPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    for (final center in [const Offset(9, 18), const Offset(16, 15)]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-0.38);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 6.5, height: 4.5),
        noteHeadPaint,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MusicMarkPainter oldDelegate) {
    return foreground != oldDelegate.foreground || accent != oldDelegate.accent;
  }
}
