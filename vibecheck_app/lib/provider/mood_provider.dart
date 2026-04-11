import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodProvider extends ChangeNotifier {
  final CollectionReference moodRef =
      FirebaseFirestore.instance.collection('emotions');

  List<String> moods = [];

  void fetchMoods() {
    moodRef.snapshots().listen((snapshot) {
      moods = snapshot.docs.map((doc) => doc['type'] as String).toList();
      notifyListeners();
    });
  }

  Future<void> addMood(String mood) async {
    await moodRef.add({
      'type': mood,
      'time': Timestamp.now(),
    });
  }

  int get total => moods.length;

  Map<String, int> get summary {
    Map<String, int> count = {};
    for (var m in moods) {
      count[m] = (count[m] ?? 0) + 1;
    }
    return count;
  }
}