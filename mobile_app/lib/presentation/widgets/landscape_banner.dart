import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandscapeBanner extends StatelessWidget {
  const LandscapeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Rolling Hills Painter
          CustomPaint(
            size: const Size(double.infinity, 96),
            painter: RollingHillsPainter(),
          ),

          // "Better Teachers • Brighter Futures" Pill Badge
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFD1FAE5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 14,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BETTER TEACHERS • BRIGHTER FUTURES',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RollingHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Hill (Light Mint Green)
    final backPaint = Paint()
      ..color = const Color(0xFF86EFAC)
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(0, h * 0.45)
      ..quadraticBezierTo(w * 0.3, h * 0.2, w * 0.6, h * 0.35)
      ..quadraticBezierTo(w * 0.85, h * 0.45, w, h * 0.3)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, backPaint);

    // Midground Hill (Emerald Green)
    final midPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;

    final midPath = Path()
      ..moveTo(0, h * 0.6)
      ..quadraticBezierTo(w * 0.25, h * 0.35, w * 0.55, h * 0.55)
      ..quadraticBezierTo(w * 0.8, h * 0.68, w, h * 0.45)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(midPath, midPaint);

    // Foreground Hill (Rich Forest Green)
    final forePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;

    final forePath = Path()
      ..moveTo(0, h * 0.75)
      ..quadraticBezierTo(w * 0.35, h * 0.5, w * 0.7, h * 0.7)
      ..quadraticBezierTo(w * 0.88, h * 0.78, w, h * 0.65)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(forePath, forePaint);

    // Stylized Tree 1 (Left)
    _drawTree(canvas, Offset(w * 0.1, h * 0.42), 16, const Color(0xFF15803D));
    _drawTree(canvas, Offset(w * 0.16, h * 0.48), 12, const Color(0xFF166534));

    // Stylized Tree 2 (Right)
    _drawTree(canvas, Offset(w * 0.86, h * 0.38), 18, const Color(0xFF15803D));
    _drawTree(canvas, Offset(w * 0.92, h * 0.45), 13, const Color(0xFF166534));
  }

  void _drawTree(Canvas canvas, Offset center, double radius, Color color) {
    // Tree Trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy + radius * 0.5),
      Offset(center.dx, center.dy + radius * 1.3),
      trunkPaint,
    );

    // Tree Foliage
    final foliagePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, foliagePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
