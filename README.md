# Plataforma de Tutorías Vecta UTP (Proyecto JIC)
**Versión de Despliegue:** 1.0.0 (Producción Final)

> Sistema integral de gestión de tutorías académicas peer-to-peer para centros educativos, desarrollado para la Jornada de Iniciación Científica (JIC) de la Universidad Tecnológica de Panamá.
> Construido con **Flutter**, **Firebase Auth**, **Cloud Firestore**, **Firebase Storage**, **Cloud Functions** y **Resend SMTP**.

---

## 📑 Tabla de Contenidos

1. [Descripción Ejecutiva](#1-descripción-ejecutiva)
2. [Arquitectura del Proyecto y Stack Técnico](#2-arquitectura-del-proyecto-y-stack-técnico)
3. [Árbol de Archivos (Estructura de Carpetas)](#3-árbol-de-archivos-estructura-de-carpetas)
4. [Desglose Exhaustivo de Funcionalidades (Feature List)](#4-desglose-exhaustivo-de-funcionalidades-feature-list)
5. [Capa de Datos: Modelos](#5-capa-de-datos-modelos)
6. [Capa de Servicios y Providers](#6-capa-de-servicios-y-providers)
7. [HCI y Heurísticas de Usabilidad](#7-hci-y-heurísticas-de-usabilidad)
8. [Desglose Técnico por Pantallas](#8-desglose-técnico-por-pantallas)
9. [Roles y Sistema de Permisos](#9-roles-y-sistema-de-permisos)
10. [Flujos de Sistema y Manejo de Datos](#10-flujos-de-sistema-y-manejo-de-datos)
11. [Módulo de Análisis de Datos y Reportes](#11-módulo-de-análisis-de-datos-y-reportes)
12. [Reglas de Seguridad y Ciberseguridad](#12-reglas-de-seguridad-y-ciberseguridad)
13. [Infraestructura de Correos SMTP](#13-infraestructura-de-correos-smtp)
14. [Contexto del Proyecto y Autores](#14-contexto-del-proyecto-y-autores)
15. [Instrucciones de Despliegue e Instalación](#15-instrucciones-de-despliegue-e-instalación)
16. [Historial de Actualizaciones (Changelogs)](#16-historial-de-actualizaciones-changelogs)

---

## 1. Descripción Ejecutiva

**Tutorías Vecta** es una plataforma móvil y web de economía colaborativa enfocada en el aprendizaje académico. Conecta en tiempo real a estudiantes que necesitan reforzamiento con tutores universitarios capacitados. Opera de manera dinámica bajo un **modelo tipo Uber**: un estudiante lanza una petición huérfana en la "Bolsa de Valores del Conocimiento", y la red global de tutores es notificada para aceptarla y reclamarla en milisegundos.

La aplicación resuelve el problema de deserción estudiantil y falta de orientación, proporcionando herramientas corporativas como el seguimiento de asistencia, métricas globales en vivo, sistema de denuncias anónimas, notificaciones automatizadas y despliegue nativo de PDFs de la universidad.

---

## 2. Arquitectura del Proyecto y Stack Técnico

El proyecto está diseñado bajo una arquitectura limpia en capas, utilizando fuertemente el patrón **Provider** para la inyección de dependencias y gestión de estado. Al ser Serverless, delega toda su lógica de backend a los servicios de Firebase, asegurando alta disponibilidad.

### Stack Tecnológico
* **Frontend:** Flutter SDK (Dart) para compilación unificada en Web, Android e iOS.
* **Backend BaaS:** Google Firebase.
  * **Auth:** Gestión de sesiones, encriptación AES.
  * **Cloud Firestore:** Base de datos NoSQL reactiva.
  * **Cloud Storage:** Alojamiento de archivos binarios (PDFs/Imágenes) con recolección de basura automática.
  * **Firebase Hosting:** Distribución perimetral (CDN) global.
* **Comunicaciones:** **Resend SMTP** integrado con dominios personalizados (`vectatutorias.me`).
* **Seguridad Activa:** Firebase App Check (reCAPTCHA v3 y Play Integrity).

### Arquitectura Limpia (MVVM Adaptado)
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

---

## 3. Árbol de Archivos (Estructura de Carpetas)

El código fuente está rigurosamente compartimentado siguiendo los estándares de escalabilidad de Dart/Flutter.

```text
lib/
├── main.dart                           # Punto de entrada y raíz de Providers
├── firebase_options.dart               # Constantes de Google Cloud (Auto-generado)
│
├── core/
│   ├── theme/
│   │   └── app_theme.dart              # Tokens de diseño, Paleta Vecta y Tipografías
│   └── utils/
│       └── moderacion_servicio.dart    # Algoritmo heurístico para censurar insultos
│
├── models/
│   ├── usuario_model.dart              # Esquema de datos del perfil
│   └── tutoria_model.dart              # Esquema de datos de las transacciones de clase
│
├── services/
│   ├── autenticacion_servicio.dart     # Conector con Firebase Auth y Custom SMTP
│   ├── base_de_datos_servicio.dart     # Transacciones atómicas de Firestore
│   ├── firebase_storage_servicio.dart  # API de carga/descarga/borrado masivo
│   ├── pdf_servicio.dart               # Generador nativo de certificados PDF
│   └── reporte_pdf_servicio.dart       # Generador de reportes matriciales para Admin
│
├── providers/
│   ├── autenticacion_provider.dart     # Estado de identidad, sesión persistente
│   ├── tutorias_provider.dart          # Orquestador del caché de tutorías
│   ├── admin_provider.dart             # Procesador de Big Data y métricas en memoria
│   └── evaluacion_provider.dart        # Rastreador de reputación Anti-Spam
│
├── views/
│   ├── auth/                           # Login, Registro Dinámico, Recuperación
│   ├── navigation/                     # BottomNavigationBar inteligente según rol
│   ├── home/                           # Feed, Cartelera y creación de Solicitudes
│   ├── tutor/                          # Paneles de gestión de clases y Pase de Lista
│   ├── tutorias/                       # Historial de clases inscritas
│   ├── explore/                        # Buscador de comunidad de talento
│   ├── profile/                        # Perfil público y edición de datos
│   ├── admin/                          # Dashboards de Métricas, Baneos y Postulaciones
│   └── widgets/                        # Componentes UI (Botones Glassmorphism, Loaders)
```

---

## 4. Desglose Exhaustivo de Funcionalidades (Feature List)

A continuación, se enumeran absolutamente todas las características y módulos programados en la aplicación, divididos por área lógica. No hay funcionalidad oculta que no esté descrita aquí.

### A. Módulo de Autenticación y Cuentas
- [x] **Login Híbrido:** Inicio de sesión con correo institucional o personal y contraseña encriptada.
- [x] **Registro Estricto:** Formulario de alta con validación de expresiones regulares (Regex) para formato de cédula panameña (`00-0000-000000`).
- [x] **Selección Dinámica Universitaria:** Menú en cascada donde elegir la Facultad filtra automáticamente las opciones de la lista de Carreras.
- [x] **Recuperación de Contraseñas:** Integración nativa con servidor SMTP propio (`adminvecta@vectatutorias.me`) para emitir enlaces criptográficos de reseteo.
- [x] **Cierre de Sesión Seguro:** Destrucción local del token JWT y limpieza de caché en el dispositivo.

### B. Módulo del Estudiante (Usuario Estándar)
- [x] **Navegación Personalizada:** BottomNavigationBar y Drawer lateral adaptados a las vistas que el estudiante tiene permitido visitar.
- [x] **Cartelera Global (Feed):** Visualización en tiempo real de todas las tutorías disponibles ofertadas por tutores, renderizadas en tarjetas interactivas.
- [x] **Inscripción a Tutorías:** Botón de un solo clic para reservar un cupo. Validación de servidor que impide inscribirse si el cupo máximo ya fue alcanzado.
- [x] **Adjuntar Materiales de Estudio:** Requisito de subida (PDF/Imagen estática) forzado por Firebase Storage para que el alumno proporcione un problema o tarea antes de unirse a la clase.
- [x] **Bolsa de Sugerencias:** Foro comunitario donde un alumno postula un tema que nadie está impartiendo, creando una petición "huérfana".
- [x] **Apoyo Colaborativo (+1):** Botón social que permite a otros alumnos sumarse a una sugerencia huérfana para crear demanda colectiva (Crowdsourcing).
- [x] **Agenda Histórica (Mis Tutorías):** Registro de todas las sesiones a las que el estudiante se inscribió, ordenadas cronológicamente (Pendientes y Finalizadas).
- [x] **Sistema de Evaluaciones:** Formulario de reseñas (1 a 5 estrellas + comentario de texto) habilitado **exclusivamente** si el estudiante fue marcado como "Asistente" por el tutor.
- [x] **Certificados PDF Nativos:** Motor generador vectorial que exporta un diploma (Tutorías Vecta UTP) con nombre, firma y horas cursadas, descargable vía Desktop Web o Móvil.
- [x] **Postulación a Tutor:** Formulario interno donde el estudiante anexa sus justificaciones y récord para solicitar un ascenso de privilegios al Administrador.

### C. Módulo del Tutor (Rol Operativo)
- [x] **Dashboard de Trabajo:** Pantalla dividida con control de pestañas para organizar visualmente las "Clases Pendientes" de las "Clases Finalizadas".
- [x] **Creación Proactiva de Clases:** Formulario extenso donde el tutor imparte una clase ofertándola al público. Permite definir: Tema, Materia, Fecha, Hora, Salón, Modalidad (Virtual/Presencial) y Cupos.
- [x] **Aceptación Reactiva de Clases:** El tutor puede entrar a la "Bolsa de Sugerencias" de los estudiantes, tomar una petición huérfana y adueñársela, configurándole un horario en ese mismo instante.
- [x] **Visor de Estudiantes Inscritos:** Panel en vivo que muestra quiénes y cuántos han reservado su asiento en la tutoría.
- [x] **Pase de Lista Criptográfico:** Sistema de "Toggle Switches" (Interruptores booleanos) que permite al tutor marcar Asistencia o Ausencia. Si marca Ausencia, el sistema le adjudica un *Strike* penal al estudiante.
- [x] **Consulta de Materiales Alumnos:** Visor para abrir los enlaces PDF y fotos de los problemas que enviaron los estudiantes previamente a la clase.
- [x] **Cancelación de Emergencia:** Botón de aborto de clase. Obliga al tutor a escribir una "Justificación de Cancelación" que quedará almacenada en los registros del Administrador.

### D. Módulo de Exploración y Social
- [x] **Buscador Universal:** Barra de búsqueda indexada para localizar perfiles de tutores específicos por su nombre en la base de datos.
- [x] **Visor de Perfiles Públicos:** Exhibe la biografía del tutor, la facultad a la que pertenece y, crucialmente, su métrica de calificación promedio (Estrellas).
- [x] **Muro de Reseñas:** Un tablón público en el perfil del tutor donde se pueden leer todos los comentarios de retroalimentación dejados por alumnos pasados.

### E. Módulo de Administración (Big Data y Moderación Policial)
- [x] **Tablero de Mandos Múltiples:** Interfaz cuadriculada exclusiva para Administradores que enlaza todas las herramientas del sistema.
- [x] **Métricas Globales Interactivas:** Algoritmos que grafican en formato de Pastel/Dona y Barras los datos en vivo: Tasa de Deserción, Tasa de Cancelación, Horas Impartidas y Demografías por Carrera.
- [x] **Exportador de Reportes:** Botón maestro que empaqueta todos los gráficos y tablas matemáticas del Dashboard en un documento PDF formateado para impresoras tamaño A4, ideal para las juntas directivas.
- [x] **Buzón de Postulaciones Estilo Tinder:** Interfaz *Glassmorphism* que presenta tarjetas de biografía de candidatos a tutor. El admin puede deslizar o presionar un botón para aprobar/rechazar el ascenso.
- [x] **Buzón de Quejas Anónimas:** Bandeja de entrada privada donde se revisan denuncias contra estudiantes o tutores conflictivos.
- [x] **Tribunal de Baneos (Lista de Estudiantes):** Tabla policial masiva. Muestra a todo usuario de la plataforma y permite ejecutar el "Kill Switch" (Botón de baneo). Un usuario baneado es eyectado del sistema inmediatamente.
- [x] **Filtro de Disciplina:** Herramienta para ordenar la tabla de usuarios buscando a los que tienen un exceso de ausencias injustificadas (Strikes).

### F. Seguridad, Utilidades y Optimizaciones Backend (Under the Hood)
- [x] **Moderador de Lenguaje (Censura de Groserías):** Algoritmo heurístico local (Regex) que bloquea el envío de reseñas que contengan insultos camuflados o "Leetspeak" (Ej: P*t@).
- [x] **Transacciones Atómicas (Evitación de Colisiones):** Empleo del comando `runTransaction` de Firestore para bloquear peticiones dobles (Ej: Dos tutores intentando aceptar la misma solicitud de la bolsa simultáneamente).
- [x] **Recolección de Basura Automática (Cloud Storage):** Cuando una clase es cancelada, una rutina limpia recursivamente la carpeta del servidor, borrando los PDFs de los alumnos para evitar desbordes de costos.
- [x] **Theme Switcher:** Cambio fluido (Modo Claro/Oscuro) persistente en el caché local del usuario.
- [x] **Soporte Directo Integrado:** Pestaña de contacto rápido con correo preconfigurado (`vecta.administrador@gmail.com`).
- [x] **Firebase App Check:** Criptografía de atestación mediante Google Play Integrity (Android) y reCaptcha v3 Invisible (Web Desktop).
- [x] **Sistema de Alertas In-App:** Subcolección de Firebase dedicada que actúa como bandeja de notificaciones. Genera un registro silencioso si "Tu clase fue aceptada", "Se canceló un evento" o "El cupo está lleno".
- [x] **Impeller Engine Bypass:** Código inyectado en C++/Java para desactivar el nuevo motor de Flutter en dispositivos Xiaomi/Asiáticos incompatibles, resolviendo el fatal error de pantalla negra.

---

## 5. Capa de Datos: Modelos

El corazón de los datos, estandarizados para serializar el formato JSON de Firebase.

### `usuario_model.dart`
Representa el perfil, historial y reputación de cualquier usuario (Estudiante, Tutor o Admin).

| Atributo Clave | Tipo | Propósito Estratégico |
|---|---|---|
| `identificadorUnico` | `String` | UID primario enlazado criptográficamente a Auth. |
| `rolEnElSistema` | `String` | Define dinámicamente si el UI muestra el panel Admin, Tutor o Estudiante. |
| `strikesInasistencia` | `int` | Contador penal. Si un estudiante falta a demasiadas clases, se le suspende. |
| `estaBaneado` | `bool` | *Kill-Switch*. Booleano de emergencia que el Admin apaga para denegar accesos. |
| `estadoSolicitudTutor` | `String` | Máquina de estados (`ninguna`, `en_revision`, `aprobado`) para moderar el ascenso de rango. |
| `facultad` / `carrera` | `String` | Clasificadores usados por los algoritmos del Dashboard de Métricas. |
| `promedioEstrellas` | `double` | Métrica pública de rendimiento (1.0 a 5.0) visible para la comunidad. |

### `tutoria_model.dart`
El activo más pesado del sistema. Representa una petición, una clase programada o una clase histórica.

| Atributo Clave | Tipo | Propósito Estratégico |
|---|---|---|
| `identificadorDelTutor` | `String` | Si está vacío `''`, es de dominio público (Bolsa Comunitaria). Si está lleno, fue reclamada. |
| `enlaces_adjuntos` | `Map` | `UID_Alumno -> Array[URL_PDF_Storage]`. Alojamiento de tareas enviadas por los alumnos. |
| `registro_asistencia` | `Map` | Sistema de pases de lista (`UID_Alumno -> bool`). Evita que un ausente pueda evaluar al tutor. |
| `estadoDeLaSolicitud` | `String` | Flujo principal: `pendiente` -> `aceptada` -> `finalizada` (o `cancelada`). |
| `alumnosQueYaEvaluaron` | `List` | Escudo lógico para impedir que una persona vote dos veces (Review Bombing). |
| `justificacion_cancelacion` | `String` | Evidencia legal obligatoria si el tutor cancela abruptamente una clase. |
| `estudiantesSuscritos` | `List` | Registro vivo de la matrícula de la clase y el orden de llegada. |

---

## 6. Capa de Servicios y Providers

### Servicios (Capa de Red Pura)
* **`autenticacion_servicio.dart`:** Control de identidades. Resuelve JWT tokens.
* **`base_de_datos_servicio.dart`:** Núcleo de las sentencias SQL-Like (Firestore queries). Utiliza `FirebaseFirestore.instance.runTransaction` para efectuar modificaciones atómicas.
* **`firebase_storage_servicio.dart`:** Escudo de tamaño. Impide subidas mayores a 5MB y valida tipos MIME para rechazar malwares (solo PDFs e Imágenes estáticas).
* **`moderacion_servicio.dart`:** Analizador heurístico de lenguaje local.

### Providers (Capa de Estado Reactivo)
* **`autenticacion_provider.dart`:** Mantiene viva la sesión de usuario a lo largo de toda la RAM de la aplicación.
* **`tutorias_provider.dart`:** Actúa como orquestador y *Garbage Collector* ecológico. Reacciona a cancelaciones.
* **`admin_provider.dart`:** Mantiene una copia local en caché de todas las quejas, usuarios y métricas para que la pestaña del Administrador no gaste cientos de peticiones de lectura de red cada vez que recalcula estadísticas.
* **`evaluacion_provider.dart`:** Mide constantemente el rendimiento matemático del usuario promedio.

---

## 7. HCI y Heurísticas de Usabilidad

El diseño cumple rigurosamente con los lineamientos de Interacción Humano-Computadora (HCI) y las 10 Heurísticas de Jakob Nielsen.

1. **Visibilidad del estado del sistema:** Todos los botones de mutación de base de datos (`Aceptar`, `Cancelar`, `Registrar`) transforman la pantalla en un *Overlay Loader* con texto descriptivo para que el usuario no toque dos veces.
2. **Relación con el Mundo Real:** Uso de analogías físicas. El *Buzón de Postulaciones* se presenta como tarjetas, las "Campanitas" muestran números de alertas en rojo.
3. **Control y Libertad del Usuario:** Uso exhaustivo de `Navigator.pop(context)` para proveer salidas de emergencia en todos los diálogos y modales de confirmación.
4. **Consistencia y Estándares (Glassmorphism):** Se incorporó la tendencia de cristal esmerilado en los paneles críticos (Dashboard y Buzón). Tarjetas semitransparentes, sombras proyectadas y bordes sutiles que generan una sensación premium operando consistentemente entre Android, iOS y Web.
5. **Prevención de Errores (Error Prevention):** 
   * Filtros de fechas nativos: El calendario bloquea seleccionar días en el pasado.
   * Reglas de formularios: Ningún formulario puede ser disparado si los Regex de contraseña, cédula y campos no coinciden.
6. **Reconocer, no recordar:** Auto-llenado visual en las tarjetas de perfil y menú desplegable para las Facultades.
7. **Estética y Diseño Minimalista (Dark Mode Nativo):** Interfaz fluida adaptable a las preferencias del SO del usuario, con soporte a un *Dark Mode* oscuro profundo que respeta el contraste de colores WCAG.
8. **Ayuda a reconocer errores:** Mensajes *Snackbars* de color rojo sangre cuando la red falla o la contraseña es débil.
9. **Documentación Externa:** Se provee una vista completa de Soporte Técnico guiado.

---

## 8. Desglose Técnico por Pantallas

*(Ver Sección 4: Feature List para un detalle de cada vista de la interfaz por módulo).* 

Adicionalmente, se subraya la utilización de `StatefulWidgets` locales donde el componente requiere controladores de texto (`TextEditingController`), evitando ensuciar la RAM global de los *Providers*. Para la capa visual se usaron *Slivers* que permiten el ocultamiento dinámico del AppBar superior al hacer *Scroll*, maximizando el área de visión en pantallas móviles pequeñas.

---

## 9. Roles y Sistema de Permisos

El sistema es trifásico y no se basa únicamente en el Frontend. Todos los accesos están blindados por las **Reglas de Firestore (IAM)**.

| Rol en DB | Privilegios Visuales y Permisos Criptográficos |
|---|---|
| `estudiante` | Solo puede leer clases aprobadas y perfiles. Solo puede modificar su propio documento de perfil y subir datos a la subcolección de sus propias sugerencias. No tiene derecho a consultar reportes ajenos o la métrica global de la UTP. |
| `tutor` | Posee permisos de escritura parciales sobre la colección de Tutorías (Para reclamarlas o modificarlas). Puede alterar estados (`pendiente` -> `aceptada`). No puede modificar ni manipular las quejas en su contra, ni cambiar sus propias evaluaciones (Estrellas). |
| `admin` | Jerarquía `Omnipotente`. Regla de Firestore: `allow read, write: if request.auth.uid in getAdmins()`. Tiene escritura ilimitada en cualquier nodo del sistema para ejercer la moderación policial de los baneos y auditorías. |

---

## 10. Flujos de Sistema y Manejo de Datos

La aplicación es altísimamente transaccional. Para sobrevivir a la concurrencia universitaria, implementamos los siguientes escudos de manejo de información:

### A. Transacciones Atómicas (Evadiendo Condiciones de Carrera)
* *El Problema:* Si una clase es lanzada a la Bolsa Comunitaria, 5 tutores podrían intentar oprimir el botón "Aceptar" al mismo milisegundo. En un sistema estándar, el último en pulsar sobreescribiría al resto.
* *Solución Vecta:* Se usa el protocolo de transacción atómica de Firestore. El servidor enruta la petición, pausa la base de datos para ese documento, lee su estado, verifica que el `identificadorDelTutor` siga vacío `''`, se lo asigna al primero que llegó y rechaza criptográficamente a los otros 4 informándoles que la clase "Acaba de ser tomada".

### B. Notificaciones Asíncronas Cruzadas
El usuario es constantemente alimentado por notificaciones *In-App* persistentes. 
* Si la clase llega a su límite de capacidad (Ej: 15/15), el `TutoriasProvider` emite inmediatamente una escritura fantasma de Alerta en los buzones de los 15 alumnos indicando "Cupo Lleno". 
* Si el tutor cancela la clase por fuerza mayor, el sistema de alertas detona un barrido enviando el mensaje a la subcolección privada de notificaciones de todos los participantes sin necesidad de usar recursos pesados.

---

## 11. Módulo de Análisis de Datos y Reportes

La versión 1.0 no solo es operativa, sino analítica. A través de la vista de Administración (`MetricasView`), la universidad puede observar el pulso de la JIC:

1. **Rastreo Demográfico y Clustering:** Los algoritmos internos mapean todos los nodos de usuarios y generan un *ranking* en vivo de qué Facultades o Carreras están exigiendo la mayor carga de tutorías, revelando deficiencias institucionales.
2. **Cálculo de Deserción Escolar Estudiantil:** Restando las ausencias registradas (`Strikes`) sobre las inscripciones totales, el programa arroja el porcentaje exacto de alumnos que apartan cupo pero abandonan la materia sin justificación.
3. **Métrica de Horas de Vida (Social Impact):** Se acumula matemáticamente el tiempo (`minutos / 60`) invertido en todas las sesiones finalizadas exitosamente, para reportar el impacto social puro a las entidades gubernamentales.
4. **Exportador Vectorial Universitario:** Renderización del documento PDF con logo oficial, usando la librería `Printing.layoutPdf` para compatibilidad extrema con navegadores Desktop Web (Chrome, Edge) invocando directamente el driver nativo de la impresora.

---

## 12. Reglas de Seguridad y Ciberseguridad

El ecosistema entero ha sido envuelto en una muralla técnica empresarial que bloquea cualquier vector de ataque básico:

1. **Firebase App Check (Aseguramiento Anti-Scraping):**
   La base de datos completa de Firestore fue clausurada a la internet pública. Se inyectaron SDKs criptográficos para el despliegue de **Google Play Integrity** (en smartphones nativos) y **reCAPTCHA v3 Invisible** (en el ecosistema Web). Cualquier llamada proveniente de un script de Python, Postman o un emulador rooteado será silenciada con un código de error `403 Forbidden`.
2. **Estructura de Firestore Rules (Zero-Trust):**
   Las reglas de base de datos impiden suplantación de identidad (Spoofing). Un usuario no puede escribir en el documento de otro usuario porque el servidor exige la sentencia `allow write: if request.auth.uid == userId;`.
3. **Impeller Engine Bypass (Compatibilidad Gráfica):**
   Para garantizar tolerancia a fallos en dispositivos Android de gama baja/asiáticos (Específicamente el bloqueo fatal de Pantalla Negra en la familia Xiaomi/HyperOS), se inyectó un Meta-Data en el manifiesto Android (`EnableImpeller = false`) obligando al motor a usar Skia OpenGL clásico.
4. **Escudos en Storage (Denial of Wallet):**
   El *Storage* solo admite archivos tipados como MIME `application/pdf`, `image/png`, `image/jpeg` limitados estrictamente a **5 Megabytes**. Esto bloquea infecciones y evita cobros exorbitantes de infraestructura Cloud.

---

## 13. Infraestructura de Correos SMTP

El mayor reto logístico de los correos corporativos (Microsoft Exchange y Google Workspace Universitario) es el filtrado letal de SPAM.

**Tutorías Vecta** prescinde del correo gratuito de Firebase (Que usualmente rebota en los cortafuegos de la UTP) y utiliza una tubería dedicada provista por el partner **Resend.com**.
* **Registros DKIM & SPF:** El dominio privado `vectatutorias.me` ha sido adquirido en Namecheap. Los registros DNS de TXT y MX fueron alineados para firmar criptográficamente (DKIM) cada correo de validación saliente.
* **Remitente Dedicado:** Todos los enlaces criptográficos de recuperación de contraseñas, reseteos y validación de correos provienen unificadamente y sin advertencias rojas de fraude desde `adminvecta@vectatutorias.me`.

---

## 14. Contexto del Proyecto y Autores

**Tutorías Vecta** nace para la **JIC (Jornada de Iniciación Científica)** a nivel nacional en Panamá, como una propuesta formal al problema del vacío de reforzamiento académico extra-curricular en la Universidad Tecnológica de Panamá (UTP).

### Equipo Técnico Principal

| Autor | Responsabilidades y Arquitectura |
|---|---|
| **Juan Rodriguez** | Liderazgo Técnico y Arquitecto Backend. Infraestructura en Firebase (Reglas, Storage, App Check), despliegue SMTP (DKIM/SPF) con Resend, Transacciones Atómicas (SRE), Seguridad, despliegue Web Hosting y lógica de minería de datos (Dashboard). |
| **Alejandra Falcon** | Directora de Experiencia (UI/UX). Implementación exhaustiva del sistema de Glassmorphism, heurísticas de interacción, diseño de paleta Vecta, consistencia gráfica y accesibilidad. |
| **Miguel Oliver** | QA & Control de Calidad. Auditorías funcionales intensivas, mapeo del *User Journey*, rastreo de memory leaks, pruebas exhaustivas en hardware gama baja y depuración de embudos críticos. |

---

## 15. Instrucciones de Despliegue e Instalación

> Todo el ecosistema de Pruebas (Mock Data, Impresiones en terminal) fue erradicado para la rama maestra. 
> Esta es la **Versión 1.0**, empaquetada lista para Producción en servidor.

### A. Preparación del Entorno
- Instalar **Flutter SDK `3.20+`** y **Dart SDK `3.x`**.
- Clonar el repositorio localmente.

```bash
# 1. Recuperar dependencias pub alojadas
flutter pub get

# 2. (Opcional) Compilar localmente en Chrome para pruebas calientes
flutter run -d chrome
```

### B. Despliegue de Producción Final (Firebase)

Asegúrese de estar autenticado en la terminal (`firebase login`) con los credenciales del administrador y poseer el ID del proyecto Vecta inicializado (`firebase init`).

```bash
# 1. Generar los archivos binarios puros (Minificados y Tree-Shaking optimizados) para Web
flutter build web --release

# 2. Desplegar de forma remota los Security Rules a la base de datos Firestore y Storage
firebase deploy --only firestore:rules,storage

# 3. Empujar la aplicación cliente compilada al CDN global (Content Delivery Network)
firebase deploy --only hosting
```

---

## 16. Historial de Actualizaciones (Changelogs)

### Changelog v1.0.0 (Release Candidate y Glassmorphism)
- **Infraestructura SMTP Corporativa:** Conexión exitosa del dominio adquirido `vectatutorias.me` hacia los microservicios de Resend (Validación DNS DKIM/SPF) para despliegue de correos enrutados desde `adminvecta@vectatutorias.me`, mitigando bloqueos institucionales en Microsoft Outlook UTP y Gmail.
- **Arquitectura de Interfaz Glassmorphism:** Renderizado UI de cristal, diseño de tarjetas semitransparentes y optimización dinámica de íconos reactivos (Variable `onSurface`) incrustados en la navegación principal (Bottom Navigation) adaptable a paletas de colores diurnas/nocturnas.
- **Hardening de Dispositivos (Hardware Compat):** Reglas nativas en la etiqueta `<meta-data>` del `AndroidManifest.xml` inyectadas a nivel binario para evadir los fallos estructurales de *Impeller* en hipercapas gráficas de la arquitectura Xiaomi/HyperOS y procesadores MediaTek antiguos.
- **Refactorización de Lógica de UI:** Erradicación irreversible del botón "Cambiar Contraseña" del perfíl local del frontend y optimización drástica de los controladores asíncronos.
- **Exportador Vectorial Independiente:** Corrección maestra de la impresión vectorial de certificados PDF y gráficas de Dashboards utilizando la nueva API `Printing.layoutPdf()`, obligando al motor de Chrome Web Desktop a disparar los controladores de la impresora del SO anfitrión.
- **Seguridad Perimetral Total (Lockdown Definitivo):** Módulo Firebase App Check reconfigurado exhaustivamente en régimen militar estricto (`reCaptchaV3` invisible con límite de tokens) para producción.

### Changelog v0.9.0 (Arquitectura SRE y Data Mining)
- Implementación de `FirebaseFirestore.instance.runTransaction()` nativas orientadas a bloquear la base de datos contra peticiones concurrentes masivas de reclamación de tutorías simultáneas (Blindaje anti-Race Conditions).
- Rediseño estructural del stack de Navegación (`Navigator.push` y `MaterialPageRoute`) en absolutamente todos los formularios transaccionales, habilitando integración directa con los botones de "Atrás" físicos del sistema operativo Android y gestos "Swipe" de iOS.
- Construcción algorítmica completa del Dashboard de Analítica de Datos (Métricas globales) con cálculos heurísticos iterativos para la extracción de "Deserción Escolar", sumatoria de "Horas de Vida Social Invertidas", y exportación automatizada de reportes estadísticos directos a Documentos PDF.
- Reescritura arquitectónica profunda de las tuberías de Inyección de Dependencias `Provider` para frenar contundentemente todas las fugas asíncronas de memoria (Memory Leaks) producidas por renders desconectados del ciclo de vida visual de la aplicación.
- Construcción modular de los evaluadores (`Promedio Estrellas`), censurador léxico Regex (`Leetspeak`) y limpieza recursiva de archivos nativos del Storage atada a la recolección de basura del backend.

***

**Tutorías Vecta — JIC UTP Panamá — Todos los Derechos Reservados © 2026**
