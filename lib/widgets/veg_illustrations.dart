import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders real high-quality produce photo or falls back smoothly to vector artwork
class ProductImageView extends StatelessWidget {
  final String? imageUrl;
  final String iconKey;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const ProductImageView({
    super.key,
    this.imageUrl,
    required this.iconKey,
    this.width = 64,
    this.height = 64,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(14);

    Widget fallback() {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF182C20),
          borderRadius: radius,
          border: Border.all(color: const Color(0xFF244431), width: 1),
        ),
        child: Center(
          child: ProduceArtWidget(
            iconKey: iconKey,
            size: math.min(width, height) * 0.85,
          ),
        ),
      );
    }

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return fallback();
    }

    final url = imageUrl!.trim();
    Widget imageWidget;

    if (url.startsWith('assets/')) {
      imageWidget = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    } else {
      imageWidget = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFF182C20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF182C20),
        borderRadius: radius,
        border: Border.all(color: const Color(0xFF244431), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageWidget,
    );
  }
}

/// Renders crisp, vibrant custom vector graphics for each vegetable and produce item
class ProduceArtWidget extends StatelessWidget {
  final String iconKey;
  final double size;
  final bool showBadge;

  const ProduceArtWidget({
    super.key,
    required this.iconKey,
    this.size = 54,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF233F2E),
            const Color(0xFF132319),
          ],
          center: Alignment.center,
          radius: 0.85,
        ),
        border: Border.all(
          color: const Color(0xFF2C523B),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.72,
          height: size * 0.72,
          child: CustomPaint(
            painter: _getPainter(iconKey),
          ),
        ),
      ),
    );
  }

  CustomPainter _getPainter(String key) {
    switch (key.toLowerCase()) {
      case 'tomato':
        return _TomatoPainter();
      case 'onion':
        return _OnionPainter();
      case 'potato':
        return _PotatoPainter();
      case 'carrot':
        return _CarrotPainter();
      case 'brinjal':
        return _BrinjalPainter();
      case 'drumstick':
        return _DrumstickPainter();
      case 'beans':
        return _BeansPainter();
      case 'mint':
        return _MintPainter();
      default:
        return _TomatoPainter();
    }
  }
}

// ----------------- PRODUCE PAINTERS -----------------

class _TomatoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Tomato Body (Red gradient)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.8,
        colors: const [
          Color(0xFFFF5252),
          Color(0xFFE53935),
          Color(0xFFB71C1C),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.78, w * 0.8, h * 0.18), shadowPaint);

    // Main lobes
    canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.22, w * 0.84, h * 0.72), bodyPaint);

    // Specular highlight
    final glossPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(w * 0.25, h * 0.32, w * 0.22, h * 0.12), glossPaint);

    // Green Calyx / Leaves
    final leafPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(w * 0.5, h * 0.22);
    leafPath.quadraticBezierTo(w * 0.3, h * 0.08, w * 0.18, h * 0.18);
    leafPath.quadraticBezierTo(w * 0.35, h * 0.26, w * 0.5, h * 0.24);
    leafPath.quadraticBezierTo(w * 0.65, h * 0.26, w * 0.82, h * 0.18);
    leafPath.quadraticBezierTo(w * 0.7, h * 0.08, w * 0.5, h * 0.22);

    // Center star leaves
    leafPath.moveTo(w * 0.5, h * 0.22);
    leafPath.lineTo(w * 0.5, h * 0.05); // stem
    leafPath.lineTo(w * 0.54, h * 0.05);
    leafPath.lineTo(w * 0.53, h * 0.22);

    final stemPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.5, h * 0.22), Offset(w * 0.5, h * 0.06), stemPaint);

    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Onion bulb gradient
    final bulbPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, 0.1),
        radius: 0.9,
        colors: const [
          Color(0xFFE0829D),
          Color(0xFFC2406E),
          Color(0xFF881C44),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(Rect.fromLTWH(w * 0.15, h * 0.8, w * 0.7, h * 0.16), shadowPaint);

    // Bulb shape
    final bulbPath = Path();
    bulbPath.moveTo(w * 0.5, h * 0.12);
    bulbPath.cubicTo(w * 0.1, h * 0.35, w * 0.1, h * 0.85, w * 0.5, h * 0.88);
    bulbPath.cubicTo(w * 0.9, h * 0.85, w * 0.9, h * 0.35, w * 0.5, h * 0.12);
    canvas.drawPath(bulbPath, bulbPaint);

    // Onion surface lines (stripes)
    final linePaint = Paint()
      ..color = const Color(0xFF6B1232).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawArc(Rect.fromLTWH(w * 0.3, h * 0.18, w * 0.4, h * 0.68), -math.pi / 2, math.pi, false, linePaint);
    canvas.drawArc(Rect.fromLTWH(w * 0.4, h * 0.15, w * 0.2, h * 0.72), -math.pi / 2, math.pi, false, linePaint);

    // Stem top tip
    final sproutPaint = Paint()
      ..color = const Color(0xFF7CB342)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.12), Offset(w * 0.52, h * 0.04), sproutPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PotatoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final potatoPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        radius: 0.8,
        colors: const [
          Color(0xFFE5C07B),
          Color(0xFFC69C55),
          Color(0xFF8D682E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Organic oblong potato
    final path = Path();
    path.moveTo(w * 0.25, h * 0.3);
    path.cubicTo(w * 0.35, h * 0.15, w * 0.75, h * 0.18, w * 0.85, h * 0.45);
    path.cubicTo(w * 0.92, h * 0.75, w * 0.65, h * 0.88, w * 0.4, h * 0.85);
    path.cubicTo(w * 0.15, h * 0.82, w * 0.12, h * 0.5, w * 0.25, h * 0.3);
    canvas.drawPath(path, potatoPaint);

    // Potato eye spots
    final spotPaint = Paint()
      ..color = const Color(0xFF6B4E1B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    canvas.drawArc(Rect.fromLTWH(w * 0.35, h * 0.38, 6, 4), 0, math.pi, false, spotPaint);
    canvas.drawArc(Rect.fromLTWH(w * 0.62, h * 0.5, 6, 4), 0, math.pi, false, spotPaint);
    canvas.drawArc(Rect.fromLTWH(w * 0.45, h * 0.65, 5, 3), 0, math.pi, false, spotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CarrotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Green leaves
    final leafPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.25), Offset(w * 0.35, h * 0.08), leafPaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.25), Offset(w * 0.5, h * 0.05), leafPaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.25), Offset(w * 0.65, h * 0.08), leafPaint);

    // Carrot conical body
    final carrotPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFFF9800),
          Color(0xFFF57C00),
          Color(0xFFE65100),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path();
    path.moveTo(w * 0.32, h * 0.25);
    path.quadraticBezierTo(w * 0.5, h * 0.2, w * 0.68, h * 0.25);
    path.cubicTo(w * 0.65, h * 0.5, w * 0.55, h * 0.8, w * 0.5, h * 0.95);
    path.cubicTo(w * 0.45, h * 0.8, w * 0.35, h * 0.5, w * 0.32, h * 0.25);
    canvas.drawPath(path, carrotPaint);

    // Horizontal ridges
    final ridgePaint = Paint()
      ..color = const Color(0xFFBF360C).withOpacity(0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.4, h * 0.38), Offset(w * 0.58, h * 0.4), ridgePaint);
    canvas.drawLine(Offset(w * 0.42, h * 0.52), Offset(w * 0.56, h * 0.54), ridgePaint);
    canvas.drawLine(Offset(w * 0.45, h * 0.68), Offset(w * 0.53, h * 0.7), ridgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrinjalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Purple gradient body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, 0.2),
        radius: 0.8,
        colors: const [
          Color(0xFF8E24AA),
          Color(0xFF6A1B9A),
          Color(0xFF4A148C),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path();
    path.moveTo(w * 0.45, h * 0.25);
    path.cubicTo(w * 0.2, h * 0.4, w * 0.2, h * 0.8, w * 0.5, h * 0.9);
    path.cubicTo(w * 0.8, h * 0.8, w * 0.8, h * 0.4, w * 0.55, h * 0.25);
    canvas.drawPath(path, bodyPaint);

    // Gloss
    final glossPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(w * 0.32, h * 0.45, w * 0.15, h * 0.25), glossPaint);

    // Green Calyx cap
    final capPaint = Paint()..color = const Color(0xFF388E3C);
    final capPath = Path();
    capPath.moveTo(w * 0.5, h * 0.25);
    capPath.lineTo(w * 0.3, h * 0.32);
    capPath.lineTo(w * 0.4, h * 0.22);
    capPath.lineTo(w * 0.5, h * 0.28);
    capPath.lineTo(w * 0.6, h * 0.22);
    capPath.lineTo(w * 0.7, h * 0.32);
    capPath.close();
    canvas.drawPath(capPath, capPaint);

    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.22), Offset(w * 0.5, h * 0.08), stemPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DrumstickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final podPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF66BB6A),
          Color(0xFF43A047),
          Color(0xFF2E7D32),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(w * 0.2, h * 0.15);
    path.quadraticBezierTo(w * 0.5, h * 0.45, w * 0.8, h * 0.85);
    canvas.drawPath(path, podPaint);

    // Ribbed segments
    final ribPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(w * 0.32, h * 0.28), Offset(w * 0.36, h * 0.32), ribPaint);
    canvas.drawLine(Offset(w * 0.48, h * 0.46), Offset(w * 0.52, h * 0.50), ribPaint);
    canvas.drawLine(Offset(w * 0.64, h * 0.66), Offset(w * 0.68, h * 0.70), ribPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BeansPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final beanPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Curved bean pod 1
    final path1 = Path();
    path1.moveTo(w * 0.3, h * 0.15);
    path1.quadraticBezierTo(w * 0.6, h * 0.45, w * 0.4, h * 0.85);
    canvas.drawPath(path1, beanPaint);

    // Curved bean pod 2
    final beanPaint2 = Paint()
      ..color = const Color(0xFF66BB6A)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path2 = Path();
    path2.moveTo(w * 0.45, h * 0.2);
    path2.quadraticBezierTo(w * 0.75, h * 0.5, w * 0.55, h * 0.88);
    canvas.drawPath(path2, beanPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.9), Offset(w * 0.5, h * 0.2), stemPaint);

    // Serrated leaves
    final leafPaint = Paint()..color = const Color(0xFF43A047);

    // Left leaves
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.35, h * 0.45), width: w * 0.28, height: h * 0.18), leafPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.32, h * 0.65), width: w * 0.3, height: h * 0.2), leafPaint);

    // Right leaves
    final leafPaintRight = Paint()..color = const Color(0xFF66BB6A);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.65, h * 0.38), width: w * 0.28, height: h * 0.18), leafPaintRight);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.68, h * 0.58), width: w * 0.3, height: h * 0.2), leafPaintRight);

    // Top tip
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.2), width: w * 0.2, height: h * 0.2), leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------- SCOOTER DELIVERY GRAPHIC -----------------

class ScooterDeliveryIllustration extends StatelessWidget {
  final double width;
  final double height;

  const ScooterDeliveryIllustration({
    super.key,
    this.width = 220,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ScooterPainter(),
      ),
    );
  }
}

class _ScooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Road shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.82, w * 0.9, h * 0.12), shadowPaint);

    // Wheels
    final tirePaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.fill;

    // Back wheel
    canvas.drawCircle(Offset(w * 0.25, h * 0.75), w * 0.13, tirePaint);
    canvas.drawCircle(Offset(w * 0.25, h * 0.75), w * 0.06, rimPaint);

    // Front wheel
    canvas.drawCircle(Offset(w * 0.78, h * 0.75), w * 0.13, tirePaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.75), w * 0.06, rimPaint);

    // Scooter Body (Orange / Coral like screenshot)
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xFFFF7043),
          Color(0xFFE64A19),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final chassisPath = Path();
    chassisPath.moveTo(w * 0.22, h * 0.72);
    chassisPath.lineTo(w * 0.42, h * 0.72);
    chassisPath.lineTo(w * 0.58, h * 0.65);
    chassisPath.lineTo(w * 0.72, h * 0.45);
    chassisPath.lineTo(w * 0.66, h * 0.42);
    chassisPath.lineTo(w * 0.48, h * 0.58);
    chassisPath.lineTo(w * 0.32, h * 0.58);
    chassisPath.close();
    canvas.drawPath(chassisPath, bodyPaint);

    // Seat
    final seatPaint = Paint()..color = const Color(0xFF212121);
    final seatRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.3, h * 0.52, w * 0.22, h * 0.08),
      const Radius.circular(6),
    );
    canvas.drawRRect(seatRect, seatPaint);

    // Delivery Box (Green Supermarket delivery box on back)
    final boxPaint = Paint()..color = const Color(0xFF10B981);
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.34, w * 0.18, h * 0.24),
      const Radius.circular(4),
    );
    canvas.drawRRect(boxRect, boxPaint);

    // Leaf logo on box
    final boxLogoPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.23, h * 0.46), 5, boxLogoPaint);

    // Driver body (Jacket / Rider)
    final riderPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawOval(Rect.fromLTWH(w * 0.36, h * 0.35, w * 0.16, h * 0.22), riderPaint);

    // Rider head / Helmet
    final helmetPaint = Paint()..color = const Color(0xFFFFB74D);
    canvas.drawCircle(Offset(w * 0.46, h * 0.26), w * 0.08, helmetPaint);

    // Helmet visor
    final visorPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawOval(Rect.fromLTWH(w * 0.48, h * 0.24, w * 0.06, h * 0.04), visorPaint);

    // Handlebar & fork
    final handlePaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.78, h * 0.75), Offset(w * 0.68, h * 0.38), handlePaint);
    canvas.drawLine(Offset(w * 0.65, h * 0.38), Offset(w * 0.72, h * 0.36), handlePaint);

    // Headlight glow
    final lightPaint = Paint()
      ..color = const Color(0xFFFFEE58).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(w * 0.74, h * 0.45), 5, lightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------- HARVEST BASKET BANNER ART -----------------

class HarvestBasketIllustration extends StatelessWidget {
  final double height;

  const HarvestBasketIllustration({
    super.key,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background organic ambient glow
          Container(
            width: height * 1.4,
            height: height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  const Color(0xFF2A5538).withOpacity(0.35),
                  const Color(0xFF13271A).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Custom Harvest Basket Painter
          CustomPaint(
            size: Size(height * 1.5, height),
            painter: _HarvestBasketPainter(),
          ),
        ],
      ),
    );
  }
}

class _HarvestBasketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Shadow on Floor
    final floorShadow = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.94), width: w * 0.72, height: h * 0.16),
      floorShadow,
    );

    // 2. Background Greens / Foliage
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2E7D32);
    final darkLeafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1B5E20);

    // Left leaves
    final leftLeafPath = Path()
      ..moveTo(w * 0.28, h * 0.45)
      ..quadraticBezierTo(w * 0.12, h * 0.25, w * 0.16, h * 0.15)
      ..quadraticBezierTo(w * 0.32, h * 0.22, w * 0.34, h * 0.42);
    canvas.drawPath(leftLeafPath, darkLeafPaint);

    final leftLeafPath2 = Path()
      ..moveTo(w * 0.25, h * 0.42)
      ..quadraticBezierTo(w * 0.16, h * 0.38, w * 0.10, h * 0.30)
      ..quadraticBezierTo(w * 0.22, h * 0.48, w * 0.28, h * 0.50);
    canvas.drawPath(leftLeafPath2, leafPaint);

    // Right leaves
    final rightLeafPath = Path()
      ..moveTo(w * 0.72, h * 0.45)
      ..quadraticBezierTo(w * 0.88, h * 0.25, w * 0.84, h * 0.15)
      ..quadraticBezierTo(w * 0.68, h * 0.22, w * 0.66, h * 0.42);
    canvas.drawPath(rightLeafPath, darkLeafPaint);

    // 3. Eggplant / Brinjal (Back Right)
    final brinjalPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.2, -0.2),
        radius: 0.8,
        colors: [Color(0xFF7B1FA2), Color(0xFF4A148C), Color(0xFF260438)],
      ).createShader(Rect.fromLTWH(w * 0.60, h * 0.24, w * 0.22, h * 0.38));
    canvas.save();
    canvas.translate(w * 0.72, h * 0.38);
    canvas.rotate(0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.18, height: h * 0.32), brinjalPaint);
    // Brinjal calyx
    final bCalyx = Path()
      ..moveTo(0, -h * 0.16)
      ..lineTo(-w * 0.04, -h * 0.10)
      ..lineTo(-w * 0.02, -h * 0.06)
      ..lineTo(0, -h * 0.08)
      ..lineTo(w * 0.03, -h * 0.05)
      ..lineTo(w * 0.04, -h * 0.11)
      ..close();
    canvas.drawPath(bCalyx, darkLeafPaint);
    canvas.restore();

    // 4. Carrots (Center-Right pointing up)
    final carrotPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF8F00), Color(0xFFF57C00), Color(0xFFE65100)],
      ).createShader(Rect.fromLTWH(w * 0.52, h * 0.20, w * 0.14, h * 0.35));
    final carrotPath = Path()
      ..moveTo(w * 0.54, h * 0.26)
      ..quadraticBezierTo(w * 0.60, h * 0.25, w * 0.64, h * 0.27)
      ..quadraticBezierTo(w * 0.62, h * 0.48, w * 0.59, h * 0.56)
      ..quadraticBezierTo(w * 0.55, h * 0.48, w * 0.54, h * 0.26);
    canvas.drawPath(carrotPath, carrotPaint);

    // Carrot greens
    final carrotGreens = Path()
      ..moveTo(w * 0.59, h * 0.26)
      ..lineTo(w * 0.58, h * 0.14)
      ..lineTo(w * 0.61, h * 0.12)
      ..lineTo(w * 0.60, h * 0.26);
    canvas.drawPath(carrotGreens, leafPaint);

    // 5. Red Onion (Left Back)
    final onionPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.2),
        radius: 0.8,
        colors: [Color(0xFFE91E63), Color(0xFFAD1457), Color(0xFF560027)],
      ).createShader(Rect.fromLTWH(w * 0.22, h * 0.32, w * 0.22, h * 0.28));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.32, h * 0.46), width: w * 0.22, height: h * 0.28),
      onionPaint,
    );

    // 6. Plump Juicy Ripe Tomatoes (Front and Center)
    final tomatoPaint1 = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.3),
        radius: 0.8,
        colors: [Color(0xFFFF5252), Color(0xFFE53935), Color(0xFFB71C1C)],
      ).createShader(Rect.fromLTWH(w * 0.36, h * 0.28, w * 0.28, h * 0.34));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.48, h * 0.44), width: w * 0.28, height: h * 0.32),
      tomatoPaint1,
    );

    // Specular highlight on tomato
    final gloss = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.43, h * 0.38), width: w * 0.07, height: h * 0.04),
      gloss,
    );

    // Calyx / star leaves on main tomato
    final tCalyx = Path();
    final tCenter = Offset(w * 0.48, h * 0.32);
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * math.pi / 180;
      final tipX = tCenter.dx + math.cos(angle) * (w * 0.07);
      final tipY = tCenter.dy + math.sin(angle) * (h * 0.06);
      if (i == 0) {
        tCalyx.moveTo(tipX, tipY);
      } else {
        tCalyx.lineTo(tipX, tipY);
      }
      tCalyx.lineTo(tCenter.dx, tCenter.dy);
    }
    tCalyx.close();
    canvas.drawPath(tCalyx, leafPaint);

    // Secondary smaller tomato on front left
    final tomatoPaint2 = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.3),
        radius: 0.8,
        colors: [Color(0xFFFF6E6E), Color(0xFFEF5350), Color(0xFFC62828)],
      ).createShader(Rect.fromLTWH(w * 0.24, h * 0.40, w * 0.20, h * 0.24));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.34, h * 0.52), width: w * 0.20, height: h * 0.24),
      tomatoPaint2,
    );

    // 7. Woven Wicker Basket Body
    final basketPath = Path()
      ..moveTo(w * 0.16, h * 0.52) // Top left rim
      ..quadraticBezierTo(w * 0.50, h * 0.56, w * 0.84, h * 0.52) // Top front rim dip
      ..quadraticBezierTo(w * 0.80, h * 0.84, w * 0.68, h * 0.90) // Right side down
      ..quadraticBezierTo(w * 0.50, h * 0.92, w * 0.32, h * 0.90) // Flat base
      ..quadraticBezierTo(w * 0.20, h * 0.84, w * 0.16, h * 0.52) // Left side up
      ..close();

    final basketFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFB88252),
          Color(0xFF8D5B36),
          Color(0xFF5A351D),
          Color(0xFF381F0E),
        ],
      ).createShader(Rect.fromLTWH(w * 0.16, h * 0.52, w * 0.68, h * 0.40));
    canvas.drawPath(basketPath, basketFill);

    // 8. Wicker Weave Texture Lines
    canvas.save();
    canvas.clipPath(basketPath);
    final weavePaintLight = Paint()
      ..color = const Color(0xFFD4A373).withOpacity(0.55)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final weavePaintDark = Paint()
      ..color = const Color(0xFF2C1608).withOpacity(0.65)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Diagonal weave criss-cross
    for (double x = -w * 0.2; x < w * 1.2; x += 14) {
      canvas.drawLine(Offset(x, h * 0.48), Offset(x + w * 0.3, h * 0.95), weavePaintLight);
      canvas.drawLine(Offset(x + w * 0.3, h * 0.48), Offset(x, h * 0.95), weavePaintDark);
    }
    // Horizontal slat rings
    for (double y = h * 0.56; y < h * 0.90; y += 12) {
      final ringPath = Path()
        ..moveTo(w * 0.16, y)
        ..quadraticBezierTo(w * 0.50, y + 8, w * 0.84, y);
      canvas.drawPath(ringPath, weavePaintDark);
    }
    canvas.restore();

    // 9. Thick Woven Rim Bead across the top
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7A4A28), Color(0xFFD4A373), Color(0xFF633718)],
      ).createShader(Rect.fromLTWH(w * 0.14, h * 0.49, w * 0.72, h * 0.08))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    final rimPath = Path()
      ..moveTo(w * 0.16, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.56, w * 0.84, h * 0.52);
    canvas.drawPath(rimPath, rimPaint);

    // Rim wrapping stitch details
    final stitchPaint = Paint()
      ..color = const Color(0xFF2D1508)
      ..strokeWidth = 1.5;
    for (double i = 0.18; i <= 0.82; i += 0.035) {
      final rx = w * i;
      final ry = h * (0.52 + 0.04 * math.sin((i - 0.16) / 0.68 * math.pi));
      canvas.drawLine(Offset(rx - 2, ry - 4), Offset(rx + 2, ry + 4), stitchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------- CELEBRATION CONFETTI -----------------

class CelebrationConfetti extends StatelessWidget {
  final double size;

  const CelebrationConfetti({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ConfettiPainter(),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFEAB308),
    ];

    final random = math.Random(42);
    for (int i = 0; i < 28; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = (w * 0.28) + (random.nextDouble() * (w * 0.2));
      final cx = (w / 2) + math.cos(angle) * dist;
      final cy = (h / 2) + math.sin(angle) * dist;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(cx, cy), 3.5, paint);
      } else if (i % 3 == 1) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: 6, height: 10),
          paint,
        );
      } else {
        final path = Path();
        path.moveTo(cx, cy - 5);
        path.lineTo(cx + 4, cy + 4);
        path.lineTo(cx - 4, cy + 4);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
