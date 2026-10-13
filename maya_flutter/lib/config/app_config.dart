class AppConfig {
  static const String appName = 'Maya Pro';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Backend API - Use VPS IP as primary (stable), Cloudflare tunnel as fallback
  static const String apiBaseUrl = 'http://130.210.46.182:8000';
  static const String apiBaseUrlLocal = 'http://130.210.46.182:8000';
  static const String wsBaseUrl = 'ws://130.210.46.182:8000';
  static const String wsBaseUrlLocal = 'ws://130.210.46.182:8000';

  // API Endpoints
  static const String authLogin = '/api/v1/auth/login';
  static const String authRegister = '/api/v1/auth/register';
  static const String authRefresh = '/api/v1/auth/refresh';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authMe = '/api/v1/users/me';

  static const String voiceTranscribe = '/api/v1/voice/transcribe';
  static const String voiceSynthesize = '/api/v1/voice/synthesize/json';
  static const String voiceSpeak = '/api/v1/voice/speak';
  static const String voiceGateway = '/api/v1/voice/gateway';

  static const String agentChat = '/api/v1/agent/chat';
  static const String agentChatStream = '/api/v1/agent/chat/stream';
  static const String agentRun = '/api/v1/agent/run';
  static const String agentThink = '/api/v1/agent/think';

  static const String cameraAnalyze = '/api/v1/vision/analyze';
  static const String cameraOcr = '/api/v1/vision/ocr';

  static const String systemStatus = '/api/v1/system/status';
  static const String systemStats = '/api/v1/tools/system_stats/run';

  // Tools
  static const String toolsList = '/api/v1/tools';
  static const String toolsRun = '/api/v1/tools/run';

  // MCP
  static const String mcpStatus = '/api/v1/mcp/status';
  static const String mcpConnect = '/api/v1/mcp/connect';
  static const String mcpDisconnect = '/api/v1/mcp/disconnect';
  static const String mcpCall = '/api/v1/mcp/call';

  // Device/Phone
  static const String deviceList = '/api/v1/device/list';
  static const String devicePairStart = '/api/v1/device/pair/start';
  static const String devicePairComplete = '/api/v1/device/pair/complete';
  static const String deviceCommand = '/api/v1/device/command';
  static const String deviceHistory = '/api/v1/device/history';

  // WAHA (WhatsApp)
  static const String wahaStatus = '/api/v1/waha/status';
  static const String wahaStartSession = '/api/v1/waha/session/start';
  static const String wahaLogout = '/api/v1/waha/session/logout';
  static const String wahaListConversations = '/api/v1/waha/conversations';
  static const String wahaGetMessages = '/api/v1/waha/messages';
  static const String wahaSendMessage = '/api/v1/waha/send';
  static const String wahaSetAutoReply = '/api/v1/waha/autoreply';

  // WebSocket
  static const String wsEvents = '/api/v1/events';
  static const String wsAgentStream = '/ws/stream/';

  // Storage Keys
  static const String keyAuthToken = 'maya_auth_token';
  static const String keyRefreshToken = 'maya_refresh_token';
  static const String keyUserPreferences = 'maya_user_prefs';
  static const String keyVoiceSettings = 'maya_voice_settings';
  static const String keyChatHistory = 'maya_chat_history';
  static const String keySystemSettings = 'maya_system_settings';

  // Feature Flags
  static const bool enableVoiceActivation = true;
  static const bool enableCameraAI = true;
  static const bool enableSystemControl = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
}
