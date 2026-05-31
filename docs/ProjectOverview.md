# MedVault - Project Overview

**Document Version:** 1.0  
**Last Updated:** February 14, 2026  
**Project Status:** In Development  
**Document Owner:** Project Team

---

## Executive Summary

MedVault is a portable medical history system (Historia Clínica Portátil) designed to provide patients and healthcare professionals with quick, secure, and standardized access to essential medical information. The system empowers patients as the owners of their medical data, enabling them to carry and manage their health information autonomously without dependency on hospital infrastructures.

This project is developed as a **Trabajo Fin de Máster (TFM)** - Master's Final Project, focusing on creating a comprehensive mobile-first solution for personal health data management.

---

## 1. Project Vision

### Vision Statement

**_"Your medical information. Protected. Accessible. Yours."_**

MedVault aims to create an intelligent health passport that travels with the patient across hospitals and medical services, complementing existing clinical systems rather than replacing them.

### Core Philosophy

- **User Data Ownership**: The patient is the owner of their data and decides when and how to share it
- **Autonomous Operation**: Functions independently without requiring hospital infrastructure integration
- **Privacy-First**: Secure, encrypted, and compliant with healthcare regulations
- **Complementary Tool**: Designed to enhance, not replace, existing Electronic Health Record (EHR) systems

---

## 2. Project Goals

### Primary Goal (TFM Objective)

Create a **Flutter mobile application** that allows users to carry and manage all their medical information autonomously, privately, and without dependency on hospital infrastructures.

### Strategic Goals

1. **Patient Empowerment**
   - Enable patients to maintain complete control over their medical information
   - Provide tools for autonomous health data management
   - Facilitate informed decision-making about data sharing

2. **Healthcare Accessibility**
   - Improve emergency care for patients in unfamiliar healthcare facilities
   - Reduce medical errors due to lack of critical information
   - Enhance coordination between different medical centers

3. **Data Security & Privacy**
   - Implement end-to-end encryption
   - Ensure GDPR compliance and adherence to healthcare regulations
   - Provide granular access control mechanisms

4. **Clinical Efficiency**
   - Provide quick access to essential patient information
   - Reduce time spent gathering patient history
   - Enable secure temporary sharing with healthcare professionals

---

## 3. Project Scope

### In Scope (TFM)

#### Phase 1: MVP — Base Mobile Application

- Mobile app built with Flutter (Android/iOS)
- Manual management of medical information:
  - Allergies
  - Active medications
  - Chronic diseases
  - Emergency contacts
  - Patient preferences (organ donation, language, advanced directives)
- Local and secure data storage
- Intuitive interface for viewing and updating information

#### Phase 2: Secure Information Sharing

- **Temporary links** with password protection for sensitive data
- **QR codes** for public/emergency data (allergies, blood type, updated information)
- **Portal-Web** to grant access to the patient's information for healthcare professionals.
- Audit trail of who accessed what information

#### Phase 3: AI-Powered Document Management

- Import and storage of medical documents (reports, tests, prescriptions)
- **Automatic metadata generation** using AI
  - Key information extraction
  - Document type classification
  - Date extraction
- Integration of metadata with user's general information
- Simplified document sharing with metadata context

#### Phase 4: Intelligent Data Ingestion Assistant

- Interactive tutorial to facilitate medical data entry
- Guided questions to obtain essential information
- Data validation and normalization

### Out of Scope (TFM)

- Direct integration with hospital systems (considered for vNext)
- Full FHIR implementation (future version)
- Physical card production
- Integration with specific health system

### Future Considerations (vNext)

- Complete FHIR standard compliance
- Advanced export capabilities
- Physical health card
- Integration with healthcare systems
- Custom connectors for medical platforms

---

## 4. Stakeholders

### Primary Stakeholders

#### Patients (End Users)

- **Role**: Data owners and primary users
- **Interest**: Secure, easy-to-use tool for managing health information
- **Impact**: High - Direct users of the application

#### Healthcare Professionals

- **Role**: Authorized readers of patient information
- **Interest**: Quick, reliable access to critical patient data
- **Impact**: High - Primary consumers of shared information

### Secondary Stakeholders

#### Academic Supervisors (TFM)

- **Role**: Project oversight and evaluation
- **Interest**: Quality of implementation and academic rigor
- **Impact**: Medium - Guidance and assessment

#### Healthcare Institutions

- **Role**: Potential future partners
- **Interest**: Improved patient care and data accessibility
- **Impact**: Low (current phase) - Future integration partners

#### Regulatory Bodies

- **Role**: Compliance oversight
- **Interest**: GDPR and healthcare regulation compliance
- **Impact**: High - Mandatory compliance requirements

---

## 5. Success Criteria

### Functional Success Metrics

1. **User Adoption**
   - Successfully onboard users through guided data entry
   - 90%+ completion rate of core medical profile (allergies, medications, emergency contacts)

2. **Data Management**
   - Users can create, read, update, and delete medical information
   - Document upload and storage functionality works reliably
   - AI metadata extraction achieves 80%+ accuracy

3. **Sharing Functionality**
   - Generate secure temporary links with configurable expiration
   - QR code generation and scanning works reliably
   - Access audit logs capture all data access events

4. **Security & Privacy**
   - All sensitive data encrypted at rest and in transit
   - GDPR compliance verified
   - No unauthorized access to user data

---

## 6. Timeline and Milestones

To be defined based on project phases and development sprints.

---

## 7. Key Features and Benefits

### Core Features

#### 🔐 Secure Medical Identity

- Locally managed by the user
- Encrypted and secure storage
- User-controlled access permissions

#### 📄 Summarized Clinical Information

- Allergies
- Active medication
- Chronic diseases
- Surgeries and relevant interventions
- Emergency contacts
- Patient preferences (donation, language, advanced directives)
- Centralized clinical document management

#### 🔎 Links to Complete Medical History

- Authenticated access to extended cloud records
- Enables quick consultations from emergency rooms or centers not connected to patient's hospital

#### 📱 Digital Application

- Patient viewing and updating
- Android/iOS compatibility
- Temporary information sharing with professionals

#### 🤖 AI-Powered Document Processing

- Automatic metadata extraction from medical documents
- Document classification and organization
- Intelligent information integration

### Benefits

#### For Patients

- Complete control over medical information
- Easy access to health records anytime, anywhere
- Simplified sharing with healthcare providers
- Reduced risk of medical errors
- Better continuity of care across different facilities

#### For Healthcare Professionals

- Quick access to critical patient information in emergencies
- Reduced time gathering patient history
- Better-informed clinical decisions
- Easy verification of medications and allergies

#### For Healthcare System

- Improved coordination between medical centers
- Reduced duplicate tests and procedures
- Enhanced patient safety
- Complementary to existing EHR/HCIS/HIS systems

---

## 8. Technical Overview

### Technology Stack

#### Mobile Frontend

- **Framework**: Flutter
- **Platforms**: Android, iOS
- **Design**: Mobile-first, responsive

#### Web Frontend (for sharing links)

- **Framework**: Angular for a simple web interface to view shared information securely.
- **Design**: Responsive design for access from any device.
- **Real-time Communication**: SignalR for 2 Factor Authorization between User and Physician.

#### Backend

- **Framework**: .NET (C#)
- **API**: REST API
- **Purpose**: Sharing functionality and optional cloud features

#### Database

- **Local Storage**: Requires some secure and encrypted local storage solution (e.g., SQLite with encryption)
- **Cloud Storage**: Optional synchronization
- **Architecture**: User-owned data model

#### AI/ML Module

- **Purpose**: Automatic metadata extraction from documents
- **Capabilities**:
  - Key information extraction
  - Document type classification
  - Date and entity recognition

### Security Architecture

#### Data Protection

- End-to-end encryption
- Encrypted storage at rest
- Secure transmission (TLS/SSL)

#### Access Control

- Granular permission system
- Temporary tokens for healthcare professionals
- Multi-factor authentication support

#### Compliance

- GDPR compliant
- Healthcare regulation adherence
- Privacy by design principles

---

## 9. Project Boundaries

### What MedVault IS

- A portable medical history companion
- A secure personal health data management tool
- A bridge between different healthcare providers
- A patient empowerment platform
- A complementary tool to existing EHR systems

### What MedVault IS NOT

- A replacement for hospital EHR systems
- A diagnostic or treatment tool
- A telemedicine platform
- A prescription management system
- A medical device (regulatory perspective)

---

## 10. Risks and Assumptions

### Key Assumptions

1. Users are willing to manually input initial medical data
2. Healthcare professionals will adopt QR code scanning for emergency access
3. Cloud storage solutions will remain available and affordable
4. AI models can achieve sufficient accuracy for metadata extraction
5. Regulatory requirements will remain stable during development

### Identified Risks

1. **Security breach**: Mitigated by encryption, security audits, penetration testing
2. **Low user adoption**: Mitigated by intuitive UX, guided onboarding
3. **Regulatory compliance issues**: Mitigated by legal consultation, compliance review
4. **Technical complexity**: Mitigated by phased development, MVP approach
5. **Data accuracy**: Mitigated by validation, user verification, audit trails

---

## 11. Contact and Governance

### Project Management

- Documentation maintained in `/docs` folder
- Version control via Git
- Issue tracking for feature requests and bugs

---

**_"Your medical information. Protected. Accessible. Yours."_**

**_"Tu información médica. Protegida. Accesible. Tuya."_**
