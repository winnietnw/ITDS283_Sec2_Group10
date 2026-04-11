import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/header.dart';

class GoalsCategoriesScreen extends StatefulWidget {
  const GoalsCategoriesScreen({super.key});

  @override
  State<GoalsCategoriesScreen> createState() => _GoalsCategoriesScreenState();
}

class _GoalsCategoriesScreenState extends State<GoalsCategoriesScreen> {
  int selectedTab = 0; // 0 = Classification, 1 = Goal
  final TextEditingController _controller = TextEditingController();

  CollectionReference<Map<String, dynamic>> get _currentCollection {
    return FirebaseFirestore.instance.collection(
      selectedTab == 0 ? 'classifications' : 'goals',
    );
  }

  String get _currentTypeLabel =>
      selectedTab == 0 ? 'classification' : 'goal';

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
            selectedTab == 0 ? 'New Classification' : 'New Goal',
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
              suffixIcon: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _submitNewItem,
              ),
            ),
            onSubmitted: (_) => _submitNewItem(),
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

    final snap = await _currentCollection
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

    await _currentCollection.add({
      'title': text,
      'order': nextOrder,
      'createdAt': Timestamp.now(),
    });

    if (mounted) Navigator.pop(context);
  }

  Future<void> _editItem(String docId, String oldValue) async {
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

                await _currentCollection.doc(docId).update({
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

  Future<void> _deleteItem(String docId) async {
    await _currentCollection.doc(docId).delete();
  }

  Future<void> _reorderItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;

    final reordered = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < reordered.length; i++) {
      batch.update(reordered[i].reference, {'order': i});
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final collectionName = selectedTab == 0 ? 'classifications' : 'goals';

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8F8),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFFE8E8F8),
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 112,
              flexibleSpace: const Padding(
                padding: EdgeInsets.only(top: 10),
                child: AppHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
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

                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection(collectionName)
                          .orderBy('order')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isNotEmpty) {
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

                              if (selectedTab == 0)
                                ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: docs.length,
                                  buildDefaultDragHandles: false,
                                  onReorder: (oldIndex, newIndex) {
                                    _reorderItems(docs, oldIndex, newIndex);
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
                                                _editItem(doc.id, title);
                                              } else if (value == 'delete') {
                                                _deleteItem(doc.id);
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
                                )
                              else
                                Column(
                                  children: docs.map((doc) {
                                    final title =
                                        doc.data()['title']?.toString() ?? '';

                                    return Container(
                                      width: double.infinity,
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
                                                _editItem(doc.id, title);
                                              } else if (value == 'delete') {
                                                _deleteItem(doc.id);
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
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 180),
                          child: Text(
                            'No $_currentTypeLabel has been created yet',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF232531),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: const Text(
            'New category',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
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