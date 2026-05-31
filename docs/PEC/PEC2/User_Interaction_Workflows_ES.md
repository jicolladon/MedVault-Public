# MedVault — Flujos de interacción de usuario (ES)

Fuente: diseño `MedVault.make` y mockups exportados en `docs/PEC/PEC2/Mockups`.

## 1. Autenticación (Login con Google)

```mermaid
flowchart LR
    A[Inicio app] --> B[Pantalla Login]
    B --> C[Tap en Continue with Google]
    C --> D[Autenticación Google]
    D --> E{¿Token válido?}
    E -- No --> F[Mostrar error y reintentar]
    E -- Sí --> G{¿Usuario nuevo?}
    G -- Sí --> H[Asistente onboarding]
    G -- No --> I{¿Dispositivo sin datos?}
    I -- Sí --> J[¿Restaurar backup?]
    J -- Sí --> K[Restaurar backup]
    K --> L[Dashboard]
    J -- No --> L[Dashboard]
    I -- No --> L[Dashboard]
```

1. La persona abre la aplicación y ve la pantalla de login.
2. Pulsa `Continue with Google`.
3. Completa la autenticación en Google.
4. El sistema valida el token de sesión.
5. Si falla, se muestra error y se permite reintento.
6. Si el token es válido, el sistema decide si es usuario nuevo o existente.
7. Usuario nuevo: entra al onboarding.
8. Usuario existente: se verifica si el dispositivo tiene datos.
   - Si no hay datos, se pregunta si desea restaurar un backup.
   - Si hay datos o se restaura el backup, se accede al dashboard.

## 2. Configuración inicial (Onboarding 1→5)

```mermaid
flowchart LR
    A[Onboarding 1: Perfil básico] --> B[Onboarding 2: Biometría]
    B --> C[Onboarding 3: Notificaciones]
    C --> D[Onboarding 4: Restaurar backup]
    D --> E[Onboarding 5: Cloud Sync]
    E --> F[Get Started]
    F --> G[Dashboard]
```

1. Se solicita completar datos básicos del perfil.
2. Se ofrece activar autenticación biométrica.
3. Se configuran preferencias de notificaciones.
4. Se propone restaurar backup (archivo o nube) o continuar manualmente.
5. Se ofrece activar sincronización en la nube.
6. La persona confirma con `Get Started`.
7. El sistema redirige al dashboard.

## 3. Navegación principal desde Dashboard

```mermaid
flowchart LR
    O[Open App] --> O1[Sesion valida?]
    O1 -- No --> O2[Login Screen]
    O1 -- Sí --> O3[Biometric?]
    O3 -- Sí --> O4[Biometric Auth]
    O3 -- No --> A[Dashboard]
    A[Dashboard] --> B{Acción principal}
    B --> C[Medical Info]
    B --> D[Lab Test Results]
    B --> E[Documents]
    B --> F[Share]
    B --> G[Alerts]
    B --> H[Profile]
```

1. La persona abre la app.
2. El sistema verifica si la sesión es válida.
3. Si no es válida, se muestra pantalla de login.
4. Si es válida, se verifica si la biometría está activada.
5. Si la biometría está activada, se solicita autenticación biométrica.
6. Si la biometría no está activada o se autentica correctamente, se accede al dashboard.
7. La persona llega al dashboard principal.
8. Revisa estado médico resumido y actividad reciente.
9. Usa tarjetas o barra inferior para navegar.
10. Puede entrar en `Medical Info` para datos clínicos.
11. Puede entrar en `Lab Test Results` para analíticas.
12. Puede entrar en `Documents` para documentación.
13. Puede entrar en `Share`, `Alerts` o `Profile` según objetivo.

## 4. Gestión de información médica

```mermaid
flowchart LR
    O[Open App] --> O1[Sesion valida?]
    O1 -- No --> O2[Login Screen]
    O1 -- Sí --> O3[Biometric?]
    O3 -- Sí --> O4[Biometric Auth]
    O3 -- No --> O5[Dashboard]
    O5[Dashboard] --> A[Medical Information]
    A[Medical Information] --> B{Sección}
    B --> C[Blood Type] --> C1[Editar] --> C2[Guardar cambios] --> M[Información médica actualizada]
    B --> D[Critical Allergies] --> D1[Add or Edit Allergy] --> D2[Guardar cambios] --> M[Información médica actualizada]
    B --> E[Current Medications] --> E1[Add or Edit Medication] --> E2[Guardar cambios] --> M[Información médica actualizada]
    B --> F[Vaccinations] --> F1[Add or Edit Vaccination] --> F2[Guardar cambios] --> M[Información médica actualizada]
    B --> G[Active Diagnoses] --> G1[Add or Edit Diagnosis] --> G2[Guardar cambios] --> M[Información médica actualizada]
    M[Información médica actualizada] --> M1[Medical Information]
```

1. La persona abre la app.
2. El sistema verifica si la sesión es válida.
3. Si no es válida, se muestra pantalla de login.
4. Si es válida, se verifica si la biometría está activada.
5. Si la biometría está activada, se solicita autenticación biométrica.
6. Si la biometría no está activada o se autentica correctamente, se accede al dashboard.
7. La persona llega al dashboard principal.
8. La persona entra en `Medical Information`.
9. Selecciona una sección: `Blood Type`, `Critical Allergies`, `Current Medications`, `Vaccinations` o `Active Diagnoses`.
10. En `Blood Type`, `Critical Allergies`, `Current Medications` o `Vaccinations`, edita la información y guarda cambios.
11. En `Active Diagnoses`, puede editar, borrar o añadir diagnóstico y luego guardar cambios.
12. El sistema muestra `Información médica actualizada`.
13. La vista vuelve a `Medical Information` con los datos actualizados.

## 5. Gestión de resultados de pruebas

```mermaid
flowchart TB
    O[Open App] --> O1[Sesion valida?]
    O1 -- No --> O2[Login Screen]
    O1 -- Sí --> O3[Biometric?]
    O3 -- Sí --> O4[Biometric Auth]
    O3 -- No --> O5[Dashboard]
    O5[Dashboard] --> A[Lab Results]
    A[Lab Results] --> A1[Filtrar por tipo: All/Blood/Hormone/...]
    A1 --> B[Tap Add]
    B --> C{¿Añadir manual o subir documento?}

    C -- Manual --> D[Completar test info]
    D --> E[Añadir valores]
    E --> F[Interpretación y notas]
    F --> G[Adjuntar PDF/Imagen]
    G --> H[Save Result]
    H --> J{¿Resultado ya existe?}
    J -- Sí --> K[Mostrar resultados similares a sobreescribir]
    K --> L[Confirmar sobreescritura]
    L --> I[Lista de resultados actualizada]
    J -- No --> I[Lista de resultados actualizada]

    C -- Subir documento --> R[Subir documento]
    R --> S[Procesar y extraer información]
    S --> T[Mostrar información para revisión]
    T --> U[Usuario revisa y confirma]
    U --> V[Guardar resultado + documento asociado]
    V --> I[Lista de resultados actualizada]

    I --> N{¿Más de un resultado para el dato?}
    N -- Sí --> P[Mostrar histórico + resultado más reciente]
    N -- No --> Q[Mostrar resultado con su estado]
```

1. La persona abre la app.
2. El sistema verifica si la sesión es válida.
3. Si no es válida, se muestra pantalla de login.
4. Si es válida, se verifica si la biometría está activada.
5. Si la biometría está activada, se solicita autenticación biométrica.
6. Si la biometría no está activada o se autentica correctamente, se accede al dashboard.
7. La persona llega al dashboard principal.
8. La persona entra en `Lab Results`.
9. Puede filtrar por tipo (All/Blood/Hormone/...).
10. Pulsa `Add` para crear un nuevo resultado.
11. El usuario puede elgir entre añadir un resultado manualmente o subir un documento para extraer la información.
12. Si elige añadir manualmente
    1. Rellena nombre, fecha y categoría.
    2. Añade valores de laboratorio y unidades.
    3. Introduce interpretación/notas y adjunta documento.
    4. Guarda el resultado.
       - Si el resultado ya existe, se muestra opción de los resultados similares que se sobreescribiran.
13. Si elige subir un documento, el sistema extrae la información relevante y la muestra para revisión antes de guardar.
    1. El sistema procesa el documento, extra la información relevante y la muestra para revisión.
    2. El usuario revisa y confirma la información extraída.
    3. El sistema guarda el resultado y el documento asociado.
14. El sistema lo muestra en la lista con su estado.
15. Si el dato tiene mas de un resultado, se muestra el histórico y el resultado más reciente en la vista principal.

## 6. Gestión documental

```mermaid
flowchart TB
    O[Open App] --> O1[Sesion valida?]
    O1 -- No --> O2[Login Screen]
    O1 -- Sí --> O3[Biometric?]
    O3 -- Sí --> O4[Biometric Auth]
    O3 -- No --> O5[Dashboard]
    O5 --> A[Documents]
    A --> B[Upload New Document]
    B --> C[Documento procesado]
    C --> D[Documento visible en lista]
    D --> E{Acción}
    E --> F[View]
    E --> G[Save/Download]
    E --> H[Share]
    E --> I[Delete]
```

1. La persona abre la app.
2. El sistema verifica si la sesión es válida.
3. Si no es válida, se muestra pantalla de login.
4. Si es válida, se verifica si la biometría está activada.
5. Si la biometría está activada, se solicita autenticación biométrica.
6. Si la biometría no está activada o se autentica correctamente, se accede al dashboard.
7. La persona llega al dashboard principal.
8. La persona abre `Documents`.
9. Sube un nuevo documento médico.
10. El sistema pregunta al usuario si desea procesar el documento para extrar información o simplemente subirlo como archivo.
    1. Si el usuario elige procesar el documento, el sistema lo indexa y extrae la información relevante para mostrarla en la vista de detalles del documento.
    2. El sistema ofrece al usuario la opción de añadir la información extraída a su perfil médico.
11. El sistema lo indexa y lo muestra en la lista.
12. Puede buscar por texto.
13. Sobre cada documento puede ver, descargar/guardar, compartir o eliminar.
14. Si elimina, el sistema confirma y retira el documento de la lista.

## 7. Perfil y contactos de emergencia

```mermaid
flowchart TB
    O[Open App] --> O1[Sesion valida?]
    O1 -- No --> O2[Login Screen]
    O1 -- Sí --> O3[Biometric?]
    O3 -- Sí --> O4[Biometric Auth]
    O4 --> O5[Dashboard]
    O3 -- No --> O5[Dashboard]
    O5 --> A[Profile]

    A --> B[Edit Profile]
    B --> C[Actualizar datos personales]
    C --> D[Guardar cambios]

    A --> E[Emergency Contacts]
    E --> F[Add Contact]
    F --> G[Nombre/Relación/Teléfono/Email]
    G --> H[Confirmar Add Contact]
    H --> I[Contacto añadido en lista]

    E --> J[Eliminar contacto]
    J --> K[Confirmar eliminación]
    K --> L[Contacto retirado de la lista]

    E --> M[Seleccionar contacto principal]
    M --> N[Marcar como contacto principal]
    N --> P[Contacto destacado en la lista]
```

1. La persona abre la app.
2. El sistema verifica si la sesión es válida.
3. Si no es válida, se muestra pantalla de login.
4. Si es válida, se verifica si la biometría está activada.
5. Si la biometría está activada, se solicita autenticación biométrica.
6. Si la biometría no está activada o se autentica correctamente, se accede al dashboard.
7. La persona llega al dashboard principal.
8. La persona entra a `Profile`.
9. Puede editar su información personal.
10. Guarda los cambios del perfil.
11. Dentro de la seccion `Profile`, puede consultar los contactos de emergencia.
12. El usuario puede añadir un contcto de emergencia pulsando `Add`.
13. Completa nombre, relación, teléfono y correo.
14. Confirma con `Add Contact`.
15. El nuevo contacto aparece en la lista.
16. El usuario puede eliminar contactos de emergencia desde la lista.
17. Si elimina un contacto, el sistema confirma y lo retira de la lista.
18. El usuario puede seleccionar un contacto de emergencia como contacto principal para emergencias, el sistema lo marca como contacto de emergencia principal y lo muestra destacado en la lista.

## 8. Alertas y preferencias de notificación

```mermaid
flowchart LR
    O[Open App] --> O1[Sesion valida?]
    O1 -- No --> O2[Login Screen]
    O1 -- Sí --> O3[Biometric?]
    O3 -- Sí --> O4[Biometric Auth]
    O4 --> O5[Dashboard]
    O3 -- No --> O5[Dashboard]
    O5 --> A[Alerts]
    A[Alerts] --> B[Ver notificaciones]
    B --> C[Filtrar All/Unread]
    B --> D[Abrir Settings]
    D --> E[Configurar canales/tipos]
    E --> F[Guardar preferencias]
```

1. La persona abre la app.
2. El sistema verifica si la sesión es válida.
3. Si no es válida, se muestra pantalla de login.
4. Si es válida, se verifica si la biometría está activada.
5. Si la biometría está activada, se solicita autenticación biométrica.
6. Si la biometría no está activada o se autentica correctamente, se accede al dashboard.
7. La persona llega al dashboard principal.
8. La persona accede a `Alerts`.
9. Consulta eventos de acceso y actividad.
10. Filtra por `All` o `Unread`.
11. Entra en ajustes de notificaciones.
12. Activa/desactiva preferencias de recepción.
13. El sistema guarda la configuración.

## 9. Compartición con profesional sanitario (Regular Sharing)

```mermaid
flowchart LR
    O[Open App] --> O1[Sesion valida?]
    O1 -- No --> O2[Login Screen]
    O1 -- Sí --> O3[Biometric?]
    O3 -- Sí --> O4[Biometric Auth]
    O4 --> O5[Dashboard]
    O3 -- No --> O5[Dashboard]
    O5 --> A[Share]
    A[Share] --> B[Share with Physician]
    B --> C[Datos médico + email + notas]
    C --> D[Seleccionar datos a compartir]
    D --> E[Continue to Security Settings]
    E --> F[Duración + contraseña + 2FA + permisos]
    F --> G[Review & Share]
    G --> H[Compartición activa]
```

1. La persona abre la app.
2. El sistema verifica si la sesión es válida.
3. Si no es válida, se muestra pantalla de login.
4. Si es válida, se verifica si la biometría está activada.
5. Si la biometría está activada, se solicita autenticación biométrica.
6. Si la biometría no está activada o se autentica correctamente, se accede al dashboard.
7. La persona llega al dashboard principal.
8. La persona entra en `Share` y selecciona `Share with Physician`.
9. Introduce datos del profesional (nombre, email, notas).
10. Elige qué información médica compartirá.
11. Pasa a `Security Settings`.
12. Configura duración, contraseña, 2FA y permiso de descarga.
13. Revisa y confirma la compartición.
14. El sistema crea acceso seguro temporal y lo registra en actividad.

### 9.1 Flujo de acceso por parte del profesional sanitario

```mermaid
flowchart LR
    O[Professional receives email invitation] --> O1[Click secure access link]
    O1 --> O2[Open web page]
    O2 --> O3{Security settings}
    O3 -- Direct access --> O4[Access granted]
    O3 -- Password required --> O5[Prompt for password]
    O5 --> O6[Verify credentials]
    O6 -- Valid --> O4[Access granted]
    O6 -- Invalid --> O7[Access denied, show error]
    O4 --> O8{2FA configured?}
    O8 -- Yes --> O9[Request user approval for access]
    O9 -- User approves --> O10[Grant access to shared medical information]
    O9 -- User denies --> O7[Access denied, show error]
    O8 -- No --> O10[Grant access to shared medical information]
    O10 --> O11[Log access and notify user]
```

1. El profesional sanitario recibe una invitación de acceso por email.
2. El profesional pulsa el enlace seguro de acceso.
3. El sistema mustra una web y dependiendo de la configuración de seguridad accede directamente o solicita una contraeña.
4. El sistema verifica las credenciales y permisos de acceso.
5. Si el sistema tiene 2FA configurado, solicita al usuario que acepte la solicitud de acceso por parte del profesional sanitario.
6. Una vez el usuario acepta, el sistema concede acceso a la información médica compartida.
7. El sistema registra el acceso y notifica a la persona usuaria.

## 10. Compartición de emergencia (QR/Código)

```mermaid
flowchart LR
    O[Open App] --> O1[Sesion valida?]
    O1 -- No --> O2[Login Screen]
    O1 -- Sí --> O3[Biometric?]
    O3 -- Sí --> O4[Biometric Auth]
    O4 --> O5[Dashboard]
    O3 -- No --> O5[Dashboard]
    O5 --> A[Share]
    A[Share] --> B[Emergency QR]
    B --> C[Seleccionar datos críticos]
    C --> D[Configure Access]
    D --> E[Definir duración]
    E --> F[Generate Emergency Code]
    F --> G[Emergency Code Active]
    G --> H[Responder escanea QR o usa código]
    G --> I[Revoke Emergency Access]
    I --> J[Acceso revocado]
```

1. La persona abre la app.
2. El sistema verifica si la sesión es válida.
3. Si no es válida, se muestra pantalla de login.
4. Si es válida, se verifica si la biometría está activada.
5. Si la biometría está activada, se solicita autenticación biométrica.
6. Si la biometría no está activada o se autentica correctamente, se accede al dashboard.
7. La persona llega al dashboard principal.
8. La persona entra en `Share` y elige `Emergency QR`.
9. Selecciona la información crítica para emergencias.
10. Configura duración del acceso y condiciones de seguridad.
11. Genera código/QR de emergencia.
12. El sistema muestra estado `Emergency Code Active`.
13. El profesional de emergencias accede por QR o código.
14. Se registran accesos y se notifica a la persona usuaria.
15. Si hace falta, la persona revoca el acceso inmediatamente.

### 10.1. Flujo de acceso por código QR en emergencia

```mermaid
flowchart LR
    O[Professional at emergency scene] --> O1[Scan QR Code]
    O1 --> O2[Open secure temporary access page]
    O2 --> O3[Prompt for manual code entry if QR fails]
    O3 --> O4[Professional enters code manually]
    O4 --> O5[System verifies code validity and access conditions]
    O5 -- Valid --> O6[Grant access to selected critical information]
    O5 -- Invalid --> O7[Deny access and show error]
    O6 --> O8[Log access and notify user]
    O8 --> O9[User can revoke access, invalidating code and removing access for emergency professional]
```

1. El profesional de emergencias escanea el código QR
2. El sitema abre el navegador por defecto y redirige a una página segura de acceso temporal.
3. El sistema solicita al profesional que introduzca el código de emergencia manualmente (en caso de no poder escanear el QR).
4. El profesional introduce el código manualmente.
5. El sistema verifica la validez del código y las condiciones de acceso.
6. Si el código es válido, se concede acceso a la información crítica seleccionada.
7. El sistema registra el acceso y notifica a la persona usuaria.
8. La persona usuaria puede revocar el acceso en cualquier momento, lo que invalidará el código y retirará el acceso al profesional de emergencias.

## 11. Configuración y privacidad (Settings)

```mermaid
flowchart LR
O[Open App] --> O1[Sesion valida?]
    O1 -- No --> O2[Login Screen]
    O1 -- Sí --> O3[Biometric?]
    O3 -- Sí --> O4[Biometric Auth]
    O4 --> O5[Dashboard]
    O3 -- No --> O5[Dashboard]
    O5 --> O6[Profile]
    O6 --> A[Settings]
    A[Settings] --> B[Account]
    A --> C[Security & Privacy]
    A --> D[Notifications]
    A --> E[Data & Backup]
    A --> F[Legal & Support]
    A --> G[Danger Zone]
    A --> H[Log Out]
```

1. La persona abre la app.
2. El sistema verifica si la sesión es válida.
3. Si no es válida, se muestra pantalla de login.
4. Si es válida, se verifica si la biometría está activada.
5. Si la biometría está activada, se solicita autenticación biométrica.
6. Si la biometría no está activada o se autentica correctamente, se accede al dashboard.
7. La persona llega al dashboard principal.
8. La persona entra en `Profile` y luego en `Settings`.
9. Gestiona opciones de cuenta y credenciales.
10. Ajusta seguridad, biometría, logs y gestión de accesos.
11. Revisa preferencias de notificación.
12. Gestiona backup/exportación de datos.
13. Consulta información legal y soporte.
14. Puede eliminar datos o cerrar sesión.
