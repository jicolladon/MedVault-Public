// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'MedVault';

  @override
  String get welcome => 'Benvingut a MedVault';

  @override
  String get dashboard => 'Tauler';

  @override
  String get contacts => 'Contactes';

  @override
  String get settings => 'Configuració';

  @override
  String get signInWithGoogle => 'Inicia sessió amb Google';

  @override
  String get continueWithoutSignIn => 'Continua sense iniciar sessió';

  @override
  String get error => 'S\'ha produït un error';

  @override
  String get loadingInProgress => 'Carregant, espera si us plau';

  @override
  String get useBiometric => 'Utilitza autenticació biomètrica';

  @override
  String get authenticationRequired => 'Autenticació requerida';

  @override
  String get authenticate => 'Autentica';

  @override
  String get authenticateToOpenContacts => 'Autentica\'t per obrir contactes';

  @override
  String get confirmDisableBiometric =>
      'Confirma la desactivació de l\'autenticació biomètrica';

  @override
  String get signOut => 'Tanca la sessió';

  @override
  String comingSoon(Object feature) {
    return '$feature estarà disponible aviat';
  }

  @override
  String get personalInformation => 'Informació personal';

  @override
  String get changePassword => 'Canvia la contrasenya';

  @override
  String get securityAndPrivacy => 'Seguretat i privacitat';

  @override
  String get activityLog => 'Registre d\'activitat';

  @override
  String get accessManagement => 'Gestió d\'accés';

  @override
  String get notificationsSectionTitle => 'Notificacions';

  @override
  String get legalAndSupport => 'Legal i suport';

  @override
  String get termsOfService => 'Termes del servei';

  @override
  String get privacyPolicy => 'Política de privacitat';

  @override
  String get helpAndSupport => 'Ajuda i suport';

  @override
  String get dangerZone => 'Zona de perill';

  @override
  String get deleteAllData => 'Elimina totes les dades';

  @override
  String get deleteAllDataDialogTitle =>
      'Vols eliminar permanentment totes les teves dades locals?';

  @override
  String get deleteAllDataDialogMessage =>
      'Aquesta acció no es pot desfer. Tots els registres mèdics emmagatzemats localment, configuracions i fitxers en memòria cau s\'eliminaran de manera permanent i no es podran restaurar.';

  @override
  String get deleteAllDataConfirmAction => 'Eliminar permanentment';

  @override
  String get deleteAllDataDeleting => 'Eliminant...';

  @override
  String get deleteAllDataSuccess =>
      'Totes les dades locals s\'han eliminat permanentment.';

  @override
  String get deleteAllDataError =>
      'No hem pogut eliminar les teves dades. Torna-ho a provar.';

  @override
  String get medVaultVersionMvp => 'MedVault v1.0.0 MVP';

  @override
  String get copyrightCompliance => '© 2026 MedVault. Compleix HIPAA i RGPD.';

  @override
  String get profileLoadFailed => 'No s\'ha pogut carregar el perfil';

  @override
  String get demoProfileUpdatedLocally =>
      'Perfil de demostració actualitzat localment';

  @override
  String get profileUpdatedSuccessfully => 'Perfil actualitzat correctament';

  @override
  String get profileSaveFailed => 'No s\'ha pogut desar el perfil';

  @override
  String get addEmergencyContact => 'Afegeix contacte d\'emergència';

  @override
  String get addEmergencyContactSubtitle =>
      'Introdueix les dades del contacte d\'emergència que vols afegir.';

  @override
  String get edit => 'Edita';

  @override
  String get retry => 'Torna-ho a provar';

  @override
  String get camera => 'Càmera';

  @override
  String get selectFromFiles => 'Selecciona des de fitxers';

  @override
  String get unknownUser => 'Usuari desconegut';

  @override
  String get emergencyContact => 'Contacte d\'emergència';

  @override
  String get fullName => 'Nom complet';

  @override
  String get address => 'Adreça';

  @override
  String lastUpdatedOn(Object date) {
    return 'Darrera actualització: $date';
  }

  @override
  String fieldRequired(Object field) {
    return '$field és obligatori';
  }

  @override
  String get enterValidEmailAddress =>
      'Introdueix una adreça de correu electrònic vàlida';

  @override
  String get emergencyContacts => 'Contactes d\'emergència';

  @override
  String get noEmergencyContactsYet =>
      'Encara no s\'han afegit contactes d\'emergència.';

  @override
  String get primary => 'Principal';

  @override
  String get setAsPrimary => 'Defineix com a principal';

  @override
  String get theme => 'Tema';

  @override
  String get darkMode => 'Mode fosc';

  @override
  String get addContact => 'Afegeix contacte';

  @override
  String get name => 'Nom';

  @override
  String get email => 'Correu electrònic';

  @override
  String get relationship => 'Relación';

  @override
  String get relationshipSelectHint => 'Selecciona una relación';

  @override
  String get relationshipRequired => 'La relación es obligatoria';

  @override
  String get relationshipSpouse => 'Cónyuge';

  @override
  String get relationshipParent => 'Padre/Madre';

  @override
  String get relationshipSibling => 'Hermano/a';

  @override
  String get relationshipChild => 'Hijo/a';

  @override
  String get relationshipPartner => 'Pareja';

  @override
  String get relationshipFriend => 'Amigo/a';

  @override
  String get relationshipCaregiver => 'Cuidador';

  @override
  String get relationshipOther => 'Otro';

  @override
  String get phone => 'Telèfon';

  @override
  String get save => 'Desa';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get add => 'Agregar';

  @override
  String get medicalInformation => 'Información médica';

  @override
  String get yourCompleteHealthProfile => 'Tu perfil de salud completo';

  @override
  String get home => 'Inicio';

  @override
  String get allergies => 'Alergias';

  @override
  String get medications => 'Medicamentos';

  @override
  String get vaccinations => 'Vacunaciones';

  @override
  String get diagnoses => 'Diagnósticos';

  @override
  String get labResults => 'Resultados de laboratorio';

  @override
  String get quickSummary => 'Resumen rápido';

  @override
  String get bloodType => 'Tipo de sangre';

  @override
  String get criticialInformation => 'Información crítica';

  @override
  String get recentUpdates => 'Actualizaciones recientes';

  @override
  String get addAllergy => 'Agregar alergia';

  @override
  String get allergiesRecorded => 'alergias registradas';

  @override
  String get allergyName => 'Nombre de la alergia';

  @override
  String get description => 'Descripción';

  @override
  String get severity => 'Severidad';

  @override
  String get critical => 'Crítico';

  @override
  String get markAsCritical => 'Marcar como crítico';

  @override
  String get notes => 'Notas';

  @override
  String get deleteAllergy => '¿Eliminar alergia?';

  @override
  String get areYouSureDelete => '¿Seguro que deseas eliminar';

  @override
  String get delete => 'Eliminar';

  @override
  String get allergyAddedSuccessfully => 'Alergia agregada correctamente';

  @override
  String get allergyDeletedSuccessfully => 'Alergia eliminada correctamente';

  @override
  String get addMedication => 'Agregar medicamento';

  @override
  String get medicationCount => 'medicamentos';

  @override
  String get medicationName => 'Nombre del medicamento';

  @override
  String get dosage => 'Dosis';

  @override
  String get frequency => 'Frecuencia';

  @override
  String get egOnceDaily => 'p. ej., una vez al día';

  @override
  String get reasonForMedication => 'Motivo del medicamento';

  @override
  String get medicationAddedSuccessfully =>
      'Medicamento agregado correctamente';

  @override
  String get medicationDeletedSuccessfully =>
      'Medicamento eliminado correctamente';

  @override
  String get addVaccination => 'Agregar vacuna';

  @override
  String get vaccinationCount => 'vacunas';

  @override
  String get vaccineName => 'Nombre de la vacuna';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get provider => 'Proveedor';

  @override
  String get batchNumber => 'Número de lote';

  @override
  String get vaccinationAddedSuccessfully => 'Vacuna agregada correctamente';

  @override
  String get vaccinationDeletedSuccessfully => 'Vacuna eliminada correctamente';

  @override
  String get addDiagnosis => 'Agregar diagnóstico';

  @override
  String get diagnosesRecorded => 'diagnósticos registrados';

  @override
  String get diagnosisName => 'Nombre del diagnóstico';

  @override
  String get status => 'Estado';

  @override
  String get treatmentPlan => 'Plan de tratamiento';

  @override
  String get diagnosisAddedSuccessfully => 'Diagnóstico agregado correctamente';

  @override
  String get diagnosisDeletedSuccessfully =>
      'Diagnóstico eliminado correctamente';

  @override
  String get addLabResult => 'Agregar resultado';

  @override
  String get labResultsAvailable => 'resultados disponibles';

  @override
  String get testName => 'Nombre del examen';

  @override
  String get category => 'Categoría';

  @override
  String get doctorInterpretation => 'Interpretación del médico';

  @override
  String get labResultAddedSuccessfully =>
      'Resultado de laboratorio agregado correctamente';

  @override
  String get labResultDeletedSuccessfully =>
      'Resultado de laboratorio eliminado correctamente';

  @override
  String get normal => 'Normal';

  @override
  String get abnormal => 'Anormal';

  @override
  String get pending => 'Pendiente';

  @override
  String get completedBloodCount => 'Biometría hemática completa';

  @override
  String get covidBooster => 'Refuerzo COVID-19';

  @override
  String get added => 'Agregado';

  @override
  String get received => 'Recibido';

  @override
  String get penicillin => 'Penicilina';

  @override
  String get severeAllergicReaction => 'Reacción alérgica grave';

  @override
  String get peanuts => 'Maní';

  @override
  String get mildRash => 'Sarpullido leve';

  @override
  String get lisinopril => 'Lisinopril';

  @override
  String get metformin => 'Metformina';

  @override
  String get flueShot => 'Vacuna contra la gripe';

  @override
  String get high => 'Alto';

  @override
  String get medium => 'Medio';

  @override
  String get low => 'Bajo';

  @override
  String get noDescription => 'Sin descripción';

  @override
  String get areYouSureYouWantToDelete => '¿Seguro que deseas eliminar';

  @override
  String get active => 'Activo';

  @override
  String get chronic => 'Crónico';

  @override
  String get resolved => 'Resuelto';

  @override
  String get expired => 'Expirado';

  @override
  String get condition => 'Condición';

  @override
  String get diagnosedBy => 'Diagnosticado por';

  @override
  String get date => 'Fecha';

  @override
  String get deleteDiagnosis => '¿Eliminar diagnóstico?';

  @override
  String get lab => 'Laboratorio';

  @override
  String get testDate => 'Fecha del examen';

  @override
  String get medicationsRecorded => 'medicamentos registrados';

  @override
  String get reason => 'Motivo';

  @override
  String get prescribedBy => 'Recetado por';

  @override
  String get deleteMedication => '¿Eliminar medicamento?';

  @override
  String get vaccinationsRecorded => 'vacunaciones registradas';

  @override
  String get nextDue => 'Próxima dosis';

  @override
  String get deleteVaccination => '¿Eliminar vacunación?';

  @override
  String get labResultsRecorded => 'resultados de laboratorio registrados';

  @override
  String get editBloodType => 'Editar tipo de sangre';

  @override
  String get authSignInFailed => 'Error al iniciar sesión';

  @override
  String get authEmailSignInFailed => 'Error al iniciar sesión con correo';

  @override
  String get authEmailRegistrationFailed => 'Error al registrar con correo';

  @override
  String get authCreateAccountWithEmail => 'Crear cuenta con correo';

  @override
  String get authSignInWithEmail => 'Iniciar sesión con correo';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authFirstName => 'Nombre';

  @override
  String get authLastName => 'Apellido';

  @override
  String get authAcceptTermsOfService => 'Acepto los Términos del servicio';

  @override
  String get authAcceptPrivacyPolicy => 'Acepto la Política de privacidad';

  @override
  String get authRegister => 'Registrar';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authSecureMedicalRecordsVault =>
      'Tu bóveda segura de registros médicos';

  @override
  String get authHipaaGdprCompliant => 'Compatible con HIPAA y GDPR';

  @override
  String get authDataEncryptedSecure => 'Tus datos están cifrados y seguros';

  @override
  String get authEndToEndEncryption => 'Cifrado de extremo a extremo';

  @override
  String get authOnlyYouControlRecords =>
      'Solo tú controlas el acceso a tus registros';

  @override
  String get authSigningInDemo => 'Iniciando sesión en demo...';

  @override
  String get authSigningIn => 'Iniciando sesión...';

  @override
  String get authContinueWithDemoGoogle => 'Continuar con Google Demo';

  @override
  String get authDateOfBirthRequired =>
      'La fecha de nacimiento es obligatoria.';

  @override
  String get authAcceptTermsPrivacyRequired =>
      'Debes aceptar los términos y la política de privacidad.';

  @override
  String get authPolicyAcknowledge => 'He leído y entiendo';

  @override
  String get authPolicyScrollHint =>
      'Desplázate hasta el final para habilitar la confirmación.';

  @override
  String get authRegistrationFailedTryAgain =>
      'El registro falló. Inténtalo de nuevo.';

  @override
  String get authRegistrationCompletedSuccessfully =>
      'Registro completado con éxito.';

  @override
  String get authCompleteRegistration => 'Completar registro';

  @override
  String get authRequiredField => 'Obligatorio';

  @override
  String get authDateOfBirth => 'Fecha de nacimiento';

  @override
  String get authGender => 'Género';

  @override
  String get authGenderMale => 'Masculino';

  @override
  String get authGenderFemale => 'Femenino';

  @override
  String get authGenderOther => 'Otro';

  @override
  String get authGenderPreferNotToSay => 'Prefiero no decirlo';

  @override
  String get authPhoneNumber => 'Número de teléfono';

  @override
  String get onboardingErrorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get onboardingStepBiometricTitle =>
      'Habilitar autenticación biométrica';

  @override
  String get onboardingStepNotificationsTitle => 'Notificaciones';

  @override
  String get onboardingStepCloudTitle => 'Respaldo en la nube';

  @override
  String get onboardingStepMedicalTitle => 'Información médica';

  @override
  String get onboardingStepBiometricSubtitle =>
      'Usa la autenticación biométrica para proteger tus datos de salud.';

  @override
  String get onboardingStepNotificationsSubtitle => 'Mantente informado';

  @override
  String get onboardingStepCloudSubtitle => 'Mantén tus datos seguros';

  @override
  String get onboardingStepMedicalSubtitle => 'Perfil de salud básico';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingBack => 'Atrás';

  @override
  String get onboardingGetStarted => 'Comenzar';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingBiometricDescription =>
      'Protege tus datos de salud con autenticación biométrica.';

  @override
  String get onboardingEnableBiometricLock => 'Autenticación biométrica';

  @override
  String get onboardingBiometricEnabled => 'Activado';

  @override
  String get onboardingBiometricDisabled => 'Desactivado';

  @override
  String get onboardingBiometricFaster => 'Más rápido y seguro';

  @override
  String get onboardingBiometricCheck1 =>
      'Tus datos biométricos nunca salen de tu dispositivo';

  @override
  String get onboardingBiometricCheck2 => 'Añade una capa extra de seguridad';

  @override
  String get onboardingBiometricCheck3 =>
      'Puedes cambiar esto en la configuración';

  @override
  String get onboardingBiometricType => 'Tipo de biometría';

  @override
  String get onboardingBiometricFingerprint => 'Huella dactilar';

  @override
  String get onboardingBiometricFace => 'Reconocimiento facial';

  @override
  String get onboardingBiometricIris => 'Escaneo de iris';

  @override
  String get biometricUnavailableTitle =>
      'Inicio de sesión biométrico no disponible';

  @override
  String get biometricUnavailableNoHardware =>
      'Este dispositivo no admite autenticación biométrica.';

  @override
  String get biometricUnavailableNotEnrolled =>
      'No hay datos biométricos configurados en este dispositivo.';

  @override
  String get biometricUnavailableUnknown =>
      'No se pudo verificar la disponibilidad biométrica en este dispositivo.';

  @override
  String get onboardingNotificationsDescription =>
      'Elige qué notificaciones deseas recibir.';

  @override
  String get onboardingPushNotifications => 'Notificaciones push';

  @override
  String get onboardingPushNotificationsSubtext =>
      'Recibe notificaciones sobre eventos de acceso';

  @override
  String get onboardingNotifyWhen => 'Serás notificado cuando:';

  @override
  String get onboardingNotifyReasonQR =>
      'Alguien acceda a tu código QR de emergencia';

  @override
  String get onboardingNotifyReasonShared =>
      'Un proveedor vea tus registros compartidos';

  @override
  String get onboardingNotifyReasonSecurity =>
      'Ocurran eventos de seguridad importantes';

  @override
  String get onboardingEmailNotifications => 'Notificaciones por correo';

  @override
  String get onboardingMedicalReminders => 'Recordatorios médicos';

  @override
  String get onboardingAppointmentAlerts => 'Alertas de citas';

  @override
  String get onboardingSecurityAlerts => 'Alertas de seguridad';

  @override
  String get onboardingCloudDescription =>
      'Respalda tus registros médicos en la nube.';

  @override
  String get onboardingBackupProvider => 'Proveedor de respaldo';

  @override
  String get onboardingProviderMedVault => 'Nube MedVault';

  @override
  String get onboardingProviderGoogleDrive => 'Google Drive';

  @override
  String get onboardingProviderICloud => 'iCloud';

  @override
  String get onboardingAutoBackup => 'Respaldo automático';

  @override
  String get onboardingAutoBackupSubtitle =>
      'Respaldar cambios automáticamente';

  @override
  String get onboardingMedicalInfoDescription =>
      'Proporciona información médica básica. Puedes agregar más detalles después.';

  @override
  String get onboardingSubstance => 'Sustancia';

  @override
  String get onboardingUnknown => 'Desconocido';

  @override
  String get onboardingOnceDaily => 'Una vez al día';

  @override
  String get emergencyAccess => 'Acceso de Emergencia';

  @override
  String get shareCriticalInfoInstantly =>
      'Comparte información crítica al instante';

  @override
  String get emergencySharingDisabledInSettings =>
      'La compartición de emergencia está deshabilitada en configuración.';

  @override
  String get medicalInfo => 'Info Médica';

  @override
  String get viewAll => 'Ver Todo';

  @override
  String get meds => 'Medicamentos';

  @override
  String get vaccines => 'Vacunas';

  @override
  String get notSignedIn => 'No has iniciado sesión';

  @override
  String get account => 'Cuenta';

  @override
  String get profile => 'Perfil';

  @override
  String get dashboardSubtitle => 'Tu panel de salud';

  @override
  String get criticalAllergy => 'Alergia crítica';

  @override
  String get noCriticalAllergies => 'No hay alergias críticas';

  @override
  String get totalTests => 'Pruebas totales';

  @override
  String get flagged => 'Marcadas';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get yourDataIsSecure => 'Tus datos están seguros';

  @override
  String get dashboardSecurityDescription =>
      'Todos los registros están cifrados de extremo a extremo. Solo tú controlas el acceso.';

  @override
  String get documents => 'Documentos';

  @override
  String get share => 'Compartir';

  @override
  String get alerts => 'Alertas';

  @override
  String get quickActions => 'Acciones rápidas';

  @override
  String get addNewDocument => 'Agregar documento';

  @override
  String get addNewLabResult => 'Agregar resultado de laboratorio';

  @override
  String get documentCreatedSuccessfully => 'Documento creado correctamente';

  @override
  String get documentsUpdatedSuccessfully =>
      'Documento actualizado correctamente';

  @override
  String get documentsDeletedSuccessfully =>
      'Documento eliminado correctamente';

  @override
  String get documentsSearchPlaceholder => 'Buscar documentos';

  @override
  String get documentsEmptyTitle => 'Aún no hay documentos';

  @override
  String get documentsEmptySubtitle =>
      'Sube tu primer documento médico para comenzar.';

  @override
  String get documentsSelectSourceTitle => 'Selecciona el origen del documento';

  @override
  String get documentsFromGallery => 'Galería';

  @override
  String get documentsUploadFailed => 'No se pudo cargar el archivo';

  @override
  String get documentsSaveFailed => 'No se pudo guardar el documento';

  @override
  String get documentsDeleteDialogTitle => '¿Eliminar documento?';

  @override
  String documentsDeleteDialogMessage(String title) {
    return '¿Seguro que deseas eliminar $title?';
  }

  @override
  String get documentsOpenWithApp => 'Abrir con otra app';

  @override
  String get documentsOpenFailed => 'No se pudo abrir el documento';

  @override
  String get documentsShareFailed => 'No se pudo compartir el documento';

  @override
  String get documentsAddDetailsTitle => 'Detalles del documento';

  @override
  String get documentsEditDetailsTitle => 'Editar detalles del documento';

  @override
  String get documentsNoDateSelected => 'Sin fecha seleccionada';

  @override
  String get documentsExtractDataButton => 'Extraer datos';

  @override
  String get documentsSaveBeforeExtraction =>
      'Guarda primero el documento para extraer datos';

  @override
  String get documentsExtractionUnavailableInDemo =>
      'Extraer datos no está disponible en modo demo';

  @override
  String get documentsExtractionNotReady =>
      'La extracción de datos aún no está conectada';

  @override
  String get documentsExtractionFailed =>
      'No se pudieron extraer los datos del documento';

  @override
  String get documentsAtLeastOneFileRequired =>
      'Debe haber al menos un archivo';

  @override
  String get documentsAddFileButton => 'Agregar archivos';

  @override
  String get documentsRemoveSelectedFileButton =>
      'Eliminar archivo seleccionado';

  @override
  String documentsFilesCount(int count) {
    return '$count archivos';
  }

  @override
  String documentsMaxFilesSelectionLimit(int maxFiles) {
    return 'Puedes seleccionar hasta $maxFiles archivos por documento.';
  }

  @override
  String documentsMaxFilesReached(int maxFiles) {
    return 'Este documento ya tiene el maximo de $maxFiles archivos.';
  }

  @override
  String documentsMaxFilesRemaining(int availableSlots, int maxFiles) {
    return 'Solo puedes agregar $availableSlots archivos mas. Maximo: $maxFiles por documento.';
  }

  @override
  String get documentsCategoryLabel => 'Categoría';

  @override
  String get documentsTagsLabel => 'Etiquetas';

  @override
  String get documentsTagsHint => 'Escribe una etiqueta y pulsa +';

  @override
  String get documentsTypePdf => 'PDF';

  @override
  String get documentsTypeImage => 'Imagen';

  @override
  String get documentsTypeDocx => 'DOCX';

  @override
  String get documentsTypeXlsx => 'XLSX';

  @override
  String get documentsTypeOther => 'Otro';

  @override
  String get documentsCategoryLabResults => 'Resultados de laboratorio';

  @override
  String get documentsCategoryMedicalReport => 'Informe médico';

  @override
  String get documentsCategoryMedicationReport => 'Informe de medicación';

  @override
  String get documentsCategoryVaccinations => 'Vacunación';

  @override
  String get documentsCategoryOther => 'Otro';

  @override
  String get labTestResultCreatedSuccessfully =>
      'Resultado de laboratorio creado correctamente';

  @override
  String get noLabResults => 'Aún no hay resultados de laboratorio';

  @override
  String get labResultsAll => 'Todas';

  @override
  String get searchLabResults => 'Buscar resultados de laboratorio';

  @override
  String get noMatchingLabResults =>
      'No hay resultados de laboratorio que coincidan';

  @override
  String get addLabResultTitle => 'Agregar resultado de laboratorio';

  @override
  String get editLabResultTitle => 'Editar resultado de laboratorio';

  @override
  String get labResultDetails => 'Detalles del resultado';

  @override
  String get addLabResultType => 'Agregar tipo de resultado';

  @override
  String get removeLabResultType => 'Eliminar tipo de resultado';

  @override
  String get removeLabResultTypeConfirmation =>
      '¿Eliminar esta categoría personalizada de tu lista?';

  @override
  String get deleteLabResultTitle => '¿Eliminar resultado?';

  @override
  String deleteLabResultConfirmation(String testName) {
    return '¿Seguro que quieres eliminar $testName?';
  }

  @override
  String get labResultUpdatedSuccessfully =>
      'Resultado de laboratorio actualizado correctamente';

  @override
  String get labResultTypeRemovedSuccessfully =>
      'El tipo de resultado de laboratorio se eliminó correctamente';

  @override
  String get updated => 'Actualizado';

  @override
  String get attachments => 'Adjuntos';

  @override
  String get labResultTypeInUseCannotRemove =>
      'Esta categoría ya se usa en un resultado de laboratorio.';

  @override
  String get chooseHowToAddYourLabResults =>
      'Elige cómo quieres agregar tus resultados de laboratorio.';

  @override
  String get labResultsAddDescription =>
      'Puedes ingresarlos manualmente o subir un documento para extraerlos automáticamente.';

  @override
  String get manualEntry => 'Entrada manual';

  @override
  String get manualEntryDetails =>
      'Agrega valores de prueba individuales\nControl total sobre la captura de datos\nIdeal para resultados únicos';

  @override
  String get uploadAndExtract => 'Subir y extraer';

  @override
  String get uploadAndExtractDetails =>
      'Extracción de datos con IA\nSube archivos PDF o imágenes\nMás rápido para múltiples valores';

  @override
  String get testInformation => 'Información de la prueba';

  @override
  String get testValues => 'Valores de la prueba';

  @override
  String get labValueNameHint => 'Nombre (p. ej., hemoglobina)';

  @override
  String get yourValue => 'Tu valor';

  @override
  String get valueLabel => 'Valor';

  @override
  String get unit => 'Unidad';

  @override
  String get minimum => 'Mín';

  @override
  String get maximum => 'Máx';

  @override
  String get interpretationAndNotes => 'Interpretación y notas';

  @override
  String get uploadLabReport => 'Subir informe de laboratorio';

  @override
  String get selectCategory => 'Selecciona una categoría';

  @override
  String get addValue => 'Agregar valor';

  @override
  String get referenceRangeOptional => 'Rango de referencia (opcional)';

  @override
  String get saveResult => 'Guardar resultado';

  @override
  String get labResultTypeCreatedSuccessfully =>
      'El tipo de resultado de laboratorio se creó correctamente';

  @override
  String get labCategoryCompleteBloodCountLabel =>
      'Biometría hemática completa (CBC)';

  @override
  String get labCategoryCompleteBloodCountDescription =>
      'Revisa tus células sanguíneas.';

  @override
  String get labCategoryMetabolicPanelsLabel =>
      'Paneles metabólicos (BMP o CMP)';

  @override
  String get labCategoryMetabolicPanelsDescription =>
      'Revisa el funcionamiento de los órganos y la química de la sangre.';

  @override
  String get labCategoryLipidPanelLabel => 'Perfil lipídico';

  @override
  String get labCategoryLipidPanelDescription =>
      'Revisa la salud del corazón y las grasas.';

  @override
  String get labCategoryThyroidPanelLabel => 'Panel tiroideo';

  @override
  String get labCategoryThyroidPanelDescription =>
      'Revisa tu regulador del metabolismo.';

  @override
  String get labCategoryDiabetesMonitoringLabel => 'Seguimiento de diabetes';

  @override
  String get labCategoryDiabetesMonitoringDescription =>
      'Controla el azúcar a largo plazo.';

  @override
  String get labCategoryHemoglobinA1cLabel => 'Hemoglobina A1c';

  @override
  String get labCategoryHemoglobinA1cDescription =>
      'Tu promedio de azúcar en sangre de los últimos 3 meses.';

  @override
  String get labCategoryUrinalysisLabel => 'Análisis de orina';

  @override
  String get labCategoryUrinalysisDescription =>
      'Revisa la eliminación de desechos.';

  @override
  String get labCategoryNutrientLevelsLabel => 'Niveles de nutrientes';

  @override
  String get labCategoryNutrientLevelsDescription =>
      'Revisa si hay deficiencias.';

  @override
  String get sharingAndCollaborationTitle => 'Compartir y colaboración';

  @override
  String get sharingManageDataAccessSubtitle =>
      'Administra el acceso a los datos';

  @override
  String get sharingEmergencyQrTitle => 'QR de emergencia';

  @override
  String get sharingQuickAccessSubtitle => 'Acceso rápido';

  @override
  String get sharingWithPhysicianTitle => 'Compartir con médico';

  @override
  String get sharingWithPhysicianSubtitle => 'Acceso seguro para proveedores';

  @override
  String get sharingSecureSharingSubtitle => 'Compartición segura';

  @override
  String get sharingActiveSharesTitle => 'Comparticiones activas';

  @override
  String get sharingNoActiveSharesMessage =>
      'Aún no hay enlaces de compartición activos.';

  @override
  String get sharingManageAccessTitle => 'Administrar acceso';

  @override
  String get sharingAccessManagementLabel => 'Gestión de acceso';

  @override
  String get sharingActivityLogLabel => 'Registro de actividad';

  @override
  String get sharingPrivacyCardTitle => 'Tu control, tu privacidad';

  @override
  String get sharingPrivacyCardDescription =>
      'Mantienes el control total de quién puede acceder a tus registros médicos. Todo acceso se registra y puede revocarse en cualquier momento.';

  @override
  String get sharingExpiresLabel => 'Expira';

  @override
  String get sharingEmergencyTypeLabel => 'Emergencia';

  @override
  String get sharingPhysicianTypeLabel => 'Médico';

  @override
  String get sharingEmergencySharingTitle => 'Compartición de emergencia';

  @override
  String get sharingEmergencySharingSubtitle =>
      'Acceso rápido para personal de primera respuesta';

  @override
  String get sharingEmergencyWarningBody =>
      'Cualquiera con el código o QR puede acceder a los datos seleccionados. Compártelo solo en emergencias. Todo acceso se registra y recibirás notificaciones.';

  @override
  String get sharingSelectInformationTitle =>
      'Seleccionar información para compartir';

  @override
  String get sharingEmergencySelectInformationSubtitle =>
      'Elige qué pueden ver los equipos de emergencia';

  @override
  String get sharingCriticalBadge => 'Crítico';

  @override
  String get sharingRecommendedBadge => 'Recomendado';

  @override
  String get sharingContinueButton => 'Continuar';

  @override
  String get sharingEmergencySecurityTitle => 'Configuración de seguridad';

  @override
  String get sharingEmergencySecuritySubtitle =>
      'Configura la duración del enlace de emergencia';

  @override
  String get sharingAccessDurationTitle => 'Duración del acceso';

  @override
  String get sharingEmergencyDurationQuestion =>
      '¿Cuánto tiempo debe ser válido el código de emergencia?';

  @override
  String get sharingDataSummaryTitle => 'Resumen de datos';

  @override
  String get sharingDataSummarySubtitle => 'Información que estará accesible';

  @override
  String get sharingPrivacySecurityTitle => 'Privacidad y seguridad';

  @override
  String get sharingSecurityBulletLogged =>
      'Todos los intentos de acceso se registran';

  @override
  String get sharingSecurityBulletNotified =>
      'Recibirás notificaciones instantáneas';

  @override
  String get sharingSecurityBulletRevoke =>
      'Puedes revocar el acceso en cualquier momento';

  @override
  String get sharingSecurityBulletExpires => 'El código expira automáticamente';

  @override
  String get sharingGenerateEmergencyCodeButton =>
      'Generar código de emergencia';

  @override
  String get sharingGeneratingCodeButton => 'Generando código...';

  @override
  String get sharingEmergencyCodeActiveTitle => 'Código de emergencia activo';

  @override
  String get sharingEmergencyAccessActiveLabel =>
      'El acceso de emergencia está activo';

  @override
  String get sharingExpiresInLabel => 'Expira en';

  @override
  String get sharingScanQrCodeTitle => 'Escanear código QR';

  @override
  String get sharingScanQrCodeSubtitle =>
      'Los equipos de primera respuesta pueden escanearlo para acceder a tu información';

  @override
  String get sharingUseCodeTitle => 'O usa el código';

  @override
  String get sharingEmergencyAccessCodeLabel =>
      'Código de acceso de emergencia';

  @override
  String get sharingVisitAndEnterCodeText => 'Visita:';

  @override
  String get sharingDownloadQrButton => 'Descargar QR';

  @override
  String get sharingDownloadPngButton => 'Descargar PNG';

  @override
  String get sharingDownloadJpgButton => 'Descargar JPG';

  @override
  String sharingQrDownloadedMessage(Object format) {
    return 'Código QR descargado como $format';
  }

  @override
  String get sharingDownloadFailedMessage => 'Error al descargar el código QR';

  @override
  String get sharingShareButton => 'Compartir';

  @override
  String get sharingDownloadNotImplementedMessage =>
      'La descarga estará disponible en una próxima actualización.';

  @override
  String get sharingLinkCopiedMessage => 'Enlace copiado.';

  @override
  String get sharingEmergencyNotificationInfo =>
      'Recibirás una notificación cada vez que alguien acceda a tu información de emergencia.';

  @override
  String get sharingRevokeEmergencyAccessButton =>
      'Revocar acceso de emergencia';

  @override
  String get sharingPhysicianInformationTitle => 'Información del médico';

  @override
  String get sharingPhysicianNameLabel => 'Nombre del médico *';

  @override
  String get sharingPhysicianEmailLabel => 'Correo electrónico (opcional)';

  @override
  String get sharingPhysicianEmailHelpText =>
      'Opcional. Agrega un correo para incluir el contacto del medico en el registro compartido.';

  @override
  String get sharingNotesOptionalLabel => 'Notas (opcional)';

  @override
  String get sharingSelectDataToShareTitle =>
      'Seleccionar datos para compartir';

  @override
  String get sharingSelectDataToShareSubtitle =>
      'Elige qué puede ver el médico';

  @override
  String get sharingPhysicianValidationMessage =>
      'Ingresa un nombre válido del médico. Si agregas correo, debe ser válido.';

  @override
  String get sharingContinueToSecuritySettingsButton =>
      'Continuar a configuración de seguridad';

  @override
  String get sharingSecuritySettingsTitle => 'Configuración de seguridad';

  @override
  String get sharingPasswordProtectedLabel => 'Protegido con contraseña';

  @override
  String get sharingTwoFactorRequiredLabel => 'Requiere aprobación de 2FA';

  @override
  String get sharingTwoFactorApprovalDescription =>
      'Cuando está habilitado, el acceso permanecerá pendiente hasta que lo apruebes o rechaces en la aplicación.';

  @override
  String get sharingAllowDownloadLabel => 'Permitir descarga';

  @override
  String get sharingPasswordConstraintsHelpText =>
      'Usa al menos 8 caracteres con letras y números. Comparte la contraseña de forma segura con el médico.';

  @override
  String get sharingReviewAndConfirmTitle => 'Revisar y confirmar';

  @override
  String get sharingWithLabel => 'Compartiendo con';

  @override
  String get sharingPatientLabel => 'Paciente';

  @override
  String get sharingDataBeingSharedTitle => 'Datos compartidos';

  @override
  String get sharingAccessDurationLabel => 'Duración del acceso';

  @override
  String get sharingYesLabel => 'Sí';

  @override
  String get sharingNoLabel => 'No';

  @override
  String get sharingConsentStatement =>
      'Confirmo que doy mi consentimiento para compartir mi información médica y entiendo que todo acceso quedará registrado y podrá revocarse en cualquier momento.';

  @override
  String get sharingConfirmAndSendButton => 'Confirmar y enviar enlace';

  @override
  String get sharingSendingLinkButton => 'Enviando enlace...';

  @override
  String get sharingConfirmationDialogTitle => 'Confirmar compartición';

  @override
  String get sharingConfirmationDialogMessage =>
      '¿Crear y enviar el enlace seguro a este médico?';

  @override
  String get sharingConfirmButton => 'Confirmar';

  @override
  String get sharingPhysicianEmailSubject =>
      'Compartición segura de información médica de MedVault';

  @override
  String get sharingPhysicianEmailBodyIntro =>
      'Por favor usa este enlace seguro de MedVault para revisar mi información médica compartida.';

  @override
  String get sharingPhysicianEmailBodyInstructions =>
      'Este enlace tiene tiempo limitado y está destinado para compartición médica segura.';

  @override
  String get sharingEmailOpenedMessage =>
      'Se abrieron las opciones para compartir.';

  @override
  String get sharingEmailFallbackCopiedMessage =>
      'No se pudieron abrir las opciones para compartir. El enlace se copió al portapapeles.';

  @override
  String get sharingLinkCreatedDialogTitle => 'Enlace creado';

  @override
  String get sharingLinkCreatedDialogMessage =>
      'Tu enlace seguro está listo y ya se puede compartir.';

  @override
  String get sharingCopyLinkButton => 'Copiar enlace';

  @override
  String get sharingDoneButton => 'Listo';

  @override
  String get sharingAccessManagementTitle => 'Gestión de acceso';

  @override
  String get sharingSummaryActiveLabel => 'Activos';

  @override
  String get sharingSummaryUsedLabel => 'Usados';

  @override
  String get sharingSummaryExpiredLabel => 'Expirados';

  @override
  String get sharingNoAccessGrantsMessage =>
      'No hay permisos de acceso disponibles.';

  @override
  String get sharingGrantedLabel => 'Otorgado';

  @override
  String get sharingLastAccessLabel => 'Último';

  @override
  String get sharingNeverLabel => 'Nunca';

  @override
  String get sharingPermissionsLabel => 'Permisos';

  @override
  String get sharingEditButton => 'Editar';

  @override
  String get sharingRevokeAccessButton => 'Revocar acceso';

  @override
  String get sharingEditPermissionsTitle => 'Editar permisos';

  @override
  String get sharingActivityLogTitle => 'Registro de actividad';

  @override
  String get sharingActivityLogSubtitle => 'Eventos de acceso y seguridad';

  @override
  String get sharingAllEventsFilter => 'Todos los eventos';

  @override
  String get sharingAccessEventsFilter => 'Eventos de acceso';

  @override
  String get sharingHighRiskFilter => 'Alto riesgo';

  @override
  String get sharingSummaryAccessLabel => 'Accesos';

  @override
  String get sharingSummaryHighRiskLabel => 'Alto riesgo';

  @override
  String get sharingSummaryPeriodLabel => 'Período';

  @override
  String get sharingSummaryPeriodValue => '7d';

  @override
  String get sharingActivityTimelineTitle => 'Línea de tiempo';

  @override
  String get sharingNoActivityEventsMessage =>
      'No hay eventos para este filtro.';

  @override
  String get sharingExportComplianceTitle => 'Exportación y cumplimiento';

  @override
  String get sharingExportActivityPdfButton => 'Exportar registro (PDF)';

  @override
  String get sharingExportGdprButton => 'Informe de portabilidad GDPR';

  @override
  String get sharingExportPdfNotReadyMessage =>
      'La exportación PDF se conectará en una futura versión.';

  @override
  String get sharingGdprExportNotReadyMessage =>
      'La exportación GDPR se conectará en una futura versión.';

  @override
  String get sharingScopePersonalInformation => 'Información personal';

  @override
  String get sharingScopeMedicalInformation => 'Información médica';

  @override
  String get sharingScopeBloodType => 'Tipo de sangre';

  @override
  String get sharingScopeAllergies => 'Alergias';

  @override
  String get sharingScopeCurrentMedications => 'Medicamentos actuales';

  @override
  String get sharingScopeChronicConditions => 'Diagnósticos';

  @override
  String get sharingScopeEmergencyContact => 'Contacto de emergencia';

  @override
  String get sharingScopeLabResults => 'Resultados de laboratorio';

  @override
  String get sharingScopeMedicalDocuments => 'Documentos médicos';

  @override
  String get sharingScopeMedicalHistory => 'Historial médico';

  @override
  String get editAllergy => 'Editar alergia';

  @override
  String get reaction => 'Reacción';

  @override
  String get documentAttachment => 'Adjunto de documento';

  @override
  String get allergyUpdatedSuccessfully => 'Alergia actualizada correctamente';

  @override
  String get editDiagnosis => 'Editar diagnóstico';

  @override
  String get duration => 'Duración';

  @override
  String get diagnosisUpdatedSuccessfully =>
      'Diagnóstico actualizado correctamente';

  @override
  String get editMedication => 'Editar medicamento';

  @override
  String get startDate => 'Fecha de inicio';

  @override
  String get endDate => 'Fecha de fin';

  @override
  String get medicationUpdatedSuccessfully =>
      'Medicamento actualizado correctamente';

  @override
  String get editVaccination => 'Editar vacunación';

  @override
  String get doseDates => 'Fechas de dosis';

  @override
  String get noDatesSelected => 'No hay fechas seleccionadas.';

  @override
  String get addDate => 'Agregar fecha';

  @override
  String get vaccinationUpdatedSuccessfully =>
      'Vacunación actualizada correctamente';

  @override
  String get documentsExtractionDisabledInSettings =>
      'La extracción de documentos está deshabilitada en tu configuración.';

  @override
  String get sharingAddShareContactButton => 'Agregar contacto para compartir';

  @override
  String get sharingLinkCreationDisabledInSettings =>
      'La creación de enlaces para compartir está deshabilitada en tu configuración.';

  @override
  String sharingMaxActiveLinksReached(int maxLinks) {
    return 'Has alcanzado el máximo de $maxLinks enlaces de compartición activos. Revoca uno para continuar.';
  }

  @override
  String get sharingPhysicianDisabledInSettings =>
      'La compartición con médicos está deshabilitada en tu configuración.';

  @override
  String get sharingPreferencesTitle => 'Preferencias de compartición';

  @override
  String get sharingPreferenceEnabled => 'Activado';

  @override
  String get sharingPreferenceDisabled => 'Desactivado';

  @override
  String sharingPreferencesSummary(
    String emergencyStatus,
    String physicianStatus,
    int maxLinks,
    int activeLinks,
    int maxDocs,
  ) {
    return 'Emergencia: $emergencyStatus • Médico: $physicianStatus • Máx enlaces: $maxLinks • Enlaces activos: $activeLinks • Máx docs: $maxDocs';
  }

  @override
  String get sharingManagedByApiConfiguration =>
      'Administrado por la configuración de la API';

  @override
  String get sharingPendingAccessApprovalsTitle =>
      'Aprobaciones de acceso pendientes';

  @override
  String get sharingNoPendingRequests => 'No hay solicitudes pendientes';

  @override
  String sharingWaitingRequests(int count) {
    return '$count solicitudes en espera';
  }

  @override
  String get sharingDocumentSharingDisabledInSettings =>
      'La compartición de documentos está deshabilitada en tu configuración.';

  @override
  String sharingSelectedFilesCount(int selected, int max) {
    return 'Archivos seleccionados: $selected/$max';
  }

  @override
  String get sharingSelectFilesButton => 'Seleccionar archivos';

  @override
  String get sharingSelectAtLeastOneMedicalDocument =>
      'Selecciona al menos un archivo para compartir documentos médicos.';

  @override
  String get sharingDuration1Hour => '1 hora';

  @override
  String get sharingDuration6Hours => '6 horas';

  @override
  String get sharingDuration12Hours => '12 horas';

  @override
  String get sharingDuration24Hours => '24 horas';

  @override
  String get sharingDuration3Days => '3 días';

  @override
  String get sharingDuration1Day => '1 día';

  @override
  String get sharingDuration7Days => '7 días';

  @override
  String get sharingDuration30Days => '30 días';

  @override
  String get sharingDuration90Days => '90 días';

  @override
  String get sharingEnterAndConfirmPassword =>
      'Ingresa y confirma la contraseña de acceso.';

  @override
  String get sharingPasswordMinRequirements =>
      'La contraseña debe tener al menos 8 caracteres e incluir letras y números.';

  @override
  String get sharingPasswordMismatch =>
      'La contraseña y la confirmación no coinciden.';

  @override
  String get sharingAccessPasswordLabel => 'Contraseña de acceso';

  @override
  String get sharingConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String sharingAccessApprovedFor(String name) {
    return 'Acceso aprobado para $name.';
  }

  @override
  String sharingAccessDeniedFor(String name) {
    return 'Acceso denegado para $name.';
  }

  @override
  String get sharingUnableToUpdateApprovalRequest =>
      'No se pudo actualizar la solicitud de aprobación.';

  @override
  String get sharingNoPendingApprovalRequests =>
      'No hay solicitudes de aprobación pendientes.';

  @override
  String get sharingRequestedLabel => 'Solicitado';

  @override
  String get sharingIpLabel => 'IP';

  @override
  String get sharingShareCodeLabel => 'Código compartido';

  @override
  String get sharingApproveButton => 'Aprobar';

  @override
  String get sharingDenyButton => 'Denegar';

  @override
  String get sharingCloseButton => 'Cerrar';

  @override
  String get sharingSelectFilesToShareTitle =>
      'Seleccionar archivos para compartir';

  @override
  String sharingChooseUpToFilesForLink(int maxFiles) {
    return 'Elige hasta $maxFiles archivos para este enlace';
  }

  @override
  String get sharingSearchFilesLabel => 'Buscar archivos';

  @override
  String get sharingFilterByCategoryLabel => 'Filtrar por categoría';

  @override
  String get sharingAllCategories => 'Todas las categorías';

  @override
  String sharingSelectedCount(int selected, int max) {
    return 'Seleccionados: $selected/$max';
  }

  @override
  String get sharingNoFilesMatchSearchFilter =>
      'No hay archivos que coincidan con tu búsqueda/filtro.';

  @override
  String get sharingApplySelectionButton => 'Aplicar selección';

  @override
  String get sharingLinkCreationDisabledBySystemConfiguration =>
      'La creación de enlaces para compartir está deshabilitada por configuración del sistema.';

  @override
  String sharingReachedMaxActiveLinksInAccessManagement(int maxLinks) {
    return 'Alcanzaste el máximo de $maxLinks enlaces de compartición activos. Revoca uno en Gestión de acceso para crear un enlace nuevo.';
  }

  @override
  String get sharingManageButton => 'Administrar';

  @override
  String get notificationsPageTitle => 'Notificaciones';

  @override
  String notificationsUnreadCount(int count) {
    return '$count sin leer';
  }

  @override
  String get notificationsTabAll => 'Todas';

  @override
  String get notificationsTabUnread => 'Sin leer';

  @override
  String get notificationsTabSettings => 'Configuración';

  @override
  String get notificationsAllEmpty => 'Aún no hay notificaciones';

  @override
  String get notificationsUnreadEmpty => 'No hay notificaciones sin leer';

  @override
  String get notificationsPushSectionTitle => 'Notificaciones push';

  @override
  String get notificationsEmailSectionTitle => 'Notificaciones por correo';

  @override
  String get notificationsSettingAccessAlertsTitle => 'Alertas de acceso';

  @override
  String get notificationsSettingAccessAlertsDescription =>
      'Cuando alguien ve tus registros';

  @override
  String get notificationsSettingShareRequestsTitle =>
      'Solicitudes de compartición';

  @override
  String get notificationsSettingShareRequestsDescription =>
      'Nuevas solicitudes de acceso de proveedores';

  @override
  String get notificationsSettingSecurityAlertsTitle => 'Alertas de seguridad';

  @override
  String get notificationsSettingSecurityAlertsDescription =>
      'Intentos de acceso no autorizados';

  @override
  String get notificationsSettingRecordUpdatesTitle =>
      'Actualizaciones de registros';

  @override
  String get notificationsSettingRecordUpdatesDescription =>
      'Cambios en tus datos médicos';

  @override
  String get notificationsSettingDailySummaryTitle => 'Resumen diario';

  @override
  String get notificationsSettingDailySummaryDescription =>
      'Resumen diario de actividad';

  @override
  String get notificationsSettingWeeklyReportTitle => 'Informe semanal';

  @override
  String get notificationsSettingWeeklyReportDescription =>
      'Resumen semanal de accesos';

  @override
  String get notificationsTypeEmergencyQrAccessedTitle =>
      'Código QR de emergencia accedido';

  @override
  String get notificationsTypeEmergencyQrAccessedDescription =>
      'Se accedió a tu información médica de emergencia';

  @override
  String get notificationsTypeShareRequestTitle =>
      'Nueva solicitud de compartición';

  @override
  String notificationsTypeShareRequestDescription(String actor) {
    return '$actor solicitó acceso a tus registros';
  }

  @override
  String get notificationsTypeProfileUpdatedTitle => 'Perfil actualizado';

  @override
  String get notificationsTypeProfileUpdatedDescription =>
      'Tu información médica fue actualizada';

  @override
  String get notificationsTypeProviderAccessTitle => 'Acceso de proveedor';

  @override
  String notificationsTypeProviderAccessDescription(String actor) {
    return '$actor vio tus resultados de laboratorio';
  }

  @override
  String get notificationsTypeMedicationReminderTitle =>
      'Recordatorio de medicación';

  @override
  String get notificationsTypeMedicationReminderDescription =>
      'Es hora de tomar tu medicación programada';

  @override
  String get notificationsTypeAppointmentAlertTitle => 'Alerta de cita';

  @override
  String get notificationsTypeAppointmentAlertDescription =>
      'Tienes una cita médica próxima';

  @override
  String get notificationsTypeSecurityAlertTitle => 'Alerta de seguridad';

  @override
  String get notificationsTypeSecurityAlertDescription =>
      'Se detectó un evento sensible de seguridad';

  @override
  String get notificationsTypeRecordUpdatedTitle => 'Registro actualizado';

  @override
  String get notificationsTypeRecordUpdatedDescription =>
      'Uno de tus registros compartidos fue actualizado';

  @override
  String get notificationsDetailTitle => 'Detalle de notificación';

  @override
  String get notificationsDetailTypeLabel => 'Tipo';

  @override
  String get notificationsDetailReceivedAtLabel => 'Recibida';

  @override
  String get notificationsDetailStatusLabel => 'Estado';

  @override
  String get notificationsDetailStatusRead => 'Leída';

  @override
  String get notificationsDetailStatusUnread => 'Sin leer';

  @override
  String get notificationsDetailActorLabel => 'Actor';

  @override
  String get notificationsDetailLanguageLabel => 'Idioma';

  @override
  String get notificationsDetailDescriptionLabel => 'Detalles';

  @override
  String get notificationsDetailViewSharingAction =>
      'Ver detalles de compartición';

  @override
  String get notificationsDetailRevokeSharingAction =>
      'Revocar enlace de compartición';

  @override
  String get notificationsDetailCloseAction => 'Cerrar';

  @override
  String get notificationsDetailOpenError =>
      'No fue posible abrir el detalle de la notificación en este momento.';

  @override
  String get notificationsDetailRevokeUnavailable =>
      'Esta notificación no incluye un enlace de compartición para revocar.';

  @override
  String get notificationsDetailRevokeSuccess =>
      'Enlace de compartición revocado.';

  @override
  String get notificationsDetailRevokeError =>
      'No fue posible revocar el enlace de compartición en este momento.';

  @override
  String get notificationsJustNow => 'Ahora mismo';

  @override
  String notificationsMinutesAgo(int count) {
    return 'Hace $count minutos';
  }

  @override
  String notificationsHoursAgo(int count) {
    return 'Hace $count horas';
  }

  @override
  String notificationsDaysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String get noRecentActivity => 'Aún no hay actividad reciente';
}
