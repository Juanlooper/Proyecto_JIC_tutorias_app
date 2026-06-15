import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/tutoria_model.dart';
import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';

class ComunidadSugerenciasView extends StatefulWidget {
  const ComunidadSugerenciasView({super.key});

  @override
  State<ComunidadSugerenciasView> createState() =>
      _ComunidadSugerenciasViewState();
}

class _ComunidadSugerenciasViewState extends State<ComunidadSugerenciasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutoriasProvider>().limpiarSolicitudesExpiradas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final motorAutenticacion = context.read<AutenticacionProvider>();
    final uidUsuarioActual =
        motorAutenticacion.usuarioActual?.identificadorUnico;

    if (uidUsuarioActual == null) {
      return const Scaffold(
        body: Center(child: Text("Sesión inválida o expirada.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bolsa de la Comunidad",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),

        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Optimizamos interceptando al menos el estado principal desde la petición para aminorar los datos locales
        stream: FirebaseFirestore.instance
            .collection('tutorias')
            .where('estadoDeLaSolicitud', isEqualTo: 'solicitada')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text("Algo salió mal al conectar con la base de datos."),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _construirEstadoVacio();
          }

          // Filtro estricto local secundario: Extraemos SOLO las que carecen de identificador de tutor
          final documentosCrudos = snapshot.data!.docs;
          final peticionesComunitarias = documentosCrudos
              .map((doc) {
                return TutoriaModel.fromMap(doc.data() as Map<String, dynamic>);
              })
              .where((modelo) {
                return modelo
                    .identificadorDelTutor
                    .isEmpty; // Refuerzo de regla arquitectónica
              })
              .toList();

          if (peticionesComunitarias.isEmpty) {
            return _construirEstadoVacio();
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: peticionesComunitarias.length,
            itemBuilder: (context, index) {
              final recomendacionGlobal = peticionesComunitarias[index];
              final bool apoyaActualmente = recomendacionGlobal
                  .listaDeEstudiantesInscritos
                  .contains(uidUsuarioActual);

              return _TarjetaVotacionComunitaria(
                sugerencia: recomendacionGlobal,
                yaEstaUnido: apoyaActualmente,
                onUnirseClick: () async {
                  final managerLogic = Provider.of<TutoriasProvider>(
                    context,
                    listen: false,
                  );
                  bool completado = await managerLogic.apoyarSugerencia(
                    recomendacionGlobal.identificadorDeTutoria,
                  );

                  if (completado && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Te has sumado a la solicitud!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(managerLogic.mensajeDeErrorDelSistema),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _construirEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey[350]),
          const SizedBox(height: 16),
          const Text(
            "La bolsa está silenciosa...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            "Actualmente no hay sugerencias\nen espera de profesor.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _TarjetaVotacionComunitaria extends StatelessWidget {
  final TutoriaModel sugerencia;
  final bool yaEstaUnido;
  final VoidCallback onUnirseClick;

  const _TarjetaVotacionComunitaria({
    required this.sugerencia,
    required this.yaEstaUnido,
    required this.onUnirseClick,
  });

  @override
  Widget build(BuildContext context) {
    // Computar Date y Time presentables
    final controlDia = sugerencia.fechaHoraSugerida;
    final diaFormateado =
        "${controlDia.day.toString().padLeft(2, '0')}/${controlDia.month.toString().padLeft(2, '0')}/${controlDia.year}";
    final TimeOfDay relojUI = TimeOfDay(
      hour: controlDia.hour,
      minute: controlDia.minute,
    );

    // UI del contador atractivo
    final int apoyo = sugerencia.listaDeEstudiantesInscritos.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey,
        ),
        boxShadow: [BoxShadow(blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sección Superior: Cabecera descriptiva elegante
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono Estilizado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF6C63FF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Metadatos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sugerencia.materiaOAsignatura,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            diaFormateado,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            relojUI.format(context),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sección Media: Tema Específico
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Tema sugerido: ${sugerencia.temaEspecifico}",
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sección Inferior (Footer): Interacción y Contador Social
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Contador Social Estilizado
                Row(
                  children: [
                    Icon(
                      Icons.group_add_rounded,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Apoyando: $apoyo",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Condicional del Botón (Pilar vital del UX)
                yaEstaUnido
                    ? _BotonDespachadoGris(texto: "Ya apoyas esta clase")
                    : _BotonActivoVerde(
                        texto: "Apoyar y Unirse",
                        alPresionar: onUnirseClick,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonActivoVerde extends StatelessWidget {
  final String texto;
  final VoidCallback alPresionar;

  const _BotonActivoVerde({required this.texto, required this.alPresionar});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: alPresionar,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00C853), // Accent Verde
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _BotonDespachadoGris extends StatelessWidget {
  final String texto;

  const _BotonDespachadoGris({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
