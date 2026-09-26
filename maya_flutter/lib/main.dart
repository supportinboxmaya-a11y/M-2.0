import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'core/theme/maya_theme.dart';
import 'core/widgets/maya_logo.dart';
import 'features/voice/voice_service.dart';
import 'features/camera/camera_service.dart';
import 'features/system/system_service.dart';
import 'config/app_config.dart';

final voiceServiceProvider = Provider((ref) => VoiceService());
final cameraServiceProvider = Provider((ref) => CameraService());
final systemServiceProvider = Provider((ref) => SystemService());

void main() {
  runApp(const ProviderScope(child: MayaApp()));
}

class MayaApp extends ConsumerStatefulWidget {
  const MayaApp({super.key});

  @override
  ConsumerState<MayaApp> createState() => _MayaAppState();
}

class _MayaAppState extends ConsumerState<MayaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await ref.read(voiceServiceProvider).initialize();
    await ref.read(cameraServiceProvider).initialize();
    await ref.read(systemServiceProvider).initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(cameraServiceProvider).initialize();
    } else if (state == AppLifecycleState.paused) {
      ref.read(cameraServiceProvider).dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maya Pro',
      debugShowCheckedModeBanner: false,
      theme: MayaTheme.darkTheme,
      home: const MayaHomeScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2)),
          ),
          child: child!,
        );
      },
    );
  }
}

class MayaHomeScreen extends ConsumerStatefulWidget {
  const MayaHomeScreen({super.key});

  @override
  ConsumerState<MayaHomeScreen> createState() => _MayaHomeScreenState();
}

class _MayaHomeScreenState extends ConsumerState<MayaHomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final systemState = ref.watch(systemServiceProvider.stateStream).value;
    final isOnline =
        (ref.watch(systemServiceProvider.connectivityStream).value ?? [])
            .any((r) => r != ConnectivityResult.none);

    return Scaffold(
      backgroundColor: MayaTheme.slate900,
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Main Content
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _HomeScreen(),
              _VoiceScreen(),
              _CameraScreen(),
              _ChatScreen(),
              _SettingsScreen(),
            ],
          ),

          // Floating Maya Logo
          _buildFloatingLogo(),

          // Connection Status Badge
          _buildConnectionBadge(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: MayaTheme.bgGradientPrimary,
      ),
      child: Stack(
        children: [
          // Subtle grid pattern
          CustomPaint(
            painter: _GridPainter(),
            size: Size.infinite,
          ),
          // Radial glow
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MayaTheme.neonCyan.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLogo() {
    return Positioned(
      top: 50,
      right: 20,
      child: const MayaLogo(
        size: 80,
        state: MayaLogoState.idle,
        showPulse: true,
        showGlow: true,
      )
          .animate()
          .fadeIn(duration: 800.ms, delay: 300.ms)
          .slideY(begin: -0.3, duration: 600.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildConnectionBadge() {
    return Consumer(
      builder: (context, ref, _) {
        final connectivity =
            ref.watch(systemServiceProvider.connectivityStream).value ?? [];
        final isOnline = connectivity.any((r) => r != ConnectivityResult.none);

        return Positioned(
          top: 50,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: MayaTheme.glassCard(
              color: MayaTheme.slate800.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? MayaTheme.neonEmerald : MayaTheme.error,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isOnline ? MayaTheme.neonEmerald : MayaTheme.error)
                                .withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Online',
                  style: MayaTheme.labelSmall.copyWith(
                    color: isOnline ? MayaTheme.neonEmerald : MayaTheme.error,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: MayaTheme.glassCard(
        color: MayaTheme.slate900.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: _currentIndex,
                onTap: () => _navigate(0),
              ),
              _NavItem(
                icon: Icons.mic_rounded,
                label: 'Voice',
                index: 1,
                currentIndex: _currentIndex,
                onTap: () => _navigate(1),
              ),
              _NavItem(
                icon: Icons.camera_alt_rounded,
                label: 'Vision',
                index: 2,
                currentIndex: _currentIndex,
                onTap: () => _navigate(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                index: 3,
                currentIndex: _currentIndex,
                onTap: () => _navigate(3),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                index: 4,
                currentIndex: _currentIndex,
                onTap: () => _navigate(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: 400.ms,
      curve: Curves.easeInOutCubic,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final color = isSelected ? MayaTheme.neonCyan : Colors.white54;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? MayaTheme.neonCyan.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? MayaTheme.neonCyan.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? MayaTheme.neonCyan : Colors.white54,
                size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: MayaTheme.labelSmall.copyWith(
                color: isSelected ? MayaTheme.neonCyan : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MayaTheme.neonCyan.withValues(alpha: 0.02)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Screens
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Maya Pro', style: MayaTheme.headlineLarge),
                IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  onPressed: () {},
                  style: IconButton.styleFrom(
                    backgroundColor: MayaTheme.glassWhite10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your autonomous AI assistant',
              style: MayaTheme.bodyMedium,
            ),

            const SizedBox(height: 32),

            // Maya Logo Center
            const Center(
              child: MayaLogo(
                size: 180,
                state: MayaLogoState.idle,
                showPulse: true,
                showGlow: true,
              ),
            ),

            const SizedBox(height: 32),

            // Quick Actions
            const Text('Quick Actions', style: MayaTheme.titleMedium),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _ActionCard(
                  icon: Icons.mic_rounded,
                  label: 'Voice Chat',
                  color: MayaTheme.neonCyan,
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.camera_alt_rounded,
                  label: 'Vision AI',
                  color: MayaTheme.neonViolet,
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  color: MayaTheme.neonEmerald,
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.settings_rounded,
                  label: 'System',
                  color: MayaTheme.neonOrange,
                  onTap: () {},
                ),
              ],
            ),

            const Spacer(),

            // Status Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatusItem(
                      label: 'Voice',
                      value: 'Ready',
                      color: MayaTheme.neonCyan),
                  _StatusItem(
                      label: 'Vision',
                      value: 'Ready',
                      color: MayaTheme.neonViolet),
                  _StatusItem(
                      label: 'System',
                      value: 'Online',
                      color: MayaTheme.neonEmerald),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: MayaTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: MayaTheme.titleMedium.copyWith(color: color)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: MayaTheme.glassCardGlow(
          glowColor: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05)
                  ],
                ),
              ),
              child: Icon(Icons.mic_rounded, color: color, size: 32),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              label,
              style: MayaTheme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: 200.ms)
          .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutCubic),
    );
  }
}

class _VoiceScreen extends ConsumerWidget {
  const _VoiceScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceServiceProvider.stateStream);
    final isRecording = voiceState == VoiceState.recording;
    final isSpeaking = voiceState == VoiceState.speaking;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Voice Control', style: MayaTheme.headlineLarge),
                MayaLogoWidget(size: 48, state: MayaLogoState.idle),
              ],
            ),

            const SizedBox(height: 48),

            // Central Voice Visualizer
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Central Voice Visualizer
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing rings
                        ...List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 500 + index * 200),
                            width: 200 + index * 60,
                            height: 200 + index * 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: MayaTheme.neonCyan
                                    .withValues(alpha: 0.3 - index * 0.08),
                                width: 2,
                              ),
                            ),
                          )
                              .animate(
                                  onPlay: (controller) => controller.repeat())
                              .scale(duration: 2000.ms, curve: Curves.easeInOut)
                              .then()
                              .scale(duration: 2000.ms);
                        }),
                        // Central Logo
                        const MayaLogo(
                          size: 160,
                          state: MayaLogoState.idle,
                          showPulse: true,
                          showGlow: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Status Text
                    Text(
                      'Tap to speak',
                      style:
                          MayaTheme.titleMedium.copyWith(color: Colors.white70),
                    ),

                    const SizedBox(height: 32),

                    // Voice Button
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [MayaTheme.neonCyan, MayaTheme.neonViolet],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.mic_rounded,
                            size: 40,
                            color: MayaTheme.slate900,
                          ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .scale(duration: 1000.ms, curve: Curves.easeInOut),
                    ),

                    const SizedBox(height: 32),

                    // Transcript
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: MayaTheme.glassCard(),
                      child: Text(
                        'Say something...',
                        style: MayaTheme.bodyMedium
                            .copyWith(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          icon: const Icon(Icons.stop_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: MayaTheme.error,
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 24),
                        IconButton.filled(
                          icon: const Icon(Icons.volume_up_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: MayaTheme.neonEmerald,
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 24),
                        IconButton.filled(
                          icon: const Icon(Icons.settings_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: MayaTheme.slate700,
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraScreen extends ConsumerWidget {
  const _CameraScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera Preview
            Consumer(
              builder: (context, ref, _) {
                final cameraService = ref.read(cameraServiceProvider);
                if (!cameraService.isInitialized ||
                    cameraService.controller == null) {
                  return const Center(
                    child: Text('Initializing camera...',
                        style: MayaTheme.bodyMedium),
                  );
                }
                return CameraPreview(cameraService.controller!);
              },
            ),

            // Overlay Grid
            CustomPaint(
              painter: _CameraGridPainter(),
              size: Size.infinite,
            ),

            // Top Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vision AI',
                        style: MayaTheme.headlineMedium
                            .copyWith(color: Colors.white)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.flash_on_rounded),
                          onPressed: () {},
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.cameraswitch_rounded),
                          onPressed: () {},
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.grid_on_rounded),
                          onPressed: () {},
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Controls
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CameraActionButton(
                          icon: Icons.image_rounded,
                          label: 'Gallery',
                          onTap: () {},
                        ),
                        _CameraShutterButton(onPressed: () {}),
                        _CameraActionButton(
                          icon: Icons.flash_on_rounded,
                          label: 'Flash',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Tap to capture • Swipe to zoom',
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CameraActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: MayaTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _CameraShutterButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CameraShutterButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: 100.ms,
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scale(duration: 1000.ms, curve: Curves.easeInOut);
  }
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final spacing = size.width / 3;

    // Rule of thirds grid
    for (int i = 1; i < 3; i++) {
      final x = i * spacing;
      canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = Colors.white12
            ..strokeWidth = 0.5);
    }

    for (int i = 1; i < 3; i++) {
      final y = i * size.height / 3;
      canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = Colors.white12
            ..strokeWidth = 0.5);
    }

    // Center crosshair
    final crosshairPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const crossSize = 30.0;

    canvas.drawLine(
      Offset(centerX - crossSize, centerY),
      Offset(centerX + crossSize, centerY),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - crossSize),
      Offset(centerX, centerY + crossSize),
      crosshairPaint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      30,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white30,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatScreen extends ConsumerWidget {
  const _ChatScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: MayaTheme.neonCyan.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  const Text('Chat', style: MayaTheme.headlineLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {},
                    style: IconButton.styleFrom(
                        backgroundColor: MayaTheme.glassWhite10),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                reverse: true,
                children: [
                  const _ChatBubble(
                    text: 'Hello! How can I help you today?',
                    isUser: false,
                    time: '10:30',
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const _ChatBubble(
                    text: 'Can you help me create a Python script?',
                    isUser: true,
                    time: '10:31',
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                ],
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: MayaTheme.neonCyan.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {},
                    style: IconButton.styleFrom(
                        backgroundColor: MayaTheme.glassWhite10),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_rounded),
                    onPressed: () {},
                    style: IconButton.styleFrom(
                        backgroundColor: MayaTheme.glassWhite10),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_rounded),
                    onPressed: () {},
                    style: IconButton.styleFrom(
                        backgroundColor: MayaTheme.glassWhite10),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: MayaTheme.slate700,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: MayaTheme.neonCyan.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Message Maya...',
                          hintStyle: MayaTheme.bodyMedium
                              .copyWith(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: MayaTheme.bodyMedium,
                        maxLines: null,
                        onSubmitted: (value) {},
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: MayaTheme.neonCyan),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String time;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? MayaTheme.neonCyan : MayaTheme.slate700,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? MayaTheme.neonCyan : MayaTheme.neonViolet)
                  .withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                style: MayaTheme.bodyMedium.copyWith(
                    color: isUser ? MayaTheme.slate900 : Colors.white)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style:
                        MayaTheme.labelSmall.copyWith(color: Colors.white38)),
                const SizedBox(width: 8),
                const Icon(Icons.done_all_rounded,
                    size: 14, color: Colors.white38),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsScreen extends ConsumerWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Settings', style: MayaTheme.headlineLarge),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'Voice',
            children: [
              _SettingsTile(
                title: 'Voice Activation',
                subtitle: 'Enable "Hey Maya" wake word',
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
              _SettingsTile(
                title: 'Voice Speed',
                subtitle: 'Adjust speech rate',
                trailing:
                    Slider(value: 1.0, onChanged: (v) {}, min: 0.5, max: 2.0),
              ),
              _SettingsTile(
                title: 'Voice Selection',
                subtitle: 'Choose TTS voice',
                trailing: DropdownButton<String>(
                  value: 'en-US-AriaNeural',
                  items: [
                    'en-US-AriaNeural',
                    'en-US-GuyNeural',
                    'en-GB-RyanNeural'
                  ]
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Camera & Vision',
            children: [
              _SettingsTile(
                title: 'Auto-analyze Photos',
                subtitle: 'Automatically analyze captured images',
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
              _SettingsTile(
                title: 'OCR Language',
                subtitle: 'Text recognition language',
                trailing: DropdownButton<String>(
                  value: 'eng',
                  items: ['eng', 'spa', 'fra', 'deu', 'chi_sim']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'System Control',
            children: [
              _SettingsTile(
                title: 'Flashlight Control',
                subtitle: 'Allow Maya to control flashlight',
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
              _SettingsTile(
                title: 'Volume Control',
                subtitle: 'Allow Maya to adjust volume',
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
              _SettingsTile(
                title: 'App Launching',
                subtitle: 'Allow Maya to open apps',
                trailing: Switch(value: false, onChanged: (v) {}),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'About',
            children: [
              const _SettingsTile(
                title: 'Version',
                subtitle: '1.0.0 (build 1)',
                trailing: SizedBox(),
              ),
              _SettingsTile(
                title: 'Clear Cache',
                subtitle: 'Remove temporary files',
                trailing:
                    TextButton(onPressed: () {}, child: const Text('Clear')),
              ),
              _SettingsTile(
                title: 'Reset Settings',
                subtitle: 'Restore default settings',
                trailing: TextButton(
                  onPressed: () {},
                  child:
                      const Text('Reset', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: MayaTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          decoration: MayaTheme.glassCard(),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MayaTheme.titleMedium),
                Text(subtitle,
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
