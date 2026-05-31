// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MedVault';

  @override
  String get welcome => 'Welcome to MedVault';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get contacts => 'Contacts';

  @override
  String get settings => 'Settings';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get continueWithoutSignIn => 'Continue without sign-in';

  @override
  String get error => 'An error occurred';

  @override
  String get loadingInProgress => 'Loading, please wait';

  @override
  String get useBiometric => 'Use biometric authentication';

  @override
  String get authenticationRequired => 'Authentication required';

  @override
  String get authenticate => 'Authenticate';

  @override
  String get authenticateToOpenContacts => 'Authenticate to open contacts';

  @override
  String get confirmDisableBiometric =>
      'Confirm disabling biometric authentication';

  @override
  String get signOut => 'Sign Out';

  @override
  String comingSoon(Object feature) {
    return '$feature is coming soon';
  }

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get changePassword => 'Change Password';

  @override
  String get securityAndPrivacy => 'Security & Privacy';

  @override
  String get activityLog => 'Activity Log';

  @override
  String get accessManagement => 'Access Management';

  @override
  String get notificationsSectionTitle => 'Notifications';

  @override
  String get legalAndSupport => 'Legal & Support';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteAllDataDialogTitle =>
      'Delete all your local data permanently?';

  @override
  String get deleteAllDataDialogMessage =>
      'This action cannot be undone. All locally stored medical records, settings, and cached files will be deleted permanently and cannot be restored.';

  @override
  String get deleteAllDataConfirmAction => 'Delete Permanently';

  @override
  String get deleteAllDataDeleting => 'Deleting...';

  @override
  String get deleteAllDataSuccess =>
      'All local data has been deleted permanently.';

  @override
  String get deleteAllDataError =>
      'We could not delete your data. Please try again.';

  @override
  String get medVaultVersionMvp => 'MedVault v1.0.0 MVP';

  @override
  String get copyrightCompliance => '© 2026 MedVault. HIPAA & GDPR Compliant.';

  @override
  String get profileLoadFailed => 'Failed to load profile';

  @override
  String get demoProfileUpdatedLocally => 'Demo profile updated locally';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get profileSaveFailed => 'Failed to save profile';

  @override
  String get addEmergencyContact => 'Add Emergency Contact';

  @override
  String get addEmergencyContactSubtitle =>
      'Enter the details of the emergency contact you want to add.';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Retry';

  @override
  String get camera => 'Camera';

  @override
  String get selectFromFiles => 'Select from files';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get emergencyContact => 'Emergency Contact';

  @override
  String get fullName => 'Full Name';

  @override
  String get address => 'Address';

  @override
  String lastUpdatedOn(Object date) {
    return 'Last updated: $date';
  }

  @override
  String fieldRequired(Object field) {
    return '$field is required';
  }

  @override
  String get enterValidEmailAddress => 'Enter a valid email address';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get noEmergencyContactsYet => 'No emergency contacts added yet.';

  @override
  String get primary => 'Primary';

  @override
  String get setAsPrimary => 'Set as Primary';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get addContact => 'Add Contact';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get relationship => 'Relationship';

  @override
  String get relationshipSelectHint => 'Select relationship';

  @override
  String get relationshipRequired => 'Relationship is required';

  @override
  String get relationshipSpouse => 'Spouse';

  @override
  String get relationshipParent => 'Parent';

  @override
  String get relationshipSibling => 'Sibling';

  @override
  String get relationshipChild => 'Child';

  @override
  String get relationshipPartner => 'Partner';

  @override
  String get relationshipFriend => 'Friend';

  @override
  String get relationshipCaregiver => 'Caregiver';

  @override
  String get relationshipOther => 'Other';

  @override
  String get phone => 'Phone';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get medicalInformation => 'Medical Information';

  @override
  String get yourCompleteHealthProfile => 'Your complete health profile';

  @override
  String get home => 'Home';

  @override
  String get allergies => 'Allergies';

  @override
  String get medications => 'Medications';

  @override
  String get vaccinations => 'Vaccinations';

  @override
  String get diagnoses => 'Diagnoses';

  @override
  String get labResults => 'Lab Results';

  @override
  String get quickSummary => 'Quick Summary';

  @override
  String get bloodType => 'Blood Type';

  @override
  String get criticialInformation => 'Critical Information';

  @override
  String get recentUpdates => 'Recent Updates';

  @override
  String get addAllergy => 'Add Allergy';

  @override
  String get allergiesRecorded => 'allergies recorded';

  @override
  String get allergyName => 'Allergy Name';

  @override
  String get description => 'Description';

  @override
  String get severity => 'Severity';

  @override
  String get critical => 'Critical';

  @override
  String get markAsCritical => 'Mark as Critical';

  @override
  String get notes => 'Notes';

  @override
  String get deleteAllergy => 'Delete Allergy?';

  @override
  String get areYouSureDelete => 'Are you sure you want to delete';

  @override
  String get delete => 'Delete';

  @override
  String get allergyAddedSuccessfully => 'Allergy added successfully';

  @override
  String get allergyDeletedSuccessfully => 'Allergy deleted successfully';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get medicationCount => 'medications';

  @override
  String get medicationName => 'Medication Name';

  @override
  String get dosage => 'Dosage';

  @override
  String get frequency => 'Frequency';

  @override
  String get egOnceDaily => 'e.g., Once daily';

  @override
  String get reasonForMedication => 'Reason for medication';

  @override
  String get medicationAddedSuccessfully => 'Medication added successfully';

  @override
  String get medicationDeletedSuccessfully => 'Medication deleted successfully';

  @override
  String get addVaccination => 'Add Vaccination';

  @override
  String get vaccinationCount => 'vaccinations';

  @override
  String get vaccineName => 'Vaccine Name';

  @override
  String get selectDate => 'Select Date';

  @override
  String get provider => 'Provider';

  @override
  String get batchNumber => 'Batch Number';

  @override
  String get vaccinationAddedSuccessfully => 'Vaccination added successfully';

  @override
  String get vaccinationDeletedSuccessfully =>
      'Vaccination deleted successfully';

  @override
  String get addDiagnosis => 'Add Diagnosis';

  @override
  String get diagnosesRecorded => 'diagnoses recorded';

  @override
  String get diagnosisName => 'Diagnosis Name';

  @override
  String get status => 'Status';

  @override
  String get treatmentPlan => 'Treatment Plan';

  @override
  String get diagnosisAddedSuccessfully => 'Diagnosis added successfully';

  @override
  String get diagnosisDeletedSuccessfully => 'Diagnosis deleted successfully';

  @override
  String get addLabResult => 'Add Result';

  @override
  String get labResultsAvailable => 'results available';

  @override
  String get testName => 'Test Name';

  @override
  String get category => 'Category';

  @override
  String get doctorInterpretation => 'Doctor\'s Interpretation';

  @override
  String get labResultAddedSuccessfully => 'Lab result added successfully';

  @override
  String get labResultDeletedSuccessfully => 'Lab result deleted successfully';

  @override
  String get normal => 'Normal';

  @override
  String get abnormal => 'Abnormal';

  @override
  String get pending => 'Pending';

  @override
  String get completedBloodCount => 'Complete Blood Count';

  @override
  String get covidBooster => 'COVID-19 Booster';

  @override
  String get added => 'Added';

  @override
  String get received => 'Received';

  @override
  String get penicillin => 'Penicillin';

  @override
  String get severeAllergicReaction => 'Severe allergic reaction';

  @override
  String get peanuts => 'Peanuts';

  @override
  String get mildRash => 'Mild rash';

  @override
  String get lisinopril => 'Lisinopril';

  @override
  String get metformin => 'Metformin';

  @override
  String get flueShot => 'Flu Shot';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get noDescription => 'No description';

  @override
  String get areYouSureYouWantToDelete => 'Are you sure you want to delete';

  @override
  String get active => 'Active';

  @override
  String get chronic => 'Chronic';

  @override
  String get resolved => 'Resolved';

  @override
  String get expired => 'Expired';

  @override
  String get condition => 'Condition';

  @override
  String get diagnosedBy => 'Diagnosed by';

  @override
  String get date => 'Date';

  @override
  String get deleteDiagnosis => 'Delete Diagnosis?';

  @override
  String get lab => 'Lab';

  @override
  String get testDate => 'Test Date';

  @override
  String get medicationsRecorded => 'medications recorded';

  @override
  String get reason => 'Reason';

  @override
  String get prescribedBy => 'Prescribed by';

  @override
  String get deleteMedication => 'Delete Medication?';

  @override
  String get vaccinationsRecorded => 'vaccinations recorded';

  @override
  String get nextDue => 'Next due';

  @override
  String get deleteVaccination => 'Delete Vaccination?';

  @override
  String get labResultsRecorded => 'lab results recorded';

  @override
  String get editBloodType => 'Edit Blood Type';

  @override
  String get authSignInFailed => 'Sign-in failed';

  @override
  String get authEmailSignInFailed => 'Email sign-in failed';

  @override
  String get authEmailRegistrationFailed => 'Email registration failed';

  @override
  String get authCreateAccountWithEmail => 'Create account with Email';

  @override
  String get authSignInWithEmail => 'Sign in with Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authFirstName => 'First name';

  @override
  String get authLastName => 'Last name';

  @override
  String get authAcceptTermsOfService => 'I accept Terms of Service';

  @override
  String get authAcceptPrivacyPolicy => 'I accept Privacy Policy';

  @override
  String get authRegister => 'Register';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSecureMedicalRecordsVault =>
      'Your secure medical records vault';

  @override
  String get authHipaaGdprCompliant => 'HIPAA & GDPR Compliant';

  @override
  String get authDataEncryptedSecure => 'Your data is encrypted and secure';

  @override
  String get authEndToEndEncryption => 'End-to-End Encryption';

  @override
  String get authOnlyYouControlRecords =>
      'Only you control access to your records';

  @override
  String get authSigningInDemo => 'Signing in to demo...';

  @override
  String get authSigningIn => 'Signing in...';

  @override
  String get authContinueWithDemoGoogle => 'Continue with Demo Google';

  @override
  String get authDateOfBirthRequired => 'Date of birth is required.';

  @override
  String get authAcceptTermsPrivacyRequired =>
      'Please accept the terms and privacy policy.';

  @override
  String get authPolicyAcknowledge => 'I have read and understand';

  @override
  String get authPolicyScrollHint =>
      'Scroll to the bottom to enable acknowledgment.';

  @override
  String get authRegistrationFailedTryAgain =>
      'Registration failed. Please try again.';

  @override
  String get authRegistrationCompletedSuccessfully =>
      'Registration completed successfully.';

  @override
  String get authCompleteRegistration => 'Complete Registration';

  @override
  String get authRequiredField => 'Required';

  @override
  String get authDateOfBirth => 'Date of Birth';

  @override
  String get authGender => 'Gender';

  @override
  String get authGenderMale => 'Male';

  @override
  String get authGenderFemale => 'Female';

  @override
  String get authGenderOther => 'Other';

  @override
  String get authGenderPreferNotToSay => 'Prefer not to say';

  @override
  String get authPhoneNumber => 'Phone Number';

  @override
  String get onboardingErrorGeneric =>
      'Something went wrong. Please try again.';

  @override
  String get onboardingStepBiometricTitle => 'Enable Biometric Authentication';

  @override
  String get onboardingStepNotificationsTitle => 'Notification Preferences';

  @override
  String get onboardingStepCloudTitle => 'Cloud Backup';

  @override
  String get onboardingStepMedicalTitle => 'Medical Information';

  @override
  String get onboardingStepBiometricSubtitle =>
      'Use fingerprint or face recognition to secure your health data.';

  @override
  String get onboardingStepNotificationsSubtitle =>
      'Stay informed about access to your medical records';

  @override
  String get onboardingStepCloudSubtitle => 'Keep your data safe';

  @override
  String get onboardingStepMedicalSubtitle => 'Basic health profile';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingBiometricDescription =>
      'Secure your health data with biometric authentication.';

  @override
  String get onboardingEnableBiometricLock => 'Biometric Login';

  @override
  String get onboardingBiometricEnabled => 'Enabled';

  @override
  String get onboardingBiometricDisabled => 'Disabled';

  @override
  String get onboardingBiometricFaster => 'Faster and more secure';

  @override
  String get onboardingBiometricCheck1 =>
      'Your biometric data never leaves your device';

  @override
  String get onboardingBiometricCheck2 => 'Add an extra layer of security';

  @override
  String get onboardingBiometricCheck3 =>
      'You can change this anytime in settings';

  @override
  String get onboardingBiometricType => 'Biometric Type';

  @override
  String get onboardingBiometricFingerprint => 'Fingerprint';

  @override
  String get onboardingBiometricFace => 'Face Recognition';

  @override
  String get onboardingBiometricIris => 'Iris Scan';

  @override
  String get biometricUnavailableTitle => 'Biometric login unavailable';

  @override
  String get biometricUnavailableNoHardware =>
      'This device does not support biometric authentication.';

  @override
  String get biometricUnavailableNotEnrolled =>
      'No biometric data is enrolled on this device.';

  @override
  String get biometricUnavailableUnknown =>
      'Biometric availability could not be verified on this device.';

  @override
  String get onboardingNotificationsDescription =>
      'Choose which notifications you would like to receive.';

  @override
  String get onboardingPushNotifications => 'Push Notifications';

  @override
  String get onboardingPushNotificationsSubtext =>
      'Get notified about access events';

  @override
  String get onboardingNotifyWhen => 'You\'ll be notified when:';

  @override
  String get onboardingNotifyReasonQR =>
      'Someone accesses your emergency QR code';

  @override
  String get onboardingNotifyReasonShared =>
      'A provider views your shared records';

  @override
  String get onboardingNotifyReasonSecurity =>
      'Important security events occur';

  @override
  String get onboardingEmailNotifications => 'Email Notifications';

  @override
  String get onboardingMedicalReminders => 'Medical Reminders';

  @override
  String get onboardingAppointmentAlerts => 'Appointment Alerts';

  @override
  String get onboardingSecurityAlerts => 'Security Alerts';

  @override
  String get onboardingCloudDescription =>
      'Back up your health records to the cloud.';

  @override
  String get onboardingBackupProvider => 'Backup Provider';

  @override
  String get onboardingProviderMedVault => 'MedVault Cloud';

  @override
  String get onboardingProviderGoogleDrive => 'Google Drive';

  @override
  String get onboardingProviderICloud => 'iCloud';

  @override
  String get onboardingAutoBackup => 'Auto-backup';

  @override
  String get onboardingAutoBackupSubtitle => 'Automatically back up changes';

  @override
  String get onboardingMedicalInfoDescription =>
      'Provide basic medical information. You can add more details later.';

  @override
  String get onboardingSubstance => 'Substance';

  @override
  String get onboardingUnknown => 'Unknown';

  @override
  String get onboardingOnceDaily => 'Once daily';

  @override
  String get emergencyAccess => 'Emergency Access';

  @override
  String get shareCriticalInfoInstantly => 'Share critical info instantly';

  @override
  String get emergencySharingDisabledInSettings =>
      'Emergency sharing is disabled in settings.';

  @override
  String get medicalInfo => 'Medical Info';

  @override
  String get viewAll => 'View All';

  @override
  String get meds => 'Meds';

  @override
  String get vaccines => 'Vaccines';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get account => 'Account';

  @override
  String get profile => 'Profile';

  @override
  String get dashboardSubtitle => 'Your Health Dashboard';

  @override
  String get criticalAllergy => 'Critical Allergy';

  @override
  String get noCriticalAllergies => 'No critical allergies';

  @override
  String get totalTests => 'Total Tests';

  @override
  String get flagged => 'Flagged';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get yourDataIsSecure => 'Your data is secure';

  @override
  String get dashboardSecurityDescription =>
      'All records are encrypted end-to-end. Only you control access.';

  @override
  String get documents => 'Documents';

  @override
  String get share => 'Share';

  @override
  String get alerts => 'Alerts';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get addNewDocument => 'Add New Document';

  @override
  String get addNewLabResult => 'Add New Lab Result';

  @override
  String get documentCreatedSuccessfully => 'Document created successfully';

  @override
  String get documentsUpdatedSuccessfully => 'Document updated successfully';

  @override
  String get documentsDeletedSuccessfully => 'Document deleted successfully';

  @override
  String get documentsSearchPlaceholder => 'Search documents';

  @override
  String get documentsEmptyTitle => 'No documents yet';

  @override
  String get documentsEmptySubtitle =>
      'Upload your first medical document to get started.';

  @override
  String get documentsSelectSourceTitle => 'Select document source';

  @override
  String get documentsFromGallery => 'Gallery';

  @override
  String get documentsUploadFailed => 'Failed to upload file';

  @override
  String get documentsSaveFailed => 'Failed to save document';

  @override
  String get documentsDeleteDialogTitle => 'Delete document?';

  @override
  String documentsDeleteDialogMessage(String title) {
    return 'Are you sure you want to delete $title?';
  }

  @override
  String get documentsOpenWithApp => 'Open with app';

  @override
  String get documentsOpenFailed => 'Failed to open document';

  @override
  String get documentsShareFailed => 'Failed to share document';

  @override
  String get documentsAddDetailsTitle => 'Document details';

  @override
  String get documentsEditDetailsTitle => 'Edit document details';

  @override
  String get documentsNoDateSelected => 'No date selected';

  @override
  String get documentsExtractDataButton => 'Extract Data';

  @override
  String get documentsSaveBeforeExtraction =>
      'Save the document first before extracting data';

  @override
  String get documentsExtractionUnavailableInDemo =>
      'Extract Data is not available in demo mode yet';

  @override
  String get documentsExtractionNotReady =>
      'Document extraction is not connected yet';

  @override
  String get documentsExtractionFailed => 'Failed to extract document data';

  @override
  String get documentsAtLeastOneFileRequired => 'At least one file is required';

  @override
  String get documentsAddFileButton => 'Add files';

  @override
  String get documentsRemoveSelectedFileButton => 'Remove selected file';

  @override
  String documentsFilesCount(int count) {
    return '$count files';
  }

  @override
  String documentsMaxFilesSelectionLimit(int maxFiles) {
    return 'You can select up to $maxFiles files per document.';
  }

  @override
  String documentsMaxFilesReached(int maxFiles) {
    return 'This document already has the maximum of $maxFiles files.';
  }

  @override
  String documentsMaxFilesRemaining(int availableSlots, int maxFiles) {
    return 'You can only add $availableSlots more files. Maximum: $maxFiles per document.';
  }

  @override
  String get documentsCategoryLabel => 'Category';

  @override
  String get documentsTagsLabel => 'Tags';

  @override
  String get documentsTagsHint => 'Type a tag and tap +';

  @override
  String get documentsTypePdf => 'PDF';

  @override
  String get documentsTypeImage => 'Image';

  @override
  String get documentsTypeDocx => 'DOCX';

  @override
  String get documentsTypeXlsx => 'XLSX';

  @override
  String get documentsTypeOther => 'Other';

  @override
  String get documentsCategoryLabResults => 'Lab Results';

  @override
  String get documentsCategoryMedicalReport => 'Medical Report';

  @override
  String get documentsCategoryMedicationReport => 'Medication Report';

  @override
  String get documentsCategoryVaccinations => 'Vaccinations';

  @override
  String get documentsCategoryOther => 'Other';

  @override
  String get labTestResultCreatedSuccessfully =>
      'Lab test result created successfully';

  @override
  String get noLabResults => 'No lab results yet';

  @override
  String get labResultsAll => 'All';

  @override
  String get searchLabResults => 'Search lab results';

  @override
  String get noMatchingLabResults => 'No matching lab results';

  @override
  String get addLabResultTitle => 'Add Lab Result';

  @override
  String get editLabResultTitle => 'Edit Lab Result';

  @override
  String get labResultDetails => 'Lab Result Details';

  @override
  String get addLabResultType => 'Add Lab Result Type';

  @override
  String get removeLabResultType => 'Remove Lab Result Type';

  @override
  String get removeLabResultTypeConfirmation =>
      'Remove this custom category from your list?';

  @override
  String get deleteLabResultTitle => 'Delete Lab Result?';

  @override
  String deleteLabResultConfirmation(String testName) {
    return 'Are you sure you want to delete $testName?';
  }

  @override
  String get labResultUpdatedSuccessfully => 'Lab result updated successfully';

  @override
  String get labResultTypeRemovedSuccessfully =>
      'Lab result type removed successfully';

  @override
  String get updated => 'Updated';

  @override
  String get attachments => 'Attachments';

  @override
  String get labResultTypeInUseCannotRemove =>
      'This category is already used by a lab result.';

  @override
  String get chooseHowToAddYourLabResults =>
      'Choose how you want to add your lab results.';

  @override
  String get labResultsAddDescription =>
      'You can enter them manually or upload a document for automatic extraction.';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get manualEntryDetails =>
      'Add individual test values\nFull control over data entry\nBest for single results';

  @override
  String get uploadAndExtract => 'Upload & Extract';

  @override
  String get uploadAndExtractDetails =>
      'AI-powered data extraction\nUpload PDF or image files\nFaster for multiple values';

  @override
  String get testInformation => 'Test Information';

  @override
  String get testValues => 'Test Values';

  @override
  String get labValueNameHint => 'Name (e.g., Hemoglobin)';

  @override
  String get yourValue => 'Your Value';

  @override
  String get valueLabel => 'Value';

  @override
  String get unit => 'Unit';

  @override
  String get minimum => 'Min';

  @override
  String get maximum => 'Max';

  @override
  String get interpretationAndNotes => 'Interpretation & Notes';

  @override
  String get uploadLabReport => 'Upload Lab Report';

  @override
  String get selectCategory => 'Select category';

  @override
  String get addValue => 'Add Value';

  @override
  String get referenceRangeOptional => 'Reference Range (Optional)';

  @override
  String get saveResult => 'Save Result';

  @override
  String get labResultTypeCreatedSuccessfully =>
      'Lab result type created successfully';

  @override
  String get labCategoryCompleteBloodCountLabel => 'Complete Blood Count (CBC)';

  @override
  String get labCategoryCompleteBloodCountDescription =>
      'Checks your blood cells.';

  @override
  String get labCategoryMetabolicPanelsLabel => 'Metabolic Panels (BMP or CMP)';

  @override
  String get labCategoryMetabolicPanelsDescription =>
      'Checks organ function and chemistry.';

  @override
  String get labCategoryLipidPanelLabel => 'Lipid Panel';

  @override
  String get labCategoryLipidPanelDescription =>
      'Checks your heart health and fats.';

  @override
  String get labCategoryThyroidPanelLabel => 'Thyroid Panel';

  @override
  String get labCategoryThyroidPanelDescription =>
      'Checks your metabolism regulator.';

  @override
  String get labCategoryDiabetesMonitoringLabel => 'Diabetes Monitoring';

  @override
  String get labCategoryDiabetesMonitoringDescription =>
      'Checks long-term sugar.';

  @override
  String get labCategoryHemoglobinA1cLabel => 'Hemoglobin A1c';

  @override
  String get labCategoryHemoglobinA1cDescription =>
      'Your average blood sugar over the last 3 months.';

  @override
  String get labCategoryUrinalysisLabel => 'Urinalysis';

  @override
  String get labCategoryUrinalysisDescription => 'Checks waste management.';

  @override
  String get labCategoryNutrientLevelsLabel => 'Nutrient Levels';

  @override
  String get labCategoryNutrientLevelsDescription => 'Checks for deficiencies.';

  @override
  String get sharingAndCollaborationTitle => 'Sharing & Collaboration';

  @override
  String get sharingManageDataAccessSubtitle => 'Manage data access';

  @override
  String get sharingEmergencyQrTitle => 'Emergency QR';

  @override
  String get sharingQuickAccessSubtitle => 'Quick access';

  @override
  String get sharingWithPhysicianTitle => 'Share with Physician';

  @override
  String get sharingWithPhysicianSubtitle => 'Secure provider access';

  @override
  String get sharingSecureSharingSubtitle => 'Secure sharing';

  @override
  String get sharingActiveSharesTitle => 'Active Shares';

  @override
  String get sharingNoActiveSharesMessage => 'No active sharing links yet.';

  @override
  String get sharingManageAccessTitle => 'Manage Access';

  @override
  String get sharingAccessManagementLabel => 'Access Management';

  @override
  String get sharingActivityLogLabel => 'Activity Log';

  @override
  String get sharingPrivacyCardTitle => 'Your Control, Your Privacy';

  @override
  String get sharingPrivacyCardDescription =>
      'You maintain full control over who can access your medical records. All access is logged and can be revoked at any time.';

  @override
  String get sharingExpiresLabel => 'Expires';

  @override
  String get sharingEmergencyTypeLabel => 'Emergency';

  @override
  String get sharingPhysicianTypeLabel => 'Physician';

  @override
  String get sharingEmergencySharingTitle => 'Emergency Sharing';

  @override
  String get sharingEmergencySharingSubtitle =>
      'Quick access for first responders';

  @override
  String get sharingEmergencyWarningBody =>
      'Anyone with the code or QR can access selected data. Only share in emergencies. All access is logged and you will be notified.';

  @override
  String get sharingSelectInformationTitle => 'Select Information to Share';

  @override
  String get sharingEmergencySelectInformationSubtitle =>
      'Choose what emergency responders can access';

  @override
  String get sharingCriticalBadge => 'Critical';

  @override
  String get sharingRecommendedBadge => 'Recommended';

  @override
  String get sharingContinueButton => 'Continue';

  @override
  String get sharingEmergencySecurityTitle => 'Security Configuration';

  @override
  String get sharingEmergencySecuritySubtitle =>
      'Configure emergency link duration';

  @override
  String get sharingAccessDurationTitle => 'Access Duration';

  @override
  String get sharingEmergencyDurationQuestion =>
      'How long should the emergency code remain valid?';

  @override
  String get sharingDataSummaryTitle => 'Data Summary';

  @override
  String get sharingDataSummarySubtitle =>
      'Information that will be accessible';

  @override
  String get sharingPrivacySecurityTitle => 'Privacy & Security';

  @override
  String get sharingSecurityBulletLogged => 'All access attempts are logged';

  @override
  String get sharingSecurityBulletNotified =>
      'You will receive instant notifications';

  @override
  String get sharingSecurityBulletRevoke => 'You can revoke access anytime';

  @override
  String get sharingSecurityBulletExpires => 'Code expires automatically';

  @override
  String get sharingGenerateEmergencyCodeButton => 'Generate Emergency Code';

  @override
  String get sharingGeneratingCodeButton => 'Generating code...';

  @override
  String get sharingEmergencyCodeActiveTitle => 'Emergency Code Active';

  @override
  String get sharingEmergencyAccessActiveLabel => 'Emergency access is active';

  @override
  String get sharingExpiresInLabel => 'Expires in';

  @override
  String get sharingScanQrCodeTitle => 'Scan QR Code';

  @override
  String get sharingScanQrCodeSubtitle =>
      'First responders can scan this to access your info';

  @override
  String get sharingUseCodeTitle => 'Or Use Code';

  @override
  String get sharingEmergencyAccessCodeLabel => 'Emergency Access Code';

  @override
  String get sharingVisitAndEnterCodeText => 'Visit:';

  @override
  String get sharingDownloadQrButton => 'Download QR';

  @override
  String get sharingDownloadPngButton => 'Download PNG';

  @override
  String get sharingDownloadJpgButton => 'Download JPG';

  @override
  String sharingQrDownloadedMessage(Object format) {
    return 'QR code downloaded as $format';
  }

  @override
  String get sharingDownloadFailedMessage => 'Failed to download QR code';

  @override
  String get sharingShareButton => 'Share';

  @override
  String get sharingDownloadNotImplementedMessage =>
      'Download action is available in a future update.';

  @override
  String get sharingLinkCopiedMessage => 'Sharing link copied.';

  @override
  String get sharingEmergencyNotificationInfo =>
      'You will be notified every time someone accesses your emergency information.';

  @override
  String get sharingRevokeEmergencyAccessButton => 'Revoke Emergency Access';

  @override
  String get sharingPhysicianInformationTitle => 'Physician Information';

  @override
  String get sharingPhysicianNameLabel => 'Physician Name *';

  @override
  String get sharingPhysicianEmailLabel => 'Email Address (Optional)';

  @override
  String get sharingPhysicianEmailHelpText =>
      'Optional. Add an email to include physician contact in the sharing record.';

  @override
  String get sharingNotesOptionalLabel => 'Notes (Optional)';

  @override
  String get sharingSelectDataToShareTitle => 'Select Data to Share';

  @override
  String get sharingSelectDataToShareSubtitle =>
      'Choose what the physician can access';

  @override
  String get sharingPhysicianValidationMessage =>
      'Please enter a valid physician name. If provided, email must be valid.';

  @override
  String get sharingContinueToSecuritySettingsButton =>
      'Continue to Security Settings';

  @override
  String get sharingSecuritySettingsTitle => 'Security Settings';

  @override
  String get sharingPasswordProtectedLabel => 'Password Protected';

  @override
  String get sharingTwoFactorRequiredLabel => '2FA Approval Required';

  @override
  String get sharingTwoFactorApprovalDescription =>
      'When enabled, access will remain pending until you approve or deny it in the app.';

  @override
  String get sharingAllowDownloadLabel => 'Allow Download';

  @override
  String get sharingPasswordConstraintsHelpText =>
      'Use at least 8 characters with letters and numbers. Share it securely with the physician.';

  @override
  String get sharingReviewAndConfirmTitle => 'Review & Confirm';

  @override
  String get sharingWithLabel => 'Sharing With';

  @override
  String get sharingPatientLabel => 'Patient';

  @override
  String get sharingDataBeingSharedTitle => 'Data Being Shared';

  @override
  String get sharingAccessDurationLabel => 'Access Duration';

  @override
  String get sharingYesLabel => 'Yes';

  @override
  String get sharingNoLabel => 'No';

  @override
  String get sharingConsentStatement =>
      'I confirm that I consent to sharing my medical information and understand that all access will be logged and can be revoked at any time.';

  @override
  String get sharingConfirmAndSendButton => 'Confirm & Send Share Link';

  @override
  String get sharingSendingLinkButton => 'Sending link...';

  @override
  String get sharingConfirmationDialogTitle => 'Confirm Sharing';

  @override
  String get sharingConfirmationDialogMessage =>
      'Create and send the secure sharing link to this physician?';

  @override
  String get sharingConfirmButton => 'Confirm';

  @override
  String get sharingPhysicianEmailSubject =>
      'MedVault secure medical information sharing';

  @override
  String get sharingPhysicianEmailBodyIntro =>
      'Please use this secure MedVault link to review my shared medical information.';

  @override
  String get sharingPhysicianEmailBodyInstructions =>
      'This link is time-limited and intended for secure medical sharing.';

  @override
  String get sharingEmailOpenedMessage => 'Sharing options opened.';

  @override
  String get sharingEmailFallbackCopiedMessage =>
      'Unable to open sharing options. Link copied to clipboard.';

  @override
  String get sharingLinkCreatedDialogTitle => 'Sharing Link Created';

  @override
  String get sharingLinkCreatedDialogMessage =>
      'Your secure link is ready and can now be shared.';

  @override
  String get sharingCopyLinkButton => 'Copy Link';

  @override
  String get sharingDoneButton => 'Done';

  @override
  String get sharingAccessManagementTitle => 'Access Management';

  @override
  String get sharingSummaryActiveLabel => 'Active';

  @override
  String get sharingSummaryUsedLabel => 'Used';

  @override
  String get sharingSummaryExpiredLabel => 'Expired';

  @override
  String get sharingNoAccessGrantsMessage => 'No access grants available.';

  @override
  String get sharingGrantedLabel => 'Granted';

  @override
  String get sharingLastAccessLabel => 'Last';

  @override
  String get sharingNeverLabel => 'Never';

  @override
  String get sharingPermissionsLabel => 'Perms';

  @override
  String get sharingEditButton => 'Edit';

  @override
  String get sharingRevokeAccessButton => 'Revoke Access';

  @override
  String get sharingEditPermissionsTitle => 'Edit Permissions';

  @override
  String get sharingActivityLogTitle => 'Activity Log';

  @override
  String get sharingActivityLogSubtitle => 'Access & security events';

  @override
  String get sharingAllEventsFilter => 'All Events';

  @override
  String get sharingAccessEventsFilter => 'Access Events';

  @override
  String get sharingHighRiskFilter => 'High Risk';

  @override
  String get sharingSummaryAccessLabel => 'Access';

  @override
  String get sharingSummaryHighRiskLabel => 'High Risk';

  @override
  String get sharingSummaryPeriodLabel => 'Period';

  @override
  String get sharingSummaryPeriodValue => '7d';

  @override
  String get sharingActivityTimelineTitle => 'Activity Timeline';

  @override
  String get sharingNoActivityEventsMessage =>
      'No activity events for this filter.';

  @override
  String get sharingExportComplianceTitle => 'Export & Compliance';

  @override
  String get sharingExportActivityPdfButton => 'Export Activity Log (PDF)';

  @override
  String get sharingExportGdprButton => 'GDPR Data Portability Report';

  @override
  String get sharingExportPdfNotReadyMessage =>
      'PDF export will be connected in a future release.';

  @override
  String get sharingGdprExportNotReadyMessage =>
      'GDPR report export will be connected in a future release.';

  @override
  String get sharingScopePersonalInformation => 'Personal Information';

  @override
  String get sharingScopeMedicalInformation => 'Medical Information';

  @override
  String get sharingScopeBloodType => 'Blood Type';

  @override
  String get sharingScopeAllergies => 'Allergies';

  @override
  String get sharingScopeCurrentMedications => 'Current Medications';

  @override
  String get sharingScopeChronicConditions => 'Diagnoses';

  @override
  String get sharingScopeEmergencyContact => 'Emergency Contact';

  @override
  String get sharingScopeLabResults => 'Lab Results';

  @override
  String get sharingScopeMedicalDocuments => 'Medical Documents';

  @override
  String get sharingScopeMedicalHistory => 'Medical History';

  @override
  String get editAllergy => 'Edit Allergy';

  @override
  String get reaction => 'Reaction';

  @override
  String get documentAttachment => 'Document attachment';

  @override
  String get allergyUpdatedSuccessfully => 'Allergy updated successfully';

  @override
  String get editDiagnosis => 'Edit Diagnosis';

  @override
  String get duration => 'Duration';

  @override
  String get diagnosisUpdatedSuccessfully => 'Diagnosis updated successfully';

  @override
  String get editMedication => 'Edit Medication';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get medicationUpdatedSuccessfully => 'Medication updated successfully';

  @override
  String get editVaccination => 'Edit Vaccination';

  @override
  String get doseDates => 'Dose dates';

  @override
  String get noDatesSelected => 'No dates selected.';

  @override
  String get addDate => 'Add date';

  @override
  String get vaccinationUpdatedSuccessfully =>
      'Vaccination updated successfully';

  @override
  String get documentsExtractionDisabledInSettings =>
      'Document extraction is disabled in your settings.';

  @override
  String get sharingAddShareContactButton => 'Add Share Contact';

  @override
  String get sharingLinkCreationDisabledInSettings =>
      'Sharing link creation is disabled in your settings.';

  @override
  String sharingMaxActiveLinksReached(int maxLinks) {
    return 'You have reached the maximum of $maxLinks active sharing links. Revoke one to continue.';
  }

  @override
  String get sharingPhysicianDisabledInSettings =>
      'Physician sharing is disabled in your settings.';

  @override
  String get sharingPreferencesTitle => 'Sharing preferences';

  @override
  String get sharingPreferenceEnabled => 'Enabled';

  @override
  String get sharingPreferenceDisabled => 'Disabled';

  @override
  String sharingPreferencesSummary(
    String emergencyStatus,
    String physicianStatus,
    int maxLinks,
    int activeLinks,
    int maxDocs,
  ) {
    return 'Emergency: $emergencyStatus • Physician: $physicianStatus • Max links: $maxLinks • Active links: $activeLinks • Max docs: $maxDocs';
  }

  @override
  String get sharingManagedByApiConfiguration => 'Managed by API configuration';

  @override
  String get sharingPendingAccessApprovalsTitle => 'Pending access approvals';

  @override
  String get sharingNoPendingRequests => 'No pending requests';

  @override
  String sharingWaitingRequests(int count) {
    return '$count waiting requests';
  }

  @override
  String get sharingDocumentSharingDisabledInSettings =>
      'Document sharing is disabled in your settings.';

  @override
  String sharingSelectedFilesCount(int selected, int max) {
    return 'Selected files: $selected/$max';
  }

  @override
  String get sharingSelectFilesButton => 'Select Files';

  @override
  String get sharingSelectAtLeastOneMedicalDocument =>
      'Select at least one file for Medical Documents sharing.';

  @override
  String get sharingDuration1Hour => '1 hour';

  @override
  String get sharingDuration6Hours => '6 hours';

  @override
  String get sharingDuration12Hours => '12 hours';

  @override
  String get sharingDuration24Hours => '24 hours';

  @override
  String get sharingDuration3Days => '3 days';

  @override
  String get sharingDuration1Day => '1 day';

  @override
  String get sharingDuration7Days => '7 days';

  @override
  String get sharingDuration30Days => '30 days';

  @override
  String get sharingDuration90Days => '90 days';

  @override
  String get sharingEnterAndConfirmPassword =>
      'Enter and confirm the access password.';

  @override
  String get sharingPasswordMinRequirements =>
      'Password must be at least 8 characters long and include letters and numbers.';

  @override
  String get sharingPasswordMismatch =>
      'Password and confirmation do not match.';

  @override
  String get sharingAccessPasswordLabel => 'Access Password';

  @override
  String get sharingConfirmPasswordLabel => 'Confirm Password';

  @override
  String sharingAccessApprovedFor(String name) {
    return 'Access approved for $name.';
  }

  @override
  String sharingAccessDeniedFor(String name) {
    return 'Access denied for $name.';
  }

  @override
  String get sharingUnableToUpdateApprovalRequest =>
      'Unable to update approval request.';

  @override
  String get sharingNoPendingApprovalRequests =>
      'There are no pending approval requests.';

  @override
  String get sharingRequestedLabel => 'Requested';

  @override
  String get sharingIpLabel => 'IP';

  @override
  String get sharingShareCodeLabel => 'Share code';

  @override
  String get sharingApproveButton => 'Approve';

  @override
  String get sharingDenyButton => 'Deny';

  @override
  String get sharingCloseButton => 'Close';

  @override
  String get sharingSelectFilesToShareTitle => 'Select Files to Share';

  @override
  String sharingChooseUpToFilesForLink(int maxFiles) {
    return 'Choose up to $maxFiles files for this link';
  }

  @override
  String get sharingSearchFilesLabel => 'Search files';

  @override
  String get sharingFilterByCategoryLabel => 'Filter by category';

  @override
  String get sharingAllCategories => 'All categories';

  @override
  String sharingSelectedCount(int selected, int max) {
    return 'Selected: $selected/$max';
  }

  @override
  String get sharingNoFilesMatchSearchFilter =>
      'No files match your search/filter.';

  @override
  String get sharingApplySelectionButton => 'Apply Selection';

  @override
  String get sharingLinkCreationDisabledBySystemConfiguration =>
      'Sharing link creation is disabled by system configuration.';

  @override
  String sharingReachedMaxActiveLinksInAccessManagement(int maxLinks) {
    return 'You reached the maximum of $maxLinks active sharing links. Revoke one in Access Management to create a new link.';
  }

  @override
  String get sharingManageButton => 'Manage';

  @override
  String get notificationsPageTitle => 'Notifications';

  @override
  String notificationsUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get notificationsTabAll => 'All';

  @override
  String get notificationsTabUnread => 'Unread';

  @override
  String get notificationsTabSettings => 'Settings';

  @override
  String get notificationsAllEmpty => 'No notifications yet';

  @override
  String get notificationsUnreadEmpty => 'No unread notifications';

  @override
  String get notificationsPushSectionTitle => 'Push Notifications';

  @override
  String get notificationsEmailSectionTitle => 'Email Notifications';

  @override
  String get notificationsSettingAccessAlertsTitle => 'Access Alerts';

  @override
  String get notificationsSettingAccessAlertsDescription =>
      'When someone views your records';

  @override
  String get notificationsSettingShareRequestsTitle => 'Share Requests';

  @override
  String get notificationsSettingShareRequestsDescription =>
      'New provider access requests';

  @override
  String get notificationsSettingSecurityAlertsTitle => 'Security Alerts';

  @override
  String get notificationsSettingSecurityAlertsDescription =>
      'Unauthorized access attempts';

  @override
  String get notificationsSettingRecordUpdatesTitle => 'Record Updates';

  @override
  String get notificationsSettingRecordUpdatesDescription =>
      'Changes to your medical data';

  @override
  String get notificationsSettingDailySummaryTitle => 'Daily Summary';

  @override
  String get notificationsSettingDailySummaryDescription =>
      'Daily activity digest';

  @override
  String get notificationsSettingWeeklyReportTitle => 'Weekly Report';

  @override
  String get notificationsSettingWeeklyReportDescription =>
      'Weekly access summary';

  @override
  String get notificationsTypeEmergencyQrAccessedTitle =>
      'Emergency QR Code Accessed';

  @override
  String get notificationsTypeEmergencyQrAccessedDescription =>
      'Your emergency medical information was accessed';

  @override
  String get notificationsTypeShareRequestTitle => 'New Share Request';

  @override
  String notificationsTypeShareRequestDescription(String actor) {
    return '$actor requested access to your records';
  }

  @override
  String get notificationsTypeProfileUpdatedTitle => 'Profile Updated';

  @override
  String get notificationsTypeProfileUpdatedDescription =>
      'Your medical information was updated';

  @override
  String get notificationsTypeProviderAccessTitle => 'Provider Access';

  @override
  String notificationsTypeProviderAccessDescription(String actor) {
    return '$actor viewed your test results';
  }

  @override
  String get notificationsTypeMedicationReminderTitle => 'Medication Reminder';

  @override
  String get notificationsTypeMedicationReminderDescription =>
      'It is time to take your scheduled medication';

  @override
  String get notificationsTypeAppointmentAlertTitle => 'Appointment Alert';

  @override
  String get notificationsTypeAppointmentAlertDescription =>
      'You have an upcoming medical appointment';

  @override
  String get notificationsTypeSecurityAlertTitle => 'Security Alert';

  @override
  String get notificationsTypeSecurityAlertDescription =>
      'A security-sensitive event was detected';

  @override
  String get notificationsTypeRecordUpdatedTitle => 'Record Updated';

  @override
  String get notificationsTypeRecordUpdatedDescription =>
      'One of your shared records was updated';

  @override
  String get notificationsDetailTitle => 'Notification Details';

  @override
  String get notificationsDetailTypeLabel => 'Type';

  @override
  String get notificationsDetailReceivedAtLabel => 'Received';

  @override
  String get notificationsDetailStatusLabel => 'Status';

  @override
  String get notificationsDetailStatusRead => 'Read';

  @override
  String get notificationsDetailStatusUnread => 'Unread';

  @override
  String get notificationsDetailActorLabel => 'Actor';

  @override
  String get notificationsDetailLanguageLabel => 'Language';

  @override
  String get notificationsDetailDescriptionLabel => 'Details';

  @override
  String get notificationsDetailViewSharingAction => 'View sharing details';

  @override
  String get notificationsDetailRevokeSharingAction => 'Revoke sharing link';

  @override
  String get notificationsDetailCloseAction => 'Close';

  @override
  String get notificationsDetailOpenError =>
      'Unable to open notification details right now.';

  @override
  String get notificationsDetailRevokeUnavailable =>
      'This notification does not include a sharing link to revoke.';

  @override
  String get notificationsDetailRevokeSuccess => 'Sharing link revoked.';

  @override
  String get notificationsDetailRevokeError =>
      'Unable to revoke the sharing link right now.';

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String notificationsMinutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String notificationsHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String notificationsDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get noRecentActivity => 'No recent activity yet';
}
