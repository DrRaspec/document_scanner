import 'package:flutter/material.dart';

import '../../../app/core/app_colors.dart';
import '../models/document_item.dart';

class DocumentFileIcon extends StatelessWidget {
  const DocumentFileIcon({required this.type, required this.color, super.key});

  final DocumentType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 24),
      painter: _DocumentIconPainter(type: type, color: color),
    );
  }
}

Color documentColor(DocumentType type) {
  return switch (type) {
    DocumentType.pdf => AppColors.red,
    DocumentType.word => AppColors.primary,
    DocumentType.image => AppColors.accent,
  };
}

class _DocumentIconPainter extends CustomPainter {
  const _DocumentIconPainter({required this.type, required this.color});

  final DocumentType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 1, size.width - 7, size.height - 2),
      const Radius.circular(2),
    );

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, border);

    final fold = Path()
      ..moveTo(size.width - 8, 1)
      ..lineTo(size.width - 2, 7)
      ..lineTo(size.width - 8, 7)
      ..close();
    canvas.drawPath(fold, Paint()..color = color.withValues(alpha: 0.14));
    canvas.drawPath(fold, border);

    switch (type) {
      case DocumentType.word:
        _paintWord(canvas, color);
      case DocumentType.pdf:
        _paintPdf(canvas, color);
      case DocumentType.image:
        _paintImage(canvas, color);
    }
  }

  void _paintWord(Canvas canvas, Color color) {
    final badge = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 8, 13, 12),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(badge, Paint()..color = color);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'W',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(2.5, 9.5));
    _drawLine(canvas, 8, 10.5, 17, color);
    _drawLine(canvas, 8, 14.5, 17, color);
    _drawLine(canvas, 8, 18.5, 14, color);
  }

  void _paintPdf(Canvas canvas, Color color) {
    final curvePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(5, 18)
      ..cubicTo(8, 14, 9, 9, 8, 5)
      ..cubicTo(9.5, 11, 13, 15, 18, 16)
      ..cubicTo(13, 15, 9, 16, 5, 18);
    canvas.drawPath(path, curvePaint);
  }

  void _paintImage(Canvas canvas, Color color) {
    final imagePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(const Offset(12, 9), 1.5, Paint()..color = color);
    final path = Path()
      ..moveTo(7, 18)
      ..lineTo(11, 14)
      ..lineTo(13, 16)
      ..lineTo(16.5, 12.5)
      ..lineTo(19, 18);
    canvas.drawPath(path, imagePaint);
  }

  void _drawLine(Canvas canvas, double x1, double y, double x2, Color color) {
    canvas.drawLine(
      Offset(x1, y),
      Offset(x2, y),
      Paint()
        ..color = color
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DocumentIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
