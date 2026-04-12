import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import 'login_view.dart'; // Importamos para tener acceso a PantallaHogarTemporal

/// Pantalla Visual Intermedia ("Fase de Ingeniería") para el Registro de Nuevos Miembros.
/// Este archivo se ofrece como "Lienzo Base" para que Alejandra le aplique la cosmética 
/// fina más adelante, manteniendo la pura funcionalidad de integración con Firebase para Maiky.
class RegistroView extends StatefulWidget {
  const RegistroView({Key? key}) : super(key: key);

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  // Los Controladores: Actúan como aspiradoras que recogen el texto digitado por los futuros estudiantes.
  // Documentación de Mapeo a UsuarioModel:
  // - controladorNombreCompleto.text -> Se enviará a Firebase y se inyectará en el campo 'nombre' del UsuarioModel.
  // - controladorCorreo.text -> Se utilizará formalmente de credencial, mapeando el campo 'correo' del UsuarioModel.
  // - controladorContrasena.text -> Se utilizará estrictamente en Firebase Auth para encriptarla, NUNCA se preservará en Firestore dentro de UsuarioModel por seguridad.
  // - controladorFacultad.text -> Se extraerá e impondrá en la propiedad 'facultad' del UsuarioModel si es otorgada.
  // - controladorCarrera.text -> Se extraerá e impondrá en la propiedad 'carrera' del UsuarioModel si es otorgada.
  
  final TextEditingController _controladorNombreCompleto = TextEditingController();
  final TextEditingController _controladorCorreo = TextEditingController();
  final TextEditingController _controladorContrasena = TextEditingController();
  final TextEditingController _controladorFacultad = TextEditingController();
  final TextEditingController _controladorCarrera = TextEditingController();

  /// El cerebro del botón "Inscribirse en JIC".
  /// Toma los textos filtrados, intercede con el Provider global de Autenticación, y evalúa el fallo/éxito de los registros.
  Future<void> _intentarInscribirseAlSistema() async {
    // 1. Limpiamos cualquier espacio "fantasma" accidental al final de lo digitado (típico error de teclado de celular).
    String nombreInyectado = _controladorNombreCompleto.text.trim();
    String correoInyectado = _controladorCorreo.text.trim();
    String claveInyectada = _controladorContrasena.text.trim();
    String facultadInyectada = _controladorFacultad.text.trim();
    String carreraInyectada = _controladorCarrera.text.trim();

    // Validamos localmente que la trinidad de la identidad básica esté presente
    if (nombreInyectado.isEmpty || correoInyectado.isEmpty || claveInyectada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa tu Nombre, Correo y Contraseña como mínimo para operar.')),
      );
      return; 
    }

    // 2. Apuntamos nuestros binoculares al Intercomunicador central global (.read instruye la solicitud directa).
    final motorDeIdentidad = context.read<AutenticacionProvider>();

    // 3. Empujamos el requerimiento al Firebase y congelamos el hilo a la espera verídica de un dictamen
    bool exitoRegistrando = await motorDeIdentidad.registrarseEnElSistemaGlobal(
      correoEscrito: correoInyectado,
      contrasenaEscrita: claveInyectada,
      nombreEscrito: nombreInyectado,
      facultadElegidaEnMenu: facultadInyectada.isNotEmpty ? facultadInyectada : null,
      carreraElegidaEnMenu: carreraInyectada.isNotEmpty ? carreraInyectada : null,
    );

    // Condición perimetral posterior de validación de estado:
    if (exitoRegistrando == true) {
      // Rotundo triunfo. La fase de registro exitosa genera una autoconexión simultánea a la plataforma (Autologin).
      // Trituramos la página actual de la pila y escoltamos al usuario nuevecito al corazón del sistema (Hogar Temporal).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaHogarTemporal()),
      );
    } else {
      // El Provider chocó contra excepciones de backend (Correo usado previamente, formato roto o contraseña paupérrima).
      // Exhibimos la ira en rojo brillante (Maiky style).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            motorDeIdentidad.mensajeDeError,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating, // Flotante para mejor UX en móviles
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Modo Escáner Constante. Reconstruye su armadura elástica (.watch) si Firebase prende el semáforo indicando retención/cálculos en Nube.
    final semaforoDeCargaEnProceso = context.watch<AutenticacionProvider>().estaCargando;

    return Scaffold(
      backgroundColor: Colors.white, // Coherencia aséptica y diáfana con la LoginView
      appBar: AppBar(
        title: const Text('Inscripción de Estudiantes'),
        backgroundColor: Colors.blueAccent, 
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        // Desbloquea capacidad elástica del lienzo. Indispensable para teclados Android/iOS invasivos de mitad de pantalla.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               // Avatar estático temporal hasta que Alejandra rediseñe a arte Figma
              const Icon(Icons.person_add_alt_1_rounded, size: 70, color: Colors.blueAccent),
              const SizedBox(height: 30),

              // ---- SECCIÓN: FORMULARIO TÉCNICO ----
              
              // Input: Nombres Completos (Mapeo a UsuarioModel: nombre)
              TextField(
                controller: _controladorNombreCompleto,
                keyboardType: TextInputType.name,
                enabled: !semaforoDeCargaEnProceso, // Si el motor central trabaja, el teclado se hiela
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Input: Mail de Credencial (Mapeo a UsuarioModel: correo)
              TextField(
                controller: _controladorCorreo,
                keyboardType: TextInputType.emailAddress,
                enabled: !semaforoDeCargaEnProceso,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Input: Password blindada (Privada, Mapeo: No expuesta en UsuarioModel)
              TextField(
                controller: _controladorContrasena,
                obscureText: true, // Protección de lectura directa implementada
                enabled: !semaforoDeCargaEnProceso,
                decoration: const InputDecoration(
                  labelText: 'Contraseña Nueva',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Input semi-opcional: Bloque de Facultades (Mapeo a UsuarioModel: facultad)
              TextField(
                controller: _controladorFacultad,
                keyboardType: TextInputType.text,
                enabled: !semaforoDeCargaEnProceso,
                decoration: const InputDecoration(
                  labelText: 'Facultad (Ej: FIE, FISC)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Input semi-opcional: Plan Vocacional (Mapeo a UsuarioModel: carrera)
              TextField(
                controller: _controladorCarrera,
                keyboardType: TextInputType.text,
                enabled: !semaforoDeCargaEnProceso,
                decoration: const InputDecoration(
                  labelText: 'Carrera / Licenciatura',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
              ),
              const SizedBox(height: 35),

              // ---- SECCIÓN: REACCIONES Y MUTACIONES DE BOTONES ----
              
              // Modificador Condicional de Estados UI.
              if (semaforoDeCargaEnProceso)
                const CircularProgressIndicator(color: Colors.blueAccent)
              else
                SizedBox(
                  width: double.infinity, // Máxima extensión de columnas para ser un Target Touch amigable
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _intentarInscribirseAlSistema,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), 
                      ),
                    ),
                    child: const Text('Completar Inscripción', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                
              const SizedBox(height: 15),

              // Botón de retracto rápido. Un Pop() simple porque sabemos que LoginView nos originó abajo.
              TextButton(
                onPressed: semaforoDeCargaEnProceso ? null : () => Navigator.pop(context), 
                child: const Text('¿Ya tienes cuenta? Vuelve al Login', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
