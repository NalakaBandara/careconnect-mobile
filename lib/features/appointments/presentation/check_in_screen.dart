import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/domain/check_in_record.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointment_ui.dart';
import 'package:flutter/material.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({
    super.key,
    required this.appointment,
    this.repository,
    this.checkInPollInterval = const Duration(seconds: 5),
  });

  final CareAppointment appointment;
  final AppointmentsDataSource? repository;
  final Duration checkInPollInterval;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late CareAppointment _appointment;
  CheckInRecord? _record;
  bool _isLoading = false;
  bool _checkInRequestInFlight = false;
  bool _appointmentRequestInFlight = false;
  bool _isRefreshingAppointment = false;
  String? _error;
  String? _qrRefreshError;
  Timer? _pollTimer;

  CareAppointment get appointment => _appointment;
  bool get _hasQrCode => appointment.qrCode?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    if (widget.repository != null) {
      unawaited(_loadCheckIn(showLoading: true));
      if (!_hasQrCode) unawaited(_refreshAppointment());
      _pollTimer = Timer.periodic(widget.checkInPollInterval, (_) {
        if (_record == null) {
          unawaited(_loadCheckIn());
          if (!_hasQrCode) unawaited(_refreshAppointment());
        }
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCheckIn({bool showLoading = false}) async {
    if (_checkInRequestInFlight || widget.repository == null) return;
    _checkInRequestInFlight = true;
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final record = await widget.repository!.getCheckIn(appointment.id);
      if (!mounted) return;
      _pollTimer?.cancel();
      setState(() {
        _record = record;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode != 404 && showLoading) {
        setState(() => _error = 'Check-in status could not be loaded.');
      }
    } catch (_) {
      if (!mounted) return;
      if (showLoading) {
        setState(() => _error = 'Check-in status could not be loaded.');
      }
    } finally {
      _checkInRequestInFlight = false;
      if (mounted && showLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshAppointment({bool showLoading = false}) async {
    if (_appointmentRequestInFlight || widget.repository == null) return;
    _appointmentRequestInFlight = true;
    if (showLoading && mounted) {
      setState(() {
        _isRefreshingAppointment = true;
        _qrRefreshError = null;
      });
    }
    try {
      final refreshed = await widget.repository!.getAppointment(appointment.id);
      if (!mounted) return;
      setState(() {
        _appointment = refreshed;
        _qrRefreshError = null;
      });
    } catch (_) {
      if (!mounted || !showLoading) return;
      setState(() {
        _qrRefreshError =
            'The latest QR status could not be loaded. Please try again.';
      });
    } finally {
      _appointmentRequestInFlight = false;
      if (mounted && showLoading) {
        setState(() => _isRefreshingAppointment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Check in')),
    body: ListView(
      key: const Key('check-in-screen'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
      children: [
        Text(
          _record == null
              ? (_hasQrCode ? 'Your appointment QR' : 'Ready when you arrive')
              : 'You are checked in',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontSize: 31),
        ),
        const SizedBox(height: 9),
        Text(
          _record == null
              ? (_hasQrCode
                    ? 'Show this QR code at reception when you arrive.'
                    : 'Keep this screen ready for reception. Your QR code will appear when it is available.')
              : 'Reception has recorded your arrival. Keep your queue details handy.',
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        if (_record == null)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE2F6F0), Color(0xFFE8F0FF)],
              ),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                _QrBadge(available: _hasQrCode),
                const SizedBox(height: 18),
                if (_hasQrCode)
                  _AppointmentQrCode(
                    dataUrl: appointment.qrCode!,
                    onRefresh: widget.repository == null
                        ? null
                        : () => _refreshAppointment(showLoading: true),
                  )
                else
                  _QrUnavailable(
                    isRefreshing: _isRefreshingAppointment,
                    error: _qrRefreshError,
                    onRefresh: widget.repository == null
                        ? null
                        : () => _refreshAppointment(showLoading: true),
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Appointment reference',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  appointment.reference,
                  key: const Key('check-in-reference'),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        if (_isLoading) ...[
          const SizedBox(height: 14),
          const LinearProgressIndicator(
            key: Key('check-in-loading'),
            minHeight: 3,
          ),
        ],
        if (_record != null) ...[
          const SizedBox(height: 14),
          _CheckedInNotice(record: _record!),
        ] else if (_error != null) ...[
          const SizedBox(height: 14),
          _CheckInLookupError(
            message: _error!,
            onRetry: () => _loadCheckIn(showLoading: true),
          ),
        ],
        const SizedBox(height: 16),
        _VisitSummary(appointment: appointment),
        const SizedBox(height: 16),
        if (_record == null)
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1D2),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _hasQrCode
                      ? Icons.qr_code_2_rounded
                      : Icons.lock_clock_outlined,
                  color: const Color(0xFF93600A),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasQrCode
                            ? 'Reception check-in'
                            : 'QR code not available yet',
                        style: const TextStyle(
                          color: Color(0xFF76500D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasQrCode
                            ? 'This code identifies your appointment. Status updates automatically after reception scans it.'
                            : 'Refresh your appointment later or provide the booking reference to reception.',
                        style: const TextStyle(
                          color: Color(0xFF76500D),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _CheckedInNotice extends StatelessWidget {
  const _CheckedInNotice({required this.record});

  final CheckInRecord record;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('checked-in-record'),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: AppColors.mintSoft,
      borderRadius: BorderRadius.circular(19),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.primary),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checked in successfully',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                record.queueNumber == null
                    ? 'Reception has recorded your arrival.'
                    : 'Your queue number is ${record.queueNumber}.',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CheckInLookupError extends StatelessWidget {
  const _CheckInLookupError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        const Icon(Icons.sync_problem_rounded, color: Color(0xFFB84C4C)),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 11))),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _QrBadge extends StatelessWidget {
  const _QrBadge({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      available ? 'APPOINTMENT QR' : 'QR PENDING',
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
      ),
    ),
  );
}

class _AppointmentQrCode extends StatelessWidget {
  const _AppointmentQrCode({required this.dataUrl, this.onRefresh});

  final String dataUrl;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataUrl(dataUrl);
    if (bytes == null) {
      return _QrLoadError(onRefresh: onRefresh);
    }

    return Container(
      key: const Key('appointment-qr-code'),
      width: 210,
      height: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14063F3C),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Image.memory(
        bytes,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        semanticLabel: 'Appointment check-in QR code',
        errorBuilder: (_, _, _) => _QrLoadError(onRefresh: onRefresh),
      ),
    );
  }

  Uint8List? _decodeDataUrl(String value) {
    final separator = value.indexOf(',');
    if (separator == -1 || !value.substring(0, separator).contains(';base64')) {
      return null;
    }
    try {
      return base64Decode(value.substring(separator + 1));
    } on FormatException {
      return null;
    }
  }
}

class _QrLoadError extends StatelessWidget {
  const _QrLoadError({this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('appointment-qr-error'),
    width: 210,
    height: 210,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.broken_image_outlined,
          color: AppColors.muted,
          size: 34,
        ),
        const SizedBox(height: 10),
        const Text(
          'QR code unavailable',
          style: TextStyle(color: AppColors.muted),
        ),
        if (onRefresh != null) ...[
          const SizedBox(height: 10),
          TextButton(onPressed: onRefresh, child: const Text('Refresh QR')),
        ],
      ],
    ),
  );
}

class _QrUnavailable extends StatelessWidget {
  const _QrUnavailable({
    required this.isRefreshing,
    required this.error,
    this.onRefresh,
  });

  final bool isRefreshing;
  final String? error;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('appointment-qr-unavailable'),
    width: 210,
    constraints: const BoxConstraints(minHeight: 210),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14063F3C),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: AppColors.mintSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.qr_code_2_rounded,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'QR code is not available yet',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          error ?? 'We will refresh this appointment automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: error == null ? AppColors.muted : const Color(0xFFB84C4C),
            fontSize: 11,
            height: 1.35,
          ),
        ),
        if (onRefresh != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            key: const Key('refresh-appointment-qr'),
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(isRefreshing ? 'Refreshing…' : 'Refresh QR'),
          ),
        ],
      ],
    ),
  );
}

class _VisitSummary extends StatelessWidget {
  const _VisitSummary({required this.appointment});
  final CareAppointment appointment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.mintSoft,
              child: Text(
                appointment.doctor.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctor.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    appointment.service.name,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            AppointmentStatusPill(status: appointment.status),
          ],
        ),
        const Divider(height: 28),
        _SummaryRow(
          icon: Icons.calendar_today_outlined,
          value: appointmentDateLabel(appointment.appointmentDate),
        ),
        _SummaryRow(
          icon: Icons.schedule_outlined,
          value: '${appointment.startTime} – ${appointment.endTime}',
        ),
        _SummaryRow(
          icon: Icons.location_on_outlined,
          value: appointment.clinic.name,
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Icon(icon, size: 17, color: AppColors.muted),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
