import 'package:careconnect_mobile/core/network/api_exception.dart';
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
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _busy = false;

  String? _error;
  Map<String, String> _fieldErrors = const {};

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = Color(0xFF00A79D);
  static const Color primaryDark = Color(0xFF008A82);

  static const Color textPrimary = Color(0xFF102B32);
  static const Color textSecondary = Color(0xFF82969C);

  static const Color borderColor = Color(0xFFDDE9E9);
  static const Color background = Color(0xFFFAFCFC);

  // ============================================================
  // DISPOSE
  // ============================================================

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

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.signUp && !_agreeToTerms) {
      setState(() {
        _error = 'Please accept the Terms of Service and Privacy Policy.';
      });

      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const {};
    });

    try {
      final AuthSession session;

      if (widget.signUp) {
        session = await widget.authService.register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
        );
      } else {
        session = await widget.authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(session);
    } on ApiException catch (error) {
      if (!mounted) return;

      final fieldErrors = error.fieldErrors.map(
        (field, messages) =>
            MapEntry(field, messages.isEmpty ? error.message : messages.first),
      );

      setState(() {
        _fieldErrors = fieldErrors;

        _error = fieldErrors.isEmpty ? error.message : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Something went wrong. Check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final required = _required(value, 'Email');

    if (required != null) {
      return required;
    }

    final email = value!.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final required = _required(value, 'Password');

    if (required != null) {
      return required;
    }

    if (widget.signUp && value!.length < 8) {
      return 'Use at least 8 characters';
    }

    return null;
  }

  void _clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field)) {
      return;
    }

    setState(() {
      _fieldErrors = Map.of(_fieldErrors)..remove(field);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final signUp = widget.signUp;

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // FIXED HEADER
            // ==================================================
            Container(
              width: double.infinity,
              color: background,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------------------------------------
                  // BACK BUTTON
                  // ---------------------------------------------
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    padding: const EdgeInsets.all(4),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 26,
                      color: textPrimary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // ---------------------------------------------
                  // LOGO + BRAND
                  // ---------------------------------------------
                  Row(
                    children: [
                      const CareConnectMark(size: 48),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Care',
                                    style: TextStyle(color: textPrimary),
                                  ),
                                  TextSpan(
                                    text: 'Connect',
                                    style: TextStyle(color: primary),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 2),

                            const Text(
                              'Your Health, Our Priority',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ---------------------------------------------
                  // TITLE
                  // ---------------------------------------------
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 28,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                      children: signUp
                          ? const [
                              TextSpan(text: 'Create your\n'),
                              TextSpan(
                                text: 'CareConnect ',
                                style: TextStyle(color: primary),
                              ),
                              TextSpan(text: 'account'),
                            ]
                          : const [
                              TextSpan(text: 'Welcome back to\n'),
                              TextSpan(
                                text: 'CareConnect',
                                style: TextStyle(color: primary),
                              ),
                            ],
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    signUp
                        ? 'Start your care journey and book appointments with ease.'
                        : 'Sign in to manage appointments and keep your care organized.',
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // HEADER DIVIDER
            // ==================================================
            Container(height: 1, color: borderColor.withValues(alpha: 0.55)),

            // ==================================================
            // SCROLLABLE FORM
            // ==================================================
            Expanded(
              child: Form(
                key: _formKey,

                child: ListView(
                  key: Key(signUp ? 'register-screen' : 'login-screen'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  children: [
                    // -------------------------------------------
                    // ERROR MESSAGE
                    // -------------------------------------------
                    if (_error != null) ...[
                      _AuthError(message: _error!),

                      const SizedBox(height: 14),
                    ],

                    // -------------------------------------------
                    // FIRST NAME + LAST NAME
                    // -------------------------------------------
                    if (signUp) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ModernField(
                              key: const Key('register-first-name'),
                              controller: _firstNameController,
                              hint: 'First name',
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.givenName],
                              validator: (value) {
                                return _required(value, 'First name');
                              },
                              forceErrorText: _fieldErrors['firstName'],
                              onChanged: (_) {
                                _clearFieldError('firstName');
                              },
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: _ModernField(
                              key: const Key('register-last-name'),
                              controller: _lastNameController,
                              hint: 'Last name',
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.familyName],
                              validator: (value) {
                                return _required(value, 'Last name');
                              },
                              forceErrorText: _fieldErrors['lastName'],
                              onChanged: (_) {
                                _clearFieldError('lastName');
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 11),
                    ],

                    // -------------------------------------------
                    // EMAIL
                    // -------------------------------------------
                    _ModernField(
                      key: const Key('auth-email-field'),
                      controller: _emailController,
                      hint: 'Email address',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      validator: _validateEmail,
                      forceErrorText: _fieldErrors['email'],
                      onChanged: (_) {
                        _clearFieldError('email');
                      },
                    ),

                    // -------------------------------------------
                    // PHONE
                    // -------------------------------------------
                    if (signUp) ...[
                      const SizedBox(height: 11),

                      _PhoneField(controller: _phoneController),
                    ],

                    const SizedBox(height: 11),

                    // -------------------------------------------
                    // PASSWORD
                    // -------------------------------------------
                    _ModernField(
                      key: const Key('auth-password-field'),
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: signUp
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: [
                        signUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      enableSuggestions: false,
                      autocorrect: false,
                      validator: _validatePassword,
                      forceErrorText: _fieldErrors['password'],
                      onChanged: (_) {
                        _clearFieldError('password');
                      },
                      onFieldSubmitted: signUp
                          ? null
                          : (_) {
                              _submit();
                            },
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: textSecondary,
                        ),
                      ),
                    ),

                    // -------------------------------------------
                    // CONFIRM PASSWORD
                    // -------------------------------------------
                    if (signUp) ...[
                      const SizedBox(height: 11),

                      _ModernField(
                        key: const Key('register-confirm-password'),
                        controller: _confirmPasswordController,
                        hint: 'Confirm password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        enableSuggestions: false,
                        autocorrect: false,
                        validator: (value) {
                          final required = _required(value, 'Confirm password');

                          if (required != null) {
                            return required;
                          }

                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) {
                          _submit();
                        },
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: textSecondary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // -----------------------------------------
                      // PASSWORD INFORMATION
                      // -----------------------------------------
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F8F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            _PasswordCheckIcon(),

                            SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Use a strong password',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  SizedBox(height: 1),

                                  Text(
                                    'At least 8 characters with letters, numbers and a symbol.',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 10.5,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // -----------------------------------------
                      // TERMS
                      // -----------------------------------------
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Checkbox(
                              value: _agreeToTerms,
                              activeColor: primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              side: const BorderSide(
                                color: Color(0xFF8AA0A4),
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;

                                  _error = null;
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 4),

                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(text: 'I agree to the '),

                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),

                                    TextSpan(text: ' and '),

                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),

                                    TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ==================================================
            // FIXED BOTTOM CTA
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              decoration: const BoxDecoration(
                color: background,
                border: Border(top: BorderSide(color: borderColor, width: 0.8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------------------------------------------
                  // MAIN BUTTON
                  // ---------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      key: const Key('auth-submit-button'),
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0x6600A79D),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  signUp ? 'Create account' : 'Sign in',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 19,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 9),

                  // ---------------------------------------------
                  // SECURITY INFO
                  // ---------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 12,
                        color: textSecondary,
                      ),

                      const SizedBox(width: 5),

                      Flexible(
                        child: Text(
                          signUp
                              ? 'Your password is sent only to the CareConnect API.'
                              : 'Your session is encrypted on this device.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 9.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MODERN INPUT FIELD
// ============================================================

class _ModernField extends StatelessWidget {
  const _ModernField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.obscureText = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.validator,
    this.forceErrorText,
    this.onChanged,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;

  final String hint;
  final IconData icon;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  final TextCapitalization textCapitalization;

  final Iterable<String>? autofillHints;

  final bool obscureText;
  final bool enableSuggestions;
  final bool autocorrect;

  final String? Function(String?)? validator;

  final String? forceErrorText;

  final ValueChanged<String>? onChanged;

  final ValueChanged<String>? onFieldSubmitted;

  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,

      keyboardType: keyboardType,

      textInputAction: textInputAction,

      textCapitalization: textCapitalization,

      autofillHints: autofillHints,

      obscureText: obscureText,

      enableSuggestions: enableSuggestions,

      autocorrect: autocorrect,

      validator: validator,

      forceErrorText: forceErrorText,

      onChanged: onChanged,

      onFieldSubmitted: onFieldSubmitted,

      cursorColor: _AuthFormScreenState.primary,

      style: const TextStyle(
        color: _AuthFormScreenState.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: const TextStyle(
          color: _AuthFormScreenState.textSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),

        prefixIcon: Icon(
          icon,
          size: 20,
          color: _AuthFormScreenState.textPrimary,
        ),

        suffixIcon: suffixIcon,

        filled: true,

        fillColor: Colors.white,

        isDense: true,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _AuthFormScreenState.borderColor),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _AuthFormScreenState.primary,
            width: 1.4,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE26A6A)),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE26A6A), width: 1.4),
        ),

        errorStyle: const TextStyle(fontSize: 10.5),
      ),
    );
  }
}

// ============================================================
// PHONE FIELD
// ============================================================

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: _AuthFormScreenState.borderColor),
      ),

      child: Row(
        children: [
          const SizedBox(width: 15),

          const Icon(
            Icons.phone_outlined,
            size: 20,
            color: _AuthFormScreenState.textPrimary,
          ),

          const SizedBox(width: 12),

          // Country code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F6),

              borderRadius: BorderRadius.circular(8),
            ),

            child: const Text(
              '+94',
              style: TextStyle(
                color: _AuthFormScreenState.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 1,
            height: 24,
            color: _AuthFormScreenState.borderColor,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextFormField(
              key: const Key('register-phone-field'),

              controller: controller,

              keyboardType: TextInputType.phone,

              textInputAction: TextInputAction.next,

              autofillHints: const [AutofillHints.telephoneNumber],

              cursorColor: _AuthFormScreenState.primary,

              style: const TextStyle(
                color: _AuthFormScreenState.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),

              decoration: const InputDecoration(
                border: InputBorder.none,

                enabledBorder: InputBorder.none,

                focusedBorder: InputBorder.none,

                errorBorder: InputBorder.none,

                focusedErrorBorder: InputBorder.none,

                hintText: '77 123 4567',

                hintStyle: TextStyle(
                  color: _AuthFormScreenState.textSecondary,
                  fontSize: 13.5,
                ),

                contentPadding: EdgeInsets.symmetric(vertical: 17),
              ),
            ),
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ============================================================
// PASSWORD CHECK ICON
// ============================================================

class _PasswordCheckIcon extends StatelessWidget {
  const _PasswordCheckIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,

      decoration: const BoxDecoration(
        color: _AuthFormScreenState.primary,

        shape: BoxShape.circle,
      ),

      child: const Icon(Icons.check_rounded, color: Colors.white, size: 17),
    );
  }
}

// ============================================================
// ERROR MESSAGE
// ============================================================

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),

      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFFF2CCCC)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB84C4C),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              message,

              style: const TextStyle(
                color: Color(0xFF8F3535),

                fontSize: 12,

                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
