import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'Week';
  late Future<_InsightData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData('Week');
  }

  Future<_InsightData> _loadData(String period) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();

    DateTime rangeStart;
    DateTime lastRangeStart;
    DateTime lastRangeEnd;

    if (period == 'Week') {
      final weekday = now.weekday;
      rangeStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: weekday - 1));
      lastRangeStart = rangeStart.subtract(const Duration(days: 7));
      lastRangeEnd = rangeStart;
    } else {
      rangeStart = DateTime(now.year, now.month, 1);
      lastRangeStart = DateTime(now.year, now.month - 1, 1);
      lastRangeEnd = rangeStart;
    }

    final emotionSnap = await FirebaseFirestore.instance
        .collection('emotions')
        .where('userId', isEqualTo: uid)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .get();

    final lastEmotionSnap = await FirebaseFirestore.instance
        .collection('emotions')
        .where('userId', isEqualTo: uid)
        .where('time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(lastRangeStart))
        .where('time', isLessThan: Timestamp.fromDate(lastRangeEnd))
        .get();

    final taskSnap = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .get();

    final lastTaskSnap = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(lastRangeStart))
        .where('createdAt', isLessThan: Timestamp.fromDate(lastRangeEnd))
        .get();

    final sessionSnap = await FirebaseFirestore.instance
        .collection('timer_sessions')
        .where('userId', isEqualTo: uid)
        .where('completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .get();

    final lastSessionSnap = await FirebaseFirestore.instance
        .collection('timer_sessions')
        .where('userId', isEqualTo: uid)
        .where('completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(lastRangeStart))
        .where('completedAt', isLessThan: Timestamp.fromDate(lastRangeEnd))
        .get();

    final emotions = emotionSnap.docs.map((d) => d.data()).toList();
    final lastEmotions = lastEmotionSnap.docs.map((d) => d.data()).toList();
    final tasks = taskSnap.docs.map((d) => d.data()).toList();
    final lastTasks = lastTaskSnap.docs.map((d) => d.data()).toList();
    final sessions = sessionSnap.docs.map((d) => d.data()).toList();
    final lastSessions =
        lastSessionSnap.docs.map((d) => d.data()).toList();

    const positiveSet = {'happy', 'calm', 'love'};
    const negativeSet = {'angry', 'sad', 'burnout'};

    // tasks
    final completedTasks =
        tasks.where((t) => t['isCompleted'] == true).length;
    final lastCompletedTasks =
        lastTasks.where((t) => t['isCompleted'] == true).length;
    final taskDiff = lastCompletedTasks == 0
        ? (completedTasks > 0 ? 100 : 0)
        : (((completedTasks - lastCompletedTasks) / lastCompletedTasks) * 100)
            .round();

    // focus time
    final totalMinutes = sessions.fold<int>(
        0, (s, e) => s + ((e['minutes'] as int?) ?? 0));
    final lastTotalMinutes = lastSessions.fold<int>(
        0, (s, e) => s + ((e['minutes'] as int?) ?? 0));
    final focusHours = totalMinutes / 60;
    final focusDiff = lastTotalMinutes == 0
        ? (totalMinutes > 0 ? 100 : 0)
        : (((totalMinutes - lastTotalMinutes) / lastTotalMinutes) * 100)
            .round();

    // avg productivity
    final totalTasks = tasks.length;
    final avgProductivity =
        totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 10;
    final lastTotalTasks = lastTasks.length;
    final lastAvgProductivity = lastTotalTasks == 0
        ? 0.0
        : (lastCompletedTasks / lastTotalTasks) * 10;
    final productivityDiff = lastAvgProductivity == 0
        ? (avgProductivity > 0 ? 100 : 0)
        : (((avgProductivity - lastAvgProductivity) / lastAvgProductivity) *
                100)
            .round();

    // goal achievement
    final goalAchievement = totalTasks == 0
        ? 0
        : ((completedTasks / totalTasks) * 100).round();
    final lastGoalAchievement = lastTotalTasks == 0
        ? 0
        : ((lastCompletedTasks / lastTotalTasks) * 100).round();
    final goalDiff = goalAchievement - lastGoalAchievement;

    // emotion count
    final Map<String, int> emotionCount = {};
    for (final e in emotions) {
      final t = e['type'] as String? ?? 'neutral';
      emotionCount[t] = (emotionCount[t] ?? 0) + 1;
    }

    String mostCommonMood = 'neutral';
    int mostCommonCount = 0;
    emotionCount.forEach((k, v) {
      if (v > mostCommonCount) {
        mostCommonCount = v;
        mostCommonMood = k;
      }
    });

    // chart spots
    List<FlSpot> chartSpots = [];
    if (period == 'Week') {
      final Map<int, int> tasksByDay = {
        0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0
      };
      for (final t in tasks) {
        if (t['isCompleted'] != true) continue;
        final createdAt = (t['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) continue;
        final dayIndex = createdAt.weekday - 1;
        tasksByDay[dayIndex] = (tasksByDay[dayIndex] ?? 0) + 1;
      }
      for (int i = 0; i <= 6; i++) {
        final count = tasksByDay[i] ?? 0;
        if (count > 0) chartSpots.add(FlSpot(i.toDouble(), count.toDouble()));
      }
    } else {
      final Map<int, int> tasksByWeek = {0: 0, 1: 0, 2: 0, 3: 0};
      for (final t in tasks) {
        if (t['isCompleted'] != true) continue;
        final createdAt = (t['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) continue;
        final weekIndex = ((createdAt.day - 1) / 7).floor().clamp(0, 3);
        tasksByWeek[weekIndex] = (tasksByWeek[weekIndex] ?? 0) + 1;
      }
      for (int i = 0; i <= 3; i++) {
        final count = tasksByWeek[i] ?? 0;
        if (count > 0) chartSpots.add(FlSpot(i.toDouble(), count.toDouble()));
      }
    }

    // Pearson Correlation
    final Map<String, double> moodScoreByDay = {};
    final Map<String, int> tasksByDayAll = {};

    for (final e in emotions) {
      final time = (e['time'] as Timestamp?)?.toDate();
      if (time == null) continue;
      final key = '${time.year}-${time.month}-${time.day}';
      final type = e['type'] as String? ?? 'neutral';
      final score =
          positiveSet.contains(type) ? 3.0 : negativeSet.contains(type) ? 1.0 : 2.0;
      if (moodScoreByDay.containsKey(key)) {
        moodScoreByDay[key] = (moodScoreByDay[key]! + score) / 2;
      } else {
        moodScoreByDay[key] = score;
      }
    }

    for (final t in tasks) {
      if (t['isCompleted'] != true) continue;
      final createdAt = (t['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) continue;
      final key =
          '${createdAt.year}-${createdAt.month}-${createdAt.day}';
      tasksByDayAll[key] = (tasksByDayAll[key] ?? 0) + 1;
    }

    final commonDays = moodScoreByDay.keys
        .where((k) => tasksByDayAll.containsKey(k))
        .toList();

    double pearsonR = 0;
    if (commonDays.length >= 2) {
      final xList = commonDays.map((k) => moodScoreByDay[k]!).toList();
      final yList =
          commonDays.map((k) => tasksByDayAll[k]!.toDouble()).toList();
      pearsonR = _pearson(xList, yList);
    }

    // Most productive mood
    final Map<String, int> moodTaskCompletion = {};
    for (final t in tasks) {
      if (t['isCompleted'] != true) continue;
      final createdAt = (t['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) continue;
      final sameDay = emotions.where((e) {
        final eTime = (e['time'] as Timestamp?)?.toDate();
        if (eTime == null) return false;
        return eTime.year == createdAt.year &&
            eTime.month == createdAt.month &&
            eTime.day == createdAt.day;
      });
      for (final e in sameDay) {
        final type = e['type'] as String? ?? 'neutral';
        moodTaskCompletion[type] = (moodTaskCompletion[type] ?? 0) + 1;
      }
    }

    String mostProductiveMood = mostCommonMood;
    int bestMoodCount = 0;
    moodTaskCompletion.forEach((k, v) {
      if (v > bestMoodCount) {
        bestMoodCount = v;
        mostProductiveMood = k;
      }
    });

    final moodTotal = emotionCount[mostProductiveMood] ?? 1;
    final moodProductivityRate =
        ((moodTaskCompletion[mostProductiveMood] ?? 0) / moodTotal * 100)
            .round()
            .clamp(0, 100);

    // Peak time
    final Map<int, int> minutesByHour = {};
    for (final s in sessions) {
      final completedAt = (s['completedAt'] as Timestamp?)?.toDate();
      if (completedAt == null) continue;
      final hour = completedAt.hour;
      minutesByHour[hour] =
          (minutesByHour[hour] ?? 0) + ((s['minutes'] as int?) ?? 0);
    }
    int peakHour = 9;
    int peakMinutes = 0;
    minutesByHour.forEach((h, m) {
      if (m > peakMinutes) {
        peakMinutes = m;
        peakHour = h;
      }
    });
    final peakStart =
        '${peakHour.toString().padLeft(2, '0')}:00 ${peakHour < 12 ? 'AM' : 'PM'}';
    final peakEnd =
        '${(peakHour + 2).toString().padLeft(2, '0')}:00 ${(peakHour + 2) < 12 ? 'AM' : 'PM'}';
    final peakPerformance = totalMinutes == 0
        ? 0
        : ((peakMinutes / totalMinutes) * 100).round().clamp(0, 100);

    // ── Weather × Mood correlation ──
    // นับว่าแต่ละ weather condition มี mood อะไรบ้าง
    final Map<String, Map<String, int>> weatherMoodMap = {};
    for (final e in emotions) {
      final condition = e['weatherCondition'] as String?;
      if (condition == null || condition.isEmpty) continue;
      final type = e['type'] as String? ?? 'neutral';
      weatherMoodMap[condition] ??= {};
      weatherMoodMap[condition]![type] =
          (weatherMoodMap[condition]![type] ?? 0) + 1;
    }

    // หา dominant mood ของแต่ละ condition
    final Map<String, String> weatherDominantMood = {};
    final Map<String, int> weatherEntryCount = {};
    weatherMoodMap.forEach((condition, moodCounts) {
      String dominant = 'neutral';
      int max = 0;
      moodCounts.forEach((mood, count) {
        if (count > max) {
          max = count;
          dominant = mood;
        }
      });
      weatherDominantMood[condition] = dominant;
      weatherEntryCount[condition] =
          moodCounts.values.fold(0, (a, b) => a + b);
    });

    return _InsightData(
      period: period,
      chartSpots: chartSpots,
      pearsonR: pearsonR.isNaN ? 0.0 : pearsonR,
      correlationDays: commonDays.length,
      mostProductiveMood: mostProductiveMood,
      moodProductivityRate: moodProductivityRate,
      peakStart: peakStart,
      peakEnd: peakEnd,
      peakPerformance: peakPerformance,
      avgProductivity: avgProductivity,
      productivityDiff: productivityDiff,
      completedTasks: completedTasks,
      taskDiff: taskDiff,
      focusHours: focusHours,
      focusDiff: focusDiff,
      goalAchievement: goalAchievement,
      goalDiff: goalDiff,
      hasData: emotions.isNotEmpty || tasks.isNotEmpty,
      weatherDominantMood: weatherDominantMood,
      weatherEntryCount: weatherEntryCount,
    );
  }

  static double _pearson(List<double> x, List<double> y) {
    final n = x.length;
    if (n < 2) return 0;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;
    double num = 0, denX = 0, denY = 0;
    for (int i = 0; i < n; i++) {
      num += (x[i] - meanX) * (y[i] - meanY);
      denX += pow(x[i] - meanX, 2);
      denY += pow(y[i] - meanY, 2);
    }
    final den = sqrt(denX * denY);
    return den == 0 ? 0 : (num / den).clamp(-1.0, 1.0);
  }

  static Map<String, dynamic> _correlationInfo(
      double r, int days, String mood) {
    if (days < 2) {
      return {
        'label': 'Not enough data yet',
        'emoji': '📊',
        'color': Colors.grey,
        'desc':
            'Log emotions and complete tasks for at least 2 days to see your correlation analysis.',
      };
    }
    if (r >= 0.7) {
      return {
        'label': 'Strong positive link',
        'emoji': '🔥',
        'color': const Color(0xFF7B5EA7),
        'desc':
            'When you feel ${_moodLabel(mood)}, you complete significantly more tasks. '
                'Your mood is a strong productivity driver — harness it!',
      };
    } else if (r >= 0.4) {
      return {
        'label': 'Moderate positive link',
        'emoji': '✨',
        'color': const Color(0xFF4CAF50),
        'desc': 'Your mood positively influences your productivity. '
            'On days you feel ${_moodLabel(mood)}, you tend to get more done.',
      };
    } else if (r >= 0.1) {
      return {
        'label': 'Weak positive link',
        'emoji': '🤔',
        'color': Colors.orange,
        'desc':
            'There\'s a slight connection between your mood and productivity. '
                'Try tracking more days for a clearer pattern.',
      };
    } else if (r >= -0.1) {
      return {
        'label': 'No clear link',
        'emoji': '😐',
        'color': Colors.grey,
        'desc': 'Your productivity seems independent of mood right now. '
            'Keep logging to discover patterns over time.',
      };
    } else {
      return {
        'label': 'Negative correlation',
        'emoji': '😮',
        'color': Colors.red,
        'desc':
            'Interestingly, you tend to complete more tasks on lower-mood days. '
                'You might work well under pressure!',
      };
    }
  }

  static String _moodLabel(String type) {
    const map = {
      'happy': 'Happy',
      'calm': 'Calm',
      'neutral': 'Neutral',
      'stressed': 'Stressed',
      'love': 'Loving',
      'burnout': 'Burnt out',
      'angry': 'Angry',
      'sad': 'Sad',
    };
    return map[type] ?? type;
  }

  static String _moodEmoji(String type) {
    const map = {
      'happy': '😊', 'calm': '😌', 'neutral': '😐',
      'stressed': '😰', 'love': '🥰',
      'burnout': '🫠', 'angry': '😡', 'sad': '😭',
    };
    return map[type] ?? '😐';
  }

  static Color _moodBgColor(String type) {
    const map = {
      'happy': Color(0xFFFFF9C4), 'calm': Color(0xFFE0F7FA),
      'neutral': Color(0xFFF5F5F5), 'stressed': Color(0xFFFFECB3),
      'love': Color(0xFFFFCDD2), 'burnout': Color(0xFFFFCCBC),
      'angry': Color(0xFFFFCDD2), 'sad': Color(0xFFE3F2FD),
    };
    return map[type] ?? const Color(0xFFF5F5F5);
  }

  static String _weatherEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':        return '☀️';
      case 'clouds':       return '☁️';
      case 'rain':         return '🌧️';
      case 'drizzle':      return '🌦️';
      case 'thunderstorm': return '⛈️';
      case 'snow':         return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':         return '🌫️';
      default:             return '🌤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFFDF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  const Expanded(
                    child: Center(
                      child: Text('Insights & History',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<_InsightData>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF7B5EA7)));
                  }
                  if (snap.hasError || !snap.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Error: ${snap.error}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.red),
                            textAlign: TextAlign.center),
                      ),
                    );
                  }
                  return _buildContent(snap.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(_InsightData d) {
    final isWeek = _period == 'Week';
    final xLabels = isWeek
        ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : ['Wk1', 'Wk2', 'Wk3', 'Wk4'];
    final corrInfo =
        _correlationInfo(d.pearsonR, d.correlationDays, d.mostProductiveMood);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(27, 0, 27, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 9),

          // ════════════════════════════════════════
          // BLOCK 1: Productivity & Mood Analytics
          // ════════════════════════════════════════
          _OuterBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text('Productivity\n& Mood\nAnalytics',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.35)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['Week', 'Month'].map((p) {
                          final isSelected = _period == p;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _period = p;
                              _future = _loadData(p);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.07),
                                            blurRadius: 8)
                                      ]
                                    : [],
                              ),
                              child: Text(p,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.black87
                                        : Colors.grey,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  isWeek
                      ? 'This Week Productivity Trend'
                      : 'This Month Productivity Trend',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: d.chartSpots.isEmpty
                      ? Center(
                          child: Text(
                              'Complete tasks to see your trend',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13)))
                      : LineChart(LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) => FlLine(
                                color: Colors.grey.shade200,
                                strokeWidth: 1),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= xLabels.length)
                                    return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(xLabels[i],
                                        style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey)),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (v, _) {
                                  if (v == v.floorToDouble()) {
                                    return Text(
                                      v.toInt().toString(),
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: d.chartSpots,
                              isCurved: true,
                              color: const Color(0xFF7B5EA7),
                              barWidth: 2.5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (_, __, ___, ____) =>
                                    FlDotCirclePainter(
                                  radius: 3,
                                  color: const Color(0xFF7B5EA7),
                                  strokeWidth: 0,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF7B5EA7)
                                    .withOpacity(0.08),
                              ),
                            ),
                          ],
                          minY: 0,
                        )),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            const Color(0xFF7B5EA7).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B5EA7)
                                  .withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 15,
                                color: Color(0xFF7B5EA7)),
                          ),
                          const SizedBox(width: 8),
                          const Text('Your Pattern Insight',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7B5EA7))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(corrInfo['emoji'] as String,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      corrInfo['label'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            corrInfo['color'] as Color,
                                      ),
                                    ),
                                    if (d.correlationDays >= 2)
                                      Text(
                                        'r = ${d.pearsonR.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: corrInfo['color']
                                              as Color,
                                        ),
                                      ),
                                  ],
                                ),
                                if (d.correlationDays >= 2) ...[
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ((d.pearsonR + 1) / 2)
                                          .clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor:
                                          Colors.grey.shade200,
                                      valueColor:
                                          AlwaysStoppedAnimation(
                                              corrInfo['color']
                                                  as Color),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text('-1',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey)),
                                      Text('0',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey)),
                                      Text('+1',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        corrInfo['desc'] as String,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ════════════════════════════════════════
          // BLOCK 2: Most Productive Mood
          // ════════════════════════════════════════
          _OuterBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Most Productive Mood',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _moodBgColor(d.mostProductiveMood),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                            _moodEmoji(d.mostProductiveMood),
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_moodLabel(d.mostProductiveMood),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${d.moodProductivityRate}%',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF7B5EA7))),
                            const SizedBox(width: 6),
                            const Text('productivity rate',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _moodBgColor(d.mostProductiveMood)
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "When you're feeling ${_moodLabel(d.mostProductiveMood).toLowerCase()}, "
                    "your productivity soars! This mood helps you tackle tasks with creativity and focus.",
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ════════════════════════════════════════
          // BLOCK 3: Peak Productive Time
          // ════════════════════════════════════════
          _OuterBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Peak Productive Time',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.access_time_rounded,
                          color: Color(0xFF1565C0), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${d.peakStart} - ${d.peakEnd}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${d.peakPerformance}%',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1565C0))),
                            const SizedBox(width: 6),
                            const Text('peak performance',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    d.peakPerformance > 0
                        ? 'Your brain is sharpest around ${d.peakStart}! '
                            'Schedule your most important tasks during this golden window.'
                        : 'Complete more focus sessions to discover your peak productive time.',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ════════════════════════════════════════
          // BLOCK 4: Weather × Mood Insight
          // ════════════════════════════════════════
          _OuterBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child:
                            Text('🌤️', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Weather & Mood',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'How different weather affects your emotions',
                  style:
                      TextStyle(fontSize: 12, color: Color(0xFF8D8D8D)),
                ),
                const SizedBox(height: 16),

                // ถ้ายังไม่มีข้อมูล weather
                if (d.weatherDominantMood.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: const [
                        Text('🌍', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text(
                          'No weather data yet',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Log your mood while location is enabled\nto see how weather affects you',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                              height: 1.5),
                        ),
                      ],
                    ),
                  )
                else
                  // แสดง weather condition แต่ละอัน
                  ...d.weatherDominantMood.entries.map((entry) {
                    final condition = entry.key;
                    final mood = entry.value;
                    final count =
                        d.weatherEntryCount[condition] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _moodBgColor(mood).withOpacity(0.45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Text(_weatherEmoji(condition),
                                style:
                                    const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    condition,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'You tend to feel ${_moodLabel(mood).toLowerCase()}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(_moodEmoji(mood),
                                    style: const TextStyle(
                                        fontSize: 20)),
                                Text(
                                  '$count log${count > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black38),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ════════════════════════════════════════
          // BLOCK 5: Weekly Summary
          // ════════════════════════════════════════
          _OuterBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly Summary',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _SummaryCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFFE91E63),
                      bgColor: const Color(0xFFFCE4EC),
                      diff: d.productivityDiff,
                      value: d.avgProductivity.toStringAsFixed(1),
                      label: 'Avg\nProductivity',
                    ),
                    _SummaryCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF4CAF50),
                      bgColor: const Color(0xFFE8F5E9),
                      diff: d.taskDiff,
                      value: '${d.completedTasks}',
                      label: 'Tasks\nCompleted',
                    ),
                    _SummaryCard(
                      icon: Icons.psychology_outlined,
                      iconColor: const Color(0xFF7B5EA7),
                      bgColor: const Color(0xFFF3E5F5),
                      diff: d.focusDiff,
                      value: '${d.focusHours.toStringAsFixed(1)}h',
                      label: 'Focus Time',
                    ),
                    _SummaryCard(
                      icon: Icons.emoji_events_outlined,
                      iconColor: const Color(0xFF1565C0),
                      bgColor: const Color(0xFFE3F2FD),
                      diff: d.goalDiff,
                      value: '${d.goalAchievement}%',
                      label: 'Goal\nAchievement',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.amber.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Great Progress!',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              d.hasData
                                  ? "You're improving across most metrics. "
                                      "Keep focusing on maintaining your routine for continued success."
                                  : "Start logging emotions and completing tasks to track your progress here!",
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.5),
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
        ],
      ),
    );
  }
}

// ─── Outer Block ──────────────────────────────────────────────────────────────
class _OuterBlock extends StatelessWidget {
  final Widget child;
  const _OuterBlock({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final int diff;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.diff,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = diff >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}$diff%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPositive
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.3)),
        ],
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────
class _InsightData {
  final String period;
  final List<FlSpot> chartSpots;
  final double pearsonR;
  final int correlationDays;
  final String mostProductiveMood;
  final int moodProductivityRate;
  final String peakStart;
  final String peakEnd;
  final int peakPerformance;
  final double avgProductivity;
  final int productivityDiff;
  final int completedTasks;
  final int taskDiff;
  final double focusHours;
  final int focusDiff;
  final int goalAchievement;
  final int goalDiff;
  final bool hasData;
  final Map<String, String> weatherDominantMood;
  final Map<String, int> weatherEntryCount;

  const _InsightData({
    required this.period,
    required this.chartSpots,
    required this.pearsonR,
    required this.correlationDays,
    required this.mostProductiveMood,
    required this.moodProductivityRate,
    required this.peakStart,
    required this.peakEnd,
    required this.peakPerformance,
    required this.avgProductivity,
    required this.productivityDiff,
    required this.completedTasks,
    required this.taskDiff,
    required this.focusHours,
    required this.focusDiff,
    required this.goalAchievement,
    required this.goalDiff,
    required this.hasData,
    required this.weatherDominantMood,
    required this.weatherEntryCount,
  });
}