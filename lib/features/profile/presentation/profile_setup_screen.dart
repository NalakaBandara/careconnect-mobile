import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/features/profile/domain/profile_creation_request.dart';
import 'package:flutter/material.dart';

typedef CreateProfileCallback =
    Future<CurrentUser> Function(ProfileCreationRequest request);
typedef ProfileHomeBuilder =
    Widget Function(BuildContext context, CurrentUser user);
typedef ExitProfileSetupCallback = Future<void> Function(BuildContext context);

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.onCreate,
    required this.homeBuilder,
    required this.onExit,
    this.email,
    this.displayName,
  });

  final String? email;
  final String? displayName;
  final CreateProfileCallback onCreate;
  final ProfileHomeBuilder homeBuilder;
  final ExitProfileSetupCallback onExit;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  final _phone = TextEditingController();
  final _dateOfBirth = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final nameParts = (widget.displayName ?? '').trim().split(RegExp(r'\s+'));
    final hasName = nameParts.isNotEmpty && nameParts.first.isNotEmpty;
    _firstName = TextEditingController(text: hasName ? nameParts.first : '');
    _lastName = TextEditingController(
      text: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
    );
    _email = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _dateOfBirth.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected == null) return;
    _dateOfBirth.text =
        '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await widget.onCreate(
        ProfileCreationRequest(
          firstName: _firstName.text,
          lastName: _lastName.text,
          email: _email.text,
          dateOfBirth: DateTime.parse(_dateOfBirth.text),
          phone: _phone.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (homeContext) => widget.homeBuilder(homeContext, user),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'We could not create your profile. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Complete your profile'),
        leading: IconButton(
          tooltip: 'Sign out',
          onPressed: _busy ? null : () => widget.onExit(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          key: const Key('profile-setup-screen'),
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 34),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'One last step',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add the details clinics need to manage your appointment requests.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            if (_error != null) ...[
              const SizedBox(height: 18),
              Container(
                key: const Key('profile-setup-error'),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFB84C4C),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('profile-setup-first-name'),
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
                    key: const Key('profile-setup-last-name'),
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
              key: const Key('profile-setup-email'),
              controller: _email,
              enabled: widget.email == null,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email address',
                helperText: widget.email == null
                    ? 'Required because the API token has no email claim'
                    : 'Verified by your sign-in account',
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                return !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                    ? 'Enter a valid email address'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('profile-setup-phone'),
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
              key: const Key('profile-setup-date-of-birth'),
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
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF5276D8),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your Auth0 identity stays linked to this profile. CareConnect never receives your password.',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('create-profile-submit'),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create my profile'),
            ),
          ],
        ),
      ),
    ),
  );
}
