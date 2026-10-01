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

  // Task Queue
  static const String queueStatus = '/api/v1/queue/status';
  static const String queueStats = '/api/v1/queue/stats';
  static const String queueTask = '/api/v1/queue/task/';
  static const String queueSubmit = '/api/v1/queue/submit';
  static const String queueCancel = '/api/v1/queue/cancel/';

  // WebSocket
  static const String wsEvents = '/api/v1/events';
  static const String wsAgentStream = '/ws/stream/';

  // Health Probes
  static const String healthLive = '/health/live';
  static const String healthReady = '/health/ready';
  static const String healthSystem = '/health/system';

  // Metrics & Flags
  static const String metrics = '/api/v1/metrics';
  static const String flags = '/api/v1/flags';

  // Memory
  static const String memoryList = '/api/v1/memory';
  static const String memorySearch = '/api/v1/memory/search';
  static const String memoryCreate = '/api/v1/memory';
  static const String memoryStats = '/api/v1/memory/stats';

  // Tools & Providers
  static const String toolsList = '/api/v1/tools';
  static const String toolsRun = '/api/v1/tools/';
  static const String toolsLogs = '/api/v1/tools/logs';
  static const String toolsFramework = '/api/v1/tools/framework';
  static const String providersList = '/api/v1/providers';
  static const String providersToggle = '/api/v1/providers/';

  // Brain Engine
  static const String brainAnalyze = '/api/v1/brain/analyze';
  static const String brainGraph = '/api/v1/brain/graph';

  // Multi-Agent System
  static const String agentsList = '/api/v1/agents';
  static const String agentsOrchestrate = '/api/v1/agents/orchestrate';
  static const String agentsMessages = '/api/v1/agents/messages';

  // Workflow Engine
  static const String workflowsPlan = '/api/v1/workflows/plan';
  static const String workflowsRuns = '/api/v1/workflows/runs';
  static const String workflowsRun = '/api/v1/workflows/runs/';
  static const String workflowsCancel = '/api/v1/workflows/runs/';
  static const String workflowsExecute = '/api/v1/workflows/runs/';

  // Autonomous Mode
  static const String autonomousRun = '/api/v1/autonomous/run';

  // Multi-Model Router
  static const String llmProviders = '/api/v1/llm/providers';
  static const String llmProviderToggle = '/api/v1/llm/providers/';
  static const String llmStats = '/api/v1/llm/stats';
  static const String llmStrategy = '/api/v1/llm/strategy';

  // Enterprise Layer
  static const String adminRoles = '/api/v1/admin/roles';
  static const String adminOrgs = '/api/v1/admin/orgs';
  static const String adminOrg = '/api/v1/admin/orgs/';
  static const String adminApiKeys = '/api/v1/admin/apikeys';
  static const String adminApiKey = '/api/v1/admin/apikeys/';
  static const String adminAudit = '/api/v1/admin/audit';
  static const String adminUsage = '/api/v1/admin/usage';
  static const String adminDashboard = '/api/v1/admin/dashboard';
  static const String adminUsers = '/api/v1/admin/users';
  static const String adminOwnerMode = '/api/v1/admin/owner-mode';

  // Learning Layer
  static const String learningFeedback = '/api/v1/learning/feedback';
  static const String learningStats = '/api/v1/learning/stats';
  static const String learningExperience = '/api/v1/learning/experience';
  static const String learningCompress = '/api/v1/learning/compress';
  static const String learningPrompts = '/api/v1/learning/prompts';

  // RAG (Phase 11)
  static const String ragStats = '/api/v1/rag/stats';
  static const String ragDocuments = '/api/v1/rag/documents';
  static const String ragDocument = '/api/v1/rag/documents/';
  static const String ragIngest = '/api/v1/rag/ingest';
  static const String ragSearch = '/api/v1/rag/search';
  static const String ragContext = '/api/v1/rag/context';

  // Phone/Device Control (Phase 13)
  static const String deviceList = '/api/v1/device/list';
  static const String devicePairStart = '/api/v1/device/pair/start';
  static const String devicePairComplete = '/api/v1/device/pair/complete';
  static const String deviceRevoke = '/api/v1/device/';
  static const String deviceHistory = '/api/v1/device/';
  static const String deviceCommand = '/api/v1/device/command';
  static const String deviceCommands = '/api/v1/device/';
  static const String deviceCommandResult = '/api/v1/device/commands/';

  // Instance CRUD (Phase 14)
  static const String instancesList = '/api/v1/instances';
  static const String instancesCreate = '/api/v1/instances';
  static const String instancesGet = '/api/v1/instances/';
  static const String instancesDelete = '/api/v1/instances/';

  // Hosting API (Phase 15)
  static const String hostingApps = '/api/v1/hosting/apps';
  static const String hostingDeploy = '/api/v1/hosting/deploy';
  static const String hostingApp = '/api/v1/hosting/apps/';
  static const String hostingStart = '/api/v1/hosting/apps/';
  static const String hostingStop = '/api/v1/hosting/apps/';
  static const String hostingRestart = '/api/v1/hosting/apps/';
  static const String hostingTunnel = '/api/v1/hosting/apps/';
  static const String hostingLogs = '/api/v1/hosting/apps/';
  static const String hostingRemove = '/api/v1/hosting/apps/';

  // Remote VPS Deploy (Phase 16)
  static const String remoteConfig = '/api/v1/hosting/remote/config';
  static const String remoteDeploy = '/api/v1/hosting/remote/deploy';
  static const String remoteAction = '/api/v1/hosting/remote/';

  // Cognitive Loop (Phase 17)
  static const String cognitiveStatus = '/api/v1/cognitive/status';
  static const String cognitiveCycle = '/api/v1/cognitive/cycle';
  static const String cognitivePause = '/api/v1/cognitive/pause';
  static const String cognitiveResume = '/api/v1/cognitive/resume';

  // AGI Architecture (Phase 18 Part 1)
  static const String kernelStatus = '/api/v1/cognitive/kernel/status';
  static const String kernelProcessGoal = '/api/v1/cognitive/kernel/process-goal';
  static const String kernelCheckpoint = '/api/v1/cognitive/kernel/checkpoint';
  static const String kernelCheckpoints = '/api/v1/cognitive/kernel/checkpoints';
  static const String kernelAudit = '/api/v1/cognitive/kernel/audit';
  static const String kernelRestore = '/api/v1/cognitive/kernel/restore';
  static const String kernelIncompleteGoals = '/api/v1/cognitive/kernel/goals/incomplete';
  static const String kernelResumeGoal = '/api/v1/cognitive/kernel/goals/';
  static const String kernelResumeIncomplete = '/api/v1/cognitive/kernel/resume-incomplete';

  static const String planCreate = '/api/v1/cognitive/plan';
  static const String planGet = '/api/v1/cognitive/plan/';
  static const String planExecute = '/api/v1/cognitive/plan/';
  static const String planReplan = '/api/v1/cognitive/plan/';

  static const String synthesizeCreate = '/api/v1/cognitive/synthesize';
  static const String synthesizeGet = '/api/v1/cognitive/synthesize/';
  static const String synthesizeStats = '/api/v1/cognitive/synthesize/stats';
  static const String synthesizeList = '/api/v1/cognitive/synthesize/list';

  // Society (Phase 18 Part 2)
  static const String societyStatus = '/api/v1/cognitive/society/status';
  static const String societySpawn = '/api/v1/cognitive/society/spawn';
  static const String societyAgents = '/api/v1/cognitive/society/agents';
  static const String societyAgentTask = '/api/v1/cognitive/society/agents/';
  static const String societyTender = '/api/v1/cognitive/society/tender';
  static const String societyBid = '/api/v1/cognitive/society/tasks/';
  static const String societyAward = '/api/v1/cognitive/society/tasks/';
  static const String societyBlackboardWrite = '/api/v1/cognitive/society/blackboard/write';
  static const String societyBlackboardRead = '/api/v1/cognitive/society/blackboard/read';
  static const String societyBlackboardQuery = '/api/v1/cognitive/society/blackboard/query';

  // Procedural Memory (Phase 18 Part 2)
  static const String proceduralList = '/api/v1/cognitive/memory/procedural/skills';
  static const String proceduralApplicable = '/api/v1/cognitive/memory/procedural/applicable';
  static const String proceduralUse = '/api/v1/cognitive/memory/procedural/skills/';
  static const String proceduralStats = '/api/v1/cognitive/memory/procedural/stats';
  static const String proceduralSearch = '/api/v1/cognitive/memory/procedural/search';
  static const String proceduralCompose = '/api/v1/cognitive/memory/procedural/compose';

  static const String metaStatus = '/api/v1/cognitive/metacognitive/status';
  static const String metaMonitor = '/api/v1/cognitive/metacognitive/monitor';
  static const String metaStepResult = '/api/v1/cognitive/metacognitive/step_result';
  static const String metaEvents = '/api/v1/cognitive/metacognitive/events';

  // Business Analysis (Phase 20)
  static const String missionsList = '/api/v1/cognitive/missions';
  static const String missionAnalyze = '/api/v1/cognitive/missions/';
  static const String missionReports = '/api/v1/cognitive/missions/';
  static const String missionReportDetail = '/api/v1/cognitive/missions/';

  // Maya Cognitive Core (Phase 19)
  static const String coreStatus = '/api/v1/maya/core/status';
  static const String coreInitialize = '/api/v1/maya/core/initialize';
  static const String coreLoopStart = '/api/v1/maya/core/loop/start';
  static const String coreLoopPause = '/api/v1/maya/core/loop/pause';
  static const String coreLoopResume = '/api/v1/maya/core/loop/resume';
  static const String coreLoopStop = '/api/v1/maya/core/loop/stop';
  static const String coreRunMission = '/api/v1/maya/core/mission';
  static const String coreExecuteGoal = '/api/v1/maya/core/goal/execute';
  static const String coreIdentity = '/api/v1/maya/core/identity';
  static const String coreModels = '/api/v1/maya/core/models';
  static const String coreSwitchModel = '/api/v1/maya/core/models/switch';
  static const String coreInvokeModel = '/api/v1/maya/core/models/invoke';
  static const String coreCheckpoint = '/api/v1/maya/core/checkpoint';
  static const String coreRestoreCheckpoint = '/api/v1/maya/core/checkpoint/restore';
  static const String coreCheckpoints = '/api/v1/maya/core/checkpoints';
  static const String coreAudit = '/api/v1/maya/core/audit';
  static const String coreShutdown = '/api/v1/maya/core/shutdown';

  // Hippocampus / Episodic Memory
  static const String episodicList = '/api/v1/cognitive/memory/episodic';
  static const String episodicSearch = '/api/v1/cognitive/memory/episodic/search';
  static const String episodicStats = '/api/v1/cognitive/memory/episodic/stats';
  static const String hippocampusSchemaQuery = '/hippocampus/schema/query';
  static const String hippocampusSchemaApply = '/hippocampus/schema/apply';

  // Semantic Memory / Knowledge
  static const String knowledgeQuery = '/api/v1/cognitive/knowledge/query';
  static const String knowledgeStats = '/api/v1/cognitive/knowledge/stats';
  static const String knowledgeLearn = '/api/v1/cognitive/knowledge/learn';

  // Working Memory
  static const String workingMemoryAdd = '/api/v1/cognitive/memory/working/add';
  static const String workingMemorySearch = '/api/v1/cognitive/memory/working/search';
  static const String workingMemoryCapacity = '/api/v1/cognitive/memory/working/capacity';
  static const String workingMemoryV2Add = '/working-memory/add';
  static const String workingMemoryV2Retrieve = '/working-memory/retrieve';
  static const String workingMemoryV2Decay = '/working-memory/decay';

  // Browser & Sandbox
  static const String browserAction = '/browser/action';
  static const String sandboxExecute = '/sandbox/execute';

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
