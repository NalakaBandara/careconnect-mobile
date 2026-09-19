import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/home/data/home_preview_data.dart';
import 'package:careconnect_mobile/shared/widgets/careconnect_mark.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.firstName,
    required this.onFindCare,
    required this.onAppointments,
    required this.onProfile,
    required this.onNotifications,
  });

  final String? firstName;
  final VoidCallback onFindCare;
  final VoidCallback onAppointments;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final displayName = firstName?.trim().isNotEmpty == true
        ? firstName!
        : 'there';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const Key('home-scroll-view'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 112),
              sliver: SliverList.list(
                children: [
                  _HomeHeader(
                    onProfile: onProfile,
                    onNotifications: onNotifications,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Good morning, $displayName',
                    key: const Key('home-greeting'),
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(fontSize: 31),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'How can we help you feel your best today?',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _FindCareHero(onTap: onFindCare),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: 'Quick actions'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.search_rounded,
                          label: 'Find a doctor',
                          caption: 'Browse care',
                          color: AppColors.primary,
                          background: AppColors.mintSoft,
                          onTap: onFindCare,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.calendar_month_rounded,
                          label: 'Appointments',
                          caption: 'Manage visits',
                          color: const Color(0xFF5276D8),
                          background: AppColors.blueSoft,
                          onTap: onAppointments,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _SectionTitle(
                    title: 'Next appointment',
                    actionLabel: 'View all',
                    onAction: onAppointments,
                  ),
                  const SizedBox(height: 14),
                  _AppointmentCard(
                    appointment: HomePreviewData.appointment,
                    onTap: onAppointments,
                  ),
                  const SizedBox(height: 30),
                  _SectionTitle(
                    title: 'Explore care',
                    actionLabel: 'See all',
                    onAction: onFindCare,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 142,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: HomePreviewData.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, index) => _CategoryCard(
                        category: HomePreviewData.categories[index],
                        onTap: onFindCare,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _WellnessCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onProfile, required this.onNotifications});

  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CareConnectMark(size: 44),
        const SizedBox(width: 11),
        const Text(
          'CareConnect',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        IconButton.filledTonal(
          key: const Key('home-notifications-button'),
          tooltip: 'Notifications',
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onProfile,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lilacSoft,
              shape: BoxShape.circle,
            ),
            child: const Text(
              'CC',
              style: TextStyle(
                color: Color(0xFF7957C8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FindCareHero extends StatelessWidget {
  const _FindCareHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'CARE THAT FITS YOUR DAY',
                style: TextStyle(
                  color: Color(0xFFBFE9DE),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Find trusted care\nnear you.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              key: const Key('home-search'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(17),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.primary),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Doctors, clinics or services',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.ink,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.caption,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 18),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({this.title, this.actionLabel, this.onAction});

  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title ?? '',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onTap});

  final AppointmentPreview appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mintSoft,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: const Key('next-appointment-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      appointment.date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      appointment.day,
                      style: const TextStyle(
                        color: Color(0xFFC6E9E3),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.specialty,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          appointment.time,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final CareCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 142,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const Spacer(),
              Text(
                category.name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                category.caption,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WellnessCard extends StatelessWidget {
  const _WellnessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.wb_sunny_outlined, color: Color(0xFFD87545), size: 28),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A gentle reminder',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Small check-ins with your health can make a big difference.',
                  style: TextStyle(
                    color: AppColors.muted,
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
