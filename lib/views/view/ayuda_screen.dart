import 'package:flutter/material.dart';
import 'package:tutorias_jic_v2/core/theme/app_theme.dart';
import 'package:tutorias_jic_v2/views/view/soporte_screen.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primarioVerde),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool esMovil = constraints.maxWidth < 800;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: esMovil ? 24.0 : 60.0,
              vertical: 20,
            ),
            child: esMovil ? _buildMobileLayout() : _buildDesktopLayout(),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildContenidoFaq()),
        const SizedBox(width: 50),
        Expanded(child: _buildIlustracionPlaceholder('Ayuda')),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildContenidoFaq(),
        const SizedBox(height: 40),
        _buildIlustracionPlaceholder('Ayuda'),
      ],
    );
  }

  Widget _buildContenidoFaq() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preguntas Frecuentes',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Encuentra respuestas rápidas a tus dudas sobre VECTA.',
          style: TextStyle(fontSize: 16, color: AppTheme.grisTexto),
        ),
        const SizedBox(height: 30),
        _buildFAQItem(
          '¿Cómo reservo una tutoría?',
          'Selecciona tu materia, elige un tutor disponible y confirma el horario en la aplicación.',
        ),
        _buildFAQItem(
          '¿Es gratuito?',
          'Sí, es un servicio de apoyo académico para estudiantes de la UTP.',
        ),
        _buildFAQItem(
          '¿Puedo cancelar?',
          'Sí, desde el apartado de "Mis tutorías" con tiempo de antelación.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String pregunta, String respuesta) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: AppTheme.grisTexto.withValues(alpha: 0.1)),
      ),
      child: ExpansionTile(
        title: Text(
          pregunta,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              respuesta,
              style: const TextStyle(color: AppTheme.grisTexto),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIlustracionPlaceholder(String titulo) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppTheme.primarioAzul.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppTheme.primarioAzul.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.help_center_rounded,
              size: 80,
              color: AppTheme.primarioAzul,
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Aún tienes dudas?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textoOscuro,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Si las preguntas frecuentes no resolvieron tu problema, puedes contactar a soporte técnico directamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.grisTexto,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SoporteScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Ir a Soporte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primarioAzul,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
