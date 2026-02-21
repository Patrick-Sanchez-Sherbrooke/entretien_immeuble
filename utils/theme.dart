// // lib/utils/theme.dart
// // ============================================
// // THÈME VISUEL DE L'APPLICATION
// // Couleurs douces et police lisible
// // ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

 class AppTheme {
   // Couleurs principales (douces et non agressives)
   static const Color primaryColor = Color(0xFF5C6BC0);     // Indigo doux
   static const Color primaryLight = Color(0xFF8E99A4);      // Gris bleuté
   static const Color secondaryColor = Color(0xFF26A69A);    // Vert teal doux
   static const Color backgroundColor = Color(0xFFF5F5F5);   // Gris très clair
   static const Color surfaceColor = Colors.white;
   static const Color errorColor = Color(0xFFE57373);        // Rouge doux
   static const Color successColor = Color(0xFF81C784);      // Vert doux
   static const Color warningColor = Color(0xFFFFB74D);      // Orange doux
   static const Color textPrimary = Color(0xFF37474F);       // Gris foncé
   static const Color textSecondary = Color(0xFF78909C);     // Gris moyen
   static const Color archiveColor = Color(0xFFB0BEC5);      // Gris clair

   static ThemeData get lightTheme {
     return ThemeData(
       useMaterial3: true,
       colorScheme: ColorScheme.fromSeed(
         seedColor: primaryColor,
         brightness: Brightness.light,
         surface: surfaceColor,
         error: errorColor,
       ),
       scaffoldBackgroundColor: backgroundColor,
       textTheme: GoogleFonts.nunitoTextTheme().apply(
         bodyColor: textPrimary,
         displayColor: textPrimary,
       ),
       appBarTheme: AppBarTheme(
         backgroundColor: primaryColor,
         foregroundColor: Colors.white,
         elevation: 2,
         centerTitle: true,
         titleTextStyle: GoogleFonts.nunito(
           fontSize: 20,
           fontWeight: FontWeight.w700,
           color: Colors.white,
         ),
       ),
       cardTheme: CardThemeData(
         elevation: 2,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
       ),
       elevatedButtonTheme: ElevatedButtonThemeData(
         style: ElevatedButton.styleFrom(
           backgroundColor: primaryColor,
           foregroundColor: Colors.white,
           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
           textStyle: GoogleFonts.nunito(
             fontSize: 16,
             fontWeight: FontWeight.w600,
           ),
         ),
       ),
       inputDecorationTheme: InputDecorationTheme(
         filled: true,
         fillColor: Colors.white,
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(10),
           borderSide: const BorderSide(color: primaryLight),
         ),
         enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(10),
           borderSide: BorderSide(color: primaryLight.withValues(alpha: 0.5)),
         ),
         focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(10),
           borderSide: const BorderSide(color: primaryColor, width: 2),
         ),
         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
         labelStyle: GoogleFonts.nunito(color: textSecondary),
       ),
       floatingActionButtonTheme: const FloatingActionButtonThemeData(
         backgroundColor: secondaryColor,
         foregroundColor: Colors.white,
         elevation: 4,
       ),
       dividerTheme: DividerThemeData(
         color: primaryLight.withValues(alpha: 0.3),
         thickness: 1,
       ),
       snackBarTheme: SnackBarThemeData(
         behavior: SnackBarBehavior.floating,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       ),
       textSelectionTheme: const TextSelectionThemeData(
         cursorColor: AppTheme.primaryColor,
         selectionColor: Color(0x405C6BC0),
         selectionHandleColor: AppTheme.primaryColor,
       ),
     );
   }
 }