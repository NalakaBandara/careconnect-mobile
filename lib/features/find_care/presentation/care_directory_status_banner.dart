import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/find_care/data/care_directory_cache.dart';
import 'package:flutter/material.dart';

class CareDirectoryStatusBanner extends StatelessWidget {
  const CareDirectoryStatusBanner({super.key, required this.source});

  final CareDirectoryStatusSource? source;

  @override
  Widget build(BuildContext context) {
    final statusSource = source;
    if (statusSource == null) return const SizedBox.shrink();
    return ValueListenableBuilder<CareDirectoryStatus>(
      valueListenable: statusSource.directoryStatus,
      builder: (context, status, _) {
        if (!status.shouldShowBanner) return const SizedBox.shrink();
        final isCached = status.mode == CareDirectoryMode.cached;
        return Container(
          key: const Key('care-directory-offline-banner'),
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isCached ? const Color(0xFFFFF4D8) : const Color(0xFFFFE9E7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCached
                  ? const Color(0xFFEBCB79)
                  : const Color(0xFFE7AAA4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCached ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
                size: 20,
                color: isCached ? const Color(0xFF8C6200) : AppColors.coral,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCached
                          ? 'Offline directory'
                          : 'Care directory unavailable',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCached
                          ? 'Showing saved public care information${_savedLabel(status.cachedAt)}. Live availability and booking still need a connection.'
                          : 'Connect to the internet and pull down to try again.',
                      style: TextStyle(
                        color: context.careColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _savedLabel(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final now = DateTime.now();
  final date = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final day = date == today
      ? 'today'
      : '${local.day} ${_months[local.month - 1]}';
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return ' from $day at $hour:$minute $period';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
