import 'package:flutter/material.dart';
import 'dart:math';

class EmotionData {
  final String type;
  final DateTime time;

  EmotionData({required this.type, required this.time});
}

class EmotionalGalaxy extends StatefulWidget {
  final List<EmotionData> emotions;

  const EmotionalGalaxy({super.key, required this.emotions});

  @override
  State<EmotionalGalaxy> createState() => _EmotionalGalaxyState();
}

class _EmotionalGalaxyState extends State<EmotionalGalaxy>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: GalaxyPainter(
              emotions: widget.emotions,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

// PAINTER
class GalaxyPainter extends CustomPainter {
  final List<EmotionData> emotions;
  final double progress;

  GalaxyPainter({required this.emotions, required this.progress});

  final Random random = Random(1);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // SUN
    final sun = Paint()
      ..color = Colors.orangeAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(center, 22, sun);

    final count = emotions.isEmpty ? 20 : emotions.length;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + progress * 2 * pi;
      final radius = 50 + sin(progress * 2 * pi + i) * 10 + i * 2;

      final offset = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final paint = Paint()
        ..color = _color(emotions.isEmpty ? 'neutral' : emotions[i].type)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(offset, 3, paint);
    }
  }

  Color _color(String type) {
    if (type == 'positive') return Colors.greenAccent;
    if (type == 'neutral') return Colors.blueAccent;
    return Colors.redAccent;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}