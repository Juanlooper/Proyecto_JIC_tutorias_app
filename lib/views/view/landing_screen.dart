import 'package:flutter/material.dart';
import 'package:tutorias_jic_v2/core/theme/app_theme.dart';
import 'package:tutorias_jic_v2/views/auth/login_view.dart';
import 'package:tutorias_jic_v2/views/auth/registro_view.dart';
import 'package:tutorias_jic_v2/views/view/ayuda_screen.dart';
import 'package:tutorias_jic_v2/views/view/soporte_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // Métodos de Navegación centralizados para auditoría
  void _irALogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  void _irARegistro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroView()),
    );
  }

  void _irAAyuda(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AyudaScreen()),
    );
  }

  void _irASoporte(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SoporteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lógica de Responsividad: Determina si el layout debe ser móvil o desktop
        bool esMovil = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: AppTheme.fondoClaro,
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: esMovil ? 24.0 : 60.0,
                vertical: 30,
              ),
              child: Column(
                children: [
                  // --- HEADER ---
                  _buildHeader(context, esMovil),

                  const SizedBox(height: 80),

                  // --- CUERPO PRINCIPAL ---
                  esMovil
                      ? _buildMobileHero(context)
                      : _buildDesktopHero(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Header: Gestión de Identidad y Soporte
  Widget _buildHeader(BuildContext context, bool esMovil) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.functions,
              size: 45,
              color: AppTheme.primarioVerde,
            ),
            const SizedBox(width: 10),
            const Text(
              'VECTA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textoOscuro,
              ),
            ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => _irAAyuda(context),
              child: Text(
                'Ayuda',
                style: TextStyle(
                  color: AppTheme.textoOscuro,
                  fontSize: esMovil ? 14 : 16,
                ),
              ),
            ),
            const SizedBox(width: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primarioVerde,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _irASoporte(context),
              child: const Text(
                'Soporte',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Layout Desktop: Distribución horizontal de elementos
  Widget _buildDesktopHero(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextosInformativos(false),
              const SizedBox(height: 40),
              _buildBotonesPrincipales(context, false),
            ],
          ),
        ),
        const SizedBox(width: 60),
        Expanded(child: _buildIlustracionPlaceholder()),
      ],
    );
  }

  // Layout Móvil: Distribución vertical para optimizar espacio
  Widget _buildMobileHero(BuildContext context) {
    return Column(
      children: [
        _buildTextosInformativos(true),
        const SizedBox(height: 40),
        _buildBotonesPrincipales(context, true),
        const SizedBox(height: 40),
        _buildIlustracionPlaceholder(),
      ],
    );
  }

  // Componente de Texto: Ajusta el tamaño según el dispositivo
  Widget _buildTextosInformativos(bool esMovil) {
    return Column(
      crossAxisAlignment: esMovil
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Reserva fácil\ntu tutoría',
          textAlign: esMovil ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: esMovil ? 36 : 60,
            fontWeight: FontWeight.bold,
            height: 1.1,
            color: AppTheme.textoOscuro,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Conéctate con tutores calificados de la UTP y asegura tu éxito académico. Todo listo a un solo clic.',
          textAlign: esMovil ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: esMovil ? 16 : 18,
            color: AppTheme.textoOscuro.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Componente de Botones: Usa Wrap para prevenir desbordamientos en móviles pequeños
  Widget _buildBotonesPrincipales(BuildContext context, bool esMovil) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: esMovil ? WrapAlignment.center : WrapAlignment.start,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primarioVerde,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => _irARegistro(context),
          child: const Text(
            'Crear cuenta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primarioAzul,
            side: const BorderSide(color: AppTheme.primarioAzul, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => _irALogin(context),
          child: const Text(
            'Iniciar sesión',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Marcador de posición para la ilustración principal
  Widget _buildIlustracionPlaceholder() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textoOscuro.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppTheme.grisTexto.withOpacity(0.1)),
      ),
      child: const Center(
        child: Text(
          'Ilustración Principal',
          style: TextStyle(color: AppTheme.grisTexto),
        ),
      ),
    );
  }
}
