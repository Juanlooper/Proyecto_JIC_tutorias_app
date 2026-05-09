import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import '../../core/utils/moderacion_servicio.dart';

class VectaColors {
  // principal
  static const Color primaryGreen = Color(0xFF1CA887);
  static const Color darkBlue = Color(0xFF1E2938);
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color textGray = Color(0xFF8B929A);
  static const Color softBlue = Color(0xFF89A6E4);
  static const Color secondaryBlue = Color(0xFF1951CB);
  static const Color lightGreen = Color(0xFF8AD1C2);
  static const Color errorRed = Colors.red;
}

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  // Controladores UI (Nombres y datos importantes)
  final TextEditingController _ctrlPrimerNombre = TextEditingController();
  final TextEditingController _ctrlPrimerApellido = TextEditingController();
  final TextEditingController _ctrlCelularPersonal = TextEditingController();
  final TextEditingController _ctrlTelefonoEmergencia = TextEditingController();
  final TextEditingController _ctrlContactoEmergencia = TextEditingController();
  final TextEditingController _ctrlParentesco = TextEditingController();

  // Controladores de Credenciales
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variables de Dropdown
  String? _anoSeleccionado;
  String? _facultadSeleccionada;
  String? _carreraSeleccionada;
  final TextEditingController _ctrlDropdownCarrera = TextEditingController();

  final List<String> _anos = [
    'Primer Año',
    'Segundo Año',
    'Tercer Año',
    'Cuarto Año',
    'Quinto Año',
  ];
  final Map<String, List<String>> _facultadesUTP = {
    'Facultad de Ingeniería de Sistemas Computacionales (FISC)': [
      'Lic. en Ingeniería de Sistemas y Computación',
      'Lic. en Ingeniería de Software',
      'Lic. en Ingeniería de Sistemas de Información',
      'Lic. en Ingeniería de Sistemas de Información Gerencial',
      'Lic. en Ciberseguridad',
      'Lic. en Ciencias de la Computación',
      'Lic. en Desarrollo de Software',
      'Lic. en Desarrollo y Gestión de Software',
      'Lic. en Redes Informáticas',
      'Técnico en Informática Aplicada a la Educación',
      'Técnico en Ingeniería con Especialización en Ciberseguridad',
      'Técnico en Ingeniería con Especialización en Redes Informáticas',
    ],
    'Facultad de Ingeniería Civil (FIC)': [
      'Lic. en Ingeniería Civil',
      'Lic. en Ingeniería Ambiental',
      'Lic. en Ingeniería Geomática',
      'Lic. en Ingeniería Geológica',
      'Lic. en Ingeniería Marítima Portuaria',
      'Lic. en Ingeniería en Administración de Proyectos de Construcción',
      'Lic. en Edificaciones',
      'Lic. en Topografía',
      'Lic. en Saneamiento y Ambiente',
      'Lic. en Dibujo Automatizado',
      'Lic. en Operaciones Marítimas y Portuarias',
    ],
    'Facultad de Ingeniería Eléctrica (FIE)': [
      'Lic. en Ingeniería Eléctrica',
      'Lic. en Ingeniería Eléctrica y Electrónica',
      'Lic. en Ingeniería Electromecánica',
      'Lic. en Ingeniería Electrónica y Telecomunicaciones',
      'Lic. en Ingeniería Electrónica Industrial (Carrera Reciente)',
      'Lic. en Electrónica y Sistemas de Comunicación',
      'Lic. en Sistemas Eléctricos y Automatización',
      'Técnico en Ingeniería con Especialización en Sistemas Eléctricos',
      'Técnico en Ingeniería con Especialización en Electrónica Biomédica',
      'Técnico en Electromecánica Industrial',
    ],
    'Facultad de Ingeniería Industrial (FII)': [
      'Lic. en Ingeniería Industrial',
      'Lic. en Ingeniería Mecánica Industrial',
      'Lic. en Ingeniería Logística y Cadena de Suministro',
      'Lic. en Ingeniería en Seguridad Industrial e Higiene Ocupacional',
      'Lic. en Logística y Transporte Multimodal',
      'Lic. en Mercadeo y Negocios Internacionales',
      'Lic. en Gestión Administrativa',
      'Lic. en Gestión de la Producción Industrial',
      'Técnico en Gestión de Ventas',
      'Técnico en Recursos Humanos y Gestión de la Productividad',
    ],
    'Facultad de Ingeniería Mecánica (FIM)': [
      'Lic. en Ingeniería Mecánica',
      'Lic. en Ingeniería Aeronáutica',
      'Lic. en Ingeniería Naval',
      'Lic. en Ingeniería de Energía y Ambiente',
      'Lic. en Ingeniería de Mantenimiento',
      'Lic. en Administración de Aviación (con opción a vuelo - Piloto)',
      'Lic. en Mecánica Industrial',
      'Lic. en Refrigeración y Aire Acondicionado',
      'Técnico en Ingeniería con Especialización en Mecánica Automotriz',
    ],
    'Facultad de Ciencias y Tecnología (FCT)': [
      'Lic. en Ingeniería de Alimentos',
      'Lic. en Ingeniería Forestal',
      'Lic. en Ingeniería Química (Carrera Reciente)',
      'Lic. en Comunicación Ejecutiva Bilingüe',
      'Técnico en Comunicación Ejecutiva Bilingüe',
    ],
  };

  // Estado de validación
  String? _errorEmail;
  bool _emailEsValido = false;
  bool _aceptaTerminos = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _ctrlPrimerNombre.dispose();
    _ctrlPrimerApellido.dispose();
    _ctrlCelularPersonal.dispose();
    _ctrlTelefonoEmergencia.dispose();
    _ctrlContactoEmergencia.dispose();
    _ctrlParentesco.dispose();
    _ctrlDropdownCarrera.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _mostrarVentanaAyuda(String tituloField, String explicacion) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Ayuda: $tituloField',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : VectaColors.darkBlue,
            ),
          ),
          content: Text(
            explicacion,
            style: const TextStyle(
              fontSize: 16,
              color: VectaColors.textGray,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: VectaColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _validarEmail(String val) {
    setState(() {
      if (val.isEmpty) {
        _errorEmail = 'El correo es obligatorio';
        _emailEsValido = false;
      } else if (!val.endsWith('@utp.ac.pa')) {
        _errorEmail = 'Debe ser tu correo institucional (@utp.ac.pa)';
        _emailEsValido = false;
      } else {
        _errorEmail = null;
        _emailEsValido = true;
      }
    });
  }

  Future<void> _intentarCrearCuenta() async {
    // Validaciones basicas
    if (_ctrlPrimerNombre.text.trim().isEmpty ||
        _ctrlPrimerApellido.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, ingresa tu primer nombre y primer apellido.',
          ),
          backgroundColor: VectaColors.errorRed,
        ),
      );
      return;
    }

    if (ModeracionServicio.contieneLenguajeToxico(_ctrlPrimerNombre.text) || 
        ModeracionServicio.contieneLenguajeToxico(_ctrlPrimerApellido.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, usa tu nombre real. El lenguaje ofensivo no está permitido en Vecta.'), backgroundColor: VectaColors.errorRed));
      return;
    }
    if (_facultadSeleccionada == null || _carreraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona tu facultad y carrera.'),
          backgroundColor: VectaColors.errorRed,
        ),
      );
      return;
    }

    if (!_emailEsValido) {
      _validarEmail(_emailController.text);
      if (!_emailEsValido) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revisa tu correo institucional.'),
            backgroundColor: VectaColors.errorRed,
          ),
        );
        return;
      }
    }

    final pass = _passwordController.text;
    final hasUppercase = pass.contains(RegExp(r'[A-Z]'));
    final hasNumber = pass.contains(RegExp(r'[0-9]'));
    final hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (pass.length < 8 || !hasUppercase || !hasNumber || !hasSpecial) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres, una mayúscula, un número y un carácter especial.'), backgroundColor: VectaColors.errorRed));
      return;
    }

    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones.'),
          backgroundColor: VectaColors.errorRed,
        ),
      );
      return;
    }

    // Si todo está bien, registramos
    String nombreEnsamblado =
        "${_ctrlPrimerNombre.text.trim()} ${_ctrlPrimerApellido.text.trim()}";
    String correoLimpio = _emailController.text.trim().toLowerCase();
    String claveLimpa = _passwordController.text.trim();

    final motorDeIdentidad = context.read<AutenticacionProvider>();

    bool exitoRegistrando = await motorDeIdentidad.registrarseEnElSistemaGlobal(
      correoEscrito: correoLimpio,
      contrasenaEscrita: claveLimpa,
      nombreEscrito: nombreEnsamblado,
      facultadElegidaEnMenu: _facultadSeleccionada,
      carreraElegidaEnMenu: _carreraSeleccionada,
      celular: _ctrlCelularPersonal.text.trim().isNotEmpty
          ? _ctrlCelularPersonal.text.trim()
          : null,
      contactoEmergenciaNombre: _ctrlContactoEmergencia.text.trim().isNotEmpty
          ? _ctrlContactoEmergencia.text.trim()
          : null,
      contactoEmergenciaTelefono: _ctrlTelefonoEmergencia.text.trim().isNotEmpty
          ? _ctrlTelefonoEmergencia.text.trim()
          : null,
      anoCursando: _anoSeleccionado,
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
          backgroundColor: VectaColors.errorRed,
        ),
      );
    }
  }
  Widget _buildResponsiveRow(Widget child1, Widget child2) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          child1,
          const SizedBox(height: 15),
          child2,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          const SizedBox(width: 20),
          Expanded(child: child2),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final semaforoCarga = context.watch<AutenticacionProvider>().estaCargando;

    return Scaffold(
      backgroundColor: VectaColors.backgroundGray,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 800, // Ancho limitado para web
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono regresar
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: VectaColors.primaryGreen,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Logo de Vecta
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VectaColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo_vecta.png',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Título principal
                const Text(
                  'Completa tu expediente estudiantil',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: VectaColors.primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 35),

                // SECCIÓN 1: Datos Personales
                _buildResponsiveRow(
                  _buildHelpTextField(
                    'Primer Nombre',
                    Icons.person,
                    'Por favor, ingresa tu primer nombre legal. Solo se permiten letras.',
                    type: _FieldType.soloLetras,
                    controller: _ctrlPrimerNombre,
                  ),
                  _buildHelpTextField(
                    'Primer Apellido',
                    Icons.badge,
                    'Por favor, ingresa tu primer apellido legal. Solo se permiten letras.',
                    type: _FieldType.soloLetras,
                    controller: _ctrlPrimerApellido,
                  ),
                ),
                const SizedBox(height: 15),
                // Campo de Cédula con el formato exacto del Forms
                _buildHelpTextField(
                  'Cédula (Ej. 08-0000-000000)',
                  Icons.credit_card,
                  'Utiliza el formato NN-NNNN-NNNNNN (2 dígitos, guión, 4 dígitos, guión, 6 dígitos). Los guiones se insertan automáticamente.',
                  type: _FieldType.cedula,
                ),
                const SizedBox(height: 15),
                // Año que cursa (Menú desplegable)
                _buildDropdownField(
                  'Año que cursa',
                  Icons.school,
                  _anos,
                  _anoSeleccionado,
                  (val) {
                    setState(() => _anoSeleccionado = val);
                  },
                  'Selecciona el año académico que estás cursando actualmente.',
                ),
                const SizedBox(height: 15),
                // Facultad y Carrera dinámicas
                _buildResponsiveRow(
                  _buildDropdownField(
                    'Facultad',
                    Icons.account_balance,
                    _facultadesUTP.keys.toList(),
                    _facultadSeleccionada,
                    (val) {
                      setState(() {
                        _facultadSeleccionada = val;
                        _carreraSeleccionada = null; // Resetea la carrera
                        _ctrlDropdownCarrera.clear();
                      });
                    },
                    'Selecciona la facultad a la que pertenece tu carrera.',
                  ),
                  _buildSearchableDropdown(
                    'Carrera',
                    Icons.menu_book,
                    _facultadSeleccionada != null
                        ? _facultadesUTP[_facultadSeleccionada]!
                        : [],
                    _carreraSeleccionada,
                    _ctrlDropdownCarrera,
                    (val) {
                      setState(() => _carreraSeleccionada = val);
                    },
                    'Escribe o selecciona tu carrera en la lista.',
                  ),
                ),

                const SizedBox(height: 35),
                const Divider(color: VectaColors.lightGreen, thickness: 1),
                const SizedBox(height: 25),

                // SECCIÓN 2: Datos de emergencia
                const Text(
                  'Datos de contacto de emergencia',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: VectaColors.primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                _buildResponsiveRow(
                  _buildHelpTextField(
                    'Celular personal',
                    Icons.smartphone,
                    'El prefijo +507 ya está puesto. Ingresa los 8 dígitos restantes; un guión se pondrá automáticamente después de los 4 primeros números.',
                    type: _FieldType.celular,
                    controller: _ctrlCelularPersonal,
                  ),
                  _buildHelpTextField(
                    'Teléfono de emergencia',
                    Icons.phone,
                    'El prefijo +507 ya está puesto. Ingresa los 8 dígitos restantes; un guión se pondrá automáticamente después de los 4 primeros números.',
                    type: _FieldType.celular,
                    controller: _ctrlTelefonoEmergencia,
                  ),
                ),
                const SizedBox(height: 15),
                _buildResponsiveRow(
                  _buildHelpTextField(
                    'Contacto de emergencia (Nombre)',
                    Icons.health_and_safety,
                    'Nombre completo de la persona que debemos contactar en caso de una emergencia real.',
                    controller: _ctrlContactoEmergencia,
                  ),
                  _buildHelpTextField(
                    'Parentesco',
                    Icons.family_restroom,
                    'Ejemplo: Madre, Padre, Tío, Hermano/a. Solo se permiten letras.',
                    type: _FieldType.soloLetras,
                    controller: _ctrlParentesco,
                  ),
                ),

                const SizedBox(height: 35),
                const Divider(color: VectaColors.lightGreen, thickness: 1),
                const SizedBox(height: 25),

                // SECCIÓN 3: Credenciales
                const Text(
                  'Crea tus credenciales de acceso',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: VectaColors.primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 35),

                Container(
                  width: 500,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _validarEmail,
                        decoration: InputDecoration(
                          hintText: 'Correo institucional (@utp.ac.pa)',
                          hintStyle: const TextStyle(
                            color: VectaColors.softBlue,
                          ),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: VectaColors.secondaryBlue,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.help_outline,
                              color: VectaColors.secondaryBlue,
                              size: 20,
                            ),
                            onPressed: () => _mostrarVentanaAyuda(
                              'Correo Electrónico',
                              'Ingresa tu dirección de correo electrónico institucional de la UTP. El sistema solo acepta direcciones que terminen en "@utp.ac.pa".',
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _errorEmail == null
                                  ? VectaColors.softBlue
                                  : VectaColors.errorRed,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _errorEmail == null
                                  ? VectaColors.primaryGreen
                                  : VectaColors.errorRed,
                              width: 2,
                            ),
                          ),
                          errorText: _errorEmail,
                          errorStyle: const TextStyle(
                            color: VectaColors.errorRed,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          hintText: 'Contraseña (min. 8 caracteres, Mayús, #, Especial)',
                          hintStyle: const TextStyle(color: VectaColors.softBlue),
                          prefixIcon: const Icon(Icons.lock, color: VectaColors.secondaryBlue),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: VectaColors.secondaryBlue,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.help_outline, color: VectaColors.secondaryBlue, size: 20),
                                onPressed: () => _mostrarVentanaAyuda('Contraseña', 'Crea una contraseña segura de al menos 8 caracteres. Obligatoriamente debe contener al menos una mayúscula, un número y un carácter especial (ej. !@#\$%^&*).'),
                              ),
                            ],
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: VectaColors.softBlue,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: VectaColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Desplegable de Términos y Condiciones
                Container(
                  width: 600,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: VectaColors.softBlue),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        'Leer Términos y Condiciones',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : VectaColors.darkBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: const Icon(
                        Icons.policy,
                        color: VectaColors.secondaryBlue,
                      ),
                      iconColor: VectaColors.primaryGreen,
                      collapsedIconColor: VectaColors.secondaryBlue,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          color: VectaColors.backgroundGray,
                          child: Text(
                            '''TÉRMINOS, CONDICIONES Y POLÍTICA DE PRIVACIDAD DE VECTA: ¡Bienvenido a Vecta! Esta plataforma ha sido diseñada para facilitar la gestión y el acceso a tutorías académicas. Antes de utilizar nuestra aplicación, te pedimos que leas detenidamente los siguientes Términos y Condiciones, así como nuestra Política de Privacidad. Al registrarte y utilizar Vecta, aceptas cumplir con estas normativas.

1. Marco Legal y Derechos del Usuario
Vecta opera bajo las leyes de la República de Panamá y cumple de manera estricta con la Ley No. 81 de 26 de marzo de 2019 sobre Protección de Datos Personales. Como usuario, tienes garantizados tus derechos ARCO:
• Acceso: Conocer qué datos tuyos tenemos.
• Rectificación: Corregir datos inexactos o desactualizados.
• Cancelación: Solicitar la eliminación de tu cuenta y tus datos de nuestros servidores.
• Oposición: Negarte al uso de tus datos para fines específicos.

2. ¿Qué datos recopilamos y para qué?
Para brindarte una experiencia funcional y conectarte con los tutores o estudiantes adecuados, recopilamos la siguiente información estrictamente necesaria:
• Datos de Identificación: Nombre completo y correo electrónico (preferiblemente institucional).
• Datos Académicos: Carrera que cursas y tu sede universitaria. Esto permite a los algoritmos de la app filtrar y mostrarte las tutorías que realmente te sirven.
• Datos de Uso: Registros de inscripciones a tutorías y asistencia, utilizados únicamente con fines estadísticos para mejorar la calidad del programa.
No venderemos, alquilaremos ni compartiremos tu información personal con terceros ajenos al programa de tutorías sin tu consentimiento previo.

3. Ciberseguridad y Almacenamiento
Tus datos están protegidos. Vecta utiliza infraestructuras seguras en la nube (a través de bases de datos como Firebase) que incluyen:
• Encriptación: Tus contraseñas y datos viajan cifrados desde tu dispositivo hasta nuestros servidores.
• Autenticación Segura: Sistemas de validación de identidad para prevenir el acceso no autorizado a tu cuenta.

4. Reglas de Uso y Conducta
Al utilizar Vecta, te comprometes a mantener un ambiente de respeto y colaboración académica. Queda estrictamente prohibido:
• Proporcionar información falsa durante el registro.
• Suplantar la identidad de otro estudiante o profesor.
• Utilizar la plataforma para fines comerciales, distribución de spam o cualquier actividad ajena al ámbito académico.
• Faltar al respeto a tutores o compañeros dentro de los espacios gestionados por la plataforma.
• Intentar vulnerar, alterar o extraer el código o las bases de datos de la aplicación.
El incumplimiento de estas reglas resultará en la suspensión o eliminación inmediata de tu cuenta.

5. Propiedad Intelectual
Todo el diseño, código fuente, logotipos (incluyendo la integración del símbolo de sumatoria y espiral de Fibonacci) y textos de la plataforma Vecta son propiedad de sus desarrolladores. No está permitida su copia, distribución o modificación sin autorización previa y por escrito.

6. Limitaciones de Responsabilidad
Vecta es una herramienta tecnológica diseñada para facilitar el apoyo académico. Por lo tanto:
• No garantizamos la aprobación de materias ni resultados académicos específicos. El éxito depende del esfuerzo del estudiante.
• No nos hacemos responsables por fallas de conexión a internet o de los servidores que puedan interrumpir temporalmente el servicio de la app.
• Cualquier acuerdo o interacción que ocurra entre tutores y estudiantes fuera de los canales oficiales de Vecta es responsabilidad exclusiva de los involucrados.

7. Cambios en estas Políticas
Nos reservamos el derecho de actualizar este documento para adaptarnos a nuevas regulaciones legales o mejoras en la aplicación. Te notificaremos a través de la app o por correo electrónico si se realizan cambios importantes.''',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : VectaColors.darkBlue,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // CUADRO de términos y condiciones (Checkbox)
                Container(
                  width: 600,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: VectaColors.softBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _aceptaTerminos,
                        activeColor: VectaColors.secondaryBlue,
                        side: const BorderSide(
                          color: VectaColors.secondaryBlue,
                          width: 2,
                        ),
                        onChanged: semaforoCarga
                            ? null
                            : (bool? valorNuevo) => setState(
                                () => _aceptaTerminos = valorNuevo ?? false,
                              ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'He leído y autorizo que se almacenen y gestionen mis datos personales y de contacto según la Ley 81 de protección de Datos Personales. Comprendo que estos datos son de uso estrictamente confidencial para fines académicos y protocolos de emergencia.',
                          style: TextStyle(
                            color: VectaColors.secondaryBlue,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // BOTÓN FINAL
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VectaColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    onPressed: semaforoCarga ? null : _intentarCrearCuenta,
                    child: semaforoCarga
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Crear cuenta y registrarme',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  // auxiliar para crear campos de texto con iconos de ayuda y validaciones
  Widget _buildHelpTextField(
    String hint,
    IconData icon,
    String ayuda, {
    _FieldType type = _FieldType.soloLetras,
    TextEditingController? controller,
  }) {
    TextInputType keyboardType = TextInputType.text;
    List<TextInputFormatter>? formatters = [];

    switch (type) {
      case _FieldType.cedula:
        keyboardType = TextInputType.number;
        formatters = [_CedulaFormatter()];
        break;
      case _FieldType.celular:
        keyboardType = TextInputType.number;
        formatters = [_CelularFormatter()];
        break;
      case _FieldType.soloNumeros:
        keyboardType = TextInputType.number;
        formatters = [FilteringTextInputFormatter.digitsOnly];
        break;
      case _FieldType.soloLetras:
        keyboardType = TextInputType.text;
        formatters = [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
        ];
        break;
    }

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: VectaColors.softBlue, fontSize: 15),
        prefixIcon: Icon(icon, color: VectaColors.secondaryBlue, size: 22),
        prefixText: type == _FieldType.celular ? '+507 ' : null,
        prefixStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : VectaColors.darkBlue,
          fontWeight: FontWeight.bold,
        ),

        suffixIcon: IconButton(
          icon: const Icon(
            Icons.help_outline,
            color: VectaColors.secondaryBlue,
            size: 20,
          ),
          onPressed: () => _mostrarVentanaAyuda(hint.split(' (')[0], ayuda),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VectaColors.softBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: VectaColors.primaryGreen,
            width: 2,
          ),
        ),
      ),
    );
  }

  // crear menús desplegables con icono de ayuda
  Widget _buildDropdownField(
    String hint,
    IconData icon,
    List<String> items,
    String? selectedValue,
    void Function(String?) onChanged,
    String ayuda,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VectaColors.softBlue),
      ),
      child: Stack(
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: VectaColors.softBlue),
              prefixIcon: Icon(icon, color: VectaColors.secondaryBlue),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
            ),
            initialValue: selectedValue,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: VectaColors.secondaryBlue,
            ),
            isExpanded: true,
            items: items
                .map(
                  (String val) => DropdownMenuItem(
                    value: val,
                    child: Text(
                      val,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : VectaColors.darkBlue,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
          Positioned(
            right: 35,
            top: 15,
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: VectaColors.secondaryBlue,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _mostrarVentanaAyuda(hint, ayuda),
            ),
          ),
        ],
      ),
    );
  }

  // crear menú desplegable con búsqueda (DropdownMenu)
  Widget _buildSearchableDropdown(
    String hint,
    IconData icon,
    List<String> items,
    String? selectedValue,
    TextEditingController controller,
    void Function(String?) onChanged,
    String ayuda,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VectaColors.softBlue),
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return DropdownMenu<String>(
                width: constraints.maxWidth,
                controller: controller,
                hintText: hint,
                textStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : VectaColors.darkBlue,
                  overflow: TextOverflow.ellipsis,
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  hintStyle: TextStyle(color: VectaColors.softBlue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                ),
                leadingIcon: Icon(icon, color: VectaColors.secondaryBlue),
                trailingIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: VectaColors.secondaryBlue,
                ),
                enableFilter: true,
                enableSearch: true,
                initialSelection: selectedValue,
                onSelected: onChanged,
                dropdownMenuEntries: items.map<DropdownMenuEntry<String>>((
                  String val,
                ) {
                  return DropdownMenuEntry<String>(
                    value: val,
                    label: val,
                    style: MenuItemButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : VectaColors.darkBlue,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          Positioned(
            right: 35,
            top: 15,
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: VectaColors.secondaryBlue,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _mostrarVentanaAyuda(hint, ayuda),
            ),
          ),
        ],
      ),
    );
  }
}

enum _FieldType { soloLetras, soloNumeros, cedula, celular }

// Formateadores especiales
class _CedulaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String texto = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (texto.length > 12) texto = texto.substring(0);

    String formateado = '';
    for (int i = 0; i < texto.length; i++) {
      formateado += texto[i];
      if (i == 1 || i == 5) {
        if (i != texto.length - 1) {
          formateado += '-';
        }
      }
    }

    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}

class _CelularFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String texto = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (texto.length > 8) texto = texto.substring(0, 8);

    String formateado = '';
    if (texto.length > 4) {
      formateado = '${texto.substring(0, 4)}-${texto.substring(4)}';
    } else {
      formateado = texto;
    }

    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}
