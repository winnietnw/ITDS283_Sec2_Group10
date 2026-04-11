import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/header.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const AppHeader(),

            const Text("Insights & History",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 5),
                        FlSpot(2, 4),
                        FlSpot(3, 7),
                        FlSpot(4, 6),
                        FlSpot(5, 8),
                        FlSpot(6, 5),
                      ],
                      isCurved: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Your productivity peaks when you're feeling energetic and focused.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}