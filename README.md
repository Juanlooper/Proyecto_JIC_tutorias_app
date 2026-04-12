README: Estado Actual del Proyecto - Tutorías JIC v2
Este documento resume la arquitectura y funcionalidad del sistema tras completar el Roadmap de Lógica Core (Sprint 1-4).
Arquitectura del Backend
La aplicación utiliza una arquitectura Serverless basada en Firebase, centralizando la lógica en Providers para garantizar un estado global reactivo y eficiente.
•	Firebase Auth: Gestiona la identidad y seguridad de las sesiones.
•	Cloud Firestore: Base de datos NoSQL para perfiles, tutorías, evaluaciones y notificaciones.
•	State Management: Implementado con Provider para desacoplar la lógica de negocio de la interfaz visual.
Estructura de Archivos y Funcionalidad
 Modelos (Data Shapes)
•	usuario_model.dart: Define la identidad del usuario (estudiante, tutor o admin) incluyendo su facultad, carrera y lista de suscripciones.
•	tutoria_model.dart: El pilar del sistema. Gestiona materias, modalidades, estados, cupos y la nueva trazabilidad cronológica (inicio/fin real) para auditoría.
Servicios (Conectores Firebase)
•	autenticacion_servicio.dart: El "guardia de seguridad". Maneja registros, inicios de sesión y creación de fichas en Firestore.
•	base_de_datos_servicio.dart: Orquesta el tráficos de tutorías. Implementa transacciones atómicas para evitar choques de cupos en clases concurrentes.
•	evaluacion_servicio.dart: Motor de calidad. Registra estrellas para clases/tutores y gestiona el buzón de quejas críticas para moderación.
Providers (Cerebro Lógico)
•	autenticacion_provider.dart: Controla el flujo de identidad y permite el sistema de suscripciones a tutores con actualización inmediata.
•	tutorias_provider.dart: Gestiona el tablero. Incluye Filtros por Carrera, ocultamiento de solicitudes y limpieza automática (Lazy Evaluation) de clases vencidas.
•	evaluacion_provider.dart: Calcula promedios de reputación usando un sistema de caché local para ahorrar lecturas a Firebase.
•	notificaciones_provider.dart: Gestiona el buzón de alertas in-app para avisar a los estudiantes cuando sus tutores favoritos aceptan clases.
•	admin_provider.dart: Panel de métricas globales. Utiliza .count() para generar estadísticas de alto rendimiento a costo casi nulo.
