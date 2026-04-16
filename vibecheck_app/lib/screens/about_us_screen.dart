import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/emotion_galaxy.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
                              'About Us',
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
                    const SizedBox(height: 28),
                    const Center(
                      child: EmotionGalaxy(size: 170),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _aboutMenuTile(
                            context,
                            icon: Icons.send_outlined,
                            title: 'Feedback',
                            onTap: () {
                              Navigator.pushNamed(context, '/feedback');
                            },
                          ),
                          _divider(),
                          _aboutMenuTile(
                            context,
                            icon: Icons.refresh,
                            title: 'Check for updates',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Your app is up to date.'),
                                ),
                              );
                            },
                          ),
                          _divider(),
                          _aboutMenuTile(
                            context,
                            icon: Icons.power_settings_new,
                            title: 'Delete Account',
                            onTap: () {
                              _showDeleteDialog(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 220),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/privacy');
                          },
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6D7CFF),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/privacy');
                          },
                          child: const Text(
                            'User Service Agreement',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6D7CFF),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
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

  Widget _divider() {
    return Container(
      height: 1,
      color: const Color(0xFFE5E5E5),
    );
  }

  Widget _aboutMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _DeleteAccountDialog(),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool isDeleting = false;
  String? inputError;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    setState(() {
      inputError = null;
    });

    if (_confirmController.text.trim().isEmpty) {
      setState(() {
        inputError = 'Please enter your email.';
      });
      return;
    }

    if (_confirmController.text.trim() != email) {
      setState(() {
        inputError = 'Email does not match your account.';
      });
      return;
    }

    if (user == null) {
      setState(() {
        inputError = 'No signed-in user found.';
      });
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      await _deleteCurrentUserData(user.uid);
      await user.delete();

      if (!mounted) return;
      setState(() {
        isDeleting = false;
      });

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showDeleteSuccess(context);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      if (e.code == 'requires-recent-login') {
        _showReauthDialog(context, email);
      } else {
        setState(() {
          inputError = e.message ?? 'Failed to delete account.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isDeleting = false;
        inputError = 'Failed to delete account.';
      });
    }
  }

  Future<void> _deleteCurrentUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    await _deleteUserOwnedQueries(firestore, uid);
    await _deleteUserDirectDocs(firestore, uid);
    await _deleteUserStorage(storage, uid);
  }

  Future<void> _deleteUserOwnedQueries(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    const collectionsWithUserId = <String>[
      'tasks',
      'emotions',
      'feedback',
      'classifications',
      'notifications',
      'contacts',
    ];

    for (final collection in collectionsWithUserId) {
      await _deleteQueryInBatches(
        firestore.collection(collection).where('userId', isEqualTo: uid),
      );
    }

    await _deleteQueryInBatches(
      firestore.collection('goal_progress').where('userId', isEqualTo: uid),
    );
  }

  Future<void> _deleteUserDirectDocs(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    final directDocPaths = <String>[
      'users/$uid',
      'profiles/$uid',
      'settings/$uid',
      'goal_progress/$uid',
    ];

    for (final path in directDocPaths) {
      final doc = firestore.doc(path);
      final snap = await doc.get();
      if (snap.exists) {
        await doc.delete();
      }
    }

    final currentActive = firestore.collection('goal_progress').doc('current_active');
    final currentActiveSnap = await currentActive.get();
    if (currentActiveSnap.exists) {
      final data = currentActiveSnap.data();
      if (data != null && data['userId'] == uid) {
        await currentActive.delete();
      }
    }
  }

  Future<void> _deleteUserStorage(
    FirebaseStorage storage,
    String uid,
  ) async {
    final userRoot = storage.ref().child('users').child(uid);
    await _deleteStorageFolderRecursive(userRoot);
  }

  Future<void> _deleteQueryInBatches(Query query) async {
    while (true) {
      final snapshot = await query.limit(50).get();
      if (snapshot.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < 50) break;
    }
  }

  Future<void> _deleteStorageFolderRecursive(Reference ref) async {
    try {
      final result = await ref.listAll();

      for (final item in result.items) {
        await item.delete();
      }

      for (final prefix in result.prefixes) {
        await _deleteStorageFolderRecursive(prefix);
      }
    } catch (_) {
      // ignore missing folder or permission edge cases
    }
  }

  void _showReauthDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ReauthDialog(
        email: email,
        onSuccess: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          await _deleteCurrentUserData(user.uid);
          await user.delete();

          if (!mounted) return;
          Navigator.pop(context);
          _showDeleteSuccess(context);
        },
      ),
    );
  }

  void _showDeleteSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteSuccessDialog(
        onClose: () async {
          Navigator.of(dialogContext).pop();
          try {
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
          if (dialogContext.mounted) {
            Navigator.of(
              dialogContext,
              rootNavigator: true,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF8F8F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
                      size: 26,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Icon(
                Icons.warning_rounded,
                size: 52,
                color: Color(0xFFE53935),
              ),
              const SizedBox(height: 20),
              const Text(
                'You are currently performing an account\n'
                'cancellation operation. All data will be cleared\n'
                'after account cancellation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Please proceed with caution.\n'
                'To confirm, manually enter the following:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Color(0xFF8B93A1),
                ),
              ),
              const SizedBox(height: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: inputError != null
                            ? Colors.red
                            : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: TextField(
                      controller: _confirmController,
                      onChanged: (_) {
                        if (inputError != null) {
                          setState(() {
                            inputError = null;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Please enter your email',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B93A1),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  if (inputError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      inputError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isDeleting ? null : _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE35D5B),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm cancellation and delete account data',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
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
}

class _ReauthDialog extends StatefulWidget {
  final String email;
  final Future<void> Function() onSuccess;

  const _ReauthDialog({
    required this.email,
    required this.onSuccess,
  });

  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  String? passwordError;
  bool obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _reauthenticate() async {
    setState(() {
      passwordError = null;
    });

    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        passwordError = 'Please enter your password.';
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No signed-in user found.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: widget.email,
        password: _passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await widget.onSuccess();

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        passwordError = e.message ?? 'Re-authentication failed.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        passwordError = 'Re-authentication failed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF8F8F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Re-enter Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
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
              const SizedBox(height: 14),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: passwordError != null
                            ? Colors.red
                            : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: obscurePassword,
                      onChanged: (_) {
                        if (passwordError != null) {
                          setState(() {
                            passwordError = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Please enter your password',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B93A1),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (passwordError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      passwordError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _reauthenticate,
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
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify and Delete',
                          style: TextStyle(
                            fontSize: 15,
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
}

class _DeleteSuccessDialog extends StatelessWidget {
  final VoidCallback onClose;

  const _DeleteSuccessDialog({
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Delete Account Successful',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
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