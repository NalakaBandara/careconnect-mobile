import 'dart:convert';
import 'dart:typed_data';

import 'package:careconnect_mobile/core/config/app_config.dart';
import 'package:flutter/material.dart';

/// Displays a profile photo returned by the API and falls back to initials
/// when the URL is missing, invalid, loading, or cannot be downloaded.
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    required this.imageUrl,
    required this.fallbackLabel,
    required this.size,
    this.borderRadius,
    this.backgroundColor = const Color(0xFFE1F5EF),
    this.foregroundColor = const Color(0xFF008F83),
    this.textStyle,
  });

  final String? imageUrl;
  final String fallbackLabel;
  final double size;
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final Color foregroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: backgroundColor,
      child: Text(
        fallbackLabel.trim().isEmpty
            ? 'CC'
            : fallbackLabel.trim().toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style:
            textStyle ??
            TextStyle(
              color: foregroundColor,
              fontSize: size * 0.27,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
    final image = _profileImage(fallback);

    return Semantics(
      image: image != null,
      label: image == null ? 'Profile placeholder' : 'Profile photo',
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
        child: image ?? fallback,
      ),
    );
  }

  Widget? _profileImage(Widget fallback) {
    final source = imageUrl?.trim();
    if (source == null || source.isEmpty) return null;

    final data = _decodeDataImage(source);
    if (data != null) {
      return Image.memory(
        data,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    final uri = _resolveImageUri(source);
    if (uri == null) return null;
    return Image.network(
      uri.toString(),
      width: size,
      height: size,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return fallback;
      },
      errorBuilder: (_, _, _) => fallback,
    );
  }

  static Uri? _resolveImageUri(String source) {
    final parsed = Uri.tryParse(source);
    if (parsed == null) return null;
    if (parsed.hasScheme) {
      return parsed.scheme == 'http' || parsed.scheme == 'https'
          ? parsed
          : null;
    }
    return AppConfig.apiUri(source);
  }

  static Uint8List? _decodeDataImage(String source) {
    if (!source.startsWith('data:image/') || !source.contains(';base64,')) {
      return null;
    }
    try {
      return base64Decode(source.substring(source.indexOf(',') + 1));
    } on FormatException {
      return null;
    }
  }
}
