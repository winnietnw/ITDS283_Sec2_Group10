import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  static Color _modeColor(String mode) {
    switch (mode) {
      case 'Focus':
        return const Color.fromARGB(255, 144, 191, 220);
      case 'Strict':
        return const Color.fromARGB(255, 226, 138, 135);
      default:
        return const Color.fromARGB(255, 151, 152, 151);
    }
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
              floating: false,
              snap: false,
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
                    const SizedBox(height: 8),

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

                    GestureDetector(
                      onTap: _openSetPlan,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _modeColor(_selectedMode).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _modeColor(_selectedMode).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _plan.isEmpty ? 'Set Plan' : _plan,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _modeColor(_selectedMode),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: _modeColor(_selectedMode),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    _TickFadeClock(
                      minutes: _selectedMinutes,
                      plan: _plan.isEmpty ? 'Focus' : _plan,
                    ),

                    const SizedBox(height: 36),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['Normal', 'Focus', 'Strict'].map((mode) {
                        final isSelected = _selectedMode == mode;
                        final modeColor = _modeColor(mode);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedMode = mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? modeColor
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: modeColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              mode,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black45,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),

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
                          horizontal: 48,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B5EA7),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B5EA7).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Start',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
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

class _TickFadeClock extends StatelessWidget {
  final int minutes;
  final String plan;

  const _TickFadeClock({
    required this.minutes,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: CustomPaint(
        painter: _TickFadeClockPainter(minutes: minutes),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:00',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mins Remaining\nfor $plan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.35),
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TickFadeClockPainter extends CustomPainter {
  final int minutes;

  const _TickFadeClockPainter({required this.minutes});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) - 4;

    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * pi - pi / 2;
      final isMajor = i % 5 == 0;
      final tickLen = isMajor ? 12.0 : 7.0;
      final strokeW = isMajor ? 2.0 : 1.2;
      final opacity = (1.0 - (i / 60) * 0.82).clamp(0.08, 1.0);

      final p1 = Offset(
        cx + (r - tickLen) * cos(angle),
        cy + (r - tickLen) * sin(angle),
      );
      final p2 = Offset(
        cx + r * cos(angle),
        cy + r * sin(angle),
      );

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
  bool shouldRepaint(covariant _TickFadeClockPainter oldDelegate) {
    return oldDelegate.minutes != minutes;
  }
}

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
  late String _selectedPlan;
  late String _mode;
  late int _minutes;
  bool _isCustomMinutes = false;
  final TextEditingController _customMinCtrl = TextEditingController();
  List<String> _tasks = [];
  bool _loadingTasks = true;

  final List<String> _modes = ['Normal', 'Focus', 'Strict'];

  static Color _modeColor(String mode) {
    switch (mode) {
      case 'Focus':
        return const Color.fromARGB(255, 144, 191, 220);
      case 'Strict':
        return const Color.fromARGB(255, 226, 138, 135);
      default:
        return const Color.fromARGB(255, 151, 152, 151);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan;
    _mode = widget.initialMode;
    _minutes = widget.initialMinutes;

    if (![15, 30, 45, 60].contains(_minutes)) {
      _isCustomMinutes = true;
      _customMinCtrl.text = _minutes.toString();
    }

    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) {
          setState(() => _loadingTasks = false);
        }
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .where('isCompleted', isEqualTo: false)
          .get();

      if (mounted) {
        setState(() {
          _tasks = snap.docs
              .map((d) => (d.data()['title'] as String?) ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
          _loadingTasks = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingTasks = false);
      }
    }
  }

  @override
  void dispose() {
    _customMinCtrl.dispose();
    super.dispose();
  }

  int get _effectiveMinutes {
    if (_isCustomMinutes) {
      return (int.tryParse(_customMinCtrl.text) ?? _minutes).clamp(1, 600);
    }
    return _minutes;
  }

  @override
  Widget build(BuildContext context) {
    final currentModeColor = _modeColor(_mode);

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.55,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFFDF),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Plan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _loadingTasks
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF7B5EA7),
                                ),
                              ),
                            ),
                          )
                        : _tasks.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  'No pending tasks',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _tasks.contains(_selectedPlan)
                                      ? _selectedPlan
                                      : null,
                                  hint: const Text(
                                    'Select a task',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.unfold_more,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  dropdownColor: const Color(0xFFEFFFDF),
                                  borderRadius: BorderRadius.circular(16),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text(
                                        'No specific task',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    ..._tasks.map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          t,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    setState(() => _selectedPlan = v ?? '');
                                  },
                                ),
                              ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _modes.map((m) {
                      final isSelected = _mode == m;
                      final modeColor = _modeColor(m);

                      return GestureDetector(
                        onTap: () => setState(() => _mode = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 92,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? modeColor
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: modeColor.withOpacity(0.25),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                m == 'Normal'
                                    ? Icons.nature
                                    : m == 'Focus'
                                        ? Icons.center_focus_strong
                                        : Icons.lock_outline,
                                size: 22,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black38,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...[15, 30, 45, 60].map((min) {
                        final isSelected = !_isCustomMinutes && _minutes == min;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _minutes = min;
                              _isCustomMinutes = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? currentModeColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            currentModeColor.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              '$min min',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }),

                      GestureDetector(
                        onTap: () => setState(() => _isCustomMinutes = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isCustomMinutes
                                ? currentModeColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: _isCustomMinutes
                                ? [
                                    BoxShadow(
                                      color:
                                          currentModeColor.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _isCustomMinutes
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_isCustomMinutes) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentModeColor.withOpacity(0.4),
                        ),
                      ),
                      child: TextField(
                        controller: _customMinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter minutes (e.g. 90, 120)',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixText: 'min',
                          suffixStyle: TextStyle(color: Colors.grey),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, {
                        'plan': _selectedPlan,
                        'mode': _mode,
                        'minutes': _effectiveMinutes,
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              currentModeColor.withOpacity(0.8),
                              currentModeColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: currentModeColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}