import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import '../../core/theme/app_theme.dart';

/// Vista de Registro (Fase 2 UI)
/// Implementa la interfaz del PDF sin alterar el backend actual.
class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

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

  // Controladores de Credenciales
  final TextEditingController _ctrlCorreo = TextEditingController();
  final TextEditingController _ctrlContrasena = TextEditingController();

  // Estado de los Checkboxes
  bool _aceptoTerminos = false;
  bool _obscureText = true;
  String? _facultadSeleccionada;
  String? _anioSeleccionado;
  String _tipoCelular = 'Nacional';

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
      facultadElegidaEnMenu: _facultadSeleccionada,
      carreraElegidaEnMenu: _anioSeleccionado,
    );

    if (exitoRegistrando && mounted) {
      await motorDeIdentidad.dispararVerificacionDeCorreo();
      await motorDeIdentidad.salirDeLaSesionActual();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cuenta creada. Por favor verifica tu correo (revisa la carpeta de spam o correo no deseado) antes de iniciar sesión.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 8),
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
                    border: Border.all(
                      color: AppTheme.primarioAzul.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    '¡Hola, Bienvenido! Por favor completa los siguientes campos para crear tu perfil en la plataforma.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textoOscuro,
                      height: 1.5,
                    ),
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
                        mensajeAyuda: 'Ingresa explícitamente tu primer nombre en letras (sin apellidos). Ej: Juan',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _construirCampoTexto(
                        'Segundo Nombre',
                        _ctrlSegundoNombre,
                        Icons.person_outline,
                        mensajeAyuda: 'Opcional. Ingresa tu segundo nombre u otro término si corresponde. Ej: Alberto',
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
                        mensajeAyuda: 'Ingresa el apellido inicial de tu familia política o paterna. Ej: Rodríguez',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _construirCampoTexto(
                        'Segundo Apellido',
                        _ctrlSegundoApellido,
                        Icons.badge_outlined,
                        mensajeAyuda: 'Opcional. Ingresa tu segundo apellido o materno. Ej: Pérez',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fila 3: Documentos
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _ctrlCedula,
                        decoration: InputDecoration(
                          labelText: 'Cédula *',
                          hintText: 'Ejemplo: 08-0752-001254',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          prefixIcon: const Icon(Icons.credit_card, color: AppTheme.grisTexto, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, color: AppTheme.primarioAzul, size: 20),
                            onPressed: () => _mostrarAyudaFormato('Cédula de Identidad', 'El formato requiere la escritura obligatoria de **guiones medios** para separar los números.\n\nFORMATO: 00-0000-000000\nDos dígitos - cuatro dígitos - seis dígitos\n\nEjemplo: 08-0752-001254'),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          // Validar el formato exacto: 2 dígitos - 4 dígitos - 6 dígitos
                          final regex = RegExp(r'^\d{2}-\d{4}-\d{6}$');
                          if (!regex.hasMatch(value)) {
                            return 'Formato: 00-0000-000000';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipoCelular,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Nacional', child: Text('Nacional', style: TextStyle(fontSize: 10))),
                          DropdownMenuItem(value: 'Internacional', child: Text('Internac.', style: TextStyle(fontSize: 10))),
                        ],
                        onChanged: (v) => setState(() {
                            _tipoCelular = v!;
                            _ctrlCelular.clear();
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _ctrlCelular,
                        keyboardType: _tipoCelular == 'Nacional' ? TextInputType.number : TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Celular/Fijo',
                          prefixText: _tipoCelular == 'Nacional' ? '+507 ' : '',
                          prefixStyle: const TextStyle(color: Colors.black87, fontSize: 13),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, color: AppTheme.primarioAzul, size: 20),
                            onPressed: () => _mostrarAyudaFormato('Télefono o Celular', 'NACIONAL: Por favor elije [Nacional] en la pestaña izquierda. Digita sólo tu número de móvil o casa sin dejar espacios en blanco ni colocar guiones, tiene que tener 7 u 8 dígitos. Ejemplo: 61234567.\n\nINTERNACIONAL: Selecciona [Internac.] e ingresa tu código de país iniciando con Signo Más (+) y luego tu número. Ejemplo: +12345678.'),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          isDense: true,
                        ),
                        validator: (value) {
                           if (value == null || value.trim().isEmpty) return null;
                           if (_tipoCelular == 'Nacional') {
                              final numLimpio = value.replaceAll(RegExp(r'\D'), '');
                              if (numLimpio.length < 7 || numLimpio.length > 8) return '7-8 dígitos';
                           } else {
                              if (!value.startsWith('+')) return 'Use +';
                           }
                           return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fila 4: Académicos
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _facultadSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Facultad',
                          prefixIcon: const Icon(Icons.account_balance, color: AppTheme.grisTexto, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, color: AppTheme.primarioAzul, size: 20),
                            onPressed: () => _mostrarAyudaFormato('Facultad Principal', 'Pulsa en este campo y despliega la lista para escoger la Facultad estructural dentro de la UTP a la que pertenece tu carrera actual.'),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Facultad de Ciencias y Tecnología', child: Text('Ciencias y Tecnología', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Facultad de Ingeniería Industrial', child: Text('Ing. Industrial', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Facultad de Ingeniería Mecánica', child: Text('Ing. Mecánica', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Facultad de Ingeniería de Sistemas Computacionales', child: Text('Sistemas Comp.', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Facultad de Ingeniería Eléctrica', child: Text('Ing. Eléctrica', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Facultad de Ingeniería Civil', child: Text('Ing. Civil', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                        ],
                        validator: (v) => v == null ? 'Obligatorio' : null,
                        onChanged: (v) => setState(() => _facultadSeleccionada = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _anioSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Año que cursa',
                          prefixIcon: const Icon(Icons.school, color: AppTheme.grisTexto, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, color: AppTheme.primarioAzul, size: 20),
                            onPressed: () => _mostrarAyudaFormato('Año Académico', 'Indica en qué año oficial de tu plan de estudios te consideras ingresado actualmente. Puedes ser desde de Primero a Quinto año.'),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Primero', child: Text('Primero', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Segundo', child: Text('Segundo', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Tercero', child: Text('Tercero', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Cuarto', child: Text('Cuarto', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Quinto', child: Text('Quinto', style: TextStyle(fontSize: 13))),
                        ],
                        validator: (v) => v == null ? 'Obligatorio' : null,
                        onChanged: (v) => setState(() => _anioSeleccionado = v),
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
                    labelText: 'Correo Institucional (@utp.ac.pa)',
                    prefixIcon: const Icon(
                      Icons.email,
                      color: AppTheme.primarioAzul,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.help_outline, color: AppTheme.primarioAzul, size: 20),
                      onPressed: () => _mostrarAyudaFormato('Correo Universitario', 'Para matricularte exitosamente en la plataforma, requieres de un correo proporcionado oficialmente por la institución. El dominio debe ser explícitamente "utp.ac.pa" para considerarse válido. Ejemplo:\njuan.rodriguez@utp.ac.pa'),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) return 'Requerido';

                    if (!valor.toLowerCase().contains('utp.ac.pa')) {
                      return 'Solo se permite correo UTP (ej. @utp.ac.pa)';
                    }
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
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Contraseña (min. 6 caracteres)',
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: AppTheme.primarioAzul,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.primarioAzul,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.help_outline, color: AppTheme.primarioAzul, size: 20),
                          onPressed: () => _mostrarAyudaFormato('Robustez de Contraseña', 'Tu contraseña debe medir al menos 6 caracteres y se mantendrá de forma estricta y oculta en Firebase para cumplir con niveles de encriptación seguros. Tip adicional: Combina mayúsculas y números.'),
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
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
                        'Autorizo que se almacenen y gestionen mis datos personales, de contacto según la Ley 81 de protección de Datos Personales. Comprendo que estos datos son de uso estrictamente confidencial para fines académicos y protocolos de emergencia.',
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
    String? mensajeAyuda,
  }) {
    return TextFormField(
      controller: controlador,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, color: AppTheme.grisTexto, size: 20),
        suffixIcon: mensajeAyuda != null ? IconButton(
          icon: const Icon(Icons.help_outline, color: AppTheme.primarioAzul, size: 20),
          onPressed: () => _mostrarAyudaFormato(etiqueta, mensajeAyuda),
        ) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        isDense: true,
      ),
      validator: obligatorio
          ? (valor) => valor == null || valor.isEmpty ? 'Campo requerido' : null
          : null,
    );
  }

  void _mostrarAyudaFormato(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primarioAzul),
            const SizedBox(width: 8),
            Expanded(child: Text('Formato: $titulo', style: const TextStyle(color: AppTheme.primarioAzul, fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(mensaje, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido', style: TextStyle(color: AppTheme.primarioVerde))),
        ],
      ),
    );
  }
}
