import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_translations.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_text_field.dart';

import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const SignupScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isEmailValid => _emailRegex.hasMatch(_emailController.text.trim());

  bool get _isFormValid {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    return name.isNotEmpty &&
        _emailRegex.hasMatch(email) &&
        pass.length >= 6 &&
        pass == confirm;
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = context.tr('password_mismatch');
      });
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    widget.authService.setStorageService(widget.storageService);

    // 1. Check if email already registered & verified
    if (widget.storageService.isEmailRegistered(email) &&
        widget.storageService.isEmailVerified(email)) {
      setState(() {
        _isLoading = false;
        _errorMessage = context.tr('auth_email_in_use');
      });
      return;
    }

    // 2. Generate random 6-digit OTP code
    final otpCode = (100000 + Random().nextInt(900000)).toString();

    // 3. Save pending credentials in AuthService
    widget.authService.savePendingSignUp(
      name: name,
      email: email,
      password: password,
      otp: otpCode,
    );

    // Register user in local storage as unverified initially
    if (!widget.storageService.isEmailRegistered(email)) {
      await widget.storageService.registerUser(
        name: name,
        email: email,
        password: password,
      );
    }

    // 4. Call sendRealEmailOtp
    bool sent = false;
    try {
      sent = await widget.authService.sendRealEmailOtp(
        toEmail: email,
        otpCode: otpCode,
      );
    } catch (e) {
      debugPrint('Sign-up real email dispatch error: $e');
      sent = false;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (sent) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            name: name,
            authService: widget.authService,
            storageService: widget.storageService,
            expectedOtp: otpCode,
            pendingPassword: password,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ইমেইল পাঠাতে সমস্যা হয়েছে, আবার চেষ্টা করুন'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.tr('signup_title')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('signup_title'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('signup_subtitle'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error message banner
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Full Name
                  CustomTextField(
                    controller: _nameController,
                    label: context.tr('full_name'),
                    hint: context.tr('full_name_hint'),
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return context.tr('full_name');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: context.tr('email'),
                    hint: context.tr('email_hint'),
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    suffixIcon: _isEmailValid
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          )
                        : null,
                    helperText:
                        (_emailController.text.trim().isNotEmpty &&
                            !_isEmailValid)
                        ? context.tr('auth_invalid_email_short')
                        : null,
                    helperStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    validator: (val) {
                      final email = val?.trim() ?? '';
                      if (email.isEmpty) {
                        return context.tr('auth_invalid_email_hint');
                      }
                      if (!_emailRegex.hasMatch(email)) {
                        return context.tr('auth_invalid_email_hint');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password
                  CustomTextField(
                    controller: _passwordController,
                    label: context.tr('password'),
                    hint: context.tr('password_hint'),
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return context.tr('password_hint');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Confirm Password
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: context.tr('confirm_password'),
                    hint: context.tr('confirm_password_hint'),
                    prefixIcon: Icons.lock_reset_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return context.tr('confirm_password_hint');
                      }
                      if (val != _passwordController.text) {
                        return context.tr('password_mismatch');
                      }
                      return null;
                    },
                    onSubmitted: (_) => _isFormValid ? _handleSignup() : null,
                  ),
                  const SizedBox(height: 28),

                  // Signup Button
                  ElevatedButton(
                    onPressed: (_isFormValid && !_isLoading)
                        ? _handleSignup
                        : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(context.tr('signup_btn')),
                  ),
                  const SizedBox(height: 20),

                  // Have Account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('have_account'),
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          context.tr('login_link'),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
