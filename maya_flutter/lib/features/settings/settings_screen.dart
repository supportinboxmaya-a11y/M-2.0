import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../config/app_config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Settings', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const _SettingsBody(),
      ),
    );
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody();

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  bool _voiceActivation = true;
  double _voiceSpeed = 1.0;
  String _voiceSelection = 'en-US-AriaNeural';
  bool _autoAnalyzePhotos = true;
  String _ocrLanguage = 'eng';
  bool _flashlightControl = true;
  bool _volumeControl = true;
  bool _appLaunching = false;

  final List<String> _voiceOptions = const [
    'en-US-AriaNeural',
    'en-US-GuyNeural',
    'en-GB-RyanNeural',
  ];

  final List<String> _ocrLanguages = const [
    'eng',
    'spa',
    'fra',
    'deu',
    'chi_sim',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceActivation = prefs.getBool('voice_activation') ?? true;
      _voiceSpeed = prefs.getDouble('voice_speed') ?? 1.0;
      _voiceSelection =
          prefs.getString('voice_selection') ?? 'en-US-AriaNeural';
      _autoAnalyzePhotos = prefs.getBool('auto_analyze_photos') ?? true;
      _ocrLanguage = prefs.getString('ocr_language') ?? 'eng';
      _flashlightControl = prefs.getBool('flashlight_control') ?? true;
      _volumeControl = prefs.getBool('volume_control') ?? true;
      _appLaunching = prefs.getBool('app_launching') ?? false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _onVoiceActivationChanged(bool value) {
    setState(() => _voiceActivation = value);
    _saveSetting('voice_activation', value);
  }

  void _onVoiceSpeedChanged(double value) {
    setState(() => _voiceSpeed = value);
    _saveSetting('voice_speed', value);
  }

  void _onVoiceSelectionChanged(String? value) {
    if (value != null) {
      setState(() => _voiceSelection = value);
      _saveSetting('voice_selection', value);
    }
  }

  void _onAutoAnalyzePhotosChanged(bool value) {
    setState(() => _autoAnalyzePhotos = value);
    _saveSetting('auto_analyze_photos', value);
  }

  void _onOcrLanguageChanged(String? value) {
    if (value != null) {
      setState(() => _ocrLanguage = value);
      _saveSetting('ocr_language', value);
    }
  }

  void _onFlashlightControlChanged(bool value) {
    setState(() => _flashlightControl = value);
    _saveSetting('flashlight_control', value);
  }

  void _onVolumeControlChanged(bool value) {
    setState(() => _volumeControl = value);
    _saveSetting('volume_control', value);
  }

  void _onAppLaunchingChanged(bool value) {
    setState(() => _appLaunching = value);
    _saveSetting('app_launching', value);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Settings', style: MayaTheme.headlineLarge),
        const SizedBox(height: 32),
        _buildSection(
          title: 'Voice',
          children: [
            _buildTile(
              title: 'Voice Activation',
              subtitle: 'Enable "Hey Maya" wake word',
              trailing: Switch(
                value: _voiceActivation,
                onChanged: _onVoiceActivationChanged,
                activeColor: MayaTheme.neonCyan,
              ),
            ),
            _buildTile(
              title: 'Voice Speed',
              subtitle: 'Adjust speech rate',
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: _voiceSpeed,
                  onChanged: _onVoiceSpeedChanged,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  activeColor: MayaTheme.neonCyan,
                  label: _voiceSpeed.toStringAsFixed(1),
                ),
              ),
            ),
            _buildTile(
              title: 'Voice Selection',
              subtitle: 'Choose TTS voice',
              trailing: DropdownButton<String>(
                value: _voiceSelection,
                dropdownColor: MayaTheme.slate800,
                style: MayaTheme.bodyMedium,
                underline: const SizedBox(),
                items: _voiceOptions
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: _onVoiceSelectionChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'Camera & Vision',
          children: [
            _buildTile(
              title: 'Auto-analyze Photos',
              subtitle: 'Automatically analyze captured images',
              trailing: Switch(
                value: _autoAnalyzePhotos,
                onChanged: _onAutoAnalyzePhotosChanged,
                activeColor: MayaTheme.neonCyan,
              ),
            ),
            _buildTile(
              title: 'OCR Language',
              subtitle: 'Text recognition language',
              trailing: DropdownButton<String>(
                value: _ocrLanguage,
                dropdownColor: MayaTheme.slate800,
                style: MayaTheme.bodyMedium,
                underline: const SizedBox(),
                items: _ocrLanguages
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: _onOcrLanguageChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'System Control',
          children: [
            _buildTile(
              title: 'Flashlight Control',
              subtitle: 'Allow Maya to control flashlight',
              trailing: Switch(
                value: _flashlightControl,
                onChanged: _onFlashlightControlChanged,
                activeColor: MayaTheme.neonCyan,
              ),
            ),
            _buildTile(
              title: 'Volume Control',
              subtitle: 'Allow Maya to adjust volume',
              trailing: Switch(
                value: _volumeControl,
                onChanged: _onVolumeControlChanged,
                activeColor: MayaTheme.neonCyan,
              ),
            ),
            _buildTile(
              title: 'App Launching',
              subtitle: 'Allow Maya to open apps',
              trailing: Switch(
                value: _appLaunching,
                onChanged: _onAppLaunchingChanged,
                activeColor: MayaTheme.neonCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'About',
          children: [
            _buildTile(
              title: 'Version',
              subtitle:
                  '${AppConfig.appVersion} (build ${AppConfig.buildNumber})',
              trailing: const SizedBox(),
            ),
            _buildTile(
              title: 'Clear Cache',
              subtitle: 'Remove temporary files',
              trailing: TextButton(
                onPressed: _clearCache,
                child: const Text('Clear'),
              ),
            ),
            _buildTile(
              title: 'Reset Settings',
              subtitle: 'Restore default settings',
              trailing: TextButton(
                onPressed: _resetSettings,
                child: const Text('Reset',
                    style: TextStyle(color: MayaTheme.error)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
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

  Widget _buildTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
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

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cache cleared'),
            backgroundColor: MayaTheme.neonEmerald),
      );
      setState(() {
        _voiceActivation = true;
        _voiceSpeed = 1.0;
        _voiceSelection = 'en-US-AriaNeural';
        _autoAnalyzePhotos = true;
        _ocrLanguage = 'eng';
        _flashlightControl = true;
        _volumeControl = true;
        _appLaunching = false;
      });
    }
  }

  Future<void> _resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Settings reset'),
            backgroundColor: MayaTheme.neonEmerald),
      );
      setState(() {
        _voiceActivation = true;
        _voiceSpeed = 1.0;
        _voiceSelection = 'en-US-AriaNeural';
        _autoAnalyzePhotos = true;
        _ocrLanguage = 'eng';
        _flashlightControl = true;
        _volumeControl = true;
        _appLaunching = false;
      });
    }
  }
}
