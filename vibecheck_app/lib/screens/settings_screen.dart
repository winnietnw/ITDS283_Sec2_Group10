import 'package:flutter/material.dart';
import '../widgets/header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 112,
              flexibleSpace: const Padding(
                padding: EdgeInsets.only(top: 10),
                child: AppHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
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