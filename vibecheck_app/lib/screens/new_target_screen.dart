import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../widgets/header.dart';
import '../data/goal_templates.dart';
import 'goal_detail_screen.dart';

class NewTargetScreen extends StatefulWidget {
  const NewTargetScreen({super.key});

  @override
  State<NewTargetScreen> createState() => _NewTargetScreenState();
}

class _NewTargetScreenState extends State<NewTargetScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const List<String> _orderedSections = [
    'Learning',
    'Work',
    'Interests',
    'Health',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = buildGoalTemplatesForCurrentMonth();
    final groupedGoals = <String, List<GoalTemplate>>{};

    for (final goal in goals) {
      groupedGoals.putIfAbsent(goal.classification, () => []);
      groupedGoals[goal.classification]!.add(goal);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Row(
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
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Goal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.unknown,
                      },
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _orderedSections.map((section) {
                          final items = groupedGoals[section] ?? [];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (items.isEmpty)
                                  const SizedBox.shrink()
                                else
                                  SizedBox(
                                    height: 140,
                                    child: ScrollConfiguration(
                                      behavior:
                                          const MaterialScrollBehavior()
                                              .copyWith(
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
                                        physics:
                                            const BouncingScrollPhysics(),
                                        itemCount: items.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final goal = items[index];

                                          return _GoalCard(
                                            goal: goal,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      GoalDetailScreen(
                                                    goal: goal,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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

class _GoalCard extends StatefulWidget {
  final GoalTemplate goal;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.onTap,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.97 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 121,
          height: 136,
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
          decoration: BoxDecoration(
            color: widget.goal.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.08 : 0.10),
                blurRadius: _pressed ? 8 : 12,
                offset: Offset(0, _pressed ? 2 : 4),
              ),
            ],
          ),
          child: Text(
            widget.goal.title,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.18,
              fontWeight: FontWeight.w600,
              color: widget.goal.accentColor,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}