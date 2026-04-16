import 'package:flutter/material.dart';
import '../../models/usuario_model.dart';
import '../../core/theme/app_theme.dart';

class TutorialVectaWidget extends StatefulWidget {
  final RolSistema rol;

  const TutorialVectaWidget({super.key, required this.rol});

  @override
  State<TutorialVectaWidget> createState() => _TutorialVectaWidgetState();
}

class _TutorialVectaWidgetState extends State<TutorialVectaWidget> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  List<Map<String, String>> _obtenerPaginas() {
    if (widget.rol == RolSistema.tutor) {
      return [
        {
          "titulo": "Tu Dashboard",
          "descripcion": "Mira tus clases pendientes y organiza tu tiempo para ayudar a tus companeros.",
          "icono": "dashboard"
        },
        {
          "titulo": "Pasa Lista",
          "descripcion": "Es obligatorio pasar lista al final para liberar horas de labor social oficiales.",
          "icono": "check_circle"
        },
        {
          "titulo": "Regla de 12 horas",
          "descripcion": "Cancela con al menos 12 horas de anticipacion o seras reportado en el panel de quejas.",
          "icono": "warning"
        }
      ];
    } else {
      // Estudiantes y Admins (visualización estándar)
      return [
        {
          "titulo": "Encuentra Tutorias",
          "descripcion": "Explora la cartelera y busca tu materia para encontrar la ayuda que necesitas.",
          "icono": "search"
        },
        {
          "titulo": "Inscribete",
          "descripcion": "Al apuntarte, justifica que necesitas aprender para que el tutor se prepare exitosamente.",
          "icono": "edit_document"
        },
        {
          "titulo": "Asiste",
          "descripcion": "Cuidado, las faltas injustificadas generan strikes y posibles baneos permanentes en VECTA.",
          "icono": "event_busy"
        }
      ];
    }
  }

  IconData _convertirIcono(String icono) {
    switch (icono) {
      case "dashboard": return Icons.dashboard;
      case "check_circle": return Icons.check_circle_outline;
      case "warning": return Icons.warning_amber_rounded;
      case "search": return Icons.search;
      case "edit_document": return Icons.edit_document;
      case "event_busy": return Icons.event_busy;
      default: return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginas = _obtenerPaginas();

    return Container(
      padding: const EdgeInsets.all(24),
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24)
        )
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _paginaActual = index;
                });
              },
              itemCount: paginas.length,
              itemBuilder: (context, index) {
                final page = paginas[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.primarioVerde.withValues(alpha: 0.1),
                      child: Icon(
                        _convertirIcono(page["icono"]!),
                        size: 48,
                        color: AppTheme.primarioVerde
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      page["titulo"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textoOscuro),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page["descripcion"]!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                      textAlign: TextAlign.center,
                    )
                  ],
                );
              },
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indicadores (Dots)
              Row(
                children: List.generate(paginas.length, (index) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  height: 10,
                  width: _paginaActual == index ? 24 : 10,
                  decoration: BoxDecoration(
                    color: _paginaActual == index ? AppTheme.primarioVerde : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)
                  ),
                )),
              ),
              
              // Botón de acción
              FilledButton(
                onPressed: _paginaActual == paginas.length - 1
                    ? () => Navigator.pop(context)
                    : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300), 
                          curve: Curves.easeInOut
                        );
                      },
                child: Text(_paginaActual == paginas.length - 1 ? '¡Entendido!' : 'Siguiente'),
              )
            ],
          )
        ],
      )
    );
  }
}
