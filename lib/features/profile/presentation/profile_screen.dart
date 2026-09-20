import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/profile/data/profile_preview_data.dart';
import 'package:careconnect_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:careconnect_mobile/features/profile/data/user_repository.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:careconnect_mobile/features/profile/presentation/profile_settings_screens.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.user,
    this.onLogout,
    this.onNotifications,
    this.repository,
    this.onUserChanged,
  });

  final CurrentUser? user;
  final Future<void> Function()? onLogout;
  final VoidCallback? onNotifications;
  final UserDataSource? repository;
  final ValueChanged<CurrentUser>? onUserChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late CurrentUser _user = widget.user ?? ProfilePreviewData.user;
  bool _isLoading = false;
  String? _error;

  bool get _isPreview => widget.repository == null;

  @override
  void initState() {
    super.initState();
    if (!_isPreview) _refreshProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != null && widget.user != oldWidget.user) {
      _user = widget.user!;
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await widget.repository!.getCurrentUser();
      if (!mounted) return;
      setState(() => _user = user);
      widget.onUserChanged?.call(user);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Your latest profile could not be loaded. Pull down to retry.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<CurrentUser>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          user: _user,
          isPreview: _isPreview,
          onSave: _isPreview ? null : widget.repository!.updateCurrentUser,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _user = updated);
      widget.onUserChanged?.call(updated);
    }
  }

  void _open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _isPreview
            ? () async =>
                  Future<void>.delayed(const Duration(milliseconds: 250))
            : _refreshProfile,
        child: ListView(
          key: const Key('profile-screen'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 118),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your profile',
                    key: const Key('profile-title'),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('profile-notifications-button'),
                  tooltip: 'Notifications',
                  onPressed:
                      widget.onNotifications ??
                      () => _open(const NotificationsScreen()),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                key: Key('profile-loading'),
                minHeight: 3,
                borderRadius: BorderRadius.all(Radius.circular(99)),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ProfileLoadError(message: _error!, onRetry: _refreshProfile),
            ],
            const SizedBox(height: 22),
            _ProfileHero(
              user: _user,
              isPreview: _isPreview,
              onEdit: _editProfile,
            ),
            const SizedBox(height: 28),
            const _SectionLabel('ACCOUNT'),
            const SizedBox(height: 10),
            _ProfileTile(
              key: const Key('personal-details-tile'),
              icon: Icons.person_outline_rounded,
              iconColor: AppColors.primary,
              iconBackground: AppColors.mintSoft,
              title: 'Personal details',
              caption: 'Name, phone and date of birth',
              onTap: _editProfile,
            ),
            const SizedBox(height: 10),
            _ProfileTile(
              key: const Key('security-tile'),
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF5276D8),
              iconBackground: AppColors.blueSoft,
              title: 'Security',
              caption: 'Sign-in and account protection',
              onTap: () => _open(const SecurityScreen()),
            ),
            const SizedBox(height: 10),
            _ProfileTile(
              key: const Key('notification-preferences-tile'),
              icon: Icons.notifications_none_rounded,
              iconColor: const Color(0xFF9A6810),
              iconBackground: const Color(0xFFFFF1D2),
              title: 'Notifications',
              caption: 'Appointment reminders and updates',
              onTap: () => _open(const NotificationPreferencesScreen()),
            ),
            const SizedBox(height: 26),
            const _SectionLabel('SUPPORT & INFORMATION'),
            const SizedBox(height: 10),
            _ProfileTile(
              key: const Key('support-tile'),
              icon: Icons.favorite_border_rounded,
              iconColor: const Color(0xFF7957C8),
              iconBackground: AppColors.lilacSoft,
              title: 'Help & support',
              caption: 'FAQs and contact information',
              onTap: () => _open(const SupportScreen()),
            ),
            const SizedBox(height: 10),
            _ProfileTile(
              key: const Key('privacy-tile'),
              icon: Icons.privacy_tip_outlined,
              iconColor: AppColors.primary,
              iconBackground: AppColors.mintSoft,
              title: 'Privacy & legal',
              caption: 'How CareConnect handles your information',
              onTap: () => _open(const PrivacyScreen()),
            ),
            if (widget.onLogout != null) ...[
              const SizedBox(height: 26),
              OutlinedButton.icon(
                key: const Key('profile-sign-out-button'),
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ],
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'CareConnect · Personal healthcare companion',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('profile-load-error'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFB84C4C)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, height: 1.4),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.isPreview,
    required this.onEdit,
  });
  final CurrentUser user;
  final bool isPreview;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials =
        '${user.firstName.isEmpty ? '' : user.firstName[0]}${user.lastName.isEmpty ? '' : user.lastName[0]}';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0E9FF), Color(0xFFE1F5EF)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF7957C8),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              if (isPreview)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'PREVIEW',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            user.displayName,
            key: const Key('profile-display-name'),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(user.email, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            key: const Key('edit-profile-button'),
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit personal details'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.1,
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.caption,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 13),
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
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}
