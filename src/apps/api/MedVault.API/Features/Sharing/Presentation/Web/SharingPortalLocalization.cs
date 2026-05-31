using Microsoft.AspNetCore.Http;

namespace MedVault.API.Features.Sharing.Presentation.Web;

internal static class SharingPortalLocalization
{
    private static readonly IReadOnlyDictionary<string, string> EnLabels = new Dictionary<string, string>(StringComparer.Ordinal)
    {
        ["PageTitle"] = "MedVault Shared Medical Information",
        ["HeaderTitle"] = "Emergency Medical Snapshot",
        ["HeaderSubtitle"] = "Secure access for emergency responders and physicians.",
        ["DemoBadge"] = "Demo Mode",
        ["ExpiresAt"] = "Access expires",
        ["AccessLevel"] = "Access level",
        ["SharedBy"] = "Shared by",
        ["SharedAt"] = "Shared at",
        ["SecurePromptTitle"] = "Confirm access details",
        ["SecurePromptText"] = "Enter your name and any required credentials to view this shared information.",
        ["ViewerNameLabel"] = "Your full name",
        ["ViewerNameRequired"] = "Please enter your name to continue.",
        ["PasswordLabel"] = "Share password",
        ["VerificationCodeLabel"] = "Verification code",
        ["VerificationCodeRequired"] = "Enter the verification code to continue.",
        ["UnlockButton"] = "Unlock medical information",
        ["TwoFactorPending"] = "Access request sent. Waiting for patient approval.",
        ["TwoFactorDenied"] = "The patient denied this access request.",
        ["TwoFactorRequestMissing"] = "Access request was not found. Request approval again.",
        ["TwoFactorPendingHint"] = "Keep this page open. It will update when the patient approves or denies the request.",
        ["TwoFactorStatusLabel"] = "Approval status",
        ["TwoFactorRequestIdLabel"] = "Request ID",
        ["TwoFactorWaitingButton"] = "Waiting for approval",
        ["PatientInfo"] = "Patient information",
        ["EmergencyContact"] = "Emergency contact",
        ["MedicalSummary"] = "Medical summary",
        ["MedicalHistory"] = "Medical history",
        ["NoData"] = "No data available for this section.",
        ["InvalidLink"] = "This shared link was not found.",
        ["ExpiredLink"] = "This shared link has expired.",
        ["RevokedLink"] = "This shared link has been revoked.",
        ["Unauthorized"] = "Credentials were not accepted for this shared link.",
        ["UnexpectedError"] = "Unable to load shared data at the moment.",
        ["FieldBloodType"] = "Blood type",
        ["FieldDateOfBirth"] = "Date of birth",
        ["FieldGender"] = "Gender",
        ["FieldRelationship"] = "Relationship",
        ["FieldPhone"] = "Phone",
        ["SectionAllergies"] = "Allergies",
        ["SectionMedications"] = "Active medications",
        ["SectionConditions"] = "Conditions",
        ["SectionVaccinations"] = "Vaccinations",
        ["Documents"] = "Shared documents",
        ["DocumentCategory"] = "Category",
        ["DocumentUploadedAt"] = "Uploaded",
        ["DocumentLink"] = "Open document",
        ["DocumentFileName"] = "File",
        ["DocumentSize"] = "Size",
        ["DocumentPreview"] = "Preview",
        ["DocumentNoContent"] = "Document content is not available for inline preview.",
        ["DocumentViewerTitle"] = "Document viewer",
        ["DocumentLoading"] = "Loading document...",
        ["DocumentClose"] = "Close",
        ["DocumentUnableToLoad"] = "Unable to load document.",
        ["DocumentDownload"] = "Download document",
        ["DocumentExternalOpen"] = "Open external document",
        ["DocumentNotFound"] = "Document was not found in this shared link.",
        ["DocumentNoPreviewAvailable"] = "This document type cannot be previewed inline.",
    };

    private static readonly IReadOnlyDictionary<string, string> EsLabels = new Dictionary<string, string>(StringComparer.Ordinal)
    {
        ["PageTitle"] = "Informacion Medica Compartida de MedVault",
        ["HeaderTitle"] = "Resumen Medico de Emergencia",
        ["HeaderSubtitle"] = "Acceso seguro para personal de emergencia y medicos.",
        ["DemoBadge"] = "Modo Demostracion",
        ["ExpiresAt"] = "Acceso vence",
        ["AccessLevel"] = "Nivel de acceso",
        ["SharedBy"] = "Compartido por",
        ["SharedAt"] = "Compartido el",
        ["SecurePromptTitle"] = "Confirma tus datos de acceso",
        ["SecurePromptText"] = "Ingresa tu nombre y cualquier credencial requerida para ver esta informacion compartida.",
        ["ViewerNameLabel"] = "Nombre completo",
        ["ViewerNameRequired"] = "Ingresa tu nombre para continuar.",
        ["PasswordLabel"] = "Contrasena del enlace",
        ["VerificationCodeLabel"] = "Codigo de verificacion",
        ["VerificationCodeRequired"] = "Ingresa el codigo de verificacion para continuar.",
        ["UnlockButton"] = "Desbloquear informacion medica",
        ["TwoFactorPending"] = "Solicitud de acceso enviada. Esperando aprobacion del paciente.",
        ["TwoFactorDenied"] = "El paciente rechazo esta solicitud de acceso.",
        ["TwoFactorRequestMissing"] = "No se encontro la solicitud de acceso. Solicita aprobacion nuevamente.",
        ["TwoFactorPendingHint"] = "Mantén esta pagina abierta. Se actualizara cuando el paciente apruebe o rechace la solicitud.",
        ["TwoFactorStatusLabel"] = "Estado de aprobacion",
        ["TwoFactorRequestIdLabel"] = "ID de solicitud",
        ["TwoFactorWaitingButton"] = "Esperando aprobacion",
        ["PatientInfo"] = "Informacion del paciente",
        ["EmergencyContact"] = "Contacto de emergencia",
        ["MedicalSummary"] = "Resumen medico",
        ["MedicalHistory"] = "Historial medico",
        ["NoData"] = "No hay datos disponibles para esta seccion.",
        ["InvalidLink"] = "No se encontro este enlace compartido.",
        ["ExpiredLink"] = "Este enlace compartido ha expirado.",
        ["RevokedLink"] = "Este enlace compartido fue revocado.",
        ["Unauthorized"] = "Las credenciales no fueron aceptadas para este enlace.",
        ["UnexpectedError"] = "No se pudo cargar la informacion compartida por el momento.",
        ["FieldBloodType"] = "Grupo sanguineo",
        ["FieldDateOfBirth"] = "Fecha de nacimiento",
        ["FieldGender"] = "Genero",
        ["FieldRelationship"] = "Relacion",
        ["FieldPhone"] = "Telefono",
        ["SectionAllergies"] = "Alergias",
        ["SectionMedications"] = "Medicacion activa",
        ["SectionConditions"] = "Condiciones",
        ["SectionVaccinations"] = "Vacunas",
        ["Documents"] = "Documentos compartidos",
        ["DocumentCategory"] = "Categoria",
        ["DocumentUploadedAt"] = "Subido",
        ["DocumentLink"] = "Abrir documento",
        ["DocumentFileName"] = "Archivo",
        ["DocumentSize"] = "Tamano",
        ["DocumentPreview"] = "Vista previa",
        ["DocumentNoContent"] = "El contenido del documento no esta disponible para vista previa en linea.",
        ["DocumentViewerTitle"] = "Visor de documentos",
        ["DocumentLoading"] = "Cargando documento...",
        ["DocumentClose"] = "Cerrar",
        ["DocumentUnableToLoad"] = "No se pudo cargar el documento.",
        ["DocumentDownload"] = "Descargar documento",
        ["DocumentExternalOpen"] = "Abrir documento externo",
        ["DocumentNotFound"] = "No se encontro el documento en este enlace compartido.",
        ["DocumentNoPreviewAvailable"] = "Este tipo de documento no se puede mostrar en vista previa.",
    };

    private static readonly IReadOnlyDictionary<string, string> CaLabels = new Dictionary<string, string>(StringComparer.Ordinal)
    {
        ["PageTitle"] = "Informació mèdica compartida de MedVault",
        ["HeaderTitle"] = "Resum mèdic d'emergència",
        ["HeaderSubtitle"] = "Accés segur per a personal d'emergència i metges.",
        ["DemoBadge"] = "Mode demostració",
        ["ExpiresAt"] = "L'accés caduca",
        ["AccessLevel"] = "Nivell d'accés",
        ["SharedBy"] = "Compartit per",
        ["SharedAt"] = "Compartit el",
        ["SecurePromptTitle"] = "Confirma les teves dades d'accés",
        ["SecurePromptText"] = "Introdueix el teu nom i qualsevol credencial requerida per veure aquesta informació compartida.",
        ["ViewerNameLabel"] = "Nom complet",
        ["ViewerNameRequired"] = "Introdueix el teu nom per continuar.",
        ["PasswordLabel"] = "Contrasenya de l'enllaç",
        ["VerificationCodeLabel"] = "Codi de verificació",
        ["VerificationCodeRequired"] = "Introdueix el codi de verificació per continuar.",
        ["UnlockButton"] = "Desbloqueja la informació mèdica",
        ["TwoFactorPending"] = "Sol·licitud d'accés enviada. Esperant l'aprovació del pacient.",
        ["TwoFactorDenied"] = "El pacient ha denegat aquesta sol·licitud d'accés.",
        ["TwoFactorRequestMissing"] = "No s'ha trobat la sol·licitud d'accés. Torna a demanar aprovació.",
        ["TwoFactorPendingHint"] = "Mantén aquesta pàgina oberta. S'actualitzarà quan el pacient aprovi o denegui la sol·licitud.",
        ["TwoFactorStatusLabel"] = "Estat de l'aprovació",
        ["TwoFactorRequestIdLabel"] = "ID de sol·licitud",
        ["TwoFactorWaitingButton"] = "Esperant aprovació",
        ["PatientInfo"] = "Informació del pacient",
        ["EmergencyContact"] = "Contacte d'emergència",
        ["MedicalSummary"] = "Resum mèdic",
        ["MedicalHistory"] = "Historial mèdic",
        ["NoData"] = "No hi ha dades disponibles per a aquesta secció.",
        ["InvalidLink"] = "No s'ha trobat aquest enllaç compartit.",
        ["ExpiredLink"] = "Aquest enllaç compartit ha caducat.",
        ["RevokedLink"] = "Aquest enllaç compartit ha estat revocat.",
        ["Unauthorized"] = "Les credencials no han estat acceptades per a aquest enllaç.",
        ["UnexpectedError"] = "No s'ha pogut carregar la informació compartida en aquest moment.",
        ["FieldBloodType"] = "Grup sanguini",
        ["FieldDateOfBirth"] = "Data de naixement",
        ["FieldGender"] = "Gènere",
        ["FieldRelationship"] = "Relació",
        ["FieldPhone"] = "Telèfon",
        ["SectionAllergies"] = "Al·lèrgies",
        ["SectionMedications"] = "Medicació activa",
        ["SectionConditions"] = "Condicions",
        ["SectionVaccinations"] = "Vacunes",
        ["Documents"] = "Documents compartits",
        ["DocumentCategory"] = "Categoria",
        ["DocumentUploadedAt"] = "Pujat",
        ["DocumentLink"] = "Obre document",
        ["DocumentFileName"] = "Fitxer",
        ["DocumentSize"] = "Mida",
        ["DocumentPreview"] = "Vista prèvia",
        ["DocumentNoContent"] = "El contingut del document no està disponible per a la vista prèvia en línia.",
        ["DocumentViewerTitle"] = "Visor de documents",
        ["DocumentLoading"] = "Carregant document...",
        ["DocumentClose"] = "Tanca",
        ["DocumentUnableToLoad"] = "No s'ha pogut carregar el document.",
        ["DocumentDownload"] = "Descarrega document",
        ["DocumentExternalOpen"] = "Obre document extern",
        ["DocumentNotFound"] = "No s'ha trobat el document en aquest enllaç compartit.",
        ["DocumentNoPreviewAvailable"] = "Aquest tipus de document no es pot previsualitzar en línia.",
    };

    public static string ResolveLanguage(string? requestedLanguage, HttpRequest request)
    {
        var candidate = requestedLanguage;

        if (string.IsNullOrWhiteSpace(candidate))
        {
            var acceptLanguage = request.Headers.AcceptLanguage.ToString();
            candidate = acceptLanguage.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)
                .FirstOrDefault();
        }

        if (!string.IsNullOrWhiteSpace(candidate)
            && candidate.StartsWith("ca", StringComparison.OrdinalIgnoreCase))
        {
            return "ca";
        }

        if (!string.IsNullOrWhiteSpace(candidate)
            && candidate.StartsWith("es", StringComparison.OrdinalIgnoreCase))
        {
            return "es";
        }

        return "en";
    }

    public static IReadOnlyDictionary<string, string> GetLabels(string language)
    {
        if (string.Equals(language, "ca", StringComparison.OrdinalIgnoreCase))
        {
            return CaLabels;
        }

        if (string.Equals(language, "es", StringComparison.OrdinalIgnoreCase))
        {
            return EsLabels;
        }

        return EnLabels;
    }
}

