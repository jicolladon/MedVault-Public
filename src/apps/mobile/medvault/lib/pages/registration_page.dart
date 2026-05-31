import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

import '../core/di/service_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/gender.dart';
import '../models/api_models.dart';
import '../services/api/auth_api.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'onboarding_page.dart';

extension GenderLocalizationExtension on Gender {
  String localizedLabel(AppLocalizations t) {
    switch (this) {
      case Gender.male:
        return t.authGenderMale;
      case Gender.female:
        return t.authGenderFemale;
      case Gender.other:
        return t.authGenderOther;
      case Gender.preferNotToSay:
        return t.authGenderPreferNotToSay;
    }
  }
}

class RegistrationPage extends StatefulWidget {
  final String googleIdToken;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const RegistrationPage({
    super.key,
    required this.googleIdToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  Gender? _gender;
  DateTime? _dateOfBirth;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isLoading = false;
  String? _error;

  ServiceLocator get _locator => ServiceLocator.instance;

  @override
  void initState() {
    super.initState();
    final parts = (widget.displayName ?? '').split(' ');
    if (parts.isNotEmpty) _firstNameController.text = parts.first;
    if (parts.length > 1) _lastNameController.text = parts.sublist(1).join(' ');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() => _error = t.authDateOfBirthRequired);
      return;
    }

    if (!_termsAccepted || !_privacyAccepted) {
      setState(() => _error = t.authAcceptTermsPrivacyRequired);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = RegisterRequest(
        googleIdToken: widget.googleIdToken,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dateOfBirth!.toIso8601String(),
        gender: _gender,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        termsAccepted: _termsAccepted,
        privacyPolicyAccepted: _privacyAccepted,
      );

      final result = await _locator.authService.registerWithGoogleAndBackend(
        request: request,
      );

      if (!result.success) {
        setState(
          () => _error = result.error ?? t.authRegistrationFailedTryAgain,
        );
        return;
      }
      if (_locator.authService.demoMode) {
        await _locator.medicalDataService.seedDemoData(result.email!);
        await _locator.profileService.seedDemoEmergencyData(
          userId: result.email!,
        );
        await _locator.notificationsService.seedDemoNotificationsData(
          userId: result.email!,
        );
        await _locator.sharingService.seedDemoSharingData(
          userId: result.email!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.authRegistrationCompletedSuccessfully)),
        );

        final decision = await _locator.authService
            .determinePostAuthDestination();
        if (!mounted) {
          return;
        }

        if (decision.destination == PostAuthDestination.onboarding) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingPage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      log('Unexpected error during registration', error: e);
      setState(() => _error = t.authRegistrationFailedTryAgain);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRegistration() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _locator.authService.signOut();
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/landing', (route) => false);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reviewTerms({required bool isPrivacy}) async {
    final t = AppLocalizations.of(context)!;

    final title = isPrivacy
        ? t.authAcceptPrivacyPolicy
        : t.authAcceptTermsOfService;

    final acknowledgeLabel = t.authPolicyAcknowledge;
    final scrollHint = t.authPolicyScrollHint;
    final body = await _loadLegalDocumentBody(isPrivacy: isPrivacy);

    if (!mounted) {
      return;
    }

    final acknowledged = await showDialog<bool>(
      context: context,
      builder: (_) => _PolicyAcknowledgeDialog(
        title: title,
        body: body,
        scrollHint: scrollHint,
        closeTooltip: t.cancel,
        acknowledgeLabel: acknowledgeLabel,
      ),
    );

    if (!mounted || acknowledged != true) {
      return;
    }

    setState(() {
      if (isPrivacy) {
        _privacyAccepted = true;
      } else {
        _termsAccepted = true;
      }
    });
  }

  Future<String> _loadLegalDocumentBody({required bool isPrivacy}) async {
    final languageCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final baseName = isPrivacy ? 'privacy' : 'terms';
    final localizedAsset = 'assets/legal/$baseName.$languageCode.html';
    final fallbackAsset = 'assets/legal/$baseName.en.html';

    final html = await _loadAssetWithFallback(
      localizedAsset: localizedAsset,
      fallbackAsset: fallbackAsset,
    );

    return html;
  }

  Future<String> _loadAssetWithFallback({
    required String localizedAsset,
    required String fallbackAsset,
  }) async {
    try {
      return await rootBundle.loadString(localizedAsset);
    } catch (_) {
      return rootBundle.loadString(fallbackAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Form(
                        key: _formKey,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  t.authCompleteRegistration,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.email,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                if (widget.photoUrl != null) ...[
                                  const SizedBox(height: 14),
                                  Center(
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundImage: NetworkImage(
                                        widget.photoUrl!,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _firstNameController,
                                  decoration: InputDecoration(
                                    labelText: '${t.authFirstName} *',
                                    prefixIcon: const Icon(Icons.person),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? t.authRequiredField
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _lastNameController,
                                  decoration: InputDecoration(
                                    labelText: '${t.authLastName} *',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? t.authRequiredField
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.cake),
                                  title: Text(
                                    _dateOfBirth != null
                                        ? DateFormat.yMMMd().format(
                                            _dateOfBirth!,
                                          )
                                        : t.authDateOfBirth,
                                  ),
                                  trailing: const Icon(Icons.calendar_today),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _dateOfBirth ??
                                          DateTime.now().subtract(
                                            const Duration(days: 365 * 25),
                                          ),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() => _dateOfBirth = picked);
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<Gender>(
                                  initialValue: _gender,
                                  decoration: InputDecoration(
                                    labelText: t.authGender,
                                    prefixIcon: const Icon(Icons.wc),
                                  ),
                                  items: Gender.values
                                      .map(
                                        (gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender.localizedLabel(t)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => _gender = v),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: t.authPhoneNumber,
                                    prefixIcon: const Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                CheckboxListTile(
                                  value: _termsAccepted,
                                  onChanged: (v) async {
                                    if (v == null) {
                                      return;
                                    }

                                    if (!v) {
                                      setState(() => _termsAccepted = false);
                                      return;
                                    }

                                    await _reviewTerms(isPrivacy: false);
                                  },
                                  title: Text(
                                    '${t.authAcceptTermsOfService} *',
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                CheckboxListTile(
                                  value: _privacyAccepted,
                                  onChanged: (v) async {
                                    if (v == null) {
                                      return;
                                    }

                                    if (!v) {
                                      setState(() => _privacyAccepted = false);
                                      return;
                                    }

                                    await _reviewTerms(isPrivacy: true);
                                  },
                                  title: Text('${t.authAcceptPrivacyPolicy} *'),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _cancelRegistration,
                                        child: Text(t.cancel),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _register,
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(t.authRegister),
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PolicyAcknowledgeDialog extends StatefulWidget {
  final String title;
  final String body;
  final String scrollHint;
  final String closeTooltip;
  final String acknowledgeLabel;

  const _PolicyAcknowledgeDialog({
    required this.title,
    required this.body,
    required this.scrollHint,
    required this.closeTooltip,
    required this.acknowledgeLabel,
  });

  @override
  State<_PolicyAcknowledgeDialog> createState() =>
      _PolicyAcknowledgeDialogState();
}

class _PolicyAcknowledgeDialogState extends State<_PolicyAcknowledgeDialog> {
  late final ScrollController _scrollController;
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBottomState());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    _checkBottomState();
  }

  void _checkBottomState() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final atBottom =
        position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - 16;

    if (atBottom != _isAtBottom) {
      setState(() => _isAtBottom = atBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          IconButton(
            tooltip: widget.closeTooltip,
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: HtmlWidget(widget.body),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.scrollHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _isAtBottom ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.acknowledgeLabel),
        ),
      ],
    );
  }
}
