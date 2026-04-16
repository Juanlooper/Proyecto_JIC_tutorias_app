import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/autenticacion_provider.dart';
import '../../models/usuario_model.dart';
import '../auth/login_view.dart';

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
    String llaveFirestore,
  ) async {
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

  /// Extrae con precisión las dos primeras iniciales o recae en la predeterminada.
  String _obtenerIniciales(String nombreCompleto) {
    if (nombreCompleto.isEmpty) return 'U';
    final fragmentos = nombreCompleto.trim().split(' ');
    if (fragmentos.length > 1) {
      return '${fragmentos[0][0]}${fragmentos[1][0]}'.toUpperCase();
    }
    return fragmentos[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final motorAutenticacion = context.watch<AutenticacionProvider>();
    final elUsuarioActual = motorAutenticacion.usuarioActual;

    // Resiliencia Visual Categórica
    if (elUsuarioActual == null || motorAutenticacion.estaCargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área Principal (Cápsula de Identidad)
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        _obtenerIniciales(elUsuarioActual.nombreCompleto),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      elUsuarioActual.nombreCompleto,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        _traducirRolAnalogo(elUsuarioActual.rolEnElSistema),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.blue.shade100,
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (elUsuarioActual.strikes_inasistencia > 0) ...[
                Card(
                  color: Colors.red.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
                    title: const Text('Advertencia de Inasistencia', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    subtitle: Text('Tienes ${elUsuarioActual.strikes_inasistencia} strike(s). Si acumulas demasiados podrías ser penalizado o suspendido de la plataforma.', style: TextStyle(color: Colors.red.shade900)),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Bloque 1: Inmutables del Sistema (Credenciales base)
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'Datos de la Cuenta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.email,
                        color: Colors.blueAccent,
                      ),
                      title: const Text('Correo Electrónico'),
                      subtitle: Text(elUsuarioActual.correoElectronico),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.verified_user,
                        color: Colors.green,
                      ),
                      title: const Text('Nivel de Acceso'),
                      subtitle: Text(
                        _traducirRolAnalogo(elUsuarioActual.rolEnElSistema),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bloque 2: Información Mutante Académica
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'Información Académica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.account_balance,
                        color: Colors.orangeAccent,
                      ),
                      title: const Text('Facultad'),
                      subtitle: Text(
                        elUsuarioActual.facultad?.isNotEmpty == true
                            ? elUsuarioActual.facultad!
                            : 'Aún no configurada',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () => _mostrarDialogoDeEdicion(
                          context,
                          'Facultad',
                          elUsuarioActual.facultad ?? '',
                          'Facultad',
                          'facultad',
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.school,
                        color: Colors.deepPurpleAccent,
                      ),
                      title: const Text('Carrera o Especialidad'),
                      subtitle: Text(
                        elUsuarioActual.carrera?.isNotEmpty == true
                            ? elUsuarioActual.carrera!
                            : 'Aún no configurada',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () => _mostrarDialogoDeEdicion(
                          context,
                          'Carrera',
                          elUsuarioActual.carrera ?? '',
                          'Carrera especial',
                          'carrera',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 56),

              // Botón Secundario: Postulación a Tutor
              if (elUsuarioActual.rolEnElSistema == RolSistema.estudiante && elUsuarioActual.estado_solicitud_tutor == 'ninguna') ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sistema de postulaciones en desarrollo (Fase futura).')),
                    );
                  },
                  icon: const Icon(Icons.star_outline),
                  label: const Text(
                    'Postularme para ser Tutor',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botón Definitivo de Control: Apagado y Limpieza
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _procesoDeCierreDeSesion(context),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'CERRAR SESIÓN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
