import 'dart:async';
import 'package:flutter/material.dart';

class TimerProvider extends ChangeNotifier {
  int totalSeconds = 1800;
  int remainingSeconds = 1800;
  Timer? _timer;
  bool isRunning = false;

  void start(int seconds) {
    totalSeconds = seconds;
    remainingSeconds = seconds;
    isRunning = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        stop();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    isRunning = false;
    notifyListeners();
  }

  String get timeFormatted {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }
}