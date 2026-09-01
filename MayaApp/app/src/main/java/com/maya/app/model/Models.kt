package com.maya.app.model

import com.google.gson.annotations.SerializedName
import java.io.Serializable

// Auth
data class AuthTokens(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("refresh_token") val refreshToken: String,
    @SerializedName("token_type") val tokenType: String = "bearer",
    @SerializedName("expires_in") val expiresIn: Int = 3600
)

data class LoginRequest(
    @SerializedName("email") val email: String,
    @SerializedName("password") val password: String
)

data class RefreshRequest(
    @SerializedName("refresh_token") val refreshToken: String
)

data class RegisterRequest(
    @SerializedName("email") val email: String,
    @SerializedName("password") val password: String,
    @SerializedName("full_name") val fullName: String? = null
)

// User
data class User(
    @SerializedName("id") val id: String,
    @SerializedName("email") val email: String,
    @SerializedName("full_name") val fullName: String?,
    @SerializedName("is_active") val isActive: Boolean,
    @SerializedName("is_admin") val isAdmin: Boolean,
    @SerializedName("created_at") val createdAt: String
)

// Agent Status
data class AgentStatus(
    @SerializedName("status") val status: String,
    @SerializedName("uptime") val uptime: Long,
    @SerializedName("tasks_pending") val tasksPending: Int,
    @SerializedName("tasks_running") val tasksRunning: Int,
    @SerializedName("tasks_completed") val tasksCompleted: Int,
    @SerializedName("memory_count") val memoryCount: Int,
    @SerializedName("tools_count") val toolsCount: Int,
    @SerializedName("providers") val providers: List<ProviderStatus>
)

data class ProviderStatus(
    @SerializedName("id") val id: String,
    @SerializedName("name") val name: String,
    @SerializedName("status") val status: String,
    @SerializedName("models") val models: List<String>
)

// Task
data class Task(
    @SerializedName("id") val id: String,
    @SerializedName("goal") val goal: String,
    @SerializedName("status") val status: String,
    @SerializedName("result") val result: TaskResult?,
    @SerializedName("error") val error: String?,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String,
    @SerializedName("steps") val steps: List<TaskStep>?
)

data class TaskResult(
    @SerializedName("success") val success: Boolean,
    @SerializedName("output") val output: String?,
    @SerializedName("artifacts") val artifacts: List<String>?
)

data class TaskStep(
    @SerializedName("id") val id: String,
    @SerializedName("name") val name: String,
    @SerializedName("status") val status: String,
    @SerializedName("started_at") val startedAt: String?,
    @SerializedName("completed_at") val completedAt: String?,
    @SerializedName("error") val error: String?
)

data class TaskCreateRequest(
    @SerializedName("goal") val goal: String
)

// Memory
data class MemoryItem(
    @SerializedName("id") val id: String,
    @SerializedName("content") val content: String,
    @SerializedName("type") val type: String,
    @SerializedName("tags") val tags: List<String>,
    @SerializedName("importance") val importance: Float,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("accessed_at") val accessedAt: String?,
    @SerializedName("access_count") val accessCount: Int
)

data class MemorySearchRequest(
    @SerializedName("query") val query: String,
    @SerializedName("limit") val limit: Int = 10,
    @SerializedName("threshold") val threshold: Float = 0.7f
)

data class MemoryCreateRequest(
    @SerializedName("content") val content: String,
    @SerializedName("type") val type: String,
    @SerializedName("tags") val tags: List<String>,
    @SerializedName("importance") val importance: Float = 0.5f
)

// Tools
data class Tool(
    @SerializedName("name") val name: String,
    @SerializedName("description") val description: String,
    @SerializedName("parameters") val parameters: Map<String, Any>,
    @SerializedName("category") val category: String
)

data class ToolRunRequest(
    @SerializedName("parameters") val parameters: Map<String, Any>
)

data class ToolRunResult(
    @SerializedName("success") val success: Boolean,
    @SerializedName("result") val result: Any?,
    @SerializedName("error") val error: String?
)

// Analytics
data class AnalyticsSummary(
    @SerializedName("total_tasks") val totalTasks: Int,
    @SerializedName("completed_tasks") val completedTasks: Int,
    @SerializedName("failed_tasks") val failedTasks: Int,
    @SerializedName("total_tokens") val totalTokens: Long,
    @SerializedName("total_cost") val totalCost: Double,
    @SerializedName("avg_response_time") val avgResponseTime: Double,
    @SerializedName("provider_usage") val providerUsage: Map<String, Int>,
    @SerializedName("tool_usage") val toolUsage: Map<String, Int>
)

// Workflow
data class Workflow(
    @SerializedName("id") val id: String,
    @SerializedName("name") val name: String,
    @SerializedName("description") val description: String,
    @SerializedName("steps") val steps: List<WorkflowStep>,
    @SerializedName("enabled") val enabled: Boolean,
    @SerializedName("created_at") val createdAt: String
)

data class WorkflowStep(
    @SerializedName("id") val id: String,
    @SerializedName("name") val name: String,
    @SerializedName("tool") val tool: String,
    @SerializedName("params") val params: Map<String, Any>
)

// Voice
data class TranscribeResponse(
    @SerializedName("transcript") val transcript: String,
    @SerializedName("language") val language: String,
    @SerializedName("language_probability") val languageProbability: Float,
    @SerializedName("duration") val duration: Float,
    @SerializedName("segments") val segments: List<TranscriptSegment>?
)

data class TranscriptSegment(
    @SerializedName("start") val start: Float,
    @SerializedName("end") val end: Float,
    @SerializedName("text") val text: String
)

data class SynthesizeResponse(
    @SerializedName("audio_base64") val audioBase64: String,
    @SerializedName("format") val format: String,
    @SerializedName("sample_rate") val sampleRate: Int,
    @SerializedName("text") val text: String
)

data class VoiceModels(
    @SerializedName("current") val current: String,
    @SerializedName("available") val available: List<String>,
    @SerializedName("device") val device: String,
    @SerializedName("compute_type") val computeType: String
)

data class VoicesResponse(
    @SerializedName("current") val current: String,
    @SerializedName("available") val available: List<String>,
    @SerializedName("model_dir") val modelDir: String
)

// Income Engine - Scout
data class Opportunity(
    @SerializedName("id") val id: String,
    @SerializedName("title") val title: String,
    @SerializedName("description") val description: String,
    @SerializedName("problem_statement") val problemStatement: String,
    @SerializedName("target_user") val targetUser: String,
    @SerializedName("proposed_solution") val proposedSolution: String,
    @SerializedName("market_signal_score") val marketSignalScore: Float,
    @SerializedName("build_complexity_score") val buildComplexityScore: Float,
    @SerializedName("competition_score") val competitionScore: Float,
    @SerializedName("monetization_score") val monetizationScore: Float,
    @SerializedName("total_score") val totalScore: Float,
    @SerializedName("status") val status: String,
    @SerializedName("source_category") val sourceCategory: String,
    @SerializedName("target_market") val targetMarket: String,
    @SerializedName("estimated_market_size") val estimatedMarketSize: String,
    @SerializedName("monetization_model") val monetizationModel: String,
    @SerializedName("created_at") val createdAt: Double,
    @SerializedName("analyzed_at") val analyzedAt: Double?,
    @SerializedName("rejected_reason") val rejectedReason: String,
    @SerializedName("owner_rejected") val ownerRejected: Boolean,
    @SerializedName("owner_feedback") val ownerFeedback: String
)

data class ScanResult(
    @SerializedName("signals_found") val signalsFound: Int,
    @SerializedName("opportunities_created") val opportunitiesCreated: Int,
    @SerializedName("duration_seconds") val durationSeconds: Float
)

// Income Engine - Strategist
data class Plan(
    @SerializedName("id") val id: String,
    @SerializedName("opportunity_id") val opportunityId: String,
    @SerializedName("title") val title: String,
    @SerializedName("executive_summary") val executiveSummary: String,
    @SerializedName("mvp_scope") val mvpScope: List<String>,
    @SerializedName("technical_approach") val technicalApproach: String,
    @SerializedName("timeline") val timeline: List<String>,
    @SerializedName("success_metrics") val successMetrics: List<String>,
    @SerializedName("risks") val risks: List<String>,
    @SerializedName("approval_checkpoints") val approvalCheckpoints: List<String>,
    @SerializedName("estimated_timeline_weeks") val estimatedTimelineWeeks: Int,
    @SerializedName("status") val status: String,
    @SerializedName("created_at") val createdAt: Double,
    @SerializedName("approved_at") val approvedAt: Double?
)

// Income Engine - Builder
data class BuildProject(
    @SerializedName("id") val id: String,
    @SerializedName("plan_id") val planId: String,
    @SerializedName("title") val title: String,
    @SerializedName("status") val status: String,
    @SerializedName("current_step") val currentStep: Int,
    @SerializedName("total_steps") val totalSteps: Int,
    @SerializedName("repo_path") val repoPath: String?,
    @SerializedName("deploy_url") val deployUrl: String?,
    @SerializedName("created_at") val createdAt: Double,
    @SerializedName("updated_at") val updatedAt: Double
)

data class BuildStep(
    @SerializedName("id") val id: String,
    @SerializedName("step_type") val stepType: String,
    @SerializedName("description") val description: String,
    @SerializedName("status") val status: String,
    @SerializedName("started_at") val startedAt: Double?,
    @SerializedName("completed_at") val completedAt: Double?,
    @SerializedName("error") val error: String?
)

// Income Engine - Launcher
data class LaunchProject(
    @SerializedName("id") val id: String,
    @SerializedName("title") val title: String,
    @SerializedName("status") val status: String,
    @SerializedName("subdomain") val subdomain: String?,
    @SerializedName("launch_url") val launchUrl: String?,
    @SerializedName("launched_at") val launchedAt: Double?
)

// Income Engine - Growth/Portfolio
data class GrowthProposal(
    @SerializedName("id") val id: String,
    @SerializedName("project_id") val projectId: String,
    @SerializedName("action_type") val actionType: String,
    @SerializedName("title") val title: String,
    @SerializedName("description") val description: String,
    @SerializedName("impact_score") val impactScore: Float,
    @SerializedName("effort_score") val effortScore: Float,
    @SerializedName("confidence") val confidence: Float,
    @SerializedName("status") val status: String,
    @SerializedName("created_at") val createdAt: Double
)

data class PortfolioRecommendation(
    @SerializedName("id") val id: String,
    @SerializedName("project_id") val projectId: String,
    @SerializedName("action") val action: String,
    @SerializedName("rationale") val rationale: String,
    @SerializedName("confidence") val confidence: Float
)

data class PortfolioSummary(
    @SerializedName("total_projects") val totalProjects: Int,
    @SerializedName("by_status") val byStatus: Map<String, Int>,
    @SerializedName("live_projects") val liveProjects: Int,
    @SerializedName("building_projects") val buildingProjects: Int,
    @SerializedName("failed_projects") val failedProjects: Int
)

// Notifications
data class ApprovalRequest(
    @SerializedName("id") val id: String,
    @SerializedName("action") val action: String,
    @SerializedName("reason") val reason: String,
    @SerializedName("risk_level") val riskLevel: String,
    @SerializedName("title") val title: String,
    @SerializedName("description") val description: String,
    @SerializedName("status") val status: String,
    @SerializedName("created_at") val createdAt: Double,
    @SerializedName("decided_at") val decidedAt: Double?,
    @SerializedName("decision") val decision: String?
)

data class NotificationItem(
    @SerializedName("id") val id: String,
    @SerializedName("type") val type: String,
    @SerializedName("priority") val priority: String,
    @SerializedName("title") val title: String,
    @SerializedName("message") val message: String,
    @SerializedName("status") val status: String,
    @SerializedName("created_at") val createdAt: Double
)

// Cognitive
data class KernelStatus(
    @SerializedName("status") val status: String,
    @SerializedName("working_memory") val workingMemory: WorkingMemory?,
    @SerializedName("beliefs_count") val beliefsCount: Int,
    @SerializedName("goals_active") val goalsActive: Int,
    @SerializedName("skills_count") val skillsCount: Int
)

data class WorkingMemory(
    @SerializedName("items") val items: List<WorkingMemoryItem>
)

data class WorkingMemoryItem(
    @SerializedName("key") val key: String,
    @SerializedName("value") val value: String,
    @SerializedName("ttl") val ttl: Long
)

// Settings / Flags
data class FeatureFlags(
    @SerializedName("flags") val flags: Map<String, Boolean>
)

data class ServerHealth(
    @SerializedName("status") val status: String,
    @SerializedName("database") val database: Boolean,
    @SerializedName("redis") val redis: Boolean,
    @SerializedName("providers") val providers: Map<String, Boolean>
)

// Queue
data class QueueStatus(
    @SerializedName("pending") val pending: Int,
    @SerializedName("running") val running: Int,
    @SerializedName("completed") val completed: Int,
    @SerializedName("failed") val failed: Int
)

// Generic API Response
data class ApiResponse<T>(
    @SerializedName("success") val success: Boolean,
    @SerializedName("data") val data: T?,
    @SerializedName("error") val error: String?
)
