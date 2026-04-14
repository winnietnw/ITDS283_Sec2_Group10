import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/task_screen.dart';
import '../screens/timer_screen.dart';
import '../screens/emotion_screen.dart';
import '../screens/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  // ✅ เพิ่ม static key เพื่อ access state จากที่อื่นได้
  static final GlobalKey<_MainNavigationState> navKey = 
      GlobalKey<_MainNavigationState>();

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  // ✅ สีพื้นหลังของแต่ละ tab
  static const List<Color> _bgColors = [
    Color(0xFFFFEFF3), // Home — ชมพูอ่อน
    Color(0xFFFDFAF2), // Tasks — ขาวม่วงอ่อน
    Color(0xFFEFFFDF), // Timer — เขียวอ่อน
    Color(0xFFF2F6FD), // Emotion — ฟ้าอ่อน
    Color(0xFFEDEDFF), // Settings — ม่วงอ่อน
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const TaskScreen(),
    const TimerScreen(),
    const EmotionScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final items = [
      _NavItem(icon: Icons.home_outlined,           activeIcon: Icons.home_rounded,           label: 'Home'),
      _NavItem(icon: Icons.check_box_outlined,      activeIcon: Icons.check_box_rounded,      label: 'Tasks'),
      _NavItem(icon: Icons.timer_outlined,          activeIcon: Icons.timer_rounded,          label: 'Time'),
      _NavItem(icon: Icons.emoji_emotions_outlined, activeIcon: Icons.emoji_emotions_rounded, label: 'Emotion'),
      _NavItem(icon: Icons.settings_outlined,       activeIcon: Icons.settings_rounded,       label: 'Settings'),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: _bgColors[_currentIndex], // ✅ เปลี่ยนสีตาม tab
      body: Stack(
        children: [
          // ✅ Screen content
          IndexedStack(index: _currentIndex, children: _screens),

          // ✅ Floating nav bar
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.80),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B5EA7).withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isActive = _currentIndex == index;

                      return GestureDetector(
                        onTap: () => setState(() => _currentIndex = index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF7B5EA7).withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  key: ValueKey(isActive),
                                  size: 22,
                                  color: isActive
                                      ? const Color(0xFF7B5EA7)
                                      : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                  color: isActive
                                      ? const Color(0xFF7B5EA7)
                                      : Colors.grey.shade400,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}