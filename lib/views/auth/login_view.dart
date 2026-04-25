// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/autenticacion_provider.dart';
import '../navigation/enrutador_roles_view.dart';
import 'registro_view.dart';
import 'package:tutorias_jic_v2/views/view/landing_screen.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _ejecutarLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AutenticacionProvider>();

      bool exito = await authProvider.ingresarConCorreoYClave(
        correoEscrito: _correoController.text.trim(),
        contrasenaEscrita: _passwordController.text.trim(),
      );

      if (!exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.mensajeDeError),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (exito && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EnrutadorRolesView()),
        );
      }
    }
  }

  void _mostrarDialogoRecuperarPassword() {
    final TextEditingController correoRecuperacion = TextEditingController(
      text: _correoController.text,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Recuperar Contraseña',
            style: TextStyle(color: AppTheme.primarioVerde),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu correo institucional para recibir un enlace de recuperación.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: correoRecuperacion,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (correoRecuperacion.text.trim().isEmpty) return;
                Navigator.pop(context); // cerramos dialogo
                final authProvider = context.read<AutenticacionProvider>();
                bool enviado = await authProvider.solicitarCambioDeContrasena(
                  correoRecuperacion.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        enviado
                            ? 'Enlace de recuperación enviado. Revisa tu correo.'
                            : authProvider.mensajeDeError,
                      ),
                      backgroundColor: enviado
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('Enviar Enlace'),
            ),
          ],
        );
      },
    );
  }

  Widget _construirPanelIzquierdo() {
    final authProvider = context.watch<AutenticacionProvider>();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Logo Circular
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  backgroundImage: const AssetImage(
                    'assets/images/logo_vecta.png',
                  ),
                  onBackgroundImageError: (_, _) {},
                ),
              ),
              const SizedBox(height: 24),

              // Título
              const Text(
                'Portal Académico',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primarioVerde,
                ),
              ),
              const SizedBox(height: 48),

              // Formulario
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Correo
                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Correo institucional (@utp.ac.pa)',
                        hintStyle: TextStyle(color: Colors.blue.shade300),
                        prefixIcon: Icon(
                          Icons.email,
                          color: Colors.blue.shade700,
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.blue.shade400,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        if (!value.contains('@')) return 'Correo no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        hintStyle: TextStyle(color: Colors.blue.shade300),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Colors.blue.shade700,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.blue.shade700,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.blue.shade400,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Botón Iniciar Sesión (Pill shape)
                    SizedBox(
                      width: 200,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: authProvider.estaCargando
                            ? null
                            : _ejecutarLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primarioVerde,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: authProvider.estaCargando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recuperar clave
                    InkWell(
                      onTap: _mostrarDialogoRecuperarPassword,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Enlace Registro
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistroView(),
                          ),
                        );
                      },
                      child: Text(
                        '¿No tienes cuenta? Crea tu cuenta aquí',
                        style: TextStyle(
                          color: Colors.blue.shade400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaInformativa({
    required IconData icono,
    required String titulo,
    required String subtitulo,
  }) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icono, color: AppTheme.primarioVerde, size: 28),
          const SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.primarioVerde,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPanelDerecho() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE5EFF9), // Suave celeste claro
            Color(0xFFC7DFF2), // Celeste intermedio
            Color(0xFFDCD5E4), // Tinte pastel morado/gris leve
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Cómo funciona?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primarioVerde,
                ),
              ),
              const SizedBox(height: 48),
              _construirTarjetaInformativa(
                icono: Icons.access_time,
                titulo: 'Reserva fácil',
                subtitulo:
                    'Agenda tutorías en segundos desde cualquier dispositivo',
              ),
              _construirTarjetaInformativa(
                icono: Icons.support_agent,
                titulo: 'Atención personalizada',
                subtitulo:
                    'Envía tus dudas y recibe apoyo adaptado a tus necesidades',
              ),
              _construirTarjetaInformativa(
                icono: Icons.verified,
                titulo: 'Tutores calificados',
                subtitulo:
                    'Aprende con estudiantes destacados y especializados',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primarioVerde),
          onPressed: () {
            // Se usa pushReplacement para evitar que la pantalla de login permanezca en la pila de navegación.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LandingScreen()),
            );
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Si la pantalla es ancha (Web/Escritorio)
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                Expanded(flex: 4, child: _construirPanelIzquierdo()),
                Expanded(flex: 6, child: _construirPanelDerecho()),
              ],
            );
          } else {
            // Diseño móvil: Apilar los páneles
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: constraints.maxHeight * 0.85,
                    child: _construirPanelIzquierdo(),
                  ),
                  SizedBox(height: 800, child: _construirPanelDerecho()),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
