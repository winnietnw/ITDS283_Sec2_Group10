import 'package:flutter/material.dart';
import 'dart:math';

class EmotionGalaxy extends StatefulWidget {
  final double size;
  const EmotionGalaxy({super.key, this.size = 280});

  @override
  State<EmotionGalaxy> createState() => _EmotionGalaxyState();
}

class _EmotionGalaxyState extends State<EmotionGalaxy>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // speed = รอบต่อ animation cycle — วงในเร็ว วงนอกช้า
  final List<_OrbitDot> _dots = [
    // วงใน — หมุนเร็วสุด
    _OrbitDot(orbit: 0.12, startAngle: 0.0, size: 14,
        color: Color(0xFFFFB3C6), speed: 1.8),   // ชมพู
    _OrbitDot(orbit: 0.12, startAngle: pi, size: 9,
        color: Color(0xFFB8E0FF), speed: 1.8),    // ฟ้า

    // วงกลาง — หมุนปานกลาง
    _OrbitDot(orbit: 0.24, startAngle: pi / 3, size: 7,
        color: Color(0xFFE8D5FF), speed: 1.0),    // ม่วงอ่อน
    _OrbitDot(orbit: 0.24, startAngle: pi + pi / 3, size: 6,
        color: Color(0xFFB8E0FF), speed: 1.0),    // ฟ้า

    // วงนอก — หมุนช้าสุด
    _OrbitDot(orbit: 0.36, startAngle: pi / 6, size: 16,
        color: Color(0xFFE0C8FF), speed: 0.5),    // ม่วงพาสเทล
    _OrbitDot(orbit: 0.36, startAngle: pi + pi / 6, size: 10,
        color: Color(0xFFFFD6E7), speed: 0.5),    // ชมพูอ่อน
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.size / 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            // สีตรงต้นฉบับ — น้ำเงินแซมม่วง ไม่มีแสงขาว
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A2080), // ม่วงเข้มซ้ายบน
                Color(0xFF2D1B8E), // น้ำเงินม่วงกลาง
                Color(0xFF1A1060), // น้ำเงินเข้มขวาล่าง
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: _dots.map((dot) {
              // แต่ละวงหมุนด้วยความเร็วต่างกัน
              final angle = dot.startAngle +
                  _controller.value * 2 * pi * dot.speed;
              final radius = widget.size * dot.orbit;
              final x = center + radius * cos(angle) - dot.size / 2;
              final y = center + radius * sin(angle) - dot.size / 2;

              return Positioned(
                left: x,
                top: y,
                child: Container(
                  width: dot.size,
                  height: dot.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dot.color.withValues(alpha: 0.9),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _OrbitDot {
  final double orbit;
  final double startAngle;
  final double size;
  final Color color;
  final double speed; // วงในเร็ว วงนอกช้า

  const _OrbitDot({
    required this.orbit,
    required this.startAngle,
    required this.size,
    required this.color,
    required this.speed,
  });
}