import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:flutter/material.dart';

class AdminUserFormScreen extends StatefulWidget {
  const AdminUserFormScreen({required this.repository, super.key});

  final AdminDataSource repository;

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _password = TextEditingController();
  final Map<String, String> _fieldErrors = {};
  String _status = 'ACTIVE';
  bool _obscurePassword = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _dateOfBirth.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Patient date of birth',
    );
    if (selected == null) return;
    _dateOfBirth.text =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    setState(() {
      _fieldErrors.clear();
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.repository.createUser(
        email: _email.text,
        password: _password.text,
        firstName: _firstName.text,
        lastName: _lastName.text,
        dateOfBirth: _optional(_dateOfBirth.text),
        phone: _optional(_phone.text),
        status: _status,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        for (final field in const [
          'firstName',
          'lastName',
          'email',
          'password',
        ]) {
          final message = error.fieldError(field);
          if (message != null) _fieldErrors[field] = message;
        }
        _error = _fieldErrors.isEmpty ? error.message : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The CareConnect user could not be created.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.remove(field) != null) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add user')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          key: const Key('admin-user-form'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Text(
              'Create a patient account',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            const Text(
              'The account receives the Patient role automatically. Share the temporary password through a secure channel.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('admin-user-first-name'),
                    controller: _firstName,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    forceErrorText: _fieldErrors['firstName'],
                    onChanged: (_) => _clearFieldError('firstName'),
                    decoration: _decoration('First name'),
                    validator: (value) => _required(value, 'First name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('admin-user-last-name'),
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.familyName],
                    forceErrorText: _fieldErrors['lastName'],
                    onChanged: (_) => _clearFieldError('lastName'),
                    decoration: _decoration('Last name'),
                    validator: (value) => _required(value, 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('admin-user-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              forceErrorText: _fieldErrors['email'],
              onChanged: (_) => _clearFieldError('email'),
              decoration: _decoration('Email address'),
              validator: (value) {
                final required = _required(value, 'Email address');
                if (required != null) return required;
                return RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(value!.trim())
                    ? null
                    : 'Enter a valid email address';
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('admin-user-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: _decoration('Phone number (optional)'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('admin-user-date-of-birth'),
              controller: _dateOfBirth,
              readOnly: true,
              onTap: _pickDate,
              decoration: _decoration('Date of birth (optional)').copyWith(
                hintText: 'YYYY-MM-DD',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('admin-user-password'),
              controller: _password,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              forceErrorText: _fieldErrors['password'],
              onChanged: (_) => _clearFieldError('password'),
              decoration: _decoration('Temporary password').copyWith(
                helperText: 'Use at least 8 characters.',
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final required = _required(value, 'Temporary password');
                if (required != null) return required;
                return value!.length < 8 ? 'Use at least 8 characters' : null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const Key('admin-user-status'),
              initialValue: _status,
              decoration: _decoration('Account status'),
              items: const [
                DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _status = value ?? 'ACTIVE'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 18),
              Container(
                key: const Key('admin-user-form-error'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EE),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('admin-save-user'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: Text(_saving ? 'Creating…' : 'Create user'),
            ),
          ],
        ),
      ),
    ),
  );
}

InputDecoration _decoration(String label) => InputDecoration(labelText: label);

String? _required(String? value, String label) =>
    value == null || value.trim().isEmpty ? '$label is required' : null;

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
