import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('en'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'MedVault'**
  String get appTitle;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome to MedVault'**
  String get welcome;

  /// Dashboard tab label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Contacts tab label
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// Settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Sign in with Google button label
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Continue without sign-in button label
  ///
  /// In en, this message translates to:
  /// **'Continue without sign-in'**
  String get continueWithoutSignIn;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error;

  /// Accessible label announced while an operation is in progress
  ///
  /// In en, this message translates to:
  /// **'Loading, please wait'**
  String get loadingInProgress;

  /// Toggle to enable biometric authentication
  ///
  /// In en, this message translates to:
  /// **'Use biometric authentication'**
  String get useBiometric;

  /// Short message shown when authentication is required
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authenticationRequired;

  /// Authenticate button label
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authenticate;

  /// Biometric prompt reason for opening contacts
  ///
  /// In en, this message translates to:
  /// **'Authenticate to open contacts'**
  String get authenticateToOpenContacts;

  /// Biometric prompt reason to confirm disabling biometric auth
  ///
  /// In en, this message translates to:
  /// **'Confirm disabling biometric authentication'**
  String get confirmDisableBiometric;

  /// Sign out button label
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} is coming soon'**
  String comingSoon(Object feature);

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @securityAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get securityAndPrivacy;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// No description provided for @accessManagement.
  ///
  /// In en, this message translates to:
  /// **'Access Management'**
  String get accessManagement;

  /// No description provided for @notificationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSectionTitle;

  /// No description provided for @legalAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Legal & Support'**
  String get legalAndSupport;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// Confirmation dialog title for deleting all local data
  ///
  /// In en, this message translates to:
  /// **'Delete all your local data permanently?'**
  String get deleteAllDataDialogTitle;

  /// Confirmation dialog message for deleting all local data
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All locally stored medical records, settings, and cached files will be deleted permanently and cannot be restored.'**
  String get deleteAllDataDialogMessage;

  /// Destructive action label to confirm deleting all local data
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deleteAllDataConfirmAction;

  /// Button label while deleting all local data
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleteAllDataDeleting;

  /// Snackbar message shown after all local data is deleted
  ///
  /// In en, this message translates to:
  /// **'All local data has been deleted permanently.'**
  String get deleteAllDataSuccess;

  /// Snackbar message shown when deleting all local data fails
  ///
  /// In en, this message translates to:
  /// **'We could not delete your data. Please try again.'**
  String get deleteAllDataError;

  /// No description provided for @medVaultVersionMvp.
  ///
  /// In en, this message translates to:
  /// **'MedVault v1.0.0 MVP'**
  String get medVaultVersionMvp;

  /// No description provided for @copyrightCompliance.
  ///
  /// In en, this message translates to:
  /// **'© 2026 MedVault. HIPAA & GDPR Compliant.'**
  String get copyrightCompliance;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get profileLoadFailed;

  /// No description provided for @demoProfileUpdatedLocally.
  ///
  /// In en, this message translates to:
  /// **'Demo profile updated locally'**
  String get demoProfileUpdatedLocally;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get profileSaveFailed;

  /// No description provided for @addEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get addEmergencyContact;

  /// No description provided for @addEmergencyContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the details of the emergency contact you want to add.'**
  String get addEmergencyContactSubtitle;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @selectFromFiles.
  ///
  /// In en, this message translates to:
  /// **'Select from files'**
  String get selectFromFiles;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @lastUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdatedOn(Object date);

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldRequired(Object field);

  /// No description provided for @enterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmailAddress;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @noEmergencyContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts added yet.'**
  String get noEmergencyContactsYet;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @setAsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Set as Primary'**
  String get setAsPrimary;

  /// Theme section header
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Dark mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Add contact button label
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Relationship field label
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// Relationship dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select relationship'**
  String get relationshipSelectHint;

  /// Validation message when relationship is not selected
  ///
  /// In en, this message translates to:
  /// **'Relationship is required'**
  String get relationshipRequired;

  /// Emergency contact relationship option: spouse
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get relationshipSpouse;

  /// Emergency contact relationship option: parent
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get relationshipParent;

  /// Emergency contact relationship option: sibling
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get relationshipSibling;

  /// Emergency contact relationship option: child
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get relationshipChild;

  /// Emergency contact relationship option: partner
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get relationshipPartner;

  /// Emergency contact relationship option: friend
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get relationshipFriend;

  /// Emergency contact relationship option: caregiver
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get relationshipCaregiver;

  /// Emergency contact relationship option: other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationshipOther;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Medical information section title
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get medicalInformation;

  /// Medical information subtitle
  ///
  /// In en, this message translates to:
  /// **'Your complete health profile'**
  String get yourCompleteHealthProfile;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Allergies tab label
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// Medications tab label
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// Vaccinations tab label
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get vaccinations;

  /// Diagnoses tab label
  ///
  /// In en, this message translates to:
  /// **'Diagnoses'**
  String get diagnoses;

  /// Lab results tab label
  ///
  /// In en, this message translates to:
  /// **'Lab Results'**
  String get labResults;

  /// Quick summary section header
  ///
  /// In en, this message translates to:
  /// **'Quick Summary'**
  String get quickSummary;

  /// Blood type field label
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

  /// Critical information section header
  ///
  /// In en, this message translates to:
  /// **'Critical Information'**
  String get criticialInformation;

  /// Recent updates section header
  ///
  /// In en, this message translates to:
  /// **'Recent Updates'**
  String get recentUpdates;

  /// Add allergy button label
  ///
  /// In en, this message translates to:
  /// **'Add Allergy'**
  String get addAllergy;

  /// Number of allergies recorded
  ///
  /// In en, this message translates to:
  /// **'allergies recorded'**
  String get allergiesRecorded;

  /// Allergy name field label
  ///
  /// In en, this message translates to:
  /// **'Allergy Name'**
  String get allergyName;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Severity field label
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// Critical severity level
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// Mark as critical checkbox label
  ///
  /// In en, this message translates to:
  /// **'Mark as Critical'**
  String get markAsCritical;

  /// Notes field label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Delete allergy confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete Allergy?'**
  String get deleteAllergy;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get areYouSureDelete;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Success message after adding allergy
  ///
  /// In en, this message translates to:
  /// **'Allergy added successfully'**
  String get allergyAddedSuccessfully;

  /// Success message after deleting allergy
  ///
  /// In en, this message translates to:
  /// **'Allergy deleted successfully'**
  String get allergyDeletedSuccessfully;

  /// Add medication button label
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// Number of medications
  ///
  /// In en, this message translates to:
  /// **'medications'**
  String get medicationCount;

  /// Medication name field label
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// Dosage field label
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// Frequency field label
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// Example frequency format
  ///
  /// In en, this message translates to:
  /// **'e.g., Once daily'**
  String get egOnceDaily;

  /// Reason field label
  ///
  /// In en, this message translates to:
  /// **'Reason for medication'**
  String get reasonForMedication;

  /// Success message after adding medication
  ///
  /// In en, this message translates to:
  /// **'Medication added successfully'**
  String get medicationAddedSuccessfully;

  /// Success message after deleting medication
  ///
  /// In en, this message translates to:
  /// **'Medication deleted successfully'**
  String get medicationDeletedSuccessfully;

  /// Add vaccination button label
  ///
  /// In en, this message translates to:
  /// **'Add Vaccination'**
  String get addVaccination;

  /// Number of vaccinations
  ///
  /// In en, this message translates to:
  /// **'vaccinations'**
  String get vaccinationCount;

  /// Vaccine name field label
  ///
  /// In en, this message translates to:
  /// **'Vaccine Name'**
  String get vaccineName;

  /// Select date button label
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Provider field label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// Batch number field label
  ///
  /// In en, this message translates to:
  /// **'Batch Number'**
  String get batchNumber;

  /// Success message after adding vaccination
  ///
  /// In en, this message translates to:
  /// **'Vaccination added successfully'**
  String get vaccinationAddedSuccessfully;

  /// Success message after deleting vaccination
  ///
  /// In en, this message translates to:
  /// **'Vaccination deleted successfully'**
  String get vaccinationDeletedSuccessfully;

  /// Add diagnosis button label
  ///
  /// In en, this message translates to:
  /// **'Add Diagnosis'**
  String get addDiagnosis;

  /// Number of diagnoses recorded
  ///
  /// In en, this message translates to:
  /// **'diagnoses recorded'**
  String get diagnosesRecorded;

  /// Diagnosis name field label
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Name'**
  String get diagnosisName;

  /// Status field label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Treatment plan field label
  ///
  /// In en, this message translates to:
  /// **'Treatment Plan'**
  String get treatmentPlan;

  /// Success message after adding diagnosis
  ///
  /// In en, this message translates to:
  /// **'Diagnosis added successfully'**
  String get diagnosisAddedSuccessfully;

  /// Success message after deleting diagnosis
  ///
  /// In en, this message translates to:
  /// **'Diagnosis deleted successfully'**
  String get diagnosisDeletedSuccessfully;

  /// Add lab result button label
  ///
  /// In en, this message translates to:
  /// **'Add Result'**
  String get addLabResult;

  /// Number of lab results available
  ///
  /// In en, this message translates to:
  /// **'results available'**
  String get labResultsAvailable;

  /// Test name field label
  ///
  /// In en, this message translates to:
  /// **'Test Name'**
  String get testName;

  /// Category field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Doctor interpretation section label
  ///
  /// In en, this message translates to:
  /// **'Doctor\'s Interpretation'**
  String get doctorInterpretation;

  /// Success message after adding lab result
  ///
  /// In en, this message translates to:
  /// **'Lab result added successfully'**
  String get labResultAddedSuccessfully;

  /// Success message after deleting lab result
  ///
  /// In en, this message translates to:
  /// **'Lab result deleted successfully'**
  String get labResultDeletedSuccessfully;

  /// Normal status label
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// Abnormal status label
  ///
  /// In en, this message translates to:
  /// **'Abnormal'**
  String get abnormal;

  /// Pending status label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Complete blood count test name
  ///
  /// In en, this message translates to:
  /// **'Complete Blood Count'**
  String get completedBloodCount;

  /// COVID-19 booster vaccine name
  ///
  /// In en, this message translates to:
  /// **'COVID-19 Booster'**
  String get covidBooster;

  /// Added date label
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// Received date label
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// Penicillin allergy name
  ///
  /// In en, this message translates to:
  /// **'Penicillin'**
  String get penicillin;

  /// Severe allergic reaction description
  ///
  /// In en, this message translates to:
  /// **'Severe allergic reaction'**
  String get severeAllergicReaction;

  /// Peanuts allergy name
  ///
  /// In en, this message translates to:
  /// **'Peanuts'**
  String get peanuts;

  /// Mild rash description
  ///
  /// In en, this message translates to:
  /// **'Mild rash'**
  String get mildRash;

  /// Lisinopril medication name
  ///
  /// In en, this message translates to:
  /// **'Lisinopril'**
  String get lisinopril;

  /// Metformin medication name
  ///
  /// In en, this message translates to:
  /// **'Metformin'**
  String get metformin;

  /// Flu shot vaccine name
  ///
  /// In en, this message translates to:
  /// **'Flu Shot'**
  String get flueShot;

  /// High severity level
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// Medium severity level
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// Low severity level
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// Fallback when description is missing
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get areYouSureYouWantToDelete;

  /// Active status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Chronic diagnosis status
  ///
  /// In en, this message translates to:
  /// **'Chronic'**
  String get chronic;

  /// Resolved diagnosis status
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// Expired diagnosis status
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// Condition field label
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// Diagnosed by field label
  ///
  /// In en, this message translates to:
  /// **'Diagnosed by'**
  String get diagnosedBy;

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Delete diagnosis confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete Diagnosis?'**
  String get deleteDiagnosis;

  /// Laboratory label
  ///
  /// In en, this message translates to:
  /// **'Lab'**
  String get lab;

  /// Test date field label
  ///
  /// In en, this message translates to:
  /// **'Test Date'**
  String get testDate;

  /// Number of medications recorded
  ///
  /// In en, this message translates to:
  /// **'medications recorded'**
  String get medicationsRecorded;

  /// Reason field label
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// Prescribed by field label
  ///
  /// In en, this message translates to:
  /// **'Prescribed by'**
  String get prescribedBy;

  /// Delete medication confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete Medication?'**
  String get deleteMedication;

  /// Number of vaccinations recorded
  ///
  /// In en, this message translates to:
  /// **'vaccinations recorded'**
  String get vaccinationsRecorded;

  /// Next due date label
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get nextDue;

  /// Delete vaccination confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete Vaccination?'**
  String get deleteVaccination;

  /// Number of lab results recorded
  ///
  /// In en, this message translates to:
  /// **'lab results recorded'**
  String get labResultsRecorded;

  /// No description provided for @editBloodType.
  ///
  /// In en, this message translates to:
  /// **'Edit Blood Type'**
  String get editBloodType;

  /// No description provided for @authSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed'**
  String get authSignInFailed;

  /// No description provided for @authEmailSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in failed'**
  String get authEmailSignInFailed;

  /// No description provided for @authEmailRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Email registration failed'**
  String get authEmailRegistrationFailed;

  /// No description provided for @authCreateAccountWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Create account with Email'**
  String get authCreateAccountWithEmail;

  /// No description provided for @authSignInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get authSignInWithEmail;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get authFirstName;

  /// No description provided for @authLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get authLastName;

  /// No description provided for @authAcceptTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'I accept Terms of Service'**
  String get authAcceptTermsOfService;

  /// No description provided for @authAcceptPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'I accept Privacy Policy'**
  String get authAcceptPrivacyPolicy;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSecureMedicalRecordsVault.
  ///
  /// In en, this message translates to:
  /// **'Your secure medical records vault'**
  String get authSecureMedicalRecordsVault;

  /// No description provided for @authHipaaGdprCompliant.
  ///
  /// In en, this message translates to:
  /// **'HIPAA & GDPR Compliant'**
  String get authHipaaGdprCompliant;

  /// No description provided for @authDataEncryptedSecure.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted and secure'**
  String get authDataEncryptedSecure;

  /// No description provided for @authEndToEndEncryption.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encryption'**
  String get authEndToEndEncryption;

  /// No description provided for @authOnlyYouControlRecords.
  ///
  /// In en, this message translates to:
  /// **'Only you control access to your records'**
  String get authOnlyYouControlRecords;

  /// No description provided for @authSigningInDemo.
  ///
  /// In en, this message translates to:
  /// **'Signing in to demo...'**
  String get authSigningInDemo;

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get authSigningIn;

  /// No description provided for @authContinueWithDemoGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Demo Google'**
  String get authContinueWithDemoGoogle;

  /// No description provided for @authDateOfBirthRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required.'**
  String get authDateOfBirthRequired;

  /// No description provided for @authAcceptTermsPrivacyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and privacy policy.'**
  String get authAcceptTermsPrivacyRequired;

  /// No description provided for @authPolicyAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I have read and understand'**
  String get authPolicyAcknowledge;

  /// No description provided for @authPolicyScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the bottom to enable acknowledgment.'**
  String get authPolicyScrollHint;

  /// No description provided for @authRegistrationFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get authRegistrationFailedTryAgain;

  /// No description provided for @authRegistrationCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Registration completed successfully.'**
  String get authRegistrationCompletedSuccessfully;

  /// No description provided for @authCompleteRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get authCompleteRegistration;

  /// No description provided for @authRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get authRequiredField;

  /// No description provided for @authDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get authDateOfBirth;

  /// No description provided for @authGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get authGender;

  /// No description provided for @authGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get authGenderMale;

  /// No description provided for @authGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get authGenderFemale;

  /// No description provided for @authGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get authGenderOther;

  /// No description provided for @authGenderPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get authGenderPreferNotToSay;

  /// No description provided for @authPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhoneNumber;

  /// No description provided for @onboardingErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get onboardingErrorGeneric;

  /// No description provided for @onboardingStepBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Authentication'**
  String get onboardingStepBiometricTitle;

  /// No description provided for @onboardingStepNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get onboardingStepNotificationsTitle;

  /// No description provided for @onboardingStepCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get onboardingStepCloudTitle;

  /// No description provided for @onboardingStepMedicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get onboardingStepMedicalTitle;

  /// No description provided for @onboardingStepBiometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face recognition to secure your health data.'**
  String get onboardingStepBiometricSubtitle;

  /// No description provided for @onboardingStepNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay informed about access to your medical records'**
  String get onboardingStepNotificationsSubtitle;

  /// No description provided for @onboardingStepCloudSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your data safe'**
  String get onboardingStepCloudSubtitle;

  /// No description provided for @onboardingStepMedicalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Basic health profile'**
  String get onboardingStepMedicalSubtitle;

  /// No description provided for @onboardingStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepCounter(int current, int total);

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingBiometricDescription.
  ///
  /// In en, this message translates to:
  /// **'Secure your health data with biometric authentication.'**
  String get onboardingBiometricDescription;

  /// No description provided for @onboardingEnableBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get onboardingEnableBiometricLock;

  /// No description provided for @onboardingBiometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get onboardingBiometricEnabled;

  /// No description provided for @onboardingBiometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get onboardingBiometricDisabled;

  /// No description provided for @onboardingBiometricFaster.
  ///
  /// In en, this message translates to:
  /// **'Faster and more secure'**
  String get onboardingBiometricFaster;

  /// No description provided for @onboardingBiometricCheck1.
  ///
  /// In en, this message translates to:
  /// **'Your biometric data never leaves your device'**
  String get onboardingBiometricCheck1;

  /// No description provided for @onboardingBiometricCheck2.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security'**
  String get onboardingBiometricCheck2;

  /// No description provided for @onboardingBiometricCheck3.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings'**
  String get onboardingBiometricCheck3;

  /// No description provided for @onboardingBiometricType.
  ///
  /// In en, this message translates to:
  /// **'Biometric Type'**
  String get onboardingBiometricType;

  /// No description provided for @onboardingBiometricFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get onboardingBiometricFingerprint;

  /// No description provided for @onboardingBiometricFace.
  ///
  /// In en, this message translates to:
  /// **'Face Recognition'**
  String get onboardingBiometricFace;

  /// No description provided for @onboardingBiometricIris.
  ///
  /// In en, this message translates to:
  /// **'Iris Scan'**
  String get onboardingBiometricIris;

  /// No description provided for @biometricUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric login unavailable'**
  String get biometricUnavailableTitle;

  /// No description provided for @biometricUnavailableNoHardware.
  ///
  /// In en, this message translates to:
  /// **'This device does not support biometric authentication.'**
  String get biometricUnavailableNoHardware;

  /// No description provided for @biometricUnavailableNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No biometric data is enrolled on this device.'**
  String get biometricUnavailableNotEnrolled;

  /// No description provided for @biometricUnavailableUnknown.
  ///
  /// In en, this message translates to:
  /// **'Biometric availability could not be verified on this device.'**
  String get biometricUnavailableUnknown;

  /// No description provided for @onboardingNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which notifications you would like to receive.'**
  String get onboardingNotificationsDescription;

  /// No description provided for @onboardingPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get onboardingPushNotifications;

  /// No description provided for @onboardingPushNotificationsSubtext.
  ///
  /// In en, this message translates to:
  /// **'Get notified about access events'**
  String get onboardingPushNotificationsSubtext;

  /// No description provided for @onboardingNotifyWhen.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified when:'**
  String get onboardingNotifyWhen;

  /// No description provided for @onboardingNotifyReasonQR.
  ///
  /// In en, this message translates to:
  /// **'Someone accesses your emergency QR code'**
  String get onboardingNotifyReasonQR;

  /// No description provided for @onboardingNotifyReasonShared.
  ///
  /// In en, this message translates to:
  /// **'A provider views your shared records'**
  String get onboardingNotifyReasonShared;

  /// No description provided for @onboardingNotifyReasonSecurity.
  ///
  /// In en, this message translates to:
  /// **'Important security events occur'**
  String get onboardingNotifyReasonSecurity;

  /// No description provided for @onboardingEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get onboardingEmailNotifications;

  /// No description provided for @onboardingMedicalReminders.
  ///
  /// In en, this message translates to:
  /// **'Medical Reminders'**
  String get onboardingMedicalReminders;

  /// No description provided for @onboardingAppointmentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Appointment Alerts'**
  String get onboardingAppointmentAlerts;

  /// No description provided for @onboardingSecurityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Security Alerts'**
  String get onboardingSecurityAlerts;

  /// No description provided for @onboardingCloudDescription.
  ///
  /// In en, this message translates to:
  /// **'Back up your health records to the cloud.'**
  String get onboardingCloudDescription;

  /// No description provided for @onboardingBackupProvider.
  ///
  /// In en, this message translates to:
  /// **'Backup Provider'**
  String get onboardingBackupProvider;

  /// No description provided for @onboardingProviderMedVault.
  ///
  /// In en, this message translates to:
  /// **'MedVault Cloud'**
  String get onboardingProviderMedVault;

  /// No description provided for @onboardingProviderGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get onboardingProviderGoogleDrive;

  /// No description provided for @onboardingProviderICloud.
  ///
  /// In en, this message translates to:
  /// **'iCloud'**
  String get onboardingProviderICloud;

  /// No description provided for @onboardingAutoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup'**
  String get onboardingAutoBackup;

  /// No description provided for @onboardingAutoBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically back up changes'**
  String get onboardingAutoBackupSubtitle;

  /// No description provided for @onboardingMedicalInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'Provide basic medical information. You can add more details later.'**
  String get onboardingMedicalInfoDescription;

  /// No description provided for @onboardingSubstance.
  ///
  /// In en, this message translates to:
  /// **'Substance'**
  String get onboardingSubstance;

  /// No description provided for @onboardingUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get onboardingUnknown;

  /// No description provided for @onboardingOnceDaily.
  ///
  /// In en, this message translates to:
  /// **'Once daily'**
  String get onboardingOnceDaily;

  /// Emergency access card title
  ///
  /// In en, this message translates to:
  /// **'Emergency Access'**
  String get emergencyAccess;

  /// Emergency access card subtitle
  ///
  /// In en, this message translates to:
  /// **'Share critical info instantly'**
  String get shareCriticalInfoInstantly;

  /// Message shown when emergency sharing is disabled
  ///
  /// In en, this message translates to:
  /// **'Emergency sharing is disabled in settings.'**
  String get emergencySharingDisabledInSettings;

  /// Medical Info section title
  ///
  /// In en, this message translates to:
  /// **'Medical Info'**
  String get medicalInfo;

  /// View all button label
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Medications abbreviation
  ///
  /// In en, this message translates to:
  /// **'Meds'**
  String get meds;

  /// Vaccines label
  ///
  /// In en, this message translates to:
  /// **'Vaccines'**
  String get vaccines;

  /// User not signed in status
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// Account section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Dashboard header subtitle
  ///
  /// In en, this message translates to:
  /// **'Your Health Dashboard'**
  String get dashboardSubtitle;

  /// Critical allergy card title
  ///
  /// In en, this message translates to:
  /// **'Critical Allergy'**
  String get criticalAllergy;

  /// Fallback text when no critical allergies are present
  ///
  /// In en, this message translates to:
  /// **'No critical allergies'**
  String get noCriticalAllergies;

  /// Dashboard lab tests summary label
  ///
  /// In en, this message translates to:
  /// **'Total Tests'**
  String get totalTests;

  /// Dashboard lab flagged summary label
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get flagged;

  /// Dashboard recent activity section title
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// Dashboard security banner title
  ///
  /// In en, this message translates to:
  /// **'Your data is secure'**
  String get yourDataIsSecure;

  /// Dashboard security banner subtitle
  ///
  /// In en, this message translates to:
  /// **'All records are encrypted end-to-end. Only you control access.'**
  String get dashboardSecurityDescription;

  /// Documents tab label
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// Share tab label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Alerts tab label
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// Dashboard quick actions title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Dashboard quick action label for adding a document
  ///
  /// In en, this message translates to:
  /// **'Add New Document'**
  String get addNewDocument;

  /// Dashboard quick action label for adding a lab result
  ///
  /// In en, this message translates to:
  /// **'Add New Lab Result'**
  String get addNewLabResult;

  /// Success message after creating a document
  ///
  /// In en, this message translates to:
  /// **'Document created successfully'**
  String get documentCreatedSuccessfully;

  /// No description provided for @documentsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Document updated successfully'**
  String get documentsUpdatedSuccessfully;

  /// No description provided for @documentsDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Document deleted successfully'**
  String get documentsDeletedSuccessfully;

  /// No description provided for @documentsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search documents'**
  String get documentsSearchPlaceholder;

  /// No description provided for @documentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get documentsEmptyTitle;

  /// No description provided for @documentsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your first medical document to get started.'**
  String get documentsEmptySubtitle;

  /// No description provided for @documentsSelectSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Select document source'**
  String get documentsSelectSourceTitle;

  /// No description provided for @documentsFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get documentsFromGallery;

  /// No description provided for @documentsUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file'**
  String get documentsUploadFailed;

  /// No description provided for @documentsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save document'**
  String get documentsSaveFailed;

  /// No description provided for @documentsDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete document?'**
  String get documentsDeleteDialogTitle;

  /// Delete confirmation message for a document
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {title}?'**
  String documentsDeleteDialogMessage(String title);

  /// No description provided for @documentsOpenWithApp.
  ///
  /// In en, this message translates to:
  /// **'Open with app'**
  String get documentsOpenWithApp;

  /// No description provided for @documentsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open document'**
  String get documentsOpenFailed;

  /// No description provided for @documentsShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share document'**
  String get documentsShareFailed;

  /// No description provided for @documentsAddDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Document details'**
  String get documentsAddDetailsTitle;

  /// No description provided for @documentsEditDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit document details'**
  String get documentsEditDetailsTitle;

  /// No description provided for @documentsNoDateSelected.
  ///
  /// In en, this message translates to:
  /// **'No date selected'**
  String get documentsNoDateSelected;

  /// No description provided for @documentsExtractDataButton.
  ///
  /// In en, this message translates to:
  /// **'Extract Data'**
  String get documentsExtractDataButton;

  /// No description provided for @documentsSaveBeforeExtraction.
  ///
  /// In en, this message translates to:
  /// **'Save the document first before extracting data'**
  String get documentsSaveBeforeExtraction;

  /// No description provided for @documentsExtractionUnavailableInDemo.
  ///
  /// In en, this message translates to:
  /// **'Extract Data is not available in demo mode yet'**
  String get documentsExtractionUnavailableInDemo;

  /// No description provided for @documentsExtractionNotReady.
  ///
  /// In en, this message translates to:
  /// **'Document extraction is not connected yet'**
  String get documentsExtractionNotReady;

  /// No description provided for @documentsExtractionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to extract document data'**
  String get documentsExtractionFailed;

  /// No description provided for @documentsAtLeastOneFileRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one file is required'**
  String get documentsAtLeastOneFileRequired;

  /// No description provided for @documentsAddFileButton.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get documentsAddFileButton;

  /// No description provided for @documentsRemoveSelectedFileButton.
  ///
  /// In en, this message translates to:
  /// **'Remove selected file'**
  String get documentsRemoveSelectedFileButton;

  /// Number of files associated with one document
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String documentsFilesCount(int count);

  /// Message shown when the user selects too many files for one document
  ///
  /// In en, this message translates to:
  /// **'You can select up to {maxFiles} files per document.'**
  String documentsMaxFilesSelectionLimit(int maxFiles);

  /// Message shown when no more files can be added to a document
  ///
  /// In en, this message translates to:
  /// **'This document already has the maximum of {maxFiles} files.'**
  String documentsMaxFilesReached(int maxFiles);

  /// Message shown when selected file count exceeds remaining slots
  ///
  /// In en, this message translates to:
  /// **'You can only add {availableSlots} more files. Maximum: {maxFiles} per document.'**
  String documentsMaxFilesRemaining(int availableSlots, int maxFiles);

  /// No description provided for @documentsCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get documentsCategoryLabel;

  /// No description provided for @documentsTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get documentsTagsLabel;

  /// No description provided for @documentsTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Type a tag and tap +'**
  String get documentsTagsHint;

  /// No description provided for @documentsTypePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get documentsTypePdf;

  /// No description provided for @documentsTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get documentsTypeImage;

  /// No description provided for @documentsTypeDocx.
  ///
  /// In en, this message translates to:
  /// **'DOCX'**
  String get documentsTypeDocx;

  /// No description provided for @documentsTypeXlsx.
  ///
  /// In en, this message translates to:
  /// **'XLSX'**
  String get documentsTypeXlsx;

  /// No description provided for @documentsTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get documentsTypeOther;

  /// No description provided for @documentsCategoryLabResults.
  ///
  /// In en, this message translates to:
  /// **'Lab Results'**
  String get documentsCategoryLabResults;

  /// No description provided for @documentsCategoryMedicalReport.
  ///
  /// In en, this message translates to:
  /// **'Medical Report'**
  String get documentsCategoryMedicalReport;

  /// No description provided for @documentsCategoryMedicationReport.
  ///
  /// In en, this message translates to:
  /// **'Medication Report'**
  String get documentsCategoryMedicationReport;

  /// No description provided for @documentsCategoryVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get documentsCategoryVaccinations;

  /// No description provided for @documentsCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get documentsCategoryOther;

  /// Success message after creating a lab result
  ///
  /// In en, this message translates to:
  /// **'Lab test result created successfully'**
  String get labTestResultCreatedSuccessfully;

  /// Fallback text when no lab results are available
  ///
  /// In en, this message translates to:
  /// **'No lab results yet'**
  String get noLabResults;

  /// No description provided for @labResultsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get labResultsAll;

  /// No description provided for @searchLabResults.
  ///
  /// In en, this message translates to:
  /// **'Search lab results'**
  String get searchLabResults;

  /// No description provided for @noMatchingLabResults.
  ///
  /// In en, this message translates to:
  /// **'No matching lab results'**
  String get noMatchingLabResults;

  /// No description provided for @addLabResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Lab Result'**
  String get addLabResultTitle;

  /// No description provided for @editLabResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Lab Result'**
  String get editLabResultTitle;

  /// No description provided for @labResultDetails.
  ///
  /// In en, this message translates to:
  /// **'Lab Result Details'**
  String get labResultDetails;

  /// No description provided for @addLabResultType.
  ///
  /// In en, this message translates to:
  /// **'Add Lab Result Type'**
  String get addLabResultType;

  /// No description provided for @removeLabResultType.
  ///
  /// In en, this message translates to:
  /// **'Remove Lab Result Type'**
  String get removeLabResultType;

  /// No description provided for @removeLabResultTypeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove this custom category from your list?'**
  String get removeLabResultTypeConfirmation;

  /// No description provided for @deleteLabResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Lab Result?'**
  String get deleteLabResultTitle;

  /// Delete confirmation for a specific lab result
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {testName}?'**
  String deleteLabResultConfirmation(String testName);

  /// No description provided for @labResultUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lab result updated successfully'**
  String get labResultUpdatedSuccessfully;

  /// No description provided for @labResultTypeRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lab result type removed successfully'**
  String get labResultTypeRemovedSuccessfully;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @labResultTypeInUseCannotRemove.
  ///
  /// In en, this message translates to:
  /// **'This category is already used by a lab result.'**
  String get labResultTypeInUseCannotRemove;

  /// No description provided for @chooseHowToAddYourLabResults.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to add your lab results.'**
  String get chooseHowToAddYourLabResults;

  /// No description provided for @labResultsAddDescription.
  ///
  /// In en, this message translates to:
  /// **'You can enter them manually or upload a document for automatic extraction.'**
  String get labResultsAddDescription;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @manualEntryDetails.
  ///
  /// In en, this message translates to:
  /// **'Add individual test values\nFull control over data entry\nBest for single results'**
  String get manualEntryDetails;

  /// No description provided for @uploadAndExtract.
  ///
  /// In en, this message translates to:
  /// **'Upload & Extract'**
  String get uploadAndExtract;

  /// No description provided for @uploadAndExtractDetails.
  ///
  /// In en, this message translates to:
  /// **'AI-powered data extraction\nUpload PDF or image files\nFaster for multiple values'**
  String get uploadAndExtractDetails;

  /// No description provided for @testInformation.
  ///
  /// In en, this message translates to:
  /// **'Test Information'**
  String get testInformation;

  /// No description provided for @testValues.
  ///
  /// In en, this message translates to:
  /// **'Test Values'**
  String get testValues;

  /// No description provided for @labValueNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g., Hemoglobin)'**
  String get labValueNameHint;

  /// No description provided for @yourValue.
  ///
  /// In en, this message translates to:
  /// **'Your Value'**
  String get yourValue;

  /// No description provided for @valueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueLabel;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @minimum.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minimum;

  /// No description provided for @maximum.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maximum;

  /// No description provided for @interpretationAndNotes.
  ///
  /// In en, this message translates to:
  /// **'Interpretation & Notes'**
  String get interpretationAndNotes;

  /// No description provided for @uploadLabReport.
  ///
  /// In en, this message translates to:
  /// **'Upload Lab Report'**
  String get uploadLabReport;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @addValue.
  ///
  /// In en, this message translates to:
  /// **'Add Value'**
  String get addValue;

  /// No description provided for @referenceRangeOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference Range (Optional)'**
  String get referenceRangeOptional;

  /// No description provided for @saveResult.
  ///
  /// In en, this message translates to:
  /// **'Save Result'**
  String get saveResult;

  /// No description provided for @labResultTypeCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lab result type created successfully'**
  String get labResultTypeCreatedSuccessfully;

  /// No description provided for @labCategoryCompleteBloodCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Complete Blood Count (CBC)'**
  String get labCategoryCompleteBloodCountLabel;

  /// No description provided for @labCategoryCompleteBloodCountDescription.
  ///
  /// In en, this message translates to:
  /// **'Checks your blood cells.'**
  String get labCategoryCompleteBloodCountDescription;

  /// No description provided for @labCategoryMetabolicPanelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Metabolic Panels (BMP or CMP)'**
  String get labCategoryMetabolicPanelsLabel;

  /// No description provided for @labCategoryMetabolicPanelsDescription.
  ///
  /// In en, this message translates to:
  /// **'Checks organ function and chemistry.'**
  String get labCategoryMetabolicPanelsDescription;

  /// No description provided for @labCategoryLipidPanelLabel.
  ///
  /// In en, this message translates to:
  /// **'Lipid Panel'**
  String get labCategoryLipidPanelLabel;

  /// No description provided for @labCategoryLipidPanelDescription.
  ///
  /// In en, this message translates to:
  /// **'Checks your heart health and fats.'**
  String get labCategoryLipidPanelDescription;

  /// No description provided for @labCategoryThyroidPanelLabel.
  ///
  /// In en, this message translates to:
  /// **'Thyroid Panel'**
  String get labCategoryThyroidPanelLabel;

  /// No description provided for @labCategoryThyroidPanelDescription.
  ///
  /// In en, this message translates to:
  /// **'Checks your metabolism regulator.'**
  String get labCategoryThyroidPanelDescription;

  /// No description provided for @labCategoryDiabetesMonitoringLabel.
  ///
  /// In en, this message translates to:
  /// **'Diabetes Monitoring'**
  String get labCategoryDiabetesMonitoringLabel;

  /// No description provided for @labCategoryDiabetesMonitoringDescription.
  ///
  /// In en, this message translates to:
  /// **'Checks long-term sugar.'**
  String get labCategoryDiabetesMonitoringDescription;

  /// No description provided for @labCategoryHemoglobinA1cLabel.
  ///
  /// In en, this message translates to:
  /// **'Hemoglobin A1c'**
  String get labCategoryHemoglobinA1cLabel;

  /// No description provided for @labCategoryHemoglobinA1cDescription.
  ///
  /// In en, this message translates to:
  /// **'Your average blood sugar over the last 3 months.'**
  String get labCategoryHemoglobinA1cDescription;

  /// No description provided for @labCategoryUrinalysisLabel.
  ///
  /// In en, this message translates to:
  /// **'Urinalysis'**
  String get labCategoryUrinalysisLabel;

  /// No description provided for @labCategoryUrinalysisDescription.
  ///
  /// In en, this message translates to:
  /// **'Checks waste management.'**
  String get labCategoryUrinalysisDescription;

  /// No description provided for @labCategoryNutrientLevelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Nutrient Levels'**
  String get labCategoryNutrientLevelsLabel;

  /// No description provided for @labCategoryNutrientLevelsDescription.
  ///
  /// In en, this message translates to:
  /// **'Checks for deficiencies.'**
  String get labCategoryNutrientLevelsDescription;

  /// No description provided for @sharingAndCollaborationTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing & Collaboration'**
  String get sharingAndCollaborationTitle;

  /// No description provided for @sharingManageDataAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage data access'**
  String get sharingManageDataAccessSubtitle;

  /// No description provided for @sharingEmergencyQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency QR'**
  String get sharingEmergencyQrTitle;

  /// No description provided for @sharingQuickAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get sharingQuickAccessSubtitle;

  /// No description provided for @sharingWithPhysicianTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with Physician'**
  String get sharingWithPhysicianTitle;

  /// No description provided for @sharingWithPhysicianSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure provider access'**
  String get sharingWithPhysicianSubtitle;

  /// No description provided for @sharingSecureSharingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure sharing'**
  String get sharingSecureSharingSubtitle;

  /// No description provided for @sharingActiveSharesTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Shares'**
  String get sharingActiveSharesTitle;

  /// No description provided for @sharingNoActiveSharesMessage.
  ///
  /// In en, this message translates to:
  /// **'No active sharing links yet.'**
  String get sharingNoActiveSharesMessage;

  /// No description provided for @sharingManageAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Access'**
  String get sharingManageAccessTitle;

  /// No description provided for @sharingAccessManagementLabel.
  ///
  /// In en, this message translates to:
  /// **'Access Management'**
  String get sharingAccessManagementLabel;

  /// No description provided for @sharingActivityLogLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get sharingActivityLogLabel;

  /// No description provided for @sharingPrivacyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Control, Your Privacy'**
  String get sharingPrivacyCardTitle;

  /// No description provided for @sharingPrivacyCardDescription.
  ///
  /// In en, this message translates to:
  /// **'You maintain full control over who can access your medical records. All access is logged and can be revoked at any time.'**
  String get sharingPrivacyCardDescription;

  /// No description provided for @sharingExpiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get sharingExpiresLabel;

  /// No description provided for @sharingEmergencyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get sharingEmergencyTypeLabel;

  /// No description provided for @sharingPhysicianTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Physician'**
  String get sharingPhysicianTypeLabel;

  /// No description provided for @sharingEmergencySharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Sharing'**
  String get sharingEmergencySharingTitle;

  /// No description provided for @sharingEmergencySharingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access for first responders'**
  String get sharingEmergencySharingSubtitle;

  /// No description provided for @sharingEmergencyWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the code or QR can access selected data. Only share in emergencies. All access is logged and you will be notified.'**
  String get sharingEmergencyWarningBody;

  /// No description provided for @sharingSelectInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Information to Share'**
  String get sharingSelectInformationTitle;

  /// No description provided for @sharingEmergencySelectInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what emergency responders can access'**
  String get sharingEmergencySelectInformationSubtitle;

  /// No description provided for @sharingCriticalBadge.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get sharingCriticalBadge;

  /// No description provided for @sharingRecommendedBadge.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sharingRecommendedBadge;

  /// No description provided for @sharingContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get sharingContinueButton;

  /// No description provided for @sharingEmergencySecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Configuration'**
  String get sharingEmergencySecurityTitle;

  /// No description provided for @sharingEmergencySecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure emergency link duration'**
  String get sharingEmergencySecuritySubtitle;

  /// No description provided for @sharingAccessDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Duration'**
  String get sharingAccessDurationTitle;

  /// No description provided for @sharingEmergencyDurationQuestion.
  ///
  /// In en, this message translates to:
  /// **'How long should the emergency code remain valid?'**
  String get sharingEmergencyDurationQuestion;

  /// No description provided for @sharingDataSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Summary'**
  String get sharingDataSummaryTitle;

  /// No description provided for @sharingDataSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Information that will be accessible'**
  String get sharingDataSummarySubtitle;

  /// No description provided for @sharingPrivacySecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get sharingPrivacySecurityTitle;

  /// No description provided for @sharingSecurityBulletLogged.
  ///
  /// In en, this message translates to:
  /// **'All access attempts are logged'**
  String get sharingSecurityBulletLogged;

  /// No description provided for @sharingSecurityBulletNotified.
  ///
  /// In en, this message translates to:
  /// **'You will receive instant notifications'**
  String get sharingSecurityBulletNotified;

  /// No description provided for @sharingSecurityBulletRevoke.
  ///
  /// In en, this message translates to:
  /// **'You can revoke access anytime'**
  String get sharingSecurityBulletRevoke;

  /// No description provided for @sharingSecurityBulletExpires.
  ///
  /// In en, this message translates to:
  /// **'Code expires automatically'**
  String get sharingSecurityBulletExpires;

  /// No description provided for @sharingGenerateEmergencyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Emergency Code'**
  String get sharingGenerateEmergencyCodeButton;

  /// No description provided for @sharingGeneratingCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Generating code...'**
  String get sharingGeneratingCodeButton;

  /// No description provided for @sharingEmergencyCodeActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Code Active'**
  String get sharingEmergencyCodeActiveTitle;

  /// No description provided for @sharingEmergencyAccessActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency access is active'**
  String get sharingEmergencyAccessActiveLabel;

  /// No description provided for @sharingExpiresInLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires in'**
  String get sharingExpiresInLabel;

  /// No description provided for @sharingScanQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get sharingScanQrCodeTitle;

  /// No description provided for @sharingScanQrCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'First responders can scan this to access your info'**
  String get sharingScanQrCodeSubtitle;

  /// No description provided for @sharingUseCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Or Use Code'**
  String get sharingUseCodeTitle;

  /// No description provided for @sharingEmergencyAccessCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency Access Code'**
  String get sharingEmergencyAccessCodeLabel;

  /// No description provided for @sharingVisitAndEnterCodeText.
  ///
  /// In en, this message translates to:
  /// **'Visit:'**
  String get sharingVisitAndEnterCodeText;

  /// No description provided for @sharingDownloadQrButton.
  ///
  /// In en, this message translates to:
  /// **'Download QR'**
  String get sharingDownloadQrButton;

  /// No description provided for @sharingDownloadPngButton.
  ///
  /// In en, this message translates to:
  /// **'Download PNG'**
  String get sharingDownloadPngButton;

  /// No description provided for @sharingDownloadJpgButton.
  ///
  /// In en, this message translates to:
  /// **'Download JPG'**
  String get sharingDownloadJpgButton;

  /// No description provided for @sharingQrDownloadedMessage.
  ///
  /// In en, this message translates to:
  /// **'QR code downloaded as {format}'**
  String sharingQrDownloadedMessage(Object format);

  /// No description provided for @sharingDownloadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to download QR code'**
  String get sharingDownloadFailedMessage;

  /// No description provided for @sharingShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sharingShareButton;

  /// No description provided for @sharingDownloadNotImplementedMessage.
  ///
  /// In en, this message translates to:
  /// **'Download action is available in a future update.'**
  String get sharingDownloadNotImplementedMessage;

  /// No description provided for @sharingLinkCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sharing link copied.'**
  String get sharingLinkCopiedMessage;

  /// No description provided for @sharingEmergencyNotificationInfo.
  ///
  /// In en, this message translates to:
  /// **'You will be notified every time someone accesses your emergency information.'**
  String get sharingEmergencyNotificationInfo;

  /// No description provided for @sharingRevokeEmergencyAccessButton.
  ///
  /// In en, this message translates to:
  /// **'Revoke Emergency Access'**
  String get sharingRevokeEmergencyAccessButton;

  /// No description provided for @sharingPhysicianInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Physician Information'**
  String get sharingPhysicianInformationTitle;

  /// No description provided for @sharingPhysicianNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Physician Name *'**
  String get sharingPhysicianNameLabel;

  /// No description provided for @sharingPhysicianEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address (Optional)'**
  String get sharingPhysicianEmailLabel;

  /// No description provided for @sharingPhysicianEmailHelpText.
  ///
  /// In en, this message translates to:
  /// **'Optional. Add an email to include physician contact in the sharing record.'**
  String get sharingPhysicianEmailHelpText;

  /// No description provided for @sharingNotesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get sharingNotesOptionalLabel;

  /// No description provided for @sharingSelectDataToShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Data to Share'**
  String get sharingSelectDataToShareTitle;

  /// No description provided for @sharingSelectDataToShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what the physician can access'**
  String get sharingSelectDataToShareSubtitle;

  /// No description provided for @sharingPhysicianValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid physician name. If provided, email must be valid.'**
  String get sharingPhysicianValidationMessage;

  /// No description provided for @sharingContinueToSecuritySettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Security Settings'**
  String get sharingContinueToSecuritySettingsButton;

  /// No description provided for @sharingSecuritySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get sharingSecuritySettingsTitle;

  /// No description provided for @sharingPasswordProtectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Password Protected'**
  String get sharingPasswordProtectedLabel;

  /// No description provided for @sharingTwoFactorRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'2FA Approval Required'**
  String get sharingTwoFactorRequiredLabel;

  /// No description provided for @sharingTwoFactorApprovalDescription.
  ///
  /// In en, this message translates to:
  /// **'When enabled, access will remain pending until you approve or deny it in the app.'**
  String get sharingTwoFactorApprovalDescription;

  /// No description provided for @sharingAllowDownloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Allow Download'**
  String get sharingAllowDownloadLabel;

  /// No description provided for @sharingPasswordConstraintsHelpText.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters with letters and numbers. Share it securely with the physician.'**
  String get sharingPasswordConstraintsHelpText;

  /// No description provided for @sharingReviewAndConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Confirm'**
  String get sharingReviewAndConfirmTitle;

  /// No description provided for @sharingWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Sharing With'**
  String get sharingWithLabel;

  /// No description provided for @sharingPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get sharingPatientLabel;

  /// No description provided for @sharingDataBeingSharedTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Being Shared'**
  String get sharingDataBeingSharedTitle;

  /// No description provided for @sharingAccessDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Access Duration'**
  String get sharingAccessDurationLabel;

  /// No description provided for @sharingYesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get sharingYesLabel;

  /// No description provided for @sharingNoLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get sharingNoLabel;

  /// No description provided for @sharingConsentStatement.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I consent to sharing my medical information and understand that all access will be logged and can be revoked at any time.'**
  String get sharingConsentStatement;

  /// No description provided for @sharingConfirmAndSendButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Send Share Link'**
  String get sharingConfirmAndSendButton;

  /// No description provided for @sharingSendingLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Sending link...'**
  String get sharingSendingLinkButton;

  /// No description provided for @sharingConfirmationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sharing'**
  String get sharingConfirmationDialogTitle;

  /// No description provided for @sharingConfirmationDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Create and send the secure sharing link to this physician?'**
  String get sharingConfirmationDialogMessage;

  /// No description provided for @sharingConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get sharingConfirmButton;

  /// No description provided for @sharingPhysicianEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'MedVault secure medical information sharing'**
  String get sharingPhysicianEmailSubject;

  /// No description provided for @sharingPhysicianEmailBodyIntro.
  ///
  /// In en, this message translates to:
  /// **'Please use this secure MedVault link to review my shared medical information.'**
  String get sharingPhysicianEmailBodyIntro;

  /// No description provided for @sharingPhysicianEmailBodyInstructions.
  ///
  /// In en, this message translates to:
  /// **'This link is time-limited and intended for secure medical sharing.'**
  String get sharingPhysicianEmailBodyInstructions;

  /// No description provided for @sharingEmailOpenedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sharing options opened.'**
  String get sharingEmailOpenedMessage;

  /// No description provided for @sharingEmailFallbackCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to open sharing options. Link copied to clipboard.'**
  String get sharingEmailFallbackCopiedMessage;

  /// No description provided for @sharingLinkCreatedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing Link Created'**
  String get sharingLinkCreatedDialogTitle;

  /// No description provided for @sharingLinkCreatedDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Your secure link is ready and can now be shared.'**
  String get sharingLinkCreatedDialogMessage;

  /// No description provided for @sharingCopyLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get sharingCopyLinkButton;

  /// No description provided for @sharingDoneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sharingDoneButton;

  /// No description provided for @sharingAccessManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Management'**
  String get sharingAccessManagementTitle;

  /// No description provided for @sharingSummaryActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sharingSummaryActiveLabel;

  /// No description provided for @sharingSummaryUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get sharingSummaryUsedLabel;

  /// No description provided for @sharingSummaryExpiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get sharingSummaryExpiredLabel;

  /// No description provided for @sharingNoAccessGrantsMessage.
  ///
  /// In en, this message translates to:
  /// **'No access grants available.'**
  String get sharingNoAccessGrantsMessage;

  /// No description provided for @sharingGrantedLabel.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get sharingGrantedLabel;

  /// No description provided for @sharingLastAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get sharingLastAccessLabel;

  /// No description provided for @sharingNeverLabel.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get sharingNeverLabel;

  /// No description provided for @sharingPermissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Perms'**
  String get sharingPermissionsLabel;

  /// No description provided for @sharingEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get sharingEditButton;

  /// No description provided for @sharingRevokeAccessButton.
  ///
  /// In en, this message translates to:
  /// **'Revoke Access'**
  String get sharingRevokeAccessButton;

  /// No description provided for @sharingEditPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Permissions'**
  String get sharingEditPermissionsTitle;

  /// No description provided for @sharingActivityLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get sharingActivityLogTitle;

  /// No description provided for @sharingActivityLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access & security events'**
  String get sharingActivityLogSubtitle;

  /// No description provided for @sharingAllEventsFilter.
  ///
  /// In en, this message translates to:
  /// **'All Events'**
  String get sharingAllEventsFilter;

  /// No description provided for @sharingAccessEventsFilter.
  ///
  /// In en, this message translates to:
  /// **'Access Events'**
  String get sharingAccessEventsFilter;

  /// No description provided for @sharingHighRiskFilter.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get sharingHighRiskFilter;

  /// No description provided for @sharingSummaryAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get sharingSummaryAccessLabel;

  /// No description provided for @sharingSummaryHighRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get sharingSummaryHighRiskLabel;

  /// No description provided for @sharingSummaryPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get sharingSummaryPeriodLabel;

  /// No description provided for @sharingSummaryPeriodValue.
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get sharingSummaryPeriodValue;

  /// No description provided for @sharingActivityTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Timeline'**
  String get sharingActivityTimelineTitle;

  /// No description provided for @sharingNoActivityEventsMessage.
  ///
  /// In en, this message translates to:
  /// **'No activity events for this filter.'**
  String get sharingNoActivityEventsMessage;

  /// No description provided for @sharingExportComplianceTitle.
  ///
  /// In en, this message translates to:
  /// **'Export & Compliance'**
  String get sharingExportComplianceTitle;

  /// No description provided for @sharingExportActivityPdfButton.
  ///
  /// In en, this message translates to:
  /// **'Export Activity Log (PDF)'**
  String get sharingExportActivityPdfButton;

  /// No description provided for @sharingExportGdprButton.
  ///
  /// In en, this message translates to:
  /// **'GDPR Data Portability Report'**
  String get sharingExportGdprButton;

  /// No description provided for @sharingExportPdfNotReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'PDF export will be connected in a future release.'**
  String get sharingExportPdfNotReadyMessage;

  /// No description provided for @sharingGdprExportNotReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'GDPR report export will be connected in a future release.'**
  String get sharingGdprExportNotReadyMessage;

  /// No description provided for @sharingScopePersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get sharingScopePersonalInformation;

  /// No description provided for @sharingScopeMedicalInformation.
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get sharingScopeMedicalInformation;

  /// No description provided for @sharingScopeBloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get sharingScopeBloodType;

  /// No description provided for @sharingScopeAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get sharingScopeAllergies;

  /// No description provided for @sharingScopeCurrentMedications.
  ///
  /// In en, this message translates to:
  /// **'Current Medications'**
  String get sharingScopeCurrentMedications;

  /// No description provided for @sharingScopeChronicConditions.
  ///
  /// In en, this message translates to:
  /// **'Diagnoses'**
  String get sharingScopeChronicConditions;

  /// No description provided for @sharingScopeEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get sharingScopeEmergencyContact;

  /// No description provided for @sharingScopeLabResults.
  ///
  /// In en, this message translates to:
  /// **'Lab Results'**
  String get sharingScopeLabResults;

  /// No description provided for @sharingScopeMedicalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Medical Documents'**
  String get sharingScopeMedicalDocuments;

  /// No description provided for @sharingScopeMedicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get sharingScopeMedicalHistory;

  /// No description provided for @editAllergy.
  ///
  /// In en, this message translates to:
  /// **'Edit Allergy'**
  String get editAllergy;

  /// No description provided for @reaction.
  ///
  /// In en, this message translates to:
  /// **'Reaction'**
  String get reaction;

  /// No description provided for @documentAttachment.
  ///
  /// In en, this message translates to:
  /// **'Document attachment'**
  String get documentAttachment;

  /// No description provided for @allergyUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Allergy updated successfully'**
  String get allergyUpdatedSuccessfully;

  /// No description provided for @editDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Edit Diagnosis'**
  String get editDiagnosis;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @diagnosisUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis updated successfully'**
  String get diagnosisUpdatedSuccessfully;

  /// No description provided for @editMedication.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedication;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @medicationUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Medication updated successfully'**
  String get medicationUpdatedSuccessfully;

  /// No description provided for @editVaccination.
  ///
  /// In en, this message translates to:
  /// **'Edit Vaccination'**
  String get editVaccination;

  /// No description provided for @doseDates.
  ///
  /// In en, this message translates to:
  /// **'Dose dates'**
  String get doseDates;

  /// No description provided for @noDatesSelected.
  ///
  /// In en, this message translates to:
  /// **'No dates selected.'**
  String get noDatesSelected;

  /// No description provided for @addDate.
  ///
  /// In en, this message translates to:
  /// **'Add date'**
  String get addDate;

  /// No description provided for @vaccinationUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Vaccination updated successfully'**
  String get vaccinationUpdatedSuccessfully;

  /// No description provided for @documentsExtractionDisabledInSettings.
  ///
  /// In en, this message translates to:
  /// **'Document extraction is disabled in your settings.'**
  String get documentsExtractionDisabledInSettings;

  /// No description provided for @sharingAddShareContactButton.
  ///
  /// In en, this message translates to:
  /// **'Add Share Contact'**
  String get sharingAddShareContactButton;

  /// No description provided for @sharingLinkCreationDisabledInSettings.
  ///
  /// In en, this message translates to:
  /// **'Sharing link creation is disabled in your settings.'**
  String get sharingLinkCreationDisabledInSettings;

  /// No description provided for @sharingMaxActiveLinksReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum of {maxLinks} active sharing links. Revoke one to continue.'**
  String sharingMaxActiveLinksReached(int maxLinks);

  /// No description provided for @sharingPhysicianDisabledInSettings.
  ///
  /// In en, this message translates to:
  /// **'Physician sharing is disabled in your settings.'**
  String get sharingPhysicianDisabledInSettings;

  /// No description provided for @sharingPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing preferences'**
  String get sharingPreferencesTitle;

  /// No description provided for @sharingPreferenceEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get sharingPreferenceEnabled;

  /// No description provided for @sharingPreferenceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get sharingPreferenceDisabled;

  /// No description provided for @sharingPreferencesSummary.
  ///
  /// In en, this message translates to:
  /// **'Emergency: {emergencyStatus} • Physician: {physicianStatus} • Max links: {maxLinks} • Active links: {activeLinks} • Max docs: {maxDocs}'**
  String sharingPreferencesSummary(
    String emergencyStatus,
    String physicianStatus,
    int maxLinks,
    int activeLinks,
    int maxDocs,
  );

  /// No description provided for @sharingManagedByApiConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Managed by API configuration'**
  String get sharingManagedByApiConfiguration;

  /// No description provided for @sharingPendingAccessApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending access approvals'**
  String get sharingPendingAccessApprovalsTitle;

  /// No description provided for @sharingNoPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get sharingNoPendingRequests;

  /// No description provided for @sharingWaitingRequests.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting requests'**
  String sharingWaitingRequests(int count);

  /// No description provided for @sharingDocumentSharingDisabledInSettings.
  ///
  /// In en, this message translates to:
  /// **'Document sharing is disabled in your settings.'**
  String get sharingDocumentSharingDisabledInSettings;

  /// No description provided for @sharingSelectedFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Selected files: {selected}/{max}'**
  String sharingSelectedFilesCount(int selected, int max);

  /// No description provided for @sharingSelectFilesButton.
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get sharingSelectFilesButton;

  /// No description provided for @sharingSelectAtLeastOneMedicalDocument.
  ///
  /// In en, this message translates to:
  /// **'Select at least one file for Medical Documents sharing.'**
  String get sharingSelectAtLeastOneMedicalDocument;

  /// No description provided for @sharingDuration1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get sharingDuration1Hour;

  /// No description provided for @sharingDuration6Hours.
  ///
  /// In en, this message translates to:
  /// **'6 hours'**
  String get sharingDuration6Hours;

  /// No description provided for @sharingDuration12Hours.
  ///
  /// In en, this message translates to:
  /// **'12 hours'**
  String get sharingDuration12Hours;

  /// No description provided for @sharingDuration24Hours.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get sharingDuration24Hours;

  /// No description provided for @sharingDuration3Days.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get sharingDuration3Days;

  /// No description provided for @sharingDuration1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get sharingDuration1Day;

  /// No description provided for @sharingDuration7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get sharingDuration7Days;

  /// No description provided for @sharingDuration30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get sharingDuration30Days;

  /// No description provided for @sharingDuration90Days.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get sharingDuration90Days;

  /// No description provided for @sharingEnterAndConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter and confirm the access password.'**
  String get sharingEnterAndConfirmPassword;

  /// No description provided for @sharingPasswordMinRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long and include letters and numbers.'**
  String get sharingPasswordMinRequirements;

  /// No description provided for @sharingPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Password and confirmation do not match.'**
  String get sharingPasswordMismatch;

  /// No description provided for @sharingAccessPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Access Password'**
  String get sharingAccessPasswordLabel;

  /// No description provided for @sharingConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get sharingConfirmPasswordLabel;

  /// No description provided for @sharingAccessApprovedFor.
  ///
  /// In en, this message translates to:
  /// **'Access approved for {name}.'**
  String sharingAccessApprovedFor(String name);

  /// No description provided for @sharingAccessDeniedFor.
  ///
  /// In en, this message translates to:
  /// **'Access denied for {name}.'**
  String sharingAccessDeniedFor(String name);

  /// No description provided for @sharingUnableToUpdateApprovalRequest.
  ///
  /// In en, this message translates to:
  /// **'Unable to update approval request.'**
  String get sharingUnableToUpdateApprovalRequest;

  /// No description provided for @sharingNoPendingApprovalRequests.
  ///
  /// In en, this message translates to:
  /// **'There are no pending approval requests.'**
  String get sharingNoPendingApprovalRequests;

  /// No description provided for @sharingRequestedLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get sharingRequestedLabel;

  /// No description provided for @sharingIpLabel.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get sharingIpLabel;

  /// No description provided for @sharingShareCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get sharingShareCodeLabel;

  /// No description provided for @sharingApproveButton.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get sharingApproveButton;

  /// No description provided for @sharingDenyButton.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get sharingDenyButton;

  /// No description provided for @sharingCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get sharingCloseButton;

  /// No description provided for @sharingSelectFilesToShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Files to Share'**
  String get sharingSelectFilesToShareTitle;

  /// No description provided for @sharingChooseUpToFilesForLink.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {maxFiles} files for this link'**
  String sharingChooseUpToFilesForLink(int maxFiles);

  /// No description provided for @sharingSearchFilesLabel.
  ///
  /// In en, this message translates to:
  /// **'Search files'**
  String get sharingSearchFilesLabel;

  /// No description provided for @sharingFilterByCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get sharingFilterByCategoryLabel;

  /// No description provided for @sharingAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get sharingAllCategories;

  /// No description provided for @sharingSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected: {selected}/{max}'**
  String sharingSelectedCount(int selected, int max);

  /// No description provided for @sharingNoFilesMatchSearchFilter.
  ///
  /// In en, this message translates to:
  /// **'No files match your search/filter.'**
  String get sharingNoFilesMatchSearchFilter;

  /// No description provided for @sharingApplySelectionButton.
  ///
  /// In en, this message translates to:
  /// **'Apply Selection'**
  String get sharingApplySelectionButton;

  /// No description provided for @sharingLinkCreationDisabledBySystemConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Sharing link creation is disabled by system configuration.'**
  String get sharingLinkCreationDisabledBySystemConfiguration;

  /// No description provided for @sharingReachedMaxActiveLinksInAccessManagement.
  ///
  /// In en, this message translates to:
  /// **'You reached the maximum of {maxLinks} active sharing links. Revoke one in Access Management to create a new link.'**
  String sharingReachedMaxActiveLinksInAccessManagement(int maxLinks);

  /// No description provided for @sharingManageButton.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get sharingManageButton;

  /// No description provided for @notificationsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsPageTitle;

  /// Unread notifications counter
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notificationsUnreadCount(int count);

  /// No description provided for @notificationsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsTabAll;

  /// No description provided for @notificationsTabUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsTabUnread;

  /// No description provided for @notificationsTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get notificationsTabSettings;

  /// No description provided for @notificationsAllEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsAllEmpty;

  /// No description provided for @notificationsUnreadEmpty.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get notificationsUnreadEmpty;

  /// No description provided for @notificationsPushSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get notificationsPushSectionTitle;

  /// No description provided for @notificationsEmailSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get notificationsEmailSectionTitle;

  /// No description provided for @notificationsSettingAccessAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Alerts'**
  String get notificationsSettingAccessAlertsTitle;

  /// No description provided for @notificationsSettingAccessAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'When someone views your records'**
  String get notificationsSettingAccessAlertsDescription;

  /// No description provided for @notificationsSettingShareRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Requests'**
  String get notificationsSettingShareRequestsTitle;

  /// No description provided for @notificationsSettingShareRequestsDescription.
  ///
  /// In en, this message translates to:
  /// **'New provider access requests'**
  String get notificationsSettingShareRequestsDescription;

  /// No description provided for @notificationsSettingSecurityAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Alerts'**
  String get notificationsSettingSecurityAlertsTitle;

  /// No description provided for @notificationsSettingSecurityAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access attempts'**
  String get notificationsSettingSecurityAlertsDescription;

  /// No description provided for @notificationsSettingRecordUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Updates'**
  String get notificationsSettingRecordUpdatesTitle;

  /// No description provided for @notificationsSettingRecordUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Changes to your medical data'**
  String get notificationsSettingRecordUpdatesDescription;

  /// No description provided for @notificationsSettingDailySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get notificationsSettingDailySummaryTitle;

  /// No description provided for @notificationsSettingDailySummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily activity digest'**
  String get notificationsSettingDailySummaryDescription;

  /// No description provided for @notificationsSettingWeeklyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get notificationsSettingWeeklyReportTitle;

  /// No description provided for @notificationsSettingWeeklyReportDescription.
  ///
  /// In en, this message translates to:
  /// **'Weekly access summary'**
  String get notificationsSettingWeeklyReportDescription;

  /// No description provided for @notificationsTypeEmergencyQrAccessedTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency QR Code Accessed'**
  String get notificationsTypeEmergencyQrAccessedTitle;

  /// No description provided for @notificationsTypeEmergencyQrAccessedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your emergency medical information was accessed'**
  String get notificationsTypeEmergencyQrAccessedDescription;

  /// No description provided for @notificationsTypeShareRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'New Share Request'**
  String get notificationsTypeShareRequestTitle;

  /// Share request notification description
  ///
  /// In en, this message translates to:
  /// **'{actor} requested access to your records'**
  String notificationsTypeShareRequestDescription(String actor);

  /// No description provided for @notificationsTypeProfileUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated'**
  String get notificationsTypeProfileUpdatedTitle;

  /// No description provided for @notificationsTypeProfileUpdatedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your medical information was updated'**
  String get notificationsTypeProfileUpdatedDescription;

  /// No description provided for @notificationsTypeProviderAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Access'**
  String get notificationsTypeProviderAccessTitle;

  /// Provider access notification description
  ///
  /// In en, this message translates to:
  /// **'{actor} viewed your test results'**
  String notificationsTypeProviderAccessDescription(String actor);

  /// No description provided for @notificationsTypeMedicationReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminder'**
  String get notificationsTypeMedicationReminderTitle;

  /// No description provided for @notificationsTypeMedicationReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'It is time to take your scheduled medication'**
  String get notificationsTypeMedicationReminderDescription;

  /// No description provided for @notificationsTypeAppointmentAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Alert'**
  String get notificationsTypeAppointmentAlertTitle;

  /// No description provided for @notificationsTypeAppointmentAlertDescription.
  ///
  /// In en, this message translates to:
  /// **'You have an upcoming medical appointment'**
  String get notificationsTypeAppointmentAlertDescription;

  /// No description provided for @notificationsTypeSecurityAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Alert'**
  String get notificationsTypeSecurityAlertTitle;

  /// No description provided for @notificationsTypeSecurityAlertDescription.
  ///
  /// In en, this message translates to:
  /// **'A security-sensitive event was detected'**
  String get notificationsTypeSecurityAlertDescription;

  /// No description provided for @notificationsTypeRecordUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Updated'**
  String get notificationsTypeRecordUpdatedTitle;

  /// No description provided for @notificationsTypeRecordUpdatedDescription.
  ///
  /// In en, this message translates to:
  /// **'One of your shared records was updated'**
  String get notificationsTypeRecordUpdatedDescription;

  /// No description provided for @notificationsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Details'**
  String get notificationsDetailTitle;

  /// No description provided for @notificationsDetailTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get notificationsDetailTypeLabel;

  /// No description provided for @notificationsDetailReceivedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get notificationsDetailReceivedAtLabel;

  /// No description provided for @notificationsDetailStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get notificationsDetailStatusLabel;

  /// No description provided for @notificationsDetailStatusRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationsDetailStatusRead;

  /// No description provided for @notificationsDetailStatusUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsDetailStatusUnread;

  /// No description provided for @notificationsDetailActorLabel.
  ///
  /// In en, this message translates to:
  /// **'Actor'**
  String get notificationsDetailActorLabel;

  /// No description provided for @notificationsDetailLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get notificationsDetailLanguageLabel;

  /// No description provided for @notificationsDetailDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get notificationsDetailDescriptionLabel;

  /// No description provided for @notificationsDetailViewSharingAction.
  ///
  /// In en, this message translates to:
  /// **'View sharing details'**
  String get notificationsDetailViewSharingAction;

  /// No description provided for @notificationsDetailRevokeSharingAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke sharing link'**
  String get notificationsDetailRevokeSharingAction;

  /// No description provided for @notificationsDetailCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get notificationsDetailCloseAction;

  /// No description provided for @notificationsDetailOpenError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open notification details right now.'**
  String get notificationsDetailOpenError;

  /// No description provided for @notificationsDetailRevokeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This notification does not include a sharing link to revoke.'**
  String get notificationsDetailRevokeUnavailable;

  /// No description provided for @notificationsDetailRevokeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sharing link revoked.'**
  String get notificationsDetailRevokeSuccess;

  /// No description provided for @notificationsDetailRevokeError.
  ///
  /// In en, this message translates to:
  /// **'Unable to revoke the sharing link right now.'**
  String get notificationsDetailRevokeError;

  /// No description provided for @notificationsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsJustNow;

  /// Relative minutes timestamp
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String notificationsMinutesAgo(int count);

  /// Relative hours timestamp
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String notificationsHoursAgo(int count);

  /// Relative days timestamp
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String notificationsDaysAgo(int count);

  /// Fallback text when no activity exists
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get noRecentActivity;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ca', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
