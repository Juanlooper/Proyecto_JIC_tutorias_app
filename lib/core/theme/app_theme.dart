import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores extraídos de la Guía de Estilos de Vecta
  static const Color verdeVecta = Color(0xFF1CA887);
  static const Color azulVecta = Color(0xFF1951CB);
  static const Color fondoClaro = Color(0xFFF8FAFC);
  static const Color textoOscuro = Color(0xFF1E2938);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondoClaro,
      colorScheme: ColorScheme.fromSeed(
        seedColor: verdeVecta,
        primary: verdeVecta,
        secondary: azulVecta,
        surface: fondoClaro,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        titleLarge: GoogleFonts.poppins(
          color: textoOscuro,
          fontWeight: FontWeight.bold,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: verdeVecta,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B929A)),
        ),
      ),
    );
  }
}
