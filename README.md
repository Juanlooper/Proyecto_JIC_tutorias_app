# 📚  Plataforma de Tutorías  (JIC)

> Sistema de gestión de tutorías peer-to-peer para centros educativos.
> Construido con **Flutter**, **Firebase Auth** y **Cloud Firestore**.

---

## 📋 Tabla de Contenidos

- [Descripción General](#-descripción-general)
- [Arquitectura del Proyecto](#-arquitectura-del-proyecto)
- [Árbol de Archivos](#-árbol-de-archivos)
- [Capa de Datos: Modelos](#-capa-de-datos-modelos)
- [Capa de Servicios](#-capa-de-servicios)
- [Capa de Estado: Providers](#-capa-de-estado-providers)
- [Capa de Presentación: Vistas](#-capa-de-presentación-vistas)
- [Flujos de Interacción](#-flujos-de-interacción)
- [Sistema de Diseño (Branding Vecta)](#-sistema-de-diseño-branding-vecta)
- [Configuración y Ejecución](#-configuración-y-ejecución)
- [Seguridad y Reglas de Negocio](#-seguridad-y-reglas-de-negocio)
- [Autores Principales](#-autores-principales)
- [Contexto del Proyecto](#-contexto-del-proyecto)

---

## 🌐 Descripción General

es una aplicación móvil/web que conecta estudiantes que necesitan ayuda académica con tutores calificados dentro del centro educativo. Opera bajo un **modelo tipo Uber**:

1. Un **estudiante** publica una solicitud de tutoría (materia, tema, fecha).
2. La solicitud aparece en la **Bolsa de Solicitudes** visible para todos los tutores.
3. Un **tutor** revisa la solicitud, proporciona lugar y contacto, y la reclama.
4. El sistema usa **transacciones atómicas** de Firestore para evitar que dos tutores acepten la misma solicitud simultáneamente (prevención de Race Condition).
5. Un **administrador** supervisa métricas, postulaciones, baneos y quejas.

### Roles del Sistema

| Rol | Acceso |
|---|---|
| **Estudiante** | Cartelera, crear solicitudes, inscribirse en tutorías, perfil, comunidad |
| **Tutor** | Bolsa de solicitudes, mis pendientes, finalizadas, pase de lista, perfil |
| **Admin** | Todo lo del estudiante + Panel de Administración (métricas, baneos, quejas, postulaciones) |

---

## 🏗 Arquitectura del Proyecto

El proyecto sigue una arquitectura en capas con el patrón **Provider** para gestión de estado:

```
┌─────────────────────────────────────────┐
│            PRESENTACIÓN (Views)          │  ← Widgets de Flutter (UI)
├─────────────────────────────────────────┤
│           ESTADO (Providers)             │  ← ChangeNotifier + notifyListeners
├─────────────────────────────────────────┤
│           SERVICIOS (Services)           │  ← Comunicación directa con Firebase
├─────────────────────────────────────────┤
│            DATOS (Models)                │  ← Estructuras Dart (toMap/fromMap)
├─────────────────────────────────────────┤
│     FIREBASE (Auth + Firestore)          │  ← Backend en la nube
└─────────────────────────────────────────┘
```

**Flujo de datos:**
`Vista → Provider → Servicio → Firebase → Servicio → Provider → Vista (rebuild)`

---

## 🗂 Árbol de Archivos

```
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
│   ├── tutorias_provider.dart          # Estado global de tutorías (CRUD + transacciones)
│   ├── admin_provider.dart             # Estado del panel de administración
│   ├── evaluacion_provider.dart        # Estado del sistema de evaluación
│   └── notificaciones_provider.dart    # Estado de notificaciones in-app
│
└── views/
    ├── auth/
    │   ├── login_view.dart             # Pantalla de inicio de sesión
    │   └── registro_view.dart          # Pantalla de registro de nuevos usuarios
    │
    ├── navigation/
    │   ├── enrutador_roles_view.dart   # Enrutador que redirige según el rol del usuario
    │   └── main_navigation_view.dart   # Navegación principal con tabs superiores
    │
    ├── home/
    │   ├── home_view.dart              # Cartelera pública de tutorías disponibles
    │   └── crear_tutoria_view.dart     # Formulario para crear nueva solicitud de tutoría
    │
    ├── tutor/
    │   ├── dashboard_tutor_view.dart   # Panel principal del tutor (Bolsa + Pendientes + Finalizadas)
    │   ├── aceptar_solicitud_view.dart # Pantalla para revisar y aceptar una solicitud
    │   └── detalle_clase_view.dart     # Detalle de clase con pase de asistencia
    │
    ├── tutorias/
    │   └── mis_tutorias_view.dart      # Listado personalizado de tutorías del usuario
    │
    ├── explore/
    │   └── explorar_view.dart          # Vista de comunidad y exploración de tutores
    │
    ├── profile/
    │   └── perfil_view.dart            # Perfil del usuario con edición y cerrar sesión
    │
    ├── admin/
    │   ├── admin_dashboard_view.dart   # Centro de mando del administrador
    │   ├── tribunal_baneos_view.dart   # Gestión de suspensiones de usuarios
    │   ├── buzon_postulaciones_view.dart # Revisión de postulaciones de tutores
    │   ├── quejas_view.dart            # Gestión de quejas y cancelaciones tardías
    │   ├── metricas_view.dart          # Gráficas y estadísticas del sistema
    │   ├── lista_estudiantes_view.dart # Listado de estudiantes activos
    │   └── historial_tutorias_view.dart # Historial completo de tutorías
    │
    └── widgets/
        ├── tutorial_vecta_widget.dart  # Modal de onboarding para nuevos usuarios
        └── vecta_buttons.dart          # Botones reutilizables con estilo Vecta
```

---

## 📦 Capa de Datos: Modelos

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

## ⚙ Capa de Servicios

### `autenticacion_servicio.dart`
Comunicación directa con **Firebase Auth**. Es el "recepcionista" del sistema.

| Método | Qué hace |
|---|---|
| `registrarNuevoUsuario()` | Crea cuenta en Auth + perfil en Firestore |
| `iniciarSesion()` | Valida correo/contraseña contra Firebase |
| `cerrarSesion()` | Destruye la sesión activa |
| `obtenerDatosDelUsuarioActual()` | Lee el perfil completo desde Firestore |
| `enviarVerificacionDeCorreo()` | Dispara email de verificación |
| `enviarRecuperacionDeContrasena()` | Envía enlace de recuperación de contraseña |

### `base_de_datos_servicio.dart`
Comunicación directa con **Cloud Firestore** para tutorías.

| Método | Qué hace |
|---|---|
| `crearNuevaTutoria()` | Inserta un documento en la colección `tutorias` |
| `obtenerTutoriasPendientes()` | Query filtrado por `estado == 'pendiente'` |
| `unirseATutoria()` | Transacción atómica para inscripción (protege cupo) |
| `aceptarTutoria()` | Asigna tutor con validación de solapamiento de horario |

### `usuario_servicio.dart`
Actualización de datos académicos del perfil (facultad y carrera).

### `evaluacion_servicio.dart`
Servicio de reputación y calificaciones entre usuarios.

---

## 🧠 Capa de Estado: Providers

### `autenticacion_provider.dart`
**El cerebro de identidad.** Conecta `AutenticacionServicio` con toda la UI.

| Getter/Método | Función |
|---|---|
| `usuarioActual` | El usuario logueado actual (o `null`) |
| `estaCargando` | Semáforo para spinners de carga |
| `mensajeDeError` | Texto del último error para SnackBars |
| `perfilCompleto` | `true` solo si nombre + facultad + carrera están llenos |
| `inicializarSesionAlAbrirApp()` | Restaura sesión previa al abrir la app |
| `ingresarConCorreoYClave()` | Login con validación de email verificado |
| `registrarseEnElSistemaGlobal()` | Registro con creación de perfil en Firestore |
| `salirDeLaSesionActual()` | Logout + limpieza de RAM |
| `dispararVerificacionDeCorreo()` | Envía email de verificación |
| `solicitarCambioDeContrasena()` | Envía email de recuperación |
| `gestionarSuscripcionATutor()` | Follow/Unfollow con FieldValue.arrayUnion/Remove |
| `actualizarInformacionPerfil()` | Actualiza facultad y carrera (con try-catch) |

### `tutorias_provider.dart`
**El motor operativo de tutorías.** Maneja toda la lógica de negocio CRUD.

| Getter/Método | Función |
|---|---|
| `tutoriasPendientesGenerales` | Lista pública filtrada (excluye ocultas por el tutor) |
| `tutoriasSuscritasDelUsuario` | Lista privada del usuario (como tutor y como alumno) |
| `totalHorasDictadas` | Cálculo automático de horas acumuladas |
| `cargarListadoDeTutoriasPendientes()` | Descarga tutorías pendientes con filtro opcional por carrera |
| `crearAperturaDeNuevaTutoria()` | Publica nueva solicitud en Firestore |
| `inscribirseEnTutoria()` | Inscripción transaccional (valida cupo + duplicados) |
| `ocultarSolicitudParaMi()` | Oculta solicitud en memoria local del tutor |
| `aceptarTutoria()` | Asignación de tutor con validación de negocio |
| `aceptarSolicitudEstudiante()` | **🔐 Transacción Atómica Uber** — Asigna tutor con protección anti Race Condition |
| `limpiarClasesVencidas()` | Purga automática de clases expiradas (+30 min sin inscritos) |
| `registrarAsistenciaClase()` | Pase de lista + strikes por ausencia |
| `cancelarAsistenciaAlumno()` | Retiro de inscripción con advertencia si <12h |
| `cancelarClaseTutor()` | Cancelación formal + queja automática si <12h |

### `admin_provider.dart`
Gestiona métricas y datos estadísticos del panel administrativo.

### `evaluacion_provider.dart`
Maneja el sistema de calificación y reputación de tutores.

### `notificaciones_provider.dart`
Controla notificaciones in-app para alertas y avisos.

---

## 🖥 Capa de Presentación: Vistas

### Autenticación (`views/auth/`)

| Archivo | Descripción |
|---|---|
| `login_view.dart` | Portal Académico rediseñado basado en Vecta Branding. Implementa `LayoutBuilder` para diseño responsivo: Split-screen en Escritorio/Web (Formulario izquierdo + Tarjetas informativas derecha con gradiente) y apilamiento vertical en móviles. |
| `registro_view.dart` | Formulario extenso con campos personales (nombre, cédula, celular), académicos (facultad, carrera, inglés), credenciales (correo, contraseña), botón de CV, checkbox legal. 11 controladores con `dispose()`. |

### Navegación (`views/navigation/`)

| Archivo | Descripción |
|---|---|
| `enrutador_roles_view.dart` | **Cerebro de tráfico.** Escucha `authStateChanges()` con `StreamBuilder`. Redirige: Admin → `MainNavigationView`, Tutor → `DashboardTutorView`, Estudiante → `MainNavigationView`. Ejecuta onboarding `TutorialVectaWidget` en primer inicio. |
| `main_navigation_view.dart` | Navegación horizontal superior con tabs dinámicos generados desde lista unificada de módulos. Incluye logo con fallback, tabs por rol (Admin ve "Métricas"), `IndexedStack` sincronizado con guard defensivo. |

### Home (`views/home/`)

| Archivo | Descripción |
|---|---|
| `home_view.dart` | Cartelera pública que muestra tutorías pendientes disponibles. |
| `crear_tutoria_view.dart` | Formulario completo para crear solicitud: materia, tema, modalidad, cupo, duración, selector de fecha/hora. Valida perfil completo antes de permitir acceso. Publica con `identificadorDelTutor = ''` (sin tutor = entra a la bolsa). |

### Panel de Tutor (`views/tutor/`)

| Archivo | Descripción |
|---|---|
| `dashboard_tutor_view.dart` | **Centro de operaciones del tutor.** `DefaultTabController` reactivo mediante un `StreamBuilder` generalizado. Pestañas: **Bolsa de Solicitudes**, **Mis Pendientes** y **Finalizadas**. Tarjetas colorimétricas auto-actualizables (sin recargas manuales). |
| `aceptar_solicitud_view.dart` | Pantalla de revisión detallada de una solicitud. Muestra info del alumno solicitante, materia, fecha, motivos y enlaces adjuntos. Formulario con campos de Lugar y Contacto. Botón verde "ACEPTAR SOLICITUD" que ejecuta la transacción atómica. 2 controladores con `dispose()`. |
| `detalle_clase_view.dart` | Detalle completo de una clase con funcionalidad de pase de asistencia. |

### Tutorías del Usuario (`views/tutorias/`)

| Archivo | Descripción |
|---|---|
| `mis_tutorias_view.dart` | `DefaultTabController` reactivo (`StreamBuilder`). Contiene 3 pestañas: **Calendario** interactivo (con filtrado por día), **Próximas** (a las que el alumno debe asistir) e **Historial** (pasadas para agilizar la evaluación). |

### Exploración (`views/explore/`)

| Archivo | Descripción |
|---|---|
| `explorar_view.dart` | Vista de comunidad y búsqueda de tutores utilizando `StreamBuilder` para mantener un listado actualizado en tiempo real sin recargar, e incluye un `SearchBar` funcional. |

### Perfil (`views/profile/`)

| Archivo | Descripción |
|---|---|
| `perfil_view.dart` | Perfil del usuario interactivo. Permite la edición dinámica de Carrera, Facultad y Datos de Contacto mediante diálogos superpuestos. Detecta el rol automáticamente y gestiona el cierre de sesión mediante alertas. |
| `perfil_publico_tutor_view.dart` | Renderiza de manera elegante los datos públicos e historial de cualquier usuario. Presenta las métricas calculadas (Tutorías dadas, Estrellas promedio, etc.). Limita la visualización de datos privados siguiendo estrictas reglas de negocio basadas en los Roles. |

### Administración (`views/admin/`)

| Archivo | Descripción |
|---|---|
| `admin_dashboard_view.dart` | Grid de 6 módulos con tarjetas interactivas: Baneos, Postulaciones, Quejas, Métricas, Estudiantes, Historial. Logo con fallback, logout con confirmación. |
| `tribunal_baneos_view.dart` | Gestión de suspensiones de cuentas por infracciones. |
| `buzon_postulaciones_view.dart` | Revisión y aprobación de solicitudes para ser tutor. |
| `quejas_view.dart` | Gestión de quejas auto-generadas por cancelaciones tardías. |
| `metricas_view.dart` | Dashboard con gráficas y estadísticas del sistema. |
| `lista_estudiantes_view.dart` | Directorio de estudiantes activos en la plataforma. |
| `historial_tutorias_view.dart` | Registro histórico de todas las tutorías. |

### Widgets Reutilizables (`views/widgets/`)

| Archivo | Descripción |
|---|---|
| `tutorial_vecta_widget.dart` | Modal de onboarding con contenido diferenciado por rol. Se muestra solo una vez usando `SharedPreferences`. |
| `vecta_buttons.dart` | Componentes de botones estilizados con el branding Vecta. |

---

## 🔄 Flujos de Interacción

### 1. Flujo de Registro e Ingreso

```
Usuario abre app
  → main.dart inicializa Firebase + Providers
  → Consumer<AutenticacionProvider> verifica sesión previa
  → ¿Hay sesión? 
      SÍ → EnrutadorRolesView (decide pantalla por rol)
      NO → LoginView
  
  LoginView:
    → Usuario llena correo + contraseña
    → Provider.ingresarConCorreoYClave()
    → Servicio.iniciarSesion() → Firebase Auth
    → ¿Email verificado? 
        NO → "Verifica tu correo" + logout forzado
        SÍ → Servicio.obtenerDatosDelUsuarioActual() → Firestore
            → Provider._usuarioActual = datos
            → notifyListeners() → UI se reconstruye
            → EnrutadorRolesView redirige según rol
```

### 2. Flujo "Uber" — Solicitar y Aceptar Tutoría

```
ESTUDIANTE:
  CrearTutoriaView
    → Llena materia, tema, fecha, hora, cupo
    → TutoriaModel con identificadorDelTutor = '' (SIN TUTOR)
    → Provider.crearAperturaDeNuevaTutoria()
    → Servicio.crearNuevaTutoria() → Firestore
    → Solicitud aparece en la "Bolsa" global

TUTOR:
  DashboardTutorView → Pestaña "Bolsa de Solicitudes"
    → Ve tarjeta con botón "Ver y Aceptar"
    → Navigator.push → AceptarSolicitudView
    → Revisa: materia, fecha, motivos, enlaces
    → Llena: lugar + contacto
    → Presiona "ACEPTAR SOLICITUD"
    → Provider.aceptarSolicitudEstudiante()
      → Firestore.runTransaction()
        → Lee documento en tiempo real
        → ¿identificadorDelTutor está vacío?
            SÍ → Escribe UID del tutor + lugar + contacto
            NO → throw Exception("Ya fue aceptada")  ← RACE CONDITION BLOCKED
    → SnackBar verde → Navigator.pop()
```

### 3. Flujo de Pase de Asistencia

```
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

### 4. Flujo de Cancelación con Auditoría

```
Tutor presiona "Cancelar clase"
  → Provider.cancelarClaseTutor()
    → ¿Faltan < 12 horas? 
        SÍ → Crea documento en colección 'quejas' (auditoría automática)
    → Estado → 'cancelada'
    → justificacion_cancelacion → texto del tutor
```

### 5. Flujo de Enrutamiento por Rol

```
EnrutadorRolesView
  → StreamBuilder escucha authStateChanges()
  → ¿Firebase tiene usuario?
      SÍ + Provider tiene datos → 
        Admin  → MainNavigationView (con pestaña "Métricas")
        Tutor  → DashboardTutorView (Bolsa + Pendientes + Finalizadas)
        Estudiante → MainNavigationView (Cartelera + Tutorías + Comunidad + Perfil)
      NO → CircularProgressIndicator (esperando)
```

---

## 🎨 Sistema de Diseño (Branding Vecta)

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

## 🛠 Configuración y Ejecución

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
- Modo QA activo: La validación de dominio `@utp.ac.pa` está temporalmente desactivada para pruebas.

### Transacciones Atómicas (Anti Race Condition)
- `aceptarSolicitudEstudiante()` — Lee y escribe en una sola transacción Firestore. Si otro tutor se adelantó, lanza excepción sin corromper datos.
- `inscribirseEnTutoria()` — Verifica cupo disponible atómicamente antes de inscribir.
- `registrarAsistenciaClase()` — Actualiza asistencia y strikes en una sola transacción.

### Reglas de Negocio
- Un tutor no puede ser estudiante de su propia solicitud.
- Cancelaciones con < 12 horas de antelación generan quejas automáticas.
- Inasistencia genera strikes (incremento atómico en perfil del alumno).
- Tutorías sin inscritos que pasen +30 min de su hora se cancelan automáticamente.
- Perfiles incompletos (sin facultad/carrera) no pueden crear solicitudes.
- Privacidad Estudiantil: Los estudiantes solo pueden ver perfiles públicos de tutores y administradores. Se ocultan por restricción de acceso los perfiles públicos directos entre estudiantes convencionales.

### Prevención de Memory Leaks
- Todos los `TextEditingController` tienen su `dispose()` implementado.
- Todos los llamados a Firebase están envueltos en `try-catch`.

---

## 🧑‍💻 Autores Principales

| Autor | Rol | Responsabilidades |
|---|---|---|
| **Juan Rodriguez** | Programador & Gestor del Proyecto | Arquitectura del sistema, desarrollo backend y frontend, integración con Firebase, gestión de sprint y coordinación general del equipo. |
| **Alejandra Falcon** | Diseñadora Principal de Frontend | Diseño UI/UX, maquetación de pantallas, sistema de diseño visual, branding, prototipado, experiencia de usuario y coherencia estética en toda la aplicación. |
| **Miguel Oliver** | Auditor & Programador | Auditoría de código, revisión de calidad (QA), pruebas de estabilidad, corrección de bugs, optimización de rendimiento y validación de reglas de negocio. |

---

## 🌎 Contexto del Proyecto

**Plataforma de Tutorías** es un proyecto desarrollado de manera **grupal** para la **JIC (Jornada de Iniciación Científica)** de **Panamá**, en el marco de la Universidad Tecnológica de Panamá.

### Pruebas con Grupo Vecta

Durante la fase de desarrollo y validación, se utilizó al **Grupo Vecta** como medio para realizar las **pruebas de producto iniciales**. El branding, la identidad visual y los datos de prueba están basados en este grupo, lo que permitió iterar sobre la plataforma con usuarios reales en un entorno educativo controlado.

### Adaptabilidad

> [!IMPORTANT]
> Aunque las pruebas iniciales se realizaron con Vecta, **la plataforma está pensada y diseñada para ser adaptada a cualquier centro educativo**. La arquitectura modular, los roles configurables y el sistema de diseño parametrizado permiten que cualquier institución académica pueda adoptar la herramienta con mínimas modificaciones — basta con ajustar el branding, las reglas de dominio de correo y la configuración de Firebase.

---

> **Versión:** 1.0 Release Candidate  
> **Última actualización:** Abril 2026
