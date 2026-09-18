import 'package:flutter/material.dart';

class CoresFolhio {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF101412);
  static const surfaceSoft = Color(0xFF171C19);
  static const input = Color(0xFF0C0F0E);
  static const border = Color(0x1FFFFFFF);
  static const borderSoft = Color(0x14FFFFFF);
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFFC1CBC6);
  static const dim = Color(0xFF68736E);
  static const green = Color(0xFF32D583);
  static const greenSoft = Color(0x1F32D583);
  static const greenDeep = Color(0xFF073D2D);
  static const cream = Color(0xFFF3EFE2);
  static const orange = Color(0xFFE98B2A);
  static const blue = Color(0xFF58A7FF);
  static const violet = Color(0xFF8F86FF);
  static const coral = Color(0xFFFF765D);
  static const pink = Color(0xFFFF5CA8);
}

@immutable
class CoresTemaFolhio extends ThemeExtension<CoresTemaFolhio> {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color input;
  final Color text;
  final Color muted;
  final Color dim;
  final Color border;
  final Color borderSoft;
  final Color onAccent;

  const CoresTemaFolhio({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.input,
    required this.text,
    required this.muted,
    required this.dim,
    required this.border,
    required this.borderSoft,
    required this.onAccent,
  });

  @override
  CoresTemaFolhio copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? surfaceSoft,
    Color? input,
    Color? text,
    Color? muted,
    Color? dim,
    Color? border,
    Color? borderSoft,
    Color? onAccent,
  }) {
    return CoresTemaFolhio(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      input: input ?? this.input,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      dim: dim ?? this.dim,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  CoresTemaFolhio lerp(ThemeExtension<CoresTemaFolhio>? other, double t) {
    if (other is! CoresTemaFolhio) return this;
    return CoresTemaFolhio(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      input: Color.lerp(input, other.input, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      dim: Color.lerp(dim, other.dim, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

extension ContextoTemaFolhio on BuildContext {
  CoresTemaFolhio get folhioColors =>
      Theme.of(this).extension<CoresTemaFolhio>()!;
}

class EstiloFolhio {
  const EstiloFolhio._();

  static const pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 24);
  static const cardPadding = EdgeInsets.all(16);
  static const cardRadius = 16.0;
  static const buttonRadius = 8.0;
  static const buttonHeight = 46.0;
  static const toolbarHeight = 52.0;
  static const navigationIconSize = 25.0;
  static const navigationFontSize = 11.0;

  static ThemeData tema({
    Brightness brightness = Brightness.dark,
    Color accentColor = CoresFolhio.green,
    bool highContrast = false,
  }) {
    final isDark = brightness == Brightness.dark;
    const brandPrimary = CoresFolhio.green;
    const secondary = CoresFolhio.green;
    final background = highContrast
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? CoresFolhio.background : Colors.white);
    final surface = highContrast
        ? (isDark ? const Color(0xFF050505) : Colors.white)
        : (isDark ? CoresFolhio.surface : Colors.white);
    final surfaceSoft = highContrast
        ? (isDark ? const Color(0xFF0B0B0B) : Colors.white)
        : (isDark ? CoresFolhio.surfaceSoft : Colors.white);
    final input = highContrast
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? CoresFolhio.input : Colors.white);
    final text = isDark ? CoresFolhio.text : Colors.black;
    final muted = highContrast ? text : (isDark ? CoresFolhio.muted : text);
    final dim = highContrast ? text : (isDark ? CoresFolhio.dim : text);
    final border = highContrast
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? CoresFolhio.border : const Color(0x33000000));
    final borderSoft = highContrast
        ? (isDark ? Colors.white70 : Colors.black87)
        : (isDark ? CoresFolhio.borderSoft : const Color(0x1F000000));
    final onAccent =
        ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark
        ? Colors.white
        : CoresFolhio.greenDeep;
    final onBrandPrimary =
        ThemeData.estimateBrightnessForColor(brandPrimary) == Brightness.dark
        ? Colors.white
        : CoresFolhio.greenDeep;
    final folhioColors = CoresTemaFolhio(
      primary: brandPrimary,
      secondary: secondary,
      background: background,
      surface: surface,
      surfaceSoft: surfaceSoft,
      input: input,
      text: text,
      muted: muted,
      dim: dim,
      border: border,
      borderSoft: borderSoft,
      onAccent: onAccent,
    );

    final titleStyle = TextStyle(
      fontFamily: 'Poppins',
      color: text,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = TextStyle(
      fontFamily: 'Inter',
      color: text,
      fontWeight: FontWeight.w400,
    );
    final actionStyle = TextStyle(
      fontFamily: 'Inter',
      color: text,
      fontWeight: FontWeight.w600,
    );
    const buttonHeight = 46.0;
    const buttonTextSize = 15.0;

    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: brandPrimary,
            brightness: brightness,
          ).copyWith(
            primary: brandPrimary,
            secondary: secondary,
            surface: surface,
            surfaceContainerHighest: surface,
            onSurface: text,
            error: CoresFolhio.coral,
          ),
      extensions: [folhioColors],
      textTheme: TextTheme(
        headlineSmall: titleStyle.copyWith(fontSize: 24),
        titleLarge: titleStyle.copyWith(fontSize: 22),
        titleMedium: titleStyle.copyWith(fontSize: 16),
        titleSmall: titleStyle.copyWith(fontSize: 14),
        bodyLarge: bodyStyle.copyWith(fontSize: 15),
        bodyMedium: bodyStyle.copyWith(fontSize: 14),
        bodySmall: bodyStyle.copyWith(fontSize: 12, color: muted),
        labelLarge: actionStyle.copyWith(fontSize: 15),
        labelMedium: actionStyle.copyWith(fontSize: 12),
        labelSmall: actionStyle.copyWith(fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 52,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: highContrast
            ? background
            : Color.alphaBlend(accentColor.withValues(alpha: 0.06), background),
        selectedItemColor: accentColor,
        unselectedItemColor: muted,
        selectedIconTheme: const IconThemeData(size: 27),
        unselectedIconTheme: const IconThemeData(size: 24),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: titleStyle.copyWith(fontSize: 20),
        contentTextStyle: bodyStyle.copyWith(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        textStyle: bodyStyle.copyWith(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: bodyStyle.copyWith(fontSize: 14),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: input,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: onBrandPrimary,
          minimumSize: Size(48, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: actionStyle.copyWith(fontSize: buttonTextSize),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          minimumSize: Size(48, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: actionStyle.copyWith(fontSize: buttonTextSize),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceSoft,
        contentTextStyle: bodyStyle.copyWith(color: text, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: borderSoft, thickness: 1, space: 1),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: brandPrimary),
      ),
      iconTheme: IconThemeData(color: text),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: accentColor.withValues(
          alpha: highContrast ? 0.30 : 0.16,
        ),
        checkmarkColor: accentColor,
        side: BorderSide(color: borderSoft),
        labelStyle: bodyStyle.copyWith(color: text, fontSize: 13),
        secondaryLabelStyle: bodyStyle.copyWith(color: text, fontSize: 13),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? onAccent : muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? accentColor
              : borderSoft;
        }),
        trackOutlineColor: WidgetStateProperty.all(
          highContrast ? border : Colors.transparent,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? accentColor
              : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onAccent),
        side: BorderSide(color: border, width: highContrast ? 2 : 1),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? accentColor : muted;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accentColor),
    );
  }
}
