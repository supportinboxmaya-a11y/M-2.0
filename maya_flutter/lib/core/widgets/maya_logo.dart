import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart' hide LinearGradient;

import '../theme/maya_theme.dart';
import '../animations/maya_animations.dart';
import 'package:flutter/services.dart';

class MayaLogo extends StatefulWidget {
  final double size;
  final MayaLogoState state;
  final VoidCallback? onTap;
  final bool showPulse;
  final bool showRotation;
  final bool showGlow;
  final Duration pulseDuration;
  final Duration rotationDuration;

  const MayaLogo({
    super.key,
    this.size = 120,
    this.state = MayaLogoState.idle,
    this.onTap,
    this.showPulse = true,
    this.showRotation = false,
    this.showGlow = true,
    this.pulseDuration = const Duration(milliseconds: 1500),
    this.rotationDuration = const Duration(seconds: 4),
  });

  @override
  State<MayaLogo> createState() => _MayaLogoState();
}

enum MayaLogoState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class _MayaLogoState extends State<MayaLogo> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _breathingController;
  late AnimationController _morphController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: widget.rotationDuration,
      vsync: this,
    )..repeat();

    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _morphController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant MayaLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimationsForState(widget.state);
    }
  }

  void _updateAnimationsForState(MayaLogoState state) {
    switch (state) {
      case MayaLogoState.idle:
        _pulseController.duration = const Duration(milliseconds: 1500);
        _pulseController.repeat(reverse: true);
        _rotationController.stop();
        _rotationController.reset();
        break;
      case MayaLogoState.listening:
        _pulseController.duration = const Duration(milliseconds: 800);
        _pulseController.repeat(reverse: true);
        _rotationController.repeat(reverse: false);
        break;
      case MayaLogoState.processing:
        _pulseController.stop();
        _pulseController.value = 1;
        _rotationController.duration = const Duration(seconds: 2);
        _rotationController.repeat();
        break;
      case MayaLogoState.speaking:
        _pulseController.duration = const Duration(milliseconds: 500);
        _pulseController.repeat(reverse: true);
        _rotationController.stop();
        break;
      case MayaLogoState.error:
        _pulseController.duration = const Duration(milliseconds: 200);
        _pulseController.repeat(reverse: true);
        _rotationController.stop();
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _breathingController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  Color _getGlowColor() {
    switch (widget.state) {
      case MayaLogoState.idle:
        return MayaTheme.neonCyan;
      case MayaLogoState.listening:
        return MayaTheme.neonEmerald;
      case MayaLogoState.processing:
        return MayaTheme.neonViolet;
      case MayaLogoState.speaking:
        return MayaTheme.neonCyan;
      case MayaLogoState.error:
        return MayaTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _getGlowColor();

    Widget logo = CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _MayaLogoPainter(
        progress: widget.state == MayaLogoState.processing ? 1.0 : 0,
        glowColor: widget.showGlow ? _getGlowColor() : Colors.transparent,
        rotation: widget.showRotation ? 1.0 : 0,
      ),
      child: Center(
        child: _buildMLogo(),
      ),
    );

    if (widget.showGlow) {
      logo = MayaAnimations.pulsingGlow(
        duration: const Duration(milliseconds: 1500),
        glowColor: _getGlowColor(),
        child: logo,
      );
    }

    if (widget.showRotation) {
      logo = MayaAnimations.rotatingGlowBorder(
        duration: const Duration(seconds: 4),
        child: Padding(padding: const EdgeInsets.all(2), child: logo),
      );
    }

    if (widget.onTap != null) {
      logo = GestureDetector(
        onTap: widget.onTap,
        child: logo,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      child: widget.state == MayaLogoState.processing
          ? logo
              .animate()
              .rotate(
                duration: const Duration(seconds: 2),
                curve: Curves.linear,
              )
              .then()
              .shimmer(
                duration: 1000.ms,
                color: MayaTheme.neonViolet.withOpacity(0.3),
              )
          : logo
              .animate()
              .scale(
                duration: 300.ms,
                curve: Curves.easeOutBack,
              )
              .shimmer(duration: 2000.ms),
    );
  }

  Widget _buildMLogo() {
    return CustomPaint(
      size: Size(widget.size * 0.8, widget.size * 0.8),
      painter: _MLetterPainter(),
    );
  }
}

class _MayaLogoPainter extends CustomPainter {
  final double progress;
  final Color glowColor;
  final double rotation;

  const _MayaLogoPainter({
    required this.progress,
    required this.glowColor,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer glow
    if (glowColor != Colors.transparent) {
      final glowPaint = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(center, radius, glowPaint);
    }

    // Draw rotating ring
    final ringPaint = Paint()
      ..color = MayaTheme.neonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = progress * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      rotation * 2 * 3.14159,
      sweepAngle,
      false,
      ringPaint,
    );

    // Center dot
    final dotPaint = Paint()..color = MayaTheme.neonEmerald;
    canvas.drawCircle(center, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _MayaLogoPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.glowColor != glowColor ||
            oldDelegate.rotation != rotation);
  }
}

class _MLetterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final gradient = LinearGradient(
      colors: [
        MayaTheme.neonCyan,
        MayaTheme.neonViolet,
        MayaTheme.neonEmerald,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, 100, 100),
    );

    final w = 100.0;
    final h = 100.0;
    final strokeWidth = 6.0;

    final path = Path()
      ..moveTo(10, 90)
      ..lineTo(10, 10)
      ..lineTo(50, 50)
      ..lineTo(90, 10)
      ..lineTo(90, 90);

    canvas.drawPath(path, paint);

    // Center dot
    final dotPaint = Paint()
      ..color = MayaTheme.neonEmerald
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(50, 50), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MayaLogoWidget extends StatelessWidget {
  final double size;
  final MayaLogoState state;
  final VoidCallback? onTap;
  final bool showPulse;
  final bool showGlow;

  const MayaLogoWidget({
    super.key,
    this.size = 80,
    this.state = MayaLogoState.idle,
    this.onTap,
    this.showPulse = true,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return MayaLogo(
      size: size,
      state: state,
      onTap: onTap,
      showPulse: showPulse,
      showGlow: showGlow,
    );
  }
}

// Animated M Logo with Rive (optional)
class RiveMayaLogo extends StatefulWidget {
  final double size;
  final MayaLogoState state;
  final VoidCallback? onTap;

  const RiveMayaLogo({
    super.key,
    this.size = 120,
    this.state = MayaLogoState.idle,
    this.onTap,
  });

  @override
  State<RiveMayaLogo> createState() => _RiveMayaLogoState();
}

class _RiveMayaLogoState extends State<RiveMayaLogo> {
  Artboard? _artboard;
  SMIBool? _isListening;
  SMIBool? _isProcessing;
  SMIBool? _isSpeaking;
  SMITrigger? _errorTrigger;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    try {
      final data = await rootBundle.load('assets/animations/maya_logo.riv');
      final file = RiveFile.import(data);
      final artboard = file.mainArtboard;

      // Add state machine
      final controller = StateMachineController.fromArtboard(
        artboard,
        'MayaLogoSM',
        onStateChange: (name, isActive) {
          // Handle state changes if needed
        },
      );

      if (controller != null) {
        artboard.addController(controller);
        _isListening = controller.findInput<bool>('isListening') as SMIBool?;
        _isProcessing = controller.findInput<bool>('isProcessing') as SMIBool?;
        _isSpeaking = controller.findInput<bool>('isSpeaking') as SMIBool?;
        _errorTrigger = controller.findInput<bool>('error') as SMITrigger?;

        _updateRiveState();
      }

      setState(() {
        _artboard = artboard;
      });
    } catch (e) {
      debugPrint('Failed to load Rive animation: $e');
    }
  }

  void _updateRiveState() {
    if (_isListening != null) {
      _isListening!.value = widget.state == MayaLogoState.listening;
    }
    if (_isProcessing != null) {
      _isProcessing!.value = widget.state == MayaLogoState.processing;
    }
    if (_isSpeaking != null) {
      _isSpeaking!.value = widget.state == MayaLogoState.speaking;
    }
    if (widget.state == MayaLogoState.error && _errorTrigger != null) {
      _errorTrigger!.fire();
    }
  }

  @override
  void didUpdateWidget(covariant RiveMayaLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateRiveState();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_artboard == null) {
      return MayaLogoWidget(
        size: widget.size,
        state: widget.state,
        onTap: widget.onTap,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Rive(artboard: _artboard!),
      ),
    );
  }
}
