import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import '../../core/theme/app_theme.dart';

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
  final TextEditingController _ctrlFacultad = TextEditingController();
  final TextEditingController _ctrlCarrera = TextEditingController();
  final TextEditingController _ctrlIngles = TextEditingController();

  // Controladores de Credenciales
  final TextEditingController _ctrlCorreo = TextEditingController();
  final TextEditingController _ctrlContrasena = TextEditingController();

  // Estado de los Checkboxes
  bool _aceptoTerminos = false;

  @override
  void dispose() {
    _ctrlPrimerNombre.dispose();
    _ctrlSegundoNombre.dispose();
    _ctrlPrimerApellido.dispose();
    _ctrlSegundoApellido.dispose();
    _ctrlCedula.dispose();
    _ctrlCelular.dispose();
    _ctrlFacultad.dispose();
    _ctrlCarrera.dispose();
    _ctrlIngles.dispose();
    _ctrlCorreo.dispose();
    _ctrlContrasena.dispose();
    super.dispose();
  }

  /// Lógica de puente: Toma los datos de la UI y los adapta al backend existente
  Future<void> _procesarInscripcionVisual() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptoTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los terminos para continuar.'),
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
      facultadElegidaEnMenu: _ctrlFacultad.text.trim().isNotEmpty ? _ctrlFacultad.text.trim() : null,
      carreraElegidaEnMenu: _ctrlCarrera.text.trim().isNotEmpty ? _ctrlCarrera.text.trim() : null,
    );

    if (exitoRegistrando && mounted) {
      await motorDeIdentidad.dispararVerificacionDeCorreo();
      await motorDeIdentidad.salirDeLaSesionActual();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada. Por favor verifica tu correo UTP antes de iniciar sesion.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      }
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primarioAzul.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primarioAzul.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '¡Hola, Bienvenido! Gracias por tu interés en ser tutor. Por favor completa los siguientes campos y adjunta tu hoja de vida. Te notificaremos pronto el estado de tu postulación.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textoOscuro, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
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
                        'Cedula',
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
                const SizedBox(height: 16),

                // Fila 4: Académicos
                Row(
                  children: [
                    Expanded(
                      child: _construirCampoTexto('Facultad', _ctrlFacultad, Icons.account_balance),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _construirCampoTexto('Carrera', _ctrlCarrera, Icons.school),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fila 5: Inglés y CV
                Row(
                  children: [
                    Expanded(
                      child: _construirCampoTexto('Nivel de Inglés', _ctrlIngles, Icons.language),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Subir Hoja de Vida', style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
                          style: OutlinedButton.styleFrom(
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             side: const BorderSide(color: AppTheme.primarioAzul),
                             foregroundColor: AppTheme.primarioAzul
                          ),
                          onPressed: () {},
                        ),
                      )
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

                    // DOWNGRADE DE SEGURIDAD (Pruebas Locales) 
                    // Ya no filtramos a que solo sea @utp.ac.pa
                    if (!valor.contains('@')) {
                      return 'Debe ser un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contrasena
                TextFormField(
                  controller: _ctrlContrasena,
                  enabled: !semaforoCarga,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contrasena (min. 6 caracteres)',
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

                // Checkbox de terminos (HCI: Prevención de errores legales)
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
                        'Autorizo que se almacenen y gestionen mis datos personales según la Ley 81 de Proteccion de Datos Personales.',
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
