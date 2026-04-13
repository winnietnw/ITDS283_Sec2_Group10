import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/emotion_galaxy.dart';
import '../widgets/animated_action_button.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE9FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const SizedBox(
                            width: 40,
                            child: Icon(
                              Icons.arrow_back,
                              size: 24,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Feedback',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 34),
                    const Center(
                      child: EmotionGalaxy(size: 170),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'We’d love to hear from you 💬',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Tell us what you like, what could be better,\n'
                        'or any ideas you have.\n'
                        'Your feedback helps us build a better experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    AnimatedActionButton(
                      text: 'Feedback',
                      onTap: () {
                        _showFeedbackPopup(context);
                      },
                      darkStyle: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _FeedbackDialog(),
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog();

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final TextEditingController _descriptionController = TextEditingController();

  String? selectedIssue;
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  bool isSubmitting = false;
  String userEmail = '';
  String userId = '';

  final List<String> issueTypes = const [
    'Stuttering/ slow response/ performance issues',
    'Malfunction/ Not working properly',
    'Function/ user experience suggestions',
    'Translation Errors',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email ?? 'No email';
    userId = user?.uid ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();

    if (!mounted) return;
    setState(() {
      selectedImageBytes = bytes;
      selectedImageName = file.name;
    });
  }

  bool _validateForm() {
    if (userId.isEmpty) {
      _showError('No signed-in user found.');
      return false;
    }

    if (selectedIssue == null || selectedIssue!.trim().isEmpty) {
      _showError('Please select the issue type.');
      return false;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter a description of the issue.');
      return false;
    }

    if (selectedImageBytes == null) {
      _showError('Please add an image.');
      return false;
    }

    if (userEmail.isEmpty || userEmail == 'No email') {
      _showError('No user email found. Please log in again.');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String> _uploadImageToStorage() async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${selectedImageName ?? 'feedback_image.jpg'}';

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(userId)
        .child('feedback')
        .child(fileName);

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'userId': userId,
        'userEmail': userEmail,
      },
    );

    await storageRef.putData(selectedImageBytes!, metadata);
    return storageRef.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final imageUrl = await _uploadImageToStorage();

      final imagePath = FirebaseStorage.instance
          .refFromURL(imageUrl)
          .fullPath;

      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': userId,
        'userEmail': userEmail,
        'issueType': selectedIssue,
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'imageName': selectedImageName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
      });

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      Navigator.pop(context);
      _showSubmitSuccess(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
      });
      _showError('Failed to submit feedback. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF7F7F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Type of Issue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 26,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedIssue,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    hint: const Text(
                      'Please select the issue type',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    items: issueTypes.map((issue) {
                      return DropdownMenuItem<String>(
                        value: issue,
                        child: Text(
                          issue,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedIssue = value;
                      });
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Please enter a description of the issue',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B93A1),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 140,
                        height: 132,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(12),
                          image: selectedImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(selectedImageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: selectedImageBytes == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: Colors.black54,
                                  ),
                                  SizedBox(height: 8),
                                  Icon(
                                    Icons.add,
                                    size: 34,
                                    color: Colors.black54,
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedImageBytes = null;
                                          selectedImageName = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.45),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (selectedImageName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        selectedImageName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7F8794),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3138),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return const _SubmitSuccessDialog();
      },
    );
  }
}

class _SubmitSuccessDialog extends StatelessWidget {
  const _SubmitSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '🎉',
                style: TextStyle(fontSize: 44),
              ),
              const SizedBox(height: 18),
              const Text(
                'Submit Successful',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}