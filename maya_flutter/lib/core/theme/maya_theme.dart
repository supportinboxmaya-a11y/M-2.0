import 'package:flutter/material.dart';

class MayaTheme {
  // Core Colors - Deep Slate Base
  static const Color slate900 = Color(0xFF0B0F19);
  static const Color slate800 = Color(0xFF121826);
  static const Color slate700 = Color(0xFF1E2A3A);
  static const Color slate600 = Color(0xFF2D3A4F);

  // Neon Accents
  static const Color neonCyan = Color(0xFF00F2FE);
  static const Color neonViolet = Color(0xFF4FACFE);
  static const Color neonEmerald = Color(0xFF00FF87);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color neonGold = Color(0xFFFFD700);

  // Semantic Colors
  static const Color success = neonEmerald;
  static const Color warning = neonOrange;
  static const Color error = Color(0xFFFF3366);
  static const Color info = neonCyan;

  // Glassmorphism Colors
  static const Color glassWhite10 = Color(0x1AFFFFFF);
  static const Color glassWhite20 = Color(0x33FFFFFF);
  static const Color glassWhite30 = Color(0x4DFFFFFF);
  static const Color glassBlack10 = Color(0x1A000000);
  static const Color glassBlack20 = Color(0x33000000);
  static const Color glassBlack30 = Color(0x4D000000);

  // Border Gradients
  static const LinearGradient borderGradientCyan = LinearGradient(
    colors: [neonCyan, neonViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient borderGradientEmerald = LinearGradient(
    colors: [neonEmerald, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient borderGradientPink = LinearGradient(
    colors: [neonPink, neonViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background Gradients
  static const LinearGradient bgGradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B0F19),
      Color(0xFF121826),
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient bgGradientVoice = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F0F1A),
      Color(0xFF1A0A2E),
      Color(0xFF0D0D2B),
    ],
  );

  static const LinearGradient bgGradientCamera = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A1A2F),
      Color(0xFF0D2B3E),
      Color(0xFF0F1A2E),
    ],
  );

  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.white60,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white54,
    letterSpacing: 0.3,
  );

  static const TextStyle codeStyle = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF00FF87),
    height: 1.5,
  );

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'SpaceGrotesk',
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonViolet,
        tertiary: neonEmerald,
        surface: slate800,
        surfaceContainerHighest: slate700,
        surfaceContainerHigh: slate700,
        surfaceContainer: slate800,
        surfaceContainerLow: slate900,
        surfaceContainerLowest: slate900,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        outline: Color(0x3300F2FE),
        outlineVariant: Color(0x1A00F2FE),
        error: error,
        onError: Colors.white,
        onErrorContainer: Color(0xFF330011),
      ),
      scaffoldBackgroundColor: slate900,
      canvasColor: slate800,
      cardColor: slate800,
      dividerColor: const Color(0x1A00F2FE),
      dividerTheme: const DividerThemeData(
        color: Color(0x1A00F2FE),
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: headlineLarge,
        displayMedium: headlineMedium,
        displaySmall: headlineSmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: titleLarge,
        iconTheme: IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
      ),
      cardTheme: CardThemeData(
        color: slate800.withValues(alpha: 0.8),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: neonCyan.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: slate900,
          elevation: 0,
          shadowColor: neonCyan.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(88, 48),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.pressed)) {
                return neonCyan.withValues(alpha: 0.8);
              }
              if (states.contains(WidgetState.hovered)) {
                return neonCyan.withValues(alpha: 0.9);
              }
              return null;
            },
          ),
        ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonCyan,
          side: const BorderSide(color: neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(88, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonCyan,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate700.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonCyan.withValues(alpha: 0.3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonCyan.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF3366), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF3366), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        labelStyle: bodyMedium.copyWith(color: Colors.white54),
        hintStyle: bodyMedium.copyWith(color: Colors.white30),
        floatingLabelStyle: labelMedium.copyWith(color: neonCyan),
        errorStyle: bodySmall.copyWith(color: const Color(0xFFFF3366)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: slate800.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shadowColor: neonCyan.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonCyan.withValues(alpha: 0.2), width: 1),
        ),
        titleTextStyle: titleLarge,
        contentTextStyle: bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: slate800,
        elevation: 24,
        shadowColor: neonCyan.withValues(alpha: 0.1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalBackgroundColor: slate800,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: slate900,
        elevation: 16,
        selectedItemColor: neonCyan,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: labelSmall,
        unselectedLabelStyle: labelSmall,
        type: BottomNavigationBarType.fixed,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: neonCyan,
        unselectedLabelColor: Colors.white38,
        indicatorColor: neonCyan,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: labelLarge,
        unselectedLabelStyle: labelMedium,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.pressed)) {
              return neonCyan.withValues(alpha: 0.1);
            }
            return null;
          },
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slate700.withValues(alpha: 0.5),
        selectedColor: neonCyan.withValues(alpha: 0.2),
        disabledColor: Colors.white10,
        labelStyle: labelMedium,
        secondaryLabelStyle: labelMedium.copyWith(color: slate900),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonCyan.withValues(alpha: 0.2)),
        ),
        side: BorderSide(color: neonCyan.withValues(alpha: 0.2)),
        brightness: Brightness.dark,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: neonCyan,
        foregroundColor: slate900,
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 12,
        highlightElevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: slate900,
        elevation: 16,
        indicatorColor: neonCyan.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return labelMedium.copyWith(color: neonCyan);
            }
            return labelSmall.copyWith(color: Colors.white38);
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: neonCyan, size: 24);
            }
            return const IconThemeData(color: Colors.white38, size: 24);
          },
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: neonCyan,
        linearTrackColor: slate700,
        circularTrackColor: slate700,
        refreshBackgroundColor: slate800,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: neonCyan,
        inactiveTrackColor: neonCyan.withValues(alpha: 0.2),
        thumbColor: neonCyan,
        overlayColor: neonCyan.withValues(alpha: 0.1),
        valueIndicatorColor: neonCyan,
        valueIndicatorTextStyle: labelSmall.copyWith(color: slate900),
        activeTickMarkColor: neonCyan,
        inactiveTickMarkColor: Colors.white24,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return neonCyan;
            }
            return Colors.white38;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return neonCyan.withValues(alpha: 0.3);
            }
            return Colors.white10;
          },
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return neonCyan;
            }
            return neonCyan.withValues(alpha: 0.2);
          },
        ),
        thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const Icon(Icons.check, size: 18, color: Color(0xFF0B0F19));
            }
            return null;
          },
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return neonCyan;
            }
            return Colors.transparent;
          },
        ),
        checkColor: WidgetStateProperty.all(const Color(0xFF0B0F19)),
        side: BorderSide(color: neonCyan.withValues(alpha: 0.4), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        shapeRadius: 4,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return neonCyan;
            }
            return Colors.white10;
          },
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: slate800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: neonCyan.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: neonCyan.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        textStyle: bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        verticalOffset: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: slate800,
        elevation: 12,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: neonCyan.withValues(alpha: 0.3)),
        ),
        contentTextStyle: bodyMedium,
        actionTextColor: neonEmerald,
        actionOverflowThreshold: 0.5,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1A00F2FE),
        thickness: 1,
        space: 1,
        indent: 16,
        endIndent: 16,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: neonCyan,
        size: 24,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.hovered)) {
                return neonCyan.withValues(alpha: 0.1);
              }
              if (states.contains(WidgetState.pressed)) {
                return neonCyan.withValues(alpha: 0.2);
              }
              return null;
            },
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(slate800.withValues(alpha: 0.95)),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(16),
          shadowColor: WidgetStateProperty.all(neonCyan.withValues(alpha: 0.1)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: neonCyan.withValues(alpha: 0.2)),
            ),
          ),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 8)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: slate800.withValues(alpha: 0.95),
        elevation: 16,
        shadowColor: neonCyan.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: neonCyan.withValues(alpha: 0.2)),
        ),
        textStyle: bodyMedium,
        labelTextStyle: WidgetStateProperty.all(labelMedium),
        enableFeedback: true,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: slate700.withValues(alpha: 0.3),
        collapsedBackgroundColor: Colors.transparent,
        textColor: Colors.white,
        collapsedTextColor: Colors.white70,
        iconColor: neonCyan,
        collapsedIconColor: Colors.white54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: neonCyan.withValues(alpha: 0.1)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: neonCyan.withValues(alpha: 0.1)),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: neonCyan.withValues(alpha: 0.1),
        selectedColor: neonCyan,
        iconColor: Colors.white70,
        textColor: Colors.white,
        titleTextStyle: titleMedium,
        subtitleTextStyle: bodyMedium,
        leadingAndTrailingTextStyle: bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // Glassmorphism Decorations
  static BoxDecoration glassCard({
    double blur = 20,
    double opacity = 0.1,
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white.withValues(alpha: opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: blur,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: neonCyan.withValues(alpha: 0.05),
              blurRadius: blur / 2,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  static BoxDecoration glassCardGlow({
    double blur = 30,
    Color glowColor = neonCyan,
    double opacity = 0.15,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: glowColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: opacity),
          blurRadius: blur,
          spreadRadius: 5,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: blur,
          spreadRadius: -5,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration neonBorder({
    Color color = neonCyan,
    double width = 1.5,
    double radius = 16,
    double glowOpacity = 0.3,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color, width: width),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: glowOpacity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static LinearGradient neonGradient({
    List<Color> colors = const [neonCyan, neonViolet],
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
    );
  }

  static LinearGradient textGradient({
    List<Color> colors = const [neonCyan, neonViolet, neonEmerald],
  }) {
    return LinearGradient(
      colors: colors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }
}