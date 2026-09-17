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

class AppointmentPreview {
  const AppointmentPreview({
    required this.doctorName,
    required this.specialty,
    required this.clinic,
    required this.day,
    required this.date,
    required this.time,
  });

  final String doctorName;
  final String specialty;
  final String clinic;
  final String day;
  final String date;
  final String time;
}

abstract final class HomePreviewData {
  static const appointment = AppointmentPreview(
    doctorName: 'Dr. Arun Mehta',
    specialty: 'General Practice',
    clinic: 'Northgate Family Practice',
    day: 'THU',
    date: '03',
    time: '09:30',
  );

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
