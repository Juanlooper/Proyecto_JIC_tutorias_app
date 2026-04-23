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
10. [Módulo de Archivos y Notificaciones Push](#módulo-de-archivos-y-notificaciones-push)
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
2. La solicitud aparece en la **Bolsa de Solicitudes**, una cartelera pública visible en tiempo real para todos los tutores de la plataforma.
3. Un **tutor** revisa la solicitud, inspecciona los archivos adjuntos, proporciona un lugar de encuentro (o enlace virtual) y sus datos de contacto, y la reclama.
4. El sistema usa **transacciones atómicas** de Firestore para evitar colisiones (evitando que dos tutores acepten la misma solicitud al mismo milisegundo).
5. Se disparan **Notificaciones Push** automatizadas al dispositivo del estudiante avisándole que su tutoría fue aceptada.
6. Los **tutores** también tienen el poder de crear proactivamente **Clases Fijas** (con recurrencias lógicas de 1, 2, 3 o 4 semanas) para que los estudiantes se inscriban libremente hasta llenar el cupo.
7. Un **administrador** (moderador global) supervisa todas las métricas, aprueba postulaciones de tutores, ejerce baneos, y gestiona de manera centralizada las quejas de mala conducta.

---

## Roles del Sistema

| Rol | Nivel de Acceso y Funcionalidades |
|---|---|
| **Estudiante** | Acceso a la Cartelera de clases fijas, creación de solicitudes huérfanas, subida de archivos adjuntos, inscripción en tutorías existentes, levantar quejas secretas contra tutores, evaluar clases (solo si su asistencia fue confirmada), gestión de perfil, explorar comunidad de tutores y recepción de notificaciones Push. |
| **Tutor** | Acceso a la Bolsa de solicitudes huérfanas, visualización y descarga nativa de adjuntos de los alumnos, creación y programación de "Clases Fijas" recurrentes, aceptación de peticiones, listado de agenda pendiente, pase de lista (registro de asistencia), visualización de su propio perfil y recepción de notificaciones. |
| **Admin** | Todo lo del estudiante + Panel de Administración unificado. Tienen el poder de ver métricas globales, ejercer moderación activa de reseñas y quejas, ejecutar baneos de usuarios problemáticos, aprobar postulaciones para ascender estudiantes a tutores, y auditar cancelaciones de clases a última hora. |

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
El usuario interactúa con una `View` → Llama a un método del `Provider` → El `Provider` ejecuta lógica de negocio y llama al `Service` → El `Service` manipula `Firebase` → Si hay un cambio global, Firebase Functions dispara una alerta Push → El `Provider` hace `notifyListeners()` → La `View` se reconstruye reactivamente.

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
│   ├── usuario_servicio.dart           # Actualización de datos académicos del usuario
│   └── evaluacion_servicio.dart        # Servicio de reputación y calificaciones
│
├── providers/
│   ├── autenticacion_provider.dart     # Estado global de sesión e identidad
│   ├── tutorias_provider.dart          # Estado de tutorías (CRUD, transacciones, recurrencias, recolector de basura)
│   ├── admin_provider.dart             # Estado del panel de administración
│   ├── evaluacion_provider.dart        # Estado del sistema de evaluación
│   └── notificaciones_provider.dart    # Estado de notificaciones in-app
│
├── views/
│   ├── auth/
│   │   ├── login_view.dart             # Pantalla de inicio de sesión segura
│   │   └── registro_view.dart          # Pantalla de registro con validación de correo
│   │
│   ├── navigation/
│   │   ├── enrutador_roles_view.dart   # Redirige inteligentemente según el rol
│   │   └── main_navigation_view.dart   # Navegación base con BottomNavigationBar
│   │
│   ├── home/
│   │   ├── home_view.dart              # Cartelera pública de tutorías disponibles
│   │   └── crear_tutoria_view.dart     # Formulario para solicitar tutoría y subir archivos
│   │
│   ├── tutor/
│   │   ├── dashboard_tutor_view.dart   # Panel del tutor (Bolsa + Pendientes + Finalizadas)
│   │   ├── aceptar_solicitud_view.dart # Pantalla interactiva "Read-only" y configuración de clase
│   │   └── detalle_clase_view.dart     # Vista de la clase, pase de lista y visualizador de adjuntos
│   │
│   ├── tutorias/
│   │   └── mis_tutorias_view.dart      # Listado personalizado con FAB de "Crear Clase Fija"
│   │
│   ├── explore/
│   │   ├── explorar_view.dart          # Vista de comunidad y listado global de tutores
│   │   └── perfil_publico_tutor_view.dart # Ver reseñas, estrellas y levantar Quejas
│   │
│   ├── profile/
│   │   └── perfil_view.dart            # Perfil propio con edición rápida de datos
│   │
│   ├── admin/
│   │   ├── admin_dashboard_view.dart   # Centro de mando del administrador
│   │   ├── metricas_view.dart          # Dashboard de KPIs y Moderación de Quejas
│   │   ├── tribunal_baneos_view.dart   # Gestión de strikes y suspensiones
│   │   ├── buzon_postulaciones_view.dart # Revisión de alumnos que quieren ser tutores
│   │   └── historial_tutorias_view.dart # Auditoría completa de todas las clases
│   │
│   └── widgets/
│       ├── tutorial_vecta_widget.dart  # Modal de onboarding interactivo
│       └── vecta_buttons.dart          # Componentes de diseño estandarizados
│
└── functions/
    ├── index.js                        # Cloud Function en Node 20 para FCM Push Notifications
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
3. **`firebase_storage_servicio.dart`**: Interfaz con Google Cloud Storage. Permite subir archivos controlando su límite de tamaño (5 MB) y borrar lotes de archivos por directorios.
4. **`usuario_servicio.dart`**: Controlador para la edición del perfil académico personal.
5. **`evaluacion_servicio.dart`**: Módulo matemático para agregar estrellas de calificaciones y emitir los cálculos de promedios de cada tutor.

---

## Capa de Estado: Providers

Toda la aplicación reactiva es controlada aquí mediante `ChangeNotifier`:

- **`autenticacion_provider.dart`**: Cerebro de la identidad. Transforma un stream de Auth en un usuario sólido cacheado. Maneja el control de sesiones, evita la suplantación y controla el "estado de carga" al entrar a la app.
- **`tutorias_provider.dart`**: El núcleo de operaciones. Gestiona el CRUD completo, se encarga de crear copias recursivas al pedir "Clases Fijas", maneja las cancelaciones atómicas y ejecuta el **Recolector de Basura** para vaciar Firebase Storage cuando una tutoría muere.
- **`admin_provider.dart`**: Agrupa y procesa matemáticamente las métricas (número de quejas, tutorías globales, reportes) para renderizar gráficas limpias en el dashboard.
- **`evaluacion_provider.dart`**: Rastrea si el estudiante actual ya calificó una tutoría finalizada específica para impedir doble votación.
- **`notificaciones_provider.dart`**: Un envoltorio para escuchar las notificaciones Push (Firebase Cloud Messaging) mientras la aplicación está en primer plano.

---

## Capa de Presentación: Vistas

| Categoría | Vistas Principales | Descripción |
|---|---|---|
| **Autenticación** | `login_view`, `registro_view` | Formularios limpios, botones OAuth y validadores de campos con regex de correo institucional. |
| **Navegación** | `enrutador_roles_view`, `main_navigation_view` | Deciden de manera instantánea a qué tab enviar al usuario tras iniciar sesión basándose en su `rolEnElSistema`. |
| **Principal (Home)**| `home_view`, `crear_tutoria_view` | La "Cartelera". Aquí el alumno ve el feed estilo red social con las clases ofertadas, y puede llenar su solicitud subiendo sus archivos adjuntos desde su celular/PC. |
| **Tutor** | `dashboard_tutor_view`, `aceptar_solicitud_view`, `detalle_clase_view` | Paneles con pestañas (Pendientes / Finalizadas). En `detalle_clase_view` el tutor da clic a los archivos subidos por el alumno y los abre directamente. |
| **Comunidad** | `explorar_view`, `perfil_publico_tutor_view` | Buscador de talento. Muestra las biografías de los tutores, su promedio de estrellas y el botón rojo de levantar una queja a la administración. |
| **Administración**| `admin_dashboard_view`, `metricas_view`, `tribunal_baneos_view` | Centro de comando. Vista de alto impacto con gráficas e interruptores para banear o des-banear a un usuario con 1 clic. |

---

## Flujos de Interacción

### 1. Flujo "Uber" — Creación y Aceptación
1. **Estudiante:** Presiona "+" → Rellena materia y tema → Sube un PDF de sus ejercicios → "Sugerir Tutoría". (La tutoría nace con estado `pendiente` y `idTutor: ''`).
2. **Tutor:** Entra a su "Bolsa de Solicitudes". Ve la petición. Le da a "Aceptar".
3. **App:** Pasa a la vista de configuración. El tutor confirma lugar, fecha exacta y cupo. Confirma.
4. **Backend:** Se dispara una **Transacción Atómica**. Firestore verifica que en ese microsegundo nadie más haya reclamado la clase. Pasa el estado a `aceptada` y asigna su UID.
5. **Nube:** La Cloud Function detecta el cambio e inmediatamente dispara un Push Notification al estudiante.

### 2. Flujo de Clases Fijas (Recurrencias Temporales)
1. Un **Tutor** clica "Crear Clase Fija" (ej. "Taller de Cálculo I").
2. Especifica que se repetirá durante `4 semanas`.
3. El `tutorias_provider.dart` clona en memoria el objeto y empuja a Firestore 4 documentos independientes, separados algorítmicamente por saltos temporales exactos de 7 días.

### 3. Flujo de Subida de Archivos Adjuntos (Estudiante)
1. Durante la reserva de cupo, el estudiante presiona "Añadir Archivos".
2. `file_picker` invoca la galería nativa de Android/iOS o explorador de Windows.
3. Se verifica tamaño (< 5 MB).
4. `firebase_storage_servicio.dart` sube el archivo a `/tutorias/{id_tutoria}/{archivo.pdf}` y devuelve la URL pública cifrada.
5. El arreglo de URLs se guarda en el documento de Firestore.

### 4. Flujo de Pase de Asistencia e Inasistencia
1. Terminada la hora, el tutor abre su "Panel de Clases Pendientes" → "Iniciar Pase de Lista".
2. Visualiza a todos los inscritos con un Toggle *Switch* (✅ / ❌).
3. Al darle a guardar, la app ejecuta una sola petición masiva (`runTransaction`):
   - Cambia estado a `finalizada`.
   - A cada alumno marcado con ❌ le suma `+1` a su propiedad `strikesInasistencia` en el modelo global de Usuarios.

### 5. Flujo de Cancelación y Auditoría
1. Tutor se le presenta una emergencia. Entra a la clase y presiona "Cancelar".
2. La app le obliga a redactar una justificación de 30 caracteres mínimo.
3. La app revisa el reloj: ¿Faltan menos de 12 horas para la clase?
   - Si SÍ: Genera un reporte automático e invisible hacia la colección de `quejas` catalogado como "Cancelación Tardía Abusiva".
   - Borra la clase del feed.
4. **Garbage Collection:** El Provider manda a destruir toda la carpeta de archivos en Cloud Storage vinculada a esa tutoría para evitar guardar basura inútil en el servidor.

---

## Módulo de Archivos y Notificaciones Push

Esta es la mejora tecnológica más avanzada de la V1.0:

1. **Uploads Seguros:** La librería nativa inyecta archivos al Cloud Storage. Todo el manejo es reactivo, permitiendo a tutores descargar el material para preparar su clase.
2. **Cloud Functions (Servidor Node.js 20):** La aplicación despliega funciones de backend automáticas en Google Cloud. 
   - La función `notificarCambioEstadoTutoria` está siempre en vigilia. 
   - Detecta cualquier `Update` en la base de datos de tutorías. Si el estado cambia a `aceptada`, envía silenciosamente un paquete FCM al token del celular del estudiante. ¡Se entera sin abrir la app!
3. **Limpieza Ecológica de Storage:** Para evitar facturas astronómicas, el `TutoriasProvider` está enlazado a los métodos de eliminación. Tutoría muerta = Carpeta de almacenamiento eliminada.

---

## Módulo de Moderación y Calidad

Para evitar que la plataforma se vuelva caótica, el sistema promueve el sano comportamiento:

- **Sistema Anti-Review Bombing:** ¿Un alumno falta a clase y quiere ponerle 1 estrella al tutor por despecho? Imposible. La UI de evaluación comprueba si el alumno asistió; si tiene falta marcada, el sistema le bloquea el acceso a las reseñas.
- **Botón de Pánico (Quejas):** Si un tutor tiene conductas inapropiadas, su perfil tiene un botón rojo de reporte. Envía la data cifrada directamente a la mesa del Admin.
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

**Estructura de Componentes UI:**
- **Elevación:** Sombras estandarizadas `boxShadow: black12, blur: 10, offset(0,4)` en todas las tarjetas y contenedores blancos (`borderRadius: 16`).
- **Botones Vecta:** Un widget reutilizable `VectaButton` asegura que todos los botones de la app midan mínimo 50px de altura para respetar los lineamientos táctiles de Apple/Google.

---

## Configuración y Ejecución

### Prerrequisitos del Entorno
- Flutter SDK ≥ 3.20.x
- Dart SDK ≥ 3.x
- Cuenta en Firebase Console con plan *Blaze* (requerido para Cloud Functions y Storage).
- Node.js 20+ instalado localmente (si vas a programar más Functions).
- GCloud CLI configurado (opcional pero recomendado).

### Instalación Rápida

```bash
# 1. Clonar este bello repositorio
git clone <url-del-repo>
cd Proyecto_JIC_tutorias_app

# 2. Bajar todo el ecosistema de dependencias Flutter
flutter pub get

# 3. Correr la app en modo emulador web (rápido)
flutter run -d chrome

# O bien, lanzar en tu teléfono Android / iOS físico
flutter run
```

### Despliegue de Reglas de Seguridad (Admin)
Si modificas el código de Firebase, protege la base de datos haciendo:
```bash
firebase deploy --only firestore:rules,storage
firebase deploy --only functions
```

---

## Seguridad y Reglas de Negocio

El sistema superó una auditoría de seguridad implementando reglas drásticas a nivel servidor:

### Reglas Firestore Strict-Mode
- **Imposibilidad de alteración masiva:** La regla de actualización de tutorías en `firestore.rules` prohíbe que cualquier estudiante malicioso modifique clases en las que no está. La regla evalúa: *¿Es el creador? ¿Es el tutor asignado? ¿Es el administrador?* Si ninguna es correcta, la escritura se rechaza al instante.
- **Escudo de Privilegios:** Ningún cliente puede modificar su campo `rolEnElSistema`. Aunque un hacker altere la App compilada, Firebase rechazará la mutación bloqueando el escalamiento de privilegios.

### Reglas Firebase Storage
- **Firewall de Archivos:** Las `storage.rules` exigen que todo archivo subido cumpla un regex de tipo de documento (`application/pdf`, `image/.*`).
- **Límite Físico:** Límite infranqueable de `5 MB` por petición de subida. Evita saturación y ataques de sobrecosto (Denial of Wallet).

### Reglas de Dominio y Negocio
- La app verifica que un estudiante no se pueda inscribir en una clase creada por sí mismo o impartida por sí mismo.
- Si un usuario tiene inasistencias en su historial, Firebase lo expone a los administradores para que asuman el bloqueo.
- No hay borrado físico de usuarios (`allow delete: if false` en Auth/Firestore). Se mantienen los registros como legado contable en la tabla administrativa, pero se les niega el *login* vía UI y Backend si son baneados.

---

## Autores Principales

| Autor | Rol en el Proyecto | Responsabilidades Asignadas |
|---|---|---|
| **Juan Rodriguez** | Liderazgo Técnico (Fullstack) | Diseño de arquitectura, programación en Dart, configuración completa del clúster de Firebase, Cloud Functions, Seguridad IAM y transacciones lógicas. |
| **Alejandra Falcon** | Jefatura de Interfaz (UI/UX) | Sistema de diseño visual, maquetación del frontend de pantallas, estandarización tipográfica, wireframing y accesibilidad del color. |
| **Miguel Oliver** | Control de Calidad (QA / Tester) | Auditorías de flujo, revisión de seguridad, reporte y prevención de *Memory Leaks*, pruebas en dispositivos de gama baja y control estadístico. |

---

## Contexto del Proyecto

**Plataforma de Tutorías** es el producto estrella de software desarrollado grupalmente para la **JIC (Jornada de Iniciación Científica)** a nivel nacional en **Panamá**, enfocado a solucionar el vacío de reforzamiento académico extra-curricular en la Universidad Tecnológica de Panamá (UTP) y otras instituciones secundarias.

### Fase Inicial con Grupo Vecta
El código original, el branding actual, y la base de datos de los primeros prototipos fueron inyectados en colaboración con el **Grupo Vecta**, sirviendo como nuestro *focus group* y ambiente de pruebas beta (Closed Testing). Esto permitió iterar los flujos de "estudiante/tutor" en una micro-sociedad académica real antes del despliegue masivo.

> [!TIP]
> **Arquitectura Agnóstica:** Pese al uso del branding Vecta en código o colores, este repositorio fue reescrito de manera modular. Cualquier otra universidad, colegio o junta educativa puede clonar este sistema, cambiar 5 variables de color y el logo, y tendrán un sistema de educación peer-to-peer 100% funcional y asegurado.

---

> **Versión del Proyecto:** 1.0.0 Release Candidate  
> **Auditoría de Seguridad:** Completada y superada con éxito (Google Cloud Rules Enforced).  
> **Última actualización:** Abril 2026
