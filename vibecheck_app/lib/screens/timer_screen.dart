import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/header.dart';
import 'timer_running_screen.dart';
import 'analytics_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  String _selectedMode = 'Normal';
  String _plan = '';
  int _selectedMinutes = 30;

  // animation สำหรับเข็มนาฬิกา (ตกแต่ง ไม่ได้เดินจริง)
  late AnimationController _tickController;

  @override
  void initState() {
    super.initState();
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _tickController.dispose();
    super.dispose();
  }

  void _openSetPlan() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetPlanSheet(
        initialPlan: _plan,
        initialMode: _selectedMode,
        initialMinutes: _selectedMinutes,
      ),
    );
    if (result != null) {
      setState(() {
        _plan = result['plan'] ?? '';
        _selectedMode = result['mode'] ?? 'Normal';
        _selectedMinutes = result['minutes'] ?? 30;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFFDF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 112,
              flexibleSpace: const Padding(
                padding: EdgeInsets.only(top: 10),
                child: AppHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    // History icon row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AnalyticsScreen(),
                            ),
                          ),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Set Plan button
                    GestureDetector(
                      onTap: _openSetPlan,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB3D9FF), Color(0xFFD4B8F0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _plan.isEmpty ? 'Set Plan' : _plan,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right,
                                size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Analog clock
                    AnimatedBuilder(
                      animation: _tickController,
                      builder: (_, __) => CustomPaint(
                        size: const Size(200, 200),
                        painter: _AnalogClockPainter(
                          minutes: _selectedMinutes,
                          progress: _tickController.value,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Start button
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TimerRunningScreen(
                            totalSeconds: _selectedMinutes * 60,
                            focusLabel: _plan.isEmpty ? 'Focus' : _plan,
                            mode: _selectedMode,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Start ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Icon(Icons.play_arrow_rounded,
                                size: 20, color: Colors.black87),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Set Plan Bottom Sheet ───────────────────────────────────────────────────

class _SetPlanSheet extends StatefulWidget {
  final String initialPlan;
  final String initialMode;
  final int initialMinutes;

  const _SetPlanSheet({
    required this.initialPlan,
    required this.initialMode,
    required this.initialMinutes,
  });

  @override
  State<_SetPlanSheet> createState() => _SetPlanSheetState();
}

class _SetPlanSheetState extends State<_SetPlanSheet> {
  late TextEditingController _planCtrl;
  late String _mode;
  late int _minutes;

  final List<String> _modes = ['Normal', 'Focus', 'Strict'];

  @override
  void initState() {
    super.initState();
    _planCtrl = TextEditingController(text: widget.initialPlan);
    _mode = widget.initialMode;
    _minutes = widget.initialMinutes;
  }

  @override
  void dispose() {
    _planCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF0),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back arrow + title
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Plan input
          const Text('Plan',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _planCtrl,
              decoration: const InputDecoration(
                hintText: 'Write a plan',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon:
                    Icon(Icons.unfold_more, color: Colors.grey, size: 18),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Mode selector
          const Text('Mode',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: _modes.map((m) {
              final isSelected = _mode == m;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _mode = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.grey.shade300
                            : Colors.transparent,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          m == 'Normal'
                              ? Icons.nature
                              : m == 'Focus'
                                  ? Icons.center_focus_strong
                                  : Icons.lock_outline,
                          size: 22,
                          color: Colors.black87,
                        ),
                        const SizedBox(height: 4),
                        Text(m,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Duration chips
          Wrap(
            spacing: 8,
            children: [15, 25, 30, 45, 60].map((min) {
              final isSelected = _minutes == min;
              return GestureDetector(
                onTap: () => setState(() => _minutes = min),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7B5EA7)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    '$min min',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Clock preview
          Center(
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(130, 130),
                  painter: _AnalogClockPainter(
                    minutes: _minutes,
                    progress: 0,
                    showPhone: true,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, {
                  'plan': _planCtrl.text.trim(),
                  'mode': _mode,
                  'minutes': _minutes,
                });
              },
              icon: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white),
              label: const Text('Start',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.6),
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Analog Clock Painter ─────────────────────────────────────────────────────

class _AnalogClockPainter extends CustomPainter {
  final int minutes;
  final double progress;
  final bool showPhone;

  const _AnalogClockPainter({
    required this.minutes,
    required this.progress,
    this.showPhone = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) - 4;

    // วงนาฬิกา
    final circlePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), r, circlePaint);

    // tick marks (12 อัน)
    final tickPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi - pi / 2;
      final outer = Offset(cx + r * cos(angle), cy + r * sin(angle));
      final inner =
          Offset(cx + (r - 8) * cos(angle), cy + (r - 8) * sin(angle));
      canvas.drawLine(inner, outer, tickPaint);
    }

    // เข็มนาทีแสดงตาม minutes ที่เลือก
    final minAngle = (minutes / 60) * 2 * pi - pi / 2;
    final minPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + (r * 0.75) * cos(minAngle), cy + (r * 0.75) * sin(minAngle)),
      minPaint,
    );

    // เข็มชั่วโมง (ชี้ 12)
    final hrPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, cy - r * 0.5),
      hrPaint,
    );

    // จุดกลาง
    canvas.drawCircle(
        Offset(cx, cy),
        4,
        Paint()..color = Colors.black87);

    // ข้อความเวลา
    final timeTp = TextPainter(
      text: TextSpan(
        text: '${minutes.toString().padLeft(2, '0')}:00',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    timeTp.paint(
        canvas, Offset(cx - timeTp.width / 2, cy + r * 0.3));
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter old) =>
      old.minutes != minutes || old.progress != progress;
}