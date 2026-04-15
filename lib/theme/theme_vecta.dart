import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Motor de Temas Centralizado para la identidad visual de VECTA.
// Todas las decisiones de color, tipografía y forma deben originarse aquí.
class ThemeVecta {
  // --- Guia de Colores Oficiales de VECTA ---

  // Color primario verde: usado como secundario en el esquema de colores.
  static const Color primarioVerde = Color(0xFF1CA887);

  // Color primario azul: usado como color principal (primary) en el esquema de colores.
  static const Color primarioAzul = Color(0xFF1951CB);

  // Color de fondo para el modo oscuro de la aplicacion.
  static const Color fondoOscuro = Color(0xFF1E2938);

  // Color de fondo para elementos claros y texto sobre fondos oscuros.
  static const Color fondoClaro = Color(0xFFF8FAFC);

  // Color de texto secundario y placeholders.
  static const Color grisTexto = Color(0xFF8B929A);

  // Variante clara del verde primario para acentos y estados activos.
  static const Color verdeClaro = Color(0xFF8AD1C2);

  // Variante clara del azul primario para titulos de seccion y etiquetas.
  static const Color azulClaro = Color(0xFF89A6E4);

  // --- Colores internos del tema (no expuestos como identidad de marca) ---

  // Color de fondo para las tarjetas (Card) en modo oscuro.
  static const Color _fondoTarjeta = Color(0xFF26323E);

  // Color del borde sutil exterior de las tarjetas.
  static const Color _bordeSubtilTarjeta = Color(0xFF374151);

  // --- Tema Principal: Modo Oscuro ---
  // Este es el unico tema de la aplicacion. Usa Material Design 3.
  static ThemeData get darkTheme {
    // Esquema de colores derivado de los colores primarios de VECTA.
    final ColorScheme esquemaDeColores = ColorScheme.dark(
      primary: primarioAzul,
      secondary: primarioVerde,
      surface: _fondoTarjeta,
      onPrimary: fondoClaro,
      onSecondary: fondoClaro,
      onSurface: fondoClaro,
    );

    // TextTheme con Poppins para titulos y Inter para cuerpo de texto.
    final TextTheme temaDeTexto = TextTheme(
      // Titulos principales de pantalla: Poppins Bold, 28px, color claro.
      headlineLarge: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: fondoClaro,
      ),
      // Titulos de seccion y etiquetas destacadas: Poppins Medium, 18px, azul claro.
      titleMedium: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: azulClaro,
      ),
      // Cuerpo de texto general: Inter Regular, 14px, gris de texto.
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: grisTexto,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: esquemaDeColores,
      scaffoldBackgroundColor: fondoOscuro,
      textTheme: temaDeTexto,

      // Configuracion de la barra de aplicacion: transparente, sin elevacion, titulo centrado.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: fondoClaro,
        ),
        iconTheme: const IconThemeData(color: fondoClaro),
      ),

      // Configuracion de botones primarios: fondo azul, texto blanco, bordes redondeados de 12px.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarioAzul,
          foregroundColor: fondoClaro,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Configuracion de tarjetas: fondo oscuro, bordes redondeados de 16px, borde exterior sutil de 1px.
      cardTheme: CardThemeData(
        color: _fondoTarjeta,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: _bordeSubtilTarjeta,
            width: 1,
          ),
        ),
      ),
    );
  }
}
