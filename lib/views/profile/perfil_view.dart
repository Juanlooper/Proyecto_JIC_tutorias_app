// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/autenticacion_provider.dart';
import '../../models/usuario_model.dart';
import '../auth/login_view.dart';
import '../../core/utils/moderacion_servicio.dart';
import '../tutor/configurar_horario_view.dart';
import '../../services/base_de_datos_servicio.dart';
import '../tutorias/mis_tutorias_view.dart';
import '../view/soporte_screen.dart';

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
                          content: Text(
                            'Lenguaje inapropiado u ofensivo detectado. Por favor, sé respetuoso.',
                          ),
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

    // El controlador se liberará con el Garbage Collector al desmontar el AlertDialog
    // para evitar el error "_dependents.isEmpty is not true" durante la animación de cierre.
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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final colorSubtexto = esOscuro ? Colors.grey[400] : Colors.grey;

    if (elUsuarioActual == null || motorAutenticacion.estaCargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Adaptación a la UI solicitada en el Mockup 5
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle()),

        elevation: 0,
        iconTheme: const IconThemeData(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _procesoDeCierreDeSesion(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Sección Superior Refinada: Avatar y Datos Categóricos
            // Sección Superior Refinada: Avatar y Datos Categóricos Centrados
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: esOscuro
                      ? Colors.teal.withValues(alpha: 0.2)
                      : Colors.teal.shade50,
                  child: const Icon(Icons.person, size: 50, color: Colors.teal),
                ),
                const SizedBox(height: 16),
                Text(
                  elUsuarioActual.nombreCompleto,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  elUsuarioActual.carrera ??
                      elUsuarioActual.facultad ??
                      'Estudiante General',
                  style: TextStyle(fontSize: 14, color: colorSubtexto),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: esOscuro ? Colors.grey[850] : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rol: ${_traducirRolAnalogo(elUsuarioActual.rolEnElSistema).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: esOscuro ? Colors.grey[300] : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sección Emails y Cédula (Mockup inferior del avatar)
            Row(
              children: [
                _buildIcon(Icons.email, Colors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Correo Institucional',
                        style: TextStyle(color: colorSubtexto, fontSize: 12),
                      ),
                      Text(
                        elUsuarioActual.correoElectronico,
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildIcon(Icons.badge, Colors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identificador Interno',
                        style: TextStyle(color: colorSubtexto, fontSize: 12),
                      ),
                      Text(
                        elUsuarioActual.identificadorUnico
                            .substring(0, 8)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: esOscuro ? Colors.grey[800]! : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  // Lógica previa adaptada a Tile
                  if (elUsuarioActual.rolEnElSistema == RolSistema.tutor) ...[
                    ListTile(
                      leading: _buildIcon(
                        Icons.calendar_today,
                        Colors.deepPurple,
                      ),
                      title: const Text(
                        'Mi Disponibilidad',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConfigurarHorarioView(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: _buildIcon(Icons.people_alt, Colors.teal),
                      title: const Text(
                        'Perfil en Comunidad',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => _mostrarDialogoDeEdicion(
                        context,
                        'Descripción',
                        elUsuarioActual.descripcionPerfil ?? '',
                        'Metodología',
                        'descripcionPerfil',
                        esMultilinea: true,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: _buildIcon(Icons.star, Colors.orange),
                      title: const Text(
                        'Especialidades',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => _mostrarDialogoEspecialidades(
                        context,
                        elUsuarioActual,
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  if (elUsuarioActual.rolEnElSistema == RolSistema.estudiante &&
                      elUsuarioActual.estadoSolicitudTutor != 'aprobado') ...[
                    ListTile(
                      leading: _buildIcon(Icons.school, Colors.indigo),
                      title: const Text(
                        'Postularme como Tutor',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle:
                          elUsuarioActual.estadoSolicitudTutor == 'en_revision'
                          ? const Text('En revisión...')
                          : null,
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        if (elUsuarioActual.estadoSolicitudTutor !=
                            'en_revision') {
                          _mostrarDialogoPostulacion(context, elUsuarioActual);
                        }
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: _buildIcon(
                      Icons.contact_phone_outlined,
                      Colors.blue,
                    ),
                    title: const Text(
                      'Mis Datos de Contacto',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () =>
                        _mostrarDialogoDatosContacto(context, elUsuarioActual),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: _buildIcon(Icons.workspace_premium, Colors.teal),
                    title: const Text(
                      'Mis Certificados de Participación',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MisTutoriasView(
                            initialIndex: 2,
                            esSubpantalla: true,
                          ),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: _buildIcon(
                      Icons.headset_mic_outlined,
                      Colors.teal,
                    ),
                    title: const Text(
                      'Contactar Soporte',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SoporteScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: _buildIcon(Icons.logout, Colors.redAccent),
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _procesoDeCierreDeSesion(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoEspecialidades(
    BuildContext context,
    UsuarioModel elUsuarioActual,
  ) async {
    final List<String> listaMaestra = [
      'Cálculo 1',
      'Cálculo 2',
      'Cálculo 3',
      'Ecuaciones Diferenciales',
      'Matemáticas Superiores Para Ingenieros',
      'Física 1',
      'Física 2',
      'Química',
      'Dibujo',
      'Desarrollo Lógico',
      'Programación',
      'Estática',
    ];

    List<String> especialidadesSeleccionadas = List.from(
      elUsuarioActual.materiasEspecializadas,
    );

    await showDialog(
      context: context,
      builder: (contextDialogo) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Materias de Especialidad'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: listaMaestra.map((materia) {
                      final bool estaSeleccionada = especialidadesSeleccionadas
                          .contains(materia);
                      return FilterChip(
                        label: Text(materia),
                        selected: estaSeleccionada,
                        onSelected: (bool seleccion) {
                          setStateModal(() {
                            if (seleccion) {
                              especialidadesSeleccionadas.add(materia);
                            } else {
                              especialidadesSeleccionadas.remove(materia);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(contextDialogo),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(contextDialogo); // cerramos el diálogo rápido

                    // Mostramos indicador
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Guardando especialidades...'),
                      ),
                    );

                    final bool exito = await BaseDeDatosServicio()
                        .actualizarMateriasEspecializadasDelTutor(
                          elUsuarioActual.identificadorUnico,
                          especialidadesSeleccionadas,
                        );

                    if (exito) {
                      // Recargamos sesión local para que UI lo vea
                      if (!mounted) return;
                      await context
                          .read<AutenticacionProvider>()
                          .inicializarSesionAlAbrirApp();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Especialidades guardadas exitosamente',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al guardar. Intenta de nuevo.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  void _mostrarDialogoDatosContacto(
    BuildContext context,
    UsuarioModel elUsuarioActual,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Datos de contacto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.smartphone),
                title: const Text('Teléfono personal'),
                subtitle: Text(
                  elUsuarioActual.telefonoPersonal ?? 'No configurado',
                ),
                onTap: () => _mostrarDialogoDeEdicion(
                  context,
                  'Teléfono personal',
                  elUsuarioActual.telefonoPersonal ?? '',
                  'Teléfono',
                  'telefonoPersonal',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.local_hospital_outlined),
                title: const Text('Contacto Emergencia'),
                subtitle: Text(
                  elUsuarioActual.contactoEmergenciaNombre ?? 'No configurado',
                ),
                onTap: () => _mostrarDialogoDeEdicion(
                  context,
                  'Contacto de Emergencia',
                  elUsuarioActual.contactoEmergenciaNombre ?? '',
                  'Nombre',
                  'contactoEmergenciaNombre',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Tel. Emergencia'),
                subtitle: Text(
                  elUsuarioActual.contactoEmergenciaTelefono ??
                      'No configurado',
                ),
                onTap: () => _mostrarDialogoDeEdicion(
                  context,
                  'Teléfono de Emergencia',
                  elUsuarioActual.contactoEmergenciaTelefono ?? '',
                  'Teléfono',
                  'contactoEmergenciaTelefono',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoPostulacion(
    BuildContext context,
    UsuarioModel usuario,
  ) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Postulación a Tutor',
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Para ser promovido, preséntate al tribunal administrativo con tus créditos (oficiales o no) para una entrevista rápida.\n\n¿Deseas entrar en la lista de revisión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Entrar en Espera'),
          ),
        ],
      ),
    );

    if (confirmacion == true && context.mounted) {
      await _actualizarCampoEnFirestore(
        context,
        'estado_solicitud_tutor',
        'en_revision',
      );
    }
  }
}
