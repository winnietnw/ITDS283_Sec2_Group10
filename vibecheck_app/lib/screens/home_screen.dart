import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/header.dart';
import '../widgets/emotion_colors.dart';

class EmotionData {
  final String type;
  final DateTime time;

  EmotionData({
    required this.type,
    required this.time,
  });
}

class TaskData {
  final String id;
  final String title;
  final bool done;

  TaskData({
    required this.id,
    required this.title,
    required this.done,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;
  double _elapsed = 0.0;

  static const Map<String, String> _emojiMap = {
    "happy": "😊",
    "calm": "😌",
    "neutral": "😐",
    "stressed": "😰",
    "love": "🥰",
    "burnout": "🫠",
    "angry": "😡",
    "sad": "😭",
  };

  static const Set<String> _positiveSet = {"happy", "calm", "love"};
  static const Set<String> _negativeSet = {"angry", "sad", "burnout"};

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10000),
    )..repeat();

    _orbitController.addListener(() {
      final elapsed = _orbitController.lastElapsedDuration;
      setState(() {
        _elapsed = elapsed == null ? 0.0 : elapsed.inMilliseconds / 1000.0;
      });
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  DateTimeRange _currentWeekRange() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
    return DateTimeRange(start: start, end: end);
  }

  String _dateLabel(DateTimeRange range) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${months[range.start.month]} ${range.start.day} - ${months[range.end.month]} ${range.end.day}";
  }

  String _safeType(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return 'neutral';
    return text;
  }

  DateTime _safeDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }

  Future<void> _toggleTask(TaskData task) async {
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
      'done': !task.done,
    });
  }

  Future<void> _showAddTaskDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add Task',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter your task',
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5EA7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                await FirebaseFirestore.instance.collection('tasks').add({
                  'title': text,
                  'done': false,
                  'createdAt': Timestamp.now(),
                  'userId': FirebaseAuth.instance.currentUser?.uid,
                });

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekRange = _currentWeekRange();

    return Scaffold(
      backgroundColor: const Color(0xFFF7EDEF),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('emotions')
              .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('time',isGreaterThanOrEqualTo: Timestamp.fromDate(weekRange.start),)
              .where('time',isLessThanOrEqualTo: Timestamp.fromDate(weekRange.end),)
              .snapshots(),
          builder: (context, emotionSnapshot) {
            final emotionDocs = emotionSnapshot.data?.docs ?? [];

            final emotions = emotionDocs.map((doc) {
              final data = (doc.data() as Map<String, dynamic>? ?? {});
              return EmotionData(
                type: _safeType(data['type']),
                time: _safeDate(data['time']),
              );
            }).toList();

            final Map<String, int> emotionCount = {};
            for (final e in emotions) {
              emotionCount[e.type] = (emotionCount[e.type] ?? 0) + 1;
            }

            final sorted = emotionCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final total = emotions.length;

            int positive = 0;
            int neutral = 0;
            int negative = 0;

            emotionCount.forEach((key, value) {
              if (_positiveSet.contains(key)) {
                positive += value;
              } else if (_negativeSet.contains(key)) {
                negative += value;
              } else {
                neutral += value;
              }
            });

            final positivePct =
                total == 0 ? 0 : ((positive / total) * 100).round();
            final neutralPct =
                total == 0 ? 0 : ((neutral / total) * 100).round();
            final negativePct =
                total == 0 ? 0 : ((negative / total) * 100).round();

            final mostType = sorted.isNotEmpty ? sorted.first.key : 'neutral';
            final mostEmoji = _emojiMap[mostType] ?? "😐";

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, taskSnapshot) {
                final taskDocs = taskSnapshot.data?.docs ?? [];

                final tasks = taskDocs.map((doc) {
                  final data = (doc.data() as Map<String, dynamic>? ?? {});
                  return TaskData(
                    id: doc.id,
                    title:
                        (data['title']?.toString().trim().isNotEmpty ?? false)
                            ? data['title'].toString()
                            : 'Untitled Task',
                    done: data['done'] == true,
                  );
                }).toList();

                final todoTasks = tasks.where((t) => !t.done).toList();
                final doneTasks = tasks.where((t) => t.done).toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      snap: false,
                      elevation: 0,
                      backgroundColor: const Color(0xFFF7EDEF),
                      surfaceTintColor: Colors.transparent,
                      automaticallyImplyLeading: false,
                      toolbarHeight: 112,
                      flexibleSpace: const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: AppHeader(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            "Your Emotional Galaxy",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF273142),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dateLabel(weekRange),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8D8D8D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          /// ORBIT
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 22),
                            width: double.infinity,
                            height: 260,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F0FF),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _OrbitView(
                                emotions: sorted,
                                elapsed: _elapsed,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          /// GALAXY SUMMARY
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 22),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/analytics_emotion',
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.bar_chart_rounded,
                                        size: 16,
                                        color: Color(0xFFD7B8FF),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          "Galaxy Summary",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF273142),
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 20,
                                        color: Color(0xFF273142),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _HomeStatBox(
                                        value: "$total",
                                        label: "Emotions Logged",
                                        color: const Color(0x33FFD6E0),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _HomeStatBox(
                                        value: mostEmoji,
                                        label: "Most Common",
                                        color: const Color(0x33CDE7FF),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _SummaryLine(
                                  label: "Positive emotions",
                                  value: positivePct,
                                  color: const Color(0xFFC9EFD1),
                                ),
                                const SizedBox(height: 10),
                                _SummaryLine(
                                  label: "Neutral emotions",
                                  value: neutralPct,
                                  color: const Color(0xFFE3E3E3),
                                ),
                                const SizedBox(height: 10),
                                _SummaryLine(
                                  label: "Negative emotions",
                                  value: negativePct,
                                  color: const Color(0xFFF7BABA),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          /// TODAY / TASK PREVIEW
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 22),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "Today",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF273142),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _showAddTaskDialog,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF4FF),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 18,
                                          color: Color(0xFF7BA7FF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _dateLabel(weekRange),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8D8D8D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Tasks",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF273142),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (todoTasks.isEmpty && doneTasks.isEmpty)
                                  const _NoPlanBox()
                                else ...[
                                  if (todoTasks.isEmpty)
                                    const _NoPlanBox()
                                  else
                                    ...todoTasks.take(3).map(
                                      (task) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: _TaskRow(
                                          title: task.title,
                                          done: false,
                                          onTap: () => _toggleTask(task),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Completed",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF273142),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (doneTasks.isEmpty)
                                    const _NoPlanBox(
                                      text: "No completed plan",
                                    )
                                  else
                                    ...doneTasks.take(2).map(
                                      (task) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: _TaskRow(
                                          title: task.title,
                                          done: true,
                                          onTap: () => _toggleTask(task),
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _OrbitView extends StatelessWidget {
  final List<MapEntry<String, int>> emotions;
  final double elapsed;

  const _OrbitView({
    required this.emotions,
    required this.elapsed,
  });

  static const Map<String, String> emojiMap = {
    "happy": "😊",
    "calm": "😌",
    "neutral": "😐",
    "stressed": "😰",
    "love": "🥰",
    "burnout": "🫠",
    "angry": "😡",
    "sad": "😭",
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cx = constraints.maxWidth / 2;
        final double cy = constraints.maxHeight / 2;
        final double maxCount =
            emotions.isNotEmpty ? emotions.first.value.toDouble() : 1.0;

        const List<double> radii = [
          40,
          58,
          74,
          88,
          100,
          112,
          122,
          130
        ];
        const List<double> speeds = [
          0.8,
          0.55,
          0.38,
          0.28,
          0.22,
          0.17,
          0.13,
          0.10
        ];
        const List<double> phases = [0.0, 1.0, 2.1, 0.5, 1.8, 3.0, 0.9, 2.5];

        final visibleRadii =
            radii.take(emotions.length.clamp(0, radii.length)).toList();

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _AllRingsPainter(
                cx: cx,
                cy: cy,
                radii: visibleRadii,
              ),
            ),
            Positioned(
              left: cx - 20,
              top: cy - 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB347),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x55FFB347),
                      blurRadius: 14,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text("☀️", style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
            for (int i = 0; i < emotions.length && i < radii.length; i++)
              Builder(
                builder: (_) {
                  final entry = emotions[i];
                  final double ratio =
                      maxCount == 0 ? 0.0 : entry.value / maxCount;
                  final double size = 24.0 + (ratio * 18.0);
                  final double angle = (elapsed * speeds[i]) + phases[i];
                  final double r = radii[i];
                  final double px = cx + r * math.cos(angle) - size / 2;
                  final double py = cy + r * math.sin(angle) - size / 2;
                  final color = EmotionColors.get(entry.key);
                  final emoji = emojiMap[entry.key] ?? "😐";

                  return Positioned(
                    left: px,
                    top: py,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.45),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: size * 0.42),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (emotions.isEmpty)
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, 0.72),
                  child: Text(
                    "No emotions this week",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AllRingsPainter extends CustomPainter {
  final double cx;
  final double cy;
  final List<double> radii;

  const _AllRingsPainter({
    required this.cx,
    required this.cy,
    required this.radii,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final r in radii) {
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AllRingsPainter oldDelegate) {
    return oldDelegate.cx != cx ||
        oldDelegate.cy != cy ||
        oldDelegate.radii.length != radii.length;
  }
}

class _HomeStatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HomeStatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF273142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8D8D8D),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0, 100).toDouble() / 100.0;

    return Row(
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6D6D6D),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F1F1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            "$value%",
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6D6D6D),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onTap;

  const _TaskRow({
    required this.title,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color:
                  done ? const Color(0xFF7EDB95) : const Color(0xFFC5C5C5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A4A4A),
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoPlanBox extends StatelessWidget {
  final String text;

  const _NoPlanBox({
    this.text = "No plan",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9A9A9A),
        ),
      ),
    );
  }
}