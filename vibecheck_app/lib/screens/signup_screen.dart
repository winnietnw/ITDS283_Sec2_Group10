// lib/screens/signup_screen.dart
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
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createAccount() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // สร้าง user ใน Firebase Auth
      final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      
      // อัปเดต displayName
      await cred.user?.updateDisplayName(_usernameController.text.trim());
      
      // บันทึก user info ลง Firestore
      await FirebaseFirestore.instance
        .collection('users').doc(cred.user?.uid).set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      
      if (mounted) {
        // แสดง success dialog
        await showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('All set!'),
          content: const Text('Your account has been created.'),
          actions: [ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'))],
        ));
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error creating account')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('Welcome to\nVibeCheck',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                  color: Color(0xFF3D1C8D))),
              const Text('Where Mood Meets Metrics',
                style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              
              // Tab Login/SignUp
              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Login'))),
                Expanded(child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5EA7)),
                  child: const Text('Sign Up', 
                    style: TextStyle(color: Colors.white)))),
              ]),
              const SizedBox(height: 20),
              
              // Form fields
              ...[
                (_usernameController, 'Username', false),
                (_emailController, 'Email', false),
                (_passwordController, 'Password', true),
                (_confirmPasswordController, 'Confirm Password', true),
              ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: item.$1,
                  obscureText: item.$3,
                  decoration: InputDecoration(
                    labelText: item.$2,
                    border: const OutlineInputBorder(),
                  ),
                ),
              )),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5EA7),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Account',
                      style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}