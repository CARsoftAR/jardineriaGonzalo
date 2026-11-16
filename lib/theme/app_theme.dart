import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta cromática "Jardín Vivo y Moderno".
/// Optimizada para visibilidad ergonómica en exteriores bajo luz solar directa
/// y elegancia visual sin estridencias en interiores.
class AppColors {
  // 1. Fondo General (Crema Suave / Gris muy pálido con tinte menta anti-reflejo)
  static const Color background = Color(0xFFF4F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFEBF1ED);

  // 2. Color Principal y Jerarquía (Verde Bosque Vivo)
  static const Color forestGreen = Color(0xFF2E6F40);
  static const Color forestGreenDark = Color(0xFF1B4928);
  static const Color forestGreenLight = Color(0xFF439259);

  // 3. Verde Salvia Tradicional
  static const Color sageGreen = Color(0xFF5B7E62);
  static const Color sageGreenLight = Color(0xFFD6E3D8);

  // 4. Acentos y Chips con Vida (Pasteles Funcionales)
  // Verde Menta Pastel: para abonos activos, estados completados y alarmas
  static const Color mintPastel = Color(0xFFD8F3DC);
  static const Color mintPastelText = Color(0xFF1B4928);

  // Salmón Suave / Terracota Claro: para servicios ocasionales y avisos
  static const Color salmonPastel = Color(0xFFFFE5D9);
  static const Color salmonPastelText = Color(0xFF8B2E0F);

  // Gris claro sutil con acento verde para chips y botones inactivos
  static const Color chipInactive = Color(0xFFEBF1ED);
  static const Color chipInactiveText = Color(0xFF4A5D50);

  // 5. Bordes y Sombras Modernas (Efecto de flotación sobre fondo crema)
  static const Color cardBorder = Color(0xFFE2ECE5);
  static const Color border = Color(0xFFD0DCD2);
  static const Color shadowColor = Color(0x141B4928); // Sombra suave verde bosque

  // 6. Textos con ratio de contraste WCAG AAA/AA para lectura nítida
  static const Color textPrimary = Color(0xFF16251B);
  static const Color textSecondary = Color(0xFF4A5D50);

  // 7. Estados
  static const Color success = Color(0xFF2E6F40);
  static const Color warning = Color(0xFFB06A17);
  static const Color danger = Color(0xFFC93B2B);
}

/// Definición del tema Material 3 de la aplicación con estética moderna "Jardín Vivo".
class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.forestGreen,
        onPrimary: Colors.white,
        secondary: AppColors.sageGreen,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.forestGreen,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        iconTheme: const IconThemeData(color: AppColors.forestGreen),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: AppColors.shadowColor,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.mintPastel,
        elevation: 3,
        shadowColor: AppColors.shadowColor,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.forestGreen,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.forestGreen);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        shadowColor: AppColors.shadowColor,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
