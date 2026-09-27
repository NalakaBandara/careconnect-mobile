import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/booking/data/booking_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/booking/presentation/booking_flow_screen.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_repository.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:flutter/material.dart';
import 'package:careconnect_mobile/shared/widgets/profile_photo.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({
    super.key,
    required this.professional,
    this.repository,
    this.bookingRepository,
    this.currentUser,
    this.canLoadAvailability = true,
    this.onSignInRequired,
    this.onAppointmentCreated,
    this.onViewAppointments,
  });

  final CareProfessional professional;
  final FindCareDataSource? repository;
  final AppointmentBookingDataSource? bookingRepository;
  final CurrentUser? currentUser;
  final bool canLoadAvailability;
  final VoidCallback? onSignInRequired;
  final ValueChanged<CareAppointment>? onAppointmentCreated;
  final VoidCallback? onViewAppointments;

  @override
  State<ProfessionalProfileScreen> createState() =>
      _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  int _selectedClinic = 0;
  int _selectedDay = 0;
  String? _selectedTime;
  bool _isFavourite = false;
  late CareProfessional _professional;
  bool _isLoading = false;
  bool _availabilityLoading = false;
  String? _error;
  int _availabilityGeneration = 0;

  CareProfessional get professional => _professional;

  @override
  void initState() {
    super.initState();
    _professional = widget.professional;
    if (widget.repository != null) _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await widget.repository!.getProfessionalProfile(
        widget.professional,
      );
      if (!mounted) return;
      setState(() {
        _professional = profile;
        _selectedClinic = 0;
        _selectedDay = 0;
        _selectedTime = null;
      });
      if (widget.canLoadAvailability && profile.clinics.isNotEmpty) {
        await _loadAvailability();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'We could not refresh this professional. The directory summary is still available.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvailability({bool reloadServices = false}) async {
    if (professional.clinics.isEmpty || widget.repository == null) return;
    final generation = ++_availabilityGeneration;
    final clinicId = professional.clinics[_selectedClinic].id;
    setState(() {
      _availabilityLoading = true;
      _error = null;
      _selectedDay = 0;
      _selectedTime = null;
    });
    try {
      final responses = await Future.wait<Object>([
        widget.repository!.getUpcomingAvailability(
          doctorId: professional.id,
          clinicId: clinicId,
        ),
        if (reloadServices)
          widget.repository!.getDoctorServices(
            doctorId: professional.id,
            clinicId: clinicId,
          ),
      ]);
      final availability = responses[0] as List<CareAvailabilityPreview>;
      final services = reloadServices
          ? responses[1] as List<CareService>
          : professional.services;
      if (!mounted || generation != _availabilityGeneration) {
        return;
      }
      final nextLabel = availability.isEmpty
          ? null
          : '${availability.first.day}, ${availability.first.times.first}';
      setState(() {
        _professional = professional.copyWith(
          services: services,
          availability: availability,
          nextAvailableLabel: nextLabel,
        );
      });
    } catch (_) {
      if (!mounted || generation != _availabilityGeneration) return;
      setState(() {
        _error =
            'Available times could not be loaded. Pull back and try again.';
        _professional = professional.copyWith(availability: const []);
      });
    } finally {
      if (mounted && generation == _availabilityGeneration) {
        setState(() => _availabilityLoading = false);
      }
    }
  }

  void _selectClinic(int index) {
    setState(() {
      _selectedClinic = index;
      _professional = professional.copyWith(services: const []);
    });
    if (widget.repository != null && widget.canLoadAvailability) {
      _loadAvailability(reloadServices: true);
    }
  }

  void _beginBooking() {
    if (widget.currentUser == null && widget.onSignInRequired != null) {
      widget.onSignInRequired!();
      return;
    }
    if (professional.services.isEmpty ||
        professional.clinics.isEmpty ||
        professional.availability.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking details are not available for this professional yet.',
          ),
        ),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an available time to continue.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingFlowScreen(
          professional: professional,
          repository: widget.bookingRepository,
          currentUser: widget.currentUser,
          onAppointmentCreated: widget.onAppointmentCreated,
          onViewAppointments: widget.onViewAppointments,
          initialClinicIndex: _selectedClinic,
          initialDayIndex: _selectedDay,
          initialTime: _selectedTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availability = professional.availability;
    final selectedAvailability = availability.isEmpty
        ? null
        : availability[_selectedDay.clamp(0, availability.length - 1)];
    final requiresSignIn =
        widget.currentUser == null && widget.onSignInRequired != null;
    final hasBookingDetails =
        professional.services.isNotEmpty &&
        professional.clinics.isNotEmpty &&
        professional.availability.isNotEmpty;
    final canBeginBooking =
        !_isLoading &&
        !_availabilityLoading &&
        (requiresSignIn || (hasBookingDetails && _selectedTime != null));

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Professional profile'),
        actions: [
          IconButton(
            key: const Key('favourite-professional'),
            tooltip: _isFavourite
                ? 'Remove from favourites'
                : 'Add to favourites',
            onPressed: () => setState(() => _isFavourite = !_isFavourite),
            icon: Icon(
              _isFavourite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavourite ? AppColors.coral : AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        key: const Key('professional-profile-scroll-view'),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 126),
        children: [
          _ProfileHero(professional: professional),
          if (_isLoading) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(
              key: Key('professional-profile-loading'),
              minHeight: 3,
              borderRadius: BorderRadius.all(Radius.circular(99)),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            _ProfileError(message: _error!, onRetry: _loadProfile),
          ],
          const SizedBox(height: 28),
          const _SectionHeading(title: 'About'),
          const SizedBox(height: 11),
          Text(
            professional.bio ??
                'A trusted healthcare professional committed to clear, compassionate care.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 14),
          ),
          if (professional.specialties.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: professional.specialties
                  .map(
                    (specialty) => Chip(
                      avatar: const Icon(
                        Icons.medical_services_outlined,
                        size: 16,
                      ),
                      label: Text(specialty.name),
                      backgroundColor: AppColors.mintSoft,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 30),
          const _SectionHeading(
            title: 'Services',
            caption: 'Choose the care you need',
          ),
          const SizedBox(height: 13),
          if (professional.services.isEmpty)
            const _InlineEmpty(
              icon: Icons.medical_information_outlined,
              message: 'Services will appear when the clinic confirms them.',
            )
          else
            ...professional.services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceCard(service: service),
              ),
            ),
          const SizedBox(height: 20),
          const _SectionHeading(
            title: 'Practice location',
            caption: 'Select where you would like to visit',
          ),
          const SizedBox(height: 13),
          if (professional.clinics.isEmpty)
            const _InlineEmpty(
              icon: Icons.location_off_outlined,
              message: 'No clinic location is currently listed.',
            )
          else
            ...List.generate(
              professional.clinics.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ClinicCard(
                  clinic: professional.clinics[index],
                  selected: index == _selectedClinic,
                  onTap: () => _selectClinic(index),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const _SectionHeading(
            title: 'Next availability',
            caption: 'Times shown in your local timezone',
          ),
          const SizedBox(height: 14),
          if (_availabilityLoading)
            const _AvailabilityLoading()
          else if (availability.isEmpty)
            const _InlineEmpty(
              icon: Icons.event_busy_outlined,
              message: 'No appointment times are currently available.',
            )
          else ...[
            SizedBox(
              height: 66,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availability.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (_, index) {
                  final item = availability[index];
                  final selected = index == _selectedDay;
                  return ChoiceChip(
                    key: ValueKey('availability-day-$index'),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedDay = index;
                      _selectedTime = null;
                    }),
                    selectedColor: AppColors.primaryDark,
                    backgroundColor: context.careColors.card,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryDark
                          : context.careColors.border,
                    ),
                    showCheckmark: false,
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.day,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.date,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFFBFE9DE)
                                  : context.careColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: (selectedAvailability?.times ?? const [])
                  .map(
                    (time) => ChoiceChip(
                      key: ValueKey('availability-time-$time'),
                      label: Text(time),
                      selected: time == _selectedTime,
                      onSelected: (_) => setState(() => _selectedTime = time),
                      selectedColor: AppColors.mintSoft,
                      side: BorderSide(
                        color: time == _selectedTime
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      showCheckmark: false,
                      labelStyle: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: FilledButton.icon(
          key: const Key('book-professional-button'),
          onPressed: canBeginBooking ? _beginBooking : null,
          icon: const Icon(Icons.calendar_month_rounded, size: 20),
          label: Text(
            requiresSignIn
                ? 'Sign in to book'
                : professional.services.isEmpty
                ? 'Service required to book'
                : professional.clinics.isEmpty
                ? 'Clinic required to book'
                : professional.availability.isEmpty
                ? 'No times available'
                : _selectedTime == null
                ? 'Choose a time to book'
                : 'Continue with $_selectedTime',
          ),
        ),
      ),
    );
  }
}

class _AvailabilityLoading extends StatelessWidget {
  const _AvailabilityLoading();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('professional-availability-loading'),
    padding: const EdgeInsets.symmetric(vertical: 26),
    alignment: Alignment.center,
    child: const Column(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        SizedBox(height: 12),
        Text(
          'Checking the next available times…',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('professional-profile-error'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFB84C4C)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.professional});

  final CareProfessional professional;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfilePhoto(
                key: const Key('professional-profile-photo'),
                imageUrl: professional.profilePhoto,
                fallbackLabel: professional.initials,
                size: 76,
                borderRadius: BorderRadius.circular(23),
                backgroundColor: Colors.white,
                textStyle: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.displayName,
                      key: const Key('professional-profile-name'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      professional.primarySpecialty,
                      style: const TextStyle(
                        color: Color(0xFFBFE9DE),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (professional.isVerified) ...[
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: AppColors.accent,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Verified professional',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    value: professional.rating?.toStringAsFixed(1) ?? 'New',
                    label: 'Rating',
                    icon: Icons.star_rounded,
                  ),
                ),
                Container(width: 1, height: 34, color: Colors.white24),
                Expanded(
                  child: _HeroStat(
                    value: '${professional.yearsOfExperience ?? 0} yrs',
                    label: 'Experience',
                    icon: Icons.workspace_premium_outlined,
                  ),
                ),
                Container(width: 1, height: 34, color: Colors.white24),
                Expanded(
                  child: _HeroStat(
                    value: '${professional.clinics.length}',
                    label: 'Locations',
                    icon: Icons.location_on_outlined,
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

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accent, size: 15),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFBFE9DE), fontSize: 10),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final CareService service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.careColors.card,
        border: Border.all(color: context.careColors.border),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Color(0xFF5276D8),
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (service.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    service.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (service.durationMinutes != null)
            Text(
              '${service.durationMinutes} min',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({
    required this.clinic,
    required this.selected,
    required this.onTap,
  });

  final CareClinicSummary clinic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.careColors.softSurface
          : context.careColors.card,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primary : context.careColors.border,
            ),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (clinic.city != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        clinic.city!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
