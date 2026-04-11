// lib/screens/timer_running_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class TimerRunningScreen extends StatefulWidget {
  final int totalSeconds;
  final String focusLabel;
  final String mode;

  const TimerRunningScreen({
    super.key,
    required this.totalSeconds,
    required this.focusLabel,
    required this.mode,
  });

  @override
  State<TimerRunningScreen> createState() => _TimerRunningScreenState();
}

class _TimerRunningScreenState extends State<TimerRunningScreen>
    with SingleTickerProviderStateMixin {
  late int _secondsLeft;
  bool _isRunning = true;
  Timer? _timer;

  // Animation controller สำหรับ planet floating
  late AnimationController _animController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.totalSeconds;

    // Planet floating animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // เริ่ม countdown ทันที
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() => _isRunning = false);
        _showFinishDialog();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _pauseResume() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _startTimer();
      setState(() => _isRunning = true);
    }
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'You spent ${widget.totalSeconds ~/ 60}:00 min!\nFocus now, shine like a star later.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // กลับหน้า timer setup
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5EA7),
              ),
              child: const Text('Continue',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Progress 0.0 → 1.0 (สำหรับ circle progress)
  double get _progress => _secondsLeft / widget.totalSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // กด back → ถาม confirm ก่อน
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Stop Timer?'),
                content:
                    const Text('Are you sure you want to stop this session?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: const Text('Stop',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(widget.focusLabel,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7B5EA7).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(widget.mode,
                style: const TextStyle(
                    color: Color(0xFF7B5EA7), fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),

          // Floating planet animation
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: child,
              );
            },
            child: CustomPaint(
              size: const Size(80, 80),
              painter: _PlanetPainter(),
            ),
          ),

          const SizedBox(height: 32),

          // Circular progress + countdown
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF7B5EA7)),
                  ),
                ),
                // Time text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_secondsLeft),
                      style: const TextStyle(
                          fontSize: 44, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isRunning ? 'Focusing...' : 'Paused',
                      style: TextStyle(
                          color: _isRunning
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stars indicator (จาก Figma มีดาวเล็กๆ)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.star, color: Colors.amber, size: 16),
              ),
            ),
          ),

          const Spacer(),

          // Pause / Resume button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pauseResume,
                icon: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                label: Text(
                  _isRunning ? 'Pause' : 'Resume',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning
                      ? Colors.orange
                      : const Color(0xFF7B5EA7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Planet painter — วาด planet แบบง่ายๆ
class _PlanetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // ตัว planet
    paint.color = const Color(0xFF7B5EA7);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), 30, paint);

    // วง ring
    paint
      ..color = const Color(0xFFB39DDB).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width,
          height: 20),
      paint,
    );

    // จุดสว่างบน planet
    paint
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width / 2 - 8, size.height / 2 - 8), 8, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}