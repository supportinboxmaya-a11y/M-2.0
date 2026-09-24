import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart' hide LinearGradient;

import 'package:maya_pro/core/theme/maya_theme.dart';

class MayaAnimations {
  // Breathing Animation (for idle state)
  static Widget breathingLogo({
    required Widget child,
    Duration duration = const Duration(seconds: 3),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOutSine,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      onEnd: () {},
      child: child,
    );
  }

  // Pulsing Glow Animation
  static Widget pulsingGlow({
    required Widget child,
    Color glowColor = MayaTheme.neonCyan,
    Duration duration = const Duration(milliseconds: 1500),
    double minOpacity = 0.3,
    double maxOpacity = 1.0,
    double blurRadius = 30,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: minOpacity, end: maxOpacity),
      duration: duration,
      curve: Curves.easeInOutSine,
      builder: (context, opacity, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(opacity),
                blurRadius: blurRadius,
                spreadRadius: 10,
              ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  // Rotating Gradient Border
  static Widget rotatingBorder({
    required Widget child,
    Duration duration = const Duration(seconds: 4),
    List<Color> colors = const [MayaTheme.neonCyan, MayaTheme.neonViolet, MayaTheme.neonEmerald],
    double borderWidth = 2,
    BorderRadius? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            gradient: SweepGradient(
              colors: colors,
              center: Alignment.center,
              startAngle: 0,
              endAngle: 2 * math.pi,
              tileMode: TileMode.repeated,
            ),
            border: Border.all(
              color: Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: MayaTheme.slate800.withOpacity(0.8),
            ),
            margin: const EdgeInsets.all(2),
            child: child,
          ),
        );
      },
    );
  }

  // Rotating Gradient with Animation
  static Widget rotatingGlowBorder({
    required Widget child,
    Duration duration = const Duration(seconds: 4),
    List<Color> colors = const [MayaTheme.neonCyan, MayaTheme.neonViolet, MayaTheme.neonEmerald],
    double borderWidth = 2,
    BorderRadius? borderRadius,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.linear,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            gradient: SweepGradient(
              colors: colors,
              center: Alignment.center,
              startAngle: value * 2 * math.pi,
              endAngle: value * 2 * math.pi + 2 * math.pi,
            ),
          ),
          padding: EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: MayaTheme.slate800.withOpacity(0.8),
            ),
            child: child,
          ),
        );
      },
      onEnd: () {},
      child: child,
    );
  }

  // Voice Visualizer Waveform
  static Widget voiceWaveform({
    required List<double> amplitudes,
    Color color = MayaTheme.neonCyan,
    double height = 60,
    double barWidth = 4,
    double spacing = 2,
  }) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(amplitudes.length, (index) {
          final amplitude = amplitudes[index].clamp(0.0, 1.0);
          return Container(
            width: barWidth,
            height: height * amplitude,
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(barWidth / 2),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  MayaTheme.neonEmerald,
                  MayaTheme.neonCyan,
                  MayaTheme.neonViolet,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: MayaTheme.neonCyan.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          )
              .animate()
              .scaleY(
                delay: Duration(milliseconds: index * 50),
                duration: Duration(milliseconds: 100),
                curve: Curves.easeOutBack,
              );
        }),
      ),
    );
  }

  // Ripple Effect
  static Widget rippleEffect({
    required Widget child,
    Color color = MayaTheme.neonCyan,
    Duration duration = const Duration(milliseconds: 600),
    double maxRadius = 100,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return CustomPaint(
          painter: _RipplePainter(
            progress: value,
            color: color,
            maxRadius: maxRadius,
          ),
          child: child,
        );
      },
      onEnd: () {},
      child: child,
    );
  }

  // Morphing Shape
  static Widget morphingShape({
    required Widget child,
    Duration duration = const Duration(seconds: 8),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.linear,
      builder: (context, value, child) {
        return ClipPath(
          clipper: _MorphingClipper(progress: value),
          child: child,
        );
      },
      child: child,
    );
  }

  // Typewriter Effect
  static Widget typewriterText({
    required String text,
    Duration duration = const Duration(milliseconds: 30),
    TextStyle? style,
    VoidCallback? onComplete,
  }) {
    return _TypewriterText(
      text: text,
      duration: duration,
      style: style,
      onComplete: onComplete,
    );
  }

  // Shimmer Effect
  static Widget shimmer({
    required Widget child,
    Color baseColor = MayaTheme.slate700,
    Color highlightColor = MayaTheme.neonCyan,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return child.animate(
      effects: [
        ShimmerEffect(
          duration: duration,
          color: highlightColor.withOpacity(0.3),
        ),
      ],
    );
  }

  // Staggered List Animation
  static List<Widget> staggerChildren(
    List<Widget> children, {
    Duration delay = Duration(milliseconds: 100),
    Duration duration = Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
    Offset beginOffset = const Offset(0, 30),
  }) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      return child
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: index * delay.inMilliseconds),
            duration: duration,
            curve: curve,
          )
          .slideY(
            begin: beginOffset.dy / 100,
            delay: Duration(milliseconds: index * delay.inMilliseconds),
            duration: duration,
            curve: curve,
          );
    }).toList();
  }

  // Page Transition
  static PageRouteBuilder pageTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
    Offset beginOffset = const Offset(1, 0),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: beginOffset, end: Offset.zero)
                .chain(CurveTween(curve: curve)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  // Modal Transition
  static PageRouteBuilder modalTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  // Bottom Sheet Transition
  static PageRouteBuilder bottomSheetTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: curve)),
          ),
          child: child,
        );
      },
    );
  }
}

// Custom Painters
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double maxRadius;

  _RipplePainter({
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = maxRadius * progress;
    final opacity = (1 - progress) * 0.5;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _RipplePainter &&
        oldDelegate.progress != progress &&
        oldDelegate.color != color &&
        oldDelegate.maxRadius != maxRadius;
  }
}

class _MorphingClipper extends CustomClipper<Path> {
  final double progress;

  _MorphingClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final radius = 24.0 + 20 * math.sin(progress * 2 * math.pi);

    path.moveTo(radius, 0);
    path.lineTo(w - radius, 0);
    path.quadraticBezierTo(w, 0, w, radius);
    path.lineTo(w, h - radius);
    path.quadraticBezierTo(w, h, w - radius, h);
    path.lineTo(radius, h);
    path.quadraticBezierTo(0, h, 0, h - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return oldClipper is _MorphingClipper && oldClipper.progress != progress;
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle? style;
  final VoidCallback? onComplete;

  const _TypewriterText({
    required this.text,
    required this.duration,
    this.style,
    this.onComplete,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  late Timer _timer;
  String _displayedText = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}

// Extension for stagger
extension StaggerExtension on List<Widget> {
  List<Widget> stagger({
    Duration delay = Duration(milliseconds: 100),
    Duration duration = Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
    Offset beginOffset = const Offset(0, 30),
  }) {
    return MayaAnimations.staggerChildren(
      this,
      delay: delay,
      duration: duration,
      curve: curve,
      beginOffset: beginOffset,
    );
  }
}