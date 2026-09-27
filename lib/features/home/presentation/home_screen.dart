import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_preview_data.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_controller.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/find_care/data/care_directory_cache.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_repository.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:careconnect_mobile/features/find_care/presentation/care_directory_status_banner.dart';
import 'package:careconnect_mobile/features/home/data/home_preview_data.dart';
import 'package:careconnect_mobile/shared/widgets/careconnect_mark.dart';
import 'package:careconnect_mobile/shared/widgets/profile_photo.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.firstName,
    this.profilePhoto,
    this.repository,
    this.appointmentsController,
    this.careRepository,
    this.isGuest = false,
    this.usePreviewData = true,
    this.onSignInRequired,
    required this.onFindCare,
    required this.onAppointments,
    required this.onProfile,
    required this.onNotifications,
  });

  final String? firstName;
  final String? profilePhoto;
  final AppointmentsDataSource? repository;
  final AppointmentsController? appointmentsController;
  final FindCareDataSource? careRepository;
  final bool isGuest;
  final bool usePreviewData;
  final VoidCallback? onSignInRequired;

  final VoidCallback onFindCare;
  final VoidCallback onAppointments;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<CareAppointment> _appointments;
  late List<CareCategory> _categories;

  bool _isLoading = false;
  String? _error;

  AppointmentsController? _controller;
  bool _ownsController = false;

  bool get _hasLiveAppointments =>
      widget.repository != null || widget.appointmentsController != null;
  bool get _isPreview =>
      widget.usePreviewData &&
      !widget.isGuest &&
      widget.repository == null &&
      widget.appointmentsController == null;

  @override
  void initState() {
    super.initState();

    _appointments = _isPreview
        ? List.of(AppointmentsPreviewData.appointments)
        : [];
    _categories = widget.careRepository == null && widget.usePreviewData
        ? List.of(HomePreviewData.categories)
        : [];

    if (_hasLiveAppointments) {
      _controller = widget.appointmentsController;

      if (_controller == null) {
        _controller = AppointmentsController(widget.repository!);
        _ownsController = true;
      }

      _controller!.addListener(_syncAppointments);
      _syncAppointments();
      _controller!.load();
    }
    if (widget.careRepository != null) _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final specialties = await widget.careRepository!.getSpecialties();
      if (!mounted) return;
      setState(() {
        _categories = specialties
            .take(8)
            .toList(growable: false)
            .asMap()
            .entries
            .map((entry) => _categoryFromSpecialty(entry.value, entry.key))
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _categories = []);
    }
  }

  CareCategory _categoryFromSpecialty(CareSpecialty specialty, int index) {
    const styles = [
      (Icons.medical_services_outlined, Color(0xFF087E75), Color(0xFFE1F5EF)),
      (Icons.favorite_outline_rounded, Color(0xFF7957C8), Color(0xFFF0E9FF)),
      (Icons.health_and_safety_outlined, Color(0xFF5276D8), Color(0xFFE7EFFE)),
      (Icons.healing_rounded, Color(0xFF9A6810), Color(0xFFFFF1D2)),
    ];
    final style = styles[index % styles.length];
    return CareCategory(
      name: specialty.name,
      caption: specialty.description?.trim().isNotEmpty == true
          ? specialty.description!.trim()
          : 'View specialists',
      icon: style.$1,
      color: style.$2,
      background: style.$3,
    );
  }

  void _syncAppointments() {
    if (!mounted) return;

    setState(() {
      _appointments = _controller!.appointments;
      _isLoading = _controller!.isLoading;

      _error = _controller!.error == null
          ? null
          : 'We could not load your dashboard. Check your connection and try again.';
    });
  }

  Future<void> _refreshDashboard() async {
    final tasks = <Future<void>>[];
    if (_controller != null) tasks.add(_controller!.refresh());
    if (widget.careRepository != null) tasks.add(_loadCategories());
    if (tasks.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }
    await Future.wait(tasks);
  }

  @override
  void dispose() {
    _controller?.removeListener(_syncAppointments);

    if (_ownsController) {
      _controller?.dispose();
    }

    super.dispose();
  }

  List<CareAppointment> get _upcomingAppointments {
    final appointments = _appointments
        .where((appointment) => !appointment.isPast)
        .toList(growable: false);

    appointments.sort((a, b) {
      final dateComparison = a.appointmentDate.compareTo(b.appointmentDate);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return a.startTime.compareTo(b.startTime);
    });

    return appointments;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.firstName?.trim().isNotEmpty == true
        ? widget.firstName!.trim()
        : 'there';

    final upcoming = _upcomingAppointments;

    final nextAppointment = upcoming.isEmpty ? null : upcoming.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFB),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshDashboard,
          child: CustomScrollView(
            key: const Key('home-scroll-view'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HomeHeader(
                      firstName: widget.firstName,
                      profilePhoto: widget.profilePhoto,
                      onProfile: widget.onProfile,
                      onNotifications: widget.onNotifications,
                    ),

                    const SizedBox(height: 18),

                    CareDirectoryStatusBanner(
                      source: widget.careRepository is CareDirectoryStatusSource
                          ? widget.careRepository as CareDirectoryStatusSource
                          : null,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'GOOD MORNING',
                      style: TextStyle(
                        color: Color(0xFF80969A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            key: const Key('home-greeting'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF092B31),
                              fontSize: 34,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        const Text('👋', style: TextStyle(fontSize: 25)),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'How can we help you feel your best today?',
                      style: TextStyle(
                        color: Color(0xFF7F9296),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _FindCareHero(onTap: widget.onFindCare),

                    const SizedBox(height: 26),

                    _SectionTitle(
                      title: 'Quick actions',
                      actionLabel: 'See all',
                      onAction: widget.onFindCare,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.search_rounded,
                            label: 'Find a doctor',
                            caption: 'Browse care',
                            color: AppColors.primary,
                            background: AppColors.mintSoft,
                            onTap: widget.onFindCare,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _QuickAction(
                            icon: Icons.calendar_month_rounded,
                            label: 'Appointments',
                            caption: widget.isGuest
                                ? 'Sign in to view'
                                : '${upcoming.length} upcoming '
                                      '${upcoming.length == 1 ? 'visit' : 'visits'}',
                            color: const Color(0xFF5276D8),
                            background: AppColors.blueSoft,
                            onTap: widget.onAppointments,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    _SectionTitle(
                      title: 'Next appointment',
                      actionLabel: 'View all',
                      onAction: widget.onAppointments,
                    ),

                    const SizedBox(height: 12),

                    if (widget.isGuest)
                      _GuestAppointmentsCard(onSignIn: widget.onSignInRequired)
                    else if (_isLoading && nextAppointment == null)
                      const _DashboardLoading()
                    else if (_error != null && nextAppointment == null)
                      _DashboardError(
                        message: _error!,
                        onRetry: _refreshDashboard,
                      )
                    else if (nextAppointment == null)
                      _NoUpcomingAppointments(onFindCare: widget.onFindCare)
                    else
                      _AppointmentCard(
                        appointment: nextAppointment,
                        onTap: widget.onAppointments,
                      ),

                    const SizedBox(height: 26),

                    _SectionTitle(
                      title: 'Explore care',
                      actionLabel: 'See all',
                      onAction: widget.onFindCare,
                    ),

                    const SizedBox(height: 12),

                    if (_categories.isEmpty)
                      _CareCategoriesEmpty(onFindCare: widget.onFindCare)
                    else
                      SizedBox(
                        height: 138,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return _CategoryCard(
                              category: _categories[index],
                              onTap: widget.onFindCare,
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 22),

                    const _WellnessCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.firstName,
    required this.profilePhoto,
    required this.onProfile,
    required this.onNotifications,
  });

  final String? firstName;
  final String? profilePhoto;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Row(
            children: [
              CareConnectMark(size: 48),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                        children: [
                          TextSpan(
                            text: 'Care',
                            style: TextStyle(color: Color(0xFF102B32)),
                          ),
                          TextSpan(
                            text: 'Connect',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Your Health, Our Priority',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF8B9EA1),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Tooltip(
          message: 'Notifications',
          child: Material(
            color: const Color(0xFFE3F5F1),
            shape: const CircleBorder(),
            child: InkWell(
              key: const Key('home-notifications-button'),
              onTap: onNotifications,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF17464B),
                  size: 21,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 7),

        Tooltip(
          message: 'Profile',
          child: Material(
            color: const Color(0xFFF3EAFE),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onProfile,
              customBorder: const CircleBorder(),
              child: ProfilePhoto(
                key: const Key('home-user-profile-photo'),
                imageUrl: profilePhoto,
                fallbackLabel: _initials(firstName),
                size: 42,
                backgroundColor: const Color(0xFFF3EAFE),
                foregroundColor: const Color(0xFF8159D9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String? value) {
    final name = value?.trim();

    if (name == null || name.isEmpty) {
      return 'CC';
    }

    return name[0].toUpperCase();
  }
}

class _FindCareHero extends StatelessWidget {
  const _FindCareHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -48,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            Positioned(
              right: 16,
              top: 52,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Color(0xFF7CE4D7),
                  size: 40,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF8CF0E1),
                        size: 15,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'CARE THAT FITS YOUR DAY',
                        style: TextStyle(
                          color: Color(0xFFD2F3EE),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const SizedBox(
                    width: 220,
                    child: Text(
                      'Find trusted care\nnear you.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      key: const Key('home-search'),
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            const Expanded(
                              child: Text(
                                'Doctors, clinics or services',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF849699),
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F7F4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF16373C),
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),

        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
              ],
            ),
          ),
      ],
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
      color: context.careColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 112,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 19),
                  ),

                  const Spacer(),

                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F8F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF547075),
                      size: 17,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF14353A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF8A9C9F), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onTap});

  final CareAppointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF8F5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('next-appointment-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${appointment.date?.day ?? '--'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _weekday(appointment.date),
                      style: const TextStyle(
                        color: Color(0xFFCCF1EC),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctor.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF13363B),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      appointment.service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Color(0xFF83979A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.startTime,
                          style: const TextStyle(
                            color: Color(0xFF83979A),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekday(DateTime? date) {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    if (date == null) {
      return '';
    }

    return labels[date.weekday - 1];
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-dashboard-loading'),
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-dashboard-error'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5D1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFD87545),
              size: 18,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF667B7F),
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),

          IconButton(
            key: const Key('home-dashboard-retry'),
            tooltip: 'Try again',
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestAppointmentsCard extends StatelessWidget {
  const _GuestAppointmentsCard({this.onSignIn});

  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('home-guest-appointments'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.mintSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign in to see your visits',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text(
                'Your appointments will stay private and appear here.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        TextButton(
          key: const Key('home-guest-sign-in'),
          onPressed: onSignIn,
          child: const Text('Sign in'),
        ),
      ],
    ),
  );
}

class _CareCategoriesEmpty extends StatelessWidget {
  const _CareCategoriesEmpty({required this.onFindCare});

  final VoidCallback onFindCare;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('home-care-categories-empty'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.careColors.card,
      border: Border.all(color: context.careColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Browse the care directory to find the right specialist.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        TextButton(onPressed: onFindCare, child: const Text('Find care')),
      ],
    ),
  );
}

class _NoUpcomingAppointments extends StatelessWidget {
  const _NoUpcomingAppointments({required this.onFindCare});

  final VoidCallback onFindCare;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF8F5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('home-dashboard-empty'),
        onTap: onFindCare,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No upcoming visits.',
                      style: TextStyle(
                        color: Color(0xFF17383D),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Find care whenever you are ready.',
                      style: TextStyle(
                        color: Color(0xFF789093),
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
              ),
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
      color: context.careColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: category.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.color, size: 19),
              ),

              const Spacer(),

              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF15363B),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                category.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF8A9C9F), fontSize: 9.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6EC), Color(0xFFFFF0E3)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE6D0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: Color(0xFFE07036),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A gentle reminder',
                  style: TextStyle(
                    color: Color(0xFF17383D),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Small check-ins with your health can make a big difference.',
                  style: TextStyle(
                    color: Color(0xFF819396),
                    fontSize: 11,
                    height: 1.3,
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
