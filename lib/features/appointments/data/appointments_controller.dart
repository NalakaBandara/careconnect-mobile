import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:flutter/foundation.dart';

class AppointmentsController extends ChangeNotifier {
  AppointmentsController(this._dataSource);

  final AppointmentsDataSource _dataSource;
  List<CareAppointment> _appointments = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  Object? _error;
  Future<void>? _inFlight;
  bool _disposed = false;

  List<CareAppointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  Object? get error => _error;

  Future<void> load({bool force = false}) {
    if (!force && _hasLoaded) return Future.value();
    final current = _inFlight;
    if (current != null) return current;
    final request = _load();
    _inFlight = request;
    return request.whenComplete(() => _inFlight = null);
  }

  Future<void> refresh() => load(force: true);

  Future<void> _load() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final appointments = await _dataSource.getMyAppointments();
      if (_disposed) return;
      _appointments = appointments;
      _hasLoaded = true;
    } catch (error) {
      if (_disposed) return;
      _error = error;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void upsert(CareAppointment appointment) {
    if (_disposed) return;
    final updated = List<CareAppointment>.of(_appointments);
    final index = updated.indexWhere((item) => item.id == appointment.id);
    if (index == -1) {
      updated.add(appointment);
    } else {
      updated[index] = appointment;
    }
    _appointments = List.unmodifiable(updated);
    _hasLoaded = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
