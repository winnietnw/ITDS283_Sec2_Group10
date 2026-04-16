import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String _errorMessage = '';

  // ค้นหา email จาก username ใน Firestore
  Future<String?> _getEmailFromUsername(String input) async {
    if (input.contains('@')) return input;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: input)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data()['email'] as String?;
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final input = _usernameController.text.trim();
      final email = await _getEmailFromUsername(input);

      if (email == null) {
        setState(() => _errorMessage = 'Username or password is incorrect');
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException {
      setState(() => _errorMessage = 'Username or password is incorrect');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
            child: Column(
              children: [
                const SizedBox(height: 25),
                const Text('Welcome to',
                    style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E2E))),
                const SizedBox(height: 6),
                const Text('VibeCheck',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E2E))),
                const SizedBox(height: 15),
                const Text('Where Mood Meets Metrics',
                    style: TextStyle(
                        fontSize: 21,
                        color: Color.fromARGB(146, 0, 0, 0))),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: _tab('Login', true, null)),
                        const SizedBox(width: 8),
                        Expanded(child: _tab('Sign Up', false,
                            () => Navigator.pushNamed(context, '/signup'))),
                      ]),
                      const SizedBox(height: 20),

                      _buildLabel('Username/Email'),
                      TextField(
                        controller: _usernameController,
                        decoration: _inputDecoration(null),
                      ),
                      const SizedBox(height: 14),

                      _buildLabel('Password'),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: _inputDecoration(
                          IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black38,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_errorMessage.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_errorMessage,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ),
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFBD7E2),
                              Color(0xFFCDE7FF)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
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
                              : const Text('Sign In',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, '/forgot-password'),
                        child: const Text('Forgot Password?',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.black38,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: Colors.black45)),
      ),
    );
  }

  InputDecoration _inputDecoration(Widget? suffixIcon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        borderSide:
            const BorderSide(color: Color(0xFFFFB3C6), width: 1.5),
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
}