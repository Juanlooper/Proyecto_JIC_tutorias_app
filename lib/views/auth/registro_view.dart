import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/autenticacion_provider.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _ejecutarRegistro() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AutenticacionProvider>();

      // Conectado con la lógica exacta de tu backend
      bool exito = await authProvider.registrarseEnElSistemaGlobal(
        correoEscrito: _correoController.text.trim(),
        contrasenaEscrita: _passwordController.text.trim(),
        nombreEscrito: _nombreController.text.trim(),
      );

      if (exito && mounted) {
        await authProvider.dispararVerificacionDeCorreo();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Cuenta creada! Revisa tu correo UTP para verificarla.',
            ),
            backgroundColor: AppTheme.verdeVecta,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.mensajeDeError,
            ), // <-- Error manejado correctamente
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AutenticacionProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textoOscuro),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Completa tu expediente estudiantil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoOscuro,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Primer Nombre',
                      ),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _apellidoController,
                      decoration: const InputDecoration(
                        labelText: 'Primer Apellido',
                      ),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional (@utp.ac.pa)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Ingresa tu correo';
                  if (!value.endsWith('@utp.ac.pa'))
                    return 'Debe ser correo UTP';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Crea una contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.length < 6)
                    return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 48),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: authProvider.estaCargando
                      ? null
                      : _ejecutarRegistro,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.azulVecta,
                  ),
                  child: authProvider.estaCargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Crear cuenta',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
