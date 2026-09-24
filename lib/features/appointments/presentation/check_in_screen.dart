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
  CheckInRecord? _record;
  bool _isLoading = false;
  bool _requestInFlight = false;
  String? _error;
  Timer? _pollTimer;

  CareAppointment get appointment => widget.appointment;
  bool get _hasQrCode => appointment.qrCode?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      unawaited(_loadCheckIn(showLoading: true));
      _pollTimer = Timer.periodic(widget.checkInPollInterval, (_) {
        if (_record == null && !_requestInFlight) {
          unawaited(_loadCheckIn());
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
    if (_requestInFlight || widget.repository == null) return;
    _requestInFlight = true;
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
      _requestInFlight = false;
      if (mounted && showLoading) setState(() => _isLoading = false);
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
                  _AppointmentQrCode(dataUrl: appointment.qrCode!)
                else
                  _LockedCode(reference: appointment.reference),
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
      available ? 'APPOINTMENT QR' : 'CHECK-IN PREVIEW',
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
  const _AppointmentQrCode({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataUrl(dataUrl);
    if (bytes == null) {
      return const _QrLoadError();
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
  const _QrLoadError();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('appointment-qr-error'),
    width: 210,
    height: 210,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image_outlined, color: AppColors.muted, size: 34),
        SizedBox(height: 10),
        Text('QR code unavailable', style: TextStyle(color: AppColors.muted)),
      ],
    ),
  );
}

class _LockedCode extends StatelessWidget {
  const _LockedCode({required this.reference});
  final String reference;

  @override
  Widget build(BuildContext context) => Container(
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
    child: Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _PreviewCodePainter(reference.hashCode)),
        Center(
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.lock_rounded, color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

class _PreviewCodePainter extends CustomPainter {
  const _PreviewCodePainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    const cells = 17;
    final cell = size.width / cells;
    final paint = Paint()..color = AppColors.ink.withValues(alpha: 0.72);
    for (var row = 0; row < cells; row++) {
      for (var column = 0; column < cells; column++) {
        final corner =
            (row < 5 && column < 5) ||
            (row < 5 && column >= cells - 5) ||
            (row >= cells - 5 && column < 5);
        final value = ((row * 31 + column * 17 + seed) & 3) == 0;
        if (corner || value) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                column * cell + 1,
                row * cell + 1,
                cell - 2,
                cell - 2,
              ),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewCodePainter oldDelegate) =>
      oldDelegate.seed != seed;
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
