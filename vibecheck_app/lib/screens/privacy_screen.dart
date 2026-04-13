import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔙 Header
                    Row(
                      children: [
                        /// 🔙 ปุ่มย้อนกลับ (แบบมีพื้นหลัง)
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        /// 🧠 Title (อยู่กลางจริง)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        /// ช่องว่าง balance layout
                        const SizedBox(width: 40),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 📜 Content
                    const Text(
                      'VibeCheck Privacy Policy & User Agreement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      '''
This Privacy Policy explains how VibeCheck collects, uses, and protects your personal information.

1. Information We Collect
We may collect information such as your email address, user activity (tasks, emotions, goals), and feedback you provide.

2. How We Use Your Information
Your data is used to improve your experience, personalize features, and enhance application performance.

3. Data Security
We implement security measures to protect your personal data. However, no system is completely secure.

4. User Responsibility
You are responsible for maintaining the confidentiality of your account and activities under your account.

5. Data Deletion
You may request account deletion at any time. All associated data will be permanently removed.

6. Third-Party Services
We use Firebase services for authentication, storage, and database management.

7. Changes to Policy
We may update this policy at any time. Continued use means you accept the updated terms.

---

User Agreement

By using VibeCheck, you agree to:
• Use the app responsibly  
• Not misuse or exploit system features  
• Respect data privacy of yourself and others  

If you do not agree with these terms, please discontinue use of the application.

---

Last Updated: 2026
                      ''',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
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
}