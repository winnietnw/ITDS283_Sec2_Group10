import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class _TimerRunningScreenState extends State<TimerRunningScreen> {
  late int _secondsLeft;
  bool _isRunning = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.totalSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_secondsLeft <= 0) {
        t.cancel();
        await _saveSession();
        if (mounted) {
          setState(() => _isRunning = false);
          _showFinishScreen();
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _saveSession() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final elapsed = widget.totalSeconds - _secondsLeft;
    await FirebaseFirestore.instance.collection('timer_sessions').add({
      'userId': uid,
      'plan': widget.focusLabel,
      'mode': widget.mode,
      'minutes': elapsed ~/ 60,
      'completedAt': FieldValue.serverTimestamp(),
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

  void _showFinishScreen() {
    final elapsed = widget.totalSeconds - _secondsLeft;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _FinishScreen(
          minutes: elapsed ~/ 60,
          focusLabel: widget.focusLabel,
        ),
      ),
    );
  }

  void _confirmStop() {
    _timer?.cancel();
    setState(() => _isRunning = false);

    final elapsed = widget.totalSeconds - _secondsLeft;
    final willSave = elapsed >= 300; // 5 นาที = 300 วินาที

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                willSave
                    ? 'Stop session?\nProgress will be saved ✓'
                    : "Session under 5 minutes\nwon't be saved",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // End button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (willSave) {
                      await _saveSession();
                      if (mounted) _showFinishScreen(); // ✅ ≥ 5 นาที → finish
                    } else {
                      if (mounted) Navigator.pop(context); // < 5 นาที → ออกเลย
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('End',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 8),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startTimer();
                    setState(() => _isRunning = true);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Text('Continue',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _secondsLeft / widget.totalSeconds;

  static Color _modeColor(String mode) {
    switch (mode) {
      case 'Focus':
        return const Color(0xFF5BA4CF);
      case 'Strict':
        return const Color(0xFFD9534F);
      default:
        return const Color(0xFF888888);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _FloatingCircles(),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // 🔴 Stop
                      GestureDetector(
                        onTap: _confirmStop,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEEE),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.red.shade100, width: 1),
                          ),
                          child: const Icon(Icons.stop_rounded,
                              size: 18, color: Color(0xFFE53935)),
                        ),
                      ),

                      const Spacer(),

                      Column(
                        children: [
                          Text(
                            widget.focusLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _modeColor(widget.mode)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.mode,
                              style: TextStyle(
                                color: _modeColor(widget.mode),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ⏸▶ Pause/Resume
                      GestureDetector(
                        onTap: _pauseResume,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.grey.shade200, width: 1),
                          ),
                          child: Icon(
                            _isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Clock
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: _CountdownTickPainter(progress: _progress),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_secondsLeft),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isRunning ? 'Focusing...' : 'Paused',
                              key: ValueKey(_isRunning),
                              style: TextStyle(
                                fontSize: 13,
                                color: _isRunning
                                    ? Colors.grey.shade500
                                    : Colors.orange,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Planet
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _PlanetPainter(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Countdown Tick Painter
// ══════════════════════════════════════════════════════
class _CountdownTickPainter extends CustomPainter {
  final double progress;

  const _CountdownTickPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) - 4;

    final activeTicks = (progress * 60).round().clamp(0, 60);

    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * pi - pi / 2;
      final isMajor = i % 5 == 0;
      final tickLen = isMajor ? 12.0 : 7.0;
      final strokeW = isMajor ? 2.0 : 1.2;

      double opacity;
      if (i < activeTicks) {
        opacity = (1.0 - (i / activeTicks.clamp(1, 60)) * 0.75)
            .clamp(0.15, 1.0);
      } else {
        opacity = 0.06;
      }

      final p1 = Offset(
          cx + (r - tickLen) * cos(angle),
          cy + (r - tickLen) * sin(angle));
      final p2 = Offset(cx + r * cos(angle), cy + r * sin(angle));

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.black.withOpacity(opacity)
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownTickPainter old) =>
      old.progress != progress;
}

// ══════════════════════════════════════════════════════
// Floating Pastel Circles
// ══════════════════════════════════════════════════════
class _FloatingCircles extends StatefulWidget {
  const _FloatingCircles();

  @override
  State<_FloatingCircles> createState() => _FloatingCirclesState();
}

class _FloatingCirclesState extends State<_FloatingCircles>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  // (color, size, left%, top%, duration)
  static const _circles = [
    (Color(0xFFFFB3C6), 60.0, 0.05, 0.08, 4),
    (Color(0xFFB3D9FF), 80.0, 0.75, 0.05, 5),
    (Color(0xFFFFF3B3), 50.0, 0.85, 0.35, 6),
    (Color(0xFFB3F0D9), 70.0, 0.02, 0.55, 4),
    (Color(0xFFE8B3FF), 55.0, 0.70, 0.75, 5),
    (Color(0xFFFFD9B3), 45.0, 0.40, 0.88, 7),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = _circles.map((c) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: c.$5),
      )..repeat(reverse: true);
    }).toList();

    _anims = _controllers.map((ctrl) {
      return Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: List.generate(_circles.length, (i) {
        final circle = _circles[i];
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Positioned(
            left: size.width * circle.$3,
            top: size.height * circle.$4 + _anims[i].value,
            child: Container(
              width: circle.$2,
              height: circle.$2,
              decoration: BoxDecoration(
                color: circle.$1.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════
// Planet Painter
// ══════════════════════════════════════════════════════
class _PlanetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawCircle(
      Offset(cx, cy),
      26,
      Paint()..color = const Color(0xFF7B5EA7).withOpacity(0.15),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      20,
      Paint()..color = const Color(0xFF7B5EA7).withOpacity(0.25),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy), width: size.width * 0.9, height: 14),
      Paint()
        ..color = const Color(0xFFB39DDB).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ══════════════════════════════════════════════════════
// Finish Screen
// ══════════════════════════════════════════════════════
class _FinishScreen extends StatelessWidget {
  final int minutes;
  final String focusLabel;

  const _FinishScreen({
    required this.minutes,
    required this.focusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _FloatingCircles(),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    const Text(
                      'VibeCheck',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Icon(Icons.star_rounded,
                        size: 80, color: Colors.amber),

                    const SizedBox(height: 32),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6),
                        children: [
                          const TextSpan(text: 'You spent '),
                          TextSpan(
                            text: '$minutes minutes',
                            style: const TextStyle(
                              color: Color(0xFFFF8C42),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' on $focusLabel\n'),
                          const TextSpan(
                              text: 'Focus now, shine like a star later.'),
                        ],
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2D2D),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}