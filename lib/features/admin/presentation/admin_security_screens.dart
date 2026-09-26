import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:flutter/material.dart';

class AdminUserAccessScreen extends StatefulWidget {
  const AdminUserAccessScreen({
    required this.user,
    required this.currentAdminId,
    required this.repository,
    required this.onChanged,
    super.key,
  });

  final AdminUser user;
  final String currentAdminId;
  final AdminDataSource repository;
  final Future<void> Function() onChanged;

  @override
  State<AdminUserAccessScreen> createState() => _AdminUserAccessScreenState();
}

class _AdminUserAccessScreenState extends State<AdminUserAccessScreen> {
  late Future<List<AdminRole>> _roles;
  late final Set<String> _assignedRoles;
  String? _assigningRole;
  bool _anonymising = false;

  bool get _isAnonymised => widget.user.status.toUpperCase() == 'ANONYMISED';
  bool get _isCurrentAdmin => widget.user.id == widget.currentAdminId;

  @override
  void initState() {
    super.initState();
    _assignedRoles = widget.user.roles
        .map((role) => role.toUpperCase())
        .toSet();
    _roles = widget.repository.getRoles();
  }

  Future<void> _assign(AdminRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign role?'),
        content: Text(
          '${widget.user.displayName} will receive the ${_roleLabel(role.name)} role. Role removal is not currently supported by the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Assign role'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _assigningRole = role.id);
    try {
      await widget.repository.assignUserRole(widget.user.id, role.id);
      if (!mounted) return;
      setState(() => _assignedRoles.add(role.name.toUpperCase()));
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_roleLabel(role.name)} role assigned.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('The role could not be assigned.');
    } finally {
      if (mounted) setState(() => _assigningRole = null);
    }
  }

  Future<void> _anonymise() async {
    if (_anonymising || _isAnonymised || _isCurrentAdmin) return;
    final understood = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anonymise this user?'),
        content: Text(
          '${widget.user.displayName} will permanently lose sign-in access. Personal details will be removed, while anonymised appointment and audit records remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('continue-admin-anonymisation'),
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
      builder: (_) => const _AdminAnonymisationConfirmationDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _anonymising = true);
    try {
      await widget.repository.anonymiseUser(widget.user.id);
      await widget.onChanged();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('The user could not be anonymised.');
    } finally {
      if (mounted) setState(() => _anonymising = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User access')),
      body: SafeArea(
        child: ListView(
          key: const Key('admin-user-access'),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.mintSoft,
              foregroundColor: AppColors.primary,
              child: Text(
                widget.user.displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.user.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 5),
            Text(
              widget.user.email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            _NoticeCard(
              icon: widget.user.status.toUpperCase() == 'ACTIVE'
                  ? Icons.check_circle_outline_rounded
                  : Icons.block_rounded,
              title: 'Account status: ${_roleLabel(widget.user.status)}',
              message: _isAnonymised
                  ? 'This account no longer has personal details or sign-in access.'
                  : 'Status changes are disabled until the backend provides a safe status-only endpoint that preserves private profile fields.',
            ),
            const SizedBox(height: 24),
            Text('Roles', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            const Text(
              'Roles can be added. Removing a role is not supported by the current API.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<AdminRole>>(
              future: _roles,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _NoticeCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Roles unavailable',
                    message: 'Check the connection and try again.',
                    action: TextButton(
                      onPressed: () => setState(() {
                        _roles = widget.repository.getRoles();
                      }),
                      child: const Text('Retry'),
                    ),
                  );
                }
                final roles = snapshot.data ?? const [];
                return Column(
                  children: roles
                      .map(
                        (role) => _RoleCard(
                          role: role,
                          assigned: _assignedRoles.contains(
                            role.name.toUpperCase(),
                          ),
                          busy: _assigningRole == role.id,
                          onAssign: () => _assign(role),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            if (!_isAnonymised) ...[
              const SizedBox(height: 30),
              _AdminDangerZone(
                isCurrentAdmin: _isCurrentAdmin,
                isBusy: _anonymising,
                onAnonymise: _anonymise,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminDangerZone extends StatelessWidget {
  const _AdminDangerZone({
    required this.isCurrentAdmin,
    required this.isBusy,
    required this.onAnonymise,
  });

  final bool isCurrentAdmin;
  final bool isBusy;
  final VoidCallback onAnonymise;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('admin-anonymise-user-section'),
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
          'Danger zone',
          style: TextStyle(
            color: Color(0xFF8F3434),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          isCurrentAdmin
              ? 'Use your own Profile privacy controls to anonymise the currently signed-in administrator.'
              : 'Permanently remove this user’s personal details and sign-in access. This cannot be undone.',
          style: const TextStyle(
            color: Color(0xFF795B58),
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('admin-anonymise-user-button'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB84C4C),
            ),
            onPressed: isCurrentAdmin || isBusy ? null : onAnonymise,
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_off_outlined),
            label: Text(isBusy ? 'Anonymising…' : 'Anonymise user'),
          ),
        ),
      ],
    ),
  );
}

class _AdminAnonymisationConfirmationDialog extends StatefulWidget {
  const _AdminAnonymisationConfirmationDialog();

  @override
  State<_AdminAnonymisationConfirmationDialog> createState() =>
      _AdminAnonymisationConfirmationDialogState();
}

class _AdminAnonymisationConfirmationDialogState
    extends State<_AdminAnonymisationConfirmationDialog> {
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
          const Text('Type ANONYMISE to confirm this permanent action.'),
          const SizedBox(height: 16),
          TextField(
            key: const Key('admin-anonymisation-confirmation'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'ANONYMISE'),
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
        key: const Key('confirm-admin-anonymisation'),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB84C4C)),
        onPressed: _controller.text.trim() == 'ANONYMISE'
            ? () => Navigator.pop(context, true)
            : null,
        child: const Text('Anonymise user'),
      ),
    ],
  );
}

class AdminSecurityScreen extends StatefulWidget {
  const AdminSecurityScreen({required this.repository, super.key});

  final AdminDataSource repository;

  @override
  State<AdminSecurityScreen> createState() => _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends State<AdminSecurityScreen> {
  late Future<List<AdminRole>> _roles;
  late Future<List<AdminAuditLog>> _logs;
  final _userIdController = TextEditingController();
  final _entityTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _roles = widget.repository.getRoles();
    _logs = widget.repository.getAuditLogs();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _entityTypeController.dispose();
    super.dispose();
  }

  void _filterLogs() {
    setState(() {
      _logs = widget.repository.getAuditLogs(
        userId: _userIdController.text,
        entityType: _entityTypeController.text,
      );
    });
  }

  void _clearFilters() {
    _userIdController.clear();
    _entityTypeController.clear();
    setState(() => _logs = widget.repository.getAuditLogs());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Security & audit'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Role catalog'),
              Tab(text: 'Audit activity'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RoleCatalog(roles: _roles),
            _AuditActivity(
              logs: _logs,
              userIdController: _userIdController,
              entityTypeController: _entityTypeController,
              onFilter: _filterLogs,
              onClear: _clearFilters,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCatalog extends StatelessWidget {
  const _RoleCatalog({required this.roles});

  final Future<List<AdminRole>> roles;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<AdminRole>>(
    future: roles,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const Center(child: Text('Role catalog could not be loaded.'));
      }
      final values = snapshot.data ?? const [];
      return ListView(
        key: const Key('admin-role-catalog'),
        padding: const EdgeInsets.all(20),
        children: [
          const _NoticeCard(
            icon: Icons.policy_outlined,
            title: 'Backend-enforced access',
            message:
                'The API remains the source of truth. Mobile role checks only control navigation and visibility.',
          ),
          const SizedBox(height: 18),
          ...values.map(
            (role) => _RoleCard(role: role, assigned: false, busy: false),
          ),
        ],
      );
    },
  );
}

class _AuditActivity extends StatelessWidget {
  const _AuditActivity({
    required this.logs,
    required this.userIdController,
    required this.entityTypeController,
    required this.onFilter,
    required this.onClear,
  });

  final Future<List<AdminAuditLog>> logs;
  final TextEditingController userIdController;
  final TextEditingController entityTypeController;
  final VoidCallback onFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<AdminAuditLog>>(
    future: logs,
    builder: (context, snapshot) {
      return ListView(
        key: const Key('admin-audit-logs'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('admin-audit-user-filter'),
                  controller: userIdController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('User ID'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const Key('admin-audit-entity-filter'),
                  controller: entityTypeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoration('Entity type'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onFilter,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Apply filters'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Clear filters',
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (snapshot.connectionState != ConnectionState.done)
            const Center(child: CircularProgressIndicator())
          else if (snapshot.hasError)
            const _NoticeCard(
              icon: Icons.cloud_off_rounded,
              title: 'Audit activity unavailable',
              message: 'Check the filters, connection, and admin permissions.',
            )
          else if ((snapshot.data ?? const []).isEmpty)
            const _NoticeCard(
              icon: Icons.history_toggle_off_rounded,
              title: 'No matching activity',
              message: 'No audit records match the selected filters.',
            )
          else ...[
            Text(
              '${snapshot.data!.length} most recent records',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...snapshot.data!.map(_AuditCard.new),
          ],
        ],
      );
    },
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.assigned,
    required this.busy,
    this.onAssign,
  });

  final AdminRole role;
  final bool assigned;
  final bool busy;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.careColors.card,
      border: Border.all(color: context.careColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.lilacSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.badge_outlined, color: Color(0xFF7654B8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _roleLabel(role.name),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (role.description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  role.description!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (assigned)
          const Chip(
            avatar: Icon(Icons.check_rounded, size: 16),
            label: Text('Assigned'),
          )
        else if (onAssign != null)
          TextButton(
            key: Key('admin-assign-role-${role.id}'),
            onPressed: busy ? null : onAssign,
            child: Text(busy ? 'Assigning…' : 'Assign'),
          ),
      ],
    ),
  );
}

class _AuditCard extends StatelessWidget {
  const _AuditCard(this.log);

  final AdminAuditLog log;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: context.careColors.card,
      border: Border.all(color: context.careColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.history_rounded, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _roleLabel(log.action),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${_roleLabel(log.entityType)}${log.entityId == null ? '' : ' #${log.entityId}'}',
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                '${_formatDateTime(log.createdAt)}${log.userId == null ? '' : ' · User #${log.userId}'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: context.careColors.card,
      border: Border.all(color: context.careColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              ?action,
            ],
          ),
        ),
      ],
    ),
  );
}

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  isDense: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.border),
  ),
);

String _roleLabel(String value) => value
    .toLowerCase()
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Time unavailable';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
