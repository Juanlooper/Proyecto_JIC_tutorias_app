// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/autenticacion_provider.dart';
import '../../models/usuario_model.dart';
import '../auth/login_view.dart';
import '../../core/utils/moderacion_servicio.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  Future<void> _mostrarDialogoDeEdicion(
    BuildContext context,
    String campoActual,
    String valorPrevio,
    String titulo,
    String llaveFirestore, {
    bool esMultilinea = false,
  }) async {
    final TextEditingController controladorCampo = TextEditingController(
      text: valorPrevio,
    );
    final GlobalKey<FormState> llaveFormulario = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (contextDialogo) {
        return AlertDialog(
          title: Text('Editar $titulo'),
          content: Form(
            key: llaveFormulario,
            child: TextFormField(
              controller: controladorCampo,
              maxLines: esMultilinea ? 5 : 1,
              decoration: InputDecoration(
                labelText: 'Nuevo $titulo',
                border: const OutlineInputBorder(),
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'El campo no puede estar vacío';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextDialogo),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (llaveFormulario.currentState!.validate()) {
                  final String nuevoValor = controladorCampo.text.trim();
                  if (ModeracionServicio.contieneLenguajeToxico(nuevoValor)) {
                    if (contextDialogo.mounted) {
                      ScaffoldMessenger.of(contextDialogo).showSnackBar(
                        const SnackBar(
                          content: Text('Lenguaje inapropiado u ofensivo detectado. Por favor, sé respetuoso.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                    return;
                  }
                  if (nuevoValor != valorPrevio) {
                    await _actualizarCampoEnFirestore(
                      context,
                      llaveFirestore,
                      nuevoValor,
                    );
                  }
                  if (context.mounted) Navigator.pop(contextDialogo);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    
    // HCI Defensive: Limpiar la memoria del controlador para evitar escapes de memoria
    controladorCampo.dispose();
  }

  /*
   * Documentación del Proceso de actualización de campos específicos en Firestore:
   * Al invocar este método, nos comunicamos directamente con la instancia global de 
   * FirebaseFirestore. Localizamos el documento exacto dentro de la colección 'usuarios'
   * a través del identificador único (ID) del usuario en sesión.
   * La función provista por Firebase 'update({'llave': valor})' es transaccionalmente segura:
   * actualiza u opera silenciosamente únicamente el fragmento o variable que se le envía,
   * respetando la integridad absoluta del resto de los datos en la nube sin sobre-escribir 
   * el documento completo de forma destructiva.
   * Finalmente, se invoca la recarga local del provider para descargar el perfil nuevamente
   * y que la APP se redibuje sola reflejando los datos confirmados.
   */
  Future<void> _actualizarCampoEnFirestore(
    BuildContext context,
    String llaveCampo,
    String valorNuevo,
  ) async {
    final proveedorAuth = context.read<AutenticacionProvider>();
    final idUsuario = proveedorAuth.usuarioActual?.identificadorUnico;

    // Solo procedemos si el usuario tiene una sesión confirmada legalmente.
    if (idUsuario != null) {
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(idUsuario)
            .update({llaveCampo: valorNuevo});

        // Forzamos la actualización de memoria local consumiendo de nuevo los datos alojados en nube
        await proveedorAuth.inicializarSesionAlAbrirApp();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$llaveCampo actualizado de forma exitosa.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ha ocurrido un error al intentar guardar tus datos por problemas de conexión.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _procesoDeCierreDeSesion(BuildContext context) async {
    // Exigimos una auditoria manual (AlertDialog) para prevenir deslogueos accidentales.
    final confirmarSalida = await showDialog<bool>(
      context: context,
      builder: (contextDialogo) {
        return AlertDialog(
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '¿Estás verdaderamente seguro de que deseas desconectarte del sistema de tutorías?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextDialogo, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(contextDialogo, true),
              child: const Text('Sí, Desconectar'),
            ),
          ],
        );
      },
    );

    // Si el usuario presionó 'Sí' en el diálogo:
    if (confirmarSalida == true && context.mounted) {
      // 1. Apagamos el motor del Provider.
      await context.read<AutenticacionProvider>().salirDeLaSesionActual();

      // 2. Erradicamos la pirámide de navegación activa, previniendo que pueda usar el botón "Atrás" de Android.
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (contexto) => const LoginView()),
          (rutaAnterior) => false,
        );
      }
    }
  }

  /// Traductor analógico del Enum a un formato presentable visualmente.
  String _traducirRolAnalogo(RolSistema rol) {
    switch (rol) {
      case RolSistema.admin:
        return 'Administrador del Sistema';
      case RolSistema.tutor:
        return 'Tutor Académico Formal';
      case RolSistema.estudiante:
        return 'Estudiante Regular';
    }
  }


  @override
  Widget build(BuildContext context) {
    final motorAutenticacion = context.watch<AutenticacionProvider>();
    final elUsuarioActual = motorAutenticacion.usuarioActual;

    if (elUsuarioActual == null || motorAutenticacion.estaCargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Adaptación a la UI solicitada en el Mockup 5
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
           IconButton(
             icon: const Icon(Icons.logout, color: Colors.redAccent),
             onPressed: () => _procesoDeCierreDeSesion(context),
           )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Sección Superior Refinada: Avatar y Datos Categóricos
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade400,
                  child: const Icon(Icons.person, size: 70, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        elUsuarioActual.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal, // Verde del mockup
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Rol: ${_traducirRolAnalogo(elUsuarioActual.rolEnElSistema).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _mostrarDialogoDeEdicion(context, 'Carrera', elUsuarioActual.carrera ?? '', 'Ingresa tu carrera (Ej. Ing. Sistemas)', 'carrera'),
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            const Icon(Icons.school, size: 24, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                elUsuarioActual.carrera?.isNotEmpty == true 
                                  ? elUsuarioActual.carrera! 
                                  : 'Editar Carrera...',
                               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                            ),
                            const Icon(Icons.edit, size: 14, color: Colors.teal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _mostrarDialogoDeEdicion(context, 'Facultad', elUsuarioActual.facultad ?? '', 'Ingresa tu facultad (Ej. FISC)', 'facultad'),
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance, size: 20, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                elUsuarioActual.facultad?.isNotEmpty == true 
                                  ? elUsuarioActual.facultad! 
                                  : 'Editar Facultad...',
                               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13),
                              ),
                            ),
                            const Icon(Icons.edit, size: 14, color: Colors.teal),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Sección Emails y Cédula (Mockup inferior del avatar)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.email, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Correo Institucional', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(elUsuarioActual.correoElectronico, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.badge, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Identificador Interno', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(elUsuarioActual.identificadorUnico.substring(0, 8).toUpperCase(), style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 32),

            // Card Interactiva de Datos de Contacto (Mockup 5)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                ]
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         const Text('Datos de contacto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigoAccent)),
                         Icon(Icons.edit, color: Colors.teal, size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _construirCajaEditaRapida(
                      context, 
                      'Teléfono personal',
                      Icons.smartphone, 
                      elUsuarioActual.telefonoPersonal,
                      'telefonoPersonal'
                    ),
                    const SizedBox(height: 16),
                    _construirCajaEditaRapida(
                      context, 
                      'Contacto de Emergencia',
                      Icons.local_hospital_outlined, 
                      elUsuarioActual.contactoEmergenciaNombre,
                      'contactoEmergenciaNombre'
                    ),
                    const SizedBox(height: 16),
                    _construirCajaEditaRapida(
                      context, 
                      'Teléfono de Emergencia',
                      Icons.phone, 
                      elUsuarioActual.contactoEmergenciaTelefono,
                      'contactoEmergenciaTelefono'
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // SECCIÓN DE COMUNIDAD (SÓLO TUTORES)
            if (elUsuarioActual.rolEnElSistema == RolSistema.tutor)
               _construirSeccionPerfilComunidad(context, elUsuarioActual),

            // LÓGICA DE POSTULACIÓN A TUTOR
            if (elUsuarioActual.rolEnElSistema == RolSistema.estudiante)
               _construirSeccionPostulacion(elUsuarioActual),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _construirSeccionPerfilComunidad(BuildContext context, UsuarioModel elUsuarioActual) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text('Perfil en Comunidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
               const Icon(Icons.people_alt, color: Colors.teal, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta información será visible públicamente para que los estudiantes conozcan más sobre tu metodología o experiencia.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _mostrarDialogoDeEdicion(
              context, 
              'Descripción de Perfil', 
              elUsuarioActual.descripcionPerfil ?? '', 
              'Descripción o Metodología', 
              'descripcionPerfil', 
              esMultilinea: true
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border.all(color: Colors.teal.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sobre mí', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      Icon(Icons.edit, color: Colors.teal.shade700, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    elUsuarioActual.descripcionPerfil?.isNotEmpty == true 
                      ? elUsuarioActual.descripcionPerfil! 
                      : 'Toca aquí para escribir una presentación corta sobre ti y lo que enseñas...',
                    style: TextStyle(color: elUsuarioActual.descripcionPerfil?.isNotEmpty == true ? Colors.black87 : Colors.teal.shade700, height: 1.5),
                  )
                ],
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _construirCajaEditaRapida(BuildContext context, String etiqueta, IconData icono, String? valorActual, String llaveFirestore) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          Text(etiqueta, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _mostrarDialogoDeEdicion(context, etiqueta, valorActual ?? '', etiqueta, llaveFirestore),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(icono, color: Colors.indigoAccent.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      valorActual?.isNotEmpty == true ? valorActual! : 'Toca para añadir...',
                      style: const TextStyle(color: Colors.indigoAccent, fontSize: 14),
                    ),
                  )
                ],
              ),
            ),
          ),
       ],
     );
  }

  Widget _construirSeccionPostulacion(UsuarioModel usuario) {
    if (usuario.estadoSolicitudTutor == 'en_revision') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
        child: const Row(
          children: [
            Icon(Icons.access_time_filled, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(child: Text('Tu postulación está en revisión. Presenta tus créditos al Administrador.', style: TextStyle(color: Colors.deepOrange))),
          ],
        ),
      );
    } 

    if (usuario.estadoSolicitudTutor == 'aprobado') {
      return const SizedBox.shrink(); 
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.indigo,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        icon: const Icon(Icons.school),
        label: const Text('Postularme como Tutor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final confirmacion = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Postulación a Tutor', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
              content: const Text('Para ser promovido, preséntate al tribunal administrativo con tus créditos (oficiales o no) para una entrevista rápida.\n\n¿Deseas entrar en la lista de revisión?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.teal), child: const Text('Entrar en Espera')),
              ],
            )
          );

          if (confirmacion == true && context.mounted) {
             await _actualizarCampoEnFirestore(context, 'estado_solicitud_tutor', 'en_revision');
          }
        },
      ),
    );
  }
}
