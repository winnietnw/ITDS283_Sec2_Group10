import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/header.dart';
import '../widgets/emotion_colors.dart';
import 'analytics_emotion_screen.dart';
import '../services/weather_service.dart';

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen> {
  String selected = "";
  bool _checked = false;
  bool _alreadySaved = false;

  final List<Map<String, String>> moods = const [
    {"type": "happy", "emoji": "😊", "label": "Happy"},
    {"type": "calm", "emoji": "😌", "label": "Calm"},
    {"type": "neutral", "emoji": "😐", "label": "Neutral"},
    {"type": "stressed", "emoji": "😰", "label": "Stressed"},
    {"type": "love", "emoji": "🥰", "label": "Love"},
    {"type": "burnout", "emoji": "🫠", "label": "Burn out"},
    {"type": "angry", "emoji": "😡", "label": "Angry"},
    {"type": "sad", "emoji": "😭", "label": "Sad"},
  ];

  @override
  void initState() {
    super.initState();
    _checkTodayEmotion();
  }

  // เช็คว่าวันนี้บันทึก emotion แล้วยัง
  Future<void> _checkTodayEmotion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await FirebaseFirestore.instance
        .collection('emotions')
        .where('userId', isEqualTo: uid)
        .where('time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (!mounted) return;

    // ถ้าบันทึกแล้ววันนี้ → แสดงหน้า analytics_emotion แทน ไม่ต้อง navigate
    if (snap.docs.isNotEmpty) {
      setState(() {
        _checked = true;
        _alreadySaved = true; // เพิ่ม flag นี้
      });
    } else {
      setState(() => _checked = true);
    }
  }

  Future<void> saveEmotion() async {
    if (selected.isEmpty) return;

    final weather = await WeatherService.fetchWeather();

    await FirebaseFirestore.instance.collection('emotions').add({
      "type": selected,
      "time": Timestamp.now(),
      "userId": FirebaseAuth.instance.currentUser?.uid,
      "weatherCondition": weather?.condition,
      "weatherTemp": weather?.tempCelsius,
      "weatherCity": weather?.city,
    });

    if (!mounted) return;
    setState(() => _alreadySaved = true);
  }

  @override
  Widget build(BuildContext context) {
    // ระหว่างเช็ค แสดง loading
    if (!_checked) {
      return const Scaffold(
        backgroundColor: Color(0xFFE8EEF9),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // ถ้าบันทึกแล้ว → แสดง analytics emotion แทน
    if (_alreadySaved) {
      return const AnalyticsEmotionScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FD),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            /// 🔥 HEADER FIXED (ไม่ overflow แล้ว)
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 112, // 🔥 สำคัญ แก้ overflow
              flexibleSpace: const Padding(
                padding: EdgeInsets.only(top: 10),
                child: AppHeader(),
              ),
            ),

            /// 🔽 CONTENT
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "How are you feeling today?",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF253142),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        GridView.builder(
                          itemCount: moods.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.82,
                              ),
                          itemBuilder: (context, index) {
                            final mood = moods[index];
                            return _buildMoodCard(mood);
                          },
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: saveEmotion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD6E0),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Save Emotion",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF253142),
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
        ),
      ),
    );
  }

  Widget _buildMoodCard(Map<String, String> mood) {
    final type = mood["type"] ?? "neutral";
    final emoji = mood["emoji"] ?? "😐";
    final label = mood["label"] ?? "";
    final isActive = selected == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selected = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: EmotionColors.get(type),
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(color: const Color(0xFF5B7383), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
