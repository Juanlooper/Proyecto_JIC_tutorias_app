# Plataforma de Tutorías (JIC)

> Sistema integral de gestión de tutorías peer-to-peer para centros educativos.
> Construido con **Flutter**, **Firebase Auth**, **Cloud Firestore**, **Firebase Storage**, y **Cloud Functions**.

---

## Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Roles del Sistema](#roles-del-sistema)
3. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
4. [Árbol de Archivos](#árbol-de-archivos)
5. [Capa de Datos: Modelos](#capa-de-datos-modelos)
6. [Capa de Servicios](#capa-de-servicios)
7. [Capa de Estado: Providers](#capa-de-estado-providers)
8. [Capa de Presentación: Vistas](#capa-de-presentación-vistas)
9. [Flujos de Interacción](#flujos-de-interacción)
10. [Módulo de Archivos y Notificaciones](#módulo-de-archivos-y-notificaciones)
11. [Módulo de Moderación y Calidad](#módulo-de-moderación-y-calidad)
12. [Sistema de Diseño (Branding Vecta)](#sistema-de-diseño-branding-vecta)
13. [Configuración y Ejecución](#configuración-y-ejecución)
14. [Seguridad y Reglas de Negocio](#seguridad-y-reglas-de-negocio)
15. [Autores Principales](#autores-principales)
16. [Contexto del Proyecto](#contexto-del-proyecto)

---

## Descripción General

Es una aplicación móvil y web escalable que conecta estudiantes que necesitan ayuda académica con tutores calificados dentro de su mismo centro educativo. Opera de manera dinámica y en tiempo real bajo un **modelo tipo Uber**:

1. Un **estudiante** publica una solicitud de tutoría especificando la materia, el tema, la fecha sugerida y puede **adjuntar archivos de estudio** (PDFs o Imágenes).
2. La solicitud aparece en la **Bolsa de Solicitudes**, una cartelera pública visible en tiempo real para todos los tutores de la plataforma. El sistema envía una **notificación In-App** a todos los tutores alertándolos.
3. Un **tutor** revisa la solicitud, inspecciona los archivos adjuntos (con soporte para visor nativo del SO), proporciona un lugar de encuentro (o enlace virtual) y sus datos de contacto, y la reclama.
4. El sistema usa **transacciones atómicas** de Firestore para evitar colisiones (evitando que dos tutores acepten la misma solicitud al mismo milisegundo).
5. Se disparan **Notificaciones Push** (Cloud Messaging) automatizadas y **Notificaciones In-App** al dispositivo del estudiante avisándole que su tutoría fue aceptada, instándolo a inscribirse oficialmente.
6. Los **tutores** también tienen el poder de crear proactivamente **Clases Fijas** (con recurrencias lógicas de 1, 2, 3 o 4 semanas) para que los estudiantes se inscriban libremente hasta llenar el cupo. Los inscritos o aquellos en cola de sugerencias reciben notificaciones cuando el **cupo se llena** o un alumno **abandona** la clase.
7. Un **administrador** (moderador global) supervisa todas las métricas, aprueba postulaciones de tutores, ejerce baneos, y gestiona de manera centralizada las quejas de mala conducta.

---

## Roles del Sistema

| Rol | Nivel de Acceso y Funcionalidades |
|---|---|
| **Estudiante** | Acceso a la Cartelera de clases fijas, creación de solicitudes huérfanas, subida de archivos adjuntos nativos, inscripción en tutorías existentes, levantar quejas secretas contra tutores, evaluar clases, gestión de perfil, explorar comunidad de tutores, visualización de notificaciones In-App, y recepción de notificaciones Push (ej. cancelaciones de clases, aceptación de tutorías). |
| **Tutor** | Acceso a la Bolsa de solicitudes huérfanas, visualización y descarga nativa de adjuntos de los alumnos, creación y programación de "Clases Fijas" recurrentes, aceptación de peticiones, listado de agenda pendiente, pase de lista (registro de asistencia), visualización de su propio perfil, y recepción de notificaciones In-App (nuevas sugerencias, abandonos, inscripciones, evaluaciones). |
| **Admin** | Todo lo del estudiante + Panel de Administración unificado. Tienen el poder de ver métricas globales, ejercer moderación activa de reseñas y quejas, ejecutar baneos de usuarios problemáticos, aprobar postulaciones para ascender estudiantes a tutores, y auditar cancelaciones de clases a última hora. |

### Pantallas Visibles por Rol

A continuación, se detalla a qué vistas (pantallas) tiene acceso cada rol en la aplicación:

**0. Público (No autenticado o Accesible por todos)**
- **Bienvenida (`LandingScreen`)**: Pantalla de aterrizaje con la identidad visual oficial de Vecta.
- **Ayuda y Soporte (`AyudaScreen`, `SoporteScreen`)**: Secciones de preguntas frecuentes y formulario para contactar a soporte técnico.

**1. Estudiante**
- **Cartelera (`HomeView`)**: Feed principal de clases ofertadas por tutores.
- **Mis Tutorías (`MisTutoriasView`)**: Listado de clases a las que el estudiante se ha inscrito.
- **Sugerencias (`MisSugerenciasView`)**: Historial y estado de las tutorías solicitadas en la Bolsa.
- **Bolsa de la Comunidad (`ComunidadSugerenciasView`)**: Vista donde los estudiantes pueden ver solicitudes huérfanas creadas por otros y apoyarlas sumándose a ellas.
- **Comunidad (`ExplorarView`)**: Buscador general de la comunidad de tutores y sus reseñas.
- **Perfil (`PerfilView`)**: Gestión de datos académicos y biografía.
- **Notificaciones (`NotificacionesView`)**: Centro In-App de alertas.
- **Sugerir Clase (`SugerirTutoriaView`)**: Formulario para crear nuevas solicitudes con adjuntos.

**2. Tutor**
- *Tiene acceso a todas las pantallas base del estudiante, y además:*
- **Tablero Tutor (`DashboardTutorView`)**: Panel central para administrar clases pendientes, finalizadas y el pase de lista.
- **Aceptar Solicitud (`AceptarSolicitudView`)**: Interfaz donde el tutor define parámetros (fecha, lugar, cupo) al reclamar una tutoría.
- **Detalle de Clase (`DetalleClaseView`)**: Vista enfocada para auditar asistencia y abrir de forma nativa los archivos subidos por los alumnos.

**3. Administrador**
- *Tiene acceso a las pantallas base del estudiante, y además:*
- **Métricas (`AdminDashboardView` / `MetricasView`)**: Centro de mando con gráficas y estadísticas globales del uso del sistema.
- **Tribunal de Baneos (`TribunalBaneosView`)**: Panel para resolver quejas, auditar cancelaciones y banear usuarios.
- **Buzón de Postulaciones (`BuzonPostulacionesView`)**: Interfaz para revisar y aprobar o rechazar a estudiantes que desean convertirse en tutores.
- **Historial de Tutorías (`HistorialTutoriasView`)**: Registro general y auditable de todas las tutorías dadas en la plataforma.
- **Lista de Estudiantes (`ListaEstudiantesView`)**: Panel de listado y gestión de la totalidad de usuarios registrados en el sistema.
- **Quejas (`QuejasView`)**: Panel dedicado exclusivamente a la revisión de denuncias emitidas contra tutores.

---

## Arquitectura del Proyecto

El proyecto está diseñado bajo una arquitectura limpia en capas, utilizando fuertemente el patrón **Provider** para la inyección de dependencias y gestión de estado. Al ser Serverless, delega toda su lógica de backend a los servicios de Firebase.

```text
┌────────────────────────────────────────────────────────┐
│               PRESENTACIÓN (Vistas y UI)               │  ← Widgets de Flutter
├────────────────────────────────────────────────────────┤
│             ESTADO GLOBAL (Providers)                  │  ← ChangeNotifier
├────────────────────────────────────────────────────────┤
│             SERVICIOS FRONTEND (Services)              │  ← Lógica de red y auth
├────────────────────────────────────────────────────────┤
│             DATOS (Modelos Serializables)              │  ← Estructuras Dart
├────────────────────────────────────────────────────────┤
│            FIREBASE (Backend en la Nube)               │
│  Auth  |  Firestore  |  Storage  |  FCM  |  Functions  │
└────────────────────────────────────────────────────────┘
```

**Flujo de Datos Típico:**
El usuario interactúa con una `View` → Llama a un método del `Provider` → El `Provider` ejecuta lógica de negocio y llama al `Service` → El `Service` manipula `Firebase` → Si hay un cambio global, Firebase Functions dispara una alerta Push / El `Provider` crea una Notificación In-App → El `Provider` hace `notifyListeners()` → La `View` se reconstruye reactivamente.

---

## Árbol de Archivos

```text
lib/
├── main.dart                           # Punto de entrada, inicializa Firebase, Notificaciones y Providers
├── firebase_options.dart               # Configuración auto-generada de Firebase
│
├── core/
│   └── theme/
│       └── app_theme.dart              # Paleta de colores, tipografía Vecta y ThemeData global
│
├── models/
│   ├── usuario_model.dart              # Modelo de datos del usuario (UID, rol, strikes, etc.)
│   └── tutoria_model.dart              # Modelo de datos de tutoría (adjuntos, inasistencias, links)
│
├── services/
│   ├── autenticacion_servicio.dart     # CRUD de sesión con Firebase Auth
│   ├── base_de_datos_servicio.dart     # Transacciones e inserciones en Firestore
│   ├── firebase_storage_servicio.dart  # Subida, descarga y borrado de PDFs/Imágenes nativos
│   ├── notificaciones_servicio.dart    # Configuración de FCM (Firebase Cloud Messaging) local
│   ├── usuario_servicio.dart           # Actualización de datos académicos del usuario
│   └── evaluacion_servicio.dart        # Servicio de reputación y calificaciones
│
├── providers/
│   ├── autenticacion_provider.dart     # Estado global de sesión e identidad
│   ├── tutorias_provider.dart          # Estado de tutorías (CRUD, transacciones, recolector de basura, in-app notifications)
│   ├── admin_provider.dart             # Estado del panel de administración
│   ├── evaluacion_provider.dart        # Estado del sistema de evaluación
│   └── notificaciones_provider.dart    # Gestor de tokens push FCM
│
├── views/
│   ├── auth/                           # Pantallas de Login y Registro
│   ├── navigation/                     # Enrutadores principales según Rol y Bottom Nav Bar
│   ├── home/                           # Cartelera principal y Formulario de Sugerencias
│   ├── tutor/                          # Paneles exclusivos para Tutores (Dashboard, Pase de Lista)
│   ├── tutorias/                       # Listados personalizados de las tutorías del usuario
│   ├── explore/                        # Explorador de comunidad (Buscador de talento y reseñas)
│   ├── profile/                        # Vista y edición de perfil del usuario
│   ├── admin/                          # Centro de mando del Administrador (Métricas, Quejas, Auditorías)
│   ├── notifications/
│   │   └── notificaciones_view.dart    # Centro de notificaciones In-App con soporte de pull-to-refresh
│   └── widgets/                        # Componentes UI reutilizables (Botones, Tutoriales)
│
└── functions/
    ├── index.js                        # Cloud Function (Node 20) orquestando Push Notifications selectivos
    └── package.json                    # Dependencias backend de la nube
```

---

## Capa de Datos: Modelos

### `usuario_model.dart`

Representa a cualquier persona registrada en la plataforma. Estandarizado a `camelCase` en Flutter, manteniendo compatibilidad con `snake_case` en Firestore.

| Campo en Dart | Tipo | Descripción |
|---|---|---|
| `identificadorUnico` | `String` | UID seguro provisto por Firebase Auth |
| `nombreCompleto` | `String` | Nombre y apellido concatenados |
| `correoElectronico` | `String` | Credencial de acceso (única) |
| `rolEnElSistema` | `RolSistema` | Enumerador: `estudiante`, `tutor`, `admin` |
| `facultad` | `String?` | Facultad universitaria a la que pertenece |
| `carrera` | `String?` | Carrera universitaria actual |
| `listaDeTutoresSuscritos` | `List<String>` | Lista de UIDs de tutores que sigue (Bookmarks) |
| `strikesInasistencia` | `int` | Contador de inasistencias comprobadas. Al llegar a 3, alerta al Admin. |
| `estaBaneado` | `bool` | Flag crítico: Indica si la cuenta tiene el acceso restringido. |
| `estadoSolicitudTutor` | `String` | `'ninguna'`, `'en_revision'`, `'aprobado'` (Proceso de postulación) |
| `descripcionPerfil` | `String?` | Biografía que el tutor redacta para convencer a la comunidad. |
| `telefonoPersonal` | `String?` | Contacto de WhatsApp |

---

### `tutoria_model.dart`

Representa una sesión de tutoría altamente parametrizada, lista para ser procesada en la base de datos.

| Campo | Tipo | Descripción |
|---|---|---|
| `identificadorDeTutoria` | `String` | ID único de la sesión autogenerado |
| `materiaOAsignatura` | `String` | Título del conocimiento requerido |
| `temaEspecifico` | `String` | El syllabus específico a tratar |
| `identificadorDelTutor` | `String` | UID del tutor. Si está vacío `''`, la solicitud está huérfana en la Bolsa. |
| `listaDeEstudiantesInscritos` | `List<String>` | Arreglo de UIDs que reservaron cupo en la tutoría. |
| `modalidadDeClase` | `String` | Modalidad seleccionada (`'Virtual'` o `'Presencial'`) |
| `estadoDeLaSolicitud` | `String` | `'pendiente'`, `'aceptada'`, `'finalizada'`, `'cancelada'` |
| `fechaHoraSugerida` | `DateTime` | El *deadline* o fecha pactada |
| `enlaceOReunion` | `String?` | URL para clases virtuales, o salón (ej. "Edificio 3, Piso 2") |
| `cupoMaximo` | `int` | Capacidad máxima que dicta el tutor (ej. 15 alumnos) |
| `esGrupal` | `bool` | Bandera rápida de renderizado de UI para saber si es 1 a 1. |
| `motivos_alumnos` | `Map<String, String>?` | UID alumno → Razón textual por la que necesita la clase. |
| `enlaces_adjuntos` | `Map<String, List<String>>?` | UID alumno → Arreglo de URLs de Firebase Storage con los PDFs/Imágenes subidos. |
| `nombres_adjuntos` | `Map<String, List<String>>?` | UID alumno → Arreglo de nombres legibles (ej. `"guia_fisica_2.pdf"`). |
| `registro_asistencia` | `Map<String, bool>?` | UID alumno → `true` (asistió) o `false` (faltó, genera strike). |
| `justificacion_cancelacion` | `String?` | Si el tutor cancela abruptamente, su excusa queda guardada aquí. |
| `lugar` | `String?` | Dirección estática u observaciones del punto de encuentro. |

---

## Capa de Servicios

1. **`autenticacion_servicio.dart`**: Comunicación directa con Auth. Maneja logs, creación de tokens y verificación de correos institucionales.
2. **`base_de_datos_servicio.dart`**: La maquinaria pesada. Transacciones seguras con Cloud Firestore para la creación, lectura y borrado de documentos de tutorías, así como la inserción auditada de quejas.
3. **`firebase_storage_servicio.dart`**: Interfaz con Google Cloud Storage. Permite subir archivos controlando su límite de tamaño (5 MB), abrir nativamente archivos subidos por estudiantes, y vaciar Storage.
4. **`notificaciones_servicio.dart`**: Gestor FCM que pide permisos al OS (iOS/Android/Web) y suscribe al usuario a recepción de notificaciones Push.
5. **`usuario_servicio.dart`**: Controlador para la edición del perfil académico personal.
6. **`evaluacion_servicio.dart`**: Módulo matemático para agregar estrellas de calificaciones y emitir los cálculos de promedios de cada tutor.

---

## Capa de Estado: Providers

Toda la aplicación reactiva es controlada aquí mediante `ChangeNotifier`:

- **`autenticacion_provider.dart`**: Cerebro de la identidad. Transforma un stream de Auth en un usuario sólido cacheado. Maneja el control de sesiones, evita la suplantación y controla el "estado de carga" al entrar a la app.
- **`tutorias_provider.dart`**: El núcleo de operaciones. Gestiona el CRUD completo, se encarga de crear copias recursivas al pedir "Clases Fijas", maneja las cancelaciones atómicas, inyecta alertas **In-App** en 8 flujos distintos a la base de datos (firestore) de notificaciones, y ejecuta el **Recolector de Basura** para vaciar Firebase Storage cuando una tutoría muere.
- **`admin_provider.dart`**: Agrupa y procesa matemáticamente las métricas (número de quejas, tutorías globales, reportes) para renderizar gráficas limpias en el dashboard.
- **`evaluacion_provider.dart`**: Rastrea si el estudiante actual ya calificó una tutoría finalizada específica para impedir doble votación.
- **`notificaciones_provider.dart`**: Almacena y sincroniza el "Token de Dispositivo" para habilitar notificaciones push backend.

---

## Capa de Presentación: Vistas

| Categoría | Vistas Principales | Descripción |
|---|---|---|
| **Público** | `landing_screen`, `ayuda_screen`, `soporte_screen` | Pantalla inicial de bienvenida con la marca Vecta, sección de FAQs y formulario de contacto para soporte técnico. |
| **Autenticación** | `login_view`, `registro_view` | Flujo unificado con buscador dinámico de carreras, validación estricta (cédula, teléfonos) y Términos & Condiciones desplegables. |
| **Navegación** | `enrutador_roles_view`, `main_navigation_view` | Deciden de manera instantánea a qué tab enviar al usuario tras iniciar sesión basándose en su `rolEnElSistema`. Posee Campanita de Alertas centralizada. |
| **Principal (Home)**| `home_view`, `sugerir_tutoria_view`, `comunidad_sugerencias_view` | La "Cartelera". Aquí el alumno ve el feed estilo red social con las clases ofertadas, llena su solicitud subiendo archivos adjuntos o apoya sugerencias en la bolsa comunitaria. |
| **Estudiante** | `mis_sugerencias_view`, `mis_tutorias_view` | Seguimiento de las tutorías sugeridas y agenda personal de clases inscritas. |
| **Tutor** | `dashboard_tutor_view`, `aceptar_solicitud_view`, `detalle_clase_view` | Paneles con pestañas (Pendientes / Finalizadas). En `detalle_clase_view` el tutor da clic a los archivos subidos por el alumno y los abre directamente con el visor nativo. |
| **Notificaciones** | `notificaciones_view` | Historial de alertas de la plataforma, filtrado por usuario y con manejo robusto de excepciones (pull to refresh local). |
| **Comunidad** | `explorar_view`, `perfil_publico_tutor_view` | Buscador de talento. Muestra las biografías de los tutores, su promedio de estrellas y el botón rojo de levantar una queja a la administración. |
| **Administración**| `admin_dashboard_view`, `metricas_view`, `tribunal_baneos_view`, `buzon_postulaciones_view`, `historial_tutorias_view`, `lista_estudiantes_view`, `quejas_view` | Centro de comando. Vista de alto impacto con gráficas e interruptores para banear o des-banear a un usuario con 1 clic. Adicionalmente agrupa historiales y gestión completa de postulaciones, usuarios y quejas. |

---

## Flujos de Interacción

### 1. Flujo "Uber" — Creación y Aceptación
1. **Estudiante:** Presiona "+" → Rellena materia y tema → Sube un PDF de sus ejercicios → "Sugerir Tutoría". (La tutoría nace con estado `pendiente` y `idTutor: ''`). Se alerta In-App a todos los Tutores.
2. **Tutor:** Entra a su "Bolsa de Solicitudes" (o presiona la alerta en la campana). Ve la petición. Le da a "Aceptar".
3. **App:** Pasa a la vista de configuración. El tutor confirma lugar, fecha exacta y cupo. Confirma.
4. **Backend:** Se dispara una **Transacción Atómica**. Firestore verifica que en ese microsegundo nadie más haya reclamado la clase. Pasa el estado a `aceptada` y asigna su UID.
5. **Nube:** La Cloud Function detecta el cambio e inmediatamente dispara un Push Notification al estudiante incitándolo a inscribirse oficialmente.

### 2. Flujo de Subida de Archivos Adjuntos (Nativo)
1. Durante la reserva de cupo o creación de sugerencia, el estudiante presiona "Añadir Archivos".
2. `file_picker` invoca la galería nativa de Android/iOS o explorador de Windows.
3. Se verifica tamaño (< 5 MB).
4. `firebase_storage_servicio.dart` sube el archivo a `/tutorias/{id_tutoria}/{archivo.pdf}` y devuelve la URL pública cifrada, almacenándola en el array del documento.
5. El Tutor abre la tutoría e invoca `url_launcher` para ver los PDFs / Imágenes sin salir del flujo.

### 3. Flujo de Pase de Asistencia e Inasistencia
1. Terminada la hora, el tutor abre su "Panel de Clases Pendientes" → "Iniciar Pase de Lista".
2. Visualiza a todos los inscritos con un Toggle *Switch* (✅ / ❌).
3. Al darle a guardar, la app ejecuta una sola petición masiva (`runTransaction`):
   - Cambia estado a `finalizada`.
   - A cada alumno marcado con ❌ le suma `+1` a su propiedad `strikesInasistencia` en el modelo global de Usuarios.

### 4. Flujo de Cancelación y Auditoría
1. Tutor se le presenta una emergencia. Entra a la clase y presiona "Cancelar".
2. La app le obliga a redactar una justificación de 30 caracteres mínimo.
3. La app revisa el reloj: ¿Faltan menos de 12 horas para la clase?
   - Si SÍ: Genera un reporte automático e invisible hacia la colección de `quejas` catalogado como "Cancelación Tardía Abusiva".
   - Borra la clase del feed.
4. **Garbage Collection:** El Provider manda a destruir toda la carpeta de archivos en Cloud Storage vinculada a esa tutoría para evitar guardar basura inútil en el servidor.
5. **Avisos Masivos:** La función Cloud Functions dispara alertas a todos los estudiantes que se habían inscrito en esa clase explicándoles la cancelación.

### 5. Flujo de Registro Unificado
1. El estudiante ingresa sus datos con formateo automático en tiempo real (Cédula `00-0000-000000`, Celulares `+507 0000-0000`).
2. Selecciona su Facultad y utiliza el **Buscador Dinámico** (`DropdownMenu`) para filtrar y elegir su carrera exacta de la UTP.
3. Despliega y lee los **Términos, Condiciones y Políticas de Vecta** integrados fluidamente en el formulario antes de aceptar.
4. El sistema crea la cuenta en Firebase Auth, inyecta el perfil académico en Firestore y emite un correo de verificación institucional.

---

## Módulo de Archivos y Notificaciones

El corazón comunicativo del sistema, estructurado en dos pilares simultáneos:

### 1. In-App Notifications (Persistentes)
Un centro de notificaciones (representado por una "campanita" en el Header) que guarda localmente en Firestore 8 flujos vitales de comunicación, manteniendo un registro auditable e interactivo:
1. Alerta a tutores de **Nueva Sugerencia en la Bolsa**.
2. Alerta a estudiante de **Sugerencia Aceptada**.
3. Alerta a estudiantes apoyadores si un **Cupo se Llenó**.
4. Alerta a tutor de **Nuevo Estudiante Inscrito**.
5. Alerta a tutor si un **Estudiante Abandonó** su clase.
6. Alerta a inscritos de **Tutoría Cancelada** por fuerza mayor.
7. Alerta a tutor de **Nueva Evaluación Recibida**.

### 2. Push Notifications (Cloud Functions FCM)
Servidor Node.js 20 backend en Firebase (`functions/index.js`) con `onUpdate` triggers. 
1. Si un estado cambia a `aceptada`, la nube dispara automáticamente FCM push al móvil / navegador del estudiante que estaba en cola, alertando de que el tutor está listo.
2. Si un estado cambia a `cancelada`, lanza Push Notifications a la lista de estudiantes inscritos, de modo que se enteran sin tan siquiera abrir la aplicación.

### 3. Limpieza Ecológica de Storage
Para evitar facturas astronómicas de Cloud, la lógica de `TutoriasProvider` está enlazada estrechamente a los métodos de eliminación. Tutoría muerta / abortada = Carpeta de almacenamiento limpia instantáneamente en la nube.

---

## Módulo de Moderación y Calidad

Para evitar que la plataforma se vuelva caótica, el sistema promueve el sano comportamiento:

- **Sistema Anti-Review Bombing:** ¿Un alumno falta a clase y quiere ponerle 1 estrella al tutor por despecho? Imposible. La UI de evaluación comprueba si el alumno asistió; si tiene falta marcada, el sistema le bloquea el acceso a las reseñas.
- **Filtro Léxico Dinámico (Moderador de Lenguaje):** Algoritmo que detecta palabras prohibidas, toxicidad, y variantes ofuscadas (como Leetspeak y homoglifos) tanto en nombres de usuario como en las justificaciones o descripciones.
- **Botón de Pánico (Quejas):** Si un tutor tiene conductas inapropiadas, su perfil tiene un botón rojo de reporte. Envía la data cifrada directamente a la mesa del Admin.
- **Moderación de Reseñas y Calificaciones:** Si un alumno deja un comentario vulgar, el Admin tiene la jerarquía para borrar el comentario abusivo desde la UI. Además, calificaciones iguales o menores a 2 estrellas generan alertas automáticas a los administradores.
- **Tribunal de Baneos:** El administrador revisa a los alumnos con altos *strikes* o tutores con demasiadas quejas, y puede apagar su bandera `estaBaneado`. Si la bandera está en `true`, `Auth` no les permitirá entrar a la app en el próximo log-in.

---

## Sistema de Diseño (Branding Vecta)

El código es puramente temático y estandarizado, dictado por `lib/core/theme/app_theme.dart`.

| Nombre del Token | Código Hexadecimal | Propósito UI |
|---|---|---|
| `primarioAzul` | `#1951CB` | Botones de Llamada a la Acción, Iconos, AppBar activa |
| `primarioVerde` | `#1CA887` | Botones de Éxito, Chips de status, Interfaces de Tutor |
| `fondoClaro` | `#F8FAFC` | Background relajante de toda la app (Scaffold) |
| `textoOscuro` | `#1E2938` | Alta legibilidad para textos y títulos H1/H2 |
| `grisTexto` | `#8B929A` | Metadatos, fechas y placeholders |

**Tipografía Exclusiva:**
- Uso de `GoogleFonts.poppins` para cabeceras prominentes y gruesas.
- Uso de `GoogleFonts.inter` para párrafos densos, priorizando la legibilidad humana.

---

## Configuración y Ejecución

### Prerrequisitos del Entorno
- Flutter SDK ≥ 3.20.x
- Dart SDK ≥ 3.x
- Cuenta en Firebase Console con plan *Blaze* (requerido para Cloud Functions y Storage).
- Node.js 20+ instalado localmente (si vas a programar más Functions).

### Instalación Rápida

```bash
# 1. Clonar el repositorio
git clone https://github.com/Juanlooper/Proyecto_JIC_tutorias_app.git
cd Proyecto_JIC_tutorias_app

# 2. Descargar todo el ecosistema de dependencias Flutter
flutter pub get

# 3. Correr la app en modo emulador web
flutter run -d chrome

# O bien, lanzar en tu teléfono Android / iOS físico
flutter run
```

### Despliegue de Reglas de Seguridad (Admin)
Si modificas el código de Firebase, protege la base de datos haciendo:
```bash
firebase deploy --only firestore:rules,storage
firebase deploy --only functions
firebase deploy --only hosting
```

---

## Seguridad y Políticas de Protección de Datos

El sistema ha superado múltiples auditorías de seguridad (incluyendo escaneos de vulnerabilidades críticas) y opera bajo un estricto modelo de Confianza Cero (Zero Trust) a nivel de servidor.

### 1. Reglas Firestore Strict-Mode (Defensa contra exploits)
- **Escudo de Privilegios (Escalamiento Bloqueado):** Ningún cliente puede modificar su propio campo `rolEnElSistema`, `estaBaneado` o `strikes_inasistencia`. Aunque un usuario malintencionado haga ingeniería inversa a la App y reescriba la petición HTTP hacia Firebase, el servidor rechazará la mutación. Solo procesos backend o un `admin` pueden alterar estas propiedades.
- **Protección de Tutorías (Anti-Hack JIC):** Se mitigó una vulnerabilidad crítica que permitía la alteración masiva de clases. Ahora, la regla `allow update` evalúa criptográficamente que la modificación solo provenga de: el creador de la tutoría, el tutor asignado, o un estudiante legítimamente inscrito. Ningún alumno externo puede borrar a los participantes ni alterar los horarios de clases de otros.
- **Blindaje contra Espionaje de Notificaciones:** Inicialmente la lectura de notificaciones era global. Se implementó una verificación estricta (`resource.data.usuarioId == request.auth.uid`) para que cada dispositivo y usuario solo pueda desencriptar y leer las notificaciones y mensajes dirigidos exclusivamente a su UID.
- **Eliminación Lógica vs Física:** Se prohíbe rotundamente el borrado de documentos de perfil (`allow delete: if false`). En su lugar, el sistema emplea "soft deletes" y banderas booleanas para mantener la integridad de la base de datos histórica.

### 2. Firewall de Firebase Storage
- **Validación de Tipos MIME (Regex):** La puerta de entrada de archivos rechaza sistemáticamente cualquier subida que no sea explícitamente `application/pdf` o formato de imagen (`image/.*`), bloqueando la inyección de malware o scripts maliciosos.
- **Límite Físico (Denial of Wallet):** Existe un límite infranqueable de `5 MB` por cada petición de subida para prevenir que un atacante sature el servidor con peticiones masivas.
- **Protección contra Borrado Masivo:** Se clausuró el acceso público a las eliminaciones en bloque; la purga de carpetas de almacenamiento quedó delegada de manera exclusiva al recolector de basura nativo del administrador o del proceso de limpieza del backend.

### 3. Reglas de Negocio y Privacidad del Usuario
- **Cumplimiento de Ley 81 (Protección de Datos - Panamá):** Se recogen los datos estrictamente necesarios bajo el consentimiento explícito del estudiante (implementado con un formulario obligatorio de Términos y Condiciones).
- **Cifrado de Credenciales:** Todas las transacciones de inicio de sesión utilizan algoritmos nativos AES manejados por Google Identity.
- **Filtro Anti-Review Bombing:** Lógica a nivel de vista y backend para impedir que estudiantes evalúen a tutores de clases a las que nunca asistieron (verificando el `registro_asistencia`).

### 4. Autenticación y Ciberseguridad Activa (Hardening)
- **Firebase App Check (Play Integrity & reCAPTCHA v3):** Se bloqueó el acceso público al ecosistema de Firebase. La base de datos y los buckets solo responden si la petición proviene de un humano en la web (reCAPTCHA v3 invisible) o desde la app oficial de Android sin alterar ni emular (Play Integrity), mitigando el *scraping* y ataques de denegación de servicio.
- **Hardening de Contraseñas:** Se rechazan claves débiles mediante expresiones regulares. La plataforma exige contraseñas alfanuméricas de al menos 8 caracteres que incluyan obligatoriamente símbolos, mayúsculas y números.

### 5. Términos, Condiciones y Política de Privacidad de Vecta
Durante el registro, el usuario debe aceptar un contrato legal detallado. A continuación, se desglosa el propósito de cada cláusula estipulada en la aplicación:

1. **Marco Legal y Derechos del Usuario (Derechos ARCO):** Garantiza que Vecta opera bajo la Ley No. 81 de Panamá. Asegura al estudiante que tiene el derecho de **Acceder, Rectificar, Cancelar u Oponerse** al uso de sus datos en cualquier momento.
2. **¿Qué datos recopilamos y para qué?:** Principio de transparencia. Explica que solo se recopilan datos de contacto institucionales y académicos (Facultad/Carrera) para alimentar el algoritmo de matchmaking de tutorías, asegurando que no se venderá la información a terceros.
3. **Ciberseguridad y Almacenamiento:** Da tranquilidad al usuario final explicando que su contraseña no se guarda en texto plano, sino mediante encriptación asimétrica de Firebase, y que la plataforma cuenta con autenticación segura.
4. **Reglas de Uso y Conducta:** Establece las bases para los baneos. Prohíbe explícitamente la suplantación de identidad, el bullying en los espacios de clase, el spam y los intentos de hacking (modificación del código).
5. **Propiedad Intelectual:** Protege el diseño, los logotipos y el código fuente (especialmente la integración gráfica del símbolo de sumatoria y la espiral de Fibonacci de Vecta) contra el plagio.
6. **Limitaciones de Responsabilidad:** Una cláusula crítica para proteger a los desarrolladores y tutores. Aclara que usar Vecta no garantiza aprobar una asignatura (el éxito depende del estudiante) y exime a la plataforma por problemas de conectividad o acuerdos externos que los usuarios hagan por fuera de la app.
7. **Cambios en estas Políticas:** Cláusula de contingencia que reserva el derecho a la administración de modificar el documento notificando a los usuarios en futuras actualizaciones.

---

## Autores Principales

| Autor | Rol en el Proyecto | Responsabilidades Asignadas |
|---|---|---|
| **Juan Rodriguez** | Liderazgo Técnico  | Diseño de arquitectura, programación en Dart, configuración completa del clúster de Firebase, Cloud Functions, Integración In-App/Push Notifications, Storage nativo, Seguridad IAM y transacciones lógicas. |
| **Alejandra Falcon** | Interfaz (UI/UX) | Sistema de diseño visual, maquetación del frontend de pantallas, estandarización tipográfica, wireframing y accesibilidad del color. |
| **Miguel Oliver** | Control de Calidad (QA / Tester) | Auditorías de flujo, revisión de seguridad, reporte y prevención de *Memory Leaks*, pruebas en dispositivos de gama baja y control estadístico. |

---

## Contexto del Proyecto

**Plataforma de Tutorías** es el producto estrella de software desarrollado grupalmente para la **JIC (Jornada de Iniciación Científica)** a nivel nacional en **Panamá**, enfocado a solucionar el vacío de reforzamiento académico extra-curricular en la Universidad Tecnológica de Panamá (UTP) y otras instituciones secundarias.

### Fase Inicial con Grupo Vecta
El código original, el branding actual, y la base de datos de los primeros prototipos fueron inyectados en colaboración con el **Grupo Vecta**, sirviendo como nuestro *focus group* y ambiente de pruebas beta (Closed Testing). Esto permitió iterar los flujos de "estudiante/tutor" en una micro-sociedad académica real antes del despliegue masivo.

> [!TIP]
> **Arquitectura Agnóstica:** Pese al uso del branding Vecta en código o colores, este repositorio fue reescrito de manera modular. Cualquier otra universidad, colegio o junta educativa puede clonar este sistema, cambiar variables de color y el logo, y tendrán un sistema de educación peer-to-peer 100% funcional y asegurado.

---

> **Versión del Proyecto:** 1.4.0 (Security Hardening & Production Ready)  

### Registro de Actualizaciones (Changelog v1.4.0)
- **App Check Integrado:** Firebase backend asegurado contra bots, emuladores root y scripts mediante Play Integrity API y reCAPTCHA v3 invisible.
- **Filtros de Lenguaje y Toxicidad:** Algoritmo en el `ModeracionServicio` integrado en el formulario de registro y en la creación de peticiones para detectar groserías y ofuscaciones de texto (Leetspeak).
- **Endurecimiento de Credenciales:** Reglas estrictas en el `RegistroView` exigiendo un mínimo de 8 caracteres, mayúsculas, números y símbolos especiales en la creación de contraseñas.
- **Alertas Administrativas Automatizadas:** Las calificaciones por debajo de 3 estrellas en el perfil del tutor y las cancelaciones tardías disparan alertas en la central del administrador.
- **Gráficas de Uso Global:** Se añadió a `MetricasView` un contador y visualización gráfica del impacto real mediante "Horas recibidas por estudiantes".

### Registro de Actualizaciones Histórico (Changelog v1.3.0)
- **Migración de Dominio:** Transición exitosa del ambiente de pruebas (tutorias-jic.web.app) al subdominio oficial `tutorias-vecta.web.app`.
- **Identidad Vecta:** Reemplazo de iconos genéricos de Flutter por el logotipo oficial de Vecta en la `LandingScreen`.
- **Refactorización UI/UX:** Implementación de `LayoutBuilder` en las pantallas de Ayuda y Soporte para asegurar una renderización impecable tanto en navegadores web de escritorio como en dispositivos móviles (Responsive Design).
- **Formularios Dinámicos:** Integración de un menú desplegable interactivo (`DropdownButtonFormField`) en la vista de Sugerir Tutoría para estandarizar las materias (Cálculo I, Física I, etc.), con una opción "Otros" que despliega dinámicamente un campo de texto adicional.
- **Auditoría de Código:** Resolución completa de advertencias del compilador (Linter a 0 errores), incluyendo la sustitución de código obsoleto (`.withOpacity` a `.withValues`) y dependencias huérfanas.

> **Auditoría de Seguridad:** Completada y superada con éxito (Google Cloud Rules Enforced & App Check Verified).  
> **Última actualización:** Abril 2026
