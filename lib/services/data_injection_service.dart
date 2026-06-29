import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DataInjectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> injectMockData() async {
    try {
      debugPrint('Iniciando inyección de datos de prueba...');
      final batch = _firestore.batch();

      // IDs fijos para mantener la coherencia relacional
      const adminId = 'admin_001';
      
      const tutor1Id = 'tutor_001';
      const tutor2Id = 'tutor_002';
      const tutor3Id = 'tutor_003';
      
      const est1Id = 'estudiante_001';
      const est2Id = 'estudiante_002';
      const est3Id = 'estudiante_003';

      const tutoriaCompletada1Id = 'tutoria_comp_001';
      const tutoriaCompletada2Id = 'tutoria_comp_002';
      const tutoriaCompletada3Id = 'tutoria_comp_003';
      const tutoriaAceptadaId = 'tutoria_acep_001';

      // ==========================================
      // 1. COLECCIÓN 'usuarios'
      // ==========================================
      
      // Admin
      final adminRef = _firestore.collection('usuarios').doc(adminId);
      batch.set(adminRef, {
        'uid': adminId,
        'nombre': 'Administrador Global',
        'correo': 'admin@vecta.edu',
        'rol': 'admin',
        'fotoUrl': '',
        'carrera': 'Ingeniería de Sistemas',
        'sede': 'Sede Principal',
        'materias': [],
        'disponibilidad': 'Lunes a Viernes, 8:00 AM - 5:00 PM',
        'calificacionPromedio': 5.0,
      });

      // Tutores
      final tutor1Ref = _firestore.collection('usuarios').doc(tutor1Id);
      batch.set(tutor1Ref, {
        'uid': tutor1Id,
        'nombre': 'Carlos Mendoza',
        'correo': 'carlos.mendoza@vecta.edu',
        'rol': 'tutor',
        'fotoUrl': '',
        'carrera': 'Ingeniería de Software',
        'sede': 'Campus Norte',
        'materias': ['Programación I', 'Estructuras de Datos', 'Bases de Datos'],
        'disponibilidad': 'Lunes y Miércoles, 2:00 PM - 6:00 PM',
        'calificacionPromedio': 4.8,
      });

      final tutor2Ref = _firestore.collection('usuarios').doc(tutor2Id);
      batch.set(tutor2Ref, {
        'uid': tutor2Id,
        'nombre': 'Ana Lucía Ramírez',
        'correo': 'ana.ramirez@vecta.edu',
        'rol': 'tutor',
        'fotoUrl': '',
        'carrera': 'Ingeniería de Sistemas',
        'sede': 'Sede Principal',
        'materias': ['Cálculo I', 'Física I', 'Álgebra Lineal'],
        'disponibilidad': 'Martes y Jueves, 9:00 AM - 1:00 PM',
        'calificacionPromedio': 4.9,
      });

      final tutor3Ref = _firestore.collection('usuarios').doc(tutor3Id);
      batch.set(tutor3Ref, {
        'uid': tutor3Id,
        'nombre': 'David Rojas',
        'correo': 'david.rojas@vecta.edu',
        'rol': 'tutor',
        'fotoUrl': '',
        'carrera': 'Ingeniería de Telecomunicaciones',
        'sede': 'Campus Sur',
        'materias': ['Redes I', 'Sistemas Operativos'],
        'disponibilidad': 'Viernes, 2:00 PM - 8:00 PM',
        'calificacionPromedio': 4.7,
      });

      // Estudiantes
      final est1Ref = _firestore.collection('usuarios').doc(est1Id);
      batch.set(est1Ref, {
        'uid': est1Id,
        'nombre': 'Sofía Castillo',
        'correo': 'sofia.castillo@est.vecta.edu',
        'rol': 'estudiante',
        'fotoUrl': '',
        'carrera': 'Ingeniería de Software',
        'sede': 'Campus Norte',
        'materias': [],
        'disponibilidad': '',
        'calificacionPromedio': 0.0,
      });

      final est2Ref = _firestore.collection('usuarios').doc(est2Id);
      batch.set(est2Ref, {
        'uid': est2Id,
        'nombre': 'Miguel Torres',
        'correo': 'miguel.torres@est.vecta.edu',
        'rol': 'estudiante',
        'fotoUrl': '',
        'carrera': 'Ingeniería de Sistemas',
        'sede': 'Sede Principal',
        'materias': [],
        'disponibilidad': '',
        'calificacionPromedio': 0.0,
      });

      final est3Ref = _firestore.collection('usuarios').doc(est3Id);
      batch.set(est3Ref, {
        'uid': est3Id,
        'nombre': 'Laura Gómez',
        'correo': 'laura.gomez@est.vecta.edu',
        'rol': 'estudiante',
        'fotoUrl': '',
        'carrera': 'Ingeniería de Telecomunicaciones',
        'sede': 'Campus Sur',
        'materias': [],
        'disponibilidad': '',
        'calificacionPromedio': 0.0,
      });

      // ==========================================
      // 2. COLECCIÓN 'tutorias'
      // ==========================================
      
      // Tutoría Completada 1
      final tutoria1Ref = _firestore.collection('tutorias').doc(tutoriaCompletada1Id);
      batch.set(tutoria1Ref, {
        'id': tutoriaCompletada1Id,
        'estudianteId': est1Id,
        'tutorId': tutor1Id,
        'materia': 'Programación I',
        'fecha': '2023-10-05',
        'hora': '14:00',
        'estado': 'completada',
        'descripcion': 'Necesito ayuda para entender ciclos y condicionales en Java.',
        'enlaceReunion': 'https://teams.microsoft.com/l/meetup-join/test1',
        'calificacionEstudiante': 5.0,
        'calificacionTutor': 4.5,
        'comentarios': 'Muy buena explicación, me ayudó a terminar el taller.',
      });

      // Tutoría Completada 2
      final tutoria2Ref = _firestore.collection('tutorias').doc(tutoriaCompletada2Id);
      batch.set(tutoria2Ref, {
        'id': tutoriaCompletada2Id,
        'estudianteId': est2Id,
        'tutorId': tutor2Id,
        'materia': 'Cálculo I',
        'fecha': '2023-10-12',
        'hora': '09:00',
        'estado': 'completada',
        'descripcion': 'Dudas con derivadas y reglas de la cadena.',
        'enlaceReunion': 'https://teams.microsoft.com/l/meetup-join/test2',
        'calificacionEstudiante': 4.5,
        'calificacionTutor': 5.0,
        'comentarios': 'El tutor dominaba el tema a la perfección.',
      });

      // Tutoría Completada 3
      final tutoria3Ref = _firestore.collection('tutorias').doc(tutoriaCompletada3Id);
      batch.set(tutoria3Ref, {
        'id': tutoriaCompletada3Id,
        'estudianteId': est3Id,
        'tutorId': tutor1Id,
        'materia': 'Estructuras de Datos',
        'fecha': '2023-10-20',
        'hora': '16:00',
        'estado': 'completada',
        'descripcion': 'Implementación de árboles binarios de búsqueda.',
        'enlaceReunion': 'https://teams.microsoft.com/l/meetup-join/test3',
        'calificacionEstudiante': 4.8,
        'calificacionTutor': 4.8,
        'comentarios': 'Logré resolver mi error de segmentación gracias a la tutoría.',
      });

      // Tutoría Aceptada (activa)
      final tutoria4Ref = _firestore.collection('tutorias').doc(tutoriaAceptadaId);
      batch.set(tutoria4Ref, {
        'id': tutoriaAceptadaId,
        'estudianteId': est1Id,
        'tutorId': tutor3Id,
        'materia': 'Sistemas Operativos',
        'fecha': '2023-11-15',
        'hora': '15:00',
        'estado': 'aceptada',
        'descripcion': 'Ayuda con algoritmos de planificación de procesos.',
        'enlaceReunion': 'https://teams.microsoft.com/l/meetup-join/test4',
        'calificacionEstudiante': 0.0,
        'calificacionTutor': 0.0,
        'comentarios': '',
      });

      // ==========================================
      // 3. COLECCIÓN 'chats'
      // ==========================================
      // Guardando subcolección 'chats' dentro de la tutoría aceptada
      final chatRef = tutoria4Ref.collection('chats');
      
      final msg1Ref = chatRef.doc('msg_001');
      batch.set(msg1Ref, {
        'emisorId': est1Id,
        'mensaje': 'Hola, ¿nos vemos por Teams?',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final msg2Ref = chatRef.doc('msg_002');
      batch.set(msg2Ref, {
        'emisorId': tutor3Id,
        'mensaje': '¡Hola Sofía! Sí, te comparto el enlace en unos minutos.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final msg3Ref = chatRef.doc('msg_003');
      batch.set(msg3Ref, {
        'emisorId': est1Id,
        'mensaje': 'Listo, ya me conecto.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Ejecutar el lote
      await batch.commit();
      debugPrint('¡Inyección de datos completada exitosamente!');
      
    } catch (e) {
      debugPrint('Error al inyectar datos: $e');
    }
  }
}
