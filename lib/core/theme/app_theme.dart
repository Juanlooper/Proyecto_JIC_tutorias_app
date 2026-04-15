import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central de Diseño Vecta
/// Orquesta la identidad visual de la aplicación según la Guía de Estilos oficial.
class AppTheme {
  // --- Paleta de Colores Oficial ---
  static const Color primarioAzul = Color(0xFF1951CB);
  static const Color primarioVerde = Color(0xFF1CA887);
  static const Color fondoClaro = Color(0xFFF8FAFC);
  static const Color textoOscuro = Color(0xFF1E2938);
  static const Color grisTexto = Color(0xFF8B929A);
  static const Color verdeClaro = Color(0xFF8AD1C2);
  static const Color azulClaro = Color(0xFF89A6E4);

  /// Construye y retorna el tema claro principal de la aplicación.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondoClaro,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarioAzul,
        primary: primarioAzul,
        secondary: primarioVerde,
        surface: Colors.white,
        background: fondoClaro,
      ),
      // Tipografía base: Poppins para títulos, Inter para lectura (legibilidad HCI)
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          color: textoOscuro,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.poppins(
          color: textoOscuro,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: GoogleFonts.inter(color: grisTexto),
      ),
    );
  }
}
