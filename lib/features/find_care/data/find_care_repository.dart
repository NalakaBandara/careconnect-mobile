import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/find_care/data/care_directory_cache.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:flutter/foundation.dart';

abstract interface class FindCareDataSource {
  Future<List<CareSpecialty>> getSpecialties();

  Future<List<CareProfessional>> getDoctors({
    String? specialtyId,
    String? clinicId,
  });

  Future<CareProfessional> getProfessionalProfile(CareProfessional summary);

  Future<List<CareService>> getDoctorServices({
    required String doctorId,
    required String clinicId,
  });

  Future<List<CareAvailabilityPreview>> getUpcomingAvailability({
    required String doctorId,
    required String clinicId,
    int days = 7,
  });
}

class FindCareRepository
    implements FindCareDataSource, CareDirectoryStatusSource {
  FindCareRepository(this._client, {CareDirectoryCacheStore? cacheStore})
    : _cacheStore = cacheStore ?? SecureCareDirectoryCacheStore();

  static const _specialtiesCacheKey = 'specialties';
  static const _directoryCacheKey = 'doctors_and_clinics';
  final ApiClient _client;
  final CareDirectoryCacheStore _cacheStore;
  final ValueNotifier<CareDirectoryStatus> _directoryStatus = ValueNotifier(
    const CareDirectoryStatus.online(),
  );
  final Map<String, CareDirectoryStatus> _resourceStatuses = {};

  @override
  ValueListenable<CareDirectoryStatus> get directoryStatus => _directoryStatus;

  void dispose() => _directoryStatus.dispose();

  @override
  Future<List<CareSpecialty>> getSpecialties() async {
    try {
      final response = await _client.get(ApiEndpoints.specialties);
      await _writeCache(_specialtiesCacheKey, response);
      _markOnline(_specialtiesCacheKey);
      return _specialtiesFromResponse(response);
    } catch (error, stackTrace) {
      final cached = await _readCache(_specialtiesCacheKey);
      if (cached != null) {
        _markCached(_specialtiesCacheKey, cached.cachedAt);
        return _specialtiesFromResponse(cached.data);
      }
      _markUnavailable(_specialtiesCacheKey);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<List<CareClinicSummary>> getClinics() async {
    try {
      final response = await _client.get(ApiEndpoints.clinics);
      _markOnline(_directoryCacheKey);
      return _clinicsFromResponse(response);
    } catch (error, stackTrace) {
      final cached = await _readCache(_directoryCacheKey);
      final cachedData = cached?.data;
      if (cached != null && cachedData is Map<String, dynamic>) {
        _markCached(_directoryCacheKey, cached.cachedAt);
        return _clinicsFromResponse(cachedData['clinics']);
      }
      _markUnavailable(_directoryCacheKey);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<CareProfessional>> getDoctors({
    String? specialtyId,
    String? clinicId,
  }) async {
    try {
      final responses = await Future.wait<Object?>([
        _client.get(
          ApiEndpoints.doctors,
          queryParameters: {'specialtyId': ?specialtyId, 'clinicId': ?clinicId},
        ),
        _client.get(ApiEndpoints.clinics),
      ]);
      if (specialtyId == null && clinicId == null) {
        await _writeCache(_directoryCacheKey, {
          'doctors': responses[0],
          'clinics': responses[1],
        });
      }
      _markOnline(_directoryCacheKey);
      return _doctorsFromResponses(
        responses[0],
        responses[1],
        specialtyId: specialtyId,
        clinicId: clinicId,
      );
    } catch (error, stackTrace) {
      final cached = await _readCache(_directoryCacheKey);
      final cachedData = cached?.data;
      if (cached != null && cachedData is Map<String, dynamic>) {
        _markCached(_directoryCacheKey, cached.cachedAt);
        return _doctorsFromResponses(
          cachedData['doctors'],
          cachedData['clinics'],
          specialtyId: specialtyId,
          clinicId: clinicId,
        );
      }
      _markUnavailable(_directoryCacheKey);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  List<CareProfessional> _doctorsFromResponses(
    Object? doctorsResponse,
    Object? clinicsResponse, {
    String? specialtyId,
    String? clinicId,
  }) {
    final clinics = _clinicsFromResponse(clinicsResponse);
    final clinicById = {for (final clinic in clinics) clinic.id: clinic};
    return _listFromResponse(doctorsResponse)
        .map((json) {
          final doctor = CareProfessional.fromJson(json);
          return doctor.copyWith(
            clinics: doctor.clinics
                .map((clinic) => clinicById[clinic.id] ?? clinic)
                .toList(growable: false),
          );
        })
        .where(
          (doctor) =>
              (specialtyId == null ||
                  doctor.specialties.any(
                    (specialty) => specialty.id == specialtyId,
                  )) &&
              (clinicId == null ||
                  doctor.clinics.any((clinic) => clinic.id == clinicId)),
        )
        .toList(growable: false);
  }

  List<CareSpecialty> _specialtiesFromResponse(Object? response) =>
      _listFromResponse(response).map(CareSpecialty.fromJson).toList();

  List<CareClinicSummary> _clinicsFromResponse(Object? response) =>
      _listFromResponse(response).map(CareClinicSummary.fromJson).toList();

  Future<CareProfessional> getDoctor(String id) async {
    final response = await _client.get(ApiEndpoints.doctor(id));
    if (response case {'data': final Map<String, dynamic> data}) {
      return CareProfessional.fromJson(data);
    }
    if (response is Map<String, dynamic>) {
      return CareProfessional.fromJson(response);
    }
    throw const FormatException('Missing doctor data');
  }

  @override
  Future<List<CareService>> getDoctorServices({
    required String doctorId,
    required String clinicId,
  }) async {
    final response = await _client.get(
      ApiEndpoints.services,
      queryParameters: {'doctorId': doctorId, 'clinicId': clinicId},
    );
    return _listFromResponse(response)
        .map(CareService.fromJson)
        .where(
          (service) =>
              service.status == null ||
              service.status!.toUpperCase() == 'ACTIVE',
        )
        .toList(growable: false);
  }

  Future<CareAvailabilityPreview> getAvailableSlots({
    required String doctorId,
    required String clinicId,
    required DateTime date,
    String? serviceId,
    String? doctorScheduleId,
  }) async {
    final isoDate = _isoDate(date);
    final response = await _client.get(
      ApiEndpoints.availableSlots(doctorId),
      queryParameters: {
        'clinicId': clinicId,
        'date': isoDate,
        'serviceId': ?serviceId,
      },
    );
    final body = response as Map<String, dynamic>;
    final slots = (body['slots'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((slot) => slot['available'] == true)
        .toList(growable: false);
    final times = slots
        .map((slot) => slot['startTime'] as String)
        .toList(growable: false);
    final endTimes = {
      for (final slot in slots)
        slot['startTime'] as String: slot['endTime'] as String,
    };
    return CareAvailabilityPreview(
      day: _dayLabel(date),
      date: '${_months[date.month - 1]} ${date.day}',
      isoDate: isoDate,
      times: times,
      doctorScheduleId: doctorScheduleId,
      endTimes: endTimes,
    );
  }

  @override
  Future<CareProfessional> getProfessionalProfile(
    CareProfessional summary,
  ) async {
    final results = await Future.wait<Object>([
      getDoctor(summary.id),
      getClinics(),
    ]);
    final doctor = results[0] as CareProfessional;
    final allClinics = results[1] as List<CareClinicSummary>;
    final clinicById = {for (final clinic in allClinics) clinic.id: clinic};
    final clinics = doctor.clinics
        .map((clinic) => clinicById[clinic.id] ?? clinic)
        .toList(growable: false);
    final services = clinics.isEmpty
        ? const <CareService>[]
        : await getDoctorServices(
            doctorId: doctor.id,
            clinicId: clinics.first.id,
          );
    return doctor.copyWith(clinics: clinics, services: services);
  }

  @override
  Future<List<CareAvailabilityPreview>> getUpcomingAvailability({
    required String doctorId,
    required String clinicId,
    int days = 7,
  }) async {
    if (days < 1 || days > 31) {
      throw RangeError.range(days, 1, 31, 'days');
    }
    final today = DateTime.now();
    final dates = List.generate(
      days,
      (index) => DateTime(today.year, today.month, today.day + index),
    );
    final schedulesResponse = await _client.get(
      ApiEndpoints.doctorSchedules(doctorId),
      queryParameters: {'clinicId': clinicId},
    );
    final schedules = _listFromResponse(schedulesResponse)
        .map(_DoctorSchedule.fromJson)
        .where((schedule) => schedule.isActive)
        .toList(growable: false);
    final slotResponses = await Future.wait<Object?>([
      for (final date in dates)
        _client.get(
          ApiEndpoints.availableSlots(doctorId),
          queryParameters: {'clinicId': clinicId, 'date': _isoDate(date)},
        ),
    ]);
    final availability = <CareAvailabilityPreview>[];
    for (var index = 0; index < dates.length; index++) {
      final date = dates[index];
      final body = slotResponses[index] as Map<String, dynamic>;
      final matchingSchedules = schedules
          .where((schedule) => schedule.dayOfWeek == _apiWeekday(date))
          .toList(growable: false);
      final scheduleId = matchingSchedules.length == 1
          ? matchingSchedules.single.id
          : null;
      final slots = (body['slots'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .where((slot) => slot['available'] == true)
          .toList(growable: false);
      final times = slots
          .map((slot) => slot['startTime'])
          .whereType<String>()
          .toList(growable: false);
      final endTimes = <String, String>{};
      for (final slot in slots) {
        final startTime = slot['startTime'];
        final endTime = slot['endTime'];
        if (startTime is String && endTime is String) {
          endTimes[startTime] = endTime;
        }
      }
      availability.add(
        CareAvailabilityPreview(
          day: _dayLabel(date),
          date: '${_months[date.month - 1]} ${date.day}',
          isoDate: _isoDate(date),
          times: times,
          doctorScheduleId: scheduleId,
          endTimes: endTimes,
        ),
      );
    }
    return availability
        .where((day) => day.times.isNotEmpty && day.doctorScheduleId != null)
        .toList(growable: false);
  }

  Future<CareDirectoryCacheEntry?> _readCache(String key) async {
    try {
      return await _cacheStore.read(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, Object? data) async {
    try {
      await _cacheStore.write(key, data, DateTime.now());
    } catch (_) {
      // Public directory caching is best-effort and must not block live data.
    }
  }

  void _markOnline(String resource) {
    _resourceStatuses[resource] = const CareDirectoryStatus.online();
    _publishStatus();
  }

  void _markCached(String resource, DateTime cachedAt) {
    _resourceStatuses[resource] = CareDirectoryStatus(
      mode: CareDirectoryMode.cached,
      cachedAt: cachedAt,
    );
    _publishStatus();
  }

  void _markUnavailable(String resource) {
    _resourceStatuses[resource] = const CareDirectoryStatus(
      mode: CareDirectoryMode.unavailable,
    );
    _publishStatus();
  }

  void _publishStatus() {
    final statuses = _resourceStatuses.values;
    if (statuses.any(
      (status) => status.mode == CareDirectoryMode.unavailable,
    )) {
      _directoryStatus.value = const CareDirectoryStatus(
        mode: CareDirectoryMode.unavailable,
      );
      return;
    }
    final cached = statuses
        .where((status) => status.mode == CareDirectoryMode.cached)
        .toList(growable: false);
    if (cached.isNotEmpty) {
      final cachedDates = cached
          .map((status) => status.cachedAt)
          .whereType<DateTime>()
          .toList(growable: false);
      cachedDates.sort();
      _directoryStatus.value = CareDirectoryStatus(
        mode: CareDirectoryMode.cached,
        cachedAt: cachedDates.isEmpty ? null : cachedDates.first,
      );
      return;
    }
    _directoryStatus.value = const CareDirectoryStatus.online();
  }
}

class _DoctorSchedule {
  const _DoctorSchedule({
    required this.id,
    required this.dayOfWeek,
    required this.isActive,
  });

  final String id;
  final String dayOfWeek;
  final bool isActive;

  factory _DoctorSchedule.fromJson(Map<String, dynamic> json) =>
      _DoctorSchedule(
        id: json['id'].toString(),
        dayOfWeek: json['dayOfWeek'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? false,
      );
}

List<Map<String, dynamic>> _listFromResponse(Object? response) {
  final body = response as Map<String, dynamic>;
  return (body['data'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _dayLabel(DateTime date) {
  final current = DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final target = DateTime(date.year, date.month, date.day);
  final difference = target.difference(today).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Tomorrow';
  return _weekdays[date.weekday - 1];
}

String _apiWeekday(DateTime date) => const [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
][date.weekday - 1];

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
