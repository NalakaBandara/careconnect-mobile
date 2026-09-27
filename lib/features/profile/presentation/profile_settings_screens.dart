import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({required this.controller, super.key});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Appearance')),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView(
        key: const Key('appearance-screen'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        children: [
          Text(
            'Choose your look',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 29),
          ),
          const SizedBox(height: 8),
          Text(
            'Use your phone setting or choose a CareConnect theme.',
            style: TextStyle(color: context.careColors.muted, height: 1.45),
          ),
          const SizedBox(height: 24),
          _ThemeModeTile(
            key: const Key('theme-system'),
            icon: Icons.brightness_auto_rounded,
            title: 'System default',
            caption: 'Follow your phone’s light or dark setting',
            selected: controller.themeMode == ThemeMode.system,
            onTap: () => controller.setThemeMode(ThemeMode.system),
          ),
          const SizedBox(height: 12),
          _ThemeModeTile(
            key: const Key('theme-light'),
            icon: Icons.light_mode_rounded,
            title: 'Light',
            caption: 'A bright, calm healthcare interface',
            selected: controller.themeMode == ThemeMode.light,
            onTap: () => controller.setThemeMode(ThemeMode.light),
          ),
          const SizedBox(height: 12),
          _ThemeModeTile(
            key: const Key('theme-dark'),
            icon: Icons.dark_mode_rounded,
            title: 'Dark',
            caption: 'Comfortable viewing in low light',
            selected: controller.themeMode == ThemeMode.dark,
            onTap: () => controller.setThemeMode(ThemeMode.dark),
          ),
          const SizedBox(height: 22),
          _InfoNotice(
            text:
                'This preference is stored only on this device and does not require a CareConnect account.',
          ),
        ],
      ),
    ),
  );
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.icon,
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.careColors.softSurface : context.careColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : context.careColors.border,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    caption,
                    style: TextStyle(
                      color: context.careColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selected
                  ? Icon(
                      Icons.check_circle_rounded,
                      key: const ValueKey('selected'),
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : Icon(
                      Icons.circle_outlined,
                      key: const ValueKey('unselected'),
                      color: context.careColors.border,
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

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
            gradient: AppGradients.brand,
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
                'CareConnect protects your account with an encrypted mobile session and a securely hashed server password.',
                style: TextStyle(color: Color(0xFFD8F3EC), height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _InformationTile(
          icon: Icons.password_rounded,
          title: 'Password changes',
          caption: 'Password management will appear when the API supports it',
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
              'CareConnect never stores your password in the mobile application. Only the signed access token is kept in encrypted device storage.',
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
      'Yes. Open an upcoming appointment to choose another available time or cancel the visit.',
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
              color: context.careColors.card,
              borderRadius: BorderRadius.circular(19),
              child: InkWell(
                onTap: () =>
                    setState(() => _expanded = expanded ? null : index),
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.careColors.border),
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
                          style: TextStyle(
                            color: context.careColors.muted,
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

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key, this.onAnonymiseAccount});

  final Future<void> Function()? onAnonymiseAccount;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _isDeleting = false;

  Future<void> _requestAccountDeletion() async {
    if (_isDeleting || widget.onAnonymiseAccount == null) return;

    final understood = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently removes your personal details and sign-in access. Your anonymised appointment history will remain for clinic and audit records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep my account'),
          ),
          FilledButton(
            key: const Key('continue-account-deletion'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB84C4C),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (understood != true || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _AccountDeletionConfirmationDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await widget.onAnonymiseAccount!();
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been anonymised.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not delete your account. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy & legal')),
    body: ListView(
      key: const Key('privacy-screen'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
      children: [
        const Text(
          'Privacy overview',
          style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'A plain-language project summary of how CareConnect is designed to handle account and appointment information.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 26),
        const _LegalSection(
          title: 'Information used',
          body:
              'Your account details and appointment information are used to provide booking, clinic communication and check-in features.',
        ),
        const _LegalSection(
          title: 'Information shared with clinics',
          body:
              'The selected clinic receives the information required to review and manage your appointment request.',
        ),
        const _LegalSection(
          title: 'Public information',
          body:
              'Professional profiles, clinic details, services and general availability may be visible while browsing.',
        ),
        const _LegalSection(
          title: 'Your choices',
          body:
              'You can review personal details, manage appointment requests, and permanently anonymise your account.',
        ),
        const _InfoNotice(
          text:
              'This screen is a product-design summary, not the final legal policy. A reviewed privacy policy and terms must be supplied before release.',
        ),
        if (widget.onAnonymiseAccount != null) ...[
          const SizedBox(height: 30),
          Container(
            key: const Key('delete-account-section'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EE),
              border: Border.all(color: const Color(0xFFF2C8C2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete your account',
                  style: TextStyle(
                    color: Color(0xFF8F3434),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Your personal details and sign-in access will be permanently removed. Anonymised appointment records will remain for clinic and audit requirements.',
                  style: TextStyle(
                    color: Color(0xFF795B58),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('delete-account-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB84C4C),
                    ),
                    onPressed: _isDeleting ? null : _requestAccountDeletion,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_remove_outlined),
                    label: Text(
                      _isDeleting ? 'Deleting account…' : 'Delete my account',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _AccountDeletionConfirmationDialog extends StatefulWidget {
  const _AccountDeletionConfirmationDialog();

  @override
  State<_AccountDeletionConfirmationDialog> createState() =>
      _AccountDeletionConfirmationDialogState();
}

class _AccountDeletionConfirmationDialogState
    extends State<_AccountDeletionConfirmationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Final confirmation'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type DELETE to permanently anonymise your account. This action cannot be undone.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('account-deletion-confirmation'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'DELETE'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('confirm-account-deletion'),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB84C4C)),
        onPressed: _controller.text.trim() == 'DELETE'
            ? () => Navigator.pop(context, true)
            : null,
        child: const Text('Delete account'),
      ),
    ],
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
      color: context.careColors.card,
      border: Border.all(color: context.careColors.border),
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
                style: TextStyle(color: context.careColors.muted, fontSize: 11),
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
      color: context.careColors.card,
      border: Border.all(color: context.careColors.border),
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
                style: TextStyle(color: context.careColors.muted, fontSize: 11),
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
