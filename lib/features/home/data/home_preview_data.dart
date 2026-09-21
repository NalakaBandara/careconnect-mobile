import 'package:flutter/material.dart';

class CareCategory {
  const CareCategory({
    required this.name,
    required this.caption,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String name;
  final String caption;
  final IconData icon;
  final Color color;
  final Color background;
}

abstract final class HomePreviewData {
  static const categories = [
    CareCategory(
      name: 'General',
      caption: 'Everyday care',
      icon: Icons.medical_services_outlined,
      color: Color(0xFF087E75),
      background: Color(0xFFE1F5EF),
    ),
    CareCategory(
      name: 'Dental',
      caption: 'Healthy smiles',
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: Color(0xFF5276D8),
      background: Color(0xFFE7EFFE),
    ),
    CareCategory(
      name: 'Wellbeing',
      caption: 'Feel supported',
      icon: Icons.favorite_outline_rounded,
      color: Color(0xFF7957C8),
      background: Color(0xFFF0E9FF),
    ),
  ];
}
