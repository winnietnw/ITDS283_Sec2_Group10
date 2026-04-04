// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../widgets/bottom_nav_bar.dart';
import 'task_screen.dart';
import 'timer_screen.dart';
import 'emotion_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // index ของ bottom nav
  
  // หน้าต่างๆ ที่แสดงตาม bottom nav
  final List<Widget> _screens = [
    const HomeContent(),
    const TaskScreen(),
    const TimerScreen(),
    const EmotionScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VibeCheck', 
                      style: TextStyle(fontSize: 20, 
                        fontWeight: FontWeight.bold)),
                    const Text('Where Mood Meets Metrics',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                // Profile icon
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Emotional Galaxy (วงกลมใหญ่ตรงกลาง)
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0533), Color(0xFF3D1C8D)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text('Your Emotional Galaxy',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                  // วงกลม emotion dots (จำลอง galaxy)
                  ...List.generate(8, (i) {
                    final angle = (i / 8) * 2 * pi;
                    final radius = 60.0 + (i % 3) * 20;
                    return Positioned(
                      left: 125 + radius * cos(angle),
                      top: 100 + radius * sin(angle),
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.5 + i * 0.05),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Galaxy Summary Card
            StreamBuilder<QuerySnapshot>(
              // ดึงข้อมูล emotion จาก Firebase realtime
              stream: FirebaseFirestore.instance
                .collection('emotions')
                .where('userId', isEqualTo: user?.uid)
                .snapshots(),
              builder: (context, snapshot) {
                int total = snapshot.data?.docs.length ?? 0;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Galaxy Summary',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('$total', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildProgressRow('Positive emotions', 0.6, Colors.green),
                      _buildProgressRow('Neutral emotions', 0.3, Colors.orange),
                      _buildProgressRow('Negative emotions', 0.1, Colors.red),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(flex: 3, child: Text(label, 
          style: const TextStyle(fontSize: 12))),
        Expanded(flex: 4, child: LinearProgressIndicator(
          value: value, 
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(color),
        )),
        const SizedBox(width: 8),
        Text('${(value * 100).toInt()}%', 
          style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}