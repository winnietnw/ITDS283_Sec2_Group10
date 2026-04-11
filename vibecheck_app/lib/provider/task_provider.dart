import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskProvider extends ChangeNotifier {
  final CollectionReference tasksRef =
      FirebaseFirestore.instance.collection('tasks');

  List<Map<String, dynamic>> tasks = [];

  // โหลดข้อมูลจาก Firebase
  void fetchTasks() {
    tasksRef.snapshots().listen((snapshot) {
      tasks = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'],
          'done': doc['done'] ?? false,
        };
      }).toList();
      notifyListeners();
    });
  }

  // เพิ่ม task
  Future<void> addTask(String title) async {
    await tasksRef.add({
      'title': title,
      'done': false,
      'createdAt': Timestamp.now(),
    });
  }

  // mark done
  Future<void> toggleTask(String id, bool current) async {
    await tasksRef.doc(id).update({'done': !current});
  }

  // ลบ task
  Future<void> deleteTask(String id) async {
    await tasksRef.doc(id).delete();
  }
}