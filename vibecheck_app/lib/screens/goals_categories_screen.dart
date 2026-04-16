import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/animated_action_button.dart';
import '../data/goal_templates.dart';
import 'goal_progress_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsCategoriesScreen extends StatefulWidget {
  const GoalsCategoriesScreen({super.key});

  @override
  State<GoalsCategoriesScreen> createState() => _GoalsCategoriesScreenState();
}

class _GoalsCategoriesScreenState extends State<GoalsCategoriesScreen> {
  int selectedTab = 0;
  final TextEditingController _controller = TextEditingController();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _classificationCollection {
    return FirebaseFirestore.instance.collection('classifications');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Dialog: Add
  // ─────────────────────────────────────────────
  Future<void> _showAddDialog() async {
    _controller.clear();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedTab == 0 ? 'New Classification' : 'New Target',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E2E),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  maxLength: 15,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E1E2E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter name...',
                    hintStyle: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontWeight: FontWeight.w400,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD0AAFF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFFF0F0F0),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: _submitNewItem,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF1E1E2E),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitNewItem() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (selectedTab == 0) {
      final snap = await _classificationCollection
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      int nextOrder = 0;
      if (snap.docs.isNotEmpty) {
        final lastOrder = snap.docs.first.data()['order'];
        if (lastOrder is int) nextOrder = lastOrder + 1;
      }

      await _classificationCollection.add({
        'title': text,
        'order': nextOrder,
        'createdAt': Timestamp.now(),
        'userId': _uid,
      });
    }

    if (mounted) Navigator.pop(context);
  }

  // ─────────────────────────────────────────────
  //  Dialog: Edit
  // ─────────────────────────────────────────────
  Future<void> _editClassification(String docId, String oldValue) async {
    final controller = TextEditingController(text: oldValue);
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E2E),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLength: 15,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E1E2E),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD0AAFF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFFF0F0F0),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          await _classificationCollection
                              .doc(docId)
                              .update({'title': text});
                          if (mounted) Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF1E1E2E),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteClassification(String docId) async {
    await _classificationCollection.doc(docId).delete();
  }

  Future<void> _reorderClassification(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final reordered =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < reordered.length; i++) {
      batch.update(reordered[i].reference, {'order': i});
    }
    await batch.commit();
  }

  GoalTemplate? _findGoalById(String id) {
    final goals = buildGoalTemplatesForCurrentMonth();
    for (final goal in goals) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/settings');
                      }
                    },
                    child: const SizedBox(
                      width: 40,
                      child: Icon(Icons.arrow_back,
                          size: 24, color: Colors.black87),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _tabButton(
                          title: 'Classification',
                          active: selectedTab == 0,
                          onTap: () => setState(() => selectedTab = 0),
                        ),
                        const SizedBox(width: 28),
                        _tabButton(
                          title: 'Goal',
                          active: selectedTab == 1,
                          onTap: () => setState(() => selectedTab = 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 100),
                child: Column(
                  children: [
                    if (selectedTab == 0)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _classificationCollection
                            .where('userId', isEqualTo: _uid)
                            .orderBy('order')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 180),
                              child: Text(
                                'No classification has been created yet',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black54),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD6E0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'All (${docs.length})',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ReorderableListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                buildDefaultDragHandles: false,
                                onReorder: (oldIndex, newIndex) {
                                  _reorderClassification(
                                      docs, oldIndex, newIndex);
                                },
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  final title =
                                      doc.data()['title']?.toString() ?? '';

                                  return Container(
                                    key: ValueKey(doc.id),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.88),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(title,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87)),
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert,
                                              color: Color(0xFF888888),
                                              size: 20),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          color: Colors.white,
                                          elevation: 8,
                                          shadowColor:
                                              Colors.black.withOpacity(0.12),
                                          padding: EdgeInsets.zero,
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editClassification(
                                                  doc.id, title);
                                            } else if (value == 'delete') {
                                              _deleteClassification(doc.id);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.edit_outlined,
                                                      size: 16,
                                                      color: Color(0xFF555555)),
                                                  SizedBox(width: 10),
                                                  Text('Edit',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(
                                                              0xFF333333))),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.delete_outline,
                                                      size: 16,
                                                      color: Color(0xFFE57373)),
                                                  SizedBox(width: 10),
                                                  Text('Delete',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(
                                                              0xFFE57373))),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(Icons.drag_handle,
                                              color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      )
                    else
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('goal_progress')
                            .doc(
                                'current_active_${FirebaseAuth.instance.currentUser?.uid ?? 'unknown'}')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data();

                          if (data == null) {
                            return SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.58,
                              child: const Center(
                                child: Text('No ongoing goals',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54)),
                              ),
                            );
                          }

                          final goalId = data['goalId']?.toString() ?? '';
                          final title = data['title']?.toString() ?? 'Goal';
                          final colorValue =
                              data['colorValue'] as int? ?? 0xFFE9D9A8;
                          final selectedDay = data['selectedDay'] as int? ?? 1;
                          final totalDays = data['totalDays'] as int? ?? 30;
                          final completedDays =
                              (data['completedDays'] as List<dynamic>? ?? [])
                                  .map((e) => e as int)
                                  .toList();
                          final activeGoal = _findGoalById(goalId);

                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.fromLTRB(18, 18, 18, 18),
                              decoration: BoxDecoration(
                                color: Color(colorValue),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ongoing Goal',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black54,
                                          letterSpacing: 0.2)),
                                  const SizedBox(height: 10),
                                  Text(title,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          height: 1.35,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87)),
                                  const SizedBox(height: 12),
                                  Text('Day $selectedDay of $totalDays',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Completed days: ${completedDays.length}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.95),
                                      foregroundColor: Colors.black87,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: activeGoal == null
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    GoalProgressScreen(
                                                        goal: activeGoal),
                                              ),
                                            );
                                          },
                                    child: const Text('Continue',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedActionButton(
        text: selectedTab == 0 ? 'New category' : 'New Target',
        onTap: () {
          if (selectedTab == 0) {
            _showAddDialog();
          } else {
            Navigator.pushNamed(context, '/new-target');
          }
        },
        darkStyle: false,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _tabButton({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? Colors.black87 : Colors.grey,
        ),
      ),
    );
  }
}