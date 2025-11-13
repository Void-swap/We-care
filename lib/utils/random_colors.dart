import 'dart:math';

import 'package:flutter/material.dart';

Color getRandomColor() {
  final List<Color> colors = [
    Color(0xFFFFCBAE),
    Color(0xFFB2E0D9),
    Color(0xFFD6B2E5)
  ];

  final Random random = Random();
  return colors[random.nextInt(colors.length)];
}
