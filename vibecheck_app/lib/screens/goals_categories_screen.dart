import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/animated_action_button.dart';
import '../data/goal_templates.dart';
import 'goal_progress_screen.dart';

class GoalsCategoriesScreen extends StatefulWidget {
  const GoalsCategoriesScreen({super.key});

  @override
  State<GoalsCategoriesScreen> createState() => _GoalsCategoriesScreenState();
}

class _GoalsCategoriesScreenState extends State<GoalsCategoriesScreen> {
  int selectedTab = 0;
  final TextEditingController _controller = TextEditingController();

  CollectionReference<Map<String, dynamic>> get _classificationCollection {
    return FirebaseFirestore.instance.collection('classifications');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    _controller.clear();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            selectedTab == 0 ? 'New Classification' : 'New Target',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: _controller,
            maxLength: 15,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Please enter content',
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF232531),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitNewItem,
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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
        if (lastOrder is int) {
          nextOrder = lastOrder + 1;
        }
      }

      await _classificationCollection.add({
        'title': text,
        'order': nextOrder,
        'createdAt': Timestamp.now(),
      });
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _editClassification(String docId, String oldValue) async {
    final controller = TextEditingController(text: oldValue);

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Edit',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            maxLength: 15,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter new name',
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF232531),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                await _classificationCollection.doc(docId).update({
                  'title': text,
                });

                if (mounted) Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 100),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                '/settings',
                              );
                            }
                          },
                          child: const SizedBox(
                            width: 40,
                            child: Icon(
                              Icons.arrow_back,
                              size: 24,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _tabButton(
                                title: 'Classification',
                                active: selectedTab == 0,
                                onTap: () {
                                  setState(() => selectedTab = 0);
                                },
                              ),
                              const SizedBox(width: 28),
                              _tabButton(
                                title: 'Goal',
                                active: selectedTab == 1,
                                onTap: () {
                                  setState(() => selectedTab = 1);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (selectedTab == 0)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _classificationCollection
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
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD6E0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'All (${docs.length})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
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
                                    docs,
                                    oldIndex,
                                    newIndex,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  final title =
                                      doc.data()['title']?.toString() ?? '';

                                  return Container(
                                    key: ValueKey(doc.id),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.88),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton<String>(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editClassification(
                                                doc.id,
                                                title,
                                              );
                                            } else if (value == 'delete') {
                                              _deleteClassification(doc.id);
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ],
                                          child: const Icon(
                                            Icons.more_vert,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(
                                            Icons.drag_handle,
                                            color: Colors.black54,
                                          ),
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
                            .doc('current_active')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data();

                          if (data == null) {
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.58,
                              child: const Center(
                                child: Text(
                                  'No ongoing goals',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
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
                            padding: const EdgeInsets.only(top: 116),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                                  const Text(
                                    'Ongoing Goal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Day $selectedDay of $totalDays',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Completed days: ${completedDays.length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.95),
                                      foregroundColor: Colors.black87,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: activeGoal == null
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    GoalProgressScreen(
                                                  goal: activeGoal,
                                                ),
                                              ),
                                            );
                                          },
                                    child: const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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