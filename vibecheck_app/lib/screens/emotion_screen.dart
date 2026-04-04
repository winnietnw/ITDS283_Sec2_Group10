// lib/screens/emotion_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen> {
  String? _selectedEmotion;
  final _user = FirebaseAuth.instance.currentUser;

  // รายการ emotion จาก Figma (emoji + ชื่อ)
  final List<Map<String, dynamic>> _emotions = [
    {'emoji': '😊', 'label': 'Happy', 'type': 'positive'},
    {'emoji': '😌', 'label': 'Calm', 'type': 'positive'},
    {'emoji': '😄', 'label': 'Excited', 'type': 'positive'},
    {'emoji': '🥰', 'label': 'Loved', 'type': 'positive'},
    {'emoji': '😐', 'label': 'Meh', 'type': 'neutral'},
    {'emoji': '😤', 'label': 'Frustrated', 'type': 'negative'},
    {'emoji': '😢', 'label': 'Sad', 'type': 'negative'},
    {'emoji': '😰', 'label': 'Anxious', 'type': 'negative'},
  ];

  Future<void> _saveEmotion() async {
    if (_selectedEmotion == null) return;
    
    // บันทึกลง Firestore
    await FirebaseFirestore.instance.collection('emotions').add({
      'userId': _user?.uid,
      'emotion': _selectedEmotion,
      'type': _emotions.firstWhere(
        (e) => e['label'] == _selectedEmotion)['type'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emotion saved! ⭐')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emotion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('How are you feeling today?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            
            // Grid ของ emotion emoji
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: _emotions.map((emotion) {
                final isSelected = _selectedEmotion == emotion['label'];
                return GestureDetector(
                  onTap: () => setState(() => 
                    _selectedEmotion = emotion['label']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? const Color(0xFF7B5EA7).withValues(alpha: 0.2)
                        : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected 
                        ? Border.all(color: const Color(0xFF7B5EA7), width: 2)
                        : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emotion['emoji']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(emotion['label']!, 
                          style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectedEmotion != null ? _saveEmotion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB6C1),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Emotion', 
                style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}