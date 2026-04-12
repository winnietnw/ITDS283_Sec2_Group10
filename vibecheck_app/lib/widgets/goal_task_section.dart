import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/goal_templates.dart';
import '../services/goal_progress_service.dart';

class GoalTaskSection extends StatelessWidget {
  const GoalTaskSection({super.key});

  GoalTemplate? _findGoal(String id) {
    try {
      return buildGoalTemplatesForCurrentMonth()
          .firstWhere((goal) => goal.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: GoalProgressService.watchCurrentGoal(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data == null) return const SizedBox.shrink();

        final goalId = data['goalId']?.toString();
        final selectedDay = data['selectedDay'] as int? ?? 1;
        final completedDays =
            (data['completedDays'] as List<dynamic>? ?? []).map((e) => e as int).toList();

        if (goalId == null) return const SizedBox.shrink();

        final goal = _findGoal(goalId);
        if (goal == null) return const SizedBox.shrink();

        final plan = goal.monthlyPlans.firstWhere(
          (e) => e.day == selectedDay,
          orElse: () => goal.monthlyPlans.first,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Goal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: goal.accentColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                goal.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF273142),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Day $selectedDay of ${goal.monthlyPlans.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 14),

              ...plan.tasks.map(
                (task) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              if (completedDays.contains(selectedDay))
                const Text(
                  'This day has already been completed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}