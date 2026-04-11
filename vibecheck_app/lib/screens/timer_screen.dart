// lib/screens/timer_screen.dart
import 'package:flutter/material.dart';
import 'timer_running_screen.dart';
import '../widgets/header.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  String _selectedMode = 'Normal';
  String _selectedFocus = 'Study';
  int _selectedMinutes = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('VibeCheck',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {})
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Set Plan label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Set Plan',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            const SizedBox(height: 20),

            // Focus dropdown
            const Text('Focus', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedFocus,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              items: ['Study', 'Work', 'Exercise', 'Reading']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFocus = v!),
            ),
            const SizedBox(height: 20),

            // Mode selector
            const Text('Mode', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: ['Normal', 'Focus', 'Strict'].map((mode) {
                final isSelected = _selectedMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7B5EA7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(mode,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black54)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Duration picker
            const Text('Duration (minutes)',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [15, 25, 30, 45, 60].map((min) {
                final isSelected = _selectedMinutes == min;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMinutes = min),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7B5EA7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$min',
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black54)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Static clock preview (ไม่เดิน)
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.grey[400]!, width: 3),
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    '$_selectedMinutes:00',
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Start button — ไปหน้า TimerRunningScreen
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TimerRunningScreen(
                        totalSeconds: _selectedMinutes * 60,
                        focusLabel: _selectedFocus,
                        mode: _selectedMode,
                      ),
                    ),
                  );
                },
                label: const Text('Start ▶',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5EA7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}