import 'package:flutter/material.dart';
import 'package:tutorias_jic_v2/core/theme/app_theme.dart';

class SoporteScreen extends StatelessWidget {
  const SoporteScreen({super.key});

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildFormularioSoporte()),
        const SizedBox(width: 60),
        Expanded(child: _buildIlustracionPlaceholder('Soporte')),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildFormularioSoporte(),
        const SizedBox(height: 40),
        _buildIlustracionPlaceholder('Soporte'),
      ],
    );
  }

  Widget _buildFormularioSoporte() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Soporte Técnico',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.textoOscuro,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '¿Algo no funciona bien? Nuestro equipo te ayudará.',
          style: TextStyle(fontSize: 16, color: AppTheme.grisTexto),
        ),
        const SizedBox(height: 30),
        _buildField('Asunto'),
        const SizedBox(height: 15),
        _buildField('Cuéntanos el problema', lines: 5),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primarioVerde,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              // Lógica futura de envío
            },
            child: const Text(
              'Enviar reporte',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String hint, {int lines = 1}) {
    return TextField(
      maxLines: lines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.grisTexto),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.azulClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.primarioVerde, width: 2),
        ),
      ),
    );
  }

  Widget _buildIlustracionPlaceholder(String titulo) {
    return Container(
      height: 350,
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
