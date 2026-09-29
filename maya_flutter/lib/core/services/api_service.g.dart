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
              'state', (v) => Map<String, dynamic>.from(v as Map)),
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
