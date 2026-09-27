import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/booking/domain/appointment_booking.dart';
import 'package:flutter/material.dart';
import 'package:careconnect_mobile/shared/widgets/profile_photo.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.reference,
    this.onViewAppointments,
  });

  final AppointmentBookingDraft booking;
  final String reference;
  final VoidCallback? onViewAppointments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request received')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            key: const Key('booking-confirmation'),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Column(
              children: [
                _SuccessIcon(),
                SizedBox(height: 20),
                Text(
                  'Your appointment request is in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'The clinic will review your request. We’ll let you know when it is confirmed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFD8F3EC), height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _AppointmentCard(booking: booking, reference: reference),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_rounded, color: Color(0xFF9A6810)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Status: Awaiting clinic confirmation',
                    style: TextStyle(
                      color: Color(0xFF76500D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            key: const Key('booking-done-button'),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              onViewAppointments?.call();
            },
            child: Text(
              onViewAppointments == null ? 'Done' : 'View appointments',
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.primary,
        size: 38,
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.booking, required this.reference});

  final AppointmentBookingDraft booking;
  final String reference;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              ProfilePhoto(
                imageUrl: booking.professional.profilePhoto,
                fallbackLabel: booking.professional.initials,
                size: 50,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.professional.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.service.name,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Detail(icon: Icons.calendar_today_outlined, text: booking.dateLabel),
          _Detail(
            icon: Icons.schedule_outlined,
            text: '${booking.startTime} – ${booking.endTime}',
          ),
          _Detail(icon: Icons.location_on_outlined, text: booking.clinic.name),
          const Divider(height: 28),
          const Text(
            'REFERENCE',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            reference,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
