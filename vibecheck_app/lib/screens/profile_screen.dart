// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    // แสดง confirm dialog ก่อน logout (ตาม Figma)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log out', 
              style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50,
              child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            Text(user?.displayName ?? 'Username',
              style: const TextStyle(fontSize: 22, 
                fontWeight: FontWeight.bold)),
            Text(user?.email ?? 'someone@gmail.com',
              style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            // Insights link
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/analytics'),
              icon: const Icon(Icons.bar_chart),
              label: const Text('Insights'),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 12),
              ),
              child: const Text('Log Out', 
                style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}