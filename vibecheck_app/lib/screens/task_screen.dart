// lib/screens/task_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _taskController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

  // เพิ่ม task ใหม่ลง Firestore
  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;
    
    await FirebaseFirestore.instance.collection('tasks').add({
      'userId': _user?.uid,
      'title': _taskController.text.trim(),
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _taskController.clear();
    Navigator.pop(context); // ปิด dialog
  }

  // toggle complete/incomplete
  Future<void> _toggleTask(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance
      .collection('tasks').doc(docId)
      .update({'isCompleted': !currentStatus});
  }

  void _showAddTaskDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Task'),
      content: TextField(
        controller: _taskController,
        decoration: const InputDecoration(hintText: 'Task name...'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), 
          child: const Text('Cancel')),
        ElevatedButton(onPressed: _addTask, 
          child: const Text('Add')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // แสดง date ปัจจุบัน
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Text('Today', style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(10)),
                child: const Text('Completed: 0', 
                  style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),
          
          // List of tasks จาก Firestore (realtime)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('userId', isEqualTo: _user?.uid)
                .orderBy('createdAt', descending: false)
                .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No tasks yet! Add one 😊'));
                }
                
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isCompleted = data['isCompleted'] ?? false;
                    
                    return ListTile(
                      leading: Checkbox(
                        value: isCompleted,
                        onChanged: (_) => _toggleTask(docs[index].id, isCompleted),
                        activeColor: const Color(0xFF7B5EA7),
                      ),
                      title: Text(data['title'] ?? '',
                        style: TextStyle(
                          decoration: isCompleted 
                            ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : Colors.black,
                        )),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: const Color(0xFF7B5EA7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}