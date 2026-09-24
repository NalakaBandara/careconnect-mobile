import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:flutter/material.dart';

class AdminCatalogScreen extends StatefulWidget {
  const AdminCatalogScreen({
    required this.specialties,
    required this.services,
    required this.repository,
    required this.onChanged,
    super.key,
  });

  final List<CareSpecialty> specialties;
  final List<CareService> services;
  final AdminDataSource repository;
  final Future<void> Function() onChanged;

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> {
  late final List<CareSpecialty> _specialties = [...widget.specialties];
  late final List<CareService> _services = [...widget.services];

  Future<void> _openSpecialty([CareSpecialty? specialty]) async {
    final saved = await Navigator.of(context).push<CareSpecialty>(
      MaterialPageRoute(
        builder: (_) => _SpecialtyFormScreen(
          repository: widget.repository,
          specialty: specialty,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    setState(() {
      final index = _specialties.indexWhere((item) => item.id == saved.id);
      index == -1 ? _specialties.add(saved) : _specialties[index] = saved;
    });
    await widget.onChanged();
  }

  Future<void> _openService([CareService? service]) async {
    final saved = await Navigator.of(context).push<CareService>(
      MaterialPageRoute(
        builder: (_) =>
            _ServiceFormScreen(repository: widget.repository, service: service),
      ),
    );
    if (saved == null || !mounted) return;
    setState(() {
      final index = _services.indexWhere((item) => item.id == saved.id);
      index == -1 ? _services.add(saved) : _services[index] = saved;
    });
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Care catalog'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Specialties'),
              Tab(text: 'Services'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CatalogList(
              key: const Key('admin-specialty-catalog'),
              intro: 'Specialties organize professionals and patient searches.',
              addLabel: 'Add specialty',
              onAdd: _openSpecialty,
              emptyMessage: 'No specialties configured.',
              children: _specialties
                  .map(
                    (specialty) => _CatalogCard(
                      title: specialty.name,
                      description: specialty.description,
                      icon: Icons.health_and_safety_outlined,
                      onEdit: () => _openSpecialty(specialty),
                    ),
                  )
                  .toList(growable: false),
            ),
            _CatalogList(
              key: const Key('admin-service-catalog'),
              intro:
                  'Services define bookable care and their expected duration.',
              addLabel: 'Add service',
              onAdd: _openService,
              emptyMessage: 'No services configured.',
              children: _services
                  .map(
                    (service) => _CatalogCard(
                      title: service.name,
                      description: [
                        if (service.durationMinutes != null)
                          '${service.durationMinutes} minutes',
                        if (service.status != null) _label(service.status!),
                        if (service.description?.trim().isNotEmpty == true)
                          service.description!,
                      ].join(' · '),
                      icon: Icons.medical_services_outlined,
                      onEdit: () => _openService(service),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminNotificationComposerScreen extends StatefulWidget {
  const AdminNotificationComposerScreen({
    required this.users,
    required this.repository,
    super.key,
  });

  final List<AdminUser> users;
  final AdminDataSource repository;

  @override
  State<AdminNotificationComposerScreen> createState() =>
      _AdminNotificationComposerScreenState();
}

class _AdminNotificationComposerScreenState
    extends State<AdminNotificationComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _userId;
  String _type = 'GENERAL';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final user = widget.users.firstWhere((item) => item.id == _userId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send notification?'),
        content: Text(
          'This message will be added to ${user.displayName}’s CareConnect notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send notification'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.sendNotification(
        userId: _userId!,
        type: _type,
        title: _titleController.text,
        message: _messageController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The notification could not be sent.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send notification')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            key: const Key('admin-notification-composer'),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              Text(
                'Message a patient or team member',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              const Text(
                'Notifications are delivered to one CareConnect account at a time.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                key: const Key('admin-notification-user'),
                initialValue: _userId,
                isExpanded: true,
                decoration: _decoration('Recipient'),
                items: widget.users
                    .map(
                      (user) => DropdownMenuItem(
                        value: user.id,
                        child: Text(user.displayName),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _userId = value),
                validator: (value) =>
                    value == null ? 'Select a recipient' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: const Key('admin-notification-type'),
                initialValue: _type,
                isExpanded: true,
                decoration: _decoration('Notification type'),
                items: _notificationTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_label(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('admin-notification-title'),
                controller: _titleController,
                maxLength: 100,
                buildCounter: _hideCounter,
                decoration: _decoration('Title'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('admin-notification-message'),
                controller: _messageController,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                buildCounter: _hideCounter,
                decoration: _decoration('Message'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Message is required'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('admin-send-notification'),
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send_rounded),
                label: Text(_sending ? 'Sending…' : 'Review and send'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialtyFormScreen extends StatefulWidget {
  const _SpecialtyFormScreen({required this.repository, this.specialty});

  final AdminDataSource repository;
  final CareSpecialty? specialty;

  @override
  State<_SpecialtyFormScreen> createState() => _SpecialtyFormScreenState();
}

class _SpecialtyFormScreenState extends State<_SpecialtyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.specialty?.name,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.specialty?.description,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.saveSpecialty(
        id: widget.specialty?.id,
        name: _name.text,
        description: _description.text,
      );
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'The specialty could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _CatalogFormScaffold(
    title: widget.specialty == null ? 'Add specialty' : 'Edit specialty',
    formKey: _formKey,
    error: _error,
    saving: _saving,
    onSave: _save,
    children: [
      TextFormField(
        key: const Key('admin-specialty-name'),
        controller: _name,
        decoration: _decoration('Specialty name'),
        validator: _required('Specialty name'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _description,
        minLines: 3,
        maxLines: 6,
        decoration: _decoration('Description (optional)'),
      ),
    ],
  );
}

class _ServiceFormScreen extends StatefulWidget {
  const _ServiceFormScreen({required this.repository, this.service});

  final AdminDataSource repository;
  final CareService? service;

  @override
  State<_ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<_ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.service?.name,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.service?.description,
  );
  late final TextEditingController _duration = TextEditingController(
    text: widget.service?.durationMinutes?.toString() ?? '',
  );
  late bool _active = widget.service?.status?.toUpperCase() != 'INACTIVE';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.saveService(
        id: widget.service?.id,
        name: _name.text,
        description: _description.text,
        durationMinutes: _duration.text.trim().isEmpty
            ? null
            : int.parse(_duration.text.trim()),
        status: _active ? 'ACTIVE' : 'INACTIVE',
      );
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'The service could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _CatalogFormScaffold(
    title: widget.service == null ? 'Add service' : 'Edit service',
    formKey: _formKey,
    error: _error,
    saving: _saving,
    onSave: _save,
    children: [
      TextFormField(
        key: const Key('admin-service-name'),
        controller: _name,
        decoration: _decoration('Service name'),
        validator: _required('Service name'),
      ),
      const SizedBox(height: 14),
      TextFormField(
        key: const Key('admin-service-duration'),
        controller: _duration,
        keyboardType: TextInputType.number,
        decoration: _decoration('Duration in minutes (optional)'),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          final duration = int.tryParse(value.trim());
          if (duration == null || duration < 5 || duration > 480) {
            return 'Enter a duration between 5 and 480 minutes';
          }
          return null;
        },
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _description,
        minLines: 3,
        maxLines: 6,
        decoration: _decoration('Description (optional)'),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: _active,
        onChanged: (value) => setState(() => _active = value),
        title: const Text('Active service'),
        subtitle: const Text(
          'Inactive services are hidden from guest discovery.',
        ),
      ),
    ],
  );
}

class _CatalogFormScaffold extends StatelessWidget {
  const _CatalogFormScaffold({
    required this.title,
    required this.formKey,
    required this.children,
    required this.error,
    required this.saving,
    required this.onSave,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final String? error;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 29),
            ),
            const SizedBox(height: 24),
            ...children,
            if (error != null) ...[
              const SizedBox(height: 14),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              key: const Key('admin-save-catalog-item'),
              onPressed: saving ? null : onSave,
              child: Text(saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.intro,
    required this.addLabel,
    required this.onAdd,
    required this.emptyMessage,
    required this.children,
    super.key,
  });

  final String intro;
  final String addLabel;
  final VoidCallback onAdd;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
    children: [
      Text(intro, style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: Text(addLabel),
      ),
      const SizedBox(height: 20),
      if (children.isEmpty)
        _CatalogCard(title: emptyMessage, icon: Icons.inventory_2_outlined)
      else
        ...children,
    ],
  );
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.title,
    required this.icon,
    this.description,
    this.onEdit,
  });

  final String title;
  final String? description;
  final IconData icon;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      leading: CircleAvatar(
        backgroundColor: AppColors.mintSoft,
        foregroundColor: AppColors.primary,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: description?.trim().isNotEmpty == true
          ? Text(description!)
          : null,
      trailing: onEdit == null
          ? null
          : IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
    ),
  );
}

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.border),
  ),
);

FormFieldValidator<String> _required(String label) =>
    (value) =>
        value == null || value.trim().isEmpty ? '$label is required' : null;

String _label(String value) => value
    .toLowerCase()
    .split('_')
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

const _notificationTypes = [
  'GENERAL',
  'APPOINTMENT_UPDATE',
  'APPOINTMENT_REMINDER',
  'CHECK_IN',
];

Widget? _hideCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) => null;
