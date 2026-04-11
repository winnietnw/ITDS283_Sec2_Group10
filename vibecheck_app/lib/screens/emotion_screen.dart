import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/header.dart';
import '../widgets/emotion_colors.dart';

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen> {
  String selected = "";

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

  Future<void> saveEmotion() async {
    if (selected.isEmpty) return;

    await FirebaseFirestore.instance.collection('emotions').add({
      "type": selected,
      "time": Timestamp.now(),
    });

    if (!mounted) return;
    Navigator.pushNamed(context, '/analytics_emotion');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF9),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            /// 🔥 HEADER FIXED (ไม่ overflow แล้ว)
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFFE8EEF9),
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
