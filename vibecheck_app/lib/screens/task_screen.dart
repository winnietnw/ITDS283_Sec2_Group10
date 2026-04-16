import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/header.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  String? _selectedCategory;
  String _deadlineView = 'All'; // Today / Upcoming / All

  Future<void> _addTask(
      String title, String? category, DateTime? deadline) async {
    if (title.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('tasks').add({
      'userId': _user?.uid,
      'title': title.trim(),
      'category': category,
      'deadline': deadline != null ? Timestamp.fromDate(deadline) : null,
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

  // ── filter docs ตาม deadline view + category ──
  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    var result = docs;

    // filter deadline view
    if (_deadlineView == 'Today') {
      result = result.where((d) {
        final data = d.data() as Map;
        final dl = (data['deadline'] as Timestamp?)?.toDate();
        if (dl == null) return false;
        return dl.isAfter(todayStart) && dl.isBefore(todayEnd);
      }).toList();
    } else if (_deadlineView == 'Upcoming') {
      result = result.where((d) {
        final data = d.data() as Map;
        final dl = (data['deadline'] as Timestamp?)?.toDate();
        if (dl == null) return false;
        return dl.isAfter(todayEnd);
      }).toList();
    }

    // filter category
    if (_selectedCategory != null) {
      result = result.where((d) {
        final cat = (d.data() as Map)['category']?.toString();
        return cat == _selectedCategory;
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF2),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            const SizedBox(
              height: 112,
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: AppHeader(),
              ),
            ),

            // ── Title + TO-DO badge + deadline dropdown ──
            StreamBuilder<QuerySnapshot>(
              stream: _taskStream,
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final filtered = _filterDocs(docs);
                final todoCount = filtered
                    .where((d) =>
                        (d.data() as Map)['isCompleted'] != true)
                    .length;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                  child: Row(
                    children: [
                      const Text('Tasks',
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
                      const Spacer(),
                      // ✅ Deadline view dropdown
                      GestureDetector(
                        onTap: () => _showDeadlineMenu(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _deadlineView,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Category filter bar ──
            StreamBuilder<QuerySnapshot>(
              stream: _categoryStream,
              builder: (context, snapshot) {
                final cats = snapshot.data?.docs ?? [];
                if (cats.isEmpty) return const SizedBox(height: 8);

                return SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.fromLTRB(20, 6, 20, 4),
                    children: [
                      _filterChip(
                        label: 'All',
                        isSelected: _selectedCategory == null,
                        onTap: () =>
                            setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 8),
                      ...cats.map((doc) {
                        final name =
                            (doc.data() as Map)['title']?.toString() ??
                                '';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _filterChip(
                            label: name,
                            isSelected: _selectedCategory == name,
                            onTap: () => setState(
                                () => _selectedCategory = name),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // ── Task list ──
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
                  final filtered = _filterDocs(allDocs);

                  final todo = filtered
                      .where((d) =>
                          (d.data() as Map)['isCompleted'] != true)
                      .toList();
                  final completed = filtered
                      .where((d) =>
                          (d.data() as Map)['isCompleted'] == true)
                      .toList();

                  if (filtered.isEmpty) {
                    return _emptyState(_deadlineView == 'Today'
                        ? "No tasks due today 🎉"
                        : _deadlineView == 'Upcoming'
                            ? "No upcoming tasks"
                            : _selectedCategory != null
                                ? 'No tasks in "$_selectedCategory"'
                                : 'No tasks yet!\nTap + to add one 😊');
                  }

                  return ListView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: [
                      ...todo.map((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final deadline =
                            (data['deadline'] as Timestamp?)
                                ?.toDate();
                        return _TaskTile(
                          title: data['title'] ?? '',
                          category: data['category']?.toString(),
                          deadline: deadline,
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
                          final deadline =
                              (data['deadline'] as Timestamp?)
                                  ?.toDate();
                          return _TaskTile(
                            title: data['title'] ?? '',
                            category: data['category']?.toString(),
                            deadline: deadline,
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
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showDeadlineMenu(BuildContext context) async {
    final options = ['All', 'Today', 'Upcoming'];
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 150,
        180,
        20,
        0,
      ),
      color: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      items: options
          .map((o) => PopupMenuItem(
                value: o,
                child: Row(
                  children: [
                    Expanded(
                        child: Text(o,
                            style: const TextStyle(fontSize: 14))),
                    if (o == _deadlineView)
                      const Icon(Icons.check_rounded,
                          size: 16, color: Color(0xFFFFB3C6)),
                  ],
                ),
              ))
          .toList(),
    );
    if (selected != null) setState(() => _deadlineView = selected);
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
          color:
              isSelected ? const Color(0xFF555555) : Colors.white,
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
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.black54,
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
  final DateTime? deadline;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.title,
    required this.category,
    required this.deadline,
    required this.isCompleted,
    required this.onToggle,
    required this.onDelete,
  });

  Color _deadlineColor(DateTime dl) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dlDay = DateTime(dl.year, dl.month, dl.day);
    final diff = dlDay.difference(today).inDays;
    if (diff < 0) return const Color(0xFFE53935);
    if (diff == 0) return const Color(0xFFFF7043);
    if (diff <= 2) return const Color(0xFFFFB300);
    return Colors.grey.shade400;
  }

  String _deadlineLabel(DateTime dl) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dlDay = DateTime(dl.year, dl.month, dl.day);
    final diff = dlDay.difference(today).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Due Tomorrow';
    return 'Due ${DateFormat('MMM d').format(dl)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasCategory = category != null && category!.isNotEmpty;
    final hasDeadline = deadline != null;
    final hasSub = hasCategory || hasDeadline;

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
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
        subtitle: hasSub
            ? Padding(
                padding:
                    const EdgeInsets.only(top: 3, bottom: 4),
                child: Row(
                  children: [
                    // category tag
                    if (hasCategory) ...[
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
                      if (hasDeadline) const SizedBox(width: 6),
                    ],
                    // deadline tag
                    if (hasDeadline && !isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _deadlineColor(deadline!)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 10,
                                color: _deadlineColor(deadline!)),
                            const SizedBox(width: 3),
                            Text(
                              _deadlineLabel(deadline!),
                              style: TextStyle(
                                fontSize: 11,
                                color: _deadlineColor(deadline!),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
  final Future<void> Function(String, String?, DateTime?) onAdd;

  const _AddTaskSheet({required this.onAdd});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final TextEditingController _ctrl = TextEditingController();
  String? _selectedCategory;
  DateTime? _deadline;
  bool _loading = false;

  // quick deadline options
  static final _quickDeadlines = [
    ('Today', 0),
    ('Tomorrow', 1),
    ('This Week', null), // คำนวณพิเศษ
    ('Pick date', -1), // เปิด date picker
  ];

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

  DateTime _thisWeekEnd() {
    final now = DateTime.now();
    final daysLeft = 7 - now.weekday;
    final end = now.add(Duration(days: daysLeft));
    return DateTime(end.year, end.month, end.day, 23, 59);
  }

  String _formatDeadline(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dlDay = DateTime(dt.year, dt.month, dt.day);
    final diff = dlDay.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('MMM d').format(dt);
  }

  Future<void> _pickDeadline(String label, int? daysOffset) async {
    if (daysOffset == -1) {
      // date picker
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate:
            DateTime.now().add(const Duration(days: 365)),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFB3C6),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        setState(() => _deadline =
            DateTime(picked.year, picked.month, picked.day, 23, 59));
      }
      return;
    }

    if (daysOffset == null) {
      // This Week
      setState(() => _deadline = _thisWeekEnd());
      return;
    }

    final now = DateTime.now();
    final target = now.add(Duration(days: daysOffset));
    setState(() =>
        _deadline = DateTime(target.year, target.month, target.day, 23, 59));
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await widget.onAdd(_ctrl.text, _selectedCategory, _deadline);
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
                      Text('Add category',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.underline,
                          )),
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
                    hint: Text('Select category (optional)',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13)),
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

          // ── Deadline quick chips ──
          const Text('Deadline',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              // "No deadline" chip
              GestureDetector(
                onTap: () => setState(() => _deadline = null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _deadline == null
                        ? const Color(0xFF555555)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.grey.shade200),
                  ),
                  child: Text('Anytime',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _deadline == null
                              ? Colors.white
                              : Colors.black54)),
                ),
              ),
              // quick deadline chips
              ..._quickDeadlines.map((item) {
                final label = item.$1;
                final offset = item.$2;
                bool isSelected = false;
                if (_deadline != null) {
                  if (label == 'Pick date') {
                    // selected ถ้าไม่ตรงกับ Today/Tomorrow/ThisWeek
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final dl = DateTime(
                        _deadline!.year, _deadline!.month, _deadline!.day);
                    final diff = dl.difference(today).inDays;
                    isSelected = diff > 1 &&
                        _deadline != _thisWeekEnd();
                  } else if (offset == null) {
                    isSelected = _deadline == _thisWeekEnd();
                  } else if (offset >= 0) {
                    final target = DateTime.now()
                        .add(Duration(days: offset));
                    isSelected = _deadline!.year == target.year &&
                        _deadline!.month == target.month &&
                        _deadline!.day == target.day;
                  }
                }

                return GestureDetector(
                  onTap: () => _pickDeadline(label, offset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFB3C6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.grey.shade200),
                    ),
                    child: Text(
                      label == 'Pick date' && _deadline != null && isSelected
                          ? _formatDeadline(_deadline!)
                          : label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Colors.black54),
                    ),
                  ),
                );
              }),
            ],
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