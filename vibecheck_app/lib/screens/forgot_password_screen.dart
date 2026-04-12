import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  Future<void> _recover() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim());
      setState(() => _sent = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                  // Find Your Password label (ปุ่มชมพูเล็ก)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD6E0),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text('Find Your Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF374151))),
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email',
                          style: TextStyle(
                              fontSize: 13, color: Colors.black45)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFD0D0D0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFD0D0D0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFFFB3C6), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Success message
                  if (_sent)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'A recovery link has been sent to your inbox.\nPlease check your email to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),

                  // Recover button
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
                      onPressed: _isLoading ? null : _recover,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: const Color(0xFF374151),
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Recover',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Back to Login
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Back to Login',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black38,
                            decoration: TextDecoration.underline)),
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
}