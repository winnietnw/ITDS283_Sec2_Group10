import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../data/goal_templates.dart';
import '../widgets/header.dart';
import '../widgets/animated_action_button.dart';
import '../services/goal_progress_service.dart';
import 'goal_progress_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  final GoalTemplate goal;

  const GoalDetailScreen({
    super.key,
    required this.goal,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  int selectedDay = 1;
  static const int previewUnlockedUntil = 3;

  @override
  Widget build(BuildContext context) {
    final plans = widget.goal.monthlyPlans;

    return Scaffold(
      backgroundColor: widget.goal.color,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedActionButton(
        text: 'Start this goal',
        icon: Icons.play_arrow,
        onTap: () async {
          await GoalProgressService.startGoal(widget.goal);
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GoalProgressScreen(goal: widget.goal),
            ),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                physics: const BouncingScrollPhysics(),
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 40,
                          child: Icon(
                            Icons.arrow_back,
                            size: 24,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.goal.title,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: widget.goal.accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    height: 210,
                    decoration: BoxDecoration(
                      color: widget.goal.color,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: CustomPaint(
                        painter: _GoalSkyPainter(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F5EA),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Plan Template',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          height: 50,
                          child: ScrollConfiguration(
                            behavior:
                                const MaterialScrollBehavior().copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                                PointerDeviceKind.stylus,
                                PointerDeviceKind.unknown,
                              },
                            ),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(right: 8),
                              itemCount: plans.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final day = index + 1;
                                final selected = day == selectedDay;
                                final locked = day > previewUnlockedUntil;

                                return GestureDetector(
                                  onTap: locked
                                      ? null
                                      : () {
                                          setState(() => selectedDay = day);
                                        },
                                  child: Container(
                                    width: 58,
                                    decoration: BoxDecoration(
                                      color: locked
                                          ? Colors.grey.shade100
                                          : selected
                                              ? widget.goal.color
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected
                                            ? widget.goal.accentColor
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Center(
                                      child: locked
                                          ? Icon(
                                              Icons.lock_outline,
                                              size: 18,
                                              color: Colors.grey.shade500,
                                            )
                                          : Text(
                                              'Day\n$day',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.2,
                                                fontWeight: FontWeight.w700,
                                                color: widget.goal.accentColor,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        ..._buildGuideCards(
                          plans: plans,
                          selectedDay: selectedDay,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGuideCards({
    required List<GoalDayPlan> plans,
    required int selectedDay,
  }) {
    final startIndex = selectedDay - 1;
    final visiblePlans = plans.skip(startIndex).take(4).toList();

    return visiblePlans.asMap().entries.map((entry) {
      final index = entry.key;
      final plan = entry.value;

      final Color stripColor =
          index == 0 ? const Color(0xFFF05A5A) : const Color(0xFF8E6CE3);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _GuideCard(
          stripColor: stripColor,
          title: plan.title,
          subtitle: plan.subtitle,
          tasks: plan.tasks,
        ),
      );
    }).toList();
  }
}

class _GuideCard extends StatelessWidget {
  final Color stripColor;
  final String title;
  final String subtitle;
  final List<String> tasks;

  const _GuideCard({
    required this.stripColor,
    required this.title,
    required this.subtitle,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 86,
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...tasks.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${entry.key + 1}. ${entry.value}',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF6FA8FF),
          Color(0xFF9ED0FF),
          Color(0xFFDCEEFF),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, skyPaint);

    final Offset moonCenter = Offset(size.width * 0.82, size.height * 0.18);
    final Paint moonGlow = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(moonCenter, 26, moonGlow);

    final Paint moonPaint = Paint()..color = const Color(0xFFFFF7D6);
    canvas.drawCircle(moonCenter, 16, moonPaint);

    final Random rand = Random(77);

    for (int i = 0; i < 38; i++) {
      final double dx = rand.nextDouble() * size.width;
      final double dy = rand.nextDouble() * (size.height * 0.48);
      final double r = rand.nextDouble() * 1.8 + 0.7;

      final Paint glow = Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final Paint star = Paint()..color = Colors.white.withOpacity(0.92);

      canvas.drawCircle(Offset(dx, dy), r + 2, glow);
      canvas.drawCircle(Offset(dx, dy), r, star);
    }

    void drawSparkle(Offset c, double s) {
      final Paint p = Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(c.dx - s, c.dy), Offset(c.dx + s, c.dy), p);
      canvas.drawLine(Offset(c.dx, c.dy - s), Offset(c.dx, c.dy + s), p);
    }

    drawSparkle(Offset(size.width * 0.18, size.height * 0.16), 4);
    drawSparkle(Offset(size.width * 0.42, size.height * 0.22), 3.5);
    drawSparkle(Offset(size.width * 0.63, size.height * 0.14), 4.5);

    final Paint backMountain = Paint()..color = const Color(0xFF8CA8C9);
    final Path backPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width * 0.16, size.height * 0.44)
      ..lineTo(size.width * 0.30, size.height * 0.66)
      ..lineTo(size.width * 0.48, size.height * 0.36)
      ..lineTo(size.width * 0.64, size.height * 0.62)
      ..lineTo(size.width * 0.86, size.height * 0.24)
      ..lineTo(size.width, size.height * 0.54)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backPath, backMountain);

    final Paint frontMountain = Paint()..color = const Color(0xFF6F87A8);
    final Path frontPath = Path()
      ..moveTo(0, size.height * 0.80)
      ..lineTo(size.width * 0.12, size.height * 0.56)
      ..lineTo(size.width * 0.22, size.height * 0.72)
      ..lineTo(size.width * 0.38, size.height * 0.46)
      ..lineTo(size.width * 0.52, size.height * 0.70)
      ..lineTo(size.width * 0.68, size.height * 0.40)
      ..lineTo(size.width * 0.82, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.48)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontPath, frontMountain);

    final Paint snowPaint = Paint()..color = const Color(0xFFF7FBFF);

    final Path cap1 = Path()
      ..moveTo(size.width * 0.34, size.height * 0.52)
      ..lineTo(size.width * 0.38, size.height * 0.46)
      ..lineTo(size.width * 0.42, size.height * 0.52)
      ..lineTo(size.width * 0.39, size.height * 0.51)
      ..lineTo(size.width * 0.37, size.height * 0.55)
      ..close();

    final Path cap2 = Path()
      ..moveTo(size.width * 0.64, size.height * 0.46)
      ..lineTo(size.width * 0.68, size.height * 0.40)
      ..lineTo(size.width * 0.72, size.height * 0.46)
      ..lineTo(size.width * 0.69, size.height * 0.45)
      ..lineTo(size.width * 0.67, size.height * 0.49)
      ..close();

    canvas.drawPath(cap1, snowPaint);
    canvas.drawPath(cap2, snowPaint);

    final Paint groundPaint = Paint()..color = const Color(0xFFEAE8D8);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      groundPaint,
    );

    final Paint polePaint = Paint()
      ..color = const Color(0xFF784421)
      ..strokeWidth = 2;

    void drawFlag(double x, double y) {
      canvas.drawLine(Offset(x, y), Offset(x, y - 20), polePaint);

      final Path flag = Path()
        ..moveTo(x, y - 20)
        ..lineTo(x + 12, y - 20)
        ..lineTo(x + 7, y - 14)
        ..lineTo(x + 12, y - 8)
        ..lineTo(x, y - 8)
        ..close();

      final Paint flagPaint = Paint()..color = const Color(0xFFFF6B6B);

      canvas.drawPath(flag, flagPaint);
    }

    drawFlag(size.width * 0.12, size.height * 0.56);
    drawFlag(size.width * 0.38, size.height * 0.46);
    drawFlag(size.width * 0.68, size.height * 0.40);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}