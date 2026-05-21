import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../theme/atoms/app_input.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryBiometricLogin();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricLogin() async {
    if (!ApiService.isAuthenticated) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_enabled') ?? false;
    if (!enabled) return;

    final auth = LocalAuthentication();
    final available = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (!available) return;

    final ok = await auth.authenticate(
      localizedReason: 'Unlock Solo OS',
      options: const AuthenticationOptions(biometricOnly: true),
    );
    if (ok && mounted) {
      widget.onAuthSuccess?.call();
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;
      if (identityToken == null) {
        setState(() => _error = 'Apple Sign-In failed: no token received.');
        return;
      }

      String? displayName;
      if (credential.givenName != null || credential.familyName != null) {
        displayName = [credential.givenName, credential.familyName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
      }

      await ApiService.signInWithApple(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        email: credential.email,
        displayName: displayName,
      );

      widget.onAuthSuccess?.call();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        setState(() => _error = 'Apple Sign-In failed. Please try again.');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    if (!_isLogin && name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await ApiService.signIn(email: email, password: password);
      } else {
        await ApiService.signUp(
          email: email,
          password: password,
          displayName: name,
        );
      }
      widget.onAuthSuccess?.call();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: SpaceTokens.s32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand mark
                Text(
                  'Solo OS',
                  style: TextStyles.displayLg(context),
                ),
                const SizedBox(height: SpaceTokens.s4),
                Text(
                  'Your personal operating system',
                  style: TextStyles.bodyMd(context).copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: SpaceTokens.s48),

                // Screen title
                Text(
                  _isLogin ? 'Welcome back' : 'Create your account',
                  style: TextStyles.displayMd(context),
                ),
                const SizedBox(height: SpaceTokens.s24),

                // Name (signup only)
                if (!_isLogin) ...[
                  AppInput(
                    controller: _nameCtrl,
                    hintText: 'Your name',
                    prefixIcon: const Icon(Icons.person_outlined),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: SpaceTokens.s12),
                ],

                // Email
                AppInput(
                  controller: _emailCtrl,
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: SpaceTokens.s12),

                // Password
                AppInput(
                  controller: _passwordCtrl,
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),

                // Error banner
                if (_error != null) ...[
                  const SizedBox(height: SpaceTokens.s12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(SpaceTokens.s12),
                    decoration: BoxDecoration(
                      color: c.danger.withValues(alpha: 0.08),
                      borderRadius: RadiusTokens.smAll,
                      border: Border.all(color: c.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(_error!,
                        style: TextStyles.bodySm(context).copyWith(color: c.dangerFg)),
                  ),
                ],

                const SizedBox(height: SpaceTokens.s24),

                // Primary CTA
                AppButton(
                  label: _isLogin ? 'Sign In' : 'Create Account',
                  isFullWidth: true,
                  size: AppButtonSize.lg,
                  isLoading: _loading,
                  onPressed: _loading ? null : _submit,
                ),

                // Apple Sign-In (iOS only)
                if (Platform.isIOS) ...[
                  const SizedBox(height: SpaceTokens.s16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: SpaceTokens.s16),
                        child: Text('or',
                            style: TextStyles.bodySm(context)
                                .copyWith(color: c.textSecondary)),
                      ),
                      Expanded(child: Divider(color: c.border)),
                    ],
                  ),
                  const SizedBox(height: SpaceTokens.s16),
                  // Apple button — white bg + black text per Apple HIG
                  AppButton(
                    label: 'Sign in with Apple',
                    isFullWidth: true,
                    size: AppButtonSize.lg,
                    variant: AppButtonVariant.secondary,
                    leadingIcon: const Icon(Icons.apple),
                    isLoading: _loading,
                    onPressed: _loading ? null : _signInWithApple,
                  ),
                ],

                const SizedBox(height: SpaceTokens.s24),

                // Toggle login / signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: TextStyles.bodyMd(context)
                          .copyWith(color: c.textSecondary),
                    ),
                    AppButton(
                      label: _isLogin ? 'Sign Up' : 'Sign In',
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      onPressed: () => setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
