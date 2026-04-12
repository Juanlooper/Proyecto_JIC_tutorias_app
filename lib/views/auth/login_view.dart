import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import 'registro_view.dart';

/// Pantalla Visual Intermedia ("Fase de Ingeniería") para el Inicio de Sesión.
/// Este archivo se ofrece como "Lienzo Base" para que Alejandra sepa qué cajas conectar 
/// cuando elabore el diseño final, y para que Maiky pruebe el salto de páginas funcional 100% puro.
class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Los Controladores: Actúan como aspiradoras que recogen el texto según lo digitan los estudiantes.
  final TextEditingController _controladorCorreo = TextEditingController();
  final TextEditingController _controladorContrasena = TextEditingController();

  /// El cerebro detrás del botón "Iniciar Sesión".
  /// Toma los textos, habla con nuestro Provider, y decide si saltar de pantalla o mostrar alerta roja.
  Future<void> _intentarAccederAlSistema() async {
    // 1. Tomamos el contenido. .trim() corta los "espacios fantasma" finales por si el estudiante pega con error su correo.
    String correoInyectado = _controladorCorreo.text.trim();
    String claveInyectada = _controladorContrasena.text.trim();

    // Barrera local visual: No desgastamos al servidor ni al Provider si está vacío.
    if (correoInyectado.isEmpty || claveInyectada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena tu correo y contraseña primero.')),
      );
      return; 
    }

    // 2. Nos asomamos al Intercomunicador. (.read da la orden disparadora sin pausar la app).
    final motorDeIdentidad = context.read<AutenticacionProvider>();

    // 3. Viajamos al Provider y esperamos firmemente la boleta de respuesta
    bool exitoEntrando = await motorDeIdentidad.ingresarConCorreoYClave(
      correoEscrito: correoInyectado,
      contrasenaEscrita: claveInyectada,
    );

    // Condición divisoria posterior de validación:
    if (exitoEntrando == true) {
      // Triunfo rotundo. Saltamos y destruimos temporalmente esta pantalla login de fondo (pushReplacement).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaHogarTemporal()),
      );
    } else {
      // Fracaso justificado por seguridad. Pedimos cordialmente el texto en "modo Maiky" que nos preparó el backend y lo dibujamos.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            motorDeIdentidad.mensajeDeError,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700, // Rojo intenso de aviso orgánico
          behavior: SnackBarBehavior.floating,  // Pequeña estilización flotante
          duration: const Duration(seconds: 4), 
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escáner en tiempo real (.watch). Si el Provider levanta la bandera "_estaCargando", reconstruimos (setState instantáneo) el visual.
    final semaforoDeCargaEnProceso = context.watch<AutenticacionProvider>().estaCargando;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo ultra limpio minimalista
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono placeholder simple mientras Canva está finalizado
              const Icon(Icons.school_rounded, size: 90, color: Colors.blueAccent),
              const SizedBox(height: 40),

              // Input TextField de Correos
              TextField(
                controller: _controladorCorreo,
                keyboardType: TextInputType.emailAddress,
                enabled: !semaforoDeCargaEnProceso, // Si la máquina procesa, paraliza el teclado
                decoration: const InputDecoration(
                  labelText: 'Correo del alumno/tutor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Input TextField de Contraseñas
              TextField(
                controller: _controladorContrasena,
                obscureText: true, // Transforma texto en "Puntitos" impenetrables a mirones
                enabled: !semaforoDeCargaEnProceso, 
                decoration: const InputDecoration(
                  labelText: 'Contraseña de Acceso',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 35),

              // --- Mecanismo Mutante ---
              // Si el Provider dijo "Espérame que uso internet"... pintamos reloj de arena (Círculo giratorio).
              // Si dijo "Ya acabé" o no a hecho nada... pintamos el Gran Botón azul de "Iniciar".
              if (semaforoDeCargaEnProceso)
                const CircularProgressIndicator(color: Colors.blueAccent)
              else
                SizedBox(
                  width: double.infinity, // Ocupa todo el margen horizontal disponible generosamente
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _intentarAccederAlSistema,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // Color prototipo
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), 
                      ),
                    ),
                    child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),

              const SizedBox(height: 15),

              // Enlace de texto fantasma de pie de la app, muy útil para el onboarding futuro
              TextButton(
                onPressed: semaforoDeCargaEnProceso ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistroView()),
                  );
                }, 
                child: const Text('¿No estás inscrito? Únete aquí', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---- ESQUELETO DE CONFIRMACIÓN (Home Falso) ----
/// Un destino seguro provisional para validar que entramos hasta el final con credenciales y luego permitir devolvernos con un "Cerrar Sesión".
class PantallaHogarTemporal extends StatelessWidget {
  const PantallaHogarTemporal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero Maestro JIC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              // Validamos el cierre de sesión natural y lo retornamos a la pared del login
              await context.read<AutenticacionProvider>().salirDeLaSesionActual();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              '¡Arquitectura Front-End Resuelta!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Has penetrado el sistema de bases de datos.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
