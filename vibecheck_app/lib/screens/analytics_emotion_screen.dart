import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../widgets/header.dart';
import '../widgets/emotion_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class AnalyticsEmotionScreen extends StatefulWidget {
  const AnalyticsEmotionScreen({super.key});

  @override
  State<AnalyticsEmotionScreen> createState() => _AnalyticsEmotionScreenState();
}

class _AnalyticsEmotionScreenState extends State<AnalyticsEmotionScreen>
    with SingleTickerProviderStateMixin {
  int _weekOffset = 0;
  late final AnimationController _orbitController;
  double _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10000),
    )..forward();

    _orbitController.addListener(() {
      setState(() {
        _elapsed = _orbitController.lastElapsedDuration?.inMilliseconds != null
            ? _orbitController.lastElapsedDuration!.inMilliseconds / 1000.0
            : 0;
      });
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  DateTimeRange _weekRange(int offset) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(
      monday.year,
      monday.month,
      monday.day,
    ).add(Duration(days: offset * 7));
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
    return DateTimeRange(start: start, end: end);
  }

  String _weekLabel(int offset) {
    if (offset == 0) return "This Week's Galaxy";
    if (offset == -1) return "Last Week's Galaxy";
    return "${offset.abs()} Weeks Ago";
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
      'Dec',
    ];
    return "${months[range.start.month]} ${range.start.day} - "
        "${months[range.end.month]} ${range.end.day}";
  }

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

  static const Set<String> positiveSet = {"happy", "calm", "love"};
  static const Set<String> negativeSet = {"angry", "sad", "burnout"};

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _menuTile(
              Icons.share_outlined,
              "Share Galaxy",
              "Share your mood galaxy as an image",
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Share coming soon!")),
                );
              },
            ),
            _menuTile(
              Icons.delete_outline,
              "Clear This Week",
              "Remove all emotions logged this week",
              () {
                Navigator.pop(context);
                _confirmClear(context);
              },
            ),
            _menuTile(
              Icons.info_outline,
              "About Galaxy View",
              "Bubble size = how often you felt that emotion",
              () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      onTap: onTap,
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear This Week?"),
        content: const Text("This will delete all emotions logged this week."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final range = _weekRange(0);
              final snap = await FirebaseFirestore.instance
                  .collection('emotions')
                  .where(
                    'time',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
                  )
                  .where(
                    'time',
                    isLessThanOrEqualTo: Timestamp.fromDate(range.end),
                  )
                  .get();
              for (final doc in snap.docs) {
                await doc.reference.delete();
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _weekRange(_weekOffset);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF9),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          key: ValueKey(_weekOffset), // ✅ rebuild stream เมื่อ offset เปลี่ยน
          stream: FirebaseFirestore.instance
              .collection('emotions')
              .where(
                'time',
                isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
              )
              .where('time', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            Map<String, int> count = {};
            for (var d in docs) {
              final type =
                  (d.data() as Map<String, dynamic>)['type'] as String? ?? '';
              count[type] = (count[type] ?? 0) + 1;
            }

            final sorted = count.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final String mostType = sorted.isNotEmpty ? sorted.first.key : "-";
            final int mostCount = sorted.isNotEmpty ? sorted.first.value : 0;
            final double strongestScore = docs.isNotEmpty
                ? (mostCount / docs.length * 10)
                : 0;

            int pos = 0, neg = 0, neu = 0;
            count.forEach((k, v) {
              if (positiveSet.contains(k))
                pos += v;
              else if (negativeSet.contains(k))
                neg += v;
              else
                neu += v;
            });
            final total = docs.length;
            final posR = total > 0 ? pos / total : 0.0;
            final neuR = total > 0 ? neu / total : 0.0;
            final negR = total > 0 ? neg / total : 0.0;

            final Set<String> days = {};
            for (var d in docs) {
              final ts =
                  (d.data() as Map<String, dynamic>)['time'] as Timestamp?;
              if (ts != null) {
                final dt = ts.toDate();
                days.add("${dt.year}-${dt.month}-${dt.day}");
              }
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xFFE8EEF9),
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
                      const SizedBox(height: 16),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EEF9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      _weekLabel(_weekOffset),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _dateLabel(range),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => _showMenu(context),
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              height: 220,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  color: const Color(0xFFF5F0FF),
                                  child: _OrbitView(
                                    emotions: sorted,
                                    elapsed: _elapsed,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _weekOffset--),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(5, (i) {
                                  final dotOffset = -(4 - i);
                                  final isActive = dotOffset == _weekOffset;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _weekOffset = dotOffset),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      width: isActive ? 10 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFF7B7EF4)
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    if (_weekOffset < 0) {
                                      setState(() => _weekOffset++);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _weekOffset < 0
                                          ? Colors.grey.shade100
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: _weekOffset < 0
                                          ? Colors.black54
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Galaxy Summary",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _StatBox(
                                    value: "$total",
                                    label: "Emotions Logged",
                                    color: const Color(0xFFFFD6E0),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatBox(
                                    value: "${days.length}",
                                    label: "Days Tracked",
                                    color: const Color(0xFFD6E4FF),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            if (mostType != "-") ...[
                              _SummaryRow(
                                emoji: emojiMap[mostType] ?? "😊",
                                emojiColor: EmotionColors.get(mostType),
                                title: "Most Common",
                                subtitle: _cap(mostType),
                                value: "${mostCount}x",
                              ),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                icon: Icons.bolt,
                                iconColor: Colors.pink,
                                iconBgColor: const Color(0xFFFFD6E0),
                                title: "Strongest",
                                subtitle: _cap(mostType),
                                value: strongestScore.toStringAsFixed(1),
                              ),
                            ],

                            if (total > 0) ...[
                              const SizedBox(height: 12),
                              _BalanceBar(posR: posR, neuR: neuR, negR: negR),
                            ],

                            if (total == 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    "No emotions logged this week 🌟\nStart by tapping + Emotion!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }
}

// ── Orbit View ────────────────────────────────────────────────────────────────
class _OrbitView extends StatelessWidget {
  final List<MapEntry<String, int>> emotions;
  final double elapsed;

  const _OrbitView({required this.emotions, required this.elapsed});

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
        final cx = constraints.maxWidth / 2;
        final cy = constraints.maxHeight / 2;
        final maxCount = emotions.isNotEmpty
            ? emotions.first.value.toDouble()
            : 1;

        final List<double> radii = [55, 75, 92, 106, 118, 128, 136, 143];
        final List<double> speeds = [
          0.8,
          0.55,
          0.38,
          0.28,
          0.22,
          0.17,
          0.13,
          0.10,
        ];
        final List<double> phases = [0.0, 1.0, 2.1, 0.5, 1.8, 3.0, 0.9, 2.5];

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // orbit rings
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _AllRingsPainter(
                cx: cx,
                cy: cy,
                radii: radii.sublist(0, emotions.length.clamp(0, radii.length)),
              ),
            ),

            // sun
            Positioned(
              left: cx - 22,
              top: cy - 22,
              child: Container(
                width: 44,
                height: 44,
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
                  child: Text("☀️", style: TextStyle(fontSize: 22)),
                ),
              ),
            ),

            // planets
            for (int i = 0; i < emotions.length; i++)
              Builder(
                builder: (_) {
                  final entry = emotions[i];
                  final ratio = entry.value / maxCount;
                  final size = 28.0 + ratio * 22.0;
                  final angle = elapsed * speeds[i] + phases[i];
                  final r = radii[i];
                  final px = cx + r * cos(angle) - size / 2;
                  final py = cy + r * sin(angle) - size / 2;
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

            // empty state
            if (emotions.isEmpty)
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, 0.7),
                  child: Text(
                    "No emotions this week",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── All Rings Painter ─────────────────────────────────────────────────────────
class _AllRingsPainter extends CustomPainter {
  final double cx, cy;
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
  bool shouldRepaint(_AllRingsPainter old) =>
      old.cx != cx || old.cy != cy || old.radii.length != radii.length;
}

// ── Stat Box ──────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String? emoji;
  final Color? emojiColor;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final String subtitle;
  final String value;

  const _SummaryRow({
    this.emoji,
    this.emojiColor,
    this.icon,
    this.iconColor,
    this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: emojiColor ?? iconBgColor ?? Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: emoji != null
                  ? Text(emoji!, style: const TextStyle(fontSize: 18))
                  : Icon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ── Balance Bar ───────────────────────────────────────────────────────────────
class _BalanceBar extends StatelessWidget {
  final double posR, neuR, negR;

  const _BalanceBar({
    required this.posR,
    required this.neuR,
    required this.negR,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Emotional Balance",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if ((posR * 100).round() > 0)
                  Flexible(
                    flex: (posR * 100).round(),
                    child: Container(
                      height: 10,
                      color: const Color(0xFF81C784),
                    ),
                  ),
                if ((neuR * 100).round() > 0)
                  Flexible(
                    flex: (neuR * 100).round(),
                    child: Container(
                      height: 10,
                      color: const Color(0xFFFFD54F),
                    ),
                  ),
                if ((negR * 100).round() > 0)
                  Flexible(
                    flex: (negR * 100).round(),
                    child: Container(
                      height: 10,
                      color: const Color(0xFFE57373),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Lbl(
                "${(posR * 100).round()}% Positive",
                const Color(0xFF388E3C),
              ),
              _Lbl("${(neuR * 100).round()}% Neutral", const Color(0xFFF9A825)),
              _Lbl(
                "${(negR * 100).round()}% Negative",
                const Color(0xFFC62828),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Lbl extends StatelessWidget {
  final String text;
  final Color color;

  const _Lbl(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
    );
  }
}
