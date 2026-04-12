import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/goal_templates.dart';

class GoalProgressService {
  static CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('goal_progress');

  static String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static Future<void> startGoal(GoalTemplate goal) async {
    final totalDays = goal.monthlyPlans.length;
    await _ref.doc('current_active').set({
      'goalId': goal.id,
      'title': goal.title,
      'classification': goal.classification,
      'colorValue': goal.color.value,
      'accentColorValue': goal.accentColor.value,
      'monthKey': monthKey(DateTime.now()),
      'totalDays': totalDays,
      'selectedDay': 1,
      'unlockedUntil': totalDays >= 3 ? 3 : totalDays,
      'completedDays': <int>[],
      'isCompleted': false,
      'startedAt': Timestamp.now(),
    });
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchCurrentGoal() {
    return _ref.doc('current_active').snapshots();
  }

  static Future<void> selectDay(int day) async {
    await _ref.doc('current_active').update({'selectedDay': day});
  }

  static Future<void> completeDay({
    required int day,
    required int totalDays,
  }) async {
    final doc = await _ref.doc('current_active').get();
    final data = doc.data();
    if (data == null) return;

    final List<dynamic> raw = (data['completedDays'] as List<dynamic>? ?? []);
    final completed = raw.map((e) => e as int).toSet();

    completed.add(day);

    int unlockedUntil = data['unlockedUntil'] as int? ?? 3;
    bool shouldUnlock = true;

    final blockEnd = (day / 3).ceil() * 3;
    final blockStart = blockEnd - 2;

    for (int i = blockStart; i <= blockEnd && i <= totalDays; i++) {
      if (!completed.contains(i)) {
        shouldUnlock = false;
        break;
      }
    }

    if (shouldUnlock) {
      unlockedUntil = blockEnd + 3;
      if (unlockedUntil > totalDays) unlockedUntil = totalDays;
    }

    final isCompleted = completed.length >= totalDays;

    await _ref.doc('current_active').update({
      'completedDays': completed.toList()..sort(),
      'unlockedUntil': unlockedUntil,
      'isCompleted': isCompleted,
    });
  }

  static Future<void> clearActiveGoal() async {
    await _ref.doc('current_active').delete();
  }
}