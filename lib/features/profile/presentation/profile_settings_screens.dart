import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _appointmentReminders = true;
  bool _statusUpdates = true;
  bool _careTips = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: ListView(
      key: const Key('notification-preferences-screen'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
      children: [
        Text(
          'Stay informed, not overwhelmed',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 23),
        ),
        const SizedBox(height: 7),
        const Text(
          'Choose the CareConnect updates you would like to receive.',
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 22),
        _PreferenceTile(
          icon: Icons.alarm_rounded,
          title: 'Appointment reminders',
          caption: 'Helpful reminders before an upcoming visit',
          value: _appointmentReminders,
          onChanged: (value) => setState(() => _appointmentReminders = value),
        ),
        const SizedBox(height: 10),
        _PreferenceTile(
          icon: Icons.sync_rounded,
          title: 'Booking status updates',
          caption: 'Confirmation, reschedule and cancellation updates',
          value: _statusUpdates,
          onChanged: (value) => setState(() => _statusUpdates = value),
        ),
        const SizedBox(height: 10),
        _PreferenceTile(
          icon: Icons.favorite_outline_rounded,
          title: 'Care tips',
          caption: 'Occasional product and wellbeing information',
          value: _careTips,
          onChanged: (value) => setState(() => _careTips = value),
        ),
        const SizedBox(height: 18),
        const _InfoNotice(
          text:
              'Preferences are preview-only. The backend currently supports notification delivery and read status, but not preference storage.',
        ),
      ],
    ),
  );
}

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Security')),
    body: ListView(
      key: const Key('security-screen'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.white, size: 36),
              SizedBox(height: 18),
              Text(
                'Protected sign-in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'CareConnect uses Auth0 to manage passwords and secure account access.',
                style: TextStyle(color: Color(0xFFD8F3EC), height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _InformationTile(
          icon: Icons.password_rounded,
          title: 'Password changes',
          caption: 'Managed securely through your Auth0 account',
        ),
        const SizedBox(height: 10),
        const _InformationTile(
          icon: Icons.devices_outlined,
          title: 'Active sessions',
          caption: 'Session management will appear after authentication',
        ),
        const SizedBox(height: 18),
        const _InfoNotice(
          text:
              'CareConnect never stores your password in the mobile application or its own profile API.',
        ),
      ],
    ),
  );
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  int? _expanded;
  static const _faqs = [
    (
      'Do I need an account to browse?',
      'No. You can browse professionals in preview mode. An account is required to request and manage real appointments.',
    ),
    (
      'How does appointment confirmation work?',
      'A new request starts as pending. The clinic reviews it and updates the appointment when it is confirmed.',
    ),
    (
      'Can I change an appointment?',
      'Cancellation is supported by the current API. Rescheduling will become active after the backend accepts new date and time fields.',
    ),
    (
      'Is CareConnect an emergency service?',
      'No. For an emergency, contact your local emergency service or visit the nearest emergency department.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & support')),
    body: ListView(
      key: const Key('support-screen'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
      children: [
        Text(
          'How can we help?',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontSize: 31),
        ),
        const SizedBox(height: 8),
        const Text(
          'Quick answers about using CareConnect.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        ...List.generate(_faqs.length, (index) {
          final faq = _faqs[index];
          final expanded = _expanded == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
              child: InkWell(
                onTap: () =>
                    setState(() => _expanded = expanded ? null : index),
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              faq.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Icon(
                            expanded ? Icons.remove_rounded : Icons.add_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 11),
                        Text(
                          faq.$2,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: AppColors.mintSoft,
            borderRadius: BorderRadius.circular(21),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need more help?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              SizedBox(height: 7),
              Text(
                'Support contact details will be added when the project support channel is confirmed.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'CareConnect is not an emergency service.',
                style: TextStyle(
                  color: Color(0xFFB84C4C),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy & legal')),
    body: ListView(
      key: const Key('privacy-screen'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
      children: const [
        Text(
          'Privacy overview',
          style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 8),
        Text(
          'A plain-language project summary of how CareConnect is designed to handle account and appointment information.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        SizedBox(height: 26),
        _LegalSection(
          title: 'Information used',
          body:
              'Your account details and appointment information are used to provide booking, clinic communication and check-in features.',
        ),
        _LegalSection(
          title: 'Information shared with clinics',
          body:
              'The selected clinic receives the information required to review and manage your appointment request.',
        ),
        _LegalSection(
          title: 'Public information',
          body:
              'Professional profiles, clinic details, services and general availability may be visible while browsing.',
        ),
        _LegalSection(
          title: 'Your choices',
          body:
              'You can review personal details and manage appointment requests. Additional privacy controls will be added with the production backend.',
        ),
        _InfoNotice(
          text:
              'This screen is a product-design summary, not the final legal policy. A reviewed privacy policy and terms must be supplied before release.',
        ),
      ],
    ),
  );
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.caption,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String caption;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(19),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                caption,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

class _InformationTile extends StatelessWidget {
  const _InformationTile({
    required this.icon,
    required this.title,
    required this.caption,
  });
  final IconData icon;
  final String title;
  final String caption;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(19),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                caption,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: Color(0xFF5276D8),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(color: AppColors.muted, height: 1.55),
        ),
      ],
    ),
  );
}
