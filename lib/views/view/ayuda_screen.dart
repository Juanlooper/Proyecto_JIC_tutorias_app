import 'package:flutter/material.dart';
import 'package:tutorias_jic_v2/core/theme/app_theme.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.textoOscuro,
          ),
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
        side: BorderSide(color: AppTheme.grisTexto.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        title: Text(
          pregunta,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textoOscuro,
          ),
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
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.grisTexto.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          'Ilustración de $titulo',
          style: const TextStyle(color: AppTheme.grisTexto),
        ),
      ),
    );
  }
}
