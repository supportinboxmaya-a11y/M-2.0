import re

with open('lib/core/services/api_service.dart', 'r') as f:
    lines = f.readlines()

# Find the class closing brace
insert_idx = -1
brace_count = 0
for i, line in enumerate(lines):
    brace_count += line.count('{') - line.count('}')
    if brace_count == 0 and i > 50:
        if line.strip() == '}':
            insert_idx = i
            break

print(f"Insert at line {insert_idx}")

new_methods = '''
  // AGI Architecture Part 2 (Phase 18 Part 2) - Synthesizer, Society, Procedural Memory

  // Synthesizer
  Future<SynthesizeListResponse> getSynthesisList() async {
    final response = await _dio.get(AppConfig.synthesizeList);
    return SynthesizeListResponse.fromJson(response.data);
  }

  // Society
  Future<SocietyStatusResponse> getSocietyStatus() async {
    final response = await _dio.get(AppConfig.societyStatus);
    return SocietyStatusResponse.fromJson(response.data);
  }

  Future<SocietySpawnResponse> spawnAgent({
    required String role,
    required String spec,
  }) async {
    final response = await _dio.post(
      AppConfig.societySpawn,
      data: {"role": role, "spec": spec},
    );
    return SocietySpawnResponse.fromJson(response.data);
  }

  Future<SocietyAgentsResponse> getSocietyAgents() async {
    final response = await _dio.get(AppConfig.societyAgents);
    return SocietyAgentsResponse.fromJson(response.data);
  }

  Future<SocietyTaskResponse> assignAgentTask({
    required String agentId,
    required Map<String, dynamic> task,
  }) async {
    final response = await _dio.post(
      "${AppConfig.societyAgentTask}$agentId/task",
      data: task,
    );
    return SocietyTaskResponse.fromJson(response.data);
  }

  Future<SocietyTenderResponse> tenderTask({
    required Map<String, dynamic> taskSpec,
    required String deadline,
    List<String>? eligibleRoles,
  }) async {
    final response = await _dio.post(
      AppConfig.societyTender,
      data: {
        "task_spec": taskSpec,
        "deadline": deadline,
        "eligible_roles": eligibleRoles ?? [],
      },
    );
    return SocietyTenderResponse.fromJson(response.data);
  }

  Future<SocietyBidResponse> bidTask({
    required String taskId,
    required String agentId,
  }) async {
    final response = await _dio.post(
      "${AppConfig.societyBid}$taskId/bid",
      data: {"agent_id": agentId},
    );
    return SocietyBidResponse.fromJson(response.data);
  }

  Future<SocietyAwardResponse> awardTask({
    required String taskId,
    required String agentId,
  }) async {
    final response = await _dio.post(
      "${AppConfig.societyAward}$taskId/award",
      data: {"agent_id": agentId},
    );
    return SocietyAwardResponse.fromJson(response.data);
  }

  Future<SocietyBlackboardWriteResponse> writeBlackboard({
    required String agentId,
    required String key,
    required dynamic value,
    List<String>? tags,
    int? ttl,
  }) async {
    final response = await _dio.post(
      AppConfig.societyBlackboardWrite,
      data: {
        "agent_id": agentId,
        "key": key,
        "value": value,
        "tags": tags ?? [],
        "ttl": ttl,
      },
    );
    return SocietyBlackboardWriteResponse.fromJson(response.data);
  }

  Future<SocietyBlackboardReadResponse> readBlackboard({
    required String key,
  }) async {
    final response = await _dio.get(
      AppConfig.societyBlackboardRead,
      queryParameters: {"key": key},
    );
    return SocietyBlackboardReadResponse.fromJson(response.data);
  }

  Future<SocietyBlackboardQueryResponse> queryBlackboard({
    required String pattern,
  }) async {
    final response = await _dio.get(
      AppConfig.societyBlackboardQuery,
      queryParameters: {"pattern": pattern},
    );
    return SocietyBlackboardQueryResponse.fromJson(response.data);
  }

  // Procedural Memory
  Future<ProceduralListResponse> getProceduralSkills({
    bool? verified,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      AppConfig.proceduralList,
      queryParameters: {
        if (verified != null) "verified": verified,
        "limit": limit,
      },
    );
    return ProceduralListResponse.fromJson(response.data);
  }

  Future<ProceduralApplicableResponse> getApplicableProcedures({
    required String goal,
    String? context,
  }) async {
    final response = await _dio.get(
      AppConfig.proceduralApplicable,
      queryParameters: {
        "goal": goal,
        if (context != null) "context": context,
      },
    );
    return ProceduralApplicableResponse.fromJson(response.data);
  }

  Future<ProceduralUseResponse> useProceduralSkill({
    required String skillId,
    required bool success,
    double? reward,
  }) async {
    final response = await _dio.post(
      "${AppConfig.proceduralUse}$skillId/use",
      data: {
        "success": success,
        if (reward != null) "reward": reward,
      },
    );
    return ProceduralUseResponse.fromJson(response.data);
  }

  Future<ProceduralStatsResponse> getProceduralStats() async {
    final response = await _dio.get(AppConfig.proceduralStats);
    return ProceduralStatsResponse.fromJson(response.data);
  }

  Future<ProceduralSearchResponse> searchProcedural({
    required String query,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      AppConfig.proceduralSearch,
      queryParameters: {"q": query, "limit": limit},
    );
    return ProceduralSearchResponse.fromJson(response.data);
  }

  Future<ProceduralComposeResponse> composeProcedural({
    required List<String> skillIds,
    required String name,
    required String description,
  }) async {
    final response = await _dio.post(
      AppConfig.proceduralCompose,
      data: {
        "skill_ids": skillIds,
        "name": name,
        "description": description,
      },
    );
    return ProceduralComposeResponse.fromJson(response.data);
  }
'''

# Insert the new methods
new_lines = lines[:insert_idx] + ['\n'] + new_methods.split('\n') + ['\n'] + lines[insert_idx:]

with open('lib/core/services/api_service.dart', 'w') as f:
    f.writelines(new_lines)

print('Done')