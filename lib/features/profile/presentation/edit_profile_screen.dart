import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.isPreview,
    this.onSave,
  });
  final CurrentUser user;
  final bool isPreview;
  final Future<CurrentUser> Function(CurrentUser user)? onSave;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.user.firstName);
  late final _lastName = TextEditingController(text: widget.user.lastName);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _dateOfBirth = TextEditingController(
    text: _formatDate(widget.user.dateOfBirth),
  );
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _dateOfBirth.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? value) => value == null
      ? ''
      : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: widget.user.dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected != null) _dateOfBirth.text = _formatDate(selected);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = widget.user.copyWith(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      dateOfBirth: DateTime.tryParse(_dateOfBirth.text),
    );
    if (widget.onSave == null) {
      Navigator.of(context).pop(updated);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final saved = await widget.onSave!(updated);
      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error =
            'Your changes could not be saved. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Personal details')),
    body: Form(
      key: _formKey,
      child: ListView(
        key: const Key('edit-profile-screen'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        children: [
          Text(
            'Keep your details up to date',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 23),
          ),
          const SizedBox(height: 7),
          const Text(
            'Clinics use this information to manage appointment requests.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('profile-first-name-field'),
                  controller: _firstName,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('profile-last-name-field'),
                  controller: _lastName,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: widget.user.email,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Email address',
              helperText: 'Email is managed by your sign-in account',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('profile-phone-field'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Phone number'),
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 9 ? 'Enter a valid phone number' : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('profile-date-of-birth-field'),
            controller: _dateOfBirth,
            readOnly: true,
            onTap: _pickDate,
            decoration: const InputDecoration(
              labelText: 'Date of birth',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            validator: (value) => DateTime.tryParse(value ?? '') == null
                ? 'Choose your date of birth'
                : null,
          ),
          if (widget.isPreview) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Text(
                'Preview mode: changes stay on this device until sign-in and the backend profile flow are enabled.',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 18),
            Container(
              key: const Key('profile-save-error'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFF9C3F3F),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save-profile-button'),
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? 'Saving…' : 'Save changes'),
          ),
        ],
      ),
    ),
  );
}
