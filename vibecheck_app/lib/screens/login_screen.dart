// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller ไว้รับ input จาก user
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // เรียก Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // ถ้า login สำเร็จ ไปหน้า Home
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Username or password is incorrect';
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo area
              const Center(
                child: Text('Welcome to\nVibeCheck',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                    color: Color(0xFF3D1C8D))),
              ),
              const Center(child: Text('Where Mood Meets Metrics',
                style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 40),

              // Tab Login / Sign Up (แบบ Figma)
              Row(children: [
                Expanded(child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5EA7)),
                  child: const Text('Login', 
                    style: TextStyle(color: Colors.white)),
                )),
                Expanded(child: TextButton(
                  onPressed: () => 
                    Navigator.pushNamed(context, '/signup'),
                  child: const Text('Sign Up'),
                )),
              ]),
              const SizedBox(height: 20),

              // ช่อง Username/Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Username / Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // ช่อง Password
              TextField(
                controller: _passwordController,
                obscureText: true, // ซ่อน password
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              
              // แสดง error message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_errorMessage,
                    style: const TextStyle(color: Colors.red)),
                ),

              Align(alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () { /* forgot password flow */ },
                  child: const Text('Forgot Password?'),
                )),

              // ปุ่ม Sign In
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5EA7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Sign in', 
                      style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}