// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
