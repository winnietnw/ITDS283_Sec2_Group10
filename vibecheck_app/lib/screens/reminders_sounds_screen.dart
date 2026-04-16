import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RemindersSoundsScreen extends StatefulWidget {
  const RemindersSoundsScreen({super.key});

  @override
  State<RemindersSoundsScreen> createState() => _RemindersSoundsScreenState();
}

class _RemindersSoundsScreenState extends State<RemindersSoundsScreen> {
  static const MethodChannel _settingsChannel =
      MethodChannel('com.example.vibecheck_app/settings');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool emailReminder = false;
  bool dailyReminder = true;
  bool vibration = true;
  bool buttonSound = false;
  bool completionSound = true;
  bool reminderPlanSound = true;

  String appReminderStatus = 'Enabled';
  String emailText = '';
  String morningTime = '09:00';
  String eveningTime = '20:00';
  String morningStatus = 'Pending: Yesterday';
  String eveningStatus = 'Pending: Today';

  final List<String> _appReminderOptions = const ['Enabled', 'Disabled'];

  final List<String> _pendingOptions = const [
    'Pending: Today',
    'Pending: Yesterday',
    'Pending: Tomorrow',
    'Completed',
    'Skipped',
  ];

  @override
  void initState() {
    super.initState();
    emailText = FirebaseAuth.instance.currentUser?.email ?? 'youremail@gmail.com';
    _initializeNotifications();
  }

  Future<void> _showPopupOptions({
    required BuildContext context,
    required TapDownDetails details,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(details.globalPosition.dx, details.globalPosition.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: options
          .map((option) => PopupMenuItem<String>(
                value: option,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(option,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF253142))),
                    ),
                    if (option == currentValue)
                      const Icon(Icons.check, size: 18, color: Color(0xFF8FB8FF)),
                  ],
                ),
              ))
          .toList(),
    );

    if (selected != null) onSelected(selected);
  }

  Future<void> _pickTime({
    required String initialTime,
    required ValueChanged<String> onSelected,
  }) async {
    final parts = initialTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.last) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB7CFFF),
              onPrimary: Colors.black,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onSelected(text);
      _updateReminderSchedule();
    }
  }

  Future<void> _initializeNotifications() async {
    await _configureLocalTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    await _createNotificationChannel();
    await _updateReminderSchedule();
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'vibecheck_reminders',
      'VibeCheck Reminders',
      description: 'แจ้งเตือนเป้าหมายและเสียงเตือน',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _updateReminderSchedule() async {
    if (appReminderStatus == 'Disabled' || !dailyReminder) {
      await _notifications.cancel(1);
      await _notifications.cancel(2);
      return;
    }

    await _scheduleNotification(
      id: 1,
      title: 'Morning Reminder',
      body: 'ถึงเวลาเช็คเป้าหมายของคุณในตอนเช้าแล้ว',
      timeText: morningTime,
    );
    await _scheduleNotification(
      id: 2,
      title: 'Evening Reminder',
      body: 'ถึงเวลาเช็คเป้าหมายของคุณในตอนเย็นแล้ว',
      timeText: eveningTime,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required String timeText,
  }) async {
    final scheduledDate = _nextInstanceOfTime(timeText);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'vibecheck_reminders',
        'VibeCheck Reminders',
        channelDescription: 'แจ้งเตือนเป้าหมายและเสียงเตือน',
        importance: Importance.max,
        priority: Priority.high,
        playSound: reminderPlanSound,
        enableVibration: vibration,
        vibrationPattern: vibration
            ? Int64List.fromList([0, 500, 200, 500])
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: reminderPlanSound,
      ),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(String timeText) {
    final parts = timeText.split(':');
    final int hour = int.tryParse(parts.first) ?? 9;
    final int minute = int.tryParse(parts.last) ?? 0;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _showTestNotification() async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'vibecheck_reminders',
        'VibeCheck Reminders',
        channelDescription: 'แจ้งเตือนเป้าหมายและเสียงเตือน',
        importance: Importance.max,
        priority: Priority.high,
        playSound: reminderPlanSound,
        enableVibration: vibration,
        vibrationPattern: vibration
            ? Int64List.fromList([0, 500, 200, 500])
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: reminderPlanSound,
      ),
    );

    await _notifications.show(
      100,
      'ทดสอบแจ้งเตือน',
      'นี่คือการแจ้งเตือนตัวอย่างพร้อมเสียงและการสั่น',
      details,
    );
    if (vibration) {
      HapticFeedback.vibrate();
    }
  }

  Future<void> _openAppNotificationSettings() async {
    if (!Platform.isAndroid) return;

    try {
      await _settingsChannel.invokeMethod('openAppNotificationSettings');
    } on PlatformException catch (error) {
      debugPrint('Failed to open notification settings: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 40,
                      child: Icon(Icons.arrow_back, size: 24, color: Colors.black87),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Reminders and Sounds',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _settingCard(
                      icon: Icons.notifications_none,
                      title: 'Notification and Reminder',
                      trailing: null,
                      child: Column(
                        children: [
                          _optionTile(
                            leftText: 'APP Reminder',
                            rightText: appReminderStatus,
                            onLeftTap: () {},
                            rightOptions: _appReminderOptions,
                            currentValue: appReminderStatus,
                            onRightSelected: (value) {
                              setState(() => appReminderStatus = value);
                              _updateReminderSchedule();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    _settingCard(
                      icon: Icons.mark_email_unread_outlined,
                      title: 'Email Reminders',
                      trailing: SmallGradientToggle(
                        value: emailReminder,
                        onChanged: (value) => setState(() => emailReminder = value),
                      ),
                      child: _inputLikeTile(leftText: 'Email', rightText: emailText),
                    ),

                    const SizedBox(height: 14),

                    _settingCard(
                      icon: Icons.check_box_outlined,
                      title: 'Daily Reminders',
                      trailing: SmallGradientToggle(
                        value: dailyReminder,
                        onChanged: (value) {
                          setState(() => dailyReminder = value);
                          _updateReminderSchedule();
                        },
                      ),
                      child: Column(
                        children: [
                          _optionTile(
                            leftText: morningTime,
                            rightText: morningStatus,
                            onLeftTap: () => _pickTime(
                              initialTime: morningTime,
                              onSelected: (value) {
                                setState(() => morningTime = value);
                                _updateReminderSchedule();
                              },
                            ),
                            rightOptions: _pendingOptions,
                            currentValue: morningStatus,
                            onRightSelected: (value) =>
                                setState(() => morningStatus = value),
                          ),
                          const SizedBox(height: 10),
                          _optionTile(
                            leftText: eveningTime,
                            rightText: eveningStatus,
                            onLeftTap: () => _pickTime(
                              initialTime: eveningTime,
                              onSelected: (value) {
                                setState(() => eveningTime = value);
                                _updateReminderSchedule();
                              },
                            ),
                            rightOptions: _pendingOptions,
                            currentValue: eveningStatus,
                            onRightSelected: (value) =>
                                setState(() => eveningStatus = value),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    _simpleToggleTile(
                      icon: Icons.vibration,
                      title: 'Vibration',
                      value: vibration,
                      onChanged: (value) {
                        setState(() => vibration = value);
                        if (value) {
                          HapticFeedback.vibrate();
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    _simpleToggleTile(
                      icon: Icons.smart_button_outlined,
                      title: 'Button Sound',
                      value: buttonSound,
                      onChanged: (value) {
                        setState(() => buttonSound = value);
                        if (value) {
                          SystemSound.play(SystemSoundType.click);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    _simpleToggleTile(
                      icon: Icons.check_circle_outline,
                      title: 'Completion Sound',
                      value: completionSound,
                      onChanged: (value) {
                        setState(() => completionSound = value);
                        if (value) {
                          SystemSound.play(SystemSoundType.alert);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    _simpleToggleTile(
                      icon: Icons.edit_calendar_outlined,
                      title: 'Reminder Plan Sound',
                      value: reminderPlanSound,
                      onChanged: (value) => setState(() => reminderPlanSound = value),
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

  Widget _settingCard({
    required IconData icon,
    required String title,
    required Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _simpleToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87)),
          ),
          SmallGradientToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _optionTile({
    required String leftText,
    required String rightText,
    required VoidCallback onLeftTap,
    required List<String> rightOptions,
    required String currentValue,
    required ValueChanged<String> onRightSelected,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLeftTap,
            child: Text(leftText,
                style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          const Spacer(),
          Builder(
            builder: (innerContext) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  _showPopupOptions(
                    context: innerContext,
                    details: details,
                    options: rightOptions,
                    currentValue: currentValue,
                    onSelected: onRightSelected,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 165),
                      child: Text(rightText,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.blueGrey)),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: Colors.black54),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _inputLikeTile(
      {required String leftText, required String rightText}) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(leftText,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(rightText,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
          ),
        ],
      ),
    );
  }
}

class SmallGradientToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SmallGradientToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final trackGradient = value
        ? const LinearGradient(colors: [Color(0xFFDDF2FF), Color(0xFFEFDFFF)])
        : const LinearGradient(colors: [Color(0xFFE7E1EA), Color(0xFFF2EDF4)]);

    final thumbGradient = value
        ? const LinearGradient(colors: [Color(0xFF9ED2FF), Color(0xFFD4B5FF)])
        : const LinearGradient(colors: [Color(0xFF8F8794), Color(0xFFA59DAA)]);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 48,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          gradient: trackGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: thumbGradient,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}