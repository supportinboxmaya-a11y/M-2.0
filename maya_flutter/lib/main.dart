import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'core/theme/maya_theme.dart';
import 'core/widgets/maya_logo.dart';
import 'core/services/api_service.dart';
import 'features/voice/voice_service.dart';
import 'features/camera/camera_service.dart';
import 'features/system/system_service.dart';
import 'features/system/health_service.dart';

final voiceServiceProvider = Provider((ref) => VoiceService(ref.read(apiServiceProvider)));
final cameraServiceProvider = Provider((ref) => CameraService(ref.read(apiServiceProvider)));
final systemServiceProvider = Provider((ref) => SystemService(ref.read(apiServiceProvider)));
// Health status stream provider - polls every 30 seconds
final healthStreamProvider = StreamProvider<HealthStatus>((ref) {
  final service = ref.watch(healthServiceProvider);
  return service.watchHealth(interval: const Duration(seconds: 30));
});

// StreamProviders to watch service streams as AsyncValue
final systemStateStreamProvider = StreamProvider<SystemState>((ref) {
  final service = ref.watch(systemServiceProvider);
  return service.stateStream;
});

final systemConnectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final service = ref.watch(systemServiceProvider);
  return service.connectivityStream;
});

final voiceStateStreamProvider = StreamProvider<VoiceState>((ref) {
  final service = ref.watch(voiceServiceProvider);
  return service.stateStream;
});

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
  ConsumerState<MayaHomeScreen> createState() => _HomeScreenState();
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
class _HomeScreen extends ConsumerStatefulWidget {
  const _HomeScreen();

  @override
  ConsumerState<MayaHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<MayaHomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Voice state management
  MayaLogoState _orbState = MayaLogoState.idle;
  bool _isVoiceMode = true;
  bool _isListening = false;
  bool _speakerOn = true;
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();
      ref.read(chatMessagesProvider.notifier).sendMessage(text);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _orbState = MayaLogoState.listening;
        _pulseController.duration = const Duration(milliseconds: 800);
        _pulseController.repeat(reverse: true);
      } else {
        _orbState = MayaLogoState.idle;
        _pulseController.duration = const Duration(milliseconds: 1500);
        _pulseController.repeat(reverse: true);
      }
    }
    // TODO: Start/stop STT
  }

  void _toggleSpeaker() {
    setState(() {
      _speakerOn = !_speakerOn;
    });
  }

  void _setOrbState(MayaLogoState state) {
    setState(() {
      _orbState = state;
      switch (state) {
        case MayaLogoState.idle:
          _pulseController.duration = const Duration(milliseconds: 1500);
          _pulseController.repeat(reverse: true);
          _spinController.stop();
          _waveController.stop();
          break;
        case MayaLogoState.listening:
          _pulseController.duration = const Duration(milliseconds: 800);
          _pulseController.repeat(reverse: true);
          _spinController.stop();
          _waveController.stop();
          break;
        case MayaLogoState.processing:
          _pulseController.stop();
          _spinController.duration = const Duration(seconds: 2);
          _spinController.repeat();
          _waveController.stop();
          break;
        case MayaLogoState.speaking:
          _pulseController.duration = const Duration(milliseconds: 500);
          _pulseController.repeat(reverse: true);
          _spinController.stop();
          _waveController.duration = const Duration(milliseconds: 800);
          _waveController.repeat(reverse: true);
          break;
        case MayaLogoState.error:
          _pulseController.duration = const Duration(milliseconds: 200);
          _pulseController.repeat(reverse: true);
          _spinController.stop();
          _waveController.stop();
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: MayaTheme.slate900,
        drawer: _AppDrawer(),
        body: Column(
          children: [
            // Slim App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: MayaTheme.slate900,
                border: Border(
                  bottom: BorderSide(
                    color: MayaTheme.neonCyan.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    style: IconButton.styleFrom(
                      backgroundColor: MayaTheme.glassWhite10,
                    ),
                    tooltip: 'Open Menu',
                  ),
                  const SizedBox(width: 8),
                  const Text('Maya Pro', style: MayaTheme.headlineMedium),
                  const Spacer(),
                  // Agent & Tools status chips
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _StatusChip(
                        label: 'Agent',
                        value: 'Maya Core',
                        color: MayaTheme.neonCyan,
                        icon: Icons.psychology_rounded,
                      ),
                      const SizedBox(width: 8),
                      const _StatusChip(
                        label: 'Tools',
                        value: '3 Active',
                        color: MayaTheme.neonViolet,
                        icon: Icons.build_rounded,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: MayaTheme.glassWhite10,
                        ),
                        tooltip: 'More options',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Conversation List
            Expanded(
              child: Container(
                color: MayaTheme.slate900,
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MayaLogo(
                              size: 120,
                              state: _orbState,
                              showPulse: true,
                              showGlow: true,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Welcome to Maya Pro',
                              style: MayaTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isVoiceMode
                                  ? 'Tap mic to speak or type a message'
                                  : 'Type a message or tap mic to enable voice',
                              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[messages.length - 1 - index];
                          return _ChatBubble(
                            text: message.text,
                            isUser: message.isUser,
                            time: message.time,
                            isStreaming: message.isStreaming,
                            isVoice: message.isVoice ?? false,
                          ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.2);
                        },
                      ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: MayaTheme.slate900,
                border: Border(
                  top: BorderSide(
                    color: MayaTheme.neonCyan.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Voice Mode Toggle
                  IconButton(
                    icon: Icon(
                      _isVoiceMode ? Icons.record_voice_over_rounded : Icons.keyboard_rounded,
                      color: _isVoiceMode ? MayaTheme.neonCyan : Colors.white54,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _isVoiceMode = !_isVoiceMode;
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: _isVoiceMode ? MayaTheme.neonCyan.withValues(alpha: 0.1) : MayaTheme.glassWhite10,
                    ),
                    tooltip: _isVoiceMode ? 'Switch to text mode' : 'Switch to voice mode',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: MayaTheme.slate700,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _isVoiceMode ? 'Type a message...' : 'Message Maya...',
                          hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: MayaTheme.bodyMedium,
                        maxLines: null,
                        onSubmitted: (value) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Large Mic Button
                  GestureDetector(
                    onTapDown: (_) => _toggleListening(),
                    onTapUp: (_) => _toggleListening(),
                    onTapCancel: () => _toggleListening(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isListening
                            ? LinearGradient(
                                colors: [MayaTheme.error, MayaTheme.error.withValues(alpha: 0.7)],
                              )
                            : const LinearGradient(
                                colors: [MayaTheme.neonCyan, MayaTheme.neonViolet],
                              ),
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: MayaTheme.error.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: MayaTheme.neonCyan.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                      ),
                      child: Center(
                        child: Icon(
                          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ).animate(target: _isListening ? 1 : 0).scale(
                      duration: const Duration(milliseconds: 200),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Speaker Toggle
                  IconButton(
                    icon: Icon(
                      _speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: _speakerOn ? MayaTheme.neonCyan : Colors.white54,
                    ),
                    onPressed: _toggleSpeaker,
                    style: IconButton.styleFrom(
                      backgroundColor: MayaTheme.glassWhite10,
                    ),
                    tooltip: _speakerOn ? 'Speaker on' : 'Speaker off',
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

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: MayaTheme.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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
    final voiceStateAsync = ref.watch(voiceStateStreamProvider);
    final voiceState = voiceStateAsync.value;
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

final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier(ref);
});

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final bool isStreaming;
  final bool isVoice;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isStreaming = false,
    this.isVoice = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isStreaming,
    bool? isVoice,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser,
      time: time,
      isStreaming: isStreaming ?? this.isStreaming,
      isVoice: isVoice ?? this.isVoice,
    );
  }
}

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;

  ChatMessagesNotifier(this.ref) : super([
    ChatMessage(
      text: 'Hello! How can I help you today?',
      isUser: false,
      time: _formatTime(DateTime.now()),
    ),
  ]);

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      time: _formatTime(DateTime.now()),
    );
    state = [...state, userMessage];

    // Add a streaming assistant message
    final assistantMessage = ChatMessage(
      text: '',
      isUser: false,
      time: _formatTime(DateTime.now()),
      isStreaming: true,
    );
    state = [...state, assistantMessage];

    _streamChatResponse(text.trim());
  }

  void _streamChatResponse(String message) async {
    final apiService = ref.read(apiServiceProvider);
    int messageIndex = state.length - 1;

    try {
      await for (final chunk in apiService.chatStream(message)) {
        if (chunk.error != null) {
          state = [
            ...state.sublist(0, messageIndex),
            state[messageIndex].copyWith(
              text: 'Error: ${chunk.error}',
              isStreaming: false,
            ),
          ];
          break;
        }

        if (chunk.delta != null && chunk.delta!.isNotEmpty) {
          final currentText = state[messageIndex].text;
          state = [
            ...state.sublist(0, messageIndex),
            state[messageIndex].copyWith(text: currentText + chunk.delta!),
          ];
        }

        if (chunk.done == true) {
          state = [
            ...state.sublist(0, messageIndex),
            state[messageIndex].copyWith(isStreaming: false),
          ];
          break;
        }
      }
    } catch (e) {
      state = [
        ...state.sublist(0, messageIndex),
        state[messageIndex].copyWith(
          text: 'Error: $e',
          isStreaming: false,
        ),
      ];
    }
  }
}

class _HealthProbesWidget extends ConsumerWidget {
  const _HealthProbesWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthStreamProvider);

    return healthAsync.when(
      data: (health) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: health.isHealthy
              ? MayaTheme.neonEmerald.withValues(alpha: 0.15)
              : health.ready
                  ? MayaTheme.neonOrange.withValues(alpha: 0.15)
                  : MayaTheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: health.statusColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              health.live ? Icons.check_circle : Icons.error,
              size: 14,
              color: health.statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              health.statusText,
              style: MayaTheme.labelSmall.copyWith(
                color: health.statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: MayaTheme.glassWhite10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MayaTheme.glassWhite30),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(MayaTheme.neonCyan),
          ),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: MayaTheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MayaTheme.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 14, color: MayaTheme.error),
            const SizedBox(width: 4),
            Text(
              'Error',
              style: MayaTheme.labelSmall.copyWith(
                color: MayaTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      width: 300,
      backgroundColor: MayaTheme.slate900,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const MayaLogo(size: 40, state: MayaLogoState.idle),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Maya Pro', style: MayaTheme.headlineSmall),
                      Text('AI Assistant', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: MayaTheme.glassWhite10, height: 1),

            // Section 1: Agent Selector & Management
            _DrawerSection(
              title: 'Agent Selector & Management',
              icon: Icons.psychology_rounded,
              children: [
                _DrawerActionTile(
                  icon: Icons.psychology_rounded,
                  label: 'Select Agent',
                  subtitle: 'Choose active AI agent',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerActionTile(
                  icon: Icons.add_rounded,
                  label: 'Create Agent',
                  subtitle: 'Build custom agent',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerActionTile(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Manage Agents',
                  subtitle: 'View & edit agents',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),

            // Section 2: Tools & Integrations
            _DrawerSection(
              title: 'Tools & Integrations',
              icon: Icons.build_rounded,
              children: [
                _DrawerActionTile(
                  icon: Icons.build_rounded,
                  label: 'Available Tools',
                  subtitle: 'Browse all tools',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerActionTile(
                  icon: Icons.integration_instructions_rounded,
                  label: 'Integrations',
                  subtitle: 'Connected services',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerActionTile(
                  icon: Icons.extension_rounded,
                  label: 'MCP Servers',
                  subtitle: 'Model Context Protocol',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),

            // Section 3: Quick Settings & VPS Status
            _DrawerSection(
              title: 'Quick Settings & VPS Status',
              icon: Icons.settings_rounded,
              children: [
                _DrawerActionTile(
                  icon: Icons.memory_rounded,
                  label: 'Memory & RAG',
                  subtitle: 'Knowledge & context',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerActionTile(
                  icon: Icons.analytics_rounded,
                  label: 'Tasks & Workflows',
                  subtitle: 'Active workflows',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerActionTile(
                  icon: Icons.queue_rounded,
                  label: 'Task Queue Monitor',
                  subtitle: 'Live job list & workers',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _TaskQueueScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.analytics_rounded,
                  label: 'Metrics Dashboard',
                  subtitle: 'Uptime, counters, latency',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _MetricsScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.flag_rounded,
                  label: 'Feature Flags',
                  subtitle: 'Runtime feature toggles',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _FlagsScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.dns_rounded,
                  label: 'VPS Status',
                  subtitle: 'Connection: Online',
                  trailing: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: MayaTheme.neonEmerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerActionTile(
                  icon: Icons.tune_rounded,
                  label: 'Settings',
                  subtitle: 'Preferences & config',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Maya Pro v1.0.0',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DrawerSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: MayaTheme.neonCyan),
              const SizedBox(width: 8),
              Text(title, style: MayaTheme.labelMedium.copyWith(color: MayaTheme.neonCyan)),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MayaTheme.neonCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: MayaTheme.neonCyan, size: 20),
      ),
      title: Text(label, style: MayaTheme.titleSmall),
      subtitle: Text(subtitle, style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
    );
  }
}

class _ChatScreen extends ConsumerWidget {
  const _ChatScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider);
    final textController = TextEditingController();
    final scaffoldKey = GlobalKey<ScaffoldState>();

    void handleSend() {
      final text = textController.text.trim();
      if (text.isNotEmpty) {
        textController.clear();
        ref.read(chatMessagesProvider.notifier).sendMessage(text);
      }
    }

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: _AppDrawer(),
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
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => scaffoldKey.currentState?.openDrawer(),
                    style: IconButton.styleFrom(
                        backgroundColor: MayaTheme.glassWhite10),
                  ),
                  const Text('Chat', style: MayaTheme.headlineLarge),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];
                  return _ChatBubble(
                    text: message.text,
                    isUser: message.isUser,
                    time: message.time,
                    isStreaming: message.isStreaming,
                    isVoice: message.isVoice ?? false,
                  ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.2);
                },
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
                        controller: textController,
                        decoration: InputDecoration(
                          hintText: 'Message Maya...',
                          hintStyle: MayaTheme.bodyMedium
                              .copyWith(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: MayaTheme.bodyMedium,
                        maxLines: null,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            ref.read(chatMessagesProvider.notifier).sendMessage(value);
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: MayaTheme.neonCyan),
                    onPressed: () {
                      final text = textController.text;
                      if (text.trim().isNotEmpty) {
                        textController.clear();
                        ref.read(chatMessagesProvider.notifier).sendMessage(text);
                      }
                    },
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

class _ChatSidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      width: 280,
      backgroundColor: MayaTheme.slate900,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Features', style: MayaTheme.headlineMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                        backgroundColor: MayaTheme.glassWhite10),
                  ),
                ],
              ),
            ),
            const Divider(color: MayaTheme.glassWhite10),
            _SidebarItem(
              icon: Icons.psychology_rounded,
              label: 'Agents',
              subtitle: 'Select AI agent',
              onTap: () => Navigator.pop(context),
            ),
            _SidebarItem(
              icon: Icons.build_rounded,
              label: 'Tools',
              subtitle: 'Available tools',
              onTap: () => Navigator.pop(context),
            ),
            _SidebarItem(
              icon: Icons.memory_rounded,
              label: 'Memory',
              subtitle: 'RAG & context',
              onTap: () => Navigator.pop(context),
            ),
            _SidebarItem(
              icon: Icons.analytics_rounded,
              label: 'Tasks',
              subtitle: 'Active workflows',
              onTap: () => Navigator.pop(context),
            ),
            _SidebarItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              subtitle: 'Chat preferences',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MayaTheme.neonCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: MayaTheme.neonCyan, size: 22),
      ),
      title: Text(label, style: MayaTheme.titleMedium),
      subtitle: Text(subtitle, style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String time;
  final bool isStreaming;
  final bool isVoice;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.time,
    this.isStreaming = false,
    this.isVoice = false,
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
            if (isStreaming && !isUser) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isUser ? MayaTheme.slate900 : Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Typing...',
                      style: MayaTheme.labelSmall
                          .copyWith(color: Colors.white54)),
                ],
              ),
            ],
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
              const SizedBox(width: 8),
              // Health Probes
              const _HealthProbesWidget(),
            ),
    );
  }
}

// Task Queue Monitor Screen
class _TaskQueueScreen extends ConsumerStatefulWidget {
  const _TaskQueueScreen();

  @override
  ConsumerState<_TaskQueueScreen> createState() => _TaskQueueScreenState();
}

class _TaskQueueScreenState extends ConsumerState<_TaskQueueScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.invalidate(queueStatusProvider);
        ref.invalidate(queueStatsProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queueStatusAsync = ref.watch(queueStatusProvider);
    final queueStatsAsync = ref.watch(queueStatsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Task Queue Monitor', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.invalidate(queueStatusProvider);
                ref.invalidate(queueStatsProvider);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Stats Cards
            queueStatsAsync.when(
              data: (stats) => Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Pending',
                      value: stats.pending.toString(),
                      color: MayaTheme.neonOrange,
                      icon: Icons.schedule_rounded,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Running',
                      value: stats.running.toString(),
                      color: MayaTheme.neonCyan,
                      icon: Icons.play_circle_rounded,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Completed',
                      value: stats.completed.toString(),
                      color: MayaTheme.neonEmerald,
                      icon: Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Failed',
                      value: stats.failed.toString(),
                      color: MayaTheme.error,
                      icon: Icons.error_rounded,
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 100),
              error: (_, __) => const SizedBox(height: 100),
            ),

            const Divider(color: MayaTheme.glassWhite10, height: 1),

            // Task List
            Expanded(
              child: queueStatusAsync.when(
                data: (status) {
                  final tasks = status.tasks.values.toList()
                    ..sort((a, b) {
                      final aTime = a['createdAt'] ?? '';
                      final bTime = b['createdAt'] ?? '';
                      return bTime.compareTo(aTime);
                    });

                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.queue_rounded,
                              size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text('No tasks in queue',
                              style: MayaTheme.bodyMedium
                                  .copyWith(color: Colors.white38)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskQueueTile(task: task);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
                  ),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_rounded,
                          size: 48, color: MayaTheme.error),
                      const SizedBox(height: 16),
                      Text('Error loading queue',
                          style: MayaTheme.bodyMedium
                              .copyWith(color: MayaTheme.error)),
                      const SizedBox(height: 8),
                      Text(err.toString(),
                          style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: MayaTheme.glassCardGlow(glowColor: color),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: MayaTheme.headlineMedium.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _TaskQueueTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> task;

  const _TaskQueueTile({required this.task});

  @override
  ConsumerState<_TaskQueueTile> createState() => _TaskQueueTileState();
}

class _TaskQueueTileState extends ConsumerState<_TaskQueueTile> {
  Color _getStateColor(String state) {
    switch (state) {
      case 'pending':
        return MayaTheme.neonOrange;
      case 'running':
        return MayaTheme.neonCyan;
      case 'completed':
        return MayaTheme.neonEmerald;
      case 'failed':
        return MayaTheme.error;
      case 'cancelled':
        return Colors.white38;
      default:
        return Colors.white54;
    }
  }

  IconData _getStateIcon(String state) {
    switch (state) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'running':
        return Icons.play_circle_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'failed':
        return Icons.error_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final taskId = task['taskId'] ?? task['id'] ?? 'unknown';
    final job = task['job'] ?? 'unknown';
    final state = task['state'] ?? 'unknown';
    final payload = task['payload'] ?? {};
    final error = task['error'];
    final createdAt = task['createdAt'] ?? '';
    final startedAt = task['startedAt'];
    final completedAt = task['completedAt'];
    final workerId = task['workerId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStateColor(state).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getStateIcon(state), color: _getStateColor(state), size: 20),
        ),
        title: Text(
          job,
          style: MayaTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStateColor(state).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.toUpperCase(),
                    style: MayaTheme.labelSmall.copyWith(
                      color: _getStateColor(state),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (workerId != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Worker: $workerId',
                    style: MayaTheme.labelSmall.copyWith(color: Colors.white54),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: state == 'pending' || state == 'running'
            ? IconButton(
                icon: const Icon(Icons.cancel_rounded, color: MayaTheme.error),
                onPressed: () async {
                  final apiService = ref.read(apiServiceProvider);
                  final success = await apiService.cancelQueueTask(taskId);
                  if (success && mounted) {
                    ref.invalidate(queueStatusProvider);
                    ref.invalidate(queueStatsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task $taskId cancelled'),
                        backgroundColor: MayaTheme.neonEmerald,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to cancel task $taskId'),
                        backgroundColor: MayaTheme.error,
                      ),
                    );
                  }
                },
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Task ID', value: taskId),
                _DetailRow(label: 'Job Type', value: job),
                _DetailRow(label: 'State', value: state),
                if (createdAt.isNotEmpty)
                  _DetailRow(label: 'Created', value: createdAt),
                if (startedAt != null)
                  _DetailRow(label: 'Started', value: startedAt),
                if (completedAt != null)
                  _DetailRow(label: 'Completed', value: completedAt),
                if (workerId != null)
                  _DetailRow(label: 'Worker', value: workerId),
                if (payload.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Payload:', style: MayaTheme.labelMedium),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MayaTheme.slate900,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MayaTheme.glassWhite10),
                    ),
                    child: Text(
                      payload.toString(),
                      style: MayaTheme.bodySmall.copyWith(
                          color: Colors.white70, fontFamily: 'monospace'),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text('Error:', style: MayaTheme.labelMedium.copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MayaTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MayaTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      error,
                      style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: MayaTheme.labelMedium.copyWith(color: Colors.white54)),
          ),
          Expanded(
            child: Text(value, style: MayaTheme.bodyMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Queue Providers
final queueStatusProvider = FutureProvider<QueueStatus>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getQueueStatus();
});

final queueStatsProvider = FutureProvider<QueueStats>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getQueueStats();
});

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

// Metrics Dashboard Screen
class _MetricsScreen extends ConsumerStatefulWidget {
  const _MetricsScreen();

  @override
  ConsumerState<_MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends ConsumerState<_MetricsScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(metricsProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(metricsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Metrics Dashboard', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(metricsProvider),
            ),
          ],
        ),
        body: metricsAsync.when(
          data: (metrics) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Uptime Card
                _MetricsCard(
                  title: 'Uptime',
                  value: _formatUptime(metrics.uptimeS),
                  icon: Icons.timer_rounded,
                  color: MayaTheme.neonCyan,
                ),
                const SizedBox(height: 16),

                // Counters Section
                const Text('Counters', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                _buildCountersGrid(metrics.counters),
                const SizedBox(height: 24),

                // Latency Section
                const Text('Latency (ms)', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                if (metrics.latency.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(
                      child: Text('No latency data yet',
                          style: MayaTheme.bodyMedium),
                    ),
                  )
                else
                  _buildLatencyTable(metrics.latency),
              ],
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
            ),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                const SizedBox(height: 16),
                Text('Error loading metrics',
                    style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                const SizedBox(height: 8),
                Text(err.toString(),
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatUptime(double seconds) {
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m ${s.toInt()}s';
    if (m > 0) return '${m}m ${s.toInt()}s';
    return '${s.toStringAsFixed(1)}s';
  }

  Widget _buildCountersGrid(Map<String, dynamic> counters) {
    if (counters.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: MayaTheme.glassCard(),
        child: const Center(
          child: Text('No counters yet', style: MayaTheme.bodyMedium),
        ),
      );
    }

    final entries = counters.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: MayaTheme.glassCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.key,
                style: MayaTheme.labelSmall.copyWith(color: Colors.white54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _formatNumber(entry.value),
                style: MayaTheme.headlineMedium.copyWith(color: MayaTheme.neonCyan),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(dynamic value) {
    if (value is int) {
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
      return value.toString();
    }
    return value.toString();
  }

  Widget _buildLatencyTable(Map<String, dynamic> latency) {
    final entries = latency.entries.toList()
      ..sort((a, b) => (b.value['avg_ms'] as num).compareTo(a.value['avg_ms'] as num));

    return Container(
      decoration: MayaTheme.glassCard(),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: MayaTheme.slate800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Endpoint', style: MayaTheme.labelMedium)),
                Expanded(flex: 1, child: Text('Count', style: MayaTheme.labelMedium, textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('Avg (ms)', style: MayaTheme.labelMedium, textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('P95 (ms)', style: MayaTheme.labelMedium, textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Rows
          ...entries.map((entry) {
            final stats = entry.value;
            final count = stats['count'] as int? ?? 0;
            final avgMs = (stats['avg_ms'] as num?)?.toDouble() ?? 0.0;
            final p95Ms = (stats['p95_ms'] as num?)?.toDouble() ?? 0.0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: MayaTheme.glassWhite10)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(entry.key, style: MayaTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1, child: Text(count.toString(), style: MayaTheme.bodySmall, textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text(avgMs.toStringAsFixed(1), style: MayaTheme.bodySmall, textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text(p95Ms.toStringAsFixed(1), style: MayaTheme.bodySmall, textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: MayaTheme.glassCardGlow(glowColor: color),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MayaTheme.labelMedium.copyWith(color: Colors.white54)),
                const SizedBox(height: 4),
                Text(value, style: MayaTheme.headlineMedium.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Feature Flags Screen
class _FlagsScreen extends ConsumerStatefulWidget {
  const _FlagsScreen();

  @override
  ConsumerState<_FlagsScreen> createState() => _FlagsScreenState();
}

class _FlagsScreenState extends ConsumerState<_FlagsScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(flagsProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flagsAsync = ref.watch(flagsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Feature Flags', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(flagsProvider),
            ),
          ],
        ),
        body: flagsAsync.when(
          data: (flags) {
            final entries = flags.flags.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_rounded, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text('No feature flags configured',
                        style: MayaTheme.bodyMedium.copyWith(color: Colors.white38)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _FlagTile(key: entry.key, value: entry.value);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
            ),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                const SizedBox(height: 16),
                Text('Error loading flags',
                    style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                const SizedBox(height: 8),
                Text(err.toString(),
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  final String key;
  final bool value;

  const _FlagTile({required this.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value
                  ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                  : MayaTheme.neonOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              value ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              color: value ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key, style: MayaTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  value ? 'Enabled' : 'Disabled',
                  style: MayaTheme.labelSmall.copyWith(
                    color: value ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Metrics & Flags Providers
final metricsProvider = FutureProvider<MetricsSnapshot>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getMetrics();
});

final flagsProvider = FutureProvider<FlagsSnapshot>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getFlags();
});
