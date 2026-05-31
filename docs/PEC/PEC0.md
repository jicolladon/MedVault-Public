# PEC 0 — Plan de trabajo inicial del TFM

**Proyecto:** MedVault - **_"Tu información médica. Protegida. Accesible. Tuya."_**
**Fecha:** 21 de febrero de 2026  
**Estado:** Borrador inicial para validación temprana

---

## 1 Temática del proyecto

El objetivo del proyecto es desarrollar una aplicatión movil que funcione como una **carpeta clinica personal digital** que permita a los usuarios gestionar su información médica de forma segura y compartirla de manera controlada con profesionales sanitarios. La idea es permitir a los usuarios llevar siempre consigo su información clinica y poder compartirla de forma rapida y segura con profesionales sanitarios, evitando la necesidad de:

- Llevar documentos físicos.
- Repetir información médica en cada consulta.
- Tener que recopilar información de salud de diferentes fuentes en cada momento.

El proyecto tiene como objetivo principal hacer que el propio paciente sea el propietario de su información médica, dándole control total sobre quién puede acceder a ella y cuándo. Además, se busca facilitar la comunicación entre pacientes y profesionales sanitarios, especialmente en situaciones de emergencia donde el acceso rápido a información crítica puede ser vital.

---

## 2 Breve descripción de lo que se quiere realizar

Se propone construir un **carpeta clinica personal digital** (MedVault) en formato móvil para que la persona usuaria pueda:

- Registrar y mantener su información clínica básica (alergias, medicación activa, patologías crónicas, contactos de emergencia y preferencias relevantes).
- Almacenar documentación médica de forma segura.
- Compartir información de manera controlada con profesionales sanitarios mediante enlaces temporales y códigos QR.

El sistema está planteado como **complemento** a los sistemas clínicos existentes, no como sustituto.

---

## 3 Alcance esperado

#### Phase 1: MVP — Base Mobile Application

- Aplicación móvil desarrollada con Flutter (Android/iOS)
- Gestión manual de información médica:
  - Alergias
  - Medicación activa
  - Enfermedades crónicas
  - Contactos de emergencia
  - Preferencias del paciente (donación de órganos, idioma, voluntades anticipadas)
- Almacenamiento local y seguro de datos
- Interfaz intuitiva para visualizar y actualizar la información

#### Phase 2: Secure Information Sharing

- **Enlaces temporales** con protección por contraseña para datos sensibles
- **Códigos QR** para datos públicos/de emergencia (alergias, grupo sanguíneo, información actualizada)
- **Portal web** para otorgar acceso a la información del paciente a profesionales sanitarios.
- Trazabilidad de acceso (quién accedió y a qué información)

#### Phase 3: AI-Powered Document Management

- Importación y almacenamiento de documentos médicos (informes, pruebas, prescripciones)
- **Generación automática de metadatos** mediante IA
  - Extracción de información clave
  - Clasificación del tipo de documento
  - Extracción de fechas
- Integración de metadatos con la información general del usuario
- Intercambio simplificado de documentos con contexto de metadatos

#### Phase 4: Intelligent Data Ingestion Assistant

- Tutorial interactivo para facilitar la introducción de datos médicos
- Preguntas guiadas para obtener información esencial
- Validación y normalización de datos

### Out of Scope (TFM)

- Integración directa con sistemas hospitalarios (considerada para vNext)
- Implementación completa de FHIR (versión futura)
- Producción de tarjeta física
- Integración con un sistema sanitario específico

### Future Considerations (vNext)

- Cumplimiento completo del estándar FHIR
- Capacidades avanzadas de exportación
- Tarjeta sanitaria física
- Integración con sistemas sanitarios
- Conectores personalizados para plataformas médicas

---

## 4 Tecnología prevista

### Aplicación móvil

- **Flutter** como framework principal.
- Objetivo multiplataforma: **Android** para el MVP.

### Web de consulta (para enlaces compartidos)

- **Angular** para interfaz web de acceso seguro.
- Diseño responsive para consulta desde distintos dispositivos.
- **SignalR** para soporte de doble factor de autorización entre paciente y profesional.

### Backend

- **ASP.NET Core (.NET)** para API REST.
- Servicios de autenticación, compartición segura y sincronización opcional.

### Gestor de documentos con IA

- **ASP.Net Core API** como punto de entrada para gestión documental.
- **Semantic Kernel** para la comunicación con modelos de lenguaje.
- **Azure OpenAI** para extracción de metadatos y clasificación documental.
- **AI Específica** para tareas de procesamiento de documentos médicos.

### Datos y seguridad

- Almacenamiento local seguro y/o base de datos según módulo.
- Cifrado de información sensible.
- Trazabilidad de accesos (auditoría).

### Deployment

- Aplicación móvil distribuida a través de tiendas oficiales (Google Play).
- Backend desplegado en Azure App Service o similar mediateant contenedores o servicios gestionados.
- Integracion con Firebase para notificaciones push y analítica básica.

### Herramientas de desarrollo

- **GitHub** para control de versiones y gestión de tareas (https://github.com/jicolladon/medVault).
- **Github Actions** para CI/CD.
- **Azure Cloud** para hosting y servicios relacionados.
- **VS Code** y **Visual Studio** como entornos de desarrollo principales.
- **Docker** para desarrollo local y despliegue de servicios backend.
- ... y otras herramientas según necesidades específicas del proyecto.

---

## 5 Plan de trabajo resumido

- **Fase 0:** Documentación y planificación (definición de alcance, tecnologías, diseño inicial, workflows,....).
- **Fase 1:** base técnica (modelo de datos, arquitectura app/API, autenticación).
- **Fase 2:** MVP clínico (gestión de información médica esencial).
- **Fase 3:** compartición segura (enlaces temporales, QR, permisos y auditoría).
- **Fase 4:** validación final (pruebas, seguridad y preparación de entrega).

---
