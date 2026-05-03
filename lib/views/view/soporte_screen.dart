import 'package:flutter/material.dart';
import 'package:tutorias_jic_v2/core/theme/app_theme.dart';

class SoporteScreen extends StatelessWidget {
  const SoporteScreen({super.key});

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
            child: esMovil ? _buildMobileLayout(context) : _buildDesktopLayout(context),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildFormularioSoporte(context)),
        const SizedBox(width: 60),
        Expanded(child: _buildIlustracionPlaceholder('Soporte')),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildFormularioSoporte(context),
        const SizedBox(height: 40),
        _buildIlustracionPlaceholder('Soporte'),
      ],
    );
  }

  Widget _buildFormularioSoporte(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Soporte Técnico',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            
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
              // Simular envío de reporte
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Tu reporte ha sido enviado con éxito. Te contactaremos pronto.'),
                  backgroundColor: AppTheme.primarioVerde,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
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
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.primarioVerde.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.primarioVerde.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.support_agent_rounded, size: 80, color: AppTheme.primarioVerde),
          const SizedBox(height: 20),
          const Text(
            'Estamos para ayudarte',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoOscuro,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Nuestro equipo técnico revisará tu reporte y te contactará al correo registrado en la plataforma lo antes posible.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppTheme.grisTexto, height: 1.5),
          ),
          const SizedBox(height: 35),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primarioVerde.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email_rounded, color: AppTheme.primarioVerde),
            ),
            title: const Text('Soporte Directo', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('soporte@vecta.edu.pa'),
          ),
          const SizedBox(height: 15),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primarioVerde.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_rounded, color: AppTheme.primarioVerde),
            ),
            title: const Text('Horario de Atención', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Lunes a Viernes, 8:00 AM - 5:00 PM'),
          ),
        ],
      ),
    );
  }
}
