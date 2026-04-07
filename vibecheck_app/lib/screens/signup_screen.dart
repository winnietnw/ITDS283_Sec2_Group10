import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createAccount() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await cred.user?.updateDisplayName(_usernameController.text.trim());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user?.uid)
          .set({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('All set!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Your account has been created.',
                    style: TextStyle(
                        color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Text('Continue',
                      style: TextStyle(
                          color: Colors.black38,
                          fontSize: 12,
                          decoration: TextDecoration.underline)),
                ),
              ]),
            ),
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const SizedBox(height: 25),
              const Text('Welcome to',
                  style: TextStyle(fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E2E))),
              const SizedBox(height: 6),
              const Text('VibeCheck',
                  style: TextStyle(fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E2E))),
              const SizedBox(height: 15),
              const Text('Where Mood Meets Metrics',
                  style: TextStyle(fontSize: 21,
                      color: Color.fromARGB(146, 0, 0, 0))),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(children: [
                  // Tab row
                  Row(children: [
                    Expanded(child: _tab('Login', false,
                        () => Navigator.pop(context))),
                    const SizedBox(width: 8),
                    Expanded(child: _tab('Sign Up', true, null)),
                  ]),
                  const SizedBox(height: 20),

                  _field('Username', _usernameController, false),
                  const SizedBox(height: 14),
                  _field('Email', _emailController, false),
                  const SizedBox(height: 14),
                  _field('Password', _passwordController, true),
                  const SizedBox(height: 14),
                  _field('Confirm Password', _confirmController, true),
                  const SizedBox(height: 20),

                  // Create Account button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBD7E2), Color(0xFFCDE7FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: const Color(0xFF374151),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Create Account',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFFD6E0)
              : const Color.fromARGB(120, 255, 214, 224),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isActive
                    ? const Color(0xFF374151)
                    : Colors.black38)),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, bool obscure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black45)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFFFB3C6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}