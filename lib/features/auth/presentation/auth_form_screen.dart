import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/auth/data/auth_service.dart';
import 'package:careconnect_mobile/features/auth/domain/auth_session.dart';
import 'package:careconnect_mobile/shared/widgets/careconnect_mark.dart';
import 'package:flutter/material.dart';

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({
    required this.authService,
    required this.signUp,
    super.key,
  });

  final AuthDataSource authService;
  final bool signUp;

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _busy = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const {};
    });

    try {
      final AuthSession session;
      if (widget.signUp) {
        session = await widget.authService.register(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phone: _phoneController.text,
        );
      } else {
        session = await widget.authService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(session);
    } on ApiException catch (error) {
      if (mounted) {
        final fieldErrors = error.fieldErrors.map(
          (field, messages) => MapEntry(
            field,
            messages.isEmpty ? error.message : messages.first,
          ),
        );
        setState(() {
          _fieldErrors = fieldErrors;
          _error = fieldErrors.isEmpty ? error.message : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Something went wrong. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final required = _required(value, 'Email');
    if (required != null) return required;
    final email = value!.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final required = _required(value, 'Password');
    if (required != null) return required;
    if (widget.signUp && value!.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

  void _clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field)) return;
    setState(() {
      _fieldErrors = Map.of(_fieldErrors)..remove(field);
    });
  }

  @override
  Widget build(BuildContext context) {
    final signUp = widget.signUp;
    return Scaffold(
      appBar: AppBar(title: Text(signUp ? 'Create account' : 'Welcome back')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            key: Key(signUp ? 'register-screen' : 'login-screen'),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CareConnectMark(size: 52),
              ),
              const SizedBox(height: 22),
              Text(
                signUp ? 'Start your care journey' : 'Good to see you again',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 9),
              Text(
                signUp
                    ? 'Create your private CareConnect account to book and manage appointments.'
                    : 'Sign in to manage appointments and keep your care organized.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                _AuthError(message: _error!),
              ],
              const SizedBox(height: 24),
              if (signUp) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('register-first-name'),
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.givenName],
                        onChanged: (_) => _clearFieldError('firstName'),
                        validator: (value) => _required(value, 'First name'),
                        forceErrorText: _fieldErrors['firstName'],
                        decoration: const InputDecoration(
                          labelText: 'First name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('register-last-name'),
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.familyName],
                        onChanged: (_) => _clearFieldError('lastName'),
                        validator: (value) => _required(value, 'Last name'),
                        forceErrorText: _fieldErrors['lastName'],
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                key: const Key('auth-email-field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                onChanged: (_) => _clearFieldError('email'),
                validator: _validateEmail,
                forceErrorText: _fieldErrors['email'],
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              if (signUp) ...[
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('register-phone-field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('auth-password-field'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: signUp
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: [
                  signUp ? AutofillHints.newPassword : AutofillHints.password,
                ],
                enableSuggestions: false,
                autocorrect: false,
                onChanged: (_) => _clearFieldError('password'),
                validator: _validatePassword,
                forceErrorText: _fieldErrors['password'],
                onFieldSubmitted: signUp ? null : (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
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
              ),
              if (signUp) ...[
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('register-confirm-password'),
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  enableSuggestions: false,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    final required = _required(value, 'Confirm password');
                    if (required != null) return required;
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('auth-submit-button'),
                onPressed: _busy ? null : _submit,
                child: Text(
                  _busy
                      ? (signUp ? 'Creating account…' : 'Signing in…')
                      : (signUp ? 'Create account' : 'Sign in'),
                ),
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      signUp
                          ? 'Your password is sent only to the CareConnect API.'
                          : 'Your session is encrypted on this device.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F0),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF3C8C8)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFB84C4C)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFF8F3535), height: 1.35),
          ),
        ),
      ],
    ),
  );
}
