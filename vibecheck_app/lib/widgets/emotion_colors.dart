
import 'package:flutter/material.dart';

class EmotionColors {
  static const Map<String, Color> map = {
    "happy": Color(0xFFFDFFB6),
    "calm": Color(0xFF9BF6FF),
    "neutral": Color(0xFFEBDEBE),
    "stressed": Color(0xFF94C9C7),
    "love": Color(0xFFFCC5D9),
    "burnout": Color(0xFFE6E6FA),
    "angry": Color(0xFFFF9292),
    "sad": Color(0xFFB3E1F8),

  };

  static Color get(String type) {
    return map[type] ?? const Color(0xFFE6E6FA);
  }
}