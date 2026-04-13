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

class _TimerRunningScreenState extends State<TimerRunningScreen>
    with SingleTickerProviderStateMixin {
  late int _secondsLeft;
  bool _isRunning = true;
  Timer? _timer;

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.totalSeconds;

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_secondsLeft <= 0) {
        t.cancel();
        await _saveSession(); // ✅ บันทึก session ก่อน
        if (mounted) {
          setState(() => _isRunning = false);
          _showFinishDialog();
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // ✅ บันทึก session ลง Firestore
  Future<void> _saveSession() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('timer_sessions').add({
      'userId': uid,
      'plan': widget.focusLabel,
      'mode': widget.mode,
      'minutes': widget.totalSeconds ~/ 60,
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

  void _confirmStop() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Stop Timer?'),
        content: const Text('Are you sure you want to stop this session?'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 72, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Great job! 🎉\nYou focused for ${widget.totalSeconds ~/ 60} minutes!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Focus now, shine like a star later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5EA7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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

  double get _progress => _secondsLeft / widget.totalSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFFDF),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _confirmStop,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          size: 18, color: Colors.black87),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.focusLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B5EA7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.mode,
                      style: const TextStyle(
                        color: Color(0xFF7B5EA7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Floating planet
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: child,
              ),
              child: CustomPaint(
                size: const Size(80, 80),
                painter: _PlanetPainter(),
              ),
            ),

            const SizedBox(height: 40),

            // Circular progress + time
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF7B5EA7)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_secondsLeft),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _isRunning ? 'Focusing...' : 'Paused',
                          key: ValueKey(_isRunning),
                          style: TextStyle(
                            fontSize: 13,
                            color: _isRunning ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child:
                      Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                ),
              ),
            ),

            const Spacer(),

            // Pause/Resume button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pauseResume,
                  icon: Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isRunning ? 'Pause' : 'Resume',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isRunning ? Colors.orange : const Color(0xFF7B5EA7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawCircle(
      Offset(cx, cy),
      28,
      Paint()..color = const Color(0xFF7B5EA7),
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: size.width, height: 18),
      Paint()
        ..color = const Color(0xFFB39DDB).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    canvas.drawCircle(
      Offset(cx - 8, cy - 8),
      8,
      Paint()..color = Colors.white.withOpacity(0.35),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}