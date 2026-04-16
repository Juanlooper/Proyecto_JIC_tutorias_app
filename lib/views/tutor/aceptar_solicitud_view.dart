import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tutoria_model.dart';
import '../../providers/tutorias_provider.dart';

class AceptarSolicitudView extends StatefulWidget {
  final TutoriaModel tutoria;

  const AceptarSolicitudView({super.key, required this.tutoria});

  @override
  State<AceptarSolicitudView> createState() => _AceptarSolicitudViewState();
}

class _AceptarSolicitudViewState extends State<AceptarSolicitudView> {
  final _ctlLugar = TextEditingController();
  final _ctlContacto = TextEditingController();
  bool _procesando = false;

  @override
  void dispose() {
    _ctlLugar.dispose();
    _ctlContacto.dispose();
    super.dispose();
  }

  void _enviarAceptacion() async {
    final lugar = _ctlLugar.text.trim();
    final contacto = _ctlContacto.text.trim();

    if (lugar.isEmpty || contacto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena el lugar y contacto para notificar al alumno.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _procesando = true);
    
    final proveedor = context.read<TutoriasProvider>();
    final exito = await proveedor.aceptarSolicitudEstudiante(
      widget.tutoria.identificadorDeTutoria,
      lugar,
      contacto,
    );

    setState(() => _procesando = false);

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Tutoría reclamada con éxito!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(proveedor.mensajeDeErrorDelSistema, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Alumno líder (el que creó la bolsa de solicitud)
    final idPrimerAlumno = widget.tutoria.listaDeEstudiantesInscritos.isNotEmpty 
        ? widget.tutoria.listaDeEstudiantesInscritos.first 
        : 'Inscripción fantasma';
        
    final motivoText = widget.tutoria.motivos_alumnos?[idPrimerAlumno] ?? 'No especificó detalles específicos de su necesidad.';
    final linksAdjuntos = widget.tutoria.enlaces_adjuntos?[idPrimerAlumno] ?? <String>[];
    
    final fechaHoraStr = '${widget.tutoria.fechaHoraSugerida.day.toString().padLeft(2, '0')}/${widget.tutoria.fechaHoraSugerida.month.toString().padLeft(2, '0')} - ${widget.tutoria.fechaHoraSugerida.hour.toString().padLeft(2, '0')}:${widget.tutoria.fechaHoraSugerida.minute.toString().padLeft(2, '0')} Hrs';

    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      appBar: AppBar(
        title: const Text('Revisión de Solicitud'),
        backgroundColor: AppTheme.primarioVerde,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera del Alumno
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.primarioAzul,
                      radius: 28,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Solicitante Principal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(idPrimerAlumno, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo panel de emergencia del perfil...')));
                            }, 
                            child: const Text('Ver perfil / Emergencia', style: TextStyle(color: AppTheme.primarioVerde))
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cuerpo Informativo Principal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.tutoria.materiaOAsignatura, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textoOscuro)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.event, color: AppTheme.primarioVerde, size: 20),
                      const SizedBox(width: 8),
                      Text(fechaHoraStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text('Requisitos / Dudas previas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(motivoText, style: const TextStyle(fontSize: 16, height: 1.4, color: AppTheme.textoOscuro)),
                  const SizedBox(height: 16),
                  if (linksAdjuntos.isNotEmpty) ...[
                    const Text('Enlaces de material:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...linksAdjuntos.map((lnk) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: AppTheme.primarioAzul, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(lnk, style: const TextStyle(color: AppTheme.primarioAzul, decoration: TextDecoration.underline))),
                        ],
                      ),
                    )),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Formulario de Setup
            const Text('Configuración de la Clase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textoOscuro)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctlLugar,
              decoration: InputDecoration(
                labelText: 'Lugar de la tutoría (Ej. Biblioteca, Meet)',
                prefixIcon: const Icon(Icons.map, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctlContacto,
              decoration: InputDecoration(
                labelText: 'Contacto (Tu WhatsApp o Correo)',
                prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _procesando ? null : _enviarAceptacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primarioVerde,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _procesando 
                 ? const CircularProgressIndicator(color: Colors.white) 
                 : const Text('ACEPTAR SOLICITUD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
              ),
            )
          ],
        ),
      )
    );
  }
}
