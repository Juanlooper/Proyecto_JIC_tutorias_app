import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import '../../services/chat_servicio.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ChatTutoriaView extends StatefulWidget {
  final String tutoriaId;
  final String materia;

  const ChatTutoriaView({
    super.key,
    required this.tutoriaId,
    required this.materia,
  });

  @override
  State<ChatTutoriaView> createState() => _ChatTutoriaViewState();
}

class _ChatTutoriaViewState extends State<ChatTutoriaView> {
  final ChatServicio _chatSvc = ChatServicio();
  final TextEditingController _mensajeCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  void _enviarMensaje(String miUid, String miNombre) async {
    final texto = _mensajeCtrl.text.trim();
    if (texto.isEmpty) return;

    _mensajeCtrl.clear();
    await _chatSvc.enviarMensaje(
      tutoriaId: widget.tutoriaId,
      emisorId: miUid,
      emisorNombre: miNombre,
      texto: texto,
    );
    
    // Auto-scroll al fondo: al usar reverse: true, la posición 0.0 es el mensaje más reciente
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _construirTextoConEnlaces(String texto, bool esMio) {
    final exp = RegExp(r'(https?://[^\s]+)');
    final Iterable<RegExpMatch> matches = exp.allMatches(texto);

    if (matches.isEmpty) {
      return Text(
        texto,
        style: TextStyle(color: esMio ? Colors.white : Colors.black87, fontSize: 14),
      );
    }

    List<TextSpan> spans = [];
    int start = 0;
    for (var match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: texto.substring(start, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: esMio ? Colors.blue[100] : Colors.blue[800],
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ),
      );
      start = match.end;
    }
    if (start < texto.length) {
      spans.add(TextSpan(text: texto.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: esMio ? Colors.white : Colors.black87, fontSize: 14, fontFamily: 'Roboto'),
        children: spans,
      ),
    );
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AutenticacionProvider>();
    final miUid = authProv.usuarioActual?.identificadorUnico ?? '';
    final miNombre = authProv.usuarioActual?.nombreCompleto ?? 'Alumno';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Micro-Foro', style: TextStyle(fontSize: 16)),
            Text(
              widget.materia,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1CA887),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.orange.withValues(alpha: 0.1),
            width: double.infinity,
            child: const Text(
              '⚠️ Los mensajes de este chat se eliminarán 24h después de la clase.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MensajeChat>>(
              stream: _chatSvc.obtenerMensajesDeTutoria(widget.tutoriaId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar mensajes',
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay mensajes aún. ¡Sé el primero en saludar!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final mensajes = snapshot.data!.reversed.toList();
                return ListView.builder(
                  reverse: true,
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: mensajes.length,
                  itemBuilder: (context, i) {
                    final msg = mensajes[i];
                    final esMio = msg.emisorId == miUid;

                    return Align(
                      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: esMio ? const Color(0xFF1CA887).withValues(alpha: 0.9) : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(esMio ? 16 : 0),
                            bottomRight: Radius.circular(esMio ? 0 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!esMio)
                              Text(
                                msg.emisorNombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1951CB),
                                ),
                              ),
                            if (!esMio) const SizedBox(height: 4),
                            _construirTextoConEnlaces(msg.texto, esMio),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                DateFormat('hh:mm a').format(msg.fechaHora),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: esMio ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensajeCtrl,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1CA887),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => _enviarMensaje(miUid, miNombre),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
