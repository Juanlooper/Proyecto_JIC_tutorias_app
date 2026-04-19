# Plataforma de Tutorías (JIC)

> Sistema de gestión de tutorías peer-to-peer para centros educativos.
> Construido con **Flutter**, **Firebase Auth** y **Cloud Firestore**.

---

## Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Arquitectura del Proyecto](#arquitectura-del-proyecto)
- [Árbol de Archivos](#árbol-de-archivos)
- [Capa de Datos: Modelos](#capa-de-datos-modelos)
- [Capa de Servicios](#capa-de-servicios)
- [Capa de Estado: Providers](#capa-de-estado-providers)
- [Capa de Presentación: Vistas](#capa-de-presentación-vistas)
- [Flujos de Interacción](#flujos-de-interacción)
- [Módulo de Moderación y Calidad](#módulo-de-moderación-y-calidad)
- [Sistema de Diseño (Branding Vecta)](#sistema-de-diseño-branding-vecta)
- [Configuración y Ejecución](#configuración-y-ejecución)
- [Seguridad y Reglas de Negocio](#seguridad-y-reglas-de-negocio)
- [Autores Principales](#autores-principales)
- [Contexto del Proyecto](#contexto-del-proyecto)

---

## Descripción General

Es una aplicación móvil/web que conecta estudiantes que necesitan ayuda académica con tutores calificados dentro del centro educativo. Opera bajo un **modelo tipo Uber**:

1. Un **estudiante** publica una solicitud de tutoría (materia, tema, fecha).
2. La solicitud aparece en la **Bolsa de Solicitudes** visible para todos los tutores.
3. Un **tutor** revisa la solicitud, proporciona lugar y contacto, y la reclama.
4. El sistema usa **transacciones atómicas** de Firestore para evitar que dos tutores acepten la misma solicitud simultáneamente (prevención de Race Condition).
5. Los **tutores** también pueden crear **Clases Fijas** (con recurrencia semanal, mensual, o semestral) para que los estudiantes se inscriban directamente desde la Cartelera pública.
6. Un **administrador** supervisa métricas, postulaciones, baneos y gestiona de manera centralizada las quejas y comentarios.

### Roles del Sistema

| Rol | Acceso |
|---|---|
| **Estudiante** | Cartelera, crear solicitudes, inscribirse en tutorías, levantar quejas contra tutores, evaluar clases (solo si asistió), perfil, comunidad |
| **Tutor** | Bolsa de solicitudes, impartir "Clases Fijas", aceptar y programar peticiones, listado de mis pendientes, pase de lista, ver comentarios en su perfil público |
| **Admin** | Todo lo del estudiante + Panel de Administración unificado (métricas, moderación activa de reseñas y quejas, baneos, postulaciones) |

---

## Arquitectura del Proyecto

El proyecto sigue una arquitectura en capas con el patrón **Provider** para gestión de estado:

```text
┌─────────────────────────────────────────┐
│            PRESENTACIÓN (Views)         │  ← Widgets de Flutter (UI)
├─────────────────────────────────────────┤
│           ESTADO (Providers)            │  ← ChangeNotifier + notifyListeners
├─────────────────────────────────────────┤
│           SERVICIOS (Services)          │  ← Comunicación directa con Firebase
├─────────────────────────────────────────┤
│            DATOS (Models)               │  ← Estructuras Dart (toMap/fromMap)
├─────────────────────────────────────────┤
│     FIREBASE (Auth + Firestore)         │  ← Backend en la nube
└─────────────────────────────────────────┘
```

**Flujo de datos:**
`Vista → Provider → Servicio → Firebase → Servicio → Provider → Vista (rebuild)`

---

## Árbol de Archivos

```text
lib/
├── main.dart                           # Punto de entrada, inicializa Firebase y Providers
├── firebase_options.dart               # Configuración auto-generada de Firebase
│
├── core/
│   └── theme/
│       └── app_theme.dart              # Paleta de colores, tipografía y ThemeData global
│
├── models/
│   ├── usuario_model.dart              # Modelo de datos del usuario (UID, rol, facultad, etc.)
│   └── tutoria_model.dart              # Modelo de datos de tutoría (materia, estado, lugar, etc.)
│
├── services/
│   ├── autenticacion_servicio.dart     # CRUD de sesión con Firebase Auth
│   ├── base_de_datos_servicio.dart     # CRUD de tutorías con Cloud Firestore
│   ├── usuario_servicio.dart           # Actualización de datos académicos del usuario
│   └── evaluacion_servicio.dart        # Servicio de reputación y calificaciones
│
├── providers/
│   ├── autenticacion_provider.dart     # Estado global de sesión e identidad
│   ├── tutorias_provider.dart          # Estado global de tutorías (CRUD, transacciones, recurrencias)
│   ├── admin_provider.dart             # Estado del panel de administración
│   ├── evaluacion_provider.dart        # Estado del sistema de evaluación
│   └── notificaciones_provider.dart    # Estado de notificaciones in-app
│
└── views/
    ├── auth/
    │   ├── login_view.dart             # Pantalla de inicio de sesión (solucionado bug de F5)
    │   └── registro_view.dart          # Pantalla de registro de nuevos usuarios
    │
    ├── navigation/
    │   ├── enrutador_roles_view.dart   # Enrutador que redirige según el rol del usuario
    │   └── main_navigation_view.dart   # Navegación principal con tabs superiores (oculta FAB inteligentemente)
    │
    ├── home/
    │   ├── home_view.dart              # Cartelera pública de tutorías disponibles
    │   └── crear_tutoria_view.dart     # Formulario para crear nueva solicitud de tutoría
    │
    ├── tutor/
    │   ├── dashboard_tutor_view.dart   # Panel principal del tutor (Bolsa + Pendientes + Finalizadas)
    │   ├── aceptar_solicitud_view.dart # Pantalla interactiva "Read-only" para revisión de fecha/hora y configuración de lugar
    │   └── detalle_clase_view.dart     # Detalle de clase con enlaces interactivos (SelectableText)
    │
    ├── tutorias/
    │   └── mis_tutorias_view.dart      # Listado personalizado de tutorías con FAB de "Crear Clase Fija"
    │
    ├── explore/
    │   ├── explorar_view.dart          # Vista de comunidad y exploración de tutores
    │   └── perfil_publico_tutor_view.dart # Visualización de reseñas y botón de reporte (Quejas)
    │
    ├── profile/
    │   └── perfil_view.dart            # Perfil del usuario con edición rápida
    │
    ├── admin/
    │   ├── admin_dashboard_view.dart   # Centro de mando del administrador
    │   ├── metricas_view.dart          # Dashboard con pestañas integradas de Estadísticas y Moderación (Quejas)
    │   ├── tribunal_baneos_view.dart   # Gestión de suspensiones de usuarios
    │   ├── buzon_postulaciones_view.dart # Revisión de postulaciones de tutores
    │   └── historial_tutorias_view.dart # Historial completo de tutorías
    │
    └── widgets/
        ├── tutorial_vecta_widget.dart  # Modal de onboarding para nuevos usuarios
        └── vecta_buttons.dart          # Botones reutilizables con estilo Vecta
```

---

## Capa de Datos: Modelos

### `usuario_model.dart`

Representa a cualquier persona registrada en la plataforma.

| Campo | Tipo | Descripción |
|---|---|---|
| `identificadorUnico` | `String` | UID de Firebase Auth |
| `nombreCompleto` | `String` | Nombre y apellido concatenados |
| `correoElectronico` | `String` | Credencial de acceso |
| `rolEnElSistema` | `RolSistema` | Enum: `estudiante`, `tutor`, `admin` |
| `facultad` | `String?` | Facultad universitaria |
| `carrera` | `String?` | Carrera universitaria |
| `listaDeTutoresSuscritos` | `List<String>` | UIDs de tutores seguidos |
| `strikes_inasistencia` | `int` | Contador de faltas acumuladas |
| `esta_baneado` | `bool` | Indica si la cuenta está suspendida |
| `estado_solicitud_tutor` | `String` | `'ninguna'`, `'en_revision'`, `'aprobado'` |

**Métodos clave:**
- `toMap()` → Mapa para guardar en Firestore.
- `fromMap()` → Construye instancia desde datos de Firestore (con defaults anti-crash).
- `tieneRol(RolSistema)` → Verifica permisos rápidamente.
- `copyWith()` → Clona con campos modificados.

---

### `tutoria_model.dart`

Representa una sesión de tutoría completa.

| Campo | Tipo | Descripción |
|---|---|---|
| `identificadorDeTutoria` | `String` | ID único de la sesión |
| `materiaOAsignatura` | `String` | Nombre de la materia |
| `temaEspecifico` | `String` | Detalle del tema a estudiar |
| `carrera` | `String` | Carrera asociada |
| `identificadorDelTutor` | `String` | UID del tutor asignado (vacío = disponible en bolsa) |
| `listaDeEstudiantesInscritos` | `List<String>` | UIDs de alumnos inscritos |
| `modalidadDeClase` | `String` | `'Virtual'` o `'Presencial'` |
| `estadoDeLaSolicitud` | `String` | `'pendiente'`, `'aceptada'`, `'finalizada'`, `'cancelada'` |
| `fechaHoraSugerida` | `DateTime` | Fecha y hora programada |
| `enlaceOReunion` | `String?` | URL de Meet/Zoom o nombre de salón |
| `cupoMaximo` | `int` | Capacidad máxima de estudiantes |
| `duracionMinutos` | `int` | Duración planificada |
| `horaInicioReal` / `horaFinReal` | `DateTime?` | Timestamps reales de la sesión |
| `esGrupal` | `bool` | Si acepta múltiples alumnos |
| `motivos_alumnos` | `Map<String, String>?` | Llave: UID alumno, Valor: razón de la solicitud |
| `enlaces_adjuntos` | `Map<String, List<String>>?` | Material de apoyo por alumno |
| `registro_asistencia` | `Map<String, bool>?` | Registro de asistencia |
| `justificacion_cancelacion` | `String?` | Motivo de cancelación |
| `lugar` | `String?` | Ubicación acordada (biblioteca, enlace, etc.) |
| `contacto_tutor` | `String?` | WhatsApp o correo del tutor |

---

## Capa de Servicios

### `autenticacion_servicio.dart`
Comunicación directa con **Firebase Auth**. Es el "recepcionista" del sistema.

### `base_de_datos_servicio.dart`
Comunicación directa con **Cloud Firestore** para tutorías e inserción de quejas.

### `usuario_servicio.dart`
Actualización de datos académicos del perfil (facultad y carrera).

### `evaluacion_servicio.dart`
Servicio de reputación y calificaciones entre usuarios.

---

## Capa de Estado: Providers

### `autenticacion_provider.dart`
**El cerebro de identidad.** Conecta `AutenticacionServicio` con toda la UI. Maneja mapeo de fallos de red, bugfixes de navegación y actualización de UI dinámica.

### `tutorias_provider.dart`
**El motor operativo.** Maneja toda la lógica CRUD, creación de recurrencias (clases fijas en bucle) y transacciones atómicas seguras. Impide bloqueos temporales e incluye limpiezas programadas.

### `admin_provider.dart`
Gestiona métricas y datos estadísticos del panel administrativo.

### `evaluacion_provider.dart`
Maneja el sistema de calificación y reputación de tutores.

### `notificaciones_provider.dart`
Controla notificaciones in-app para alertas y avisos.

---

## Flujos de Interacción

### 1. Flujo de Enrutamiento por Rol
```text
EnrutadorRolesView
  → StreamBuilder escucha authStateChanges()
  → ¿Firebase tiene usuario?
      SÍ + Provider tiene datos → 
        Admin  → MainNavigationView (con pestaña "Métricas")
        Tutor  → DashboardTutorView (Bolsa + Pendientes + Finalizadas)
        Estudiante → MainNavigationView (Cartelera + Tutorías + Perfil)
      NO → CircularProgressIndicator (esperando)
```

### 2. Flujo "Uber" — Sugerencias y Aceptación
1. Un **Estudiante** lanza una "Sugerencia Huérfana".
2. Un **Tutor** la visualiza en la Bolsa publicá. Al hacer clic en "Postularme como Tutor", es redirigido a la vista `AceptarSolicitudView`.
3. El tutor inspecciona en modo "Solo-Lectura" la fecha requerida, mientras rellena sus datos de **Lugar**, **Contacto** y **Cupo Máximo**.
4. Tras su confirmación, usa una **Transacción Atómica en Firestore** previniendo *Race Conditions*. Luego la solicitud abandona la Bolsa y viaja a ser una tutoría impartible.

### 3. Flujo de Clases Fijas (Recurrencias Temporales)
1. El **Tutor** utiliza su panel "Mis Tutorías" y clica el Floating Action Button de "Crear Clase Fija".
2. Selecciona la Repetición (`1 semana`, `4 semanas`, etc.).
3. El Provider clona e inyecta múltiples documentos separados por intervalos de 7 días exactos. Los estudiantes las verán enlistadas secuencialmente en la Cartelera.

### 4. Flujo de Pase de Asistencia
```text
Tutor ve tutoría en "Mis Pendientes"
  → Presiona "Iniciar pase de lista"
  → Navigator.push → DetalleClaseView
  → Marca asistencia por alumno (true/false)
  → Provider.registrarAsistenciaClase()
    → Firestore.runTransaction()
      → Actualiza registro_asistencia
      → Cambia estado a 'finalizada'
      → Por cada alumno con false → FieldValue.increment(strikes)
```

### 5. Flujo de Cancelación con Auditoría
```text
Tutor presiona "Cancelar clase"
  → Provider.cancelarClaseTutor()
    → ¿Faltan < 12 horas? 
        SÍ → Crea documento en colección 'quejas' (auditoría automática)
    → Estado → 'cancelada'
    → justificacion_cancelacion → texto del tutor
```

---

## Módulo de Moderación y Calidad

El sistema ahora cuenta con políticas automáticas de moderación orientadas a la sana interacción:
- **Reseñas Públicas y Evaluaciones:** En el `perfil_publico_tutor_view`, todos los roles pueden revisar comentarios directos y puntuación general (estrellas) que los alumnos le dan a sus tutores. Para garantizar veracidad, **solo estudiantes que sí asistieron** (registro validado por el tutor) tienen acceso al botón "Calificar".
- **Buzón de Quejas Comunitarias:** Directamente en el perfil público del tutor, los estudiantes pueden cliquear el ícono de Reporte e inicializar el formulario para enviar reportes y banderas rojas de inconducta de forma discreta a los DB admins.
- **Acción Administrativa Concentrada:** La pestaña del `admin_dashboard_view` integra limpiamente "Quejas y Cancelaciones Tardías" en la central de **Métricas**. Asimismo, un Administrador visualiza íconos de basurero interactivos en las Reseñas que permite un control en caliente contra campañas de difamación.

---

## Sistema de Diseño (Branding Vecta)

Definido en `lib/core/theme/app_theme.dart`:

| Token | Valor | Uso |
|---|---|---|
| `primarioAzul` | `#1951CB` | Botones principales, enlaces, acentos |
| `primarioVerde` | `#1CA887` | AppBar de tutores, botones de éxito, chips |
| `fondoClaro` | `#F8FAFC` | Scaffold background global |
| `textoOscuro` | `#1E2938` | Títulos y texto principal |
| `grisTexto` | `#8B929A` | Texto secundario y placeholders |
| `verdeClaro` | `#8AD1C2` | Acentos decorativos suaves |
| `azulClaro` | `#89A6E4` | Acentos decorativos suaves |

**Tipografía:**
- **Títulos:** Poppins (via Google Fonts) — Bold
- **Cuerpo:** Inter (via Google Fonts) — Regular

**Componentes visuales recurrentes:**
- Tarjetas con `borderRadius: 16`, `boxShadow: black12, blur: 10`
- Chips de estado con color dinámico según `estadoDeLaSolicitud`
- Logo con `errorBuilder` que renderiza "VECTA" en texto como fallback en Web
- Botones full-width con `borderRadius: 12` y altura `50-56px`

---

## Configuración y Ejecución

### Prerrequisitos
- Flutter SDK ≥ 3.x
- Dart ≥ 3.x
- Proyecto Firebase configurado (Auth + Firestore)

### Instalación

```bash
# Clonar el repositorio
git clone <url-del-repo>
cd Proyecto_JIC_tutorias_app

# Instalar dependencias
flutter pub get

# Ejecutar en Chrome (Web)
flutter run -d chrome

# Ejecutar en dispositivo móvil
flutter run
```

### Dependencias Principales

| Paquete | Uso |
|---|---|
| `firebase_core` | Inicialización de Firebase |
| `firebase_auth` | Autenticación de usuarios |
| `cloud_firestore` | Base de datos en tiempo real |
| `provider` | Gestión de estado reactivo |
| `google_fonts` | Tipografía Poppins e Inter |
| `shared_preferences` | Almacenamiento local (onboarding) |

---

## Seguridad y Reglas de Negocio

### Autenticación
- Verificación de email obligatoria antes de permitir login.
- Cierre de sesión forzado tras registro (el usuario debe verificar correo primero).
- Modo QA activo: La validación de dominio `@utp.ac.pa` está temporalmente desactivada para pruebas iniciales.

### Prevención de Memory Leaks
- Todos los `TextEditingController` tienen su `dispose()` implementado activamente.
- Todos los llamados a Firebase están envueltos de forma inteligente en mecanismos `try-catch`.

### Transacciones Atómicas (Anti Race Condition)
- `aceptarSolicitudEstudiante()` — Lee y escribe en una sola transacción Firestore. Si otro tutor se adelantó, lanza excepción sin corromper datos.
- `inscribirseEnTutoria()` — Verifica cupo disponible atómicamente antes de inscribir.
- `registrarAsistenciaClase()` — Actualiza asistencia y strikes en una sola transacción.

### Reglas de Negocio
- Un tutor **no puede** ser estudiante ni aceptar su propia solicitud (Restricción Cruzada activada).
- Cancelaciones con < 12 horas de antelación generan *quejas automáticas* que van directo al panel Admin.
- Inasistencia genera `strikes` (incremento atómico en perfil del alumno), y bloquea los derechos de evaluación en la respectiva sesión; evita reportes de rating envenenado (`review-bombing`).
- Tutorías sin inscritos que pasen +30 min de su hora se cancelan automáticamente por el sistema.
- Perfiles incompletos (sin facultad/carrera) no pueden crear solicitudes.
- Privacidad Sensible: Las vistas comunitarias restringen totalmente los detalles y perfiles de los estudiantes ante otros estudiantes externos.

---

## Autores Principales

| Autor | Rol | Responsabilidades |
|---|---|---|
| **Juan Rodriguez** | Programador & Gestor del Proyecto | Arquitectura del sistema, desarrollo backend y frontend, integración con Firebase, gestión de sprint y coordinación general del equipo. |
| **Alejandra Falcon** | Diseñadora Principal de Frontend | Diseño UI/UX, maquetación de pantallas, sistema de diseño visual, branding, prototipado, experiencia de usuario y coherencia estética en toda la aplicación. |
| **Miguel Oliver** | Auditor & Programador | Auditoría de código, revisión de calidad (QA), pruebas de estabilidad, corrección de bugs, optimización de rendimiento y validación de reglas de negocio. |

---

## Contexto del Proyecto

**Plataforma de Tutorías** es un proyecto desarrollado de manera **grupal** para la **JIC (Jornada de Iniciación Científica)** de **Panamá**, en el marco de la Universidad Tecnológica de Panamá.

### Pruebas con Grupo Vecta

Durante la fase de desarrollo y validación, se utilizó al **Grupo Vecta** como medio para realizar las **pruebas de producto iniciales**. El branding, la identidad visual y los datos de prueba están basados en este grupo, lo que permitió iterar sobre la plataforma con usuarios reales en un entorno educativo controlado.

### Adaptabilidad

> [!IMPORTANT]
> Aunque las pruebas iniciales se realizaron con Vecta, **la plataforma está pensada y diseñada para ser adaptada a cualquier centro educativo**. La arquitectura modular, los roles configurables y el sistema de diseño parametrizado permiten que cualquier institución académica pueda adoptar la herramienta con mínimas modificaciones — basta con ajustar el branding, las reglas de dominio de correo y la configuración de Firebase.

---

> **Versión:** 1.0 Release Candidate  
> **Última actualización:** Abril 2026
