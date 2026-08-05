import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../models/tutoria_model.dart';
import '../../models/usuario_model.dart';
import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../core/theme/app_theme.dart';
import '../tutor/aceptar_solicitud_view.dart';

class MisSugerenciasView extends StatefulWidget {
  const MisSugerenciasView({super.key});

  @override
  State<MisSugerenciasView> createState() => _MisSugerenciasViewState();
}

class _MisSugerenciasViewState extends State<MisSugerenciasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutoriasProvider>().limpiarSolicitudesExpiradas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AutenticacionProvider>();
    final elUsuario = auth.usuarioActual;

    if (elUsuario == null) {
      return const Scaffold(
        body: Center(child: Text("Ocurrió un error al identificar tu sesión.")),
      );
    }

    final esTutor = elUsuario.tieneRol(RolSistema.tutor);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bolsa de Sugerencias",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Cargamos todas las sugerencias globales que aún no tienen tutor
        stream: FirebaseFirestore.instance
            .collection('tutorias')
            .where('estadoDeLaSolicitud', isEqualTo: 'solicitada')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar la bolsa."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _construirEstadoVacio(context);
          }

          // Filtrar adicionalmente por seguridad
          final sugerenciasActivas = snapshot.data!.docs
              .map(
                (doc) =>
                    TutoriaModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .where((m) => m.identificadorDelTutor.isEmpty)
              .toList();

          if (sugerenciasActivas.isEmpty) {
            return _construirEstadoVacio(context);
          }

          // ORDENAMIENTO (De mayor apoyo a menor)
          sugerenciasActivas.sort(
            (a, b) => b.estudiantesApoyando.length.compareTo(
              a.estudiantesApoyando.length,
            ),
          );

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sugerenciasActivas.length,
            itemBuilder: (context, index) {
              final sugerencia = sugerenciasActivas[index];
              return _TarjetaSugerenciaFlat(
                sugerencia: sugerencia,
                usuarioActual: elUsuario,
                esTutor: esTutor,
              );
            },
          );
        },
      ),
    );
  }

  Widget _construirEstadoVacio(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 80,
            color: esOscuro ? Colors.grey[700] : Colors.grey[350],
          ),
          const SizedBox(height: 16),
          Text(
            "La bolsa está vacía.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "¡Sé el primero en proponer una tutoría!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: esOscuro ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaSugerenciaFlat extends StatelessWidget {
  final TutoriaModel sugerencia;
  final UsuarioModel usuarioActual;
  final bool esTutor;

  const _TarjetaSugerenciaFlat({
    required this.sugerencia,
    required this.usuarioActual,
    required this.esTutor,
  });

  void _ejecutarApoyo(BuildContext context, bool yaApoya) async {
    final provider = context.read<TutoriasProvider>();
    bool exito;
    if (yaApoya) {
      exito = await provider.abandonarTutoria(
        sugerencia.identificadorDeTutoria,
      );
    } else {
      exito = await provider.apoyarSugerencia(
        sugerencia.identificadorDeTutoria,
      );
    }

    if (exito && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            yaApoya ? 'Apoyo retirado.' : '¡Has apoyado esta sugerencia!',
          ),
          backgroundColor: yaApoya ? Colors.orange : AppTheme.primarioVerde,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _aceptarClaseComoTutor(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Asumir Tutoría'),
        content: const Text(
          'Al aceptar esta sugerencia, serás promovido como su tutor oficial y deberás configurarla con detalles como modalidad, horarios finales y enlace de reunión. ¿Aceptar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, Aceptar y Configurar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AceptarSolicitudView(tutoria: sugerencia),
        ),
      );
    }
  }

  void _borrarMisugerenciaPropia(BuildContext context) async {
    final provider = context.read<TutoriasProvider>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Petición'),
        content: const Text(
          '¿Deseas retirar defintivamente tu sugerencia de la bolsa comunitaria?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await provider.cancelarSolicitudHuerfana(
        sugerencia.identificadorDeTutoria,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int cantidadApoyos = sugerencia.estudiantesApoyando.length;
    final bool yoApoyoEsto = sugerencia.estudiantesApoyando.contains(
      usuarioActual.identificadorUnico,
    );
    final bool esMiCreacion =
        sugerencia.creador == usuarioActual.identificadorUnico;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final colorSubtexto = esOscuro ? Colors.grey[400] : Colors.grey[700];

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: esOscuro ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1CA887).withValues(alpha: esOscuro ? 0.35 : 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sugerencia.materiaOAsignatura,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorTexto,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$cantidadApoyos',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tema: ${sugerencia.temaEspecifico}',
                style: TextStyle(fontSize: 14, color: colorSubtexto),
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: esOscuro ? Colors.grey[800] : Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!esTutor)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            yoApoyoEsto ? Icons.thumb_down : Icons.thumb_up,
                            color: yoApoyoEsto
                                ? Colors.redAccent
                                : AppTheme.primarioVerde,
                          ),
                          tooltip: yoApoyoEsto ? 'Retirar apoyo' : 'Apoyar',
                          onPressed: () => _ejecutarApoyo(context, yoApoyoEsto),
                        ),
                        Text(
                          yoApoyoEsto ? 'Retirar apoyo' : 'Apoyar',
                          style: TextStyle(
                            color: yoApoyoEsto
                                ? Colors.redAccent
                                : AppTheme.primarioVerde,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                  if (esTutor)
                    FilledButton.icon(
                      onPressed: () => _aceptarClaseComoTutor(context),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Postularme como Tutor'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primarioAzul,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),

                  if (!esTutor && esMiCreacion)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: esOscuro ? Colors.grey[400] : Colors.grey,
                      ),
                      tooltip: 'Eliminar mi sugerencia',
                      onPressed: () => _borrarMisugerenciaPropia(context),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
