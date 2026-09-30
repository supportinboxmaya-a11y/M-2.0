// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KernelAuditEntry _$KernelAuditEntryFromJson(Map json) => $checkedCreate(
      'KernelAuditEntry',
      json,
      ($checkedConvert) {
        final val = KernelAuditEntry(
          id: $checkedConvert('id', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          goalId: $checkedConvert('goal_id', (v) => v as String),
          result: $checkedConvert('result', (v) => v as String),
          timestamp: $checkedConvert('timestamp', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'goalId': 'goal_id'},
    );

Map<String, dynamic> _$KernelAuditEntryToJson(KernelAuditEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'goal_id': instance.goalId,
      'result': instance.result,
      'timestamp': instance.timestamp,
    };

PlanStep _$PlanStepFromJson(Map json) => $checkedCreate(
      'PlanStep',
      json,
      ($checkedConvert) {
        final val = PlanStep(
          id: $checkedConvert('id', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          agent: $checkedConvert('agent', (v) => v as String),
          tool: $checkedConvert('tool', (v) => v as String),
          params: $checkedConvert(
              'params', (v) => Map<String, dynamic>.from(v as Map)),
          status: $checkedConvert('status', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanStepToJson(PlanStep instance) => <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'agent': instance.agent,
      'tool': instance.tool,
      'params': instance.params,
      'status': instance.status,
    };

MetaEvent _$MetaEventFromJson(Map json) => $checkedCreate(
      'MetaEvent',
      json,
      ($checkedConvert) {
        final val = MetaEvent(
          id: $checkedConvert('id', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          timestamp: $checkedConvert('timestamp', (v) => (v as num).toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$MetaEventToJson(MetaEvent instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'description': instance.description,
      'timestamp': instance.timestamp,
    };

KernelCheckpointsResponse _$KernelCheckpointsResponseFromJson(Map json) =>
    $checkedCreate(
      'KernelCheckpointsResponse',
      json,
      ($checkedConvert) {
        final val = KernelCheckpointsResponse(
          checkpoints: $checkedConvert(
              'checkpoints', (v) => _checkpointsFromJson(v as List)),
        );
        return val;
      },
    );

Map<String, dynamic> _$KernelCheckpointsResponseToJson(
        KernelCheckpointsResponse instance) =>
    <String, dynamic>{
      'checkpoints': _checkpointsToJson(instance.checkpoints),
    };

KernelCheckpoint _$KernelCheckpointFromJson(Map json) => $checkedCreate(
      'KernelCheckpoint',
      json,
      ($checkedConvert) {
        final val = KernelCheckpoint(
          id: $checkedConvert('id', (v) => v as String),
          goalId: $checkedConvert('goal_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          timestamp: $checkedConvert('timestamp', (v) => (v as num).toDouble()),
          stateJson: $checkedConvert('state_json', (v) => v as String? ?? ''),
        );
        return val;
      },
      fieldKeyMap: const {'goalId': 'goal_id', 'stateJson': 'state_json'},
    );

Map<String, dynamic> _$KernelCheckpointToJson(KernelCheckpoint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'goal_id': instance.goalId,
      'status': instance.status,
      'timestamp': instance.timestamp,
      'state_json': instance.stateJson,
    };

_$KernelStatusResponseImpl _$$KernelStatusResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$KernelStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KernelStatusResponseImpl(
          running: $checkedConvert('running', (v) => v as bool),
          status: $checkedConvert('status', (v) => v as String),
          activeGoals:
              $checkedConvert('active_goals', (v) => (v as num).toInt()),
          activeAgents:
              $checkedConvert('active_agents', (v) => (v as num).toInt()),
          memoryItems:
              $checkedConvert('memory_items', (v) => (v as num).toInt()),
          totalCheckpoints:
              $checkedConvert('total_checkpoints', (v) => (v as num).toInt()),
          uptime: $checkedConvert('uptime', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'activeGoals': 'active_goals',
        'activeAgents': 'active_agents',
        'memoryItems': 'memory_items',
        'totalCheckpoints': 'total_checkpoints'
      },
    );

Map<String, dynamic> _$$KernelStatusResponseImplToJson(
        _$KernelStatusResponseImpl instance) =>
    <String, dynamic>{
      'running': instance.running,
      'status': instance.status,
      'active_goals': instance.activeGoals,
      'active_agents': instance.activeAgents,
      'memory_items': instance.memoryItems,
      'total_checkpoints': instance.totalCheckpoints,
      'uptime': instance.uptime,
    };

_$KernelProcessGoalResponseImpl _$$KernelProcessGoalResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$KernelProcessGoalResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KernelProcessGoalResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          goalId: $checkedConvert('goal_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          plan: $checkedConvert('plan', (v) => v as String),
          steps: $checkedConvert('steps',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {'goalId': 'goal_id'},
    );

Map<String, dynamic> _$$KernelProcessGoalResponseImplToJson(
    _$KernelProcessGoalResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'goal_id': instance.goalId,
    'status': instance.status,
    'plan': instance.plan,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('steps', instance.steps);
  return val;
}

_$KernelCheckpointResponseImpl _$$KernelCheckpointResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$KernelCheckpointResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KernelCheckpointResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          checkpointId: $checkedConvert('checkpoint_id', (v) => v as String),
          goalId: $checkedConvert('goal_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          timestamp: $checkedConvert('timestamp', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'checkpointId': 'checkpoint_id', 'goalId': 'goal_id'},
    );

Map<String, dynamic> _$$KernelCheckpointResponseImplToJson(
        _$KernelCheckpointResponseImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'checkpoint_id': instance.checkpointId,
      'goal_id': instance.goalId,
      'status': instance.status,
      'timestamp': instance.timestamp,
    };

_$KernelCheckpointImpl _$$KernelCheckpointImplFromJson(Map json) =>
    $checkedCreate(
      r'_$KernelCheckpointImpl',
      json,
      ($checkedConvert) {
        final val = _$KernelCheckpointImpl(
          id: $checkedConvert('id', (v) => v as String),
          goalId: $checkedConvert('goal_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          timestamp: $checkedConvert('timestamp', (v) => (v as num).toDouble()),
          stateJson: $checkedConvert('state_json', (v) => v as String? ?? ''),
        );
        return val;
      },
      fieldKeyMap: const {'goalId': 'goal_id', 'stateJson': 'state_json'},
    );

Map<String, dynamic> _$$KernelCheckpointImplToJson(
        _$KernelCheckpointImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'goal_id': instance.goalId,
      'status': instance.status,
      'timestamp': instance.timestamp,
      'state_json': instance.stateJson,
    };

_$KernelAuditResponseImpl _$$KernelAuditResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$KernelAuditResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KernelAuditResponseImpl(
          entries: $checkedConvert(
              'entries',
              (v) => (v as List<dynamic>)
                  .map((e) => KernelAuditEntry.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$KernelAuditResponseImplToJson(
        _$KernelAuditResponseImpl instance) =>
    <String, dynamic>{
      'entries': instance.entries,
    };

_$KernelRestoreResponseImpl _$$KernelRestoreResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$KernelRestoreResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KernelRestoreResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          checkpointId: $checkedConvert('checkpoint_id', (v) => v as String),
          goalId: $checkedConvert('goal_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'checkpointId': 'checkpoint_id', 'goalId': 'goal_id'},
    );

Map<String, dynamic> _$$KernelRestoreResponseImplToJson(
        _$KernelRestoreResponseImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'checkpoint_id': instance.checkpointId,
      'goal_id': instance.goalId,
      'status': instance.status,
    };

_$KernelIncompleteGoalsResponseImpl
    _$$KernelIncompleteGoalsResponseImplFromJson(Map json) => $checkedCreate(
          r'_$KernelIncompleteGoalsResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$KernelIncompleteGoalsResponseImpl(
              goalIds: $checkedConvert('goal_ids',
                  (v) => (v as List<dynamic>).map((e) => e as String).toList()),
              count: $checkedConvert('count', (v) => (v as num).toInt()),
            );
            return val;
          },
          fieldKeyMap: const {'goalIds': 'goal_ids'},
        );

Map<String, dynamic> _$$KernelIncompleteGoalsResponseImplToJson(
        _$KernelIncompleteGoalsResponseImpl instance) =>
    <String, dynamic>{
      'goal_ids': instance.goalIds,
      'count': instance.count,
    };

_$KernelResumeGoalResponseImpl _$$KernelResumeGoalResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$KernelResumeGoalResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KernelResumeGoalResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          goalId: $checkedConvert('goal_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          plan: $checkedConvert('plan', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'goalId': 'goal_id'},
    );

Map<String, dynamic> _$$KernelResumeGoalResponseImplToJson(
    _$KernelResumeGoalResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'goal_id': instance.goalId,
    'status': instance.status,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('plan', instance.plan);
  return val;
}

_$KernelResumeIncompleteResponseImpl
    _$$KernelResumeIncompleteResponseImplFromJson(Map json) => $checkedCreate(
          r'_$KernelResumeIncompleteResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$KernelResumeIncompleteResponseImpl(
              ok: $checkedConvert('ok', (v) => v as bool),
              resumedGoalIds: $checkedConvert('resumed_goal_ids',
                  (v) => (v as List<dynamic>).map((e) => e as String).toList()),
              count: $checkedConvert('count', (v) => (v as num).toInt()),
            );
            return val;
          },
          fieldKeyMap: const {'resumedGoalIds': 'resumed_goal_ids'},
        );

Map<String, dynamic> _$$KernelResumeIncompleteResponseImplToJson(
        _$KernelResumeIncompleteResponseImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'resumed_goal_ids': instance.resumedGoalIds,
      'count': instance.count,
    };

_$PlanCreateResponseImpl _$$PlanCreateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$PlanCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PlanCreateResponseImpl(
          planId: $checkedConvert('plan_id', (v) => v as String),
          goal: $checkedConvert('goal', (v) => v as String),
          steps: $checkedConvert(
              'steps',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      PlanStep.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {'planId': 'plan_id'},
    );

Map<String, dynamic> _$$PlanCreateResponseImplToJson(
        _$PlanCreateResponseImpl instance) =>
    <String, dynamic>{
      'plan_id': instance.planId,
      'goal': instance.goal,
      'steps': instance.steps,
    };

_$PlanGetResponseImpl _$$PlanGetResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$PlanGetResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PlanGetResponseImpl(
          planId: $checkedConvert('plan_id', (v) => v as String),
          goal: $checkedConvert('goal', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          steps: $checkedConvert(
              'steps',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      PlanStep.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
          currentStep: $checkedConvert('current_step', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'planId': 'plan_id', 'currentStep': 'current_step'},
    );

Map<String, dynamic> _$$PlanGetResponseImplToJson(
    _$PlanGetResponseImpl instance) {
  final val = <String, dynamic>{
    'plan_id': instance.planId,
    'goal': instance.goal,
    'status': instance.status,
    'steps': instance.steps,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('current_step', instance.currentStep);
  return val;
}

_$PlanExecuteResponseImpl _$$PlanExecuteResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$PlanExecuteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PlanExecuteResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          planId: $checkedConvert('plan_id', (v) => v as String),
          result: $checkedConvert('result', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'planId': 'plan_id'},
    );

Map<String, dynamic> _$$PlanExecuteResponseImplToJson(
        _$PlanExecuteResponseImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'plan_id': instance.planId,
      'result': instance.result,
    };

_$PlanReplanResponseImpl _$$PlanReplanResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$PlanReplanResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PlanReplanResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          planId: $checkedConvert('plan_id', (v) => v as String),
          result: $checkedConvert('result', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'planId': 'plan_id'},
    );

Map<String, dynamic> _$$PlanReplanResponseImplToJson(
        _$PlanReplanResponseImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'plan_id': instance.planId,
      'result': instance.result,
    };

_$SynthesizeCreateResponseImpl _$$SynthesizeCreateResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$SynthesizeCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SynthesizeCreateResponseImpl(
          jobId: $checkedConvert('job_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'jobId': 'job_id'},
    );

Map<String, dynamic> _$$SynthesizeCreateResponseImplToJson(
        _$SynthesizeCreateResponseImpl instance) =>
    <String, dynamic>{
      'job_id': instance.jobId,
      'status': instance.status,
    };

_$SynthesizeGetResponseImpl _$$SynthesizeGetResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SynthesizeGetResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SynthesizeGetResponseImpl(
          jobId: $checkedConvert('job_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          result: $checkedConvert('result', (v) => v as String),
          artifacts: $checkedConvert(
              'artifacts',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {'jobId': 'job_id'},
    );

Map<String, dynamic> _$$SynthesizeGetResponseImplToJson(
    _$SynthesizeGetResponseImpl instance) {
  final val = <String, dynamic>{
    'job_id': instance.jobId,
    'status': instance.status,
    'result': instance.result,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('artifacts', instance.artifacts);
  return val;
}

_$SynthesizeStatsResponseImpl _$$SynthesizeStatsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$SynthesizeStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SynthesizeStatsResponseImpl(
          totalJobs: $checkedConvert('total_jobs', (v) => (v as num).toInt()),
          completedJobs:
              $checkedConvert('completed_jobs', (v) => (v as num).toInt()),
          failedJobs: $checkedConvert('failed_jobs', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalJobs': 'total_jobs',
        'completedJobs': 'completed_jobs',
        'failedJobs': 'failed_jobs'
      },
    );

Map<String, dynamic> _$$SynthesizeStatsResponseImplToJson(
        _$SynthesizeStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_jobs': instance.totalJobs,
      'completed_jobs': instance.completedJobs,
      'failed_jobs': instance.failedJobs,
    };

_$MetaStatusResponseImpl _$$MetaStatusResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MetaStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$MetaStatusResponseImpl(
          running: $checkedConvert('running', (v) => v as bool),
          monitoredSteps:
              $checkedConvert('monitored_steps', (v) => (v as num).toInt()),
          errorsDetected:
              $checkedConvert('errors_detected', (v) => (v as num).toInt()),
          correctionsApplied:
              $checkedConvert('corrections_applied', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'monitoredSteps': 'monitored_steps',
        'errorsDetected': 'errors_detected',
        'correctionsApplied': 'corrections_applied'
      },
    );

Map<String, dynamic> _$$MetaStatusResponseImplToJson(
        _$MetaStatusResponseImpl instance) =>
    <String, dynamic>{
      'running': instance.running,
      'monitored_steps': instance.monitoredSteps,
      'errors_detected': instance.errorsDetected,
      'corrections_applied': instance.correctionsApplied,
    };

_$MetaMonitorResponseImpl _$$MetaMonitorResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MetaMonitorResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$MetaMonitorResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          stepId: $checkedConvert('step_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          correction: $checkedConvert('correction', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'stepId': 'step_id'},
    );

Map<String, dynamic> _$$MetaMonitorResponseImplToJson(
    _$MetaMonitorResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'step_id': instance.stepId,
    'status': instance.status,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('correction', instance.correction);
  return val;
}

_$MetaStepResultResponseImpl _$$MetaStepResultResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MetaStepResultResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$MetaStepResultResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          stepId: $checkedConvert('step_id', (v) => v as String),
          verified: $checkedConvert('verified', (v) => v as bool),
          issues: $checkedConvert('issues', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'stepId': 'step_id'},
    );

Map<String, dynamic> _$$MetaStepResultResponseImplToJson(
    _$MetaStepResultResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'step_id': instance.stepId,
    'verified': instance.verified,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('issues', instance.issues);
  return val;
}

_$MetaEventsResponseImpl _$$MetaEventsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MetaEventsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$MetaEventsResponseImpl(
          events: $checkedConvert(
              'events',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      MetaEvent.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$MetaEventsResponseImplToJson(
        _$MetaEventsResponseImpl instance) =>
    <String, dynamic>{
      'events': instance.events,
    };

_$HealthCheckResultImpl _$$HealthCheckResultImplFromJson(Map json) =>
    $checkedCreate(
      r'_$HealthCheckResultImpl',
      json,
      ($checkedConvert) {
        final val = _$HealthCheckResultImpl(
          live: $checkedConvert('live', (v) => v as bool),
          ready: $checkedConvert('ready', (v) => v as bool),
          system: $checkedConvert('system', (v) => v as String),
          latency: $checkedConvert('latency', (v) => (v as num).toInt()),
          lastCheck:
              $checkedConvert('last_check', (v) => DateTime.parse(v as String)),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'lastCheck': 'last_check'},
    );

Map<String, dynamic> _$$HealthCheckResultImplToJson(
    _$HealthCheckResultImpl instance) {
  final val = <String, dynamic>{
    'live': instance.live,
    'ready': instance.ready,
    'system': instance.system,
    'latency': instance.latency,
    'last_check': instance.lastCheck.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('error', instance.error);
  return val;
}

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map json) => $checkedCreate(
      r'_$AuthResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AuthResponseImpl(
          accessToken: $checkedConvert('access_token', (v) => v as String),
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
          user: $checkedConvert('user',
              (v) => UserProfile.fromJson(Map<String, dynamic>.from(v as Map))),
        );
        return val;
      },
      fieldKeyMap: const {
        'accessToken': 'access_token',
        'refreshToken': 'refresh_token'
      },
    );

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'user': instance.user,
    };

_$UserProfileImpl _$$UserProfileImplFromJson(Map json) => $checkedCreate(
      r'_$UserProfileImpl',
      json,
      ($checkedConvert) {
        final val = _$UserProfileImpl(
          id: $checkedConvert('id', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          avatar: $checkedConvert('avatar', (v) => v as String?),
          role: $checkedConvert('role', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'email': instance.email,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('avatar', instance.avatar);
  writeNotNull('role', instance.role);
  return val;
}

_$TranscriptionResultImpl _$$TranscriptionResultImplFromJson(Map json) =>
    $checkedCreate(
      r'_$TranscriptionResultImpl',
      json,
      ($checkedConvert) {
        final val = _$TranscriptionResultImpl(
          transcript: $checkedConvert('transcript', (v) => v as String),
          language: $checkedConvert('language', (v) => v as String),
          languageProbability: $checkedConvert(
              'language_probability', (v) => (v as num).toDouble()),
          duration: $checkedConvert('duration', (v) => (v as num).toDouble()),
          segments: $checkedConvert(
              'segments',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => TranscriptionSegment.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {'languageProbability': 'language_probability'},
    );

Map<String, dynamic> _$$TranscriptionResultImplToJson(
    _$TranscriptionResultImpl instance) {
  final val = <String, dynamic>{
    'transcript': instance.transcript,
    'language': instance.language,
    'language_probability': instance.languageProbability,
    'duration': instance.duration,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('segments', instance.segments);
  return val;
}

_$TranscriptionSegmentImpl _$$TranscriptionSegmentImplFromJson(Map json) =>
    $checkedCreate(
      r'_$TranscriptionSegmentImpl',
      json,
      ($checkedConvert) {
        final val = _$TranscriptionSegmentImpl(
          start: $checkedConvert('start', (v) => (v as num).toDouble()),
          end: $checkedConvert('end', (v) => (v as num).toDouble()),
          text: $checkedConvert('text', (v) => v as String),
          avgLogprob:
              $checkedConvert('avg_logprob', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'avgLogprob': 'avg_logprob'},
    );

Map<String, dynamic> _$$TranscriptionSegmentImplToJson(
    _$TranscriptionSegmentImpl instance) {
  final val = <String, dynamic>{
    'start': instance.start,
    'end': instance.end,
    'text': instance.text,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('avg_logprob', instance.avgLogprob);
  return val;
}

_$TtsResultImpl _$$TtsResultImplFromJson(Map json) => $checkedCreate(
      r'_$TtsResultImpl',
      json,
      ($checkedConvert) {
        final val = _$TtsResultImpl(
          success: $checkedConvert('success', (v) => v as bool),
          audioBase64: $checkedConvert('audio_base64', (v) => v as String?),
          format: $checkedConvert('format', (v) => v as String?),
          provider: $checkedConvert('provider', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'audioBase64': 'audio_base64'},
    );

Map<String, dynamic> _$$TtsResultImplToJson(_$TtsResultImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('audio_base64', instance.audioBase64);
  writeNotNull('format', instance.format);
  writeNotNull('provider', instance.provider);
  writeNotNull('error', instance.error);
  return val;
}

_$AgentChatResponseImpl _$$AgentChatResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AgentChatResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentChatResponseImpl(
          reply: $checkedConvert('reply', (v) => v as String),
          timestamp: $checkedConvert('timestamp', (v) => v as String),
          taskId: $checkedConvert('task_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'taskId': 'task_id'},
    );

Map<String, dynamic> _$$AgentChatResponseImplToJson(
    _$AgentChatResponseImpl instance) {
  final val = <String, dynamic>{
    'reply': instance.reply,
    'timestamp': instance.timestamp,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('task_id', instance.taskId);
  return val;
}

_$AgentRunResponseImpl _$$AgentRunResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AgentRunResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentRunResponseImpl(
          taskId: $checkedConvert('task_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          result: $checkedConvert('result', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'taskId': 'task_id'},
    );

Map<String, dynamic> _$$AgentRunResponseImplToJson(
    _$AgentRunResponseImpl instance) {
  final val = <String, dynamic>{
    'task_id': instance.taskId,
    'status': instance.status,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('result', instance.result);
  writeNotNull('error', instance.error);
  return val;
}

_$AgentThinkResponseImpl _$$AgentThinkResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AgentThinkResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentThinkResponseImpl(
          analysis: $checkedConvert('analysis', (v) => v as String),
          plan: $checkedConvert('plan', (v) => v as String?),
          steps: $checkedConvert('steps',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AgentThinkResponseImplToJson(
    _$AgentThinkResponseImpl instance) {
  final val = <String, dynamic>{
    'analysis': instance.analysis,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('plan', instance.plan);
  writeNotNull('steps', instance.steps);
  return val;
}

_$VisionAnalysisResultImpl _$$VisionAnalysisResultImplFromJson(Map json) =>
    $checkedCreate(
      r'_$VisionAnalysisResultImpl',
      json,
      ($checkedConvert) {
        final val = _$VisionAnalysisResultImpl(
          analysis: $checkedConvert('analysis', (v) => v as String),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$$VisionAnalysisResultImplToJson(
    _$VisionAnalysisResultImpl instance) {
  final val = <String, dynamic>{
    'analysis': instance.analysis,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('tags', instance.tags);
  writeNotNull('metadata', instance.metadata);
  return val;
}

_$OcrResultImpl _$$OcrResultImplFromJson(Map json) => $checkedCreate(
      r'_$OcrResultImpl',
      json,
      ($checkedConvert) {
        final val = _$OcrResultImpl(
          text: $checkedConvert('text', (v) => v as String),
          regions: $checkedConvert(
              'regions',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      OcrRegion.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$OcrResultImplToJson(_$OcrResultImpl instance) {
  final val = <String, dynamic>{
    'text': instance.text,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('regions', instance.regions);
  return val;
}

_$OcrRegionImpl _$$OcrRegionImplFromJson(Map json) => $checkedCreate(
      r'_$OcrRegionImpl',
      json,
      ($checkedConvert) {
        final val = _$OcrRegionImpl(
          text: $checkedConvert('text', (v) => v as String),
          bounds: $checkedConvert('bounds',
              (v) => const RectConverter().fromJson(v as Map<String, double>)),
          confidence:
              $checkedConvert('confidence', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$OcrRegionImplToJson(_$OcrRegionImpl instance) {
  final val = <String, dynamic>{
    'text': instance.text,
    'bounds': const RectConverter().toJson(instance.bounds),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('confidence', instance.confidence);
  return val;
}

_$SystemStatusImpl _$$SystemStatusImplFromJson(Map json) => $checkedCreate(
      r'_$SystemStatusImpl',
      json,
      ($checkedConvert) {
        final val = _$SystemStatusImpl(
          status: $checkedConvert('status', (v) => v as String),
          maya: $checkedConvert('maya', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SystemStatusImplToJson(_$SystemStatusImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'maya': instance.maya,
    };

_$SystemStatsImpl _$$SystemStatsImplFromJson(Map json) => $checkedCreate(
      r'_$SystemStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$SystemStatsImpl(
          cpu: $checkedConvert('cpu',
              (v) => CpuStats.fromJson(Map<String, dynamic>.from(v as Map))),
          memory: $checkedConvert('memory',
              (v) => MemoryStats.fromJson(Map<String, dynamic>.from(v as Map))),
          disk: $checkedConvert('disk',
              (v) => DiskStats.fromJson(Map<String, dynamic>.from(v as Map))),
          load: $checkedConvert('load',
              (v) => LoadStats.fromJson(Map<String, dynamic>.from(v as Map))),
          network: $checkedConvert(
              'network',
              (v) => v == null
                  ? null
                  : NetworkStats.fromJson(Map<String, dynamic>.from(v as Map))),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SystemStatsImplToJson(_$SystemStatsImpl instance) {
  final val = <String, dynamic>{
    'cpu': instance.cpu,
    'memory': instance.memory,
    'disk': instance.disk,
    'load': instance.load,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('network', instance.network);
  return val;
}

_$CpuStatsImpl _$$CpuStatsImplFromJson(Map json) => $checkedCreate(
      r'_$CpuStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$CpuStatsImpl(
          percent: $checkedConvert('percent', (v) => (v as num).toDouble()),
          count: $checkedConvert('count', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CpuStatsImplToJson(_$CpuStatsImpl instance) =>
    <String, dynamic>{
      'percent': instance.percent,
      'count': instance.count,
    };

_$MemoryStatsImpl _$$MemoryStatsImplFromJson(Map json) => $checkedCreate(
      r'_$MemoryStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$MemoryStatsImpl(
          totalGb: $checkedConvert('total_gb', (v) => (v as num).toDouble()),
          availableGb:
              $checkedConvert('available_gb', (v) => (v as num).toDouble()),
          usedGb: $checkedConvert('used_gb', (v) => (v as num).toDouble()),
          percent: $checkedConvert('percent', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalGb': 'total_gb',
        'availableGb': 'available_gb',
        'usedGb': 'used_gb'
      },
    );

Map<String, dynamic> _$$MemoryStatsImplToJson(_$MemoryStatsImpl instance) =>
    <String, dynamic>{
      'total_gb': instance.totalGb,
      'available_gb': instance.availableGb,
      'used_gb': instance.usedGb,
      'percent': instance.percent,
    };

_$DiskStatsImpl _$$DiskStatsImplFromJson(Map json) => $checkedCreate(
      r'_$DiskStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$DiskStatsImpl(
          totalGb: $checkedConvert('total_gb', (v) => (v as num).toDouble()),
          usedGb: $checkedConvert('used_gb', (v) => (v as num).toDouble()),
          freeGb: $checkedConvert('free_gb', (v) => (v as num).toDouble()),
          percent: $checkedConvert('percent', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalGb': 'total_gb',
        'usedGb': 'used_gb',
        'freeGb': 'free_gb'
      },
    );

Map<String, dynamic> _$$DiskStatsImplToJson(_$DiskStatsImpl instance) =>
    <String, dynamic>{
      'total_gb': instance.totalGb,
      'used_gb': instance.usedGb,
      'free_gb': instance.freeGb,
      'percent': instance.percent,
    };

_$LoadStatsImpl _$$LoadStatsImplFromJson(Map json) => $checkedCreate(
      r'_$LoadStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$LoadStatsImpl(
          loadAvg: $checkedConvert(
              'load_avg',
              (v) => (v as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {'loadAvg': 'load_avg'},
    );

Map<String, dynamic> _$$LoadStatsImplToJson(_$LoadStatsImpl instance) =>
    <String, dynamic>{
      'load_avg': instance.loadAvg,
    };

_$NetworkStatsImpl _$$NetworkStatsImplFromJson(Map json) => $checkedCreate(
      r'_$NetworkStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$NetworkStatsImpl(
          bytesSent: $checkedConvert('bytes_sent', (v) => (v as num).toInt()),
          bytesRecv: $checkedConvert('bytes_recv', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'bytesSent': 'bytes_sent', 'bytesRecv': 'bytes_recv'},
    );

Map<String, dynamic> _$$NetworkStatsImplToJson(_$NetworkStatsImpl instance) =>
    <String, dynamic>{
      'bytes_sent': instance.bytesSent,
      'bytes_recv': instance.bytesRecv,
    };

_$QueueStatusImpl _$$QueueStatusImplFromJson(Map json) => $checkedCreate(
      r'_$QueueStatusImpl',
      json,
      ($checkedConvert) {
        final val = _$QueueStatusImpl(
          tasks: $checkedConvert(
              'tasks', (v) => Map<String, dynamic>.from(v as Map)),
          workers: $checkedConvert('workers', (v) => (v as num).toInt()),
          running: $checkedConvert('running', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$$QueueStatusImplToJson(_$QueueStatusImpl instance) =>
    <String, dynamic>{
      'tasks': instance.tasks,
      'workers': instance.workers,
      'running': instance.running,
    };

_$QueueStatsImpl _$$QueueStatsImplFromJson(Map json) => $checkedCreate(
      r'_$QueueStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$QueueStatsImpl(
          pending: $checkedConvert('pending', (v) => (v as num).toInt()),
          running: $checkedConvert('running', (v) => (v as num).toInt()),
          completed: $checkedConvert('completed', (v) => (v as num).toInt()),
          failed: $checkedConvert('failed', (v) => (v as num).toInt()),
          cancelled: $checkedConvert('cancelled', (v) => (v as num).toInt()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$QueueStatsImplToJson(_$QueueStatsImpl instance) =>
    <String, dynamic>{
      'pending': instance.pending,
      'running': instance.running,
      'completed': instance.completed,
      'failed': instance.failed,
      'cancelled': instance.cancelled,
      'total': instance.total,
    };

_$QueueTaskStatusImpl _$$QueueTaskStatusImplFromJson(Map json) =>
    $checkedCreate(
      r'_$QueueTaskStatusImpl',
      json,
      ($checkedConvert) {
        final val = _$QueueTaskStatusImpl(
          taskId: $checkedConvert('task_id', (v) => v as String),
          job: $checkedConvert('job', (v) => v as String),
          state: $checkedConvert('state', (v) => v as String),
          payload: $checkedConvert(
              'payload', (v) => Map<String, dynamic>.from(v as Map)),
          priority: $checkedConvert('priority', (v) => (v as num?)?.toInt()),
          result: $checkedConvert('result', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
          createdAt: $checkedConvert('created_at', (v) => v as String?),
          startedAt: $checkedConvert('started_at', (v) => v as String?),
          completedAt: $checkedConvert('completed_at', (v) => v as String?),
          workerId: $checkedConvert('worker_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'taskId': 'task_id',
        'createdAt': 'created_at',
        'startedAt': 'started_at',
        'completedAt': 'completed_at',
        'workerId': 'worker_id'
      },
    );

Map<String, dynamic> _$$QueueTaskStatusImplToJson(
    _$QueueTaskStatusImpl instance) {
  final val = <String, dynamic>{
    'task_id': instance.taskId,
    'job': instance.job,
    'state': instance.state,
    'payload': instance.payload,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('priority', instance.priority);
  writeNotNull('result', instance.result);
  writeNotNull('error', instance.error);
  writeNotNull('created_at', instance.createdAt);
  writeNotNull('started_at', instance.startedAt);
  writeNotNull('completed_at', instance.completedAt);
  writeNotNull('worker_id', instance.workerId);
  return val;
}

_$QueueSubmitResultImpl _$$QueueSubmitResultImplFromJson(Map json) =>
    $checkedCreate(
      r'_$QueueSubmitResultImpl',
      json,
      ($checkedConvert) {
        final val = _$QueueSubmitResultImpl(
          taskId: $checkedConvert('task_id', (v) => v as String),
          job: $checkedConvert(
              'job', (v) => Map<String, dynamic>.from(v as Map)),
          state: $checkedConvert('state', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'taskId': 'task_id'},
    );

Map<String, dynamic> _$$QueueSubmitResultImplToJson(
        _$QueueSubmitResultImpl instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'job': instance.job,
      'state': instance.state,
    };

_$MetricsSnapshotImpl _$$MetricsSnapshotImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MetricsSnapshotImpl',
      json,
      ($checkedConvert) {
        final val = _$MetricsSnapshotImpl(
          uptimeS: $checkedConvert('uptime_s', (v) => (v as num).toDouble()),
          counters: $checkedConvert(
              'counters', (v) => Map<String, dynamic>.from(v as Map)),
          latency: $checkedConvert(
              'latency', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {'uptimeS': 'uptime_s'},
    );

Map<String, dynamic> _$$MetricsSnapshotImplToJson(
        _$MetricsSnapshotImpl instance) =>
    <String, dynamic>{
      'uptime_s': instance.uptimeS,
      'counters': instance.counters,
      'latency': instance.latency,
    };

_$LatencyStatsImpl _$$LatencyStatsImplFromJson(Map json) => $checkedCreate(
      r'_$LatencyStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$LatencyStatsImpl(
          count: $checkedConvert('count', (v) => (v as num).toInt()),
          avgMs: $checkedConvert('avg_ms', (v) => (v as num).toDouble()),
          p95Ms: $checkedConvert('p95_ms', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'avgMs': 'avg_ms', 'p95Ms': 'p95_ms'},
    );

Map<String, dynamic> _$$LatencyStatsImplToJson(_$LatencyStatsImpl instance) =>
    <String, dynamic>{
      'count': instance.count,
      'avg_ms': instance.avgMs,
      'p95_ms': instance.p95Ms,
    };

_$FlagsSnapshotImpl _$$FlagsSnapshotImplFromJson(Map json) => $checkedCreate(
      r'_$FlagsSnapshotImpl',
      json,
      ($checkedConvert) {
        final val = _$FlagsSnapshotImpl(
          flags:
              $checkedConvert('flags', (v) => Map<String, bool>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$FlagsSnapshotImplToJson(_$FlagsSnapshotImpl instance) =>
    <String, dynamic>{
      'flags': instance.flags,
    };

_$MemoryItemImpl _$$MemoryItemImplFromJson(Map json) => $checkedCreate(
      r'_$MemoryItemImpl',
      json,
      ($checkedConvert) {
        final val = _$MemoryItemImpl(
          id: $checkedConvert('id', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          createdAt: $checkedConvert('created_at', (v) => v as String?),
          score: $checkedConvert('score', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$$MemoryItemImplToJson(_$MemoryItemImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'content': instance.content,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  writeNotNull('created_at', instance.createdAt);
  writeNotNull('score', instance.score);
  return val;
}

_$MemoryListResponseImpl _$$MemoryListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MemoryListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$MemoryListResponseImpl(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      MemoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          limit: $checkedConvert('limit', (v) => (v as num?)?.toInt()),
          offset: $checkedConvert('offset', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$MemoryListResponseImplToJson(
    _$MemoryListResponseImpl instance) {
  final val = <String, dynamic>{
    'items': instance.items,
    'total': instance.total,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('limit', instance.limit);
  writeNotNull('offset', instance.offset);
  return val;
}

_$MemorySearchResponseImpl _$$MemorySearchResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MemorySearchResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$MemorySearchResponseImpl(
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      MemoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
          query: $checkedConvert('query', (v) => v as String),
          count: $checkedConvert('count', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$MemorySearchResponseImplToJson(
        _$MemorySearchResponseImpl instance) =>
    <String, dynamic>{
      'results': instance.results,
      'query': instance.query,
      'count': instance.count,
    };

_$MemoryCreateResponseImpl _$$MemoryCreateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MemoryCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$MemoryCreateResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          createdAt: $checkedConvert('created_at', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$$MemoryCreateResponseImplToJson(
    _$MemoryCreateResponseImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'content': instance.content,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  writeNotNull('created_at', instance.createdAt);
  return val;
}

_$MemoryStatsResponseImpl _$$MemoryStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MemoryStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$MemoryStatsResponseImpl(
          totalMemories:
              $checkedConvert('total_memories', (v) => (v as num).toInt()),
          totalVectors:
              $checkedConvert('total_vectors', (v) => (v as num).toInt()),
          indexType: $checkedConvert('index_type', (v) => v as String),
          indexSizeMb:
              $checkedConvert('index_size_mb', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalMemories': 'total_memories',
        'totalVectors': 'total_vectors',
        'indexType': 'index_type',
        'indexSizeMb': 'index_size_mb'
      },
    );

Map<String, dynamic> _$$MemoryStatsResponseImplToJson(
        _$MemoryStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_memories': instance.totalMemories,
      'total_vectors': instance.totalVectors,
      'index_type': instance.indexType,
      'index_size_mb': instance.indexSizeMb,
    };

_$ToolInfoImpl _$$ToolInfoImplFromJson(Map json) => $checkedCreate(
      r'_$ToolInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$ToolInfoImpl(
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          category: $checkedConvert('category', (v) => v as String),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          schema: $checkedConvert(
              'schema',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ToolInfoImplToJson(_$ToolInfoImpl instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'description': instance.description,
    'category': instance.category,
    'enabled': instance.enabled,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('schema', instance.schema);
  writeNotNull('metadata', instance.metadata);
  return val;
}

_$ToolsListResponseImpl _$$ToolsListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ToolsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ToolsListResponseImpl(
          tools: $checkedConvert(
              'tools',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ToolInfo.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ToolsListResponseImplToJson(
        _$ToolsListResponseImpl instance) =>
    <String, dynamic>{
      'tools': instance.tools,
    };

_$ToolRunResponseImpl _$$ToolRunResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ToolRunResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ToolRunResponseImpl(
          result: $checkedConvert('result', (v) => v),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ToolRunResponseImplToJson(
    _$ToolRunResponseImpl instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('result', instance.result);
  writeNotNull('error', instance.error);
  return val;
}

_$ToolLogEntryImpl _$$ToolLogEntryImplFromJson(Map json) => $checkedCreate(
      r'_$ToolLogEntryImpl',
      json,
      ($checkedConvert) {
        final val = _$ToolLogEntryImpl(
          tool: $checkedConvert('tool', (v) => v as String),
          calls: $checkedConvert('calls', (v) => (v as num).toInt()),
          successes: $checkedConvert('successes', (v) => (v as num).toInt()),
          failures: $checkedConvert('failures', (v) => (v as num).toInt()),
          avgTime: $checkedConvert('avg_time', (v) => (v as num).toDouble()),
          lastError: $checkedConvert('last_error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'avgTime': 'avg_time', 'lastError': 'last_error'},
    );

Map<String, dynamic> _$$ToolLogEntryImplToJson(_$ToolLogEntryImpl instance) {
  final val = <String, dynamic>{
    'tool': instance.tool,
    'calls': instance.calls,
    'successes': instance.successes,
    'failures': instance.failures,
    'avg_time': instance.avgTime,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('last_error', instance.lastError);
  return val;
}

_$ToolsLogsResponseImpl _$$ToolsLogsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ToolsLogsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ToolsLogsResponseImpl(
          logs: $checkedConvert(
              'logs',
              (v) => (v as List<dynamic>)
                  .map((e) => ToolLogEntry.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ToolsLogsResponseImplToJson(
        _$ToolsLogsResponseImpl instance) =>
    <String, dynamic>{
      'logs': instance.logs,
    };

_$FrameworkToolImpl _$$FrameworkToolImplFromJson(Map json) => $checkedCreate(
      r'_$FrameworkToolImpl',
      json,
      ($checkedConvert) {
        final val = _$FrameworkToolImpl(
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          category: $checkedConvert('category', (v) => v as String),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          permission: $checkedConvert('permission', (v) => v as String),
          timeoutSeconds:
              $checkedConvert('timeout_seconds', (v) => (v as num).toInt()),
          maxRetries: $checkedConvert('max_retries', (v) => (v as num).toInt()),
          dangerous: $checkedConvert('dangerous', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'timeoutSeconds': 'timeout_seconds',
        'maxRetries': 'max_retries'
      },
    );

Map<String, dynamic> _$$FrameworkToolImplToJson(_$FrameworkToolImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'enabled': instance.enabled,
      'permission': instance.permission,
      'timeout_seconds': instance.timeoutSeconds,
      'max_retries': instance.maxRetries,
      'dangerous': instance.dangerous,
    };

_$ToolsFrameworkResponseImpl _$$ToolsFrameworkResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ToolsFrameworkResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ToolsFrameworkResponseImpl(
          tools: $checkedConvert(
              'tools',
              (v) => (v as List<dynamic>)
                  .map((e) => FrameworkTool.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ToolsFrameworkResponseImplToJson(
        _$ToolsFrameworkResponseImpl instance) =>
    <String, dynamic>{
      'tools': instance.tools,
    };

_$ProviderInfoImpl _$$ProviderInfoImplFromJson(Map json) => $checkedCreate(
      r'_$ProviderInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$ProviderInfoImpl(
          id: $checkedConvert('id', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String),
          configured: $checkedConvert('configured', (v) => v as bool),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          active: $checkedConvert('active', (v) => v as bool),
          errorCount: $checkedConvert('error_count', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'errorCount': 'error_count'},
    );

Map<String, dynamic> _$$ProviderInfoImplToJson(_$ProviderInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'configured': instance.configured,
      'enabled': instance.enabled,
      'active': instance.active,
      'error_count': instance.errorCount,
    };

_$ProvidersListResponseImpl _$$ProvidersListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ProvidersListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProvidersListResponseImpl(
          providers: $checkedConvert(
              'providers',
              (v) => (v as List<dynamic>)
                  .map((e) => ProviderInfo.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProvidersListResponseImplToJson(
        _$ProvidersListResponseImpl instance) =>
    <String, dynamic>{
      'providers': instance.providers,
    };

_$BrainAnalyzeResponseImpl _$$BrainAnalyzeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BrainAnalyzeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BrainAnalyzeResponseImpl(
          goal: $checkedConvert('goal', (v) => v as String),
          complexity: $checkedConvert('complexity', (v) => v as String),
          estimatedSteps:
              $checkedConvert('estimated_steps', (v) => (v as num).toInt()),
          suggestedTools: $checkedConvert('suggested_tools',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          subGoals: $checkedConvert('sub_goals',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'estimatedSteps': 'estimated_steps',
        'suggestedTools': 'suggested_tools',
        'subGoals': 'sub_goals'
      },
    );

Map<String, dynamic> _$$BrainAnalyzeResponseImplToJson(
        _$BrainAnalyzeResponseImpl instance) =>
    <String, dynamic>{
      'goal': instance.goal,
      'complexity': instance.complexity,
      'estimated_steps': instance.estimatedSteps,
      'suggested_tools': instance.suggestedTools,
      'sub_goals': instance.subGoals,
    };

_$GraphNodeImpl _$$GraphNodeImplFromJson(Map json) => $checkedCreate(
      r'_$GraphNodeImpl',
      json,
      ($checkedConvert) {
        final val = _$GraphNodeImpl(
          id: $checkedConvert('id', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          tool: $checkedConvert('tool', (v) => v as String?),
          agent: $checkedConvert('agent', (v) => v as String?),
          dependsOn: $checkedConvert('depends_on',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          state: $checkedConvert('state', (v) => v as String),
          attempts: $checkedConvert('attempts', (v) => (v as num).toInt()),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'dependsOn': 'depends_on'},
    );

Map<String, dynamic> _$$GraphNodeImplToJson(_$GraphNodeImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'description': instance.description,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('tool', instance.tool);
  writeNotNull('agent', instance.agent);
  val['depends_on'] = instance.dependsOn;
  val['state'] = instance.state;
  val['attempts'] = instance.attempts;
  writeNotNull('error', instance.error);
  return val;
}

_$GraphProgressImpl _$$GraphProgressImplFromJson(Map json) => $checkedCreate(
      r'_$GraphProgressImpl',
      json,
      ($checkedConvert) {
        final val = _$GraphProgressImpl(
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          states:
              $checkedConvert('states', (v) => Map<String, int>.from(v as Map)),
          percent: $checkedConvert('percent', (v) => (v as num).toDouble()),
          finished: $checkedConvert('finished', (v) => v as bool),
          stuck: $checkedConvert('stuck', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GraphProgressImplToJson(_$GraphProgressImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'states': instance.states,
      'percent': instance.percent,
      'finished': instance.finished,
      'stuck': instance.stuck,
    };

_$BrainGraphResponseImpl _$$BrainGraphResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BrainGraphResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BrainGraphResponseImpl(
          nodes: $checkedConvert(
              'nodes',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      GraphNode.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
          progress: $checkedConvert(
              'progress',
              (v) =>
                  GraphProgress.fromJson(Map<String, dynamic>.from(v as Map))),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BrainGraphResponseImplToJson(
        _$BrainGraphResponseImpl instance) =>
    <String, dynamic>{
      'nodes': instance.nodes,
      'progress': instance.progress,
    };

_$AgentInfoImpl _$$AgentInfoImplFromJson(Map json) => $checkedCreate(
      r'_$AgentInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentInfoImpl(
          name: $checkedConvert('name', (v) => v as String),
          role: $checkedConvert('role', (v) => v as String),
          skills: $checkedConvert('skills',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          permissions: $checkedConvert('permissions',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          ok: $checkedConvert('ok', (v) => (v as num).toInt()),
          errors: $checkedConvert('errors', (v) => (v as num).toInt()),
          successRate:
              $checkedConvert('success_rate', (v) => (v as num?)?.toDouble()),
          lastError: $checkedConvert('last_error', (v) => v as String?),
          lastActive:
              $checkedConvert('last_active', (v) => (v as num?)?.toDouble()),
          status: $checkedConvert('status', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'successRate': 'success_rate',
        'lastError': 'last_error',
        'lastActive': 'last_active'
      },
    );

Map<String, dynamic> _$$AgentInfoImplToJson(_$AgentInfoImpl instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'role': instance.role,
    'skills': instance.skills,
    'permissions': instance.permissions,
    'ok': instance.ok,
    'errors': instance.errors,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('success_rate', instance.successRate);
  writeNotNull('last_error', instance.lastError);
  writeNotNull('last_active', instance.lastActive);
  val['status'] = instance.status;
  return val;
}

_$AgentsListResponseImpl _$$AgentsListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AgentsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentsListResponseImpl(
          agents: $checkedConvert(
              'agents',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      AgentInfo.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AgentsListResponseImplToJson(
        _$AgentsListResponseImpl instance) =>
    <String, dynamic>{
      'agents': instance.agents,
    };

_$OrchestrationAssignmentImpl _$$OrchestrationAssignmentImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$OrchestrationAssignmentImpl',
      json,
      ($checkedConvert) {
        final val = _$OrchestrationAssignmentImpl(
          nodeId: $checkedConvert('node_id', (v) => v as String),
          agentName: $checkedConvert('agent_name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String?),
          tool: $checkedConvert('tool', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'nodeId': 'node_id', 'agentName': 'agent_name'},
    );

Map<String, dynamic> _$$OrchestrationAssignmentImplToJson(
    _$OrchestrationAssignmentImpl instance) {
  final val = <String, dynamic>{
    'node_id': instance.nodeId,
    'agent_name': instance.agentName,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  writeNotNull('tool', instance.tool);
  return val;
}

_$AgentsOrchestrateResponseImpl _$$AgentsOrchestrateResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$AgentsOrchestrateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentsOrchestrateResponseImpl(
          analysis: $checkedConvert(
              'analysis',
              (v) => BrainAnalyzeResponse.fromJson(
                  Map<String, dynamic>.from(v as Map))),
          assignments: $checkedConvert(
              'assignments', (v) => Map<String, String>.from(v as Map)),
          graph: $checkedConvert(
              'graph',
              (v) => BrainGraphResponse.fromJson(
                  Map<String, dynamic>.from(v as Map))),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AgentsOrchestrateResponseImplToJson(
        _$AgentsOrchestrateResponseImpl instance) =>
    <String, dynamic>{
      'analysis': instance.analysis,
      'assignments': instance.assignments,
      'graph': instance.graph,
    };

_$AgentMessageImpl _$$AgentMessageImplFromJson(Map json) => $checkedCreate(
      r'_$AgentMessageImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentMessageImpl(
          from: $checkedConvert('from', (v) => v as String),
          to: $checkedConvert('to', (v) => v as String),
          content: $checkedConvert('content', (v) => v),
          ts: $checkedConvert('ts', (v) => (v as num).toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AgentMessageImplToJson(_$AgentMessageImpl instance) {
  final val = <String, dynamic>{
    'from': instance.from,
    'to': instance.to,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('content', instance.content);
  val['ts'] = instance.ts;
  return val;
}

_$AgentsMessagesResponseImpl _$$AgentsMessagesResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AgentsMessagesResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentsMessagesResponseImpl(
          messages: $checkedConvert(
              'messages',
              (v) => (v as List<dynamic>)
                  .map((e) => AgentMessage.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AgentsMessagesResponseImplToJson(
        _$AgentsMessagesResponseImpl instance) =>
    <String, dynamic>{
      'messages': instance.messages,
    };

_$WorkflowPlanResponseImpl _$$WorkflowPlanResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WorkflowPlanResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WorkflowPlanResponseImpl(
          runId: $checkedConvert('run_id', (v) => v as String),
          state: $checkedConvert(
              'state', (v) => Map<String, String>.from(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {'runId': 'run_id'},
    );

Map<String, dynamic> _$$WorkflowPlanResponseImplToJson(
        _$WorkflowPlanResponseImpl instance) =>
    <String, dynamic>{
      'run_id': instance.runId,
      'state': instance.state,
    };

_$WorkflowNodeImpl _$$WorkflowNodeImplFromJson(Map json) => $checkedCreate(
      r'_$WorkflowNodeImpl',
      json,
      ($checkedConvert) {
        final val = _$WorkflowNodeImpl(
          id: $checkedConvert('id', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          tool: $checkedConvert('tool', (v) => v as String?),
          agent: $checkedConvert('agent', (v) => v as String?),
          dependsOn: $checkedConvert('depends_on',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          state: $checkedConvert('state', (v) => v as String),
          attempts: $checkedConvert('attempts', (v) => (v as num).toInt()),
          error: $checkedConvert('error', (v) => v as String?),
          recoveryNote: $checkedConvert('recovery_note', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'dependsOn': 'depends_on',
        'recoveryNote': 'recovery_note'
      },
    );

Map<String, dynamic> _$$WorkflowNodeImplToJson(_$WorkflowNodeImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'description': instance.description,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('tool', instance.tool);
  writeNotNull('agent', instance.agent);
  val['depends_on'] = instance.dependsOn;
  val['state'] = instance.state;
  val['attempts'] = instance.attempts;
  writeNotNull('error', instance.error);
  writeNotNull('recovery_note', instance.recoveryNote);
  return val;
}

_$WorkflowRunStateImpl _$$WorkflowRunStateImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WorkflowRunStateImpl',
      json,
      ($checkedConvert) {
        final val = _$WorkflowRunStateImpl(
          id: $checkedConvert('id', (v) => v as String),
          goal: $checkedConvert('goal', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          created: $checkedConvert('created', (v) => (v as num).toDouble()),
          results: $checkedConvert('results', (v) => v as List<dynamic>),
          nodes: $checkedConvert(
              'nodes',
              (v) => (v as List<dynamic>)
                  .map((e) => WorkflowNode.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          replansLeft:
              $checkedConvert('replans_left', (v) => (v as num?)?.toInt()),
          recoveryLog:
              $checkedConvert('recovery_log', (v) => v as List<dynamic>?),
          replanCount:
              $checkedConvert('replan_count', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'replansLeft': 'replans_left',
        'recoveryLog': 'recovery_log',
        'replanCount': 'replan_count'
      },
    );

Map<String, dynamic> _$$WorkflowRunStateImplToJson(
    _$WorkflowRunStateImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'goal': instance.goal,
    'status': instance.status,
    'created': instance.created,
    'results': instance.results,
    'nodes': instance.nodes,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('replans_left', instance.replansLeft);
  writeNotNull('recovery_log', instance.recoveryLog);
  writeNotNull('replan_count', instance.replanCount);
  return val;
}

_$WorkflowsRunsResponseImpl _$$WorkflowsRunsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WorkflowsRunsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WorkflowsRunsResponseImpl(
          checkpoints: $checkedConvert('checkpoints',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$WorkflowsRunsResponseImplToJson(
        _$WorkflowsRunsResponseImpl instance) =>
    <String, dynamic>{
      'checkpoints': instance.checkpoints,
    };

_$WorkflowExecuteResponseImpl _$$WorkflowExecuteResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$WorkflowExecuteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WorkflowExecuteResponseImpl(
          runId: $checkedConvert('run_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          progress: $checkedConvert(
              'progress', (v) => Map<String, dynamic>.from(v as Map)),
          results: $checkedConvert('results', (v) => v as List<dynamic>),
          recoveryLog:
              $checkedConvert('recovery_log', (v) => v as List<dynamic>),
          replansUsed:
              $checkedConvert('replans_used', (v) => (v as num).toInt()),
          planConfidence: $checkedConvert(
              'plan_confidence', (v) => (v as num?)?.toDouble()),
          shouldReplan: $checkedConvert('should_replan', (v) => v as bool?),
          stepCount: $checkedConvert('step_count', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'runId': 'run_id',
        'recoveryLog': 'recovery_log',
        'replansUsed': 'replans_used',
        'planConfidence': 'plan_confidence',
        'shouldReplan': 'should_replan',
        'stepCount': 'step_count'
      },
    );

Map<String, dynamic> _$$WorkflowExecuteResponseImplToJson(
    _$WorkflowExecuteResponseImpl instance) {
  final val = <String, dynamic>{
    'run_id': instance.runId,
    'status': instance.status,
    'progress': instance.progress,
    'results': instance.results,
    'recovery_log': instance.recoveryLog,
    'replans_used': instance.replansUsed,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('plan_confidence', instance.planConfidence);
  writeNotNull('should_replan', instance.shouldReplan);
  writeNotNull('step_count', instance.stepCount);
  return val;
}

_$AutonomousRunResponseImpl _$$AutonomousRunResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AutonomousRunResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AutonomousRunResponseImpl(
          goal: $checkedConvert('goal', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          progress: $checkedConvert(
              'progress', (v) => Map<String, dynamic>.from(v as Map)),
          results: $checkedConvert('results', (v) => v as List<dynamic>),
          recoveryLog:
              $checkedConvert('recovery_log', (v) => v as List<dynamic>),
          replansUsed:
              $checkedConvert('replans_used', (v) => (v as num).toInt()),
          planConfidence: $checkedConvert(
              'plan_confidence', (v) => (v as num?)?.toDouble()),
          shouldReplan: $checkedConvert('should_replan', (v) => v as bool?),
          stepCount: $checkedConvert('step_count', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'recoveryLog': 'recovery_log',
        'replansUsed': 'replans_used',
        'planConfidence': 'plan_confidence',
        'shouldReplan': 'should_replan',
        'stepCount': 'step_count'
      },
    );

Map<String, dynamic> _$$AutonomousRunResponseImplToJson(
    _$AutonomousRunResponseImpl instance) {
  final val = <String, dynamic>{
    'goal': instance.goal,
    'status': instance.status,
    'progress': instance.progress,
    'results': instance.results,
    'recovery_log': instance.recoveryLog,
    'replans_used': instance.replansUsed,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('plan_confidence', instance.planConfidence);
  writeNotNull('should_replan', instance.shouldReplan);
  writeNotNull('step_count', instance.stepCount);
  return val;
}

_$LLMProviderInfoImpl _$$LLMProviderInfoImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LLMProviderInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$LLMProviderInfoImpl(
          id: $checkedConvert('id', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String),
          configured: $checkedConvert('configured', (v) => v as bool),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          active: $checkedConvert('active', (v) => v as bool),
          errorCount: $checkedConvert('error_count', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'errorCount': 'error_count'},
    );

Map<String, dynamic> _$$LLMProviderInfoImplToJson(
        _$LLMProviderInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'configured': instance.configured,
      'enabled': instance.enabled,
      'active': instance.active,
      'error_count': instance.errorCount,
    };

_$LLMProvidersResponseImpl _$$LLMProvidersResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LLMProvidersResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LLMProvidersResponseImpl(
          providers: $checkedConvert(
              'providers',
              (v) => (v as List<dynamic>)
                  .map((e) => LLMProviderInfo.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LLMProvidersResponseImplToJson(
        _$LLMProvidersResponseImpl instance) =>
    <String, dynamic>{
      'providers': instance.providers,
    };

_$LLMProviderStatImpl _$$LLMProviderStatImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LLMProviderStatImpl',
      json,
      ($checkedConvert) {
        final val = _$LLMProviderStatImpl(
          latencyEmaS:
              $checkedConvert('latency_ema_s', (v) => (v as num).toDouble()),
          ok: $checkedConvert('ok', (v) => (v as num).toInt()),
          errors: $checkedConvert('errors', (v) => (v as num).toInt()),
          errorRate:
              $checkedConvert('error_rate', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'latencyEmaS': 'latency_ema_s',
        'errorRate': 'error_rate'
      },
    );

Map<String, dynamic> _$$LLMProviderStatImplToJson(
        _$LLMProviderStatImpl instance) =>
    <String, dynamic>{
      'latency_ema_s': instance.latencyEmaS,
      'ok': instance.ok,
      'errors': instance.errors,
      'error_rate': instance.errorRate,
    };

_$LLMStatsResponseImpl _$$LLMStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LLMStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LLMStatsResponseImpl(
          stats: $checkedConvert(
              'stats',
              (v) => (v as Map).map(
                    (k, e) => MapEntry(
                        k as String,
                        LLMProviderStat.fromJson(
                            Map<String, dynamic>.from(e as Map))),
                  )),
          table: $checkedConvert(
              'table',
              (v) => (v as Map).map(
                    (k, e) => MapEntry(
                        k as String, Map<String, dynamic>.from(e as Map)),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LLMStatsResponseImplToJson(
        _$LLMStatsResponseImpl instance) =>
    <String, dynamic>{
      'stats': instance.stats,
      'table': instance.table,
    };

_$LLMStrategyResponseImpl _$$LLMStrategyResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LLMStrategyResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LLMStrategyResponseImpl(
          strategy: $checkedConvert('strategy', (v) => v as String),
          order: $checkedConvert('order',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LLMStrategyResponseImplToJson(
        _$LLMStrategyResponseImpl instance) =>
    <String, dynamic>{
      'strategy': instance.strategy,
      'order': instance.order,
    };

_$RoleInfoImpl _$$RoleInfoImplFromJson(Map json) => $checkedCreate(
      r'_$RoleInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$RoleInfoImpl(
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          permissions: $checkedConvert('permissions',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$RoleInfoImplToJson(_$RoleInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'permissions': instance.permissions,
    };

_$AdminRolesResponseImpl _$$AdminRolesResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminRolesResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminRolesResponseImpl(
          roles: $checkedConvert(
              'roles',
              (v) => (v as Map).map(
                    (k, e) => MapEntry(k as String,
                        RoleInfo.fromJson(Map<String, dynamic>.from(e as Map))),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminRolesResponseImplToJson(
        _$AdminRolesResponseImpl instance) =>
    <String, dynamic>{
      'roles': instance.roles,
    };

_$AdminOrgImpl _$$AdminOrgImplFromJson(Map json) => $checkedCreate(
      r'_$AdminOrgImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminOrgImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          memberCount:
              $checkedConvert('member_count', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'memberCount': 'member_count'
      },
    );

Map<String, dynamic> _$$AdminOrgImplToJson(_$AdminOrgImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'created_at': instance.createdAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('member_count', instance.memberCount);
  return val;
}

_$AdminOrgsResponseImpl _$$AdminOrgsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminOrgsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminOrgsResponseImpl(
          orgs: $checkedConvert(
              'orgs',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      AdminOrg.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminOrgsResponseImplToJson(
        _$AdminOrgsResponseImpl instance) =>
    <String, dynamic>{
      'orgs': instance.orgs,
    };

_$AdminOrgResponseImpl _$$AdminOrgResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminOrgResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminOrgResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminOrgResponseImplToJson(
        _$AdminOrgResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

_$OrgMemberImpl _$$OrgMemberImplFromJson(Map json) => $checkedCreate(
      r'_$OrgMemberImpl',
      json,
      ($checkedConvert) {
        final val = _$OrgMemberImpl(
          email: $checkedConvert('email', (v) => v as String),
          role: $checkedConvert('role', (v) => v as String),
          teamId: $checkedConvert('team_id', (v) => v as String?),
          joinedAt: $checkedConvert('joined_at', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'teamId': 'team_id', 'joinedAt': 'joined_at'},
    );

Map<String, dynamic> _$$OrgMemberImplToJson(_$OrgMemberImpl instance) {
  final val = <String, dynamic>{
    'email': instance.email,
    'role': instance.role,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('team_id', instance.teamId);
  val['joined_at'] = instance.joinedAt;
  return val;
}

_$AdminOrgMembersResponseImpl _$$AdminOrgMembersResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$AdminOrgMembersResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminOrgMembersResponseImpl(
          members: $checkedConvert(
              'members',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      OrgMember.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminOrgMembersResponseImplToJson(
        _$AdminOrgMembersResponseImpl instance) =>
    <String, dynamic>{
      'members': instance.members,
    };

_$AdminApiKeyImpl _$$AdminApiKeyImplFromJson(Map json) => $checkedCreate(
      r'_$AdminApiKeyImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminApiKeyImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          prefix: $checkedConvert('prefix', (v) => v as String),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          lastUsedAt: $checkedConvert('last_used_at', (v) => v as String?),
          revoked: $checkedConvert('revoked', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'lastUsedAt': 'last_used_at'
      },
    );

Map<String, dynamic> _$$AdminApiKeyImplToJson(_$AdminApiKeyImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'prefix': instance.prefix,
    'created_at': instance.createdAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('last_used_at', instance.lastUsedAt);
  val['revoked'] = instance.revoked;
  return val;
}

_$AdminApiKeysResponseImpl _$$AdminApiKeysResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminApiKeysResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminApiKeysResponseImpl(
          keys: $checkedConvert(
              'keys',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      AdminApiKey.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminApiKeysResponseImplToJson(
        _$AdminApiKeysResponseImpl instance) =>
    <String, dynamic>{
      'keys': instance.keys,
    };

_$AdminApiKeyCreatedResponseImpl _$$AdminApiKeyCreatedResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$AdminApiKeyCreatedResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminApiKeyCreatedResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          key: $checkedConvert('key', (v) => v as String),
          prefix: $checkedConvert('prefix', (v) => v as String),
          createdAt: $checkedConvert('created_at', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$$AdminApiKeyCreatedResponseImplToJson(
        _$AdminApiKeyCreatedResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'key': instance.key,
      'prefix': instance.prefix,
      'created_at': instance.createdAt,
    };

_$AuditEventImpl _$$AuditEventImplFromJson(Map json) => $checkedCreate(
      r'_$AuditEventImpl',
      json,
      ($checkedConvert) {
        final val = _$AuditEventImpl(
          id: $checkedConvert('id', (v) => v as String),
          actor: $checkedConvert('actor', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          target: $checkedConvert('target', (v) => v as String),
          details: $checkedConvert(
              'details', (v) => Map<String, dynamic>.from(v as Map)),
          timestamp: $checkedConvert('timestamp', (v) => (v as num).toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AuditEventImplToJson(_$AuditEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'actor': instance.actor,
      'action': instance.action,
      'target': instance.target,
      'details': instance.details,
      'timestamp': instance.timestamp,
    };

_$AdminAuditResponseImpl _$$AdminAuditResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminAuditResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminAuditResponseImpl(
          events: $checkedConvert(
              'events',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      AuditEvent.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminAuditResponseImplToJson(
        _$AdminAuditResponseImpl instance) =>
    <String, dynamic>{
      'events': instance.events,
    };

_$AdminUsageResponseImpl _$$AdminUsageResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminUsageResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminUsageResponseImpl(
          summary: $checkedConvert(
              'summary', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminUsageResponseImplToJson(
        _$AdminUsageResponseImpl instance) =>
    <String, dynamic>{
      'summary': instance.summary,
    };

_$AdminDashboardResponseImpl _$$AdminDashboardResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminDashboardResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminDashboardResponseImpl(
          metrics: $checkedConvert(
              'metrics', (v) => Map<String, dynamic>.from(v as Map)),
          agents: $checkedConvert(
              'agents', (v) => Map<String, dynamic>.from(v as Map)),
          providers: $checkedConvert(
              'providers', (v) => Map<String, dynamic>.from(v as Map)),
          queueDepth: $checkedConvert('queue_depth', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'queueDepth': 'queue_depth'},
    );

Map<String, dynamic> _$$AdminDashboardResponseImplToJson(
        _$AdminDashboardResponseImpl instance) =>
    <String, dynamic>{
      'metrics': instance.metrics,
      'agents': instance.agents,
      'providers': instance.providers,
      'queue_depth': instance.queueDepth,
    };

_$AdminOwnerModeResponseImpl _$$AdminOwnerModeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminOwnerModeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminOwnerModeResponseImpl(
          mode: $checkedConvert('mode', (v) => v as String),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminOwnerModeResponseImplToJson(
    _$AdminOwnerModeResponseImpl instance) {
  final val = <String, dynamic>{
    'mode': instance.mode,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$LearningFeedbackResponseImpl _$$LearningFeedbackResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$LearningFeedbackResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LearningFeedbackResponseImpl(
          recorded: $checkedConvert('recorded', (v) => v as bool),
          stats: $checkedConvert(
              'stats', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LearningFeedbackResponseImplToJson(
        _$LearningFeedbackResponseImpl instance) =>
    <String, dynamic>{
      'recorded': instance.recorded,
      'stats': instance.stats,
    };

_$FeedbackStatsImpl _$$FeedbackStatsImplFromJson(Map json) => $checkedCreate(
      r'_$FeedbackStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$FeedbackStatsImpl(
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          positive: $checkedConvert('positive', (v) => (v as num).toInt()),
          negative: $checkedConvert('negative', (v) => (v as num).toInt()),
          satisfaction:
              $checkedConvert('satisfaction', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$FeedbackStatsImplToJson(_$FeedbackStatsImpl instance) {
  final val = <String, dynamic>{
    'total': instance.total,
    'positive': instance.positive,
    'negative': instance.negative,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('satisfaction', instance.satisfaction);
  return val;
}

_$LessonImpl _$$LessonImplFromJson(Map json) => $checkedCreate(
      r'_$LessonImpl',
      json,
      ($checkedConvert) {
        final val = _$LessonImpl(
          ts: $checkedConvert('ts', (v) => (v as num).toDouble()),
          goal: $checkedConvert('goal', (v) => v as String),
          comment: $checkedConvert('comment', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LessonImplToJson(_$LessonImpl instance) =>
    <String, dynamic>{
      'ts': instance.ts,
      'goal': instance.goal,
      'comment': instance.comment,
    };

_$LearningStatsResponseImpl _$$LearningStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LearningStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LearningStatsResponseImpl(
          feedback: $checkedConvert(
              'feedback',
              (v) =>
                  FeedbackStats.fromJson(Map<String, dynamic>.from(v as Map))),
          lessons: $checkedConvert(
              'lessons',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Lesson.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
          prompts: $checkedConvert(
              'prompts', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LearningStatsResponseImplToJson(
        _$LearningStatsResponseImpl instance) =>
    <String, dynamic>{
      'feedback': instance.feedback,
      'lessons': instance.lessons,
      'prompts': instance.prompts,
    };

_$ExperienceEpisodeImpl _$$ExperienceEpisodeImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExperienceEpisodeImpl',
      json,
      ($checkedConvert) {
        final val = _$ExperienceEpisodeImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          ts: $checkedConvert('ts', (v) => (v as num).toDouble()),
          goal: $checkedConvert('goal', (v) => v as String),
          steps: $checkedConvert('steps', (v) => v as List<dynamic>),
          outcome: $checkedConvert('outcome', (v) => v as String),
          confidence:
              $checkedConvert('confidence', (v) => (v as num).toDouble()),
          similarity:
              $checkedConvert('similarity', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExperienceEpisodeImplToJson(
    _$ExperienceEpisodeImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'ts': instance.ts,
    'goal': instance.goal,
    'steps': instance.steps,
    'outcome': instance.outcome,
    'confidence': instance.confidence,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('similarity', instance.similarity);
  return val;
}

_$LearningExperienceResponseImpl _$$LearningExperienceResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$LearningExperienceResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LearningExperienceResponseImpl(
          similar: $checkedConvert(
              'similar',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ExperienceEpisode.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          history: $checkedConvert(
              'history',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ExperienceEpisode.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          successRate: $checkedConvert(
              'success_rate',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {'successRate': 'success_rate'},
    );

Map<String, dynamic> _$$LearningExperienceResponseImplToJson(
    _$LearningExperienceResponseImpl instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('similar', instance.similar);
  writeNotNull('history', instance.history);
  writeNotNull('success_rate', instance.successRate);
  return val;
}

_$LearningCompressResponseImpl _$$LearningCompressResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$LearningCompressResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LearningCompressResponseImpl(
          dryRun: $checkedConvert('dry_run', (v) => v as bool),
          memoryType: $checkedConvert('memory_type', (v) => v as String),
          result: $checkedConvert(
              'result', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {'dryRun': 'dry_run', 'memoryType': 'memory_type'},
    );

Map<String, dynamic> _$$LearningCompressResponseImplToJson(
        _$LearningCompressResponseImpl instance) =>
    <String, dynamic>{
      'dry_run': instance.dryRun,
      'memory_type': instance.memoryType,
      'result': instance.result,
    };

_$PromptVariantImpl _$$PromptVariantImplFromJson(Map json) => $checkedCreate(
      r'_$PromptVariantImpl',
      json,
      ($checkedConvert) {
        final val = _$PromptVariantImpl(
          ok: $checkedConvert('ok', (v) => (v as num).toInt()),
          fail: $checkedConvert('fail', (v) => (v as num).toInt()),
          score: $checkedConvert('score', (v) => (v as num).toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$PromptVariantImplToJson(_$PromptVariantImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'fail': instance.fail,
      'score': instance.score,
    };

_$LearningPromptsResponseImpl _$$LearningPromptsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$LearningPromptsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LearningPromptsResponseImpl(
          prompts: $checkedConvert(
              'prompts',
              (v) => (v as Map).map(
                    (k, e) => MapEntry(
                        k as String,
                        (e as Map).map(
                          (k, e) => MapEntry(
                              k as String,
                              PromptVariant.fromJson(
                                  Map<String, dynamic>.from(e as Map))),
                        )),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LearningPromptsResponseImplToJson(
        _$LearningPromptsResponseImpl instance) =>
    <String, dynamic>{
      'prompts': instance.prompts,
    };

_$RAGStatsResponseImpl _$$RAGStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RAGStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RAGStatsResponseImpl(
          totalDocuments:
              $checkedConvert('total_documents', (v) => (v as num).toInt()),
          totalChunks:
              $checkedConvert('total_chunks', (v) => (v as num).toInt()),
          indexType: $checkedConvert('index_type', (v) => v as String),
          indexSizeMb:
              $checkedConvert('index_size_mb', (v) => (v as num).toDouble()),
          searchEngines: $checkedConvert(
              'search_engines', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalDocuments': 'total_documents',
        'totalChunks': 'total_chunks',
        'indexType': 'index_type',
        'indexSizeMb': 'index_size_mb',
        'searchEngines': 'search_engines'
      },
    );

Map<String, dynamic> _$$RAGStatsResponseImplToJson(
        _$RAGStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_documents': instance.totalDocuments,
      'total_chunks': instance.totalChunks,
      'index_type': instance.indexType,
      'index_size_mb': instance.indexSizeMb,
      'search_engines': instance.searchEngines,
    };

_$RAGDocumentImpl _$$RAGDocumentImplFromJson(Map json) => $checkedCreate(
      r'_$RAGDocumentImpl',
      json,
      ($checkedConvert) {
        final val = _$RAGDocumentImpl(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          docType: $checkedConvert('doc_type', (v) => v as String),
          chunkCount: $checkedConvert('chunk_count', (v) => (v as num).toInt()),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          sizeKb: $checkedConvert('size_kb', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'docType': 'doc_type',
        'chunkCount': 'chunk_count',
        'createdAt': 'created_at',
        'sizeKb': 'size_kb'
      },
    );

Map<String, dynamic> _$$RAGDocumentImplToJson(_$RAGDocumentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'doc_type': instance.docType,
      'chunk_count': instance.chunkCount,
      'created_at': instance.createdAt,
      'size_kb': instance.sizeKb,
    };

_$RAGDocumentsResponseImpl _$$RAGDocumentsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RAGDocumentsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RAGDocumentsResponseImpl(
          documents: $checkedConvert(
              'documents',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      RAGDocument.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$RAGDocumentsResponseImplToJson(
        _$RAGDocumentsResponseImpl instance) =>
    <String, dynamic>{
      'documents': instance.documents,
    };

_$RAGIngestResponseImpl _$$RAGIngestResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RAGIngestResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RAGIngestResponseImpl(
          docId: $checkedConvert('doc_id', (v) => v as String),
          chunksCreated:
              $checkedConvert('chunks_created', (v) => (v as num).toInt()),
          title: $checkedConvert('title', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'docId': 'doc_id', 'chunksCreated': 'chunks_created'},
    );

Map<String, dynamic> _$$RAGIngestResponseImplToJson(
        _$RAGIngestResponseImpl instance) =>
    <String, dynamic>{
      'doc_id': instance.docId,
      'chunks_created': instance.chunksCreated,
      'title': instance.title,
    };

_$RAGSearchResultImpl _$$RAGSearchResultImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RAGSearchResultImpl',
      json,
      ($checkedConvert) {
        final val = _$RAGSearchResultImpl(
          docId: $checkedConvert('doc_id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          score: $checkedConvert('score', (v) => (v as num).toDouble()),
          docType: $checkedConvert('doc_type', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'docId': 'doc_id', 'docType': 'doc_type'},
    );

Map<String, dynamic> _$$RAGSearchResultImplToJson(
        _$RAGSearchResultImpl instance) =>
    <String, dynamic>{
      'doc_id': instance.docId,
      'title': instance.title,
      'content': instance.content,
      'score': instance.score,
      'doc_type': instance.docType,
    };

_$RAGSearchResponseImpl _$$RAGSearchResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RAGSearchResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RAGSearchResponseImpl(
          query: $checkedConvert('query', (v) => v as String),
          mode: $checkedConvert('mode', (v) => v as String),
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => RAGSearchResult.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$RAGSearchResponseImplToJson(
        _$RAGSearchResponseImpl instance) =>
    <String, dynamic>{
      'query': instance.query,
      'mode': instance.mode,
      'results': instance.results,
    };

_$RAGContextResponseImpl _$$RAGContextResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RAGContextResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RAGContextResponseImpl(
          context: $checkedConvert('context', (v) => v as String),
          citations: $checkedConvert(
              'citations',
              (v) => (v as List<dynamic>)
                  .map((e) => RAGSearchResult.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$RAGContextResponseImplToJson(
        _$RAGContextResponseImpl instance) =>
    <String, dynamic>{
      'context': instance.context,
      'citations': instance.citations,
    };

_$DeviceInfoImpl _$$DeviceInfoImplFromJson(Map json) => $checkedCreate(
      r'_$DeviceInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$DeviceInfoImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          pairedAt: $checkedConvert('paired_at', (v) => (v as num).toDouble()),
          lastSeen:
              $checkedConvert('last_seen', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'pairedAt': 'paired_at', 'lastSeen': 'last_seen'},
    );

Map<String, dynamic> _$$DeviceInfoImplToJson(_$DeviceInfoImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'paired_at': instance.pairedAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('last_seen', instance.lastSeen);
  return val;
}

_$DeviceListResponseImpl _$$DeviceListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$DeviceListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$DeviceListResponseImpl(
          devices: $checkedConvert(
              'devices',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      DeviceInfo.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$DeviceListResponseImplToJson(
        _$DeviceListResponseImpl instance) =>
    <String, dynamic>{
      'devices': instance.devices,
    };

_$DevicePairStartResponseImpl _$$DevicePairStartResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$DevicePairStartResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$DevicePairStartResponseImpl(
          pairingCode: $checkedConvert('pairing_code', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'pairingCode': 'pairing_code'},
    );

Map<String, dynamic> _$$DevicePairStartResponseImplToJson(
        _$DevicePairStartResponseImpl instance) =>
    <String, dynamic>{
      'pairing_code': instance.pairingCode,
      'name': instance.name,
    };

_$DevicePairCompleteResponseImpl _$$DevicePairCompleteResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$DevicePairCompleteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$DevicePairCompleteResponseImpl(
          deviceId: $checkedConvert('device_id', (v) => v as String),
          secret: $checkedConvert('secret', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'deviceId': 'device_id'},
    );

Map<String, dynamic> _$$DevicePairCompleteResponseImplToJson(
        _$DevicePairCompleteResponseImpl instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'secret': instance.secret,
    };

_$DeviceCommandEntryImpl _$$DeviceCommandEntryImplFromJson(Map json) =>
    $checkedCreate(
      r'_$DeviceCommandEntryImpl',
      json,
      ($checkedConvert) {
        final val = _$DeviceCommandEntryImpl(
          id: $checkedConvert('id', (v) => v as String),
          deviceId: $checkedConvert('device_id', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          params: $checkedConvert(
              'params', (v) => Map<String, dynamic>.from(v as Map)),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
          result: $checkedConvert(
              'result',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {'deviceId': 'device_id', 'createdAt': 'created_at'},
    );

Map<String, dynamic> _$$DeviceCommandEntryImplToJson(
    _$DeviceCommandEntryImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'device_id': instance.deviceId,
    'action': instance.action,
    'params': instance.params,
    'status': instance.status,
    'created_at': instance.createdAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('result', instance.result);
  return val;
}

_$DeviceHistoryResponseImpl _$$DeviceHistoryResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$DeviceHistoryResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$DeviceHistoryResponseImpl(
          commands: $checkedConvert(
              'commands',
              (v) => (v as List<dynamic>)
                  .map((e) => DeviceCommandEntry.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$DeviceHistoryResponseImplToJson(
        _$DeviceHistoryResponseImpl instance) =>
    <String, dynamic>{
      'commands': instance.commands,
    };

_$DeviceCommandResponseImpl _$$DeviceCommandResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$DeviceCommandResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$DeviceCommandResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          deviceId: $checkedConvert('device_id', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          params: $checkedConvert(
              'params', (v) => Map<String, dynamic>.from(v as Map)),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'deviceId': 'device_id', 'createdAt': 'created_at'},
    );

Map<String, dynamic> _$$DeviceCommandResponseImplToJson(
        _$DeviceCommandResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device_id': instance.deviceId,
      'action': instance.action,
      'params': instance.params,
      'status': instance.status,
      'created_at': instance.createdAt,
    };

_$DeviceCommandResultImpl _$$DeviceCommandResultImplFromJson(Map json) =>
    $checkedCreate(
      r'_$DeviceCommandResultImpl',
      json,
      ($checkedConvert) {
        final val = _$DeviceCommandResultImpl(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          result: $checkedConvert(
              'result',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$$DeviceCommandResultImplToJson(
    _$DeviceCommandResultImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'status': instance.status,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('result', instance.result);
  return val;
}

_$InstanceInfoImpl _$$InstanceInfoImplFromJson(Map json) => $checkedCreate(
      r'_$InstanceInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$InstanceInfoImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          persona: $checkedConvert('persona', (v) => v as String),
          memoryScope: $checkedConvert('memory_scope', (v) => v as String),
          skills: $checkedConvert('skills',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          budgetUsd:
              $checkedConvert('budget_usd', (v) => (v as num).toDouble()),
          owner: $checkedConvert('owner', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'memoryScope': 'memory_scope',
        'budgetUsd': 'budget_usd',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$$InstanceInfoImplToJson(_$InstanceInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'persona': instance.persona,
      'memory_scope': instance.memoryScope,
      'skills': instance.skills,
      'budget_usd': instance.budgetUsd,
      'owner': instance.owner,
      'created_at': instance.createdAt,
    };

_$InstancesListResponseImpl _$$InstancesListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$InstancesListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$InstancesListResponseImpl(
          instances: $checkedConvert(
              'instances',
              (v) => (v as List<dynamic>)
                  .map((e) => InstanceInfo.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$InstancesListResponseImplToJson(
        _$InstancesListResponseImpl instance) =>
    <String, dynamic>{
      'instances': instance.instances,
    };

_$InstanceCreateResponseImpl _$$InstanceCreateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$InstanceCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$InstanceCreateResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          persona: $checkedConvert('persona', (v) => v as String),
          memoryScope: $checkedConvert('memory_scope', (v) => v as String),
          skills: $checkedConvert('skills',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          budgetUsd:
              $checkedConvert('budget_usd', (v) => (v as num).toDouble()),
          owner: $checkedConvert('owner', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'memoryScope': 'memory_scope',
        'budgetUsd': 'budget_usd',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$$InstanceCreateResponseImplToJson(
        _$InstanceCreateResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'persona': instance.persona,
      'memory_scope': instance.memoryScope,
      'skills': instance.skills,
      'budget_usd': instance.budgetUsd,
      'owner': instance.owner,
      'created_at': instance.createdAt,
    };

_$InstanceResponseImpl _$$InstanceResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$InstanceResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$InstanceResponseImpl(
          instance: $checkedConvert(
              'instance',
              (v) =>
                  InstanceInfo.fromJson(Map<String, dynamic>.from(v as Map))),
        );
        return val;
      },
    );

Map<String, dynamic> _$$InstanceResponseImplToJson(
        _$InstanceResponseImpl instance) =>
    <String, dynamic>{
      'instance': instance.instance,
    };

_$HostingAppInfoImpl _$$HostingAppInfoImplFromJson(Map json) => $checkedCreate(
      r'_$HostingAppInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$HostingAppInfoImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          kind: $checkedConvert('kind', (v) => v as String),
          entry: $checkedConvert('entry', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          command: $checkedConvert('command', (v) => v as String),
          port: $checkedConvert('port', (v) => (v as num).toInt()),
          env:
              $checkedConvert('env', (v) => Map<String, String>.from(v as Map)),
          owner: $checkedConvert('owner', (v) => v as String),
          autostart: $checkedConvert('autostart', (v) => v as bool),
          tunnel: $checkedConvert('tunnel', (v) => v as bool),
          tunnelUrl: $checkedConvert('tunnel_url', (v) => v as String),
          pid: $checkedConvert('pid', (v) => (v as num).toInt()),
          logFile: $checkedConvert('log_file', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
          startedAt:
              $checkedConvert('started_at', (v) => (v as num?)?.toDouble()),
          alive: $checkedConvert('alive', (v) => v as bool),
          reachable: $checkedConvert('reachable', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'tunnelUrl': 'tunnel_url',
        'logFile': 'log_file',
        'createdAt': 'created_at',
        'startedAt': 'started_at'
      },
    );

Map<String, dynamic> _$$HostingAppInfoImplToJson(
    _$HostingAppInfoImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'kind': instance.kind,
    'entry': instance.entry,
    'path': instance.path,
    'command': instance.command,
    'port': instance.port,
    'env': instance.env,
    'owner': instance.owner,
    'autostart': instance.autostart,
    'tunnel': instance.tunnel,
    'tunnel_url': instance.tunnelUrl,
    'pid': instance.pid,
    'log_file': instance.logFile,
    'created_at': instance.createdAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('started_at', instance.startedAt);
  val['alive'] = instance.alive;
  val['reachable'] = instance.reachable;
  return val;
}

_$HostingAppsResponseImpl _$$HostingAppsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$HostingAppsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$HostingAppsResponseImpl(
          apps: $checkedConvert(
              'apps',
              (v) => (v as List<dynamic>)
                  .map((e) => HostingAppInfo.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$HostingAppsResponseImplToJson(
        _$HostingAppsResponseImpl instance) =>
    <String, dynamic>{
      'apps': instance.apps,
    };

_$HostingDeployResponseImpl _$$HostingDeployResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$HostingDeployResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$HostingDeployResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          kind: $checkedConvert('kind', (v) => v as String),
          entry: $checkedConvert('entry', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          command: $checkedConvert('command', (v) => v as String),
          port: $checkedConvert('port', (v) => (v as num).toInt()),
          env:
              $checkedConvert('env', (v) => Map<String, String>.from(v as Map)),
          owner: $checkedConvert('owner', (v) => v as String),
          autostart: $checkedConvert('autostart', (v) => v as bool),
          tunnel: $checkedConvert('tunnel', (v) => v as bool),
          tunnelUrl: $checkedConvert('tunnel_url', (v) => v as String?),
          pid: $checkedConvert('pid', (v) => (v as num?)?.toInt()),
          logFile: $checkedConvert('log_file', (v) => v as String?),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num?)?.toDouble()),
          startedAt:
              $checkedConvert('started_at', (v) => (v as num?)?.toDouble()),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'tunnelUrl': 'tunnel_url',
        'logFile': 'log_file',
        'createdAt': 'created_at',
        'startedAt': 'started_at'
      },
    );

Map<String, dynamic> _$$HostingDeployResponseImplToJson(
    _$HostingDeployResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'id': instance.id,
    'name': instance.name,
    'kind': instance.kind,
    'entry': instance.entry,
    'path': instance.path,
    'command': instance.command,
    'port': instance.port,
    'env': instance.env,
    'owner': instance.owner,
    'autostart': instance.autostart,
    'tunnel': instance.tunnel,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('tunnel_url', instance.tunnelUrl);
  writeNotNull('pid', instance.pid);
  writeNotNull('log_file', instance.logFile);
  writeNotNull('created_at', instance.createdAt);
  writeNotNull('started_at', instance.startedAt);
  writeNotNull('error', instance.error);
  return val;
}

_$HostingAppResponseImpl _$$HostingAppResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$HostingAppResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$HostingAppResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          app: $checkedConvert(
              'app',
              (v) =>
                  HostingAppInfo.fromJson(Map<String, dynamic>.from(v as Map))),
        );
        return val;
      },
    );

Map<String, dynamic> _$$HostingAppResponseImplToJson(
        _$HostingAppResponseImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'app': instance.app,
    };

_$HostingLogsResponseImpl _$$HostingLogsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$HostingLogsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$HostingLogsResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          name: $checkedConvert('name', (v) => v as String),
          lines: $checkedConvert('lines',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$HostingLogsResponseImplToJson(
        _$HostingLogsResponseImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'name': instance.name,
      'lines': instance.lines,
    };

_$RemoteConfigResponseImpl _$$RemoteConfigResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RemoteConfigResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RemoteConfigResponseImpl(
          host: $checkedConvert('host', (v) => v as String),
          port: $checkedConvert('port', (v) => (v as num).toInt()),
          user: $checkedConvert('user', (v) => v as String),
          hasPassword: $checkedConvert('has_password', (v) => v as bool),
          hasKey: $checkedConvert('has_key', (v) => v as bool),
          sshCmd: $checkedConvert('ssh_cmd', (v) => v as String?),
          scpCmd: $checkedConvert('scp_cmd', (v) => v as String?),
          paramiko: $checkedConvert('paramiko', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'hasPassword': 'has_password',
        'hasKey': 'has_key',
        'sshCmd': 'ssh_cmd',
        'scpCmd': 'scp_cmd'
      },
    );

Map<String, dynamic> _$$RemoteConfigResponseImplToJson(
    _$RemoteConfigResponseImpl instance) {
  final val = <String, dynamic>{
    'host': instance.host,
    'port': instance.port,
    'user': instance.user,
    'has_password': instance.hasPassword,
    'has_key': instance.hasKey,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('ssh_cmd', instance.sshCmd);
  writeNotNull('scp_cmd', instance.scpCmd);
  val['paramiko'] = instance.paramiko;
  return val;
}

_$RemoteDeployResponseImpl _$$RemoteDeployResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RemoteDeployResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RemoteDeployResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          app: $checkedConvert('app', (v) => v as String),
          image: $checkedConvert('image', (v) => v as String),
          dockerfileDir: $checkedConvert('dockerfile_dir', (v) => v as String?),
          ports: $checkedConvert(
              'ports',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e as String),
                  )),
          env: $checkedConvert(
              'env',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e as String),
                  )),
          pid: $checkedConvert('pid', (v) => (v as num?)?.toInt()),
          containerId: $checkedConvert('container_id', (v) => v as String?),
          output: $checkedConvert('output', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'dockerfileDir': 'dockerfile_dir',
        'containerId': 'container_id'
      },
    );

Map<String, dynamic> _$$RemoteDeployResponseImplToJson(
    _$RemoteDeployResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'app': instance.app,
    'image': instance.image,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('dockerfile_dir', instance.dockerfileDir);
  writeNotNull('ports', instance.ports);
  writeNotNull('env', instance.env);
  writeNotNull('pid', instance.pid);
  writeNotNull('container_id', instance.containerId);
  writeNotNull('output', instance.output);
  writeNotNull('error', instance.error);
  return val;
}

_$RemoteActionResponseImpl _$$RemoteActionResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RemoteActionResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RemoteActionResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          app: $checkedConvert('app', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          output: $checkedConvert('output', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$RemoteActionResponseImplToJson(
    _$RemoteActionResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'app': instance.app,
    'action': instance.action,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('output', instance.output);
  writeNotNull('error', instance.error);
  return val;
}

_$RemoteLogsResponseImpl _$$RemoteLogsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RemoteLogsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$RemoteLogsResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          app: $checkedConvert('app', (v) => v as String),
          logs: $checkedConvert('logs', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$RemoteLogsResponseImplToJson(
        _$RemoteLogsResponseImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'app': instance.app,
      'logs': instance.logs,
    };

_$CognitiveStatusResponseImpl _$$CognitiveStatusResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CognitiveStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CognitiveStatusResponseImpl(
          enabled: $checkedConvert('enabled', (v) => v as bool),
          running: $checkedConvert('running', (v) => v as bool),
          status: $checkedConvert('status', (v) => v as String),
          mode: $checkedConvert('mode', (v) => v as String),
          cycleCount:
              $checkedConvert('cycle_count', (v) => (v as num?)?.toInt()),
          lastCycleAt:
              $checkedConvert('last_cycle_at', (v) => (v as num?)?.toDouble()),
          currentStep: $checkedConvert('current_step', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'cycleCount': 'cycle_count',
        'lastCycleAt': 'last_cycle_at',
        'currentStep': 'current_step'
      },
    );

Map<String, dynamic> _$$CognitiveStatusResponseImplToJson(
    _$CognitiveStatusResponseImpl instance) {
  final val = <String, dynamic>{
    'enabled': instance.enabled,
    'running': instance.running,
    'status': instance.status,
    'mode': instance.mode,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cycle_count', instance.cycleCount);
  writeNotNull('last_cycle_at', instance.lastCycleAt);
  writeNotNull('current_step', instance.currentStep);
  return val;
}

_$CognitiveCycleResponseImpl _$$CognitiveCycleResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CognitiveCycleResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CognitiveCycleResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          cycleId: $checkedConvert('cycle_id', (v) => v as String),
          step: $checkedConvert('step', (v) => v as String),
          thinking: $checkedConvert('thinking', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String?),
          observation: $checkedConvert('observation', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'cycleId': 'cycle_id'},
    );

Map<String, dynamic> _$$CognitiveCycleResponseImplToJson(
    _$CognitiveCycleResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'cycle_id': instance.cycleId,
    'step': instance.step,
    'thinking': instance.thinking,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('action', instance.action);
  writeNotNull('observation', instance.observation);
  writeNotNull('error', instance.error);
  return val;
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apiServiceHash() => r'd76dea2a3d4afd840c19952cd59fe889ce36151d';

/// See also [apiService].
@ProviderFor(apiService)
final apiServiceProvider = AutoDisposeProvider<ApiService>.internal(
  apiService,
  name: r'apiServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiServiceRef = AutoDisposeProviderRef<ApiService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
