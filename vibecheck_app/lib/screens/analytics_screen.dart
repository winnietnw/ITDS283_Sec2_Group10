// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Productivity &\nMood Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            
            // กราฟ Trend (ใช้ fl_chart)
            const Text('Your Weekly Productivity Trend',
              style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const days = ['M','T','W','T','F','S','S'];
                          return Text(days[val.toInt() % 7]);
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true)),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3), FlSpot(1, 5), FlSpot(2, 4),
                        FlSpot(3, 7), FlSpot(4, 6), FlSpot(5, 8), FlSpot(6, 5),
                      ],
                      isCurved: true,
                      color: const Color(0xFF7B5EA7),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // AI Insights section (Advanced Feature — API call)
            const Text('Your Hidden Insight',
              style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _getAIInsight(user?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(snapshot.data ?? 'Loading insights...'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Advanced Feature: เรียก API ภายนอก (weather API)
  Future<String> _getAIInsight(String userId) async {
    // ดึง emotion data จาก Firestore แล้ว generate insight
    // (ตรงนี้เป็น placeholder, จะทำ full API ในส่วน Advanced Feature)
    await Future.delayed(const Duration(seconds: 1));
    return '📊 Based on your data this week, your productivity peaks on Thursdays. '
      'Your mood correlates 78% with task completion rate. '
      'Try scheduling important tasks in the morning!';
  }
}