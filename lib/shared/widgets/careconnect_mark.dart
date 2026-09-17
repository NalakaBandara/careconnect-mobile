import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CareConnectMark extends StatelessWidget {
  const CareConnectMark({super.key, this.size = 64, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: onDark ? AppColors.primary : Colors.white,
            size: size * 0.46,
          ),
          Positioned(
            top: size * 0.22,
            right: size * 0.2,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: onDark ? AppColors.coral : AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
