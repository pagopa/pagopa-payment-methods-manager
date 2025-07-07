// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Colori primari ispirati allo screenshot
  static const Color primaryColor = Color(0xFF0073E6); // Blu PagoPA
  static const Color backgroundColor = Color(0xFFF5F7FA); // Grigio chiaro di sfondo
  static const Color cardColor = Colors.white;
  static const Color fontColor = Color(0xFF333333); // Grigio scuro per il testo
  static const Color fontColorSecondary = Color(0xFF666666); // Grigio più chiaro
  static const Color successColor = Color(0xFF28A745); // Verde per lo stato "abilitato"

  static ThemeData get theme {
    return ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: 'Roboto', // Puoi scegliere un font sans-serif pulito

        // Definisce lo schema di colori principale
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: primaryColor,
          background: backgroundColor,
          surface: cardColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: fontColor,
          onSurface: fontColor,
          error: Colors.redAccent,
        ),

        // Stile del testo
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: fontColor, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: fontColor, fontWeight: FontWeight.bold, fontSize: 18),
          bodyLarge: TextStyle(color: fontColor),
          bodyMedium: TextStyle(color: fontColorSecondary),
        ),

        // Stile dell'AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: cardColor,
          elevation: 1,
          surfaceTintColor: Colors.transparent, // Rimuove tinta M3
          iconTheme: IconThemeData(color: fontColor),
          titleTextStyle: TextStyle(
            color: fontColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Stile dei bottoni
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // Stile per i campi di input (MOLTO IMPORTANTE)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          floatingLabelBehavior: FloatingLabelBehavior.always, // Etichetta sempre sopra
          labelStyle: const TextStyle(color: fontColorSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),

        // Stile delle Card
        cardTheme: CardTheme(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        // Stile per i Chip (status pill)
        chipTheme: ChipThemeData(
          backgroundColor: successColor.withOpacity(0.1),
          labelStyle: const TextStyle(color: successColor, fontWeight: FontWeight.bold),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        )
    );
  }
}