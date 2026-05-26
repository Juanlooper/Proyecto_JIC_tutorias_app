const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Función que se dispara cada vez que un documento en la colección 'tutorias' es actualizado.
 * Se encarga de verificar si el estado cambió a 'cancelada' o 'aceptada' para enviar 
 * una notificación push selectiva (Cloud Messaging) a los involucrados.
 */
exports.notificarCambioEstadoTutoria = functions.firestore
    .document('tutorias/{tutoriaId}')
    .onUpdate(async (change, context) => {
        const estadoAntes = change.before.data().estadoDeLaSolicitud;
        const estadoDespues = change.after.data().estadoDeLaSolicitud;
        const tutoria = change.after.data();

        // Si el estado no cambió, no hacemos nada (ahorramos ejecuciones y dinero)
        if (estadoAntes === estadoDespues) return null;

        let titulo = '';
        let mensaje = '';
        let uidsAnotificar = [];

        // Lógica para Tutoría Cancelada
        if (estadoDespues === 'cancelada') {
            titulo = 'Tutoría Cancelada ❌';
            mensaje = `La tutoría de ${tutoria.materiaOAsignatura || 'una materia'} ha sido cancelada. Revisa la aplicación para más detalles.`;
            
            // Queremos notificar a todos los estudiantes inscritos
            uidsAnotificar = [...(tutoria.listaDeEstudiantesInscritos || [])];
            
            // Y al tutor (por si un admin la canceló o algo por el estilo)
            if (tutoria.identificadorDelTutor) {
                uidsAnotificar.push(tutoria.identificadorDelTutor);
            }

            // Si era una sugerencia huérfana, notificar a los que la apoyaban
            if (estadoAntes === 'solicitada' || estadoAntes === 'sugerida_directa') {
                mensaje = `Lamentablemente ningún tutor pudo tomar tu sugerencia de clase de ${tutoria.materiaOAsignatura || 'una materia'} a tiempo. Ha sido cancelada automáticamente.`;
                uidsAnotificar.push(...(tutoria.estudiantesApoyando || []));
            }
        } 
        // Lógica para Tutoría Aceptada (Desde la bolsa de sugerencias)
        else if (estadoDespues === 'aceptada' || estadoDespues === 'abierta') {
            titulo = '¡Tutoría Aceptada! 🎉';
            mensaje = `Un tutor acaba de aceptar impartir tu sugerencia de ${tutoria.materiaOAsignatura || 'clase'}. ¡Inscríbete oficialmente desde la Cartelera para reservar tu cupo!`;
            
            // Notificamos a los estudiantes que estaban en la lista de espera/sugerencia
            uidsAnotificar = [...(tutoria.listaDeEstudiantesInscritos || []), ...(tutoria.estudiantesApoyando || [])];
        }
        // Lógica para Sugerencia tomada por un tutor (pasa de 'solicitada' a 'pendiente')
        else if (estadoAntes === 'solicitada' && estadoDespues === 'pendiente') {
            titulo = '¡Tu sugerencia fue aceptada! 🎉';
            mensaje = `Un tutor ha aceptado impartir la clase de ${tutoria.materiaOAsignatura || 'una materia'}. Inscríbete oficialmente desde la Cartelera para reservar tu cupo.`;
            
            uidsAnotificar = [...(tutoria.estudiantesApoyando || [])];
        }
        // Si es otro estado (ej. en_curso, finalizada), no mandamos push notification de momento
        else {
            return null;
        }

        // Limpiar duplicados por si un UID se repite
        uidsAnotificar = [...new Set(uidsAnotificar)];
        
        if (uidsAnotificar.length === 0) {
            console.log('No hay usuarios a los cuales notificar.');
            return null;
        }

        // Buscar en Firestore los 'token_dispositivo' de cada usuario implicado
        const tokensFCM = [];
        for (const uid of uidsAnotificar) {
            try {
                const userDoc = await admin.firestore().collection('usuarios').doc(uid).get();
                if (userDoc.exists) {
                    const token = userDoc.data().token_dispositivo;
                    if (token) {
                        tokensFCM.push(token);
                    }
                }
            } catch (error) {
                console.error(`Error obteniendo token para el usuario ${uid}:`, error);
            }
        }

        if (tokensFCM.length === 0) {
            console.log('Ninguno de los usuarios involucrados tiene un token FCM registrado.');
            return null;
        }

        // Construir el paquete de notificación
        const payload = {
            notification: {
                title: titulo,
                body: mensaje,
            },
            tokens: tokensFCM // sendEachForMulticast espera una lista de tokens aquí
        };

        // Enviar vía Firebase Cloud Messaging
        try {
            const respuesta = await admin.messaging().sendEachForMulticast(payload);
            console.log(`Notificaciones enviadas. Éxito: ${respuesta.successCount}, Fallos: ${respuesta.failureCount}`);
        } catch (error) {
            console.error('Error masivo al intentar enviar notificaciones push:', error);
        }

        return null;
    });

/**
 * Función que se dispara cada vez que se crea un documento en la colección 'notificaciones'.
 * Se encarga de enviar una notificación push (FCM) al dispositivo del usuario.
 */
exports.enviarNotificacionPush = functions.firestore
    .document('notificaciones/{notificacionId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        if (!data || !data.usuarioId) return null;

        const uid = data.usuarioId;
        const titulo = data.titulo || 'Nueva Notificación';
        const mensaje = data.mensaje || 'Tienes una nueva notificación en Vecta.';

        try {
            const userDoc = await admin.firestore().collection('usuarios').doc(uid).get();
            if (!userDoc.exists) {
                console.log(`Usuario ${uid} no encontrado.`);
                return null;
            }

            const token = userDoc.data().token_dispositivo;
            if (!token) {
                console.log(`El usuario ${uid} no tiene token de dispositivo.`);
                return null;
            }

            const payload = {
                notification: {
                    title: titulo,
                    body: mensaje,
                },
                token: token
            };

            const respuesta = await admin.messaging().send(payload);
            console.log(`Notificación push enviada exitosamente a ${uid}:`, respuesta);
        } catch (error) {
            console.error(`Error enviando notificación push a ${uid}:`, error);
        }

        return null;
    });

/**
 * Cron Job: Limpiar clases vencidas
 * Se ejecuta cada 15 minutos. Si una tutoría pendiente pasó de largo por más de 30 minutos
 * y no tiene estudiantes inscritos, se marca como 'cancelada' automáticamente.
 */
exports.limpiarClasesVencidas = functions.pubsub.schedule('every 15 minutes').onRun(async (context) => {
    const db = admin.firestore();
    const ahora = new Date();
    // Restamos 30 minutos
    const limiteTiempo = new Date(ahora.getTime() - 30 * 60000);

    try {
        const snapshot = await db.collection('tutorias')
            .where('estadoDeLaSolicitud', 'in', ['pendiente', 'solicitada', 'sugerida_directa'])
            .get();

        if (snapshot.empty) {
            console.log('No hay tutorías pendientes/solicitadas para limpiar.');
            return null;
        }

        const batch = db.batch();
        let canceladas = 0;

        snapshot.forEach(doc => {
            const data = doc.data();
            const inscritos = data.listaDeEstudiantesInscritos || [];
            
            if (data.fechaHoraSugerida && typeof data.fechaHoraSugerida.toDate === 'function') {
                const fechaTutoria = data.fechaHoraSugerida.toDate();
                
                if (fechaTutoria < limiteTiempo) {
                    let debeCancelar = false;
                    
                    if (data.estadoDeLaSolicitud === 'pendiente' && inscritos.length === 0) {
                        debeCancelar = true; // Clase abandonada por alumnos
                    } else if (data.estadoDeLaSolicitud === 'solicitada' || data.estadoDeLaSolicitud === 'sugerida_directa') {
                        debeCancelar = true; // Sugerencia ignorada por tutores
                    }
                    
                    if (debeCancelar) {
                        batch.update(doc.ref, { estadoDeLaSolicitud: 'cancelada' });
                        canceladas++;
                    }
                }
            }
        });

        if (canceladas > 0) {
            await batch.commit();
            console.log(`Limpieza completada: ${canceladas} tutorías vencidas fueron canceladas.`);
        } else {
            console.log('No se encontraron tutorías vencidas que cumplan los criterios.');
        }

    } catch (error) {
        console.error('Error limpiando clases vencidas:', error);
    }

    return null;
});
