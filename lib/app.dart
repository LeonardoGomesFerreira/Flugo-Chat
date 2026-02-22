import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/auth_gate.dart';

class FlugoColors {
  static const primary      = Color(0xFF22C55E);
  static const primaryLight = Color(0xFF4ADE80);
  static const primaryDark  = Color(0xFF16A34A);
  static const dark         = Color(0xFF0F172A);
  static const surface      = Color(0xFF1E293B);
  static const surfaceAlt   = Color(0xFF334155);
  static const chatBg       = Color(0xFF0F172A);
  static const appBar       = Color(0xFF1E293B);
  static const msgMine      = Color(0xFF14532D);
  static const msgOther     = Color(0xFF1E293B);
  static const textPrimary  = Color(0xFFF8FAFC);
  static const textSecond   = Color(0xFF94A3B8);
  static const textHint     = Color(0xFF64748B);
  static const error        = Color(0xFFEF4444);
  static const warning      = Color(0xFFF59E0B);
  static const success      = Color(0xFF22C55E);
  static const onPrimary    = Color(0xFFFFFFFF);
  // Bordas sempre visíveis (não depende de foco)
  static const border       = Color(0x33FFFFFF); // white 20% — sempre visível
  static const borderFocus  = Color(0xFF22C55E);
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.interTextTheme();
    return MaterialApp(
      title: 'Flugo Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: FlugoColors.dark,
        colorScheme: const ColorScheme.dark(
          primary:   FlugoColors.primary,
          secondary: FlugoColors.primaryLight,
          surface:   FlugoColors.surface,
          error:     FlugoColors.error,
          onPrimary: FlugoColors.onPrimary,
          onSurface: FlugoColors.textPrimary,
        ),
        textTheme: base.copyWith(
          bodyLarge:  base.bodyLarge?.copyWith(color: FlugoColors.textPrimary),
          bodyMedium: base.bodyMedium?.copyWith(color: FlugoColors.textPrimary),
          bodySmall:  base.bodySmall?.copyWith(color: FlugoColors.textSecond),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: FlugoColors.appBar,
          foregroundColor: FlugoColors.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FlugoColors.surfaceAlt,
          hintStyle: const TextStyle(color: FlugoColors.textHint),
          prefixIconColor: FlugoColors.textSecond,
          suffixIconColor: FlugoColors.textSecond,
          // ── Bordas SEMPRE visíveis ──
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FlugoColors.border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FlugoColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FlugoColors.borderFocus, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FlugoColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FlugoColors.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: FlugoColors.primary,
            foregroundColor: FlugoColors.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            elevation: 0,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
