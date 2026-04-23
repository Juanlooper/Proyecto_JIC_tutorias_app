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
        } 
        // Lógica para Tutoría Aceptada (Desde la bolsa de sugerencias)
        else if (estadoDespues === 'aceptada') {
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
            
            // (Opcional) Aquí podríamos identificar tokens fallidos (caducados) y borrarlos de la BD
            
        } catch (error) {
            console.error('Error masivo al intentar enviar notificaciones push:', error);
        }

        return null;
    });
