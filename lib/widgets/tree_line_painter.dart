import 'package:flutter/material.dart';

class TreeBranchDecoration extends StatelessWidget {
  final Widget child;
  final bool isLast;
  final bool isFirst;

  const TreeBranchDecoration({
    super.key,
    required this.child,
    this.isLast = false,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kolom Garis Pohon Hierarki
          SizedBox(
            width: 32,
            child: CustomPaint(
              painter: _TreeBranchPainter(
                isLast: isLast,
                isFirst: isFirst,
                lineColor: Colors.white.withOpacity(0.25),
              ),
            ),
          ),
          // Isi Kartu
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TreeBranchPainter extends CustomPainter {
  final bool isLast;
  final bool isFirst;
  final Color lineColor;

  _TreeBranchPainter({
    required this.isLast,
    required this.isFirst,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double startX = 14.0;
    final double midY = size.height / 2;

    // Garis vertikal
    if (isLast) {
      // Hanya dari atas sampai tengah
      canvas.drawLine(Offset(startX, 0), Offset(startX, midY), paint);
    } else {
      // Dari atas sampai bawah penuh
      canvas.drawLine(Offset(startX, 0), Offset(startX, size.height), paint);
    }

    // Garis horizontal ke kanan (siku menuju kartu anak)
    canvas.drawLine(Offset(startX, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(covariant _TreeBranchPainter oldDelegate) {
    return oldDelegate.isLast != isLast ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.lineColor != lineColor;
  }
}
