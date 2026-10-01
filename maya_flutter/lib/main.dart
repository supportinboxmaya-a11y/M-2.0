import 'dart:async';

import 'package:flutter/services.dart';

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

class _VoiceScreen extends ConsumerStatefulWidget {
  const _VoiceScreen();

  @override
  ConsumerState<_VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<_VoiceScreen> {
  String _ttsText = 'Hello! I am Maya, your AI assistant.';

  @override
  Widget build(BuildContext context) {
    final voiceStateAsync = ref.watch(voiceStateStreamProvider);
    final voiceState = voiceStateAsync.value;
    final voiceService = ref.read(voiceServiceProvider);
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
                        MayaLogo(
                          size: 160,
                          state: isRecording ? MayaLogoState.listening : (isSpeaking ? MayaLogoState.speaking : MayaLogoState.idle),
                          showPulse: true,
                          showGlow: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Status Text
                    Text(
                      isRecording ? 'Listening...' : (isSpeaking ? 'Speaking...' : 'Tap to speak'),
                      style: MayaTheme.titleMedium.copyWith(color: Colors.white70),
                    ),

                    const SizedBox(height: 32),

                    // Voice Button
                    GestureDetector(
                      onTapDown: (_) => _toggleListening(),
                      onTapUp: (_) => _toggleListening(),
                      onTapCancel: () => _toggleListening(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isRecording
                              ? LinearGradient(
                                  colors: [MayaTheme.error, MayaTheme.error.withValues(alpha: 0.7)],
                                )
                              : const LinearGradient(
                                  colors: [MayaTheme.neonCyan, MayaTheme.neonViolet],
                                ),
                          boxShadow: isRecording
                              ? [
                                  BoxShadow(
                                    color: MayaTheme.error.withValues(alpha: 0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: MayaTheme.neonCyan.withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Icon(
                            isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            size: 40,
                            color: MayaTheme.slate900,
                          ),
                        ),
                      )
                          .animate(target: isRecording ? 1 : 0)
                          .scale(duration: const Duration(milliseconds: 200)),
                    ),

                    const SizedBox(height: 32),

                    // Transcript
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: MayaTheme.glassCard(),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final transcript = ref.watch(voiceServiceProvider).currentTranscript;
                          return Text(
                            transcript.isEmpty ? 'Say something...' : transcript,
                            style: MayaTheme.bodyMedium
                                .copyWith(color: Colors.white54),
                            textAlign: TextAlign.center,
                          );
                        },
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
                          onPressed: _stopAll,
                        ),
                        const SizedBox(width: 24),
                        IconButton.filled(
                          icon: Icon(isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: isSpeaking ? MayaTheme.error : MayaTheme.neonEmerald,
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: _toggleTTS,
                        ),
                        const SizedBox(width: 24),
                        IconButton.filled(
                          icon: const Icon(Icons.settings_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: MayaTheme.slate700,
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: _showVoiceSettings,
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

  void _toggleListening() {
    final voiceService = ref.read(voiceServiceProvider);
    if (voiceService.isRecording) {
      voiceService.stopRecording();
    } else {
      voiceService.startRecording(useSpeechToText: true);
    }
  }

  void _stopAll() {
    final voiceService = ref.read(voiceServiceProvider);
    voiceService.stopRecording();
    voiceService.stopSpeaking();
  }

  void _toggleTTS() {
    final voiceService = ref.read(voiceServiceProvider);
    if (voiceService.isSpeaking) {
      voiceService.stopSpeaking();
    } else {
      voiceService.speak(_ttsText, voice: 'en-US-AriaNeural');
    }
  }

  void _showVoiceSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MayaTheme.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voice Settings', style: MayaTheme.headlineMedium),
            const SizedBox(height: 24),
            const Text('TTS Voice', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['en-US-AriaNeural', 'en-US-GuyNeural', 'en-GB-RyanNeural', 'bn-BD', 'hi-IN']
                  .map((v) => FilterChip(
                        label: Text(v),
                        selected: _ttsText.contains(v),
                        onSelected: (selected) {
                          setState(() => _ttsText = v);
                        },
                        selectedColor: MayaTheme.neonCyan.withValues(alpha: 0.3),
                        checkmarkColor: MayaTheme.neonCyan,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: TextEditingController(text: _ttsText),
              maxLines: 3,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Test Text',
                labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => _ttsText = v,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(voiceServiceProvider).speak(_ttsText);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Speak Test Text'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MayaTheme.neonCyan,
                  foregroundColor: MayaTheme.slate900,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraScreen extends ConsumerStatefulWidget {
  const _CameraScreen();

  @override
  ConsumerState<_CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<_CameraScreen> {
  VisionAnalysisResult? _analysisResult;
  OcrResult? _ocrResult;
  bool _isProcessing = false;
  String _processingText = '';

  @override
  Widget build(BuildContext context) {
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
                          onPressed: () {
                            final cameraService = ref.read(cameraServiceProvider);
                            final mode = cameraService.controller?.value.flashMode ?? FlashMode.off;
                            cameraService.setFlashMode(mode == FlashMode.off ? FlashMode.torch : FlashMode.off);
                          },
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.cameraswitch_rounded),
                          onPressed: () {
                            ref.read(cameraServiceProvider).switchCamera();
                          },
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

            // Processing Overlay
            if (_isProcessing)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
                      ),
                      const SizedBox(height: 16),
                      Text(_processingText, style: MayaTheme.bodyMedium.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),

            // Results Overlay
            if ((_analysisResult != null || _ocrResult != null) && !_isProcessing)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MayaTheme.slate900.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: MayaTheme.neonCyan.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_rounded, color: MayaTheme.neonCyan, size: 24),
                          const SizedBox(width: 12),
                          Text('Analysis Result', style: MayaTheme.titleMedium),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54),
                            onPressed: () => setState(() {
                              _analysisResult = null;
                              _ocrResult = null;
                            }),
                          ),
                        ],
                      ),
                      if (_analysisResult != null) ...[
                        const SizedBox(height: 8),
                        Text(_analysisResult!.analysis, style: MayaTheme.bodyMedium),
                        if (_analysisResult!.tags != null && _analysisResult!.tags!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _analysisResult!.tags!.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: MayaTheme.neonCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
                              ),
                              child: Text(tag, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan)),
                            )).toList(),
                          ),
                        ],
                      ],
                      if (_ocrResult != null) ...[
                        const SizedBox(height: 12),
                        const Divider(color: MayaTheme.glassWhite10),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.text_fields_rounded, color: MayaTheme.neonViolet, size: 20),
                            const SizedBox(width: 8),
                            Text('OCR Text', style: MayaTheme.titleSmall.copyWith(color: MayaTheme.neonViolet)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: MayaTheme.neonCyan, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _ocrResult!.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: const Text('Copied to clipboard'), backgroundColor: MayaTheme.neonEmerald),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MayaTheme.slate700,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: MayaTheme.glassWhite10),
                          ),
                          child: SelectableText(
                            _ocrResult!.text.isEmpty ? 'No text detected' : _ocrResult!.text,
                            style: MayaTheme.bodyMedium.copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                        if (_ocrResult!.regions != null && _ocrResult!.regions!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Regions: ${_ocrResult!.regions!.length}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                        ],
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _analyzeImage,
                              icon: const Icon(Icons.psychology_rounded),
                              label: const Text('Analyze'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MayaTheme.neonCyan,
                                side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _extractText,
                              icon: const Icon(Icons.text_fields_rounded),
                              label: const Text('OCR'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MayaTheme.neonViolet,
                                side: BorderSide(color: MayaTheme.neonViolet.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _captureAndAnalyze,
                              icon: const Icon(Icons.camera_rounded),
                              label: const Text('Capture'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MayaTheme.neonCyan,
                                foregroundColor: MayaTheme.slate900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                          onTap: _pickFromGallery,
                        ),
                        _CameraShutterButton(onPressed: _capturePhoto),
                        _CameraActionButton(
                          icon: Icons.flash_on_rounded,
                          label: 'Flash',
                          onPressed: _toggleFlash,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Capture → Analyze → OCR',
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

  Future<void> _capturePhoto() async {
    if (_isProcessing) return;
    final cameraService = ref.read(cameraServiceProvider);
    final photo = await cameraService.takePhoto();
    if (photo != null) {
      _analyzePhoto(photo);
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_isProcessing) return;
    final cameraService = ref.read(cameraServiceProvider);
    final photo = await cameraService.takePhoto();
    if (photo != null) {
      _analyzePhoto(photo);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    final cameraService = ref.read(cameraServiceProvider);
    final photo = await cameraService._picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      _analyzePhoto(photo);
    }
  }

  Future<void> _analyzePhoto(XFile photo) async {
    setState(() {
      _isProcessing = true;
      _processingText = 'Analyzing image...';
      _analysisResult = null;
      _ocrResult = null;
    });

    final cameraService = ref.read(cameraServiceProvider);
    final result = await cameraService.analyzePhoto(photo, prompt: 'Describe this image in detail.');

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _analysisResult = result;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_isProcessing) return;
    // Re-analyze last captured image
    final cameraService = ref.read(cameraServiceProvider);
    // This would need the last photo - for now just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Recapture image to analyze'), backgroundColor: MayaTheme.neonOrange),
    );
  }

  Future<void> _extractText() async {
    if (_isProcessing) return;
    // OCR on last captured image - would need to store last photo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Recapture image for OCR'), backgroundColor: MayaTheme.neonOrange),
    );
  }

  Future<void> _toggleFlash() async {
    final cameraService = ref.read(cameraServiceProvider);
    final mode = cameraService.controller?.value.flashMode ?? FlashMode.off;
    cameraService.setFlashMode(mode == FlashMode.off ? FlashMode.torch : FlashMode.off);
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
                  icon: Icons.people_rounded,
                  label: 'Agents',
                  subtitle: '11 agents, status & orchestration',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _AgentsScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.psychology_rounded,
                  label: 'Brain Engine',
                  subtitle: 'Goal analysis & task graphs',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _BrainEngineScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.robot_rounded,
                  label: 'Autonomous Mode',
                  subtitle: 'End-to-end autonomous execution',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _AutonomousModeScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.router_rounded,
                  label: 'Multi-Model Router',
                  subtitle: 'Providers, stats & routing strategy',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _RouterScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.business_rounded,
                  label: 'Enterprise Layer',
                  subtitle: 'RBAC, Orgs, API Keys, Audit',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _EnterpriseScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.psychology_rounded,
                  label: 'Learning Layer',
                  subtitle: 'Feedback, Experience, Prompts',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _LearningScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.architecture_rounded,
                  label: 'AGI Architecture',
                  subtitle: 'Synthesizer, Society, Procedural Memory',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _AGIArchitectureScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.psychology_rounded,
                  label: 'Maya Cognitive Core',
                  subtitle: 'Hippocampus, Semantic, Working Memory, Browser, Sandbox',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _MayaCognitiveCoreScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.analytics_rounded,
                  label: 'Business Analysis',
                  subtitle: 'Missions, reports, 4-agent analysis pipeline',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _BusinessAnalysisScreen(),
                      ),
                    );
                  },
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
                  label: 'Tools & Providers',
                  subtitle: 'Manage tools, logs & LLM providers',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _ToolsProvidersScreen(),
                      ),
                    );
                  },
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _MemoryScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.analytics_rounded,
                  label: 'Tasks & Workflows',
                  subtitle: 'Workflow runs, steps, checkpoints',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _WorkflowEngineScreen(),
                      ),
                    );
                  },
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
                  icon: Icons.computer_rounded,
                  label: 'Instance Manager',
                  subtitle: 'Create & manage Maya instances',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _InstanceScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.deployed_code_rounded,
                  label: 'Hosting Manager',
                  subtitle: 'Deploy & manage hosted apps',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _HostingScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.psychology_rounded,
                  label: 'Cognition Loop',
                  subtitle: 'Think → Act → Observe cycle',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _CognitionLoopScreen(),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.deployed_code_rounded,
                  label: 'Hosting Manager',
                  subtitle: 'Deploy & manage hosted apps',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _HostingScreen(),
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
                  icon: Icons.cloud_rounded,
                  label: 'Remote VPS Deploy',
                  subtitle: 'SSH + Docker deploy to VPS',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _RemoteVpsScreen(),
                      ),
                    );
                  },
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

class _ChatBubble extends ConsumerStatefulWidget {
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
  ConsumerState<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends ConsumerState<_ChatBubble> {
  bool _isSpeaking = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: widget.isUser ? MayaTheme.neonCyan : MayaTheme.slate700,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(widget.isUser ? 20 : 4),
            bottomRight: Radius.circular(widget.isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.isUser ? MayaTheme.neonCyan : MayaTheme.neonViolet)
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
            Text(widget.text,
                style: MayaTheme.bodyMedium.copyWith(
                    color: widget.isUser ? MayaTheme.slate900 : Colors.white)),
            if (widget.isStreaming && !widget.isUser) ...[
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
                          widget.isUser ? MayaTheme.slate900 : Colors.white70),
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
                Text(widget.time,
                    style:
                        MayaTheme.labelSmall.copyWith(color: Colors.white38)),
                const SizedBox(width: 8),
                const Icon(Icons.done_all_rounded,
                    size: 14, color: Colors.white38),
                if (!widget.isUser) ...[
                  const SizedBox(width: 8),
                  _TTSButton(text: widget.text, isSpeaking: _isSpeaking, onStateChanged: (speaking) {
                    setState(() => _isSpeaking = speaking);
                  }),
                ],
              ),
            ],
          ),
        ),
      );
  }
}

class _TTSButton extends ConsumerStatefulWidget {
  final String text;
  final bool isSpeaking;
  final ValueChanged<bool> onStateChanged;

  const _TTSButton({
    required this.text,
    required this.isSpeaking,
    required this.onStateChanged,
  });

  @override
  ConsumerState<_TTSButton> createState() => _TTSButtonState();
}

class _TTSButtonState extends ConsumerState<_TTSButton> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleTTS,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _isPlaying
              ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
              : MayaTheme.glassWhite10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
          size: 16,
          color: _isPlaying ? MayaTheme.neonEmerald : Colors.white54,
        ),
      ),
    );
  }

  void _toggleTTS() async {
    final voiceService = ref.read(voiceServiceProvider);
    if (voiceService.isSpeaking) {
      await voiceService.stopSpeaking();
      widget.onStateChanged(false);
      setState(() => _isPlaying = false);
    } else {
      widget.onStateChanged(true);
      setState(() => _isPlaying = true);
      await voiceService.speak(widget.text);
      widget.onStateChanged(false);
      if (mounted) setState(() => _isPlaying = false);
    }
  }
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

// Memory Screen
class _MemoryScreen extends ConsumerStatefulWidget {
  const _MemoryScreen();

  @override
  ConsumerState<_MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<_MemoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(memoryListProvider);
        ref.invalidate(memoryStatsProvider);
        ref.invalidate(ragStatsProvider);
        ref.invalidate(ragDocumentsProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoryListAsync = ref.watch(memoryListProvider);
    final memoryStatsAsync = ref.watch(memoryStatsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Memory & RAG', style: MayaTheme.headlineSmall),
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
                ref.invalidate(memoryListProvider);
                ref.invalidate(memoryStatsProvider);
                ref.invalidate(ragStatsProvider);
                ref.invalidate(ragDocumentsProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _showAddMemoryDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.memory_rounded), text: 'Memories'),
              Tab(icon: Icon(Icons.description_rounded), text: 'Documents'),
              Tab(icon: Icon(Icons.search_rounded), text: 'RAG Search'),
              Tab(icon: Icon(Icons.context_rounded), text: 'RAG Context'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMemoriesTab(memoryListAsync, memoryStatsAsync),
            _buildDocumentsTab(),
            _buildRAGSearchTab(),
            _buildRAGContextTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoriesTab(AsyncValue<MemoryListResponse> memoryListAsync, AsyncValue<MemoryStatsResponse> memoryStatsAsync) {
    return Column(
      children: [
        // Stats Cards
        memoryStatsAsync.when(
          data: (stats) => Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Total Memories',
                    value: stats.totalMemories.toString(),
                    color: MayaTheme.neonCyan,
                    icon: Icons.memory_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Vectors',
                    value: stats.totalVectors.toString(),
                    color: MayaTheme.neonViolet,
                    icon: Icons.data_array_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Index Type',
                    value: stats.indexType,
                    color: MayaTheme.neonEmerald,
                    icon: Icons.category_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Size (MB)',
                    value: stats.indexSizeMb.toStringAsFixed(1),
                    color: MayaTheme.neonOrange,
                    icon: Icons.storage_rounded,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox(height: 100),
          error: (_, __) => const SizedBox(height: 100),
        ),

        const Divider(color: MayaTheme.glassWhite10, height: 1),

        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search memories...',
                    hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              ref.read(memorySearchTriggerProvider.notifier).state = '';
                            },
                          )
                        : null,
                      filled: true,
                      fillColor: MayaTheme.slate700,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    style: MayaTheme.bodyMedium,
                    onSubmitted: (value) {
                      setState(() => _searchQuery = value);
                      ref.read(memorySearchTriggerProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    color: MayaTheme.neonCyan,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = '';
                        _searchController.clear();
                        ref.read(memorySearchTriggerProvider.notifier).state = '';
                      }
                    });
                    ref.invalidate(memoryListProvider);
                    ref.invalidate(memorySearchProvider);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: MayaTheme.glassWhite10,
                  ),
                ),
              ],
            ),
          ),

          // Memory List / Search Results
          Expanded(
            child: _isSearching && _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildMemoryList(memoryListAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final ragStatsAsync = ref.watch(ragStatsProvider);
    final ragDocsAsync = ref.watch(ragDocumentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RAG Stats
          ragStatsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _MemoryStatCard(
                      label: 'Documents',
                      value: stats.totalDocuments.toString(),
                      color: MayaTheme.neonCyan,
                      icon: Icons.description_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MemoryStatCard(
                      label: 'Chunks',
                      value: stats.totalChunks.toString(),
                      color: MayaTheme.neonViolet,
                      icon: Icons.data_array_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MemoryStatCard(
                      label: 'Index Type',
                      value: stats.indexType,
                      color: MayaTheme.neonEmerald,
                      icon: Icons.category_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MemoryStatCard(
                      label: 'Size (MB)',
                      value: stats.indexSizeMb.toStringAsFixed(1),
                      color: MayaTheme.neonOrange,
                      icon: Icons.storage_rounded,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox(height: 100),
          ),

          const SizedBox(height: 24),

          // Ingest Document
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ingest Document', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                _IngestDocumentForm(onSuccess: () {
                  ref.invalidate(ragDocumentsProvider);
                  ref.invalidate(ragStatsProvider);
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Documents List
          const Text('Documents', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          ragDocsAsync.when(
            data: (response) {
              if (response.documents.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: const Center(
                    child: Text('No documents yet. Ingest a document to get started.',
                        style: MayaTheme.bodyMedium),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: response.documents.length,
                itemBuilder: (context, index) {
                  final doc = response.documents[index];
                  return _RAGDocumentTile(doc: doc, onDelete: () async {
                    final success = await ref.read(apiServiceProvider).deleteRAGDocument(doc.id);
                    if (success && mounted) {
                      ref.invalidate(ragDocumentsProvider);
                      ref.invalidate(ragStatsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Document deleted'), backgroundColor: MayaTheme.neonEmerald),
                      );
                    }
                  });
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
            ),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading documents', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRAGSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RAG Hybrid Search', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Search the knowledge base with hybrid (vector + keyword), keyword-only, or vector-only modes.',
                  style: MayaTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Query',
                    labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    ref.invalidate(ragSearchProvider(_searchQuery));
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: 'hybrid',
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Search Mode',
                          labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'hybrid', child: Text('Hybrid (Vector + Keyword)')),
                          DropdownMenuItem(value: 'keyword', child: Text('Keyword Only (BM25)')),
                          DropdownMenuItem(value: 'vector', child: Text('Vector Only')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: 5,
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Limit',
                          labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3')),
                          DropdownMenuItem(value: 5, child: Text('5')),
                          DropdownMenuItem(value: 10, child: Text('10')),
                          DropdownMenuItem(value: 20, child: Text('20')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _searchQuery = _searchController.text);
                      ref.invalidate(ragSearchProvider(_searchQuery));
                    },
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Search Results
          Consumer(
            builder: (context, ref, _) {
              final searchAsync = ref.watch(ragSearchProvider(_searchQuery));
              return searchAsync.when(
                data: (result) {
                  if (result.results.isEmpty && _searchQuery.isNotEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: MayaTheme.glassCard(),
                      child: const Center(
                        child: Text('No results found', style: MayaTheme.bodyMedium),
                      ),
                    );
                  }
                  if (_searchQuery.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: MayaTheme.glassCard(),
                      child: const Center(
                        child: Text('Enter a query and tap Search',
                            style: MayaTheme.bodyMedium),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Results for "${result.query}" (${result.mode})',
                          style: MayaTheme.titleMedium),
                      const SizedBox(height: 12),
                      ...result.results.map((hit) => _RAGSearchResultTile(hit: hit)),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                      const SizedBox(height: 16),
                      Text('Search error', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                      const SizedBox(height: 8),
                      Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRAGContextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context Form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RAG Context with Attribution', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Get an LLM-ready context block with numbered citations for a query.',
                  style: MayaTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Query',
                    labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: 5,
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Limit',
                          labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3')),
                          DropdownMenuItem(value: 5, child: Text('5')),
                          DropdownMenuItem(value: 10, child: Text('10')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: 6000,
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Max Chars',
                          labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 2000, child: Text('2000')),
                          DropdownMenuItem(value: 4000, child: Text('4000')),
                          DropdownMenuItem(value: 6000, child: Text('6000')),
                          DropdownMenuItem(value: 8000, child: Text('8000')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(ragContextProvider(_searchController.text));
                    },
                    icon: const Icon(Icons.context_rounded),
                    label: const Text('Get Context'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Context Result
          Consumer(
            builder: (context, ref, _) {
              final contextAsync = ref.watch(ragContextProvider(_searchController.text));
              return contextAsync.when(
                data: (result) {
                  if (result.context.isEmpty && _searchController.text.isEmpty) {
                    return const SizedBox();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Context Block', style: MayaTheme.titleMedium),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: MayaTheme.glassCard(),
                        child: SelectableText(
                          result.context,
                          style: MayaTheme.bodyMedium.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                      if (result.citations.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Citations', style: MayaTheme.titleMedium),
                        const SizedBox(height: 12),
                        ...result.citations.asMap().entries.map((entry) {
                          final index = entry.key;
                          final citation = entry.value;
                          return _RAGCitationTile(index: index + 1, citation: citation);
                        }),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                      const SizedBox(height: 16),
                      Text('Context error', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                      const SizedBox(height: 8),
                      Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryList(AsyncValue<MemoryListResponse> memoryListAsync) {
    return memoryListAsync.when(
      data: (response) {
        if (response.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.memory_rounded, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text('No memories yet',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white38)),
                const SizedBox(height: 8),
                Text('Tap + to add a memory',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white24)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: response.items.length,
          itemBuilder: (context, index) {
            final item = response.items[index];
            return _MemoryItemTile(item: item);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading memories',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ref.watch(memorySearchProvider).when(
      data: (response) {
        if (response.results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text('No results for "$_searchQuery"',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white38)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: response.results.length,
          itemBuilder: (context, index) {
            final item = response.results[index];
            return _MemoryItemTile(item: item, showScore: true);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Search error',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showAddMemoryDialog() {
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Add Memory', style: MayaTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              maxLines: 4,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Enter memory content...',
                hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = contentController.text.trim();
              if (content.isNotEmpty) {
                Navigator.pop(context);
                try {
                  final apiService = ref.read(apiServiceProvider);
                  await apiService.createMemory(content: content);
                  ref.invalidate(memoryListProvider);
                  ref.invalidate(memoryStatsProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Memory added'),
                        backgroundColor: MayaTheme.neonEmerald,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: MayaTheme.error,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _MemoryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MemoryStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _MemoryItemTile extends ConsumerWidget {
  final MemoryItem item;
  final bool showScore;

  const _MemoryItemTile({required this.item, this.showScore = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.article_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(
          item.content.length > 60
              ? '${item.content.substring(0, 60)}...'
              : item.content,
          style: MayaTheme.titleMedium.copyWith(fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (item.createdAt != null)
              Text(
                'Created: ${item.createdAt}',
                style: MayaTheme.labelSmall.copyWith(color: Colors.white54),
              ),
            if (showScore && item.score != null)
              Text(
                'Score: ${item.score!.toStringAsFixed(3)}',
                style: MayaTheme.labelSmall.copyWith(
                  color: MayaTheme.neonEmerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  Icon(Icons.copy_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Copy'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'copy') {
              await Clipboard.setData(ClipboardData(text: item.content));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                    backgroundColor: MayaTheme.neonEmerald,
                  ),
                );
              }
            } else if (value == 'delete') {
              // TODO: Implement delete when backend supports it
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Delete not yet implemented'),
                    backgroundColor: MayaTheme.neonOrange,
                  ),
                );
              }
            }
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.metadata != null && item.metadata!.isNotEmpty) ...[
                  const Text('Metadata:', style: MayaTheme.labelMedium),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MayaTheme.slate900,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MayaTheme.glassWhite10),
                    ),
                    child: Text(
                      item.metadata.toString(),
                      style: MayaTheme.bodySmall.copyWith(
                          color: Colors.white70, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SelectableText(
                  item.content,
                  style: MayaTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Memory Providers
final memoryListProvider = FutureProvider<MemoryListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getMemoryList();
});

final memoryStatsProvider = FutureProvider<MemoryStatsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getMemoryStats();
});

final memorySearchProvider = FutureProvider<MemorySearchResponse>((ref) async {
  final query = ref.watch(memorySearchTriggerProvider);
  if (query.isEmpty) {
    return MemorySearchResponse(results: [], query: '', count: 0);
  }
  final apiService = ref.read(apiServiceProvider);
  return apiService.searchMemory(query: query);
});

// Helper to trigger search
final memorySearchTriggerProvider = StateProvider<String>((ref) => '');

// Tools & Providers Screen
class _ToolsProvidersScreen extends ConsumerStatefulWidget {
  const _ToolsProvidersScreen();

  @override
  ConsumerState<_ToolsProvidersScreen> createState() => _ToolsProvidersScreenState();
}

class _ToolsProvidersScreenState extends ConsumerState<_ToolsProvidersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(toolsListProvider);
        ref.invalidate(toolsLogsProvider);
        ref.invalidate(providersListProvider);
        ref.invalidate(toolsFrameworkProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Tools & Providers', style: MayaTheme.headlineSmall),
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
                ref.invalidate(toolsListProvider);
                ref.invalidate(toolsLogsProvider);
                ref.invalidate(providersListProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.build_rounded), text: 'Tools'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Logs'),
              Tab(icon: Icon(Icons.policy_rounded), text: 'Policies'),
              Tab(icon: Icon(Icons.cloud_rounded), text: 'Providers'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildToolsTab(),
            _buildLogsTab(),
            _buildPoliciesTab(),
            _buildProvidersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsTab() {
    final toolsAsync = ref.watch(toolsListProvider);

    return toolsAsync.when(
      data: (response) {
        if (response.tools.isEmpty) {
          return const Center(
            child: Text('No tools available', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.tools.length,
          itemBuilder: (context, index) {
            final tool = response.tools[index];
            return _ToolTile(tool: tool);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading tools', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTab() {
    final logsAsync = ref.watch(toolsLogsProvider);

    return logsAsync.when(
      data: (response) {
        if (response.logs.isEmpty) {
          return const Center(
            child: Text('No tool logs yet', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.logs.length,
          itemBuilder: (context, index) {
            final log = response.logs[index];
            return _LogTile(log: log);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading logs', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildPoliciesTab() {
    final frameworkAsync = ref.watch(toolsFrameworkProvider);

    return frameworkAsync.when(
      data: (response) {
        if (response.tools.isEmpty) {
          return const Center(
            child: Text('No managed tools found', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.tools.length,
          itemBuilder: (context, index) {
            final tool = response.tools[index];
            return _PolicyTile(tool: tool);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading policies', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersTab() {
    final providersAsync = ref.watch(providersListProvider);

    return providersAsync.when(
      data: (response) {
        if (response.providers.isEmpty) {
          return const Center(
            child: Text('No providers configured', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.providers.length,
          itemBuilder: (context, index) {
            final provider = response.providers[index];
            return _ProviderTile(provider: provider, onToggle: (enabled) async {
              final success = await ref.read(apiServiceProvider).toggleProvider(provider.id, enabled);
              if (success && mounted) {
                ref.invalidate(providersListProvider);
              }
            });
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading providers', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final ToolInfo tool;

  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.build_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(tool.name, style: MayaTheme.titleMedium),
        subtitle: Text(
          tool.description,
          style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tool.enabled
                ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                : MayaTheme.neonOrange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tool.enabled ? 'Enabled' : 'Disabled',
            style: MayaTheme.labelSmall.copyWith(
              color: tool.enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Category', value: tool.category),
                if (tool.schema != null && tool.schema!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Schema:', style: MayaTheme.labelMedium),
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
                      tool.schema.toString(),
                      style: MayaTheme.bodySmall.copyWith(
                          color: Colors.white70, fontFamily: 'monospace'),
                    ),
                  ),
                ],
                if (tool.metadata != null && tool.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Metadata:', style: MayaTheme.labelMedium),
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
                      tool.metadata.toString(),
                      style: MayaTheme.bodySmall.copyWith(
                          color: Colors.white70, fontFamily: 'monospace'),
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

class _LogTile extends StatelessWidget {
  final ToolLogEntry log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final successRate = log.calls > 0
        ? (log.successes / log.calls * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_rounded, color: MayaTheme.neonViolet, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(log.tool, style: MayaTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$successRate%',
                  style: MayaTheme.labelSmall.copyWith(
                    color: MayaTheme.neonCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _LogStat(label: 'Calls', value: log.calls.toString())),
              Expanded(child: _LogStat(label: 'Success', value: log.successes.toString(), color: MayaTheme.neonEmerald)),
              Expanded(child: _LogStat(label: 'Failed', value: log.failures.toString(), color: MayaTheme.error)),
              Expanded(child: _LogStat(label: 'Avg (ms)', value: (log.avgTime * 1000).toStringAsFixed(1))),
            ],
          ),
          if (log.lastError != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MayaTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MayaTheme.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Last Error: ${log.lastError}',
                style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _LogStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: MayaTheme.titleSmall.copyWith(color: color ?? Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
      ],
    );
  }
}

class _PolicyTile extends StatelessWidget {
  final FrameworkTool tool;

  const _PolicyTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tool.dangerous
                ? MayaTheme.error.withValues(alpha: 0.2)
                : MayaTheme.neonViolet.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            tool.dangerous ? Icons.warning_rounded : Icons.policy_rounded,
            color: tool.dangerous ? MayaTheme.error : MayaTheme.neonViolet,
            size: 20,
          ),
        ),
        title: Text(tool.name, style: MayaTheme.titleMedium),
        subtitle: Text(
          tool.description,
          style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tool.dangerous)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'DANGEROUS',
                  style: MayaTheme.labelSmall.copyWith(
                    color: MayaTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tool.category,
                style: MayaTheme.labelSmall.copyWith(
                  color: MayaTheme.neonCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PolicyStat(
                      label: 'Timeout',
                      value: '${tool.timeoutSeconds}s',
                      icon: Icons.timer_rounded,
                      color: MayaTheme.neonOrange,
                    ),
                    const SizedBox(width: 16),
                    _PolicyStat(
                      label: 'Retries',
                      value: tool.maxRetries.toString(),
                      icon: Icons.refresh_rounded,
                      color: MayaTheme.neonViolet,
                    ),
                    const SizedBox(width: 16),
                    _PolicyStat(
                      label: 'Permission',
                      value: tool.permission,
                      icon: Icons.lock_rounded,
                      color: MayaTheme.neonEmerald,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: MayaTheme.glassWhite10),
                const SizedBox(height: 12),
                const Text('Policy Details', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                _PolicyDetailRow(label: 'Category', value: tool.category),
                _PolicyDetailRow(label: 'Timeout', value: '${tool.timeoutSeconds} seconds'),
                _PolicyDetailRow(label: 'Max Retries', value: tool.maxRetries.toString()),
                _PolicyDetailRow(label: 'Dangerous', value: tool.dangerous ? 'Yes (requires approval)' : 'No'),
                _PolicyDetailRow(label: 'Permission Category', value: tool.permission),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PolicyStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: MayaTheme.titleMedium.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _PolicyDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _PolicyDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: MayaTheme.labelMedium.copyWith(color: Colors.white54)),
          ),
          Expanded(
            child: Text(value, style: MayaTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends ConsumerWidget {
  final ProviderInfo provider;
  final Future<void> Function(bool) onToggle;

  const _ProviderTile({required this.provider, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: provider.active
                  ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                  : (provider.configured
                      ? MayaTheme.neonOrange.withValues(alpha: 0.2)
                      : Colors.white12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              provider.active
                  ? Icons.cloud_done_rounded
                  : (provider.configured ? Icons.cloud_off_rounded : Icons.cloud_queue_rounded),
              color: provider.active
                  ? MayaTheme.neonEmerald
                  : (provider.configured ? MayaTheme.neonOrange : Colors.white38),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(provider.label, style: MayaTheme.titleMedium),
                    const SizedBox(width: 8),
                    Text(
                      '(${provider.id})',
                      style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _ProviderStatusChip(
                      label: provider.configured ? 'Configured' : 'Not Configured',
                      color: provider.configured ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                    ),
                    const SizedBox(width: 8),
                    _ProviderStatusChip(
                      label: provider.enabled ? 'Enabled' : 'Disabled',
                      color: provider.enabled ? MayaTheme.neonCyan : Colors.white38,
                    ),
                    if (provider.errorCount > 0) ...[
                      const SizedBox(width: 8),
                      _ProviderStatusChip(
                        label: 'Errors: ${provider.errorCount}',
                        color: MayaTheme.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: provider.enabled,
            activeColor: MayaTheme.neonCyan,
            onChanged: (value) => onToggle(value),
          ),
        ],
      ),
    );
  }
}

class _ProviderStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ProviderStatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: MayaTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Tools & Providers Providers
final toolsListProvider = FutureProvider<ToolsListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getToolsList();
  return ToolsListResponse(tools: response.tools);
});

final toolsLogsProvider = FutureProvider<ToolsLogsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getToolsLogs();
  return ToolsLogsResponse(logs: response.logs);
});

final toolsFrameworkProvider = FutureProvider<ToolsFrameworkResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getToolsFramework();
});

final providersListProvider = FutureProvider<ProvidersListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getProvidersList();
  return ProvidersListResponse(providers: response.providers);
});

// Brain Engine Screen
class _BrainEngineScreen extends ConsumerStatefulWidget {
  const _BrainEngineScreen();

  @override
  ConsumerState<_BrainEngineScreen> createState() => _BrainEngineScreenState();
}

class _BrainEngineScreenState extends ConsumerState<_BrainEngineScreen> {
  final _goalController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _goalController.text = 'Build a todo app with Flutter';
  }

  @override
  void dispose() {
    _goalController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Brain Engine', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Input Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Goal Analysis', style: MayaTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _goalController,
                      style: MayaTheme.bodyMedium,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter a goal to analyze...',
                        hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                        filled: true,
                        fillColor: MayaTheme.slate700,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _analyzeGoal,
                        icon: const Icon(Icons.psychology_rounded),
                        label: const Text('Analyze Goal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MayaTheme.neonCyan,
                          foregroundColor: MayaTheme.slate900,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Analysis Result
              _buildAnalysisSection(),

              const SizedBox(height: 24),

              // Graph Builder Section
              _buildGraphSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeGoal() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.analyzeGoal(goal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis complete: ${result.complexity} (${result.estimatedSteps} steps)'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _buildGraphFromAnalysis(BrainAnalyzeResponse analysis) async {
    // Convert sub-goals to steps for graph building
    final steps = analysis.subGoals.asMap().entries.map((entry) {
      final index = entry.key;
      final subGoal = entry.value;
      return {
        'description': subGoal,
        'tool': analysis.suggestedTools.isNotEmpty ? analysis.suggestedTools.first : 'llm',
        'depends_on': index > 0 ? [index - 1] : [],
      };
    }).toList();

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.buildGraph(steps);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Graph built from analysis'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Graph build failed: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildAnalysisSection() {
    // We'll use a simple FutureBuilder-like approach with a local state
    return Consumer(
      builder: (context, ref, _) {
        final analysisAsync = ref.watch(brainAnalyzeProvider(_goalController.text.trim()));

        return analysisAsync.when(
          data: (analysis) => _AnalysisResultCard(analysis: analysis, onBuildGraph: () => _buildGraphFromAnalysis(analysis)),
          loading: () => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: MayaTheme.glassCard(),
            child: const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
            ),
          ),
          error: (err, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: MayaTheme.glassCard(),
            child: Column(
              children: [
                const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                const SizedBox(height: 16),
                Text('Analysis error', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                const SizedBox(height: 8),
                Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGraphSection() {
    return Consumer(
      builder: (context, ref, _) {
        // Only show graph if we have analysis
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task Graph', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter a goal above and tap "Analyze Goal" to see the task graph visualization.',
                    style: MayaTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The graph will show:',
                    style: MayaTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  _GraphFeatureRow(icon: Icons.circle_rounded, text: 'Nodes = steps/tasks', color: MayaTheme.neonCyan),
                  _GraphFeatureRow(icon: Icons.arrow_forward_rounded, text: 'Edges = dependencies', color: MayaTheme.neonViolet),
                  _GraphFeatureRow(icon: Icons.color_lens_rounded, text: 'Colors = state (pending/running/done/failed)', color: MayaTheme.neonEmerald),
                  _GraphFeatureRow(icon: Icons.build_rounded, text: 'Tool/agent assignments per node', color: MayaTheme.neonOrange),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnalysisResultCard extends StatelessWidget {
  final BrainAnalyzeResponse analysis;
  final VoidCallback onBuildGraph;

  const _AnalysisResultCard({required this.analysis, required this.onBuildGraph});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MayaTheme.slate800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: MayaTheme.neonCyan, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(analysis.goal, style: MayaTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _AnalysisChip(
                            label: analysis.complexity.toUpperCase(),
                            color: analysis.complexity == 'multi_step' ? MayaTheme.neonOrange : MayaTheme.neonEmerald,
                          ),
                          const SizedBox(width: 8),
                          _AnalysisChip(
                            label: '${analysis.estimatedSteps} steps',
                            color: MayaTheme.neonViolet,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Suggested Tools
          if (analysis.suggestedTools.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Suggested Tools', style: MayaTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: analysis.suggestedTools.map((tool) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: MayaTheme.neonCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
                      ),
                      child: Text(tool, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],

          // Sub Goals
          if (analysis.subGoals.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sub-goals', style: MayaTheme.labelMedium),
                      TextButton.icon(
                        onPressed: onBuildGraph,
                        icon: const Icon(Icons.account_tree_rounded, size: 16),
                        label: const Text('Build Graph'),
                        style: TextButton.styleFrom(foregroundColor: MayaTheme.neonCyan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...analysis.subGoals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final subGoal = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MayaTheme.slate700,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MayaTheme.glassWhite10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${index + 1}', style: MayaTheme.labelMedium.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(subGoal, style: MayaTheme.bodyMedium),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Build Graph Button
          if (analysis.subGoals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onBuildGraph,
                  icon: const Icon(Icons.account_tree_rounded),
                  label: const Text('Build Task Graph from Analysis'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MayaTheme.neonCyan,
                    side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalysisChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AnalysisChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: MayaTheme.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _GraphFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _GraphFeatureRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: MayaTheme.bodyMedium),
        ],
      ),
    );
  }
}

// Brain Engine Provider (depends on goal text)
final brainAnalyzeProvider = FutureProvider.family<BrainAnalyzeResponse, String>((ref, goal) async {
  if (goal.isEmpty) {
    throw Exception('Empty goal');
  }
  final apiService = ref.read(apiServiceProvider);
  return apiService.analyzeGoal(goal);
});

// Multi-Agent System Screen
class _AgentsScreen extends ConsumerStatefulWidget {
  const _AgentsScreen();

  @override
  ConsumerState<_AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<_AgentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(agentsListProvider);
        ref.invalidate(agentsMessagesProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Multi-Agent System', style: MayaTheme.headlineSmall),
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
                ref.invalidate(agentsListProvider);
                ref.invalidate(agentsMessagesProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.people_rounded), text: 'Agents'),
              Tab(icon: Icon(Icons.account_tree_rounded), text: 'Orchestration'),
              Tab(icon: Icon(Icons.message_rounded), text: 'Messages'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAgentsTab(),
            _buildOrchestrationTab(),
            _buildMessagesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentsTab() {
    final agentsAsync = ref.watch(agentsListProvider);

    return agentsAsync.when(
      data: (response) {
        if (response.agents.isEmpty) {
          return const Center(
            child: Text('No agents found', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.agents.length,
          itemBuilder: (context, index) {
            final agent = response.agents[index];
            return _AgentTile(agent: agent);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading agents', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrchestrationTab() {
    final agentsAsync = ref.watch(agentsListProvider);
    final _goalController = TextEditingController(text: 'Build a todo app with Flutter');

    return agentsAsync.when(
      data: (response) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Orchestrate Goal', style: MayaTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _goalController,
                      style: MayaTheme.bodyMedium,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter a goal to orchestrate across agents...',
                        hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                        filled: true,
                        fillColor: MayaTheme.slate700,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _orchestrateGoal(_goalController.text.trim()),
                        icon: const Icon(Icons.psychology_rounded),
                        label: const Text('Plan & Assign'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MayaTheme.neonCyan,
                          foregroundColor: MayaTheme.slate900,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Orchestration Result
              Consumer(
                builder: (context, ref, _) {
                  final orchestrationAsync = ref.watch(agentsOrchestrateProvider);

                  return orchestrationAsync.when(
                    data: (result) => _OrchestrationResultCard(result: result),
                    loading: () => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: MayaTheme.glassCard(),
                      child: const Center(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                      ),
                    ),
                    error: (err, _) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: MayaTheme.glassCard(),
                      child: Column(
                        children: [
                          const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                          const SizedBox(height: 16),
                          Text('Orchestration error', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                          const SizedBox(height: 8),
                          Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Available Agents Reference
              const Text('Available Agents', style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              ...response.agents.map((agent) => _AgentReferenceTile(agent: agent)),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading agents', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    final messagesAsync = ref.watch(agentsMessagesProvider);

    return messagesAsync.when(
      data: (response) {
        if (response.messages.isEmpty) {
          return const Center(
            child: Text('No messages yet', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.messages.length,
          itemBuilder: (context, index) {
            final msg = response.messages[index];
            return _MessageTile(message: msg);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading messages', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Future<void> _orchestrateGoal(String goal) async {
    if (goal.isEmpty) return;
    ref.invalidate(agentsOrchestrateProvider);
    // The provider will auto-fetch when we invalidate
    // We just need to trigger it by watching with the goal
    // Using a workaround: set a state provider for the goal
    ref.read(agentsOrchestrateGoalProvider.notifier).state = goal;
  }
}

class _AgentTile extends ConsumerWidget {
  final AgentInfo agent;

  const _AgentTile({required this.agent});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'healthy':
        return MayaTheme.neonEmerald;
      case 'degraded':
        return MayaTheme.neonOrange;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHealthy = agent.status == 'healthy';
    final totalTasks = agent.ok + agent.errors;
    final lastActive = agent.lastActive != null
        ? DateTime.fromMillisecondsSinceEpoch((agent.lastActive! * 1000).round())
            .toString()
            .substring(11, 19)
        : 'Never';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(agent.status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: _getStatusColor(agent.status),
            size: 20,
          ),
        ),
        title: Text(agent.name, style: MayaTheme.titleMedium),
        subtitle: Text(
          agent.role,
          style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(agent.status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            agent.status.toUpperCase(),
            style: MayaTheme.labelSmall.copyWith(
              color: _getStatusColor(agent.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Role', value: agent.role),
                _DetailRow(label: 'Success/Errors', value: '${agent.ok} / ${agent.errors}'),
                if (agent.successRate != null)
                  _DetailRow(label: 'Success Rate', value: '${(agent.successRate! * 100).toStringAsFixed(1)}%'),
                _DetailRow(label: 'Last Active', value: lastActive),
                if (agent.lastError != null) ...[
                  const SizedBox(height: 8),
                  const Text('Last Error:', style: MayaTheme.labelMedium),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MayaTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MayaTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(agent.lastError!, style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error)),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Skills:', style: MayaTheme.labelMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: agent.skills.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MayaTheme.neonViolet.withValues(alpha: 0.3)),
                    ),
                    child: Text(skill, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Permissions:', style: MayaTheme.labelMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: agent.permissions.map((perm) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
                    ),
                    child: Text(perm, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentReferenceTile extends StatelessWidget {
  final AgentInfo agent;

  const _AgentReferenceTile({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                agent.name.substring(0, 1).toUpperCase(),
                style: MayaTheme.titleMedium.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.name, style: MayaTheme.titleSmall),
                Text(agent.role, style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          Wrap(
            spacing: 4,
            children: agent.skills.take(3).map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _OrchestrationResultCard extends StatelessWidget {
  final AgentsOrchestrateResponse result;

  const _OrchestrationResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final analysis = result.analysis;
    final assignments = result.assignments;
    final graph = result.graph;

    return Container(
      width: double.infinity,
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MayaTheme.slate800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_tree_rounded, color: MayaTheme.neonCyan, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Orchestration Plan', style: MayaTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Goal: ${analysis.goal}',
                            style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Analysis Summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AnalysisChip(label: analysis.complexity.toUpperCase(), color: analysis.complexity == 'multi_step' ? MayaTheme.neonOrange : MayaTheme.neonEmerald),
                    const SizedBox(width: 8),
                    _AnalysisChip(label: '${analysis.estimatedSteps} steps', color: MayaTheme.neonViolet),
                    const SizedBox(width: 8),
                    _AnalysisChip(label: '${graph.nodes.length} nodes', color: MayaTheme.neonCyan),
                  ],
                ),
                if (analysis.suggestedTools.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Suggested Tools:', style: MayaTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: analysis.suggestedTools.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MayaTheme.neonCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
                      ),
                      child: Text(t, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Assignments
          if (assignments.isNotEmpty) ...[
            const Divider(color: MayaTheme.glassWhite10, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Agent Assignments', style: MayaTheme.labelMedium),
                  const SizedBox(height: 8),
                  ...assignments.entries.map((entry) {
                    final nodeId = entry.key;
                    final agentName = entry.value;
                    final node = graph.nodes.firstWhere((n) => n.id == nodeId, orElse: () => null);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MayaTheme.slate700,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MayaTheme.glassWhite10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: agentName.isNotEmpty ? MayaTheme.neonEmerald.withValues(alpha: 0.2) : MayaTheme.neonOrange.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                agentName.isNotEmpty ? agentName.substring(0, 1).toUpperCase() : '?',
                                style: MayaTheme.labelMedium.copyWith(
                                  color: agentName.isNotEmpty ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agentName.isNotEmpty ? agentName : 'Unassigned',
                                  style: MayaTheme.titleSmall,
                                ),
                                if (node != null)
                                  Text(
                                    node.description,
                                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (node?.tool != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(node!.tool!, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Graph Progress
          const Divider(color: MayaTheme.glassWhite10, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Graph Progress', style: MayaTheme.labelMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MayaTheme.slate700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ProgressStat(label: 'Total', value: graph.progress.total.toString(), color: MayaTheme.neonCyan),
                          _ProgressStat(label: 'Done', value: graph.progress.states['done']?.toString() ?? '0', color: MayaTheme.neonEmerald),
                          _ProgressStat(label: 'Running', value: graph.progress.states['running']?.toString() ?? '0', color: MayaTheme.neonViolet),
                          _ProgressStat(label: 'Failed', value: graph.progress.states['failed']?.toString() ?? '0', color: MayaTheme.error),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: graph.progress.percent / 100,
                        backgroundColor: MayaTheme.slate900,
                        valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${graph.progress.percent.toStringAsFixed(1)}% complete',
                        style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                      ),
                    ],
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

class _AnalysisChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AnalysisChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: MayaTheme.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProgressStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: MayaTheme.headlineSmall.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
      ],
    );
  }
}

class _MessageTile extends StatelessWidget {
  final AgentMessage message;

  const _MessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch((message.ts * 1000).round())
        .toString()
        .substring(11, 19);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.message_rounded, color: MayaTheme.neonCyan, size: 18),
              ),
              const SizedBox(width: 12),
              Text(message.from, style: MayaTheme.titleSmall),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white38),
              const SizedBox(width: 8),
              Text(message.to, style: MayaTheme.titleSmall),
              const Spacer(),
              Text(time, style: MayaTheme.labelSmall.copyWith(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MayaTheme.slate700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.content.toString(),
              style: MayaTheme.bodySmall.copyWith(color: Colors.white70, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

// Multi-Agent Providers
final agentsListProvider = FutureProvider<AgentsListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAgentsList();
});

final agentsOrchestrateGoalProvider = StateProvider<String>((ref) => '');

final agentsOrchestrateProvider = FutureProvider<AgentsOrchestrateResponse>((ref) async {
  final goal = ref.watch(agentsOrchestrateGoalProvider);
  if (goal.isEmpty) {
    throw Exception('Empty goal');
  }
  final apiService = ref.read(apiServiceProvider);
  return apiService.orchestrateGoal(goal);
});

final agentsMessagesProvider = FutureProvider<AgentsMessagesResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAgentsMessages();
});

// Workflow Engine Screen
class _WorkflowEngineScreen extends ConsumerStatefulWidget {
  const _WorkflowEngineScreen();

  @override
  ConsumerState<_WorkflowEngineScreen> createState() => _WorkflowEngineScreenState();
}

class _WorkflowEngineScreenState extends ConsumerState<_WorkflowEngineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  final _goalController = TextEditingController(text: 'Build a REST API with FastAPI');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(workflowsRunsProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Workflow Engine', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(workflowsRunsProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.list_rounded), text: 'Runs'),
              Tab(icon: Icon(Icons.add_rounded), text: 'New Workflow'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRunsTab(),
            _buildNewWorkflowTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRunsTab() {
    final runsAsync = ref.watch(workflowsRunsProvider);

    return runsAsync.when(
      data: (response) {
        if (response.checkpoints.isEmpty) {
          return const Center(
            child: Text('No workflow runs yet', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.checkpoints.length,
          itemBuilder: (context, index) {
            final runId = response.checkpoints[index];
            return _WorkflowRunTile(runId: runId);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading runs', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildNewWorkflowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create New Workflow', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _goalController,
                  style: MayaTheme.bodyMedium,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the goal for the workflow...',
                    hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createWorkflow,
                    icon: const Icon(Icons.psychology_rounded),
                    label: const Text('Plan Workflow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Consumer(
            builder: (context, ref, _) {
              final planAsync = ref.watch(workflowPlanProvider(_goalController.text.trim()));

              return planAsync.when(
                data: (plan) => _WorkflowPlanCard(plan: plan),
                loading: () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: MayaTheme.glassCard(),
                  child: const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                  ),
                ),
                error: (err, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    children: [
                      const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                      const SizedBox(height: 16),
                      Text('Planning error', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                      const SizedBox(height: 8),
                      Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createWorkflow() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;

    ref.read(workflowPlanGoalProvider.notifier).state = goal;
    await Future.delayed(const Duration(milliseconds: 100));
    ref.invalidate(workflowPlanProvider(goal));
  }
}

class _WorkflowRunTile extends ConsumerWidget {
  final String runId;

  const _WorkflowRunTile({required this.runId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runAsync = ref.watch(workflowRunProvider(runId));

    return runAsync.when(
      data: (run) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: MayaTheme.glassCard(),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(run.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(run.status),
              color: _getStatusColor(run.status),
              size: 20,
            ),
          ),
          title: Text(run.goal, style: MayaTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            'Run ID: ${run.id.substring(0, 12)}...',
            style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(run.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  run.status.toUpperCase(),
                  style: MayaTheme.labelSmall.copyWith(
                    color: _getStatusColor(run.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                itemBuilder: (context) => [
                  if (run.status == 'pending' || run.status == 'running')
                    const PopupMenuItem(
                      value: 'execute',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Execute'),
                        ],
                      ),
                    ),
                  if (run.status == 'running' || run.status == 'pending')
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded, size: 18, color: MayaTheme.error),
                          SizedBox(width: 8),
                          Text('Cancel', style: TextStyle(color: MayaTheme.error)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'execute') {
                    await _executeRun(run.id, ref, context);
                  } else if (value == 'cancel') {
                    await _cancelRun(run.id, ref, context);
                  } else if (value == 'refresh') {
                    ref.invalidate(workflowsRunsProvider);
                    ref.invalidate(workflowRunProvider(run.id));
                  }
                },
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Run ID', value: run.id),
                  _DetailRow(label: 'Goal', value: run.goal),
                  _DetailRow(label: 'Status', value: run.status),
                  _DetailRow(label: 'Created', value: DateTime.fromMillisecondsSinceEpoch((run.created * 1000).round()).toString()),
                  _DetailRow(label: 'Steps', value: '${run.nodes.length}'),
                  const SizedBox(height: 12),
                  const Text('Steps / Checkpoints', style: MayaTheme.labelMedium),
                  const SizedBox(height: 8),
                  ...run.nodes.map((node) => _WorkflowNodeTile(node: node)),
                  if (run.recoveryLog != null && run.recoveryLog!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Recovery Log', style: MayaTheme.labelMedium),
                    const SizedBox(height: 8),
                    ...run.recoveryLog!.map((entry) => _RecoveryLogTile(entry: entry)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: MayaTheme.glassCard(),
        child: const ListTile(
          leading: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
          title: Text('Loading...'),
        ),
      ),
      error: (err, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: MayaTheme.glassCard(),
        child: ListTile(
          leading: const Icon(Icons.error_rounded, color: MayaTheme.error),
          title: Text('Error loading run', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          subtitle: Text(err.toString(), style: MayaTheme.bodySmall),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return MayaTheme.neonEmerald;
      case 'running':
        return MayaTheme.neonCyan;
      case 'pending':
        return MayaTheme.neonOrange;
      case 'failed':
        return MayaTheme.error;
      case 'cancelled':
        return Colors.white38;
      default:
        return Colors.white54;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'running':
        return Icons.play_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'failed':
        return Icons.error_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Future<void> _executeRun(String runId, WidgetRef ref, BuildContext context) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.executeWorkflowRun(runId);
      if (mounted) {
        ref.invalidate(workflowsRunsProvider);
        ref.invalidate(workflowRunProvider(runId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow executed: ${result.status}'),
            backgroundColor: result.status == 'completed' ? MayaTheme.neonEmerald : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Execution failed: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelRun(String runId, WidgetRef ref, BuildContext context) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final success = await apiService.cancelWorkflowRun(runId);
      if (success && mounted) {
        ref.invalidate(workflowsRunsProvider);
        ref.invalidate(workflowRunProvider(runId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow cancelled'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancel failed'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancel error: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }
}

class _WorkflowNodeTile extends StatelessWidget {
  final WorkflowNode node;

  const _WorkflowNodeTile({required this.node});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'done':
        return MayaTheme.neonEmerald;
      case 'running':
        return MayaTheme.neonCyan;
      case 'pending':
        return MayaTheme.neonOrange;
      case 'failed':
        return MayaTheme.error;
      case 'blocked':
        return MayaTheme.neonViolet;
      case 'skipped':
        return Colors.white38;
      default:
        return Colors.white54;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'done':
        return Icons.check_circle_rounded;
      case 'running':
        return Icons.play_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'failed':
        return Icons.error_rounded;
      case 'blocked':
        return Icons.block_rounded;
      case 'skipped':
        return Icons.skip_next_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MayaTheme.slate700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MayaTheme.glassWhite10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _getStatusColor(node.state).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(_getStatusIcon(node.state), color: _getStatusColor(node.state), size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.description, style: MayaTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (node.tool != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(node.tool!, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (node.agent != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MayaTheme.neonEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(node.agent!, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonEmerald)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (node.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MayaTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(node.error!, style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error)),
            ),
        ],
      ),
    );
  }
}

class _RecoveryLogTile extends StatelessWidget {
  final dynamic entry;

  const _RecoveryLogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MayaTheme.slate700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MayaTheme.glassWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Node: ${entry['node'] ?? 'unknown'}', style: MayaTheme.labelMedium),
          const SizedBox(height: 4),
          Text('Strategy: ${entry['strategy'] ?? 'unknown'}', style: MayaTheme.bodySmall),
          if (entry['reflection'] != null) ...[
            const SizedBox(height: 4),
            Text('Reflection: ${entry['reflection']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          ],
        ],
      ),
    );
  }
}

class _WorkflowPlanCard extends StatelessWidget {
  final WorkflowPlanResponse plan;

  const _WorkflowPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final state = plan.state;
    final goal = state['goal'] ?? 'Unknown goal';
    final nodes = state['nodes'] as List? ?? [];

    return Container(
      width: double.infinity,
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MayaTheme.slate800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: MayaTheme.neonCyan, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal, style: MayaTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _AnalysisChip(label: '${nodes.length} steps', color: MayaTheme.neonViolet),
                          const SizedBox(width: 8),
                          _AnalysisChip(label: 'Planned', color: MayaTheme.neonEmerald),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nodes
          if (nodes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Planned Steps', style: MayaTheme.labelMedium),
                  const SizedBox(height: 8),
                  ...nodes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final node = entry.value as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MayaTheme.slate700,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MayaTheme.glassWhite10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${index + 1}', style: MayaTheme.labelMedium.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(node['description'] ?? '', style: MayaTheme.bodyMedium),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (node['tool'] != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(node['tool'], style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    if (node['agent'] != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: MayaTheme.neonEmerald.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(node['agent'], style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonEmerald)),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to run detail
                    },
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('View Run'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MayaTheme.neonCyan,
                      side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Execute workflow
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Execute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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

class _AnalysisChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AnalysisChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: MayaTheme.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Workflow Engine Providers
final workflowsRunsProvider = FutureProvider<WorkflowsRunsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getWorkflowsRuns();
});

final workflowPlanGoalProvider = StateProvider<String>((ref) => '');

final workflowPlanProvider = FutureProvider.family<WorkflowPlanResponse, String>((ref, goal) async {
  if (goal.isEmpty) {
    throw Exception('Empty goal');
  }
  final apiService = ref.read(apiServiceProvider);
  return apiService.planWorkflow(goal);
});

final workflowRunProvider = FutureProvider.family<WorkflowRunState, String>((ref, runId) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getWorkflowRun(runId);
});

// Autonomous Mode Screen
class _AutonomousModeScreen extends ConsumerStatefulWidget {
  const _AutonomousModeScreen();

  @override
  ConsumerState<_AutonomousModeScreen> createState() => _AutonomousModeScreenState();
}

class _AutonomousModeScreenState extends ConsumerState<_AutonomousModeScreen> {
  Timer? _refreshTimer;
  bool _isRunning = false;
  String _currentGoal = '';
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.invalidate(autonomousStatusProvider);
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
    final statusAsync = ref.watch(autonomousStatusProvider);
    final flagsAsync = ref.watch(flagsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Autonomous Mode', style: MayaTheme.headlineSmall),
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
                ref.invalidate(autonomousStatusProvider);
                ref.invalidate(flagsProvider);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Safety Warning Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MayaTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MayaTheme.error.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: MayaTheme.error, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '⚠️ Autonomous Mode executes goals without step-by-step approval. Maya will plan, use tools, and iterate automatically. Ensure you trust the goal and have set appropriate limits.',
                            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Main Toggle
              _buildMainToggle(),

              const SizedBox(height: 24),

              // Permissions & Scope
              _buildPermissionsSection(flagsAsync),

              const SizedBox(height: 24),

              // Live Status (if running)
              _buildLiveStatus(statusAsync),

              const SizedBox(height: 24),

              // Run Autonomous Goal
              _buildRunSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: MayaTheme.glassCardGlow(glowColor: MayaTheme.neonCyan),
      child: Column(
        children: [
          const Text('Autonomous Mode', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'When enabled, Maya can execute goals end-to-end without manual approval for each step.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, _) {
              final flags = ref.watch(flagsProvider);
              final isEnabled = flags.valueOrNull?.flags['autonomous'] ?? false;

              return Switch(
                value: isEnabled,
                activeColor: MayaTheme.neonCyan,
                activeTrackColor: MayaTheme.neonCyan.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white12,
                thumbIcon: MaterialStateProperty.resolveWith<Icon?>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Icon(Icons.check_rounded, color: MayaTheme.slate900, size: 18);
                  }
                  return const Icon(Icons.close_rounded, color: Colors.white38, size: 18);
                }),
                onChanged: (value) => _showSafetyDialog(value),
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, _) {
              final flags = ref.watch(flagsProvider);
              final isEnabled = flags.valueOrNull?.flags['autonomous'] ?? false;
              return Text(
                isEnabled ? 'ENABLED — Maya runs autonomously' : 'DISABLED — Manual approval required',
                style: MayaTheme.bodyMedium.copyWith(
                  color: isEnabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSafetyDialog(bool newValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: Row(
          children: [
            Icon(newValue ? Icons.warning_amber_rounded : Icons.info_rounded, color: newValue ? MayaTheme.error : MayaTheme.neonCyan),
            const SizedBox(width: 8),
            Text(newValue ? 'Enable Autonomous Mode?' : 'Disable Autonomous Mode?', style: MayaTheme.headlineSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newValue
                  ? 'Maya will execute goals autonomously. This means:\n'
                    '• Maya plans and decomposes goals\n'
                    '• Maya selects and uses tools automatically\n'
                    '• Maya iterates on failures without asking\n'
                    '• Dangerous tools require approve_dangerous flag\n\n'
                    'Ensure you have set FLAG_AUTONOMOUS=true on the server.'
                  : 'Maya will require manual approval for each step.',
              style: MayaTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text('Are you sure you want to continue?', style: MayaTheme.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _toggleAutonomousMode(newValue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newValue ? MayaTheme.error : MayaTheme.neonCyan,
              foregroundColor: newValue ? Colors.white : MayaTheme.slate900,
            ),
            child: Text(newValue ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAutonomousMode(bool enabled) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final success = await apiService.toggleProvider('autonomous', enabled);
      if (success && mounted) {
        ref.invalidate(flagsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Autonomous mode enabled' : 'Autonomous mode disabled'),
            backgroundColor: enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildPermissionsSection(AsyncValue<FlagsSnapshot> flagsAsync) {
    return flagsAsync.when(
      data: (flags) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: MayaTheme.glassCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Permissions & Scope', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            _PermissionRow(
              label: 'Autonomous Execution',
              enabled: flags.flags['autonomous'] ?? false,
              description: 'Maya can run goals end-to-end',
            ),
            _PermissionRow(
              label: 'Tool Execution',
              enabled: flags.flags['tool_execute'] ?? false,
              description: 'Remote tool execution allowed',
            ),
            _PermissionRow(
              label: 'Cognition Autorun',
              enabled: flags.flags['cognition_autorun'] ?? false,
              description: 'Cognitive cycles execute (not just propose)',
            ),
            _PermissionRow(
              label: 'Deploy Pipeline',
              enabled: flags.flags['deploy_pipeline_enabled'] ?? false,
              description: 'Build → Deploy pipeline active',
            ),
            _PermissionRow(
              label: 'App Monitor',
              enabled: flags.flags['app_monitor_enabled'] ?? false,
              description: 'Remote app health monitoring',
            ),
            _PermissionRow(
              label: 'Research Engine',
              enabled: flags.flags['research_engine_enabled'] ?? false,
              description: 'Web research & analysis enabled',
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildLiveStatus(AsyncValue<dynamic> statusAsync) {
    return statusAsync.when(
      data: (status) {
        if (!_isRunning && _currentGoal.isEmpty) {
          return const SizedBox();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isRunning ? MayaTheme.neonCyan.withValues(alpha: 0.15) : MayaTheme.neonEmerald.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isRunning ? MayaTheme.neonCyan.withValues(alpha: 0.5) : MayaTheme.neonEmerald.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isRunning ? Icons.play_circle_rounded : Icons.check_circle_rounded,
                    color: _isRunning ? MayaTheme.neonCyan : MayaTheme.neonEmerald,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isRunning ? 'Autonomous Run Active' : 'Last Run Completed',
                    style: MayaTheme.titleMedium.copyWith(
                      color: _isRunning ? MayaTheme.neonCyan : MayaTheme.neonEmerald,
                    ),
                  ),
                  const Spacer(),
                  if (_isRunning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_currentGoal.isNotEmpty) ...[
                Text('Goal: $_currentGoal', style: MayaTheme.bodyMedium),
                const SizedBox(height: 4),
              ],
              if (_currentStatus.isNotEmpty)
                Text('Status: $_currentStatus', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildRunSection() {
    final _goalController = TextEditingController(text: 'Build a REST API with FastAPI');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Run Autonomous Goal', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            style: MayaTheme.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter a goal for autonomous execution...',
              hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _runAutonomous(_goalController.text.trim()),
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: const Text('Run Autonomously'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonCyan,
                    foregroundColor: MayaTheme.slate900,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _runAutonomous(_goalController.text.trim(), approveDangerous: true),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Run (Dangerous)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MayaTheme.error,
                    side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '⚠️ Normal run: dangerous tools blocked. Dangerous run: approve_dangerous=true',
            style: MayaTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _runAutonomous(String goal, {bool approveDangerous = false}) async {
    if (goal.isEmpty) return;

    setState(() {
      _isRunning = true;
      _currentGoal = goal;
      _currentStatus = 'Starting...';
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.runAutonomous(
        goal: goal,
        approveDangerous: approveDangerous,
      );

      if (mounted) {
        setState(() {
          _isRunning = false;
          _currentStatus = result.status;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Autonomous run: ${result.status}'),
            backgroundColor: result.status == 'completed' ? MayaTheme.neonEmerald : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _currentStatus = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Autonomous run failed: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final String description;

  const _PermissionRow({
    required this.label,
    required this.enabled,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: enabled
                  ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                  : MayaTheme.neonOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                enabled ? Icons.check_rounded : Icons.close_rounded,
                color: enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: MayaTheme.bodyMedium),
                Text(description, style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Autonomous Mode Provider
final autonomousStatusProvider = FutureProvider<dynamic>((ref) async {
  // This would check if there's an active autonomous run
  // For now, return empty since backend doesn't have a status endpoint
  return {};
});

// Multi-Model Router Screen
class _RouterScreen extends ConsumerStatefulWidget {
  const _RouterScreen();

  @override
  ConsumerState<_RouterScreen> createState() => _RouterScreenState();
}

class _RouterScreenState extends ConsumerState<_RouterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  String _selectedStrategy = 'balanced';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        ref.invalidate(llmProvidersProvider);
        ref.invalidate(llmStatsProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Multi-Model Router', style: MayaTheme.headlineSmall),
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
                ref.invalidate(llmProvidersProvider);
                ref.invalidate(llmStatsProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.cloud_rounded), text: 'Providers'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Stats'),
              Tab(icon: Icon(Icons.tune_rounded), text: 'Strategy'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProvidersTab(),
            _buildStatsTab(),
            _buildStrategyTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersTab() {
    final providersAsync = ref.watch(llmProvidersProvider);

    return providersAsync.when(
      data: (response) {
        if (response.providers.isEmpty) {
          return const Center(
            child: Text('No providers configured', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.providers.length,
          itemBuilder: (context, index) {
            final provider = response.providers[index];
            return _ProviderTile(
              provider: provider,
              onToggle: (enabled) async {
                final success = await ref.read(apiServiceProvider).toggleLLMProvider(provider.id, enabled);
                if (success && mounted) {
                  ref.invalidate(llmProvidersProvider);
                }
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading providers', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final statsAsync = ref.watch(llmStatsProvider);

    return statsAsync.when(
      data: (stats) {
        if (stats.stats.isEmpty) {
          return const Center(
            child: Text('No stats available yet', style: MayaTheme.bodyMedium),
          );
        }

        // Combine stats with table info
        final entries = stats.stats.entries.toList()
          ..sort((a, b) => b.value.ok.compareTo(a.value.ok));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Live Provider Stats', style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final providerId = entry.key;
                  final stat = entry.value;
                  final tableInfo = stats.table[providerId] ?? {};
                  final cost = tableInfo['cost'] ?? 0.0;
                  final quality = tableInfo['quality'] ?? 0.0;

                  return _StatTile(
                    providerId: providerId,
                    latency: stat.latencyEmaS,
                    ok: stat.ok,
                    errors: stat.errors,
                    errorRate: stat.errorRate,
                    cost: cost.toDouble(),
                    quality: quality.toDouble(),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Provider Cost/Quality Reference', style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              _buildReferenceTable(stats.table),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading stats', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceTable(Map<String, Map<String, dynamic>> table) {
    final entries = table.entries.toList()
      ..sort((a, b) => (a.value['cost'] ?? 0.0).compareTo(b.value['cost'] ?? 0.0));

    return Container(
      decoration: MayaTheme.glassCard(),
      child: Column(
        children: [
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
                Expanded(flex: 2, child: Text('Provider', style: MayaTheme.labelMedium)),
                Expanded(flex: 1, child: Text('Cost ($/1M)', style: MayaTheme.labelMedium, textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('Quality (0-1)', style: MayaTheme.labelMedium, textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...entries.map((entry) {
            final cost = entry.value['cost'] ?? 0.0;
            final quality = entry.value['quality'] ?? 0.0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: MayaTheme.glassWhite10)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(entry.key, style: MayaTheme.bodyMedium)),
                  Expanded(flex: 1, child: Text('\$${cost.toStringAsFixed(2)}', style: MayaTheme.bodyMedium, textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text(quality.toStringAsFixed(2), style: MayaTheme.bodyMedium, textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStrategyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Routing Strategy', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Choose how Maya selects the best model for each task. The strategy determines the priority order of providers.',
                  style: MayaTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStrategy,
                  dropdownColor: MayaTheme.slate800,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Strategy',
                    labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'balanced', child: Text('Balanced (quality per $, tempered by latency)')),
                    DropdownMenuItem(value: 'cost', child: Text('Cost (cheapest first)')),
                    DropdownMenuItem(value: 'latency', child: Text('Latency (fastest first)')),
                    DropdownMenuItem(value: 'quality', child: Text('Quality (best quality first)')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStrategy = value ?? 'balanced');
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => ref.invalidate(llmStrategyProvider(_selectedStrategy)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Preview Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Consumer(
            builder: (context, ref, _) {
              final strategyAsync = ref.watch(llmStrategyProvider(_selectedStrategy));

              return strategyAsync.when(
                data: (result) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_tree_rounded, color: MayaTheme.neonViolet, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Strategy: ${result.strategy}', style: MayaTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text('Provider order (1st → last)', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...result.order.asMap().entries.map((entry) {
                        final index = entry.key;
                        final provider = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MayaTheme.slate700,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: MayaTheme.glassWhite10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${index + 1}', style: MayaTheme.labelMedium.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(provider, style: MayaTheme.bodyMedium),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                loading: () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: MayaTheme.glassCard(),
                  child: const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                  ),
                ),
                error: (err, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    children: [
                      const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                      const SizedBox(height: 16),
                      Text('Error loading strategy', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                      const SizedBox(height: 8),
                      Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Strategy explanation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Strategy Details', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                _StrategyInfoRow(
                  title: 'Balanced',
                  desc: 'Optimizes quality per dollar, tempered by observed latency. Best for general use.',
                ),
                _StrategyInfoRow(
                  title: 'Cost',
                  desc: 'Prioritizes cheapest providers first. Good for high-volume, cost-sensitive tasks.',
                ),
                _StrategyInfoRow(
                  title: 'Latency',
                  desc: 'Prioritizes fastest providers first. Good for real-time interactive tasks.',
                ),
                _StrategyInfoRow(
                  title: 'Quality',
                  desc: 'Prioritizes highest quality providers first. Good for complex reasoning tasks.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends ConsumerWidget {
  final LLMProviderInfo provider;
  final Future<void> Function(bool) onToggle;

  const _ProviderTile({required this.provider, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: provider.active
                  ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                  : (provider.configured
                      ? MayaTheme.neonOrange.withValues(alpha: 0.2)
                      : Colors.white12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              provider.active
                  ? Icons.cloud_done_rounded
                  : (provider.configured ? Icons.cloud_off_rounded : Icons.cloud_queue_rounded),
              color: provider.active
                  ? MayaTheme.neonEmerald
                  : (provider.configured ? MayaTheme.neonOrange : Colors.white38),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(provider.label, style: MayaTheme.titleMedium),
                    const SizedBox(width: 8),
                    Text(
                      '(${provider.id})',
                      style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _ProviderStatusChip(
                      label: provider.configured ? 'Configured' : 'Not Configured',
                      color: provider.configured ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                    ),
                    const SizedBox(width: 8),
                    _ProviderStatusChip(
                      label: provider.enabled ? 'Enabled' : 'Disabled',
                      color: provider.enabled ? MayaTheme.neonCyan : Colors.white38,
                    ),
                    if (provider.errorCount > 0) ...[
                      const SizedBox(width: 8),
                      _ProviderStatusChip(
                        label: 'Errors: ${provider.errorCount}',
                        color: MayaTheme.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: provider.enabled,
            activeColor: MayaTheme.neonCyan,
            onChanged: (value) => onToggle(value),
          ),
        ],
      ),
    );
  }
}

class _ProviderStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ProviderStatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: MayaTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String providerId;
  final double latency;
  final int ok;
  final int errors;
  final double errorRate;
  final double cost;
  final double quality;

  const _StatTile({
    required this.providerId,
    required this.latency,
    required this.ok,
    required this.errors,
    required this.errorRate,
    required this.cost,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(providerId, style: MayaTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (cost <= 0.5 ? MayaTheme.neonEmerald : (cost <= 1.0 ? MayaTheme.neonOrange : MayaTheme.error)).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${cost.toStringAsFixed(2)}/1M',
                  style: MayaTheme.labelSmall.copyWith(
                    color: cost <= 0.5 ? MayaTheme.neonEmerald : (cost <= 1.0 ? MayaTheme.neonOrange : MayaTheme.error),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatItem(label: 'Latency (EMA)', value: '${latency.toStringAsFixed(2)}s', icon: Icons.speed_rounded, color: MayaTheme.neonCyan)),
              Expanded(child: _StatItem(label: 'Success', value: ok.toString(), icon: Icons.check_circle_rounded, color: MayaTheme.neonEmerald)),
              Expanded(child: _StatItem(label: 'Errors', value: errors.toString(), icon: Icons.error_rounded, color: MayaTheme.error)),
              Expanded(child: _StatItem(label: 'Error Rate', value: '${(errorRate * 100).toStringAsFixed(1)}%', icon: Icons.percent_rounded, color: errorRate > 0.3 ? MayaTheme.error : MayaTheme.neonEmerald)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatItem(label: 'Quality', value: quality.toStringAsFixed(2), icon: Icons.star_rounded, color: MayaTheme.neonViolet)),
              const SizedBox(width: 16),
              Expanded(child: _StatItem(label: 'Cost/Quality', value: (cost > 0 ? (quality / cost).toStringAsFixed(2) : 'N/A'), icon: Icons.trending_up_rounded, color: MayaTheme.neonOrange)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: MayaTheme.titleSmall.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _StrategyInfoRow extends StatelessWidget {
  final String title;
  final String desc;

  const _StrategyInfoRow({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            child: Text(title, style: MayaTheme.labelMedium.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(desc, style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// Multi-Model Router Providers
final llmProvidersProvider = FutureProvider<LLMProvidersResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getLLMProviders();
});

final llmStatsProvider = FutureProvider<LLMStatsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getLLMStats();
});

final llmStrategyProvider = FutureProvider.family<LLMStrategyResponse, String>((ref, strategy) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getLLMStrategy(strategy: strategy);
});

// Enterprise Layer Screen
class _EnterpriseScreen extends ConsumerStatefulWidget {
  const _EnterpriseScreen();

  @override
  ConsumerState<_EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends ConsumerState<_EnterpriseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(adminRolesProvider);
        ref.invalidate(adminOrgsProvider);
        ref.invalidate(adminApiKeysProvider);
        ref.invalidate(adminAuditProvider);
        ref.invalidate(adminDashboardProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Enterprise Layer', style: MayaTheme.headlineSmall),
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
                ref.invalidate(adminRolesProvider);
                ref.invalidate(adminOrgsProvider);
                ref.invalidate(adminApiKeysProvider);
                ref.invalidate(adminAuditProvider);
                ref.invalidate(adminDashboardProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.security_rounded), text: 'RBAC'),
              Tab(icon: Icon(Icons.groups_rounded), text: 'Organizations'),
              Tab(icon: Icon(Icons.key_rounded), text: 'API Keys'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Audit Log'),
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRBTab(),
            _buildOrgsTab(),
            _buildApiKeysTab(),
            _buildAuditTab(),
            _buildDashboardTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRBTab() {
    final rolesAsync = ref.watch(adminRolesProvider);

    return rolesAsync.when(
      data: (response) {
        if (response.roles.isEmpty) {
          return const Center(
            child: Text('No roles found', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.roles.length,
          itemBuilder: (context, index) {
            final entry = response.roles.entries.elementAt(index);
            final roleName = entry.key;
            final role = entry.value;
            return _RoleTile(roleName: roleName, role: role);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading roles', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgsTab() {
    final orgsAsync = ref.watch(adminOrgsProvider);

    return orgsAsync.when(
      data: (response) {
        if (response.orgs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_rounded, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text('No organizations', style: MayaTheme.bodyMedium.copyWith(color: Colors.white38)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showCreateOrgDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Organization'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonCyan,
                    foregroundColor: MayaTheme.slate900,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.orgs.length,
          itemBuilder: (context, index) {
            final org = response.orgs[index];
            return _OrgTile(org: org);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading orgs', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  void _showCreateOrgDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Create Organization', style: MayaTheme.headlineSmall),
        content: TextField(
          controller: controller,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Organization name',
            hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                try {
                  final apiService = ref.read(apiServiceProvider);
                  await apiService.createAdminOrg(name);
                  ref.invalidate(adminOrgsProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Organization created'), backgroundColor: MayaTheme.neonEmerald),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeysTab() {
    final keysAsync = ref.watch(adminApiKeysProvider);

    return keysAsync.when(
      data: (response) {
        return Column(
          children: [
            if (response.keys.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No API keys yet', style: MayaTheme.bodyMedium)),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: response.keys.length,
                itemBuilder: (context, index) {
                  final key = response.keys[index];
                  return _ApiKeyTile(key: key, onRevoke: () async {
                    final success = await ref.read(apiServiceProvider).revokeAdminApiKey(key.id);
                    if (success && mounted) {
                      ref.invalidate(adminApiKeysProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Key revoked'), backgroundColor: MayaTheme.neonEmerald),
                      );
                    }
                  });
                },
              ),
            ),
            // Create key button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateApiKeyDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create API Key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonCyan,
                    foregroundColor: MayaTheme.slate900,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading keys', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  void _showCreateApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Create API Key', style: MayaTheme.headlineSmall),
        content: TextField(
          controller: controller,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Key name (e.g., production, ci-cd)',
            hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                try {
                  final apiService = ref.read(apiServiceProvider);
                  final created = await apiService.createAdminApiKey(name);
                  if (mounted) {
                    // Show the key once - it won't be shown again
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: MayaTheme.slate800,
                        title: Row(
                          children: [
                            Icon(Icons.key_rounded, color: MayaTheme.neonEmerald),
                            const SizedBox(width: 8),
                            const Text('API Key Created', style: MayaTheme.headlineSmall),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Save this key now - it will never be shown again:', style: MayaTheme.bodyMedium),
                            const SizedBox(height: 12),
                            SelectableText(
                              created.key,
                              style: MayaTheme.bodyMedium.copyWith(
                                color: MayaTheme.neonEmerald,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Prefix: ${created.prefix}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Copied'),
                          ),
                        ],
                      ),
                    );
                    ref.invalidate(adminApiKeysProvider);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab() {
    final auditAsync = ref.watch(adminAuditProvider);

    return auditAsync.when(
      data: (response) {
        if (response.events.isEmpty) {
          return const Center(
            child: Text('No audit events', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.events.length,
          itemBuilder: (context, index) {
            final event = response.events[index];
            final time = DateTime.fromMillisecondsSinceEpoch((event.timestamp * 1000).round())
                .toString()
                .substring(0, 19);
            return _AuditTile(event: event, time: time);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading audit', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return dashboardAsync.when(
      data: (response) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Health
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCardGlow(glowColor: MayaTheme.neonCyan),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.dashboard_rounded, color: MayaTheme.neonCyan, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('System Dashboard', style: MayaTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Real-time overview of Maya\'s health and activity',
                            style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Queue Depth
              _DashboardStatCard(
                label: 'Queue Depth',
                value: response.queueDepth.toString(),
                color: MayaTheme.neonCyan,
                icon: Icons.queue_rounded,
              ),

              const SizedBox(height: 24),

              // Metrics
              if (response.metrics.isNotEmpty) ...[
                const Text('Metrics', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                ...response.metrics.entries.map((entry) => _DashboardMetricTile(
                  label: entry.key,
                  value: entry.value.toString(),
                )),
                const SizedBox(height: 24),
              ],

              // Agents
              if (response.agents.isNotEmpty) ...[
                const Text('Agents', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                ...response.agents.entries.map((entry) => _DashboardMetricTile(
                  label: entry.key,
                  value: entry.value.toString(),
                )),
                const SizedBox(height: 24),
              ],

              // Providers
              if (response.providers.isNotEmpty) ...[
                const Text('Providers', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                ...response.providers.entries.map((entry) => _DashboardMetricTile(
                  label: entry.key,
                  value: entry.value.toString(),
                )),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading dashboard', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String roleName;
  final RoleInfo role;

  const _RoleTile({required this.roleName, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.security_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(roleName, style: MayaTheme.titleMedium),
        subtitle: Text(role.description, style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Permissions:', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: role.permissions.map((perm) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MayaTheme.neonViolet.withValues(alpha: 0.3)),
                    ),
                    child: Text(perm, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgTile extends ConsumerWidget {
  final AdminOrg org;

  const _OrgTile({required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.groups_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(org.name, style: MayaTheme.titleMedium),
        subtitle: Text(
          'Members: ${org.memberCount ?? 0} • ID: ${org.id.substring(0, 8)}...',
          style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: MayaTheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: MayaTheme.slate800,
                  title: const Text('Delete Organization?'),
                  content: Text('Delete "${org.name}" and all its members? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final success = await ref.read(apiServiceProvider).deleteAdminOrg(org.id);
                if (success && mounted) {
                  ref.invalidate(adminOrgsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Organization deleted'), backgroundColor: MayaTheme.neonEmerald),
                  );
                }
              }
            },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FutureBuilder<AdminOrgMembersResponse>(
              future: ref.read(apiServiceProvider).getAdminOrgMembers(org.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)));
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error));
                }
                final members = snapshot.data?.members ?? [];
                if (members.isEmpty) {
                  return const Text('No members', style: MayaTheme.bodyMedium);
                }
                return Column(
                  children: members.map((member) => _OrgMemberTile(member: member)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgMemberTile extends StatelessWidget {
  final OrgMember member;

  const _OrgMemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MayaTheme.slate700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MayaTheme.glassWhite10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: MayaTheme.neonCyan.withValues(alpha: 0.2),
            child: Text(
              member.email.substring(0, 1).toUpperCase(),
              style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.email, style: MayaTheme.bodyMedium),
                Text('Role: ${member.role} • Joined: ${member.joinedAt}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: MayaTheme.neonViolet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(member.role, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
          ),
        ],
      ),
    );
  }
}

class _ApiKeyTile extends StatelessWidget {
  final AdminApiKey key;
  final VoidCallback onRevoke;

  const _ApiKeyTile({required this.key, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: key.revoked
                      ? Colors.white12
                      : MayaTheme.neonEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  key.revoked ? Icons.lock_rounded : Icons.key_rounded,
                  color: key.revoked ? Colors.white38 : MayaTheme.neonEmerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(key.name, style: MayaTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Prefix: ${key.prefix}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                        const SizedBox(width: 16),
                        Text('Created: ${key.createdAt}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
              if (key.lastUsedAt != null)
                Text('Last used: ${key.lastUsedAt}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54))
              else
                const Text('Never used', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!key.revoked)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRevoke,
                    icon: const Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                    label: const Text('Revoke', style: TextStyle(color: MayaTheme.error)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MayaTheme.error,
                      side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final AuditEvent event;
  final String time;

  const _AuditTile({required this.event, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_rounded, color: MayaTheme.neonCyan, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.action, style: MayaTheme.titleMedium),
                    Text('Actor: ${event.actor}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Text(time, style: MayaTheme.labelSmall.copyWith(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Target: ${event.target}', style: MayaTheme.bodyMedium),
          if (event.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MayaTheme.slate700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.details.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white70, fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
                Text(label, style: MayaTheme.labelMedium.copyWith(color: Colors.white54)),
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

class _DashboardMetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _DashboardMetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Text(label, style: MayaTheme.bodyMedium),
          const Spacer(),
          Text(value, style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.neonCyan)),
        ],
      ),
    );
  }
}

// Enterprise Providers
final adminRolesProvider = FutureProvider<AdminRolesResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAdminRoles();
});

final adminOrgsProvider = FutureProvider<AdminOrgsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAdminOrgs();
});

final adminApiKeysProvider = FutureProvider<AdminApiKeysResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAdminApiKeys();
});

final adminAuditProvider = FutureProvider<AdminAuditResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAdminAudit();
});

final adminDashboardProvider = FutureProvider<AdminDashboardResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAdminDashboard();
});

// Learning Layer Screen
class _LearningScreen extends ConsumerStatefulWidget {
  const _LearningScreen();

  @override
  ConsumerState<_LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<_LearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(learningStatsProvider);
        ref.invalidate(learningExperienceProvider);
        ref.invalidate(learningPromptsProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Learning Layer', style: MayaTheme.headlineSmall),
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
                ref.invalidate(learningStatsProvider);
                ref.invalidate(learningExperienceProvider);
                ref.invalidate(learningPromptsProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.feedback_rounded), text: 'Feedback'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Experience'),
              Tab(icon: Icon(Icons.psychology_rounded), text: 'Prompts'),
              Tab(icon: Icon(Icons.compress_rounded), text: 'Compression'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedbackTab(),
            _buildExperienceTab(),
            _buildPromptsTab(),
            _buildCompressionTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackTab() {
    final statsAsync = ref.watch(learningStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Submit Feedback Form
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: _FeedbackForm(onSubmit: () {
                ref.invalidate(learningStatsProvider);
              }),
            ),

            const SizedBox(height: 24),

            // Stats Summary
            Row(
              children: [
                Expanded(child: _FeedbackStatCard(label: 'Total', value: stats.feedback.total.toString(), color: MayaTheme.neonCyan)),
                const SizedBox(width: 12),
                Expanded(child: _FeedbackStatCard(label: 'Positive', value: stats.feedback.positive.toString(), color: MayaTheme.neonEmerald)),
                const SizedBox(width: 12),
                Expanded(child: _FeedbackStatCard(label: 'Negative', value: stats.feedback.negative.toString(), color: MayaTheme.error)),
                const SizedBox(width: 12),
                Expanded(child: _FeedbackStatCard(label: 'Satisfaction', value: stats.feedback.satisfaction != null ? '${(stats.feedback.satisfaction! * 100).toStringAsFixed(1)}%' : 'N/A', color: MayaTheme.neonViolet)),
              ],
            ),

            const SizedBox(height: 24),

            // Lessons (from negative feedback)
            if (stats.lessons.isNotEmpty) ...[
              const Text('Lessons Learned (from negative feedback)', style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              ...stats.lessons.map((lesson) => _LessonTile(lesson: lesson)),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCard(),
                child: const Text('No lessons recorded yet. Submit feedback with comments on negative ratings.',
                    style: MayaTheme.bodyMedium),
              ),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading stats', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceTab() {
    final experienceAsync = ref.watch(learningExperienceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Similar Experience Lookup
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: _ExperienceLookup(onSearch: () {
              ref.invalidate(learningExperienceProvider);
            }),
          ),

          const SizedBox(height: 24),

          // Experience History
          const Text('Recent Experience History', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          experienceAsync.when(
            data: (exp) {
              final history = exp.history ?? [];
              if (history.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: const Text('No experience recorded yet',
                      style: MayaTheme.bodyMedium),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final episode = history[index];
                  return _ExperienceTile(episode: episode);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
            ),
            error: (err, _) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                children: [
                  const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading experience', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptsTab() {
    final promptsAsync = ref.watch(learningPromptsProvider);

    return promptsAsync.when(
      data: (prompts) {
        if (prompts.prompts.isEmpty) {
          return const Center(
            child: Text('No prompt variants recorded yet', style: MayaTheme.bodyMedium),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: prompts.prompts.entries.map((entry) {
            final task = entry.key;
            final variants = entry.value;
            return _PromptTaskTile(task: task, variants: variants);
          }).toList(),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading prompts', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Memory Compression', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Compress long-term memory (chat, episodic, semantic) to reduce storage and improve retrieval. Dry-run shows what would be compressed without making changes.',
                  style: MayaTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: 'chat',
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Memory Type',
                          labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'chat', child: Text('Chat History')),
                          DropdownMenuItem(value: 'episodic', child: Text('Episodic Memory')),
                          DropdownMenuItem(value: 'semantic', child: Text('Semantic Memory')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Dry Run'),
                        subtitle: const Text('Preview only, no changes'),
                        value: true,
                        activeColor: MayaTheme.neonCyan,
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final apiService = ref.read(apiServiceProvider);
                          final result = await apiService.compressMemory(dryRun: true, memoryType: 'chat');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Compression dry-run complete'), backgroundColor: MayaTheme.neonEmerald),
                            );
                          }
                        },
                        icon: const Icon(Icons.preview_rounded),
                        label: const Text('Dry Run'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MayaTheme.neonCyan,
                          foregroundColor: MayaTheme.slate900,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: MayaTheme.slate800,
                              title: const Text('Confirm Compression'),
                              content: const Text('This will permanently compress memory. Continue?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error), child: const Text('Compress')),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            final apiService = ref.read(apiServiceProvider);
                            final result = await apiService.compressMemory(dryRun: false, memoryType: 'chat');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Compression executed'), backgroundColor: MayaTheme.neonEmerald),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.compress_rounded),
                        label: const Text('Execute'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.error,
                          side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Compression Stats (from stats endpoint)
          Consumer(
            builder: (context, ref, _) {
              final statsAsync = ref.watch(learningStatsProvider);
              return statsAsync.when(
                data: (stats) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Compression Status', style: MayaTheme.titleMedium),
                      const SizedBox(height: 12),
                      _CompressionStatRow(label: 'Prompt Variants', value: stats.prompts.length.toString()),
                      _CompressionStatRow(label: 'Feedback Entries', value: stats.feedback.total.toString()),
                      _CompressionStatRow(label: 'Satisfaction Rate', value: stats.feedback.satisfaction != null ? '${(stats.feedback.satisfaction! * 100).toStringAsFixed(1)}%' : 'N/A'),
                    ],
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeedbackForm extends ConsumerStatefulWidget {
  final VoidCallback onSubmit;

  const _FeedbackForm({required this.onSubmit});

  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm> {
  final _goalController = TextEditingController();
  final _outputController = TextEditingController();
  final _commentController = TextEditingController();
  int _rating = 0; // -1, 0, 1

  @override
  void dispose() {
    _goalController.dispose();
    _outputController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Submit Feedback', style: MayaTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _goalController,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Goal / Task',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _outputController,
          style: MayaTheme.bodyMedium,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Maya\'s Output',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Rating:', style: MayaTheme.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            _RatingButton(label: '👎 Bad', value: -1, selected: _rating == -1, color: MayaTheme.error, onTap: () => setState(() => _rating = -1)),
            const SizedBox(width: 8),
            _RatingButton(label: '😐 Neutral', value: 0, selected: _rating == 0, color: MayaTheme.neonOrange, onTap: () => setState(() => _rating = 0)),
            const SizedBox(width: 8),
            _RatingButton(label: '👍 Good', value: 1, selected: _rating == 1, color: MayaTheme.neonEmerald, onTap: () => setState(() => _rating = 1)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          style: MayaTheme.bodyMedium,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Comment (optional)',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _rating != 0 ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.neonCyan,
              foregroundColor: MayaTheme.slate900,
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: Colors.white12,
            ),
            child: const Text('Submit Feedback'),
          ),
        ),
      ],
    );
  }

  void _submit() async {
    final goal = _goalController.text.trim();
    final output = _outputController.text.trim();
    final comment = _commentController.text.trim();
    if (goal.isEmpty || output.isEmpty) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.submitFeedback(goal: goal, output: output, rating: _rating, comment: comment);
      _goalController.clear();
      _outputController.clear();
      _commentController.clear();
      setState(() => _rating = 0);
      widget.onSubmit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Feedback submitted'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({required this.label, required this.value, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.3) : MayaTheme.slate700,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : MayaTheme.glassWhite10, width: 2),
          ),
          child: Center(child: Text(label, style: MayaTheme.bodyMedium.copyWith(color: selected ? color : Colors.white))),
        ),
      ),
    );
  }
}

class _FeedbackStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FeedbackStatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCardGlow(glowColor: color),
      child: Column(
        children: [
          Text(value, style: MayaTheme.headlineMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch((lesson.ts * 1000).round())
        .toString()
        .substring(0, 19);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: MayaTheme.neonOrange, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Lesson from negative feedback', style: MayaTheme.titleSmall.copyWith(color: MayaTheme.neonOrange))),
            ],
          ),
          const SizedBox(height: 8),
          Text(lesson.goal, style: MayaTheme.bodyMedium),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MayaTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(lesson.comment, style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
          ),
          const SizedBox(height: 4),
          Text(time, style: MayaTheme.labelSmall.copyWith(color: Colors.white38)),
        ],
      ),
    );
  }
}

class _ExperienceLookup extends ConsumerStatefulWidget {
  final VoidCallback onSearch;

  const _ExperienceLookup({required this.onSearch});

  @override
  ConsumerState<_ExperienceLookup> createState() => _ExperienceLookupState();
}

class _ExperienceLookupState extends ConsumerState<_ExperienceLookup> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Find Similar Past Work', style: MayaTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Describe the goal/task',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search_rounded, color: MayaTheme.neonCyan),
              onPressed: () {
                widget.onSearch();
              },
            ),
          ),
          onSubmitted: (_) => widget.onSearch(),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, _) {
            final goal = _controller.text.trim();
            if (goal.isEmpty) return const SizedBox();
            return ref.watch(learningExperienceProvider(goal)).when(
              data: (exp) {
                final similar = exp.similar ?? [];
                if (similar.isEmpty) {
                  return const Text('No similar past work found', style: MayaTheme.bodyMedium);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text('Similar Episodes', style: MayaTheme.labelMedium),
                    const SizedBox(height: 8),
                    ...similar.map((ep) => _ExperienceTile(episode: ep, showSimilarity: true)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
              error: (_, __) => const SizedBox(),
            );
          },
        ),
      ],
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  final ExperienceEpisode episode;
  final bool showSimilarity;

  const _ExperienceTile({required this.episode, this.showSimilarity = false});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch((episode.ts * 1000).round())
        .toString()
        .substring(0, 19);
    Color statusColor;
    switch (episode.outcome) {
      case 'completed':
        statusColor = MayaTheme.neonEmerald;
        break;
      case 'failed':
        statusColor = MayaTheme.error;
        break;
      default:
        statusColor = MayaTheme.neonOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(episode.outcome, style: MayaTheme.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
              ),
              if (showSimilarity && episode.similarity != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Similarity: ${(episode.similarity! * 100).toStringAsFixed(1)}%', style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
                ),
              ],
              const Spacer(),
              Text(time, style: MayaTheme.labelSmall.copyWith(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 8),
          Text(episode.goal, style: MayaTheme.bodyMedium),
          if (episode.steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: episode.steps.take(3).map((step) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(step.toString(), style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
              )).toList(),
            ),
            if (episode.steps.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('... and ${episode.steps.length - 3} more steps', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Confidence: ${(episode.confidence * 100).toStringAsFixed(1)}%', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptTaskTile extends StatelessWidget {
  final String task;
  final Map<String, PromptVariant> variants;

  const _PromptTaskTile({required this.task, required this.variants});

  @override
  Widget build(BuildContext context) {
    final sortedVariants = variants.entries.toList()
      ..sort((a, b) => b.value.score.compareTo(a.value.score));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task, style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          ...sortedVariants.map((entry) {
            final variant = entry.key;
            final stats = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MayaTheme.slate700,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stats.score > 0.7 ? MayaTheme.neonEmerald.withValues(alpha: 0.3) : MayaTheme.glassWhite10),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(variant, style: MayaTheme.bodyMedium)),
                  const SizedBox(width: 12),
                  Text('✓ ${stats.ok}  ✗ ${stats.fail}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stats.score > 0.7 ? MayaTheme.neonEmerald.withValues(alpha: 0.2) : (stats.score > 0.5 ? MayaTheme.neonOrange.withValues(alpha: 0.2) : MayaTheme.error.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Score: ${(stats.score * 100).toStringAsFixed(1)}%', style: MayaTheme.labelSmall.copyWith(color: stats.score > 0.7 ? MayaTheme.neonEmerald : (stats.score > 0.5 ? MayaTheme.neonOrange : MayaTheme.error))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CompressionStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompressionStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: MayaTheme.bodyMedium),
          const Spacer(),
          Text(value, style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.neonCyan)),
        ],
      ),
    );
  }
}

// Learning Providers
final learningStatsProvider = FutureProvider<LearningStatsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getLearningStats();
});

final learningExperienceProvider = FutureProvider.family<LearningExperienceResponse, String>((ref, goal) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getLearningExperience(goal: goal, limit: 10);
});

final learningPromptsProvider = FutureProvider<LearningPromptsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getLearningPrompts();
});

// RAG Providers
final ragStatsProvider = FutureProvider<RAGStatsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getRAGStats();
});

final ragDocumentsProvider = FutureProvider<RAGDocumentsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getRAGDocuments();
});

final ragSearchProvider = FutureProvider.family<RAGSearchResponse, String>((ref, query) async {
  if (query.isEmpty) {
    throw Exception('Empty query');
  }
  final apiService = ref.read(apiServiceProvider);
  return apiService.searchRAG(query: query);
});

final ragContextProvider = FutureProvider.family<RAGContextResponse, String>((ref, query) async {
  if (query.isEmpty) {
    throw Exception('Empty query');
  }
  final apiService = ref.read(apiServiceProvider);
  return apiService.getRAGContext(query: query);
});

// RAG Helper Widgets
class _IngestDocumentForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const _IngestDocumentForm({required this.onSuccess});

  @override
  ConsumerState<_IngestDocumentForm> createState() => _IngestDocumentFormState();
}

class _IngestDocumentFormState extends ConsumerState<_IngestDocumentForm> {
  final _textController = TextEditingController();
  final _titleController = TextEditingController();
  final _docTypeController = TextEditingController(text: 'text');
  final _pathController = TextEditingController();
  bool _usePath = false;

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _docTypeController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Use workspace file path'),
          subtitle: const Text('Instead of inline text'),
          value: _usePath,
          activeColor: MayaTheme.neonCyan,
          onChanged: (value) => setState(() => _usePath = value),
        ),
        const SizedBox(height: 12),
        if (_usePath) ...[
          TextField(
            controller: _pathController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Workspace Path (e.g., docs/readme.md)',
              labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ] else ...[
          TextField(
            controller: _textController,
            style: MayaTheme.bodyMedium,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Document Text',
              labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Title (optional)',
              labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _docTypeController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Doc Type (text, code, pdf, etc.)',
              labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.neonCyan,
              foregroundColor: MayaTheme.slate900,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(_usePath ? 'Ingest File' : 'Ingest Text'),
          ),
        ),
      ],
    );
  }

  void _submit() async {
    if (_usePath && _pathController.text.trim().isEmpty) return;
    if (!_usePath && _textController.text.trim().isEmpty) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.ingestRAGDocument(
        text: _usePath ? null : _textController.text.trim(),
        title: _usePath ? null : _titleController.text.trim(),
        docType: _usePath ? null : _docTypeController.text.trim(),
        path: _usePath ? _pathController.text.trim() : null,
      );
      if (mounted) {
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document ingested: ${result.docId} (${result.chunksCreated} chunks)'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

class _RAGDocumentTile extends StatelessWidget {
  final RAGDocument doc;
  final VoidCallback onDelete;

  const _RAGDocumentTile({required this.doc, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_rounded, color: MayaTheme.neonCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title, style: MayaTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${doc.id} • Type: ${doc.docType} • ${doc.chunkCount} chunks',
                      style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${doc.sizeKb.toStringAsFixed(1)} KB',
                  style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Created: ${doc.createdAt}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                label: const Text('Delete', style: TextStyle(color: MayaTheme.error)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MayaTheme.error,
                  side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RAGSearchResultTile extends StatelessWidget {
  final RAGSearchResult hit;

  const _RAGSearchResultTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Score: ${hit.score.toStringAsFixed(3)}',
                  style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(hit.docType, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
              ),
              const Spacer(),
              Text(hit.title, style: MayaTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(hit.content.length > 300 ? '${hit.content.substring(0, 300)}...' : hit.content,
              style: MayaTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RAGCitationTile extends StatelessWidget {
  final int index;
  final RAGSearchResult citation;

  const _RAGCitationTile({required this.index, required this.citation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MayaTheme.slate700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MayaTheme.glassWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('[$index]', style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(citation.title, style: MayaTheme.bodyMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(citation.docType, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            citation.content.length > 200 ? '${citation.content.substring(0, 200)}...' : citation.content,
            style: MayaTheme.bodySmall.copyWith(color: Colors.white70, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
}

// RAG Providers
final ragStatsProvider = FutureProvider<RAGStatsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getRAGStats();
});

final ragDocumentsProvider = FutureProvider<RAGDocumentsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getRAGDocuments();
});

final ragSearchProvider = FutureProvider.family<RAGSearchResponse, String>((ref, query) async {
  if (query.isEmpty) {
    throw Exception('Empty query');
  }
  final apiService = ref.read(apiServiceProvider);
  return apiService.searchRAG(query: query);
});

final ragContextProvider = FutureProvider.family<RAGContextResponse, String>((ref, query) async {
  if (query.isEmpty) {
    throw Exception('Empty query');
  }
  final apiService = ref.read(apiServiceProvider);
  return apiService.getRAGContext(query: query);
});

// Instance CRUD Screen (Phase 14)
class _InstanceScreen extends ConsumerStatefulWidget {
  const _InstanceScreen();

  @override
  ConsumerState<_InstanceScreen> createState() => _InstanceScreenState();
}

class _InstanceScreenState extends ConsumerState<_InstanceScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(instancesListProvider);
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
    final instancesAsync = ref.watch(instancesListProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Instance Manager', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(instancesListProvider),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _showCreateInstanceDialog,
            ),
          ],
        ),
        body: instancesAsync.when(
          data: (response) {
            if (response.instances.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.computer_rounded, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text('No instances yet', style: MayaTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text('Tap + to create your first Maya instance',
                        style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: response.instances.length,
              itemBuilder: (context, index) {
                final instance = response.instances[index];
                return _InstanceTile(instance: instance);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                const SizedBox(height: 16),
                Text('Error loading instances', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                const SizedBox(height: 8),
                Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateInstanceDialog() {
    final nameController = TextEditingController();
    final personaController = TextEditingController();
    final skillsController = TextEditingController();
    final budgetController = TextEditingController(text: '5.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Create Instance', style: MayaTheme.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: MayaTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Instance Name',
                  labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: personaController,
                style: MayaTheme.bodyMedium,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Persona',
                  labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsController,
                style: MayaTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Skills (comma-separated)',
                  labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: MayaTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Budget (USD)',
                  labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final persona = personaController.text.trim();
              if (name.isEmpty || persona.isEmpty) return;

              final skills = skillsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final budget = double.tryParse(budgetController.text) ?? 5.0;

              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.createInstance(
                  name: name,
                  persona: persona,
                  skills: skills,
                  budgetUsd: budget,
                );
                ref.invalidate(instancesListProvider);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Instance created'), backgroundColor: MayaTheme.neonEmerald),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _InstanceTile extends ConsumerWidget {
  final InstanceInfo instance;

  const _InstanceTile({required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.computer_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(instance.name, style: MayaTheme.titleMedium),
        subtitle: Text(instance.persona, style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: MayaTheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') _deleteInstance(context, instance.id);
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Instance ID', value: instance.id),
                _DetailRow(label: 'Persona', value: instance.persona),
                _DetailRow(label: 'Memory Scope', value: instance.memoryScope),
                _DetailRow(label: 'Budget (USD)', value: instance.budgetUsd.toString()),
                _DetailRow(label: 'Owner', value: instance.owner),
                _DetailRow(label: 'Created', value: DateTime.fromMillisecondsSinceEpoch((instance.createdAt * 1000).round()).toString()),
                const SizedBox(height: 12),
                const Text('Skills', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: instance.skills.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MayaTheme.neonViolet.withValues(alpha: 0.3)),
                    ),
                    child: Text(skill, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'Memory Scope', value: instance.memoryScope),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to instance detail
                        },
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.neonCyan,
                          side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteInstance(context, instance.id),
                        icon: const Icon(Icons.delete_rounded, color: MayaTheme.error),
                        label: const Text('Delete', style: TextStyle(color: MayaTheme.error)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.error,
                          side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteInstance(BuildContext context, String instanceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Delete Instance?'),
        content: const Text('This will permanently delete the instance and all its memory. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteInstanceConfirmed(instance.id);
      }
    );
  }

  void _deleteInstanceConfirmed(String instanceId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final success = await ref.read(apiServiceProvider).deleteInstance(instance.id);
      if (success && mounted) {
        ref.invalidate(instancesListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Instance deleted'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

class _InstanceTile extends ConsumerWidget {
  final InstanceInfo instance;

  const _InstanceTile({required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.computer_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(instance.name, style: MayaTheme.titleMedium),
        subtitle: Text(instance.persona, style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: MayaTheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') _deleteInstance(context, instance.id);
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Instance ID', value: instance.id),
                _DetailRow(label: 'Persona', value: instance.persona),
                _DetailRow(label: 'Memory Scope', value: instance.memoryScope),
                _DetailRow(label: 'Budget (USD)', value: instance.budgetUsd.toString()),
                _DetailRow(label: 'Owner', value: instance.owner),
                _DetailRow(label: 'Created', value: DateTime.fromMillisecondsSinceEpoch((instance.createdAt * 1000).round()).toString()),
                const SizedBox(height: 12),
                const Text('Skills', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: instance.skills.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MayaTheme.neonViolet.withValues(alpha: 0.3)),
                    ),
                    child: Text(skill, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'Memory Scope', value: instance.memoryScope),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to instance detail
                        },
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.neonCyan,
                          side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteInstance(context, instance.id),
                        icon: const Icon(Icons.delete_rounded, color: MayaTheme.error),
                        label: const Text('Delete', style: TextStyle(color: MayaTheme.error)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.error,
                          side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteInstance(BuildContext context, String instanceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Delete Instance?'),
        content: const Text('This will permanently delete the instance and all its memory. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteInstanceConfirmed(instance.id);
      }
    );
  }

  void _deleteInstanceConfirmed(String instanceId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final success = await ref.read(apiServiceProvider).deleteInstance(instance.id);
      if (success && mounted) {
        ref.invalidate(instancesListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Instance deleted'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

class _InstanceTile extends ConsumerWidget {
  final InstanceInfo instance;

  const _InstanceTile({required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.computer_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(instance.name, style: MayaTheme.titleMedium),
        subtitle: Text(instance.persona, style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: MayaTheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') _deleteInstance(context, instance.id);
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Instance ID', value: instance.id),
                _DetailRow(label: 'Persona', value: instance.persona),
                _DetailRow(label: 'Memory Scope', value: instance.memoryScope),
                _DetailRow(label: 'Budget (USD)', value: instance.budgetUsd.toString()),
                _DetailRow(label: 'Owner', value: instance.owner),
                _DetailRow(label: 'Created', value: DateTime.fromMillisecondsSinceEpoch((instance.createdAt * 1000).round()).toString()),
                const SizedBox(height: 12),
                const Text('Skills', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: instance.skills.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MayaTheme.neonViolet.withValues(alpha: 0.3)),
                    ),
                    child: Text(skill, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'Memory Scope', value: instance.memoryScope),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to instance detail
                        },
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.neonCyan,
                          side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteInstance(context, instance.id),
                        icon: const Icon(Icons.delete_rounded, color: MayaTheme.error),
                        label: const Text('Delete', style: TextStyle(color: MayaTheme.error)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.error,
                          side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteInstance(BuildContext context, String instanceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Delete Instance?'),
        content: const Text('This will permanently delete the instance and all its memory. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteInstanceConfirmed(instance.id);
      }
    );
  }

  void _deleteInstanceConfirmed(String instanceId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final success = await ref.read(apiServiceProvider).deleteInstance(instance.id);
      if (success && mounted) {
        ref.invalidate(instancesListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Instance deleted'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

class _InstanceTile extends ConsumerWidget {
  final InstanceInfo instance;

  const _InstanceTile({required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.computer_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(instance.name, style: MayaTheme.titleMedium),
        subtitle: Text(instance.persona, style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: MayaTheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') _deleteInstance(context, instance.id);
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Instance ID', value: instance.id),
                _DetailRow(label: 'Persona', value: instance.persona),
                _DetailRow(label: 'Memory Scope', value: instance.memoryScope),
                _DetailRow(label: 'Budget (USD)', value: instance.budgetUsd.toString()),
                _DetailRow(label: 'Owner', value: instance.owner),
                _DetailRow(label: 'Created', value: DateTime.fromMillisecondsSinceEpoch((instance.createdAt * 1000).round()).toString()),
                const SizedBox(height: 12),
                const Text('Skills', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: instance.skills.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MayaTheme.neonViolet.withValues(alpha: 0.3)),
                    ),
                    child: Text(skill, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'Memory Scope', value: instance.memoryScope),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to instance detail
                        },
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.neonCyan,
                          side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteInstance(context, instance.id),
                        icon: const Icon(Icons.delete_rounded, color: MayaTheme.error),
                        label: const Text('Delete', style: TextStyle(color: MayaTheme.error)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.error,
                          side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteInstance(BuildContext context, String instanceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Delete Instance?'),
        content: const Text('This will permanently delete the instance and all its memory. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteInstanceConfirmed(instance.id);
      }
    );
  }

  void _deleteInstanceConfirmed(String instanceId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final success = await ref.read(apiServiceProvider).deleteInstance(instance.id);
      if (success && mounted) {
        ref.invalidate(instancesListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Instance deleted'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

// Instance Providers
final instancesListProvider = FutureProvider<InstancesListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getInstancesList();
});
class _PhoneControlScreen extends ConsumerStatefulWidget {
  const _PhoneControlScreen();

  @override
  ConsumerState<_PhoneControlScreen> createState() => _PhoneControlScreenState();
}

class _PhoneControlScreenState extends ConsumerState<_PhoneControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  String _pairingCode = '';
  String _deviceName = 'My computer';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(deviceListProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Phone / Device Control', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(deviceListProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.devices_rounded), text: 'Devices'),
              Tab(icon: Icon(Icons.link_rounded), text: 'Pair Device'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Command History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDevicesTab(),
            _buildPairTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesTab() {
    final devicesAsync = ref.watch(deviceListProvider);

    return devicesAsync.when(
      data: (response) {
        if (response.devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.devices_rounded, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('No paired devices', style: MayaTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('Tap "Pair Device" to connect your computer',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.devices.length,
          itemBuilder: (context, index) {
            final device = response.devices[index];
            return _DeviceTile(
              device: device,
              onSendCommand: (action, params) => _sendCommand(device.id, action, params),
              onRevoke: () => _revokeDevice(device.id),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading devices', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildPairTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pair a New Device', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Run the Maya Bridge Agent on your computer, then enter the pairing code shown here.',
                  style: MayaTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: TextEditingController(text: _deviceName),
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Device Name',
                    labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => _deviceName = v,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startPairing,
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Generate Pairing Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_pairingCode.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Pairing Code (expires in 10 min):', style: MayaTheme.labelMedium),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _pairingCode,
                          style: MayaTheme.headlineMedium.copyWith(
                            color: MayaTheme.neonCyan,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: MayaTheme.neonCyan),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _pairingCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: const Text('Code copied!'), backgroundColor: MayaTheme.neonEmerald),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Text('Share this code with your computer', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How to Pair', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                _PairStep(number: 1, text: 'On your computer, run: pip install requests pyautogui pillow'),
                _PairStep(number: 2, text: 'Run: python maya_bridge_agent.py'),
                _PairStep(number: 3, text: 'Enter the backend URL (e.g., http://130.210.46.182:8000/api/v1)'),
                _PairStep(number: 4, text: 'Paste the pairing code above when prompted'),
                _PairStep(number: 5, text: 'Keep the script running to receive commands'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer(
      builder: (context, ref, _) {
        final devicesAsync = ref.watch(deviceListProvider);
        return devicesAsync.when(
          data: (response) {
            if (response.devices.isEmpty) {
              return const Center(child: Text('No devices to show history for', style: MayaTheme.bodyMedium));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: response.devices.length,
              itemBuilder: (context, index) {
                final device = response.devices[index];
                return _DeviceHistoryTile(deviceId: device.id, deviceName: device.name);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
          error: (err, _) => Center(child: Text('Error: $err', style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error))),
        );
      },
    );
  }

  Future<void> _startPairing() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.startDevicePairing(name: _deviceName);
      if (mounted) {
        setState(() => _pairingCode = result.pairingCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Pairing code generated'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _revokeDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Revoke Device?'),
        content: const Text('This will unpair the device and it can no longer receive commands.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        final success = await apiService.revokeDevice(deviceId);
        if (success && mounted) {
          ref.invalidate(deviceListProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Device revoked'), backgroundColor: MayaTheme.neonEmerald),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
          );
        }
      }
    }
  }

  Future<void> _sendCommand(String deviceId, String action, Map<String, dynamic> params) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.sendDeviceCommand(deviceId: deviceId, action: action, params: params);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Command queued: ${result.id}'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

class _DeviceTile extends StatelessWidget {
  final DeviceInfo device;
  final Future<void> Function(String, Map<String, dynamic>) onSendCommand;
  final VoidCallback onRevoke;

  const _DeviceTile({
    required this.device,
    required this.onSendCommand,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.computer_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(device.name, style: MayaTheme.titleMedium),
        subtitle: Text(
          'Last seen: ${device.lastSeen != null ? DateTime.fromMillisecondsSinceEpoch((device.lastSeen! * 1000).round()).toString().substring(0, 19) : "Never"}',
          style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'revoke',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                  SizedBox(width: 8),
                  Text('Revoke', style: TextStyle(color: MayaTheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'revoke') onRevoke();
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Device ID', value: device.id),
                _DetailRow(label: 'Paired', value: DateTime.fromMillisecondsSinceEpoch((device.pairedAt * 1000).round()).toString()),
                _DetailRow(label: 'Last Seen', value: device.lastSeen != null ? DateTime.fromMillisecondsSinceEpoch((device.lastSeen! * 1000).round()).toString() : 'Never'),
                const SizedBox(height: 16),
                const Text('Quick Actions', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ActionChip(icon: Icons.mouse_rounded, label: 'Move Mouse', onTap: () => _showMoveMouseDialog(context, onSendCommand)),
                    _ActionChip(icon: Icons.touch_app_rounded, label: 'Click', onTap: () => _showClickDialog(context, onSendCommand)),
                    _ActionChip(icon: Icons.keyboard_rounded, label: 'Type Text', onTap: () => _showTypeTextDialog(context, onSendCommand)),
                    _ActionChip(icon: Icons.keyboard_rounded, label: 'Press Key', onTap: () => _showPressKeyDialog(context, onSendCommand)),
                    _ActionChip(icon: Icons.screenshot_rounded, label: 'Screenshot', onTap: () => onSendCommand('screenshot', {})),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoveMouseDialog(BuildContext context, Future<void> Function(String, Map<String, dynamic>) onSendCommand) {
    final xController = TextEditingController();
    final yController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Move Mouse', style: MayaTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: xController,
              keyboardType: TextInputType.number,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'X',
                labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yController,
              keyboardType: TextInputType.number,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Y',
                labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final x = int.tryParse(xController.text);
              final y = int.tryParse(yController.text);
              if (x != null && y != null) {
                Navigator.pop(context);
                onSendCommand('move_mouse', {'x': x, 'y': y});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }

  void _showClickDialog(BuildContext context, Future<void> Function(String, Map<String, dynamic>) onSendCommand) {
    final xController = TextEditingController();
    final yController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Click', style: MayaTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: xController,
              keyboardType: TextInputType.number,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'X (optional)',
                labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yController,
              keyboardType: TextInputType.number,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Y (optional)',
                labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final params = <String, dynamic>{};
              final x = int.tryParse(xController.text);
              final y = int.tryParse(yController.text);
              if (x != null) params['x'] = x;
              if (y != null) params['y'] = y;
              Navigator.pop(context);
              onSendCommand('click', params);
            },
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Click'),
          ),
        ],
      ),
    );
  }

  void _showTypeTextDialog(BuildContext context, Future<void> Function(String, Map<String, dynamic>) onSendCommand) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Type Text', style: MayaTheme.headlineSmall),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Text to type',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context);
                onSendCommand('type_text', {'text': text});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Type'),
          ),
        ],
      ),
    );
  }

  void _showPressKeyDialog(BuildContext context, Future<void> Function(String, Map<String, dynamic>) onSendCommand) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Press Key', style: MayaTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Key (e.g., enter, escape, tab, ctrl, alt)',
                labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                Navigator.pop(context);
                onSendCommand('press_key', {'key': key});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Press'),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: MayaTheme.neonCyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: MayaTheme.neonCyan),
            const SizedBox(width: 6),
            Text(label, style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan)),
          ],
        ),
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

class _PairStep extends StatelessWidget {
  final int number;
  final String text;

  const _PairStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$number', style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: MayaTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _DeviceHistoryTile extends ConsumerWidget {
  final String deviceId;
  final String deviceName;

  const _DeviceHistoryTile({required this.deviceId, required this.deviceName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(deviceHistoryProvider(deviceId));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.history_rounded, color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(deviceName, style: MayaTheme.titleMedium),
        subtitle: Text('Device ID: ${deviceId.substring(0, 8)}...', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: historyAsync.when(
              data: (history) {
                if (history.commands.isEmpty) {
                  return const Text('No commands yet', style: MayaTheme.bodyMedium);
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.commands.length,
                  itemBuilder: (context, index) {
                    final cmd = history.commands[index];
                    return _CommandHistoryTile(cmd: cmd);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
              error: (err, _) => Text('Error: $err', style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandHistoryTile extends StatelessWidget {
  final DeviceCommandEntry cmd;

  const _CommandHistoryTile({required this.cmd});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch((cmd.createdAt * 1000).round())
        .toString()
        .substring(11, 19);
    Color statusColor;
    switch (cmd.status) {
      case 'done':
        statusColor = MayaTheme.neonEmerald;
        break;
      case 'sent':
        statusColor = MayaTheme.neonCyan;
        break;
      case 'pending':
        statusColor = MayaTheme.neonOrange;
        break;
      default:
        statusColor = Colors.white38;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MayaTheme.slate700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MayaTheme.glassWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(cmd.status.toUpperCase(), style: MayaTheme.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(cmd.action, style: MayaTheme.titleSmall),
              const Spacer(),
              Text(time, style: MayaTheme.labelSmall.copyWith(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Params: ${cmd.params}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
          if (cmd.result != null) ...[
            const SizedBox(height: 8),
            Text('Result: ${cmd.result}', style: MayaTheme.bodySmall.copyWith(color: Colors.white70, fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }
}

// Device Bridge Providers
final deviceListProvider = FutureProvider<DeviceListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getDeviceList();
});

final deviceHistoryProvider = FutureProvider.family<DeviceHistoryResponse, String>((ref, deviceId) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getDeviceHistory(deviceId);
});

// Hosting API Screen (Phase 15)
class _HostingScreen extends ConsumerStatefulWidget {
  const _HostingScreen();

  @override
  ConsumerState<_HostingScreen> createState() => _HostingScreenState();
}

class _HostingScreenState extends ConsumerState<_HostingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(hostingAppsProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Hosting Manager', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(hostingAppsProvider),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _showDeployDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.apps_rounded), text: 'Apps'),
              Tab(icon: Icon(Icons.rocket_launch_rounded), text: 'Deploy'),
              Tab(icon: Icon(Icons.person_rounded), text: 'My Apps'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAppsTab(),
            _buildDeployTab(),
            _buildMyAppsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsTab() {
    final appsAsync = ref.watch(hostingAppsProvider);

    return appsAsync.when(
      data: (response) {
        if (response.apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apps_rounded, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('No hosted apps yet', style: MayaTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('Tap + to deploy your first app',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.apps.length,
          itemBuilder: (context, index) {
            final app = response.apps[index];
            return _AppTile(app: app);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading apps', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeployTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Deploy New App', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(),
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'App Name',
                    labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: 'python-asgi',
                  dropdownColor: MayaTheme.slate800,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Kind',
                    labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'python-asgi', child: Text('Python ASGI (FastAPI, Starlette)')),
                    DropdownMenuItem(value: 'python', child: Text('Python Script')),
                    DropdownMenuItem(value: 'node', child: Text('Node.js')),
                    DropdownMenuItem(value: 'static', child: Text('Static Files')),
                    DropdownMenuItem(value: 'command', child: Text('Custom Command')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(),
                  style: MayaTheme.bodyMedium,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Entry Point / Command',
                    labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(),
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Working Directory (optional)',
                    labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(),
                        keyboardType: TextInputType.number,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Port (optional, auto-allocated)',
                          labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<bool>(
                        value: true,
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Auto-start',
                          labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: true, child: Text('Yes')),
                          DropdownMenuItem(value: false, child: Text('No')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Cloudflare Tunnel'),
                  subtitle: const Text('Create public HTTPS tunnel'),
                  value: false,
                  onChanged: (value) {},
                  activeColor: MayaTheme.neonCyan,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _deployApp,
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: const Text('Deploy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions for existing apps
          Consumer(
            builder: (context, ref, _) {
              final appsAsync = ref.watch(hostingAppsProvider);
              return appsAsync.when(
                data: (response) {
                  if (response.apps.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quick Actions', style: MayaTheme.titleMedium),
                      const SizedBox(height: 12),
                      ...response.apps.map((app) => _QuickActionTile(app: app)).toList(),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deployApp() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Deploy functionality coming soon'), backgroundColor: MayaTheme.neonCyan),
    );
  }

  Widget _buildMyAppsTab() {
    final appsAsync = ref.watch(hostingAppsProvider);

    return appsAsync.when(
      data: (response) {
        if (response.apps.isEmpty) {
          return const Center(
            child: Text('No apps deployed yet', style: MayaTheme.bodyMedium),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.apps.length,
          itemBuilder: (context, index) {
            final app = response.apps[index];
            return _MyAppTile(app: app);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading apps', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _AppTile extends ConsumerWidget {
  final HostingAppInfo app;

  const _AppTile({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = app.alive;
    final isReachable = app.reachable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (app.alive ? MayaTheme.neonEmerald : MayaTheme.error).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isRunning ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: isRunning ? MayaTheme.neonEmerald : MayaTheme.error,
            size: 20,
          ),
        ),
        title: Text(app.name, style: MayaTheme.titleMedium),
        subtitle: Text(
          '${app.kind} • Port ${app.port} • ${isRunning ? "Running" : "Stopped"}',
          style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            if (!app.alive)
              const PopupMenuItem(
                value: 'start',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Start'),
                  ],
                ),
              ),
            if (app.alive)
              const PopupMenuItem(
                value: 'stop',
                child: Row(
                  children: [
                    Icon(Icons.stop_rounded, size: 18, color: MayaTheme.error),
                    SizedBox(width: 8),
                    Text('Stop', style: TextStyle(color: MayaTheme.error)),
                  ],
                ),
              ),
            if (app.alive)
              const PopupMenuItem(
                value: 'restart',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 18, color: MayaTheme.neonViolet),
                    SizedBox(width: 8),
                    Text('Restart'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'tunnel',
              child: Row(
                children: [
                  Icon(Icons.cloud_rounded, size: 18, color: MayaTheme.neonViolet),
                  SizedBox(width: 8),
                  Text('Open Tunnel'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logs',
              child: Row(
                children: [
                  Icon(Icons.article_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('View Logs'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: MayaTheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'start') {
              final success = await ref.read(apiServiceProvider).startHostingApp(app.name);
              if (mounted) {
                ref.invalidate(hostingAppsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'App started' : 'Start failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                );
              }
            } else if (value == 'stop') {
              final success = await ref.read(apiServiceProvider).stopHostingApp(app.name);
              if (mounted) {
                ref.invalidate(hostingAppsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'App stopped' : 'Stop failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                );
              }
            } else if (value == 'restart') {
              final success = await ref.read(apiServiceProvider).restartHostingApp(app.name);
              if (mounted) {
                ref.invalidate(hostingAppsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'App restarted' : 'Restart failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                );
              }
            } else if (value == 'tunnel') {
              final success = await ref.read(apiServiceProvider).openHostingTunnel(app.name);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Tunnel opened' : 'Tunnel failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                );
              }
            } else if (value == 'logs') {
              // TODO: Show logs dialog
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: MayaTheme.slate800,
                  title: const Text('Delete App?'),
                  content: Text('Delete "${app.name}" and all its data? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final success = await ref.read(apiServiceProvider).removeHostingApp(app.name);
                if (mounted) {
                  ref.invalidate(hostingAppsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'App deleted' : 'Delete failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MyAppTile extends ConsumerWidget {
  final HostingAppInfo app;

  const _MyAppTile({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = app.alive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isRunning ? MayaTheme.neonEmerald.withValues(alpha: 0.2) : MayaTheme.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isRunning ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: isRunning ? MayaTheme.neonEmerald : MayaTheme.error,
            size: 20,
          ),
        ),
        title: Text(app.name, style: MayaTheme.titleMedium),
        subtitle: Text(
          '${app.kind} • Port ${app.port}',
          style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            if (!app.alive)
              const PopupMenuItem(
                value: 'start',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Start'),
                  ],
                ),
              ),
            if (app.alive)
              const PopupMenuItem(
                value: 'stop',
                child: Row(
                  children: [
                    Icon(Icons.stop_rounded, size: 18, color: MayaTheme.error),
                    SizedBox(width: 8),
                    Text('Stop', style: TextStyle(color: MayaTheme.error)),
                  ],
                ),
              ),
            if (app.alive)
              const PopupMenuItem(
                value: 'restart',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 18, color: MayaTheme.neonViolet),
                    SizedBox(width: 8),
                    Text('Restart'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'tunnel',
              child: Row(
                children: [
                  Icon(Icons.cloud_rounded, size: 18, color: MayaTheme.neonViolet),
                  SizedBox(width: 8),
                  Text('Open Tunnel'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logs',
              child: Row(
                children: [
                  Icon(Icons.article_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('View Logs'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: MayaTheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'start') {
              final success = await ref.read(apiServiceProvider).startHostingApp(app.name);
              if (mounted) {
                ref.invalidate(hostingAppsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'App started' : 'Start failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                );
              }
            } else if (value == 'stop') {
              final success = await ref.read(apiServiceProvider).stopHostingApp(app.name);
              if (mounted) {
                ref.invalidate(hostingAppsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'App stopped' : 'Stop failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                );
              }
            } else if (value == 'restart') {
              final success = await ref.read(apiServiceProvider).restartHostingApp(app.name);
              if (mounted) {
                ref.invalidate(hostingAppsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'App restarted' : 'Restart failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                );
              }
            } else if (value == 'tunnel') {
              final success = await ref.read(apiServiceProvider).openHostingTunnel(app.name);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Tunnel opened' : 'Tunnel failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                );
              }
            } else if (value == 'logs') {
              final logsResult = await ref.read(apiServiceProvider).getHostingLogs(app.name, limit: 200);
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: MayaTheme.slate800,
                    title: Text('Logs: ${app.name}'),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 400,
                      child: SingleChildScrollView(
                        child: SelectableText(
                          logsResult.lines.join('\n'),
                          style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ],
                  ),
                );
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: MayaTheme.slate800,
                  title: const Text('Delete App?'),
                  content: Text('Delete "${app.name}" and all its data? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final success = await ref.read(apiServiceProvider).removeHostingApp(app.name);
                if (mounted) {
                  ref.invalidate(hostingAppsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'App deleted' : 'Delete failed'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                  );
                }
              }
            }
          },
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final HostingAppInfo app;

  const _QuickActionTile({required this.app});

  @override
  Widget build(BuildContext context) {
    final isRunning = app.alive;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (app.alive ? MayaTheme.neonEmerald : MayaTheme.error).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              app.alive ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: app.alive ? MayaTheme.neonEmerald : MayaTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name, style: MayaTheme.titleSmall),
                Text('${app.kind} • Port ${app.port}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          const Spacer(),
          if (app.alive)
            OutlinedButton.icon(
              onPressed: () => ref.read(apiServiceProvider).stopHostingApp(app.name),
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text('Stop'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MayaTheme.error,
                side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => ref.read(apiServiceProvider).startHostingApp(app.name),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MayaTheme.neonEmerald,
                side: BorderSide(color: MayaTheme.neonEmerald.withValues(alpha: 0.5)),
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

// Hosting Providers
final hostingAppsProvider = FutureProvider<HostingAppsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getHostingApps();
});

// Remote VPS Deploy Screen (Phase 16)
class _RemoteVpsScreen extends ConsumerStatefulWidget {
  const _RemoteVpsScreen();

  @override
  ConsumerState<_RemoteVpsScreen> createState() => _RemoteVpsScreenState();
}

class _RemoteVpsScreenState extends ConsumerState<_RemoteVpsScreen> {
  Timer? _refreshTimer;
  String _selectedApp = '';

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(remoteConfigProvider);
        ref.invalidate(remoteContainersProvider);
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Remote VPS Deploy', style: MayaTheme.headlineSmall),
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
                ref.invalidate(remoteConfigProvider);
                ref.invalidate(remoteContainersProvider);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // VPS Config Status
              Consumer(
                builder: (context, ref, _) {
                  final configAsync = ref.watch(remoteConfigProvider);
                  return configAsync.when(
                    data: (config) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: MayaTheme.glassCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud_rounded, color: MayaTheme.neonCyan, size: 24),
                              const SizedBox(width: 12),
                              const Text('VPS Configuration', style: MayaTheme.titleMedium),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: config.configured ? MayaTheme.neonEmerald.withValues(alpha: 0.2) : MayaTheme.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  config.configured ? 'CONNECTED' : 'NOT CONFIGURED',
                                  style: MayaTheme.labelSmall.copyWith(
                                    color: config.configured ? MayaTheme.neonEmerald : MayaTheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ConfigRow(label: 'Host', value: config.host.isNotEmpty ? config.host : 'Not set'),
                          _ConfigRow(label: 'Port', value: config.port.toString()),
                          _ConfigRow(label: 'User', value: config.user.isNotEmpty ? config.user : 'Not set'),
                          _ConfigRow(label: 'SSH Key', value: config.hasKey ? 'Configured' : 'Not set'),
                          _ConfigRow(label: 'Password Auth', value: config.hasPassword ? 'Enabled' : 'Disabled'),
                          _ConfigRow(label: 'Paramiko', value: config.paramiko ? 'Available' : 'Not available'),
                        ],
                      ),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                    ),
                    error: (err, _) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: MayaTheme.glassCard(),
                      child: Column(
                        children: [
                          const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                          const SizedBox(height: 16),
                          Text('Error loading VPS config', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                          const SizedBox(height: 8),
                          Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Deploy New Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deploy New Container', style: MayaTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'Deploy a Docker container to the remote VPS. Supports building from Dockerfile or running existing images.',
                      style: MayaTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _DeployForm(onSuccess: () {
                      ref.invalidate(remoteContainersProvider);
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Container List & Actions
              Consumer(
                builder: (context, ref, _) {
                  final containersAsync = ref.watch(remoteContainersProvider);
                  return containersAsync.when(
                    data: (containers) {
                      if (containers.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: MayaTheme.glassCard(),
                          child: const Center(
                            child: Text('No containers running on VPS', style: MayaTheme.bodyMedium),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Running Containers', style: MayaTheme.titleMedium),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: containers.length,
                            itemBuilder: (context, index) {
                              final container = containers[index];
                              return _RemoteContainerTile(
                                container: container,
                                onAction: (action) async {
                                  final success = await ref.read(apiServiceProvider).remoteAction(app: container.Names?.first ?? '', action: action);
                                  if (mounted) {
                                    ref.invalidate(remoteContainersProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${action.capitalize()} ${success ? 'succeeded' : 'failed'}'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                    ),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                          const SizedBox(height: 16),
                          Text('Error loading containers', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                          const SizedBox(height: 8),
                          Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
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

class _DeployForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const _DeployForm({required this.onSuccess});

  @override
  ConsumerState<_DeployForm> createState() => _DeployFormState();
}

class _DeployFormState extends ConsumerState<_DeployForm> {
  final _appController = TextEditingController();
  final _imageController = TextEditingController();
  final _dockerfileController = TextEditingController();
  final _portsController = TextEditingController();
  final _envController = TextEditingController();

  @override
  void dispose() {
    _appController.dispose();
    _imageController.dispose();
    _dockerfileController.dispose();
    _portsController.dispose();
    _envController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _appController,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Container Name',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _imageController,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Docker Image',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dockerfileController,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Dockerfile Directory (optional)',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _portsController,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Ports (host:container, e.g., 8080:80)',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _envController,
          style: MayaTheme.bodyMedium,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Environment Variables (KEY=VALUE, one per line)',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.neonCyan,
              foregroundColor: MayaTheme.slate900,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Deploy'),
          ),
        ),
      ],
    );
  }

  void _submit() async {
    if (_appController.text.trim().isEmpty || _imageController.text.trim().isEmpty) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      final ports = _portsController.text.trim().isNotEmpty
          ? Map.fromEntries(_portsController.text.split(',').map((e) {
              final parts = e.split(':');
              return MapEntry(parts[0].trim(), parts.length > 1 ? parts[1].trim() : parts[0].trim());
            }))
          : <String, String>{};
      final env = _envController.text.trim().isNotEmpty
          ? Map.fromEntries(_envController.text.split('\n').map((e) {
              final parts = e.split('=');
              return MapEntry(parts[0].trim(), parts.length > 1 ? parts[1].trim() : '');
            }))
          : <String, String>{};

      final result = await apiService.deployRemote(
        app: _appController.text.trim(),
        image: _imageController.text.trim(),
        dockerfileDir: _dockerfileController.text.trim().isNotEmpty ? _dockerfileController.text.trim() : null,
        ports: ports.isNotEmpty ? ports : null,
        env: env.isNotEmpty ? env : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deploy ${result.ok ? 'succeeded' : 'failed'}'),
            backgroundColor: result.ok ? MayaTheme.neonEmerald : MayaTheme.error,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

class _RemoteContainerTile extends ConsumerWidget {
  final Map<String, dynamic> container;
  final Future<void> Function(String) onAction;

  const _RemoteContainerTile({required this.container, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = (container['Names'] as List?)?.first ?? 'unknown';
    final status = container['Status'] as String? ?? 'unknown';
    final image = container['Image'] as String? ?? 'unknown';
    final ports = container['Ports'] as String? ?? 'none';
    final isRunning = status.toLowerCase().contains('up');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRunning ? MayaTheme.neonEmerald.withValues(alpha: 0.2) : MayaTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isRunning ? 'Running' : 'Stopped',
                  style: MayaTheme.labelSmall.copyWith(
                    color: isRunning ? MayaTheme.neonEmerald : MayaTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name, style: MayaTheme.titleSmall),
              ),
              const Spacer(),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                itemBuilder: (context) => [
                  if (!isRunning)
                    const PopupMenuItem(
                      value: 'start',
                      child: Row(children: [Icon(Icons.play_arrow_rounded, size: 18), SizedBox(width: 8), Text('Start')]),
                    ),
                  if (isRunning)
                    const PopupMenuItem(
                      value: 'stop',
                      child: Row(children: [Icon(Icons.stop_rounded, size: 18, color: MayaTheme.error), SizedBox(width: 8), Text('Stop', style: TextStyle(color: MayaTheme.error))]),
                    ),
                  const PopupMenuItem(
                    value: 'restart',
                    child: Row(children: [Icon(Icons.restart_alt_rounded, size: 18, color: MayaTheme.neonViolet), SizedBox(width: 8), Text('Restart')]),
                  ),
                  const PopupMenuItem(
                    value: 'logs',
                    child: Row(children: [Icon(Icons.article_rounded, size: 18), SizedBox(width: 8), Text('View Logs')]),
                  ),
                ],
                onSelected: (value) async {
                  final success = await ref.read(apiServiceProvider).remoteAction(app: container['Names']?.first ?? '', action: value);
                  if (mounted) {
                    ref.invalidate(remoteContainersProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${value.capitalize()} ${success ? 'succeeded' : 'failed'}'), backgroundColor: success ? MayaTheme.neonEmerald : MayaTheme.error),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemoteConfigRow extends StatelessWidget {
  final String label;
  final String value;

  const _RemoteConfigRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
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

// Remote VPS Providers
final remoteConfigProvider = FutureProvider<RemoteConfigResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getRemoteConfig();
});

final remoteContainersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getRemoteContainers();
});

// Cognition Loop Screen (Phase 17)
class _CognitionLoopScreen extends ConsumerStatefulWidget {
  const _CognitionLoopScreen();

  @override
  ConsumerState<_CognitionLoopScreen> createState() => _CognitionLoopScreenState();
}

class _CognitionLoopScreenState extends ConsumerState<_CognitionLoopScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.invalidate(cognitiveStatusProvider);
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
    final statusAsync = ref.watch(cognitiveStatusProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Cognition Loop', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(cognitiveStatusProvider),
            ),
          ],
        ),
        body: statusAsync.when(
          data: (status) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCardGlow(
                    glowColor: status.running ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (status.running ? MayaTheme.neonEmerald : MayaTheme.neonOrange).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              status.running ? Icons.play_circle_rounded : Icons.pause_circle_rounded,
                              color: status.running ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.enabled ? 'Cognition Enabled' : 'Cognition Disabled',
                                  style: MayaTheme.titleMedium.copyWith(
                                    color: status.enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${status.status} • Mode: ${status.mode}',
                                  style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            status.running ? 'RUNNING' : 'PAUSED',
                            style: MayaTheme.headlineMedium.copyWith(
                              color: status.running ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats
                    if (status.cycleCount != null || status.lastCycleAt != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Cycles',
                              value: status.cycleCount?.toString() ?? 'N/A',
                              color: MayaTheme.neonCyan,
                              icon: Icons.repeat_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Last Cycle',
                              value: status.lastCycleAt != null
                                  ? DateTime.fromMillisecondsSinceEpoch((status.lastCycleAt! * 1000).round())
                                      .toString()
                                      .substring(11, 19)
                                  : 'Never',
                              color: MayaTheme.neonViolet,
                              icon: Icons.access_time_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Current Step
                    if (status.currentStep != null && status.currentStep!.isNotEmpty) ...[
                      const Text('Current Step', style: MayaTheme.titleMedium),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: MayaTheme.glassCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(status.currentStep!, style: MayaTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Controls
                    const Text('Controls', style: MayaTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: status.running ? _pauseLoop : null,
                            icon: const Icon(Icons.pause_rounded),
                            label: const Text('Pause'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MayaTheme.neonOrange,
                              foregroundColor: MayaTheme.slate900,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: status.running ? null : _resumeLoop,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Resume'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MayaTheme.neonEmerald,
                              foregroundColor: MayaTheme.slate900,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _triggerCycle,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Single Cycle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MayaTheme.neonCyan,
                              foregroundColor: MayaTheme.slate900,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Cycle History (would need additional endpoint)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: MayaTheme.glassCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cycle History', style: MayaTheme.titleMedium),
                          const SizedBox(height: 12),
                          const Text(
                            'Cycle history would be displayed here with a dedicated endpoint.',
                            style: MayaTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                const SizedBox(height: 16),
                Text('Error loading status', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                const SizedBox(height: 8),
                Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _triggerCycle() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.triggerCognitiveCycle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cycle triggered: ${result.step}'),
            backgroundColor: result.ok ? MayaTheme.neonEmerald : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _pauseLoop() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.pauseCognitiveLoop();
      ref.invalidate(cognitiveStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Cognition loop paused'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _resumeLoop() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.resumeCognitiveLoop();
      ref.invalidate(cognitiveStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Cognition loop resumed'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
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
    return Container(
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
    );
  }
}

// Cognition Loop Provider
final cognitiveStatusProvider = FutureProvider<CognitiveStatusResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCognitiveStatus();
});

// AGI Architecture Screen
class _AGIArchitectureScreen extends ConsumerStatefulWidget {
  const _AGIArchitectureScreen();

  @override
  ConsumerState<_AGIArchitectureScreen> createState() => _AGIArchitectureScreenState();
}

class _AGIArchitectureScreenState extends ConsumerState<_AGIArchitectureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('AGI Architecture', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.architecture_rounded), text: 'Synthesizer'),
              Tab(icon: Icon(Icons.groups_rounded), text: 'Society'),
              Tab(icon: Icon(Icons.memory_rounded), text: 'Procedural Memory'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _SynthesizerTab(),
            _SocietyTab(),
            _ProceduralMemoryTab(),
          ],
        ),
      ),
    );
  }
}

class _SynthesizerTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(synthesizeListProvider);

    return async.when(
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Synthesis Jobs', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Manage and monitor cognitive synthesis operations',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            if (data.items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: MayaTheme.glassCard(),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.architecture_rounded, size: 48, color: Colors.white38),
                      SizedBox(height: 16),
                      Text('No synthesis jobs found', style: MayaTheme.bodyMedium),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final item = data.items[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: MayaTheme.glassCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: MayaTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(item.description, style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            _StatusChip(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text('Created: ${item.createdAt.toString().substring(0, 19)}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                            const SizedBox(width: 16),
                            if (item.completedAt != null) ...[
                              Icon(Icons.check_circle_rounded, size: 14, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text('Completed: ${item.completedAt!.toString().substring(0, 19)}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
        const SizedBox(height: 16),
        Text('Error loading synthesis jobs', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = MayaTheme.neonEmerald;
        break;
      case 'running':
        color = MayaTheme.neonCyan;
        break;
      case 'failed':
        color = MayaTheme.error;
        break;
      case 'pending':
        color = MayaTheme.neonOrange;
        break;
      default:
        color = Colors.white38;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: MayaTheme.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _SocietyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(societyStatusProvider);
    final agentsAsync = ref.watch(societyAgentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agent Society', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Multi-agent coordination and task tendering',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          // Status Overview
          statusAsync.when(
            data: (status) => Row(
              children: [
                Expanded(child: _SocietyStatCard(label: 'Total Agents', value: status.totalAgents.toString(), color: MayaTheme.neonCyan, icon: Icons.people_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _SocietyStatCard(label: 'Active', value: status.activeAgents.toString(), color: MayaTheme.neonEmerald, icon: Icons.circle_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _SocietyStatCard(label: 'Queued Tasks', value: status.tasksQueued.toString(), color: MayaTheme.neonOrange, icon: Icons.queue_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _SocietyStatCard(label: 'Running', value: status.tasksRunning.toString(), color: MayaTheme.neonViolet, icon: Icons.play_circle_rounded)),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          // Agents List
          const Text('Agents', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          agentsAsync.when(
            data: (data) => data.agents.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(child: Text('No agents spawned', style: MayaTheme.bodyMedium)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.agents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final agent = data.agents[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: MayaTheme.glassCard(),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.psychology_rounded, color: MayaTheme.neonViolet, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(agent.role, style: MayaTheme.titleMedium),
                                  Text('ID: ${agent.id}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                                  if (agent.capabilities != null && agent.capabilities!.isNotEmpty)
                                    Text('Capabilities: ${agent.capabilities!.keys.join(', ')}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                                ],
                              ),
                            ),
                            _StatusChip(status: agent.status),
                          ],
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SocietyStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SocietyStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ProceduralMemoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(proceduralListProvider);
    final statsAsync = ref.watch(proceduralStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Procedural Memory', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Learned skills and procedural knowledge',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          // Stats
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(child: _ProcStatCard(label: 'Total Skills', value: stats.totalSkills.toString(), color: MayaTheme.neonCyan, icon: Icons.memory_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _ProcStatCard(label: 'Verified', value: stats.verifiedSkills.toString(), color: MayaTheme.neonEmerald, icon: Icons.verified_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _ProcStatCard(label: 'Avg Confidence', value: stats.avgConfidence.toStringAsFixed(2), color: MayaTheme.neonViolet, icon: Icons.trending_up_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _ProcStatCard(label: 'Avg Success Rate', value: '${(stats.avgSuccessRate * 100).toStringAsFixed(1)}%', color: MayaTheme.neonOrange, icon: Icons.check_circle_rounded)),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          // Skills List
          const Text('Skills', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          listAsync.when(
            data: (data) => data.skills.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(child: Text('No skills learned yet', style: MayaTheme.bodyMedium)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.skills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final skill = data.skills[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: MayaTheme.glassCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(skill.name, style: MayaTheme.titleMedium),
                                          const SizedBox(width: 8),
                                          if (skill.verified)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: MayaTheme.neonEmerald.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: MayaTheme.neonEmerald),
                                              ),
                                              child: Text('VERIFIED', style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonEmerald)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(skill.description, style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Confidence: ${(skill.confidence * 100).toStringAsFixed(1)}%', style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
                                    Text('Success Rate: ${(skill.successRate * 100).toStringAsFixed(1)}%', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                                    Text('Uses: ${skill.usageCount}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: skill.applicableGoals.take(4).map((goal) => Chip(
                                label: Text(goal, style: MayaTheme.labelSmall),
                                backgroundColor: MayaTheme.neonCyan.withValues(alpha: 0.1),
                                side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
                              )).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _ProcStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ProcStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

// Maya Cognitive Core Screen (Phase 19)
class _MayaCognitiveCoreScreen extends ConsumerStatefulWidget {
  const _MayaCognitiveCoreScreen();

  @override
  ConsumerState<_MayaCognitiveCoreScreen> createState() => _MayaCognitiveCoreScreenState();
}

class _MayaCognitiveCoreScreenState extends ConsumerState<_MayaCognitiveCoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(coreStatusProvider);
        ref.invalidate(episodicListProvider);
        ref.invalidate(episodicStatsProvider);
        ref.invalidate(knowledgeStatsProvider);
        ref.invalidate(workingMemoryCapacityProvider);
        ref.invalidate(coreIdentityProvider);
        ref.invalidate(coreModelsProvider);
        ref.invalidate(coreCheckpointsProvider);
        ref.invalidate(coreAuditProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Maya Cognitive Core', style: MayaTheme.headlineSmall),
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
                ref.invalidate(coreStatusProvider);
                ref.invalidate(episodicListProvider);
                ref.invalidate(episodicStatsProvider);
                ref.invalidate(knowledgeStatsProvider);
                ref.invalidate(workingMemoryCapacityProvider);
                ref.invalidate(coreIdentityProvider);
                ref.invalidate(coreModelsProvider);
                ref.invalidate(coreCheckpointsProvider);
                ref.invalidate(coreAuditProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.psychology_rounded), text: 'Hippocampus'),
              Tab(icon: Icon(Icons.lightbulb_rounded), text: 'Semantic Memory'),
              Tab(icon: Icon(Icons.memory_rounded), text: 'Working Memory'),
              Tab(icon: Icon(Icons.web_rounded), text: 'Browser'),
              Tab(icon: Icon(Icons.code_rounded), text: 'Sandbox'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _HippocampusTab(),
            _SemanticMemoryTab(),
            _WorkingMemoryTab(),
            _BrowserTab(),
            _SandboxTab(),
          ],
        ),
      ),
    );
  }
}

class _HippocampusTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(episodicListProvider);
    final statsAsync = ref.watch(episodicStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hippocampus (Episodic Memory)', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Recent experiences and episodic memories',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          // Stats
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(child: _CoreStatCard(label: 'Total Episodes', value: stats.totalEpisodes.toString(), color: MayaTheme.neonCyan, icon: Icons.psychology_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _CoreStatCard(label: 'Successful', value: stats.successfulEpisodes.toString(), color: MayaTheme.neonEmerald, icon: Icons.check_circle_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _CoreStatCard(label: 'Failed', value: stats.failedEpisodes.toString(), color: MayaTheme.error, icon: Icons.cancel_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _CoreStatCard(label: 'Avg Confidence', value: stats.avgConfidence.toStringAsFixed(2), color: MayaTheme.neonViolet, icon: Icons.trending_up_rounded)),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          // Episodes List
          const Text('Recent Episodes', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          listAsync.when(
            data: (data) => data.episodes.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(child: Text('No episodic memories yet', style: MayaTheme.bodyMedium)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.episodes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final episode = data.episodes[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: MayaTheme.glassCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(episode.goal, style: MayaTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: episode.outcome == 'success'
                                                  ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                                                  : MayaTheme.error.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: episode.outcome == 'success'
                                                    ? MayaTheme.neonEmerald
                                                    : MayaTheme.error,
                                              ),
                                            ),
                                            child: Text(
                                              episode.outcome.toUpperCase(),
                                              style: MayaTheme.labelSmall.copyWith(
                                                color: episode.outcome == 'success'
                                                    ? MayaTheme.neonEmerald
                                                    : MayaTheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Confidence: ${(episode.confidence * 100).toStringAsFixed(1)}%', style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
                                      Text('Time: ${episode.timestamp.toString().substring(0, 19)}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (episode.metadata != null && episode.metadata!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Metadata: ${episode.metadata.toString()}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SemanticMemoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(knowledgeStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Semantic Memory (Knowledge)', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Concepts, facts, and belief network',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          // Stats
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(child: _CoreStatCard(label: 'Total Beliefs', value: stats.totalBeliefs.toString(), color: MayaTheme.neonCyan, icon: Icons.lightbulb_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _CoreStatCard(label: 'Domains', value: stats.domains.toString(), color: MayaTheme.neonViolet, icon: Icons.category_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _CoreStatCard(label: 'Avg Confidence', value: stats.avgConfidence.toStringAsFixed(2), color: MayaTheme.neonEmerald, icon: Icons.trending_up_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _CoreStatCard(label: 'Retrieval Engine', value: stats.retrievalEngine.toString(), color: MayaTheme.neonOrange, icon: Icons.data_array_rounded)),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          // Knowledge Query
          const Text('Query Knowledge', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          _KnowledgeQueryForm(),
          const SizedBox(height: 24),
          // Learn Knowledge
          const Text('Teach Maya (Add Knowledge)', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          _LearnKnowledgeForm(),
        ],
      ),
    );
  }
}

class _KnowledgeQueryForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_KnowledgeQueryForm> createState() => _KnowledgeQueryFormState();
}

class _KnowledgeQueryFormState extends ConsumerState<_KnowledgeQueryForm> {
  final _queryController = TextEditingController();
  final _domainController = TextEditingController();
  final _limitController = TextEditingController(text: '5');
  KnowledgeQueryResponse? _result;

  @override
  void dispose() {
    _queryController.dispose();
    _domainController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.queryKnowledge(
        query: _queryController.text,
        domain: _domainController.text.isEmpty ? null : _domainController.text,
        limit: int.tryParse(_limitController.text) ?? 5,
      );
      setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Query failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _queryController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Query',
              hintText: 'Enter search query...',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _domainController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Domain (optional)',
                    hintText: 'general, coding, science...',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _limitController,
                  style: MayaTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Limit',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _query,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Query'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            const Divider(color: MayaTheme.glassWhite10),
            const SizedBox(height: 8),
            const Text('Results', style: MayaTheme.titleSmall),
            const SizedBox(height: 8),
            ..._result!.results.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.proposition, style: MayaTheme.bodyMedium)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${(item.confidence * 100).toStringAsFixed(0)}%', style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Domain: ${item.domain} • Source: ${item.source}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  Text('Created: ${item.createdAt.toString().substring(0, 19)}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _LearnKnowledgeForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LearnKnowledgeForm> createState() => _LearnKnowledgeFormState();
}

class _LearnKnowledgeFormState extends ConsumerState<_LearnKnowledgeForm> {
  final _propositionController = TextEditingController();
  final _confidenceController = TextEditingController(text: '0.6');
  final _sourceController = TextEditingController(text: 'testimony');
  final _domainController = TextEditingController(text: 'general');

  @override
  void dispose() {
    _propositionController.dispose();
    _confidenceController.dispose();
    _sourceController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _learn() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.learnKnowledge(
        proposition: _propositionController.text,
        confidence: double.tryParse(_confidenceController.text) ?? 0.6,
        source: _sourceController.text,
        domain: _domainController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Knowledge ${result.action}: ${result.beliefId} (confidence: ${result.confidence})'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Learn failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _propositionController,
            style: MayaTheme.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Proposition (fact to learn)',
              hintText: 'e.g., "The capital of France is Paris"',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _confidenceController,
                  style: MayaTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Confidence (0-1)',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sourceController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Source',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _domainController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Domain',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _learn,
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: const Text('Learn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonEmerald,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkingMemoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacityAsync = ref.watch(workingMemoryCapacityProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Working Memory', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Current active context and attention slots',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          // Capacity
          capacityAsync.when(
            data: (capacity) => Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _CoreStatCard(label: 'Total Slots', value: capacity.totalSlots.toString(), color: MayaTheme.neonCyan, icon: Icons.slots_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _CoreStatCard(label: 'Used', value: capacity.usedSlots.toString(), color: MayaTheme.neonOrange, icon: Icons.memory_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _CoreStatCard(label: 'Free', value: capacity.freeSlots.toString(), color: MayaTheme.neonEmerald, icon: Icons.storage_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _CoreStatCard(label: 'Total Attention', value: capacity.totalAttention.toStringAsFixed(1), color: MayaTheme.neonViolet, icon: Icons.center_focus_strong_rounded)),
                  ],
                ),
                const SizedBox(height: 16),
                if (capacity.byType.isNotEmpty) ...[
                  const Text('By Type', style: MayaTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: capacity.byType.entries.map((e) => Chip(
                      label: Text('${e.key}: ${e.value}', style: MayaTheme.labelSmall),
                      backgroundColor: MayaTheme.neonCyan.withValues(alpha: 0.1),
                      side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          // Search Working Memory
          const Text('Search Working Memory', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          _WorkingMemorySearchForm(),
          const SizedBox(height: 24),
          // Add to Working Memory
          const Text('Add to Working Memory', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          _WorkingMemoryAddForm(),
        ],
      ),
    );
  }
}

class _WorkingMemorySearchForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WorkingMemorySearchForm> createState() => _WorkingMemorySearchFormState();
}

class _WorkingMemorySearchFormState extends ConsumerState<_WorkingMemorySearchForm> {
  final _queryController = TextEditingController();
  final _limitController = TextEditingController(text: '10');
  final _typeController = TextEditingController();
  WorkingMemorySearchResponse? _result;

  @override
  void dispose() {
    _queryController.dispose();
    _limitController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.searchWorkingMemory(
        query: _queryController.text,
        limit: int.tryParse(_limitController.text) ?? 10,
        type: _typeController.text.isEmpty ? null : _typeController.text,
      );
      setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _queryController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Query',
              hintText: 'Search working memory...',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _typeController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Type (optional)',
                    hintText: 'fact, goal, observation...',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _limitController,
                  style: MayaTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Limit',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            const Divider(color: MayaTheme.glassWhite10),
            const SizedBox(height: 8),
            const Text('Results', style: MayaTheme.titleSmall),
            const SizedBox(height: 8),
            ..._result!.results.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.content, style: MayaTheme.bodyMedium)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item.type.toUpperCase(), style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Attention: ${item.attention.toStringAsFixed(2)} • Time: ${item.createdAt.toString().substring(0, 19)}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _WorkingMemoryAddForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WorkingMemoryAddForm> createState() => _WorkingMemoryAddFormState();
}

class _WorkingMemoryAddFormState extends ConsumerState<_WorkingMemoryAddForm> {
  final _contentController = TextEditingController();
  final _typeController = TextEditingController(text: 'fact');
  final _attentionController = TextEditingController(text: '1.0');

  @override
  void dispose() {
    _contentController.dispose();
    _typeController.dispose();
    _attentionController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.addWorkingMemory(
        content: _contentController.text,
        type: _typeController.text,
        attention: double.tryParse(_attentionController.text) ?? 1.0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Added to working memory'), backgroundColor: MayaTheme.neonEmerald),
        );
        _contentController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _contentController,
            style: MayaTheme.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Content',
              hintText: 'What to remember...',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _typeController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _attentionController,
                  style: MayaTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Attention (0-1)',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add to Working Memory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonEmerald,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowserTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Browser Automation', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Control browser actions and view results',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          _BrowserActionForm(),
        ],
      ),
    );
  }
}

class _BrowserActionForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BrowserActionForm> createState() => _BrowserActionFormState();
}

class _BrowserActionFormState extends ConsumerState<_BrowserActionForm> {
  String _selectedAction = 'open';
  final _urlController = TextEditingController();
  final _selectorController = TextEditingController();
  final _textController = TextEditingController();
  final _queryController = TextEditingController();
  BrowserActionResponse? _result;

  final List<String> _actions = ['open', 'click', 'type', 'get_text', 'screenshot', 'search_google'];

  @override
  void dispose() {
    _urlController.dispose();
    _selectorController.dispose();
    _textController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _execute() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.browserAction(
        action: _selectedAction,
        url: _urlController.text.isEmpty ? null : _urlController.text,
        selector: _selectorController.text.isEmpty ? null : _selectorController.text,
        text: _textController.text.isEmpty ? null : _textController.text,
        query: _queryController.text.isEmpty ? null : _queryController.text,
      );
      setState(() => _result = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Action completed' : 'Action failed: ${result.error ?? 'Unknown error'}'),
            backgroundColor: result.success ? MayaTheme.neonEmerald : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Browser action failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedAction,
            decoration: InputDecoration(
              labelText: 'Action',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            dropdownColor: MayaTheme.slate800,
            style: MayaTheme.bodyMedium,
            items: _actions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (v) => setState(() => _selectedAction = v!),
          ),
          const SizedBox(height: 12),
          if (_selectedAction == 'open' || _selectedAction == 'search_google')
            TextField(
              controller: _selectedAction == 'open' ? _urlController : _queryController,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: _selectedAction == 'open' ? 'URL' : 'Search Query',
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          if (_selectedAction == 'click' || _selectedAction == 'type' || _selectedAction == 'get_text')
            TextField(
              controller: _selectorController,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'CSS Selector',
                hintText: 'e.g., button.submit, #main-content',
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          if (_selectedAction == 'type')
            TextField(
              controller: _textController,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Text to Type',
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _execute,
              icon: const Icon(Icons.web_rounded),
              label: const Text('Execute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            const Divider(color: MayaTheme.glassWhite10),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(_result!.success ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: _result!.success ? MayaTheme.neonEmerald : MayaTheme.error),
                const SizedBox(width: 8),
                Text(_result!.success ? 'Success' : 'Failed', style: MayaTheme.bodyMedium),
              ],
            ),
            if (_result!.content != null) ...[
              const SizedBox(height: 12),
              const Text('Content:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard(),
                child: SingleChildScrollView(
                  child: SelectableText(_result!.content!, style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace')),
                ),
              ),
            ],
            if (_result!.screenshotPath != null) ...[
              const SizedBox(height: 12),
              const Text('Screenshot:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard(),
                child: Text(_result!.screenshotPath!, style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
              ),
            ],
            if (_result!.error != null) ...[
              const SizedBox(height: 12),
              const Text('Error:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard().copyWith(
                  border: Border.all(color: MayaTheme.error.withValues(alpha: 0.5)),
                ),
                child: Text(_result!.error!, style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SandboxTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Code Sandbox', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Execute code in secure sandbox environment',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          _SandboxExecuteForm(),
        ],
      ),
    );
  }
}

class _SandboxExecuteForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SandboxExecuteForm> createState() => _SandboxExecuteFormState();
}

class _SandboxExecuteFormState extends ConsumerState<_SandboxExecuteForm> {
  String _selectedLanguage = 'python';
  final _codeController = TextEditingController();
  final _timeoutController = TextEditingController(text: '30');
  SandboxExecuteResponse? _result;

  final List<String> _languages = ['python', 'javascript', 'bash', 'typescript'];

  @override
  void dispose() {
    _codeController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  Future<void> _execute() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.sandboxExecute(
        code: _codeController.text,
        language: _selectedLanguage,
        timeoutSeconds: int.tryParse(_timeoutController.text) ?? 30,
      );
      setState(() => _result = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Execution completed' : 'Execution failed: ${result.error ?? 'Unknown error'}'),
            backgroundColor: result.success ? MayaTheme.neonEmerald : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sandbox execution failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: 'Language',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  dropdownColor: MayaTheme.slate800,
                  style: MayaTheme.bodyMedium,
                  items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _timeoutController,
                  style: MayaTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Timeout (s)',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            style: MayaTheme.bodyMedium.copyWith(fontFamily: 'monospace'),
            maxLines: 15,
            decoration: InputDecoration(
              hintText: '# Enter code here\nprint("Hello from Maya!")',
              hintStyle: MayaTheme.bodySmall.copyWith(color: Colors.white38, fontFamily: 'monospace'),
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _execute,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Execute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            const Divider(color: MayaTheme.glassWhite10),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(_result!.success ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: _result!.success ? MayaTheme.neonEmerald : MayaTheme.error),
                const SizedBox(width: 8),
                Text(_result!.success ? 'Success' : 'Failed', style: MayaTheme.bodyMedium),
                const SizedBox(width: 16),
                if (_result!.executionTimeMs != null)
                  Text('Time: ${_result!.executionTimeMs!.toStringAsFixed(0)}ms', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                if (_result!.exitCode != null)
                  Text('Exit: ${_result!.exitCode}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
            if (_result!.output != null && _result!.output!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Output:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard(),
                child: SingleChildScrollView(
                  child: SelectableText(_result!.output!, style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace', color: Colors.white70)),
                ),
              ),
            ],
            if (_result!.error != null && _result!.error!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Error:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard().copyWith(
                  border: Border.all(color: MayaTheme.error.withValues(alpha: 0.5)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(_result!.error!, style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace', color: MayaTheme.error)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CoreStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _CoreStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

// Business Analysis Screen (Phase 20)
class _BusinessAnalysisScreen extends ConsumerStatefulWidget {
  const _BusinessAnalysisScreen();

  @override
  ConsumerState<_BusinessAnalysisScreen> createState() => _BusinessAnalysisScreenState();
}

class _BusinessAnalysisScreenState extends ConsumerState<_BusinessAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Business Analysis', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(businessMissionsProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.business_rounded), text: 'Missions & Reports'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Run Analysis'),
              Tab(icon: Icon(Icons.description_rounded), text: 'Report Detail'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _BusinessMissionsTab(),
            _RunAnalysisTab(),
            _ReportDetailTab(),
          ],
        ),
      ),
    );
  }
}

class _BusinessMissionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(businessMissionsProvider);

    return missionsAsync.when(
      data: (data) => data.missions.isEmpty
          ? _emptyState('No Business Missions', 'Create a business mission to start analysis', Icons.business_rounded)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Business Missions', style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Select a mission to view its analysis reports',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.missions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final mission = data.missions[index];
                      return _MissionCard(mission: mission);
                    },
                  ),
                ],
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => _errorState(err.toString()),
    );
  }
}

class _MissionCard extends ConsumerWidget {
  final MissionInfo mission;

  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MayaTheme.neonEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.business_rounded, color: MayaTheme.neonEmerald, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mission.name, style: MayaTheme.titleMedium),
                    Text('ID: ${mission.id}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                    if (mission.description.isNotEmpty)
                      Text(mission.description, style: MayaTheme.bodySmall.copyWith(color: Colors.white38), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mission.active ? MayaTheme.neonEmerald.withValues(alpha: 0.2) : MayaTheme.neonOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: mission.active ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                    ),
                    child: Text(
                      mission.active ? 'ACTIVE' : 'INACTIVE',
                      style: MayaTheme.labelSmall.copyWith(color: mission.active ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Created: ${mission.createdAt.toString().substring(0, 10)}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MissionReportsList(missionId: mission.id),
        ],
      ),
    );
  }
}

class _MissionReportsList extends ConsumerWidget {
  final String missionId;

  const _MissionReportsList({required this.missionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(businessReportsProvider(missionId));

    return reportsAsync.when(
      data: (data) => data.reports.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: const Center(child: Text('No reports yet. Run an analysis to generate reports.', style: MayaTheme.bodyMedium)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reports', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final report = data.reports[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: MayaTheme.glassCard(),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.description_rounded, color: MayaTheme.neonCyan, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(report.objectiveDesc, style: MayaTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('Report ID: ${report.id} • ${DateTime.fromMillisecondsSinceEpoch((report.createdAt * 1000).round()).toString().substring(0, 19)}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios_rounded, color: MayaTheme.neonCyan, size: 18),
                            onPressed: () => _showReportDetail(context, ref, missionId, report.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)))),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: MayaTheme.glassCard(),
        child: Text('Error loading reports: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
      ),
    );
  }

  void _showReportDetail(BuildContext context, WidgetRef ref, String missionId, String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ReportDetailView(missionId: missionId, reportId: reportId),
      ),
    );
  }
}

class _RunAnalysisTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(businessMissionsFamily(false));

    return missionsAsync.when(
      data: (data) => data.missions.isEmpty
          ? _emptyState('No Business Missions', 'Create a business mission first in the Cognition Loop screen', Icons.business_rounded)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Run Business Analysis', style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Select a mission and objective to run the 4-agent analysis pipeline (Pricing → Finance → Marketing → Strategy)',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  _AnalysisForm(missions: data.missions),
                ],
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => _errorState(err.toString()),
    );
  }
}

class _AnalysisForm extends ConsumerStatefulWidget {
  final List<MissionInfo> missions;

  const _AnalysisForm({required this.missions});

  @override
  ConsumerState<_AnalysisForm> createState() => _AnalysisFormState();
}

class _AnalysisFormState extends ConsumerState<_AnalysisForm> {
  String? _selectedMissionId;
  String _selectedObjectiveId = '';
  BusinessAnalyzeResponse? _result;
  bool _isLoading = false;

  Future<void> _runAnalysis() async {
    if (_selectedMissionId == null) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.runBusinessAnalysis(
        missionId: _selectedMissionId!,
        objectiveId: _selectedObjectiveId.isEmpty ? null : _selectedObjectiveId,
      );
      setState(() {
        _result = result;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis complete: ${result.id}'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: MayaTheme.glassCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Mission', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMissionId,
                decoration: InputDecoration(
                  hintText: 'Choose a business mission',
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                dropdownColor: MayaTheme.slate800,
                style: MayaTheme.bodyMedium,
                items: widget.missions.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                onChanged: (v) => setState(() => _selectedMissionId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(text: _selectedObjectiveId),
                style: MayaTheme.bodyMedium,
                onChanged: (v) => _selectedObjectiveId = v,
                decoration: InputDecoration(
                  labelText: 'Objective ID (optional)',
                  hintText: 'Leave empty to auto-select highest priority pending objective',
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runAnalysis,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                      : const Icon(Icons.analytics_rounded),
                  label: Text(_isLoading ? 'Analyzing...' : 'Run Analysis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonCyan,
                    foregroundColor: MayaTheme.slate900,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 24),
          _AnalysisResultCard(result: _result!),
        ],
      ],
    );
  }
}

class _AnalysisResultCard extends StatelessWidget {
  final BusinessAnalyzeResponse result;

  const _AnalysisResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCardGlow(glowColor: MayaTheme.neonEmerald),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: MayaTheme.neonEmerald, size: 24),
              const SizedBox(width: 8),
              Text('Analysis Complete', style: MayaTheme.titleMedium.copyWith(color: MayaTheme.neonEmerald)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Report ID: ${result.id}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          Text('Objective: ${result.objectiveDesc}', style: MayaTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          const Text('Executive Summary', style: MayaTheme.labelMedium),
          const SizedBox(height: 8),
          Text(result.combinedSummary, style: MayaTheme.bodyMedium),
          const SizedBox(height: 16),
          const Text('Agent Responses', style: MayaTheme.labelMedium),
          const SizedBox(height: 8),
          ...result.agentResponses.entries.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key.toUpperCase(), style: MayaTheme.labelMedium.copyWith(color: MayaTheme.neonCyan)),
                const SizedBox(height: 4),
                Text(entry.value, style: MayaTheme.bodySmall, maxLines: 4, overflow: TextOverflow.ellipsis),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ReportDetailTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Report Detail', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Navigate from the Missions & Reports tab to view a full report with all agent responses',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: MayaTheme.glassCard(),
            child: Column(
              children: [
                Icon(Icons.description_rounded, size: 48, color: Colors.white38),
                const SizedBox(height: 16),
                const Text('Select a report from the Missions & Reports tab', style: MayaTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('to view the full detail with all agent responses', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailView extends ConsumerWidget {
  final String missionId;
  final String reportId;

  const _ReportDetailView({required this.missionId, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(businessReportDetailProvider((missionId: missionId, reportId: reportId)));

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Report Detail', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: detailAsync.when(
          data: (detail) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MayaTheme.neonEmerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.description_rounded, color: MayaTheme.neonEmerald, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Report: ${detail.id}', style: MayaTheme.titleMedium),
                          Text('Mission: ${detail.missionId}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                          Text('Objective: ${detail.objectiveId}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                          Text('Created: ${DateTime.fromMillisecondsSinceEpoch((detail.createdAt * 1000).round()).toString()}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Objective Description', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: Text(detail.objectiveDesc, style: MayaTheme.bodyMedium),
                ),
                const SizedBox(height: 24),
                const Text('Executive Summary', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCardGlow(glowColor: MayaTheme.neonEmerald),
                  child: Text(detail.combinedSummary, style: MayaTheme.bodyMedium),
                ),
                const SizedBox(height: 24),
                const Text('Agent Responses', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                ...detail.agentResponses.entries.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(entry.key.toUpperCase(), style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(entry.value, style: MayaTheme.bodyMedium.copyWith(fontFamily: 'monospace')),
                    ],
                  ),
                )),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
          error: (err, _) => Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
              const SizedBox(height: 16),
              Text('Error loading report', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
              const SizedBox(height: 8),
              Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          )),
        ),
      ),
    );
  }
}

Widget _emptyState(String title, String subtitle, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.white38),
        const SizedBox(height: 16),
        Text(title, style: MayaTheme.titleMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: MayaTheme.bodyMedium.copyWith(color: Colors.white54), textAlign: TextAlign.center),
      ],
    ),
  );
}

Widget _errorState(String error) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
        const SizedBox(height: 16),
        Text('Error', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(error, style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ],
    ),
  );
}

class _CoreStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _CoreStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

// AGI Architecture Part 2 Providers
// Synthesizer
final synthesizeListProvider = FutureProvider<SynthesizeListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getSynthesisList();
});

// Society
final societyStatusProvider = FutureProvider<SocietyStatusResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getSocietyStatus();
});

final societyAgentsProvider = FutureProvider<SocietyAgentsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getSocietyAgents();
});

// Procedural Memory
final proceduralListProvider = FutureProvider<ProceduralListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getProceduralSkills();
});

final proceduralStatsProvider = FutureProvider<ProceduralStatsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getProceduralStats();
});

// Maya Cognitive Core Providers (Phase 19)
final coreStatusProvider = FutureProvider<CoreStatusResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCoreStatus();
});

final episodicListProvider = FutureProvider<EpisodicListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getEpisodicMemory();
});

final episodicStatsProvider = FutureProvider<EpisodicStatsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getEpisodicStats();
});

final knowledgeStatsProvider = FutureProvider<KnowledgeStatsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getKnowledgeStats();
});

final workingMemoryCapacityProvider = FutureProvider<WorkingMemoryCapacityResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getWorkingMemoryCapacity();
});

final coreIdentityProvider = FutureProvider<CoreIdentityResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getIdentity();
});

final coreModelsProvider = FutureProvider<CoreModelsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getModels();
});

final coreCheckpointsProvider = FutureProvider<CoreCheckpointsResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.listCheckpoints();
});

final coreAuditProvider = FutureProvider<CoreAuditResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCoreAudit();
});

// Business Analysis Providers (Phase 20)
final businessMissionsProvider = FutureProvider<MissionListResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getBusinessMissions();
});

final businessMissionsFamily = FutureProvider.family<MissionListResponse, bool>((ref, activeOnly) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getBusinessMissions(activeOnly: activeOnly);
});

final businessReportsProvider = FutureProvider.family<BusinessReportsListResponse, String>((ref, missionId) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getBusinessReports(missionId);
});

final businessReportDetailProvider = FutureProvider.family<BusinessReportDetailResponse, ({String missionId, String reportId})>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getBusinessReport(missionId: params.missionId, reportId: params.reportId);
});