import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/header.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  String? _selectedFilter;

  Future<void> _addTask(String title, String? category) async {
    if (title.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('tasks').add({
      'userId': _user?.uid,
      'title': title.trim(),
      'category': category,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleTask(String docId, bool current) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(docId)
        .update({'isCompleted': !current});
  }

  Future<void> _deleteTask(String docId) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(docId)
        .delete();
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(onAdd: _addTask),
    );
  }

  Stream<QuerySnapshot> get _taskStream => FirebaseFirestore.instance
      .collection('tasks')
      .where('userId', isEqualTo: _user?.uid)
      .orderBy('createdAt', descending: false)
      .snapshots();

  Stream<QuerySnapshot> get _categoryStream => FirebaseFirestore.instance
      .collection('classifications')
      .orderBy('order')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF2),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header fixed ──
            const SizedBox(
              height: 112,
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: AppHeader(),
              ),
            ),

            // ── Today + badges fixed ──
            StreamBuilder<QuerySnapshot>(
              stream: _taskStream,
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final todoCount = docs
                    .where((d) =>
                        (d.data() as Map)['isCompleted'] != true)
                    .length;
                final completedCount = docs
                    .where((d) =>
                        (d.data() as Map)['isCompleted'] == true)
                    .length;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 5),
                  child: Row(
                    children: [
                      const Text('Today',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          )),
                      const SizedBox(width: 10),
                      _badge(
                        label: 'TO-DO ($todoCount)',
                        color: const Color(0xFFFFB3C6),
                        textColor: const Color(0xFF8B3A52),
                      ),
                      const SizedBox(width: 6),
                      _badge(
                        label: 'Completed ($completedCount)',
                        color: const Color(0xFFB3F0D9),
                        textColor: const Color(0xFF1A6B48),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Category filter bar fixed ──
            StreamBuilder<QuerySnapshot>(
              stream: _categoryStream,
              builder: (context, snapshot) {
                final cats = snapshot.data?.docs ?? [];
                if (cats.isEmpty) return const SizedBox(height: 12);

                return SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(30, 8, 30, 7),
                    children: [
                      _filterChip(
                        label: 'All',
                        isSelected: _selectedFilter == null,
                        onTap: () =>
                            setState(() => _selectedFilter = null),
                      ),
                      const SizedBox(width: 10),
                      ...cats.map((doc) {
                        final name =
                            (doc.data() as Map)['title']?.toString() ??
                                '';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _filterChip(
                            label: name,
                            isSelected: _selectedFilter == name,
                            onTap: () => setState(
                                () => _selectedFilter = name),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // ── Task list scrollable ──
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _taskStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  final filtered = _selectedFilter == null
                      ? allDocs
                      : allDocs.where((d) {
                          final cat = (d.data()
                                  as Map)['category']
                              ?.toString();
                          return cat == _selectedFilter;
                        }).toList();

                  final todo = filtered
                      .where((d) =>
                          (d.data() as Map)['isCompleted'] != true)
                      .toList();
                  final completed = filtered
                      .where((d) =>
                          (d.data() as Map)['isCompleted'] == true)
                      .toList();

                  if (filtered.isEmpty) {
                    return _emptyState(
                      _selectedFilter == null
                          ? 'No tasks yet!\nTap + to add one 😊'
                          : 'No tasks in "$_selectedFilter" yet',
                    );
                  }

                  return ListView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: [
                      ...todo.map((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        return _TaskTile(
                          title: data['title'] ?? '',
                          category: data['category']?.toString(),
                          isCompleted: false,
                          onToggle: () => _toggleTask(doc.id, false),
                          onDelete: () => _deleteTask(doc.id),
                        );
                      }),
                      if (completed.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _badge(
                              label:
                                  'Completed (${completed.length})',
                              color: const Color(0xFFB3F0D9),
                              textColor: const Color(0xFF1A6B48),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...completed.map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          return _TaskTile(
                            title: data['title'] ?? '',
                            category: data['category']?.toString(),
                            isCompleted: true,
                            onToggle: () =>
                                _toggleTask(doc.id, true),
                            onDelete: () => _deleteTask(doc.id),
                          );
                        }),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: _showAddSheet,
          backgroundColor: const Color(0xFFFFB3C6),
          elevation: 4,
          child:
              const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
          const SizedBox(width: 4),
          Icon(Icons.refresh_rounded, size: 12, color: textColor),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF555555)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(isSelected ? 0.12 : 0.04),
              blurRadius: isSelected ? 6 : 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.w400,
            color:
                isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black38,
          height: 1.6,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Task Tile
// ══════════════════════════════════════════════════════
class _TaskTile extends StatelessWidget {
  final String title;
  final String? category;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.title,
    required this.category,
    required this.isCompleted,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasCategory = category != null && category!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 0), // ✅ ลด vertical
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? const Color(0xFF4CAF50)
                  : Colors.transparent,
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isCompleted
                ? Colors.grey.shade400
                : Colors.black87,
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            decorationColor: Colors.grey.shade400,
          ),
        ),
        // ✅ category tag ไม่ยืด
        subtitle: hasCategory
            ? Padding(
                padding: const EdgeInsets.only(top: 3, bottom: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: GestureDetector(
          onTap: onDelete,
          child: Icon(Icons.close_rounded,
              size: 18, color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Add Task Bottom Sheet
// ══════════════════════════════════════════════════════
class _AddTaskSheet extends StatefulWidget {
  final Future<void> Function(String, String?) onAdd;

  const _AddTaskSheet({required this.onAdd});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final TextEditingController _ctrl = TextEditingController();
  String? _selectedCategory;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await widget.onAdd(_ctrl.text, _selectedCategory);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFAF2),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Task input ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: "I'm planning to do...",
                hintStyle:
                    TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),

          const SizedBox(height: 12),

          // ── Category dropdown ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classifications')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              final cats = snapshot.data?.docs ?? [];

              if (cats.isEmpty) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                        context, '/goals-categories');
                  },
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 14,
                          color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        'Add category',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: Text(
                      'Select category (optional)',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13),
                    ),
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400, size: 18),
                    dropdownColor: const Color(0xFFFDFAF2),
                    borderRadius: BorderRadius.circular(14),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('No category',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13)),
                      ),
                      ...cats.map((doc) {
                        final name =
                            (doc.data() as Map)['title']
                                ?.toString() ??
                                '';
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87)),
                        );
                      }),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // ── Submit ──
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _loading ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _ctrl.text.trim().isEmpty
                      ? Colors.grey.shade200
                      : const Color(0xFFFFB3C6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: _ctrl.text.trim().isEmpty
                            ? Colors.grey.shade400
                            : Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}