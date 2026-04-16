import 'package:flutter/material.dart';

class SettingsFromProfileScreen extends StatelessWidget {
  const SettingsFromProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = [
      {
        'icon': Icons.flag_outlined,
        'title': 'Goals and categories',
        'route': '/goals-categories',
      },
      {
        'icon': Icons.notifications_none,
        'title': 'Reminders and Sounds',
        'route': '/reminders-sounds',
      },
      {
        'icon': Icons.devices_outlined,
        'title': 'Multi-device Support',
        'route': '/multi-device-support',
      },
      {
        'icon': Icons.info_outline,
        'title': 'About Us',
        'route': '/about-us',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header ปุ่มถอย
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // List
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  itemCount: settings.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, i) {
                    final item = settings[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Icon(
                        item['icon'] as IconData,
                        color: const Color(0xFF7B5EA7),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        final route = item['route'] as String?;
                        if (route != null) {
                          Navigator.pushNamed(context, route);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}