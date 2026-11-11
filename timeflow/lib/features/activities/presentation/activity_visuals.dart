import 'package:flutter/material.dart';

abstract final class ActivityVisuals {
  static const icons = <String, IconData>{
    'code': Icons.code_rounded,
    'language': Icons.translate_rounded,
    'workout': Icons.fitness_center_rounded,
    'reading': Icons.menu_book_rounded,
    'design': Icons.draw_rounded,
    'study': Icons.school_rounded,
    'music': Icons.music_note_rounded,
    'walk': Icons.directions_walk_rounded,
    'other': Icons.category_rounded,
  };

  static const colors = <int>[
    0xFF52C7FF,
    0xFF8B7CFF,
    0xFFFF7A90,
    0xFFFFB85C,
    0xFF49D49D,
    0xFF3478F6,
  ];

  static IconData iconFor(String key) => icons[key] ?? Icons.bolt_rounded;
}
