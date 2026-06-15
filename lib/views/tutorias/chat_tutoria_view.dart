import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import '../../services/chat_servicio.dart';
import '../../services/notificaciones_servicio.dart';
import '../../providers/tutorias_provider.dart';
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
  late Stream<List<MensajeChat>> _mensajesStream;
  MensajeChat? _mensajeAResponder;

  @override
  void initState() {
    super.initState();
    _mensajesStream = _chatSvc.obtenerMensajesDeTutoria(widget.tutoriaId);
  }

  void _enviarMensaje(String miUid, String miNombre) async {
    final texto = _mensajeCtrl.text.trim();
    if (texto.isEmpty) return;

    _mensajeCtrl.clear();
    try {
      await _chatSvc.enviarMensaje(
        tutoriaId: widget.tutoriaId,
        emisorId: miUid,
        emisorNombre: miNombre,
        texto: texto,
        respuestaA: _mensajeAResponder?.emisorNombre,
        textoRespuesta: _mensajeAResponder?.texto,
      );

      setState(() {
        _mensajeAResponder = null;
      });

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      // Notificar a los miembros del foro
      if (mounted) {
        final tutoriasProv = context.read<TutoriasProvider>();
        try {
          final tutoria = tutoriasProv.tutoriasSuscritasDelUsuario.firstWhere(
            (t) => t.identificadorDeTutoria == widget.tutoriaId,
          );

          List<String> destinatarios = [];
          if (tutoria.identificadorDelTutor.isNotEmpty &&
              tutoria.identificadorDelTutor != miUid) {
            destinatarios.add(tutoria.identificadorDelTutor);
          }
          for (var estudianteId in tutoria.listaDeEstudiantesInscritos) {
            if (estudianteId != miUid) {
              destinatarios.add(estudianteId);
            }
          }

          if (destinatarios.isNotEmpty) {
            await NotificacionesServicio().notificarMultiples(
              uids: destinatarios,
              titulo: 'Foro: ${widget.materia}',
              mensaje: '$miNombre ha enviado un mensaje.',
              tipo: 'info',
            );
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de red al enviar el mensaje.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _construirTextoConEnlaces(String texto, bool esMio) {
    final exp = RegExp(r'(https?://[^\s]+)');
    final Iterable<RegExpMatch> matches = exp.allMatches(texto);

    if (matches.isEmpty) {
      return Text(
        texto,
        style: TextStyle(
          color: esMio ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
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
        style: TextStyle(
          color: esMio ? Colors.white : Colors.black87,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
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

  void _mostrarOpciones(BuildContext context, MensajeChat msg, bool esMio) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.reply_rounded,
                    color: Color(0xFF1CA887),
                  ),
                  title: const Text('Responder'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _mensajeAResponder = msg;
                    });
                  },
                ),
                if (esMio)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Eliminar mensaje',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      try {
                        await _chatSvc.eliminarMensaje(
                          widget.tutoriaId,
                          msg.id,
                        );
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Error al eliminar.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
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
              stream: _mensajesStream,
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

                    return GestureDetector(
                      onLongPress: () {
                        _mostrarOpciones(context, msg, esMio);
                      },
                      onTap: () {
                        _mostrarOpciones(context, msg, esMio);
                      },
                      child: Align(
                        alignment: esMio
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: esMio
                                ? const Color(0xFF1CA887).withValues(alpha: 0.9)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(esMio ? 16 : 0),
                              bottomRight: Radius.circular(esMio ? 0 : 16),
                            ),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (msg.textoRespuesta != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: const Border(
                                          left: BorderSide(
                                            color: Colors.white70,
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.respuestaA ?? '',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: esMio
                                                  ? Colors.white
                                                  : Colors.blueGrey,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            msg.textoRespuesta!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: esMio
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
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
                                ],
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  DateFormat('hh:mm a').format(msg.fechaHora),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: esMio
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (_mensajeAResponder != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey[200],
                    child: Row(
                      children: [
                        const Icon(
                          Icons.reply_rounded,
                          color: Color(0xFF1CA887),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Respondiendo a ${_mensajeAResponder!.emisorNombre}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1CA887),
                                ),
                              ),
                              Text(
                                _mensajeAResponder!.texto,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _mensajeAResponder = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
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
                          minLines: 1,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1CA887),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _enviarMensaje(miUid, miNombre),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
