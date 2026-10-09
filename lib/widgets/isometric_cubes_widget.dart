import 'package:flutter/material.dart';

class IsometricCubesWidget extends StatelessWidget {
  final double size;
  final bool isDark;

  const IsometricCubesWidget({
    super.key,
    this.size = 140,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IsometricCubesPainter(isDark: isDark),
      ),
    );
  }
}

class _IsometricCubesPainter extends CustomPainter {
  final bool isDark;

  _IsometricCubesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isDark ? Colors.white : Colors.black;
    final topCubeFillColor = isDark ? Colors.white : Colors.black;
    final topCubeSideFillColor =
        isDark ? const Color(0xFFCCCCCC) : const Color(0xFF222222);
    final bottomCubeFillColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.22;

    const double cos30 = 0.86602540378;
    const double sin30 = 0.5;

    final dx = s * cos30;
    final dy = s * sin30;

    void drawCube({
      required Offset center,
      required Color topColor,
      required Color leftColor,
      required Color rightColor,
    }) {
      final pCenter = center;
      final pTop = Offset(center.dx, center.dy - s);
      final pTopRight = Offset(center.dx + dx, center.dy - dy);
      final pTopLeft = Offset(center.dx - dx, center.dy - dy);
      final pBottom = Offset(center.dx, center.dy + s);
      final pBottomRight = Offset(center.dx + dx, center.dy + dy);
      final pBottomLeft = Offset(center.dx - dx, center.dy + dy);

      final topPath = Path()
        ..moveTo(pCenter.dx, pCenter.dy)
        ..lineTo(pTopRight.dx, pTopRight.dy)
        ..lineTo(pTop.dx, pTop.dy)
        ..lineTo(pTopLeft.dx, pTopLeft.dy)
        ..close();

      canvas.drawPath(
          topPath,
          Paint()
            ..color = topColor
            ..style = PaintingStyle.fill);
      canvas.drawPath(topPath, strokePaint);

      final leftPath = Path()
        ..moveTo(pCenter.dx, pCenter.dy)
        ..lineTo(pTopLeft.dx, pTopLeft.dy)
        ..lineTo(pBottomLeft.dx, pBottomLeft.dy)
        ..lineTo(pBottom.dx, pBottom.dy)
        ..close();

      canvas.drawPath(
          leftPath,
          Paint()
            ..color = leftColor
            ..style = PaintingStyle.fill);
      canvas.drawPath(leftPath, strokePaint);

      final rightPath = Path()
        ..moveTo(pCenter.dx, pCenter.dy)
        ..lineTo(pTopRight.dx, pTopRight.dy)
        ..lineTo(pBottomRight.dx, pBottomRight.dy)
        ..lineTo(pBottom.dx, pBottom.dy)
        ..close();

      canvas.drawPath(
          rightPath,
          Paint()
            ..color = rightColor
            ..style = PaintingStyle.fill);
      canvas.drawPath(rightPath, strokePaint);
    }

    final topCenter = Offset(cx, cy - dy * 1.55);
    final bLeftCenter = Offset(cx - dx * 0.98, cy + dy * 0.65);
    final bRightCenter = Offset(cx + dx * 0.98, cy + dy * 0.65);

    drawCube(
      center: bLeftCenter,
      topColor: bottomCubeFillColor,
      leftColor: bottomCubeFillColor,
      rightColor: bottomCubeFillColor,
    );

    drawCube(
      center: bRightCenter,
      topColor: bottomCubeFillColor,
      leftColor: bottomCubeFillColor,
      rightColor: bottomCubeFillColor,
    );

    drawCube(
      center: topCenter,
      topColor: topCubeFillColor,
      leftColor: topCubeSideFillColor,
      rightColor: topCubeFillColor,
    );
  }

  @override
  bool shouldRepaint(covariant _IsometricCubesPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
