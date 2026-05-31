import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/custom_dialog.dart';

import '../core/di/service_locator.dart';
import '../core/env/app_environment.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'registration_page.dart';
import 'onboarding_page.dart';

const bool _emailAuthEnabled = false;
const bool _continueWithoutSignInEnabled = false;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _busy = false;
  String? _error;

  ServiceLocator get _locator => ServiceLocator.instance;

  bool get _isDemo => _locator.environment == AppEnvironment.demo;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await _locator.authService.signInWithGoogleAndBackend();
    if (!mounted) return;

    if (result.success && !result.isNewUser) {
      await _continueAfterSuccessfulSignIn();
    } else if (result.isNewUser) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RegistrationPage(
            googleIdToken: result.googleIdToken ?? '',
            email: result.email ?? '',
            displayName: result.displayName ?? '',
            photoUrl: result.photoUrl,
          ),
        ),
      );
    } else {
      setState(() {
        _busy = false;
        _error = result.error ?? t?.authSignInFailed ?? t?.error;
      });
      return;
    }

    if (mounted) setState(() => _busy = false);
  }

  Future<void> _handleEmailLogin() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await _locator.authService.signInWithEmailAndBackend(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      await _continueAfterSuccessfulSignIn();
      if (mounted) setState(() => _busy = false);
      return;
    }

    setState(() {
      _busy = false;
      _error = result.error ?? t?.authEmailSignInFailed ?? t?.error;
    });
  }

  Future<void> _handleEmailRegister() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await _locator.authService.registerWithEmailAndBackend(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      termsAccepted: _termsAccepted,
      privacyPolicyAccepted: _privacyAccepted,
    );

    if (!mounted) return;

    if (result.success) {
      await _continueAfterSuccessfulSignIn();
      if (mounted) setState(() => _busy = false);
      return;
    }

    setState(() {
      _busy = false;
      _error = result.error ?? t?.authEmailRegistrationFailed ?? t?.error;
    });
  }

  Future<void> _continueAfterSuccessfulSignIn() async {
    try {
      final decision = await _locator.authService
          .determinePostAuthDestination();
      if (!mounted) return;

      if (decision.destination == PostAuthDestination.onboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
        );
      } else {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  Future<void> _showEmailDialog({required bool isRegister}) async {
    if (!_emailAuthEnabled) {
      return;
    }

    final t = AppLocalizations.of(context)!;
    _error = null;
    _emailController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _termsAccepted = false;
    _privacyAccepted = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CustomDialog(
              title: isRegister
                  ? t.authCreateAccountWithEmail
                  : t.authSignInWithEmail,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: t.email),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: t.authPasswordLabel,
                      ),
                    ),
                    if (isRegister) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _firstNameController,
                        decoration: InputDecoration(labelText: t.authFirstName),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(labelText: t.authLastName),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.authAcceptTermsOfService),
                        value: _termsAccepted,
                        onChanged: (v) =>
                            setDialogState(() => _termsAccepted = v ?? false),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.authAcceptPrivacyPolicy),
                        value: _privacyAccepted,
                        onChanged: (v) =>
                            setDialogState(() => _privacyAccepted = v ?? false),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(t.cancel),
                ),
                ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          Navigator.of(dialogContext).pop();
                          if (isRegister) {
                            await _handleEmailRegister();
                          } else {
                            await _handleEmailLogin();
                          }
                        },
                  child: Text(isRegister ? t.authRegister : t.authSignIn),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Column(
                      children: [
                        Image.asset(
                          'assets/icontransparent.png',
                          width: 96,
                          height: 96,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.appTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t.welcome,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.authSecureMedicalRecordsVault,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            _featureRow(
                              icon: Icons.verified_user_outlined,
                              title: t.authHipaaGdprCompliant,
                              subtitle: t.authDataEncryptedSecure,
                            ),
                            const SizedBox(height: 10),
                            _featureRow(
                              icon: Icons.lock_outline,
                              title: t.authEndToEndEncryption,
                              subtitle: t.authOnlyYouControlRecords,
                            ),
                            const SizedBox(height: 16),
                            if (_error != null)
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1F1F1F),
                                side: const BorderSide(
                                  color: Color(0xFF747775),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: const Size.fromHeight(40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              icon: SizedBox(
                                width: 18,
                                height: 18,
                                child: _isDemo
                                    ? const Icon(Icons.smart_toy, size: 18)
                                    : SvgPicture.asset(
                                        'assets/google_logo.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                              ),
                              label: Text(
                                _busy
                                    ? (_isDemo
                                          ? t.authSigningInDemo
                                          : t.authSigningIn)
                                    : (_isDemo
                                          ? t.authContinueWithDemoGoogle
                                          : t.signInWithGoogle),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_emailAuthEnabled) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _showEmailDialog(isRegister: false),
                                icon: const Icon(Icons.alternate_email),
                                label: Text(t.authSignInWithEmail),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _showEmailDialog(isRegister: true),
                                icon: const Icon(Icons.person_add_alt_1),
                                label: Text(t.authCreateAccountWithEmail),
                              ),
                            ],
                            if (_busy) ...[
                              const SizedBox(height: 10),
                              const LinearProgressIndicator(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_continueWithoutSignInEnabled) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const HomePage(),
                                  ),
                                );
                              },
                        child: Text(
                          t.continueWithoutSignIn,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
