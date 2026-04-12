import 'dart:math';
import 'package:flutter/material.dart';
import '../data/goal_templates.dart';

class CongratulationScreen extends StatelessWidget {
  final GoalTemplate goal;

  const CongratulationScreen({
    super.key,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/task',
            (route) => false,
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF171A37),
                Color(0xFF2A245A),
                Color(0xFF0D1026),
              ],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _StarField()),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFFFE38D),
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Congratulations!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You have successfully completed\n${goal.title}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Tap anywhere on the screen to return to Tasks',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    final random = Random(42);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(60, (index) {
            final x = random.nextDouble() * constraints.maxWidth;
            final y = random.nextDouble() * constraints.maxHeight;
            final size = random.nextDouble() * 3 + 1;

            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}