import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class CareConnectBrandAssets {
  static const icon = 'assets/branding/careconnect-icon.svg';
  static const logo = 'assets/branding/careconnect-logo.svg';
}

class CareConnectMark extends StatelessWidget {
  const CareConnectMark({
    super.key,
    this.size = 64,
    this.onDark = false,
    this.showShadow = true,
  });

  final double size;
  final bool onDark;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: onDark ? 0.16 : 0.1),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: SvgPicture.asset(
        CareConnectBrandAssets.icon,
        width: size,
        height: size,
        semanticsLabel: 'CareConnect',
      ),
    );
  }
}

class CareConnectLogo extends StatelessWidget {
  const CareConnectLogo({super.key, this.width = 246, this.showShadow = false});

  final double width;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      CareConnectBrandAssets.logo,
      width: width,
      semanticsLabel: 'CareConnect',
    );

    if (!showShadow) return logo;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: logo,
    );
  }
}
