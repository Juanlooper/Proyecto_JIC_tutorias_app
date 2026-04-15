import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import '../../core/theme/app_theme.dart';
import '../main_navigation_view.dart';

/// Vista de Registro (Fase 2 UI)
/// Implementa la interfaz del PDF sin alterar el backend actual.
class RegistroView extends StatefulWidget {
  const RegistroView({Key? key}) : super(key: key);

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();

  // Controladores UI (Campos del PDF)
  final TextEditingController _ctrlPrimerNombre = TextEditingController();
  final TextEditingController _ctrlSegundoNombre = TextEditingController();
  final TextEditingController _ctrlPrimerApellido = TextEditingController();
  final TextEditingController _ctrlSegundoApellido = TextEditingController();
  final TextEditingController _ctrlCedula = TextEditingController();
  final TextEditingController _ctrlCelular = TextEditingController();

  // Controladores de Credenciales
  final TextEditingController _ctrlCorreo = TextEditingController();
  final TextEditingController _ctrlContrasena = TextEditingController();

  // Estado de los Checkboxes
  bool _aceptoTerminos = false;

  /// Lógica de puente: Toma los datos de la UI y los adapta al backend existente
  Future<void> _procesarInscripcionVisual() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptoTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos para continuar.'),
        ),
      );
      return;
    }

    // Adaptación para no tocar la base de datos: Concatenamos los nombres
    String nombreEnsamblado =
        "${_ctrlPrimerNombre.text.trim()} ${_ctrlPrimerApellido.text.trim()}";
    String correoLimpio = _ctrlCorreo.text.trim().toLowerCase();
    String claveLimpa = _ctrlContrasena.text.trim();

    final motorDeIdentidad = context.read<AutenticacionProvider>();

    bool exitoRegistrando = await motorDeIdentidad.registrarseEnElSistemaGlobal(
      correoEscrito: correoLimpio,
      contrasenaEscrita: claveLimpa,
      nombreEscrito: nombreEnsamblado,
      // Pasamos null temporalmente a facultad y carrera ya que no están en esta pantalla UI
      facultadElegidaEnMenu: null,
      carreraElegidaEnMenu: null,
    );

    if (exitoRegistrando && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationView()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(motorDeIdentidad.mensajeDeError),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final semaforoCarga = context.watch<AutenticacionProvider>().estaCargando;

    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      appBar: AppBar(
        title: Text(
          'Crear cuenta',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppTheme.primarioAzul),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primarioAzul),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completa tu expediente estudiantil',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primarioVerde,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Fila 1: Nombres
                Row(
                  children: [
                    Expanded(
                      child: _construirCampoTexto(
                        'Primer Nombre',
                        _ctrlPrimerNombre,
                        Icons.person,
                        obligatorio: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _construirCampoTexto(
                        'Segundo Nombre',
                        _ctrlSegundoNombre,
                        Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fila 2: Apellidos
                Row(
                  children: [
                    Expanded(
                      child: _construirCampoTexto(
                        'Primer Apellido',
                        _ctrlPrimerApellido,
                        Icons.badge,
                        obligatorio: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _construirCampoTexto(
                        'Segundo Apellido',
                        _ctrlSegundoApellido,
                        Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fila 3: Documentos
                Row(
                  children: [
                    Expanded(
                      child: _construirCampoTexto(
                        'Cédula',
                        _ctrlCedula,
                        Icons.credit_card,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _construirCampoTexto(
                        'Celular',
                        _ctrlCelular,
                        Icons.phone_android,
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(),
                ),

                Text(
                  'Crea tus credenciales de acceso',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primarioVerde,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),

                // Correo Institucional
                TextFormField(
                  controller: _ctrlCorreo,
                  enabled: !semaforoCarga,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo institucional (@utp.ac.pa)',
                    prefixIcon: const Icon(
                      Icons.email,
                      color: AppTheme.primarioAzul,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) return 'Requerido';
                    if (!valor.trim().toLowerCase().endsWith('@utp.ac.pa')) {
                      return 'Debe ser un correo UTP válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _ctrlContrasena,
                  enabled: !semaforoCarga,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña (min. 6 caracteres)',
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: AppTheme.primarioAzul,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.length < 6)
                      return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Checkbox de términos (HCI: Prevención de errores legales)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _aceptoTerminos,
                        activeColor: AppTheme.primarioVerde,
                        onChanged: semaforoCarga
                            ? null
                            : (bool? valor) {
                                setState(() {
                                  _aceptoTerminos = valor ?? false;
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Autorizo que se almacenen y gestionen mis datos personales según la Ley 81 de Protección de Datos Personales.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grisTexto,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Botón de Envío
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: semaforoCarga
                        ? null
                        : _procesarInscripcionVisual,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarioAzul,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: semaforoCarga
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Crear cuenta y registrarme',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Método auxiliar para construir campos de texto estandarizados
  Widget _construirCampoTexto(
    String etiqueta,
    TextEditingController controlador,
    IconData icono, {
    bool obligatorio = false,
  }) {
    return TextFormField(
      controller: controlador,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, color: AppTheme.grisTexto, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        isDense: true,
      ),
      validator: obligatorio
          ? (valor) => valor == null || valor.isEmpty ? '*' : null
          : null,
    );
  }
}
