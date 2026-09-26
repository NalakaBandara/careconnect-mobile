import 'dart:async';

import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/domain/check_in_record.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef AdminQrScannerBuilder = Widget Function(ValueChanged<String> onScan);

class AdminQrCheckInScreen extends StatefulWidget {
  const AdminQrCheckInScreen({
    required this.repository,
    this.scannerBuilder,
    super.key,
  });

  final AdminDataSource repository;
  final AdminQrScannerBuilder? scannerBuilder;

  @override
  State<AdminQrCheckInScreen> createState() => _AdminQrCheckInScreenState();
}

class _AdminQrCheckInScreenState extends State<AdminQrCheckInScreen> {
  late final MobileScannerController _scannerController =
      MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
        autoZoom: true,
      );

  CareAppointment? _appointment;
  CheckInRecord? _checkIn;
  bool _loading = false;
  bool _checkingIn = false;
  String? _error;

  @override
  void dispose() {
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  Future<void> _loadAppointment(String rawValue) async {
    if (_loading || _appointment != null) return;
    final appointmentId = rawValue.trim();
    if (!RegExp(r'^[1-9]\d*$').hasMatch(appointmentId)) {
      setState(() => _error = 'This QR code is not a CareConnect appointment.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    if (widget.scannerBuilder == null) {
      try {
        await _scannerController.stop();
      } catch (_) {
        // The preview may still be initializing when a code is detected.
      }
    }

    try {
      final appointment = await widget.repository.getAppointment(appointmentId);
      if (!mounted) return;
      setState(() => _appointment = appointment);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
      await _resumeScanner();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Appointment details could not be loaded.');
      await _resumeScanner();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resumeScanner() async {
    if (widget.scannerBuilder != null) return;
    try {
      await _scannerController.start();
    } catch (_) {
      // The scanner error builder provides the actionable camera state.
    }
  }

  Future<void> _enterAppointmentId() async {
    var enteredId = '';
    final appointmentId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter appointment ID'),
        content: TextField(
          key: const Key('admin-manual-appointment-id'),
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Appointment ID',
            hintText: 'Example: 4821',
          ),
          onChanged: (value) => enteredId = value,
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('admin-find-appointment'),
            onPressed: () => Navigator.pop(dialogContext, enteredId),
            child: const Text('Find appointment'),
          ),
        ],
      ),
    );
    if (appointmentId != null && mounted) {
      await _loadAppointment(appointmentId);
    }
  }

  Future<void> _confirmCheckIn() async {
    final appointment = _appointment;
    if (appointment == null || _checkingIn) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm patient arrival?'),
        content: Text(
          'Check in appointment ${appointment.reference} at ${appointment.clinic.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review'),
          ),
          FilledButton(
            key: const Key('admin-confirm-reception-check-in'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm check-in'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _checkingIn = true;
      _error = null;
    });
    try {
      final record = await widget.repository.createReceptionCheckIn(
        appointment.id,
      );
      if (!mounted) return;
      setState(() => _checkIn = record);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Check-in could not be completed.');
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  Future<void> _scanAnother() async {
    setState(() {
      _appointment = null;
      _checkIn = null;
      _error = null;
    });
    await _resumeScanner();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('admin-qr-check-in-screen'),
    appBar: AppBar(title: const Text('Patient check-in')),
    body: SafeArea(
      child: _appointment == null ? _buildScanner() : _buildReview(),
    ),
  );

  Widget _buildScanner() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
    children: [
      Text(
        'Scan appointment QR',
        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 29),
      ),
      const SizedBox(height: 7),
      const Text(
        'Ask the patient to open their appointment check-in screen, then place the QR inside the frame.',
        style: TextStyle(color: AppColors.muted, height: 1.4),
      ),
      const SizedBox(height: 20),
      AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child:
              widget.scannerBuilder?.call(_loadAppointment) ??
              MobileScanner(
                key: const Key('admin-mobile-qr-scanner'),
                controller: _scannerController,
                onDetect: (capture) {
                  for (final barcode in capture.barcodes) {
                    final value = barcode.rawValue;
                    if (value != null) {
                      unawaited(_loadAppointment(value));
                      return;
                    }
                  }
                },
                errorBuilder: (context, error) => _CameraError(
                  message:
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Camera permission is required to scan a patient QR.'
                      : 'The camera could not be started on this device.',
                ),
                overlayBuilder: (context, constraints) => const _ScanFrame(),
              ),
        ),
      ),
      if (_loading) ...[
        const SizedBox(height: 16),
        const LinearProgressIndicator(key: Key('admin-qr-loading')),
      ],
      if (_error != null) ...[
        const SizedBox(height: 14),
        _ErrorNotice(message: _error!),
      ],
      const SizedBox(height: 16),
      OutlinedButton.icon(
        key: const Key('admin-enter-appointment-id'),
        onPressed: _loading ? null : _enterAppointmentId,
        icon: const Icon(Icons.keyboard_alt_outlined),
        label: const Text('Enter appointment ID instead'),
      ),
    ],
  );

  Widget _buildReview() {
    final appointment = _appointment!;
    if (_checkIn != null) {
      return _CheckInSuccess(
        appointment: appointment,
        record: _checkIn!,
        onScanAnother: _scanAnother,
      );
    }

    return ListView(
      key: const Key('admin-qr-appointment-review'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        Text(
          'Verify appointment',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontSize: 29),
        ),
        const SizedBox(height: 8),
        const Text(
          'Confirm these details with the patient before recording arrival.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        _AppointmentReviewCard(appointment: appointment),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _ErrorNotice(message: _error!),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('admin-reception-check-in'),
          onPressed: _checkingIn ? null : _confirmCheckIn,
          icon: const Icon(Icons.how_to_reg_rounded),
          label: Text(_checkingIn ? 'Checking in…' : 'Confirm patient arrival'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _checkingIn ? null : _scanAnother,
          child: const Text('Scan a different QR'),
        ),
      ],
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(26),
      ),
      margin: const EdgeInsets.all(45),
    ),
  );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.ink,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AppointmentReviewCard extends StatelessWidget {
  const _AppointmentReviewCard({required this.appointment});

  final CareAppointment appointment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.careColors.card,
      border: Border.all(color: context.careColors.border),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.mintSoft,
              foregroundColor: AppColors.primary,
              child: Text(appointment.doctor.initials),
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
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(status: appointment.status),
          ],
        ),
        const Divider(height: 32),
        _DetailRow(label: 'Reference', value: appointment.reference),
        _DetailRow(label: 'Appointment ID', value: appointment.id),
        _DetailRow(label: 'Date', value: appointment.appointmentDate),
        _DetailRow(
          label: 'Time',
          value: '${appointment.startTime} – ${appointment.endTime}',
        ),
        _DetailRow(label: 'Clinic', value: appointment.clinic.name),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.mintSoft,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      status.label,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _CheckInSuccess extends StatelessWidget {
  const _CheckInSuccess({
    required this.appointment,
    required this.record,
    required this.onScanAnother,
  });

  final CareAppointment appointment;
  final CheckInRecord record;
  final VoidCallback onScanAnother;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('admin-qr-check-in-success'),
    padding: const EdgeInsets.fromLTRB(20, 34, 20, 30),
    children: [
      const CircleAvatar(
        radius: 40,
        backgroundColor: AppColors.mintSoft,
        foregroundColor: AppColors.primary,
        child: Icon(Icons.check_rounded, size: 42),
      ),
      const SizedBox(height: 20),
      Text(
        'Patient checked in',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 29),
      ),
      const SizedBox(height: 8),
      Text(
        '${appointment.reference} is ready for ${appointment.clinic.name}.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.mintSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text('QUEUE NUMBER', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 6),
            Text(
              record.queueNumber?.toString() ?? 'Assigned',
              key: const Key('admin-check-in-queue-number'),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: onScanAnother,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan next patient'),
      ),
    ],
  );
}
