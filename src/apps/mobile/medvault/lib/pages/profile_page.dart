import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/di/service_locator.dart';
import '../core/env/app_environment.dart';
import '../l10n/app_localizations.dart';
import '../models/api_models.dart';
import '../models/gender.dart';
import '../models/profile_models.dart';
import '../services/api/auth_api.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/medvault_page_header.dart';
import 'medical_information_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isEditing = false;

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dateOfBirthCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  Gender? _selectedGender;

  final _newContactNameCtrl = TextEditingController();
  final _newContactPhoneCtrl = TextEditingController();
  final _newContactEmailCtrl = TextEditingController();

  DateTime _lastUpdated = DateTime(2026, 3, 10);
  List<EmergencyContact> _emergencyContacts = [];
  final ImagePicker _imagePicker = ImagePicker();
  String? _localProfileImagePath;

  bool get _isDemo =>
      ServiceLocator.instance.environment == AppEnvironment.demo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _dateOfBirthCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _newContactNameCtrl.dispose();
    _newContactPhoneCtrl.dispose();
    _newContactEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileData = await ServiceLocator.instance.profileService
          .loadProfileData();

      setState(() {
        _profile = profileData.profile;
        _populateFromProfile(profileData.profile);
        _emergencyContacts = profileData.emergencyContacts;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
        () => _error =
            AppLocalizations.of(context)?.profileLoadFailed ??
            'Failed to load profile',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFromProfile(UserProfile profile) {
    final fullName = [profile.firstName, profile.lastName]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(' ')
        .trim();
    _fullNameCtrl.text = fullName.isNotEmpty
        ? fullName
        : (profile.displayName?.trim().isNotEmpty == true
                  ? profile.displayName!.trim()
                  : '')
              .trim();

    if (_fullNameCtrl.text.isEmpty) {
      _fullNameCtrl.text =
          AppLocalizations.of(context)?.unknownUser ?? 'Unknown User';
    }
    _emailCtrl.text = profile.email;
    _dateOfBirthCtrl.text = _formatDateInput(profile.dateOfBirth);
    _selectedGender = profile.gender;
    _phoneCtrl.text = profile.phoneNumber ?? '';
    _addressCtrl.text = _formatAddress(profile);
  }

  String? get _currentStorageUserId {
    final profileEmail = _profile?.email.trim();
    if (profileEmail != null && profileEmail.isNotEmpty) {
      return profileEmail;
    }

    final typedEmail = _emailCtrl.text.trim();
    if (typedEmail.isNotEmpty) {
      return typedEmail;
    }

    return null;
  }

  String _formatDateInput(String? rawIsoDate) {
    if (rawIsoDate == null || rawIsoDate.trim().isEmpty) {
      return '';
    }

    final parsed = _parseDateInput(rawIsoDate);
    if (parsed == null) {
      return rawIsoDate;
    }

    return _localizedDateInputFormat().format(parsed);
  }

  DateFormat _localizedDateInputFormat() {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat.yMd(localeName);
  }

  DateTime? _parseDateInput(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return null;
    }

    final trimmedDate = rawDate.trim();
    final isoDate = DateTime.tryParse(trimmedDate);
    if (isoDate != null) {
      return isoDate;
    }

    final dateFormats = [
      _localizedDateInputFormat(),
      DateFormat.yMd(),
      DateFormat('dd/MM/yyyy'),
    ];

    for (final dateFormat in dateFormats) {
      try {
        return dateFormat.parseStrict(trimmedDate);
      } catch (_) {
      }
    }

    return null;
  }

  String _serializeDateForApi(String rawDate) {
    final trimmedDate = rawDate.trim();
    if (trimmedDate.isEmpty) {
      return trimmedDate;
    }

    final parsedDate = _parseDateInput(trimmedDate);
    if (parsedDate == null) {
      return trimmedDate;
    }

    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final parsedDateOfBirth = _parseDateInput(_dateOfBirthCtrl.text);
    final initialDate =
        parsedDateOfBirth != null &&
            !parsedDateOfBirth.isAfter(now) &&
            parsedDateOfBirth.year >= 1900
        ? parsedDateOfBirth
        : DateTime(now.year - 18, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText:
          AppLocalizations.of(context)?.authDateOfBirth ?? 'Date of Birth',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _dateOfBirthCtrl.text = _localizedDateInputFormat().format(selectedDate);
    });
  }

  String _formatAddress(UserProfile profile) {
    final parts = [
      profile.addressLine1,
      profile.city,
      profile.state,
      profile.postalCode,
    ].where((part) => part != null && part.trim().isNotEmpty).toList();

    return parts.join(', ');
  }

  String _formatLastUpdated(AppLocalizations? t) {
    final locale = t?.localeName;
    final formattedDate = locale == null
        ? DateFormat.yMMMMd().format(_lastUpdated)
        : DateFormat.yMMMMd(locale).format(_lastUpdated);

    return t?.lastUpdatedOn(formattedDate) ?? 'Last updated: $formattedDate';
  }

  String _initials(String fullName) {
    final parts = fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _saveProfile() async {
    if (_profile == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final names = _fullNameCtrl.text.trim().split(RegExp(r'\s+'));
      final firstName = names.isNotEmpty ? names.first : '';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final request = UpdateProfileRequest(
        displayName: _fullNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: _serializeDateForApi(_dateOfBirthCtrl.text),
        gender: _selectedGender,
        phoneNumber: _phoneCtrl.text.trim(),
        addressLine1: _addressCtrl.text.trim(),
        profilePictureUrl: _profile?.profilePictureUrl,
      );

      final updated = await ServiceLocator.instance.profileService
          .updateUserProfile(request);

      await ServiceLocator.instance.profileService.replaceEmergencyContacts(
        userId: updated.email,
        contacts: _emergencyContacts,
      );
      final persistedContacts = await ServiceLocator.instance.profileService
          .getEmergencyContacts(userId: updated.email);

      setState(() {
        _profile = updated;
        _emergencyContacts = persistedContacts;
        _lastUpdated = DateTime.now();
        _isEditing = false;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDemo
                ? (AppLocalizations.of(context)?.demoProfileUpdatedLocally ??
                      'Demo profile updated locally')
                : (AppLocalizations.of(context)?.profileUpdatedSuccessfully ??
                      'Profile updated successfully'),
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
        () => _error =
            AppLocalizations.of(context)?.profileSaveFailed ??
            'Failed to save profile',
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _cancelEditing() {
    final profile = _profile;
    if (profile != null) {
      _populateFromProfile(profile);
    }

    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _setPrimaryContact(String id) async {
    final userId = _currentStorageUserId;
    if (userId == null) {
      return;
    }

    await ServiceLocator.instance.profileService.setPrimaryEmergencyContact(
      userId: userId,
      contactId: id,
    );
    final contacts = await ServiceLocator.instance.profileService
        .getEmergencyContacts(userId: userId);

    if (!mounted) {
      return;
    }

    setState(() {
      _emergencyContacts = contacts;
    });
  }

  Future<void> _deleteContact(String id) async {
    final userId = _currentStorageUserId;
    if (userId == null) {
      return;
    }

    await ServiceLocator.instance.profileService.removeEmergencyContact(
      userId: userId,
      contactId: id,
    );
    final contacts = await ServiceLocator.instance.profileService
        .getEmergencyContacts(userId: userId);

    if (!mounted) {
      return;
    }

    setState(() {
      _emergencyContacts = contacts;
    });
  }

  Future<void> _openAddContactDialog() async {
    _newContactNameCtrl.clear();
    _newContactPhoneCtrl.clear();
    _newContactEmailCtrl.clear();

    final formKey = GlobalKey<FormState>();
    EmergencyContactRelationship? selectedRelationship;

    final added = await showDialog<EmergencyContact>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final t = AppLocalizations.of(context);

          return CustomDialog(
            title: t?.addEmergencyContact ?? 'Add Emergency Contact',
            subtitle:
                t?.addEmergencyContactSubtitle ??
                'Enter the details of the emergency contact you want to add.',
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddContactDialogField(
                    label: t?.name ?? 'Name',
                    localizations: t,
                    controller: _newContactNameCtrl,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t?.relationship ?? 'Relationship',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<EmergencyContactRelationship>(
                    initialValue: selectedRelationship,
                    items: EmergencyContactRelationship.values
                        .map(
                          (option) =>
                              DropdownMenuItem<EmergencyContactRelationship>(
                                value: option,
                                child: Text(option.localizedLabel(t)),
                              ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRelationship = value;
                      });
                    },
                    decoration: _addContactDialogInputDecoration(),
                    hint: Text(
                      t?.relationshipSelectHint ?? 'Select relationship',
                    ),
                    validator: (value) {
                      if (value == null) {
                        return t?.relationshipRequired ??
                            'Relationship is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAddContactDialogField(
                    label: t?.authPhoneNumber ?? 'Phone Number',
                    localizations: t,
                    controller: _newContactPhoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildAddContactDialogField(
                    label: t?.email ?? 'Email',
                    localizations: t,
                    controller: _newContactEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    isEmail: true,
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final isValid =
                            formKey.currentState?.validate() ?? false;
                        if (!isValid || selectedRelationship == null) {
                          return;
                        }

                        Navigator.of(context).pop(
                          EmergencyContact(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: _newContactNameCtrl.text.trim(),
                            relationship: selectedRelationship!,
                            phone: _newContactPhoneCtrl.text.trim(),
                            email: _newContactEmailCtrl.text.trim().isEmpty
                                ? null
                                : _newContactEmailCtrl.text.trim(),
                            isPrimary: _emergencyContacts.isEmpty,
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(t?.addContact ?? 'Add Contact'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (added == null) {
      return;
    }

    final userId = _currentStorageUserId;
    if (userId == null) {
      return;
    }

    await ServiceLocator.instance.profileService.addEmergencyContact(
      userId: userId,
      contact: added,
    );
    final contacts = await ServiceLocator.instance.profileService
        .getEmergencyContacts(userId: userId);

    if (!mounted) {
      return;
    }

    setState(() {
      _emergencyContacts = contacts;
    });
  }

  InputDecoration _addContactDialogInputDecoration() {
    final theme = Theme.of(context);

    return InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildAddContactDialogField({
    required String label,
    required AppLocalizations? localizations,
    required TextEditingController controller,
    required TextInputType keyboardType,
    bool isEmail = false,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _addContactDialogInputDecoration(),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (isRequired && text.isEmpty) {
              return localizations?.fieldRequired(label) ??
                  '$label is required';
            }

            if (isEmail && text.isNotEmpty) {
              final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailPattern.hasMatch(text)) {
                return localizations?.enterValidEmailAddress ??
                    'Enter a valid email address';
              }
            }

            return null;
          },
        ),
      ],
    );
  }

  Future<void> _pickProfileImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(context)?.camera ?? 'Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                AppLocalizations.of(context)?.selectFromFiles ??
                    'Select from files',
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (file == null) {
      return;
    }

    setState(() {
      _localProfileImagePath = file.path;
      _lastUpdated = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(child: LoadingSpinner(semanticLabel: t?.loadingInProgress));
    }

    if (_error != null && _profile == null) {
      final t = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadProfile,
              child: Text(t?.retry ?? 'Retry'),
            ),
          ],
        ),
      );
    }

    final fullName = _fullNameCtrl.text.trim().isEmpty
        ? (t?.unknownUser ?? 'Unknown User')
        : _fullNameCtrl.text.trim();

    final editTooltip = t?.edit ?? 'Edit';
    final cancelTooltip = t?.cancel ?? 'Cancel';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          MedVaultPageHeader(
            title: t?.profile ?? 'Profile',
            leading: IconButton(
              key: const Key('profile_header_edit_button'),
              tooltip: _isEditing ? cancelTooltip : editTooltip,
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_isEditing) {
                        _cancelEditing();
                        return;
                      }

                      setState(() => _isEditing = true);
                    },
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit_outlined,
                color: Colors.white,
              ),
            ),
            trailing: _isEditing
                ? IconButton(
                    tooltip: t?.save ?? 'Save',
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: LoadingSpinner(
                              size: 18,
                              strokeWidth: 2,
                              color: Colors.white,
                              semanticLabel: t?.loadingInProgress,
                            ),
                          )
                        : const Icon(Icons.save_outlined, color: Colors.white),
                  )
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(fullName, t),
                  const SizedBox(height: 14),
                  _buildQuickActions(t),
                  const SizedBox(height: 14),
                  _buildPersonalInformationCard(t),
                  const SizedBox(height: 14),
                  _buildEmergencyContactsCard(t),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String fullName, AppLocalizations? t) {
    final theme = Theme.of(context);
    final profilePhotoUrl = _profile?.profilePictureUrl;
    final imageProvider = _localProfileImagePath != null
        ? FileImage(File(_localProfileImagePath!)) as ImageProvider
        : (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
              ? NetworkImage(profilePhotoUrl)
              : null);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Text(
                            _initials(fullName),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _emailCtrl.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                _formatLastUpdated(t),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations? t) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicalInformationPage(),
                ),
              );
            },
            label: Text(t?.medicalInfo ?? 'Medical Info'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
            icon: const Icon(Icons.settings_outlined),
            label: Text(t?.settings ?? 'Settings'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInformationCard(AppLocalizations? t) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t?.personalInformation ?? 'Personal Information',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _profileField(
              label: t?.fullName ?? 'Full Name',
              controller: _fullNameCtrl,
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
            ),
            _profileField(
              label: t?.email ?? 'Email',
              controller: _emailCtrl,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            _profileField(
              label: t?.authDateOfBirth ?? 'Date of Birth',
              controller: _dateOfBirthCtrl,
              icon: Icons.calendar_month_outlined,
              keyboardType: TextInputType.datetime,
              onTap: _pickDateOfBirth,
              readOnly: true,
            ),
            _genderField(t),
            _profileField(
              label: t?.authPhoneNumber ?? 'Phone Number',
              controller: _phoneCtrl,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _profileField(
              label: t?.address ?? 'Address',
              controller: _addressCtrl,
              icon: Icons.location_on_outlined,
              keyboardType: TextInputType.streetAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactsCard(AppLocalizations? t) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t?.emergencyContacts ?? 'Emergency Contacts',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _openAddContactDialog,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(t?.add ?? 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_emergencyContacts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  t?.noEmergencyContactsYet ??
                      'No emergency contacts added yet.',
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else
              ..._emergencyContacts.map(
                (contact) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    contact.name,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (contact.isPrimary) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      t?.primary ?? 'Primary',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteContact(contact.id),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFF43F5E),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        contact.relationship.localizedLabel(t),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            contact.phone,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (contact.email != null &&
                          contact.email!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              contact.email!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!contact.isPrimary) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _setPrimaryContact(contact.id),
                            child: Text(t?.setAsPrimary ?? 'Set as Primary'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
    bool showTrailingAction = false,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              onTap: onTap,
              readOnly: readOnly,
              showCursor: !readOnly,
              enableInteractiveSelection: !readOnly,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: onTap == null
                    ? null
                    : const Icon(Icons.calendar_month_outlined),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.text,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (showTrailingAction)
                    Icon(
                      Icons.visibility_off_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _genderField(AppLocalizations? t) {
    final theme = Theme.of(context);

    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<Gender>(
          initialValue: _selectedGender,
          items: Gender.values
              .map(
                (gender) => DropdownMenuItem<Gender>(
                  value: gender,
                  child: Text(_genderLabel(gender, t)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
          decoration: InputDecoration(
            labelText: t?.authGender ?? 'Gender',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t?.authGender ?? 'Gender',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wc_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _genderLabel(_selectedGender, t),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _genderLabel(Gender? gender, AppLocalizations? t) {
    switch (gender) {
      case Gender.male:
        return t?.authGenderMale ?? 'Male';
      case Gender.female:
        return t?.authGenderFemale ?? 'Female';
      case Gender.other:
        return t?.authGenderOther ?? 'Other';
      case Gender.preferNotToSay:
        return t?.authGenderPreferNotToSay ?? 'Prefer not to say';
      case null:
        return '-';
    }
  }
}

extension EmergencyContactRelationshipLocalization
    on EmergencyContactRelationship {
  String localizedLabel(AppLocalizations? t) {
    switch (this) {
      case EmergencyContactRelationship.spouse:
        return t?.relationshipSpouse ?? 'Spouse';
      case EmergencyContactRelationship.parent:
        return t?.relationshipParent ?? 'Parent';
      case EmergencyContactRelationship.sibling:
        return t?.relationshipSibling ?? 'Sibling';
      case EmergencyContactRelationship.child:
        return t?.relationshipChild ?? 'Child';
      case EmergencyContactRelationship.partner:
        return t?.relationshipPartner ?? 'Partner';
      case EmergencyContactRelationship.friend:
        return t?.relationshipFriend ?? 'Friend';
      case EmergencyContactRelationship.caregiver:
        return t?.relationshipCaregiver ?? 'Caregiver';
      case EmergencyContactRelationship.other:
        return t?.relationshipOther ?? 'Other';
    }
  }
}
