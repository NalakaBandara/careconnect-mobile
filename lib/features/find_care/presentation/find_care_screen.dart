import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/booking/data/booking_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_preview_data.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_repository.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:careconnect_mobile/features/find_care/presentation/professional_profile_screen.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:flutter/material.dart';

class FindCareScreen extends StatefulWidget {
  const FindCareScreen({
    super.key,
    this.repository,
    this.bookingRepository,
    this.currentUser,
    this.onAppointmentCreated,
    this.onViewAppointments,
    this.onNotifications,
  });

  final FindCareDataSource? repository;
  final AppointmentBookingDataSource? bookingRepository;
  final CurrentUser? currentUser;
  final ValueChanged<CareAppointment>? onAppointmentCreated;
  final VoidCallback? onViewAppointments;
  final VoidCallback? onNotifications;

  @override
  State<FindCareScreen> createState() => _FindCareScreenState();
}

class _FindCareScreenState extends State<FindCareScreen> {
  final _searchController = TextEditingController();
  String _selectedSpecialty = 'All';
  bool _verifiedOnly = false;
  bool _availableSoon = false;
  late List<CareProfessional> _professionals;
  late List<CareSpecialty> _specialties;
  bool _isLoading = false;
  String? _error;
  int _requestGeneration = 0;

  bool get _isPreview => widget.repository == null;

  List<CareProfessional> get _results {
    final query = _searchController.text.trim().toLowerCase();
    return _professionals
        .where((professional) {
          final matchesSpecialty =
              _selectedSpecialty == 'All' ||
              professional.specialties.any(
                (specialty) => specialty.name == _selectedSpecialty,
              );
          final searchableText = [
            professional.displayName,
            professional.primarySpecialty,
            professional.primaryClinic,
            professional.city ?? '',
          ].join(' ').toLowerCase();
          final matchesSearch = query.isEmpty || searchableText.contains(query);
          final matchesVerified = !_verifiedOnly || professional.isVerified;
          final matchesAvailability =
              !_availableSoon ||
              !_isPreview ||
              (professional.nextAvailableLabel?.startsWith('Today') ?? false);
          return matchesSpecialty &&
              matchesSearch &&
              matchesVerified &&
              matchesAvailability;
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _professionals = _isPreview
        ? List.of(FindCarePreviewData.professionals)
        : [];
    _specialties = _isPreview
        ? FindCarePreviewData.specialties
              .where((name) => name != 'All')
              .map((name) => CareSpecialty(id: name, name: name))
              .toList()
        : [];
    if (!_isPreview) _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final generation = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository!.getSpecialties(),
        widget.repository!.getDoctors(),
      ]);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _specialties = results[0] as List<CareSpecialty>;
        _professionals = results[1] as List<CareProfessional>;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error =
            'We could not load care professionals. Check your connection and try again.';
      });
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDoctors({String? specialtyId}) async {
    final generation = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final doctors = await widget.repository!.getDoctors(
        specialtyId: specialtyId,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() => _professionals = doctors);
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = 'The selected care options could not be loaded. Try again.';
      });
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectSpecialty(String name) {
    setState(() => _selectedSpecialty = name);
    if (_isPreview) return;
    String? specialtyId;
    for (final specialty in _specialties) {
      if (specialty.name == name) specialtyId = specialty.id;
    }
    _loadDoctors(specialtyId: specialtyId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_FilterSelection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        initialVerifiedOnly: _verifiedOnly,
        initialAvailableSoon: _availableSoon,
        supportsAvailabilityFilter: _isPreview,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _verifiedOnly = result.verifiedOnly;
      _availableSoon = result.availableSoon;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    final shouldReload = !_isPreview && _selectedSpecialty != 'All';
    setState(() {
      _selectedSpecialty = 'All';
      _verifiedOnly = false;
      _availableSoon = false;
    });
    if (shouldReload) _loadDoctors();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final activeFilterCount =
        (_verifiedOnly ? 1 : 0) + (_availableSoon ? 1 : 0);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const Key('find-care-scroll-view'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Find care',
                          key: const Key('find-care-title'),
                          style: Theme.of(
                            context,
                          ).textTheme.displaySmall?.copyWith(fontSize: 32),
                        ),
                      ),
                      IconButton.filledTonal(
                        key: const Key('find-care-notifications-button'),
                        tooltip: 'Notifications',
                        onPressed: widget.onNotifications,
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Search professionals, specialties, clinics, or locations.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    key: const Key('find-care-search-field'),
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'What care are you looking for?',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _specialties.length + 2,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          return ActionChip(
                            key: const Key('open-care-filters'),
                            onPressed: _openFilters,
                            avatar: const Icon(Icons.tune_rounded, size: 17),
                            label: Text(
                              activeFilterCount == 0
                                  ? 'Filters'
                                  : 'Filters $activeFilterCount',
                            ),
                            backgroundColor: activeFilterCount == 0
                                ? Colors.white
                                : AppColors.mintSoft,
                            side: const BorderSide(color: AppColors.border),
                          );
                        }
                        final specialty = index == 1
                            ? 'All'
                            : _specialties[index - 2].name;
                        return ChoiceChip(
                          label: Text(specialty),
                          selected: specialty == _selectedSpecialty,
                          onSelected: (_) => _selectSpecialty(specialty),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: specialty == _selectedSpecialty
                                ? Colors.white
                                : AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(
                      key: Key('find-care-loading'),
                      minHeight: 3,
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                    ),
                  ],
                  const SizedBox(height: 27),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          results.isEmpty
                              ? 'No matches yet'
                              : results.length == 1
                              ? '1 professional'
                              : '${results.length} professionals',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 20),
                        ),
                      ),
                      if (activeFilterCount > 0 || _selectedSpecialty != 'All')
                        TextButton(
                          key: const Key('clear-care-filters'),
                          onPressed: _clearFilters,
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  if (_error != null)
                    _ErrorResults(message: _error!, onRetry: _loadCatalog)
                  else if (results.isEmpty && _isLoading)
                    const _LoadingResults()
                  else if (results.isEmpty)
                    _EmptyResults(onClear: _clearFilters)
                  else
                    for (var index = 0; index < results.length; index++) ...[
                      _ProfessionalCard(
                        professional: results[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProfessionalProfileScreen(
                              professional: results[index],
                              repository: widget.repository,
                              bookingRepository: widget.bookingRepository,
                              currentUser: widget.currentUser,
                              onAppointmentCreated: widget.onAppointmentCreated,
                              onViewAppointments: widget.onViewAppointments,
                            ),
                          ),
                        ),
                      ),
                      if (index != results.length - 1)
                        const SizedBox(height: 13),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({required this.professional, required this.onTap});

  final CareProfessional professional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        key: ValueKey('professional-${professional.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      professional.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                professional.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (professional.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.primary,
                                size: 17,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          professional.primarySpecialty,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${professional.yearsOfExperience ?? 0} years experience',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: AppColors.muted,
                    size: 21,
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (professional.rating != null)
                    _InfoPill(
                      icon: Icons.star_rounded,
                      label: professional.rating!.toStringAsFixed(1),
                      foreground: const Color(0xFF9B6400),
                      background: const Color(0xFFFFF3D9),
                    ),
                  if (professional.nextAvailableLabel != null)
                    _InfoPill(
                      icon: Icons.schedule_rounded,
                      label: professional.nextAvailableLabel!,
                      foreground: AppColors.primary,
                      background: AppColors.mintSoft,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${professional.primaryClinic}${professional.city == null ? '' : ' · ${professional.city}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'View profile',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.mintSoft,
            child: Icon(
              Icons.search_off_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Try a different search',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Change the specialty, location, or filters to discover more care options.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          TextButton(onPressed: onClear, child: const Text('Clear search')),
        ],
      ),
    );
  }
}

class _LoadingResults extends StatelessWidget {
  const _LoadingResults();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Finding trusted care near you…',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _ErrorResults extends StatelessWidget {
  const _ErrorResults({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('find-care-error'),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        const CircleAvatar(
          radius: 32,
          backgroundColor: Color(0xFFFFE8E3),
          child: Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFB84C4C),
            size: 29,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Care directory unavailable',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 18),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialVerifiedOnly,
    required this.initialAvailableSoon,
    required this.supportsAvailabilityFilter,
  });

  final bool initialVerifiedOnly;
  final bool initialAvailableSoon;
  final bool supportsAvailabilityFilter;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _verifiedOnly = widget.initialVerifiedOnly;
  late bool _availableSoon = widget.initialAvailableSoon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Refine your search',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Choose what matters most for this visit.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Verified professionals only'),
              subtitle: const Text('Show verified CareConnect profiles'),
              value: _verifiedOnly,
              onChanged: (value) => setState(() => _verifiedOnly = value),
            ),
            if (widget.supportsAvailabilityFilter)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available today'),
                subtitle: const Text('Prioritize care you can book soon'),
                value: _availableSoon,
                onChanged: (value) => setState(() => _availableSoon = value),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Open a professional profile to see live appointment times.',
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('apply-care-filters'),
              onPressed: () => Navigator.of(context).pop(
                _FilterSelection(
                  verifiedOnly: _verifiedOnly,
                  availableSoon: _availableSoon,
                ),
              ),
              child: const Text('Show results'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSelection {
  const _FilterSelection({
    required this.verifiedOnly,
    required this.availableSoon,
  });

  final bool verifiedOnly;
  final bool availableSoon;
}
