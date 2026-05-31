# MedVault: Your Portable Medical History

**_Your medical information. Protected. Accessible. Yours._**

MedVault is a portable medical history system designed to provide patients and healthcare professionals with quick, secure, and standardized access to essential medical information. It complements existing clinical systems rather than replacing them, serving as an "intelligent health passport" that travels with the patient across hospitals and medical services.

This project is developed as a **Trabajo Fin de Máster (TFM)** - Master's Final Project, focusing on creating a comprehensive mobile-first solution for personal health data management.

---

## 📋 Table of Contents

- [Executive Summary](#executive-summary)
- [Project Vision](#project-vision)
- [Key Features](#key-features)
- [Project Scope](#project-scope)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Documentation](#documentation)
- [Security & Privacy](#security--privacy)
- [Contributing](#contributing)
- [License](#license)

---

## Executive Summary

MedVault empowers patients as the owners of their medical data, enabling them to carry and manage their health information autonomously without dependency on hospital infrastructures. The system focuses on:

- **User Data Ownership**: Patients control when and how their data is shared
- **Autonomous Operation**: Functions independently without requiring hospital integration
- **Privacy-First Approach**: End-to-end encrypted and GDPR compliant
- **Complementary Tool**: Enhances existing Electronic Health Record (EHR) systems

---

## Project Vision

### Core Objectives

1. **MVP — Base Mobile Application**
   - Flutter mobile app (Android/iOS)
   - Manual management of medical information:
     - Allergies
     - Active medications
     - Chronic diseases
     - Surgeries and relevant interventions
     - Emergency contacts
     - Patient preferences (organ donation, language, advanced directives)
   - Local and secure data storage
   - Intuitive interface for viewing and updating information

2. **Secure Information Sharing**
   - Temporary links with password protection for sensitive data
   - QR codes for public/emergency data (allergies, blood type, updated information)
   - Granular permission and access control
   - Audit trail of who accessed what information

3. **Intelligent Data Ingestion**
   - Interactive tutorial for medical data entry
   - Guided questions to obtain essential information
   - Data validation and normalization

4. **AI-Powered Document Management**
   - Import and storage of medical documents (reports, tests, prescriptions)
   - Automatic metadata generation using AI:
     - Key information extraction
     - Document type classification
     - Date extraction
   - Integration of metadata with user's general information
   - Simplified document sharing with metadata context

---

## Key Features

### 🔐 Secure Medical Identity

- Locally managed by the user
- Encrypted and secure storage
- User-controlled access permissions

### 📄 Summarized Clinical Information

- Complete medical profile with essential health data
- Allergies and medication management
- Chronic disease tracking
- Surgery and intervention history
- Emergency contact management
- Centralized clinical document management

### 🔎 Links to Complete Medical History

- Authenticated access to extended cloud records
- Quick consultations from emergency rooms
- Access from centers not connected to patient's primary hospital

### 📱 Digital Application

- Patient viewing and updating capabilities
- Android/iOS compatibility
- Temporary secure sharing with healthcare professionals
- Responsive design for multiple screen sizes

### 🤖 AI-Powered Document Processing

- Automatic metadata extraction from medical documents
- Document classification and organization
- Intelligent information integration

---

## Project Scope

### In Scope (TFM Phase)

✅ Mobile application with core health management features  
✅ Secure local and cloud storage  
✅ Information sharing with access control  
✅ GDPR compliance and data encryption

### Out of Scope (Future - vNext)

📌 Direct hospital system integration  
📌 Full FHIR standard implementation  
📌 Physical card production  
📌 System-specific integrations (e.g., ICS)

---

## Technology Stack

### Frontend

- **Framework**: Flutter
- **Platforms**: Android (API 21+), iOS (12+)
- **Design**: Mobile-first, responsive architecture
- **State Management**: Provider pattern

### Backend

- **Framework**: ASP.NET Core (.NET)
- **Architecture**: REST API
- **Database**: SQL Server / SQLite with encryption
- **Purpose**: Sharing, cloud features, and optional synchronization

### Infrastructure

- **Local Storage**: Secure encrypted local database (SQLite/Isar)
- **Cloud Storage**: Optional synchronization (user-owned data model)
- **Security**: End-to-end encryption, HTTPS, secure tokens

### AI/ML Module

- Automatic metadata extraction
- Document classification
- Key information extraction
- Entity recognition

---

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- .NET 6.0 SDK or higher
- Visual Studio or Visual Studio Code
- Android SDK and/or Xcode (for mobile development)

### Quick Setup

Read the [QUICKSTART.md](QUICKSTART.md) for detailed instructions on setting up the development environment, running the application, and executing tests.

## Project Structure

```
root/
├── docs/                        # Documentation and design assets
├── src/                          # Main application source code
│   └── apps/
│       ├── mobile/               # Flutter mobile app
│       │   └── medvault/        # Main Flutter project
│       │       ├── lib/         # Dart source code
│       │       ├── pubspec.yaml  # Flutter dependencies
│       │       └── test/        # Flutter unit tests
│       └── api/                 # ASP.NET Core backend
│           ├── MedVault.API/    # Main API project
│           ├── MedVault.AppHost/         # .NET Aspire host
│           └── MedVault.ServiceDefaults/ # Shared configuration
├── tools/                       # Development utilities
│   └── MedVault.DocIntelligence/ # Document AI processing
├── tests/                       # Test suites
│   └── backend/                # .NET unit & integration tests
├── QUICKSTART.md               # This file
└── README.md                   # Project overview
```

---

## Benefits

### For Patients

✅ Complete control over medical information  
✅ Easy access to health records anytime, anywhere  
✅ Simplified sharing with healthcare providers  
✅ Reduced risk of medical errors  
✅ Better continuity of care across different facilities

### For Healthcare Professionals

✅ Quick access to critical patient information in emergencies  
✅ Reduced time gathering patient history  
✅ Better-informed clinical decisions  
✅ Easy verification of medications and allergies

### For Healthcare System

✅ Improved coordination between medical centers  
✅ Reduced duplicate tests and procedures  
✅ Enhanced patient safety  
✅ Complementary to existing EHR/HCIS/HIS systems

---

## Security & Privacy

MedVault prioritizes security and privacy through:

- **Encryption**: End-to-end encryption for data at rest and in transit
- **GDPR Compliance**: Full compliance with European data protection regulations
- **Access Control**: Granular permission system and temporary access tokens
- **Audit Logging**: Complete audit trail of all data access events
- **Authentication**: Secure authentication mechanisms with OAuth/OpenID Connect support
- **Data Ownership**: User-controlled data model - no server-side data ownership

### Key Security Features

- Local-first data storage with optional cloud synchronization
- Password-protected temporary links for data sharing
- QR codes with time-limited access for emergencies
- Role-based access control (RBAC)
- Secure session management
- Regular security audits and compliance verification

---

## Roadmap

### Phase 1: Analysis & Planning ✅

- Requirements analysis
- Workflow definition
- Technical analysis

### Phase 2: Prototype (v0.1)

- Base Android app
- Authentication with 3rd parties (offline mode)
- Basic architecture

### Phase 3: Data Management (v0.2)

- Document management
- Cloud synchronization
- Enhanced data organization

### Phase 4: Processing & Export (v0.3)

- AI-powered document processing
- Basic export systems (QR, PDF, Links)

### Phase 5: MVP (v1.0)

- Emergency access system
- QR + PIN access
- Allergies, medications, emergency contacts display
- Read-only access mode
- Access audit logging

### Phase 6+: Future (vNext)

- Complete FHIR compliance
- Advanced exports
- Physical health card
- Healthcare system integration

---

## Contributing

We welcome contributions! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Code style and standards
- Development workflow
- Testing requirements
- Pull request process
- Issue reporting

### Development Team

This project is being developed by a dedicated team focused on healthcare technology innovation and patient data empowerment.

---

## Support

- 📖 [Documentation](docs/)
- 🐛 [Report Issues](https://github.com/yourusername/medvault/issues)
- 💬 [Discussions](https://github.com/yourusername/medvault/discussions)

---

## License

This project is licensed under the Creative Commons License - see [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Flutter and Dart communities
- ASP.NET Core team
- Healthcare professionals who provided domain expertise
- Academic advisors overseeing the TFM project

---

**MedVault — Your medical information with you, Always protected, Always yours.**
