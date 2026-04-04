// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = [
      {'icon': Icons.flag, 'title': 'Goals and categories'},
      {'icon': Icons.notifications, 'title': 'Reminders and Sounds'},
      {'icon': Icons.devices, 'title': 'Multi-device Support'},
      {'icon': Icons.info_outline, 'title': 'About Us'},
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Settings'),
      ),
      body: ListView.separated(
        itemCount: settings.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) => ListTile(
          leading: Icon(settings[i]['icon'] as IconData,
            color: const Color(0xFF7B5EA7)),
          title: Text(settings[i]['title'] as String),
          trailing: const Icon(Icons.chevron_right),
          onTap: () { /* navigate to sub-settings */ },
        ),
      ),
    );
  }
}