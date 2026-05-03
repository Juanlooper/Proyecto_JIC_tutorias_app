import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Botón de acción principal de la plataforma (Azul Vecta).
/// Integra manejo de estado de carga para bloquear interacciones múltiples.
class VectaButtonPrimary extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool estaCargando;

  const VectaButtonPrimary({
    super.key,
    required this.texto,
    required this.onPressed,
    this.estaCargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        // Si está cargando, pasamos null a onPressed para deshabilitar el botón nativamente
        onPressed: estaCargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primarioAzul,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primarioAzul.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: estaCargando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Botón de acción secundaria de la plataforma (Verde Vecta).
class VectaButtonSecondary extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool estaCargando;

  const VectaButtonSecondary({
    super.key,
    required this.texto,
    required this.onPressed,
    this.estaCargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: estaCargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primarioVerde,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primarioVerde.withValues(
            alpha: 0.6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: estaCargando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
