namespace MedVault.DocIntelligence.Models;

/// <summary>
/// Known types of medical documents that the analyzer can classify.
/// </summary>
public enum MedicalDocumentType
{
    Unknown = 0,
    BloodTest,
    Urinalysis,
    Radiology,
    Diagnosis,
    Prescription,
    DischargeSummary,
    Referral,
    Vaccination,
    Allergy,
    Pathology,
    SurgeryReport,
    ConsultationNote,
    LabResult,
    ImagingReport,
    MedicalCertificate
}
