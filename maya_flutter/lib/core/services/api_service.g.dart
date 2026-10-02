// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KernelCheckpointsResponseWrapper _$KernelCheckpointsResponseWrapperFromJson(
        Map json) =>
    $checkedCreate(
      'KernelCheckpointsResponseWrapper',
      json,
      ($checkedConvert) {
        final val = KernelCheckpointsResponseWrapper(
          checkpoints: $checkedConvert(
              'checkpoints', (v) => _checkpointsFromJson(v as List)),
        );
        return val;
      },
    );

Map<String, dynamic> _$KernelCheckpointsResponseWrapperToJson(
        KernelCheckpointsResponseWrapper instance) =>
    <String, dynamic>{
      'checkpoints': _checkpointsToJson(instance.checkpoints),
    };

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

SynthesisItem _$SynthesisItemFromJson(Map json) => $checkedCreate(
      'SynthesisItem',
      json,
      ($checkedConvert) {
        final val = SynthesisItem(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          completedAt: $checkedConvert('completed_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          result: $checkedConvert(
              'result',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'completedAt': 'completed_at'
      },
    );

Map<String, dynamic> _$SynthesisItemToJson(SynthesisItem instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'description': instance.description,
    'status': instance.status,
    'created_at': instance.createdAt.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('completed_at', instance.completedAt?.toIso8601String());
  writeNotNull('result', instance.result);
  return val;
}

SocietyAgent _$SocietyAgentFromJson(Map json) => $checkedCreate(
      'SocietyAgent',
      json,
      ($checkedConvert) {
        final val = SocietyAgent(
          id: $checkedConvert('id', (v) => v as String),
          role: $checkedConvert('role', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          capabilities: $checkedConvert(
              'capabilities',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          lastActive: $checkedConvert('last_active',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'lastActive': 'last_active'
      },
    );

Map<String, dynamic> _$SocietyAgentToJson(SocietyAgent instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'role': instance.role,
    'status': instance.status,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('capabilities', instance.capabilities);
  val['created_at'] = instance.createdAt.toIso8601String();
  writeNotNull('last_active', instance.lastActive?.toIso8601String());
  return val;
}

BlackboardEntry _$BlackboardEntryFromJson(Map json) => $checkedCreate(
      'BlackboardEntry',
      json,
      ($checkedConvert) {
        final val = BlackboardEntry(
          key: $checkedConvert('key', (v) => v as String),
          value: $checkedConvert('value', (v) => v),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          ttl: $checkedConvert('ttl', (v) => (v as num?)?.toInt()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          agentId: $checkedConvert('agent_id', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at', 'agentId': 'agent_id'},
    );

Map<String, dynamic> _$BlackboardEntryToJson(BlackboardEntry instance) {
  final val = <String, dynamic>{
    'key': instance.key,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('value', instance.value);
  val['tags'] = instance.tags;
  writeNotNull('ttl', instance.ttl);
  val['created_at'] = instance.createdAt.toIso8601String();
  val['agent_id'] = instance.agentId;
  return val;
}

ProceduralSkill _$ProceduralSkillFromJson(Map json) => $checkedCreate(
      'ProceduralSkill',
      json,
      ($checkedConvert) {
        final val = ProceduralSkill(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          verified: $checkedConvert('verified', (v) => v as bool),
          confidence:
              $checkedConvert('confidence', (v) => (v as num).toDouble()),
          usageCount: $checkedConvert('usage_count', (v) => (v as num).toInt()),
          successRate:
              $checkedConvert('success_rate', (v) => (v as num).toDouble()),
          applicableGoals: $checkedConvert('applicable_goals',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'usageCount': 'usage_count',
        'successRate': 'success_rate',
        'applicableGoals': 'applicable_goals',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$ProceduralSkillToJson(ProceduralSkill instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'description': instance.description,
    'verified': instance.verified,
    'confidence': instance.confidence,
    'usage_count': instance.usageCount,
    'success_rate': instance.successRate,
    'applicable_goals': instance.applicableGoals,
    'created_at': instance.createdAt.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('updated_at', instance.updatedAt?.toIso8601String());
  return val;
}

ModelInfo _$ModelInfoFromJson(Map json) => $checkedCreate(
      'ModelInfo',
      json,
      ($checkedConvert) {
        final val = ModelInfo(
          id: $checkedConvert('id', (v) => v as String),
          provider: $checkedConvert('provider', (v) => v as String),
          taskType: $checkedConvert('task_type', (v) => v as String),
          available: $checkedConvert('available', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'taskType': 'task_type'},
    );

Map<String, dynamic> _$ModelInfoToJson(ModelInfo instance) => <String, dynamic>{
      'id': instance.id,
      'provider': instance.provider,
      'task_type': instance.taskType,
      'available': instance.available,
    };

CheckpointInfo _$CheckpointInfoFromJson(Map json) => $checkedCreate(
      'CheckpointInfo',
      json,
      ($checkedConvert) {
        final val = CheckpointInfo(
          id: $checkedConvert('id', (v) => v as String),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
          cycleCount: $checkedConvert('cycle_count', (v) => (v as num).toInt()),
          description: $checkedConvert('description', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'cycleCount': 'cycle_count'},
    );

Map<String, dynamic> _$CheckpointInfoToJson(CheckpointInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'cycle_count': instance.cycleCount,
      'description': instance.description,
    };

AuditEntry _$AuditEntryFromJson(Map json) => $checkedCreate(
      'AuditEntry',
      json,
      ($checkedConvert) {
        final val = AuditEntry(
          eventType: $checkedConvert('event_type', (v) => v as String),
          details: $checkedConvert('details', (v) => v as String),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
          cycleId: $checkedConvert('cycle_id', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'eventType': 'event_type', 'cycleId': 'cycle_id'},
    );

Map<String, dynamic> _$AuditEntryToJson(AuditEntry instance) =>
    <String, dynamic>{
      'event_type': instance.eventType,
      'details': instance.details,
      'timestamp': instance.timestamp.toIso8601String(),
      'cycle_id': instance.cycleId,
    };

EpisodicMemory _$EpisodicMemoryFromJson(Map json) => $checkedCreate(
      'EpisodicMemory',
      json,
      ($checkedConvert) {
        final val = EpisodicMemory(
          id: $checkedConvert('id', (v) => v as String),
          goal: $checkedConvert('goal', (v) => v as String),
          outcome: $checkedConvert('outcome', (v) => v as String),
          confidence:
              $checkedConvert('confidence', (v) => (v as num).toDouble()),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$EpisodicMemoryToJson(EpisodicMemory instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'goal': instance.goal,
    'outcome': instance.outcome,
    'confidence': instance.confidence,
    'timestamp': instance.timestamp.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  return val;
}

SchemaInfo _$SchemaInfoFromJson(Map json) => $checkedCreate(
      'SchemaInfo',
      json,
      ($checkedConvert) {
        final val = SchemaInfo(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          relevance: $checkedConvert('relevance', (v) => (v as num).toDouble()),
          parameters: $checkedConvert(
              'parameters',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$SchemaInfoToJson(SchemaInfo instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'description': instance.description,
    'relevance': instance.relevance,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('parameters', instance.parameters);
  return val;
}

KnowledgeItem _$KnowledgeItemFromJson(Map json) => $checkedCreate(
      'KnowledgeItem',
      json,
      ($checkedConvert) {
        final val = KnowledgeItem(
          id: $checkedConvert('id', (v) => v as String),
          proposition: $checkedConvert('proposition', (v) => v as String),
          confidence:
              $checkedConvert('confidence', (v) => (v as num).toDouble()),
          source: $checkedConvert('source', (v) => v as String),
          domain: $checkedConvert('domain', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          evidence: $checkedConvert('evidence',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at', 'updatedAt': 'updated_at'},
    );

Map<String, dynamic> _$KnowledgeItemToJson(KnowledgeItem instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'proposition': instance.proposition,
    'confidence': instance.confidence,
    'source': instance.source,
    'domain': instance.domain,
    'created_at': instance.createdAt.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('updated_at', instance.updatedAt?.toIso8601String());
  val['evidence'] = instance.evidence;
  return val;
}

VectorSearchResult _$VectorSearchResultFromJson(Map json) => $checkedCreate(
      'VectorSearchResult',
      json,
      ($checkedConvert) {
        final val = VectorSearchResult(
          id: $checkedConvert('id', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          score: $checkedConvert('score', (v) => (v as num).toDouble()),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$VectorSearchResultToJson(VectorSearchResult instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'content': instance.content,
    'score': instance.score,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  return val;
}

SelfImproveGap _$SelfImproveGapFromJson(Map json) => $checkedCreate(
      'SelfImproveGap',
      json,
      ($checkedConvert) {
        final val = SelfImproveGap(
          taskType: $checkedConvert('task_type', (v) => v as String),
          attempts: $checkedConvert('attempts', (v) => (v as num).toInt()),
          successRate:
              $checkedConvert('success_rate', (v) => (v as num).toDouble()),
          skillsCovering:
              $checkedConvert('skills_covering', (v) => (v as num).toInt()),
          priority: $checkedConvert('priority', (v) => (v as num).toDouble()),
          suggestion: $checkedConvert('suggestion', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'taskType': 'task_type',
        'successRate': 'success_rate',
        'skillsCovering': 'skills_covering'
      },
    );

Map<String, dynamic> _$SelfImproveGapToJson(SelfImproveGap instance) =>
    <String, dynamic>{
      'task_type': instance.taskType,
      'attempts': instance.attempts,
      'success_rate': instance.successRate,
      'skills_covering': instance.skillsCovering,
      'priority': instance.priority,
      'suggestion': instance.suggestion,
    };

SelfImproveProposal _$SelfImproveProposalFromJson(Map json) => $checkedCreate(
      'SelfImproveProposal',
      json,
      ($checkedConvert) {
        final val = SelfImproveProposal(
          id: $checkedConvert('id', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          gap: $checkedConvert('gap', (v) => v as String?),
          goalHint: $checkedConvert('goal_hint', (v) => v as String?),
          codeDraft: $checkedConvert('code_draft', (v) => v as String?),
          estimatedImpact:
              $checkedConvert('estimated_impact', (v) => v as String?),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          decidedAt: $checkedConvert('decided_at', (v) => v as String?),
          executedAt: $checkedConvert('executed_at', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'goalHint': 'goal_hint',
        'codeDraft': 'code_draft',
        'estimatedImpact': 'estimated_impact',
        'createdAt': 'created_at',
        'decidedAt': 'decided_at',
        'executedAt': 'executed_at'
      },
    );

Map<String, dynamic> _$SelfImproveProposalToJson(SelfImproveProposal instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'type': instance.type,
    'description': instance.description,
    'status': instance.status,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('gap', instance.gap);
  writeNotNull('goal_hint', instance.goalHint);
  writeNotNull('code_draft', instance.codeDraft);
  writeNotNull('estimated_impact', instance.estimatedImpact);
  val['created_at'] = instance.createdAt;
  writeNotNull('decided_at', instance.decidedAt);
  writeNotNull('executed_at', instance.executedAt);
  return val;
}

Belief _$BeliefFromJson(Map json) => $checkedCreate(
      'Belief',
      json,
      ($checkedConvert) {
        final val = Belief(
          id: $checkedConvert('id', (v) => v as String),
          proposition: $checkedConvert('proposition', (v) => v as String),
          confidence:
              $checkedConvert('confidence', (v) => (v as num).toDouble()),
          domain: $checkedConvert('domain', (v) => v as String),
          source: $checkedConvert('source', (v) => v as String),
          evidence: $checkedConvert('evidence', (v) => v as String?),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at', 'updatedAt': 'updated_at'},
    );

Map<String, dynamic> _$BeliefToJson(Belief instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'proposition': instance.proposition,
    'confidence': instance.confidence,
    'domain': instance.domain,
    'source': instance.source,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('evidence', instance.evidence);
  val['created_at'] = instance.createdAt.toIso8601String();
  val['updated_at'] = instance.updatedAt.toIso8601String();
  return val;
}

ScoutScanRecord _$ScoutScanRecordFromJson(Map json) => $checkedCreate(
      'ScoutScanRecord',
      json,
      ($checkedConvert) {
        final val = ScoutScanRecord(
          scanId: $checkedConvert('scan_id', (v) => v as String),
          signals: $checkedConvert('signals', (v) => (v as num).toInt()),
          opportunities:
              $checkedConvert('opportunities', (v) => (v as num).toInt()),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
          status: $checkedConvert('status', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'scanId': 'scan_id'},
    );

Map<String, dynamic> _$ScoutScanRecordToJson(ScoutScanRecord instance) =>
    <String, dynamic>{
      'scan_id': instance.scanId,
      'signals': instance.signals,
      'opportunities': instance.opportunities,
      'timestamp': instance.timestamp.toIso8601String(),
      'status': instance.status,
    };

ScoutSignal _$ScoutSignalFromJson(Map json) => $checkedCreate(
      'ScoutSignal',
      json,
      ($checkedConvert) {
        final val = ScoutSignal(
          id: $checkedConvert('id', (v) => v as String),
          source: $checkedConvert('source', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          summary: $checkedConvert('summary', (v) => v as String),
          score: $checkedConvert('score', (v) => (v as num).toDouble()),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ScoutSignalToJson(ScoutSignal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'title': instance.title,
      'summary': instance.summary,
      'score': instance.score,
      'timestamp': instance.timestamp.toIso8601String(),
    };

ScoutOpportunity _$ScoutOpportunityFromJson(Map json) => $checkedCreate(
      'ScoutOpportunity',
      json,
      ($checkedConvert) {
        final val = ScoutOpportunity(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          source: $checkedConvert('source', (v) => v as String),
          score: $checkedConvert('score', (v) => (v as num).toDouble()),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$ScoutOpportunityToJson(ScoutOpportunity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'source': instance.source,
      'score': instance.score,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };

StrategistReviewRecord _$StrategistReviewRecordFromJson(Map json) =>
    $checkedCreate(
      'StrategistReviewRecord',
      json,
      ($checkedConvert) {
        final val = StrategistReviewRecord(
          reviewId: $checkedConvert('review_id', (v) => v as String),
          opportunitiesReviewed: $checkedConvert(
              'opportunities_reviewed', (v) => (v as num).toInt()),
          plansCreated:
              $checkedConvert('plans_created', (v) => (v as num).toInt()),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'reviewId': 'review_id',
        'opportunitiesReviewed': 'opportunities_reviewed',
        'plansCreated': 'plans_created'
      },
    );

Map<String, dynamic> _$StrategistReviewRecordToJson(
        StrategistReviewRecord instance) =>
    <String, dynamic>{
      'review_id': instance.reviewId,
      'opportunities_reviewed': instance.opportunitiesReviewed,
      'plans_created': instance.plansCreated,
      'timestamp': instance.timestamp.toIso8601String(),
    };

StrategistPlan _$StrategistPlanFromJson(Map json) => $checkedCreate(
      'StrategistPlan',
      json,
      ($checkedConvert) {
        final val = StrategistPlan(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          opportunityId: $checkedConvert('opportunity_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'opportunityId': 'opportunity_id',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$StrategistPlanToJson(StrategistPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'opportunity_id': instance.opportunityId,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };

StrategistRankedOpportunity _$StrategistRankedOpportunityFromJson(Map json) =>
    $checkedCreate(
      'StrategistRankedOpportunity',
      json,
      ($checkedConvert) {
        final val = StrategistRankedOpportunity(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          score: $checkedConvert('score', (v) => (v as num).toDouble()),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$StrategistRankedOpportunityToJson(
        StrategistRankedOpportunity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'score': instance.score,
      'reason': instance.reason,
    };

BuiltinAgentProfile _$BuiltinAgentProfileFromJson(Map json) => $checkedCreate(
      'BuiltinAgentProfile',
      json,
      ($checkedConvert) {
        final val = BuiltinAgentProfile(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          icon: $checkedConvert('icon', (v) => v as String),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$BuiltinAgentProfileToJson(
        BuiltinAgentProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'tags': instance.tags,
    };

BuilderProject _$BuilderProjectFromJson(Map json) => $checkedCreate(
      'BuilderProject',
      json,
      ($checkedConvert) {
        final val = BuilderProject(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          planId: $checkedConvert('plan_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'planId': 'plan_id',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$BuilderProjectToJson(BuilderProject instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'description': instance.description,
    'plan_id': instance.planId,
    'status': instance.status,
    'created_at': instance.createdAt.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('updated_at', instance.updatedAt?.toIso8601String());
  return val;
}

BuilderStep _$BuilderStepFromJson(Map json) => $checkedCreate(
      'BuilderStep',
      json,
      ($checkedConvert) {
        final val = BuilderStep(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          order: $checkedConvert('order', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$BuilderStepToJson(BuilderStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'order': instance.order,
    };

LauncherLaunch _$LauncherLaunchFromJson(Map json) => $checkedCreate(
      'LauncherLaunch',
      json,
      ($checkedConvert) {
        final val = LauncherLaunch(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          projectId: $checkedConvert('project_id', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          launchedAt: $checkedConvert('launched_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'projectId': 'project_id',
        'createdAt': 'created_at',
        'launchedAt': 'launched_at'
      },
    );

Map<String, dynamic> _$LauncherLaunchToJson(LauncherLaunch instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'status': instance.status,
    'project_id': instance.projectId,
    'created_at': instance.createdAt.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('launched_at', instance.launchedAt?.toIso8601String());
  return val;
}

LauncherContent _$LauncherContentFromJson(Map json) => $checkedCreate(
      'LauncherContent',
      json,
      ($checkedConvert) {
        final val = LauncherContent(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$LauncherContentToJson(LauncherContent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'status': instance.status,
      'content': instance.content,
    };

GrowthProposal _$GrowthProposalFromJson(Map json) => $checkedCreate(
      'GrowthProposal',
      json,
      ($checkedConvert) {
        final val = GrowthProposal(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          projectId: $checkedConvert('project_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          estimatedImpact:
              $checkedConvert('estimated_impact', (v) => (v as num).toDouble()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'projectId': 'project_id',
        'estimatedImpact': 'estimated_impact',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$GrowthProposalToJson(GrowthProposal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'project_id': instance.projectId,
      'status': instance.status,
      'estimated_impact': instance.estimatedImpact,
      'created_at': instance.createdAt.toIso8601String(),
    };

GrowthMetric _$GrowthMetricFromJson(Map json) => $checkedCreate(
      'GrowthMetric',
      json,
      ($checkedConvert) {
        final val = GrowthMetric(
          projectId: $checkedConvert('project_id', (v) => v as String),
          metricName: $checkedConvert('metric_name', (v) => v as String),
          value: $checkedConvert('value', (v) => (v as num).toDouble()),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'projectId': 'project_id',
        'metricName': 'metric_name'
      },
    );

Map<String, dynamic> _$GrowthMetricToJson(GrowthMetric instance) =>
    <String, dynamic>{
      'project_id': instance.projectId,
      'metric_name': instance.metricName,
      'value': instance.value,
      'timestamp': instance.timestamp.toIso8601String(),
    };

GrowthRecommendation _$GrowthRecommendationFromJson(Map json) => $checkedCreate(
      'GrowthRecommendation',
      json,
      ($checkedConvert) {
        final val = GrowthRecommendation(
          projectId: $checkedConvert('project_id', (v) => v as String),
          recommendation: $checkedConvert('recommendation', (v) => v as String),
          priority: $checkedConvert('priority', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'projectId': 'project_id'},
    );

Map<String, dynamic> _$GrowthRecommendationToJson(
        GrowthRecommendation instance) =>
    <String, dynamic>{
      'project_id': instance.projectId,
      'recommendation': instance.recommendation,
      'priority': instance.priority,
    };

GrowthAction _$GrowthActionFromJson(Map json) => $checkedCreate(
      'GrowthAction',
      json,
      ($checkedConvert) {
        final val = GrowthAction(
          id: $checkedConvert('id', (v) => v as String),
          projectId: $checkedConvert('project_id', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
          userId: $checkedConvert('user_id', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'projectId': 'project_id', 'userId': 'user_id'},
    );

Map<String, dynamic> _$GrowthActionToJson(GrowthAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'action': instance.action,
      'timestamp': instance.timestamp.toIso8601String(),
      'user_id': instance.userId,
    };

NotifApproval _$NotifApprovalFromJson(Map json) => $checkedCreate(
      'NotifApproval',
      json,
      ($checkedConvert) {
        final val = NotifApproval(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          channel: $checkedConvert('channel', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$NotifApprovalToJson(NotifApproval instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'channel': instance.channel,
      'created_at': instance.createdAt.toIso8601String(),
    };

NotifTemplate _$NotifTemplateFromJson(Map json) => $checkedCreate(
      'NotifTemplate',
      json,
      ($checkedConvert) {
        final val = NotifTemplate(
          name: $checkedConvert('name', (v) => v as String),
          subject: $checkedConvert('subject', (v) => v as String),
          body: $checkedConvert('body', (v) => v as String),
          channel: $checkedConvert('channel', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$NotifTemplateToJson(NotifTemplate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'subject': instance.subject,
      'body': instance.body,
      'channel': instance.channel,
    };

ExtTask _$ExtTaskFromJson(Map json) => $checkedCreate(
      'ExtTask',
      json,
      ($checkedConvert) {
        final val = ExtTask(
          id: $checkedConvert('id', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$ExtTaskToJson(ExtTask instance) => <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };

ProactiveJob _$ProactiveJobFromJson(Map json) => $checkedCreate(
      'ProactiveJob',
      json,
      ($checkedConvert) {
        final val = ProactiveJob(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          cron: $checkedConvert('cron', (v) => v as String),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$ProactiveJobToJson(ProactiveJob instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'cron': instance.cron,
      'enabled': instance.enabled,
      'created_at': instance.createdAt.toIso8601String(),
    };

ExtMemFact _$ExtMemFactFromJson(Map json) => $checkedCreate(
      'ExtMemFact',
      json,
      ($checkedConvert) {
        final val = ExtMemFact(
          id: $checkedConvert('id', (v) => v as String),
          fact: $checkedConvert('fact', (v) => v as String),
          source: $checkedConvert('source', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$ExtMemFactToJson(ExtMemFact instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fact': instance.fact,
      'source': instance.source,
      'created_at': instance.createdAt.toIso8601String(),
    };

ExtInterruption _$ExtInterruptionFromJson(Map json) => $checkedCreate(
      'ExtInterruption',
      json,
      ($checkedConvert) {
        final val = ExtInterruption(
          id: $checkedConvert('id', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ExtInterruptionToJson(ExtInterruption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reason': instance.reason,
      'timestamp': instance.timestamp.toIso8601String(),
    };

Capability _$CapabilityFromJson(Map json) => $checkedCreate(
      'Capability',
      json,
      ($checkedConvert) {
        final val = Capability(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          verified: $checkedConvert('verified', (v) => v as bool),
          usageCount: $checkedConvert('usage_count', (v) => (v as num).toInt()),
          successRate:
              $checkedConvert('success_rate', (v) => (v as num).toDouble()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'usageCount': 'usage_count',
        'successRate': 'success_rate',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$CapabilityToJson(Capability instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'description': instance.description,
    'verified': instance.verified,
    'usage_count': instance.usageCount,
    'success_rate': instance.successRate,
    'created_at': instance.createdAt.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('updated_at', instance.updatedAt?.toIso8601String());
  return val;
}

Webhook _$WebhookFromJson(Map json) => $checkedCreate(
      'Webhook',
      json,
      ($checkedConvert) {
        final val = Webhook(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String),
          events: $checkedConvert('events',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          active: $checkedConvert('active', (v) => v as bool),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$WebhookToJson(Webhook instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'events': instance.events,
      'active': instance.active,
      'created_at': instance.createdAt.toIso8601String(),
    };

Doc _$DocFromJson(Map json) => $checkedCreate(
      'Doc',
      json,
      ($checkedConvert) {
        final val = Doc(
          name: $checkedConvert('name', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          category: $checkedConvert('category', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$DocToJson(Doc instance) => <String, dynamic>{
      'name': instance.name,
      'title': instance.title,
      'category': instance.category,
    };

Project _$ProjectFromJson(Map json) => $checkedCreate(
      'Project',
      json,
      ($checkedConvert) {
        final val = Project(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };

Schedule _$ScheduleFromJson(Map json) => $checkedCreate(
      'Schedule',
      json,
      ($checkedConvert) {
        final val = Schedule(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          cron: $checkedConvert('cron', (v) => v as String),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$ScheduleToJson(Schedule instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'cron': instance.cron,
      'enabled': instance.enabled,
      'created_at': instance.createdAt.toIso8601String(),
    };

AnalyticsDailyPoint _$AnalyticsDailyPointFromJson(Map json) => $checkedCreate(
      'AnalyticsDailyPoint',
      json,
      ($checkedConvert) {
        final val = AnalyticsDailyPoint(
          date: $checkedConvert('date', (v) => v as String),
          requests: $checkedConvert('requests', (v) => (v as num).toInt()),
          errors: $checkedConvert('errors', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$AnalyticsDailyPointToJson(
        AnalyticsDailyPoint instance) =>
    <String, dynamic>{
      'date': instance.date,
      'requests': instance.requests,
      'errors': instance.errors,
    };

AnalyticsProviderStat _$AnalyticsProviderStatFromJson(Map json) =>
    $checkedCreate(
      'AnalyticsProviderStat',
      json,
      ($checkedConvert) {
        final val = AnalyticsProviderStat(
          provider: $checkedConvert('provider', (v) => v as String),
          requests: $checkedConvert('requests', (v) => (v as num).toInt()),
          errors: $checkedConvert('errors', (v) => (v as num).toInt()),
          avgLatency:
              $checkedConvert('avg_latency', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'avgLatency': 'avg_latency'},
    );

Map<String, dynamic> _$AnalyticsProviderStatToJson(
        AnalyticsProviderStat instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'requests': instance.requests,
      'errors': instance.errors,
      'avg_latency': instance.avgLatency,
    };

AnalyticsToolStat _$AnalyticsToolStatFromJson(Map json) => $checkedCreate(
      'AnalyticsToolStat',
      json,
      ($checkedConvert) {
        final val = AnalyticsToolStat(
          tool: $checkedConvert('tool', (v) => v as String),
          calls: $checkedConvert('calls', (v) => (v as num).toInt()),
          errors: $checkedConvert('errors', (v) => (v as num).toInt()),
          avgLatency:
              $checkedConvert('avg_latency', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'avgLatency': 'avg_latency'},
    );

Map<String, dynamic> _$AnalyticsToolStatToJson(AnalyticsToolStat instance) =>
    <String, dynamic>{
      'tool': instance.tool,
      'calls': instance.calls,
      'errors': instance.errors,
      'avg_latency': instance.avgLatency,
    };

LogEntry _$LogEntryFromJson(Map json) => $checkedCreate(
      'LogEntry',
      json,
      ($checkedConvert) {
        final val = LogEntry(
          id: $checkedConvert('id', (v) => v as String),
          level: $checkedConvert('level', (v) => v as String),
          message: $checkedConvert('message', (v) => v as String),
          provider: $checkedConvert('provider', (v) => v as String),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$LogEntryToJson(LogEntry instance) => <String, dynamic>{
      'id': instance.id,
      'level': instance.level,
      'message': instance.message,
      'provider': instance.provider,
      'timestamp': instance.timestamp.toIso8601String(),
    };

Plugin _$PluginFromJson(Map json) => $checkedCreate(
      'Plugin',
      json,
      ($checkedConvert) {
        final val = Plugin(
          name: $checkedConvert('name', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          installedAt: $checkedConvert(
              'installed_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'installedAt': 'installed_at'},
    );

Map<String, dynamic> _$PluginToJson(Plugin instance) => <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'description': instance.description,
      'enabled': instance.enabled,
      'installed_at': instance.installedAt.toIso8601String(),
    };

WorkingMemoryItem _$WorkingMemoryItemFromJson(Map json) => $checkedCreate(
      'WorkingMemoryItem',
      json,
      ($checkedConvert) {
        final val = WorkingMemoryItem(
          id: $checkedConvert('id', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          attention: $checkedConvert('attention', (v) => (v as num).toDouble()),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          bindings: $checkedConvert(
              'bindings',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$WorkingMemoryItemToJson(WorkingMemoryItem instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'content': instance.content,
    'type': instance.type,
    'attention': instance.attention,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  writeNotNull('bindings', instance.bindings);
  val['created_at'] = instance.createdAt.toIso8601String();
  return val;
}

WMItem _$WMItemFromJson(Map json) => $checkedCreate(
      'WMItem',
      json,
      ($checkedConvert) {
        final val = WMItem(
          id: $checkedConvert('id', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          chunkId: $checkedConvert('chunk_id', (v) => v as String?),
          attention: $checkedConvert('attention', (v) => (v as num).toDouble()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'chunkId': 'chunk_id', 'createdAt': 'created_at'},
    );

Map<String, dynamic> _$WMItemToJson(WMItem instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'content': instance.content,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('chunk_id', instance.chunkId);
  val['attention'] = instance.attention;
  val['created_at'] = instance.createdAt.toIso8601String();
  return val;
}

MissionInfo _$MissionInfoFromJson(Map json) => $checkedCreate(
      'MissionInfo',
      json,
      ($checkedConvert) {
        final val = MissionInfo(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          missionType: $checkedConvert('mission_type', (v) => v as String),
          active: $checkedConvert('active', (v) => v as bool),
          selfGen: $checkedConvert('self_gen', (v) => v as bool),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'missionType': 'mission_type',
        'selfGen': 'self_gen',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$MissionInfoToJson(MissionInfo instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'description': instance.description,
    'mission_type': instance.missionType,
    'active': instance.active,
    'self_gen': instance.selfGen,
    'status': instance.status,
    'created_at': instance.createdAt.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('updated_at', instance.updatedAt?.toIso8601String());
  return val;
}

BusinessReportSummary _$BusinessReportSummaryFromJson(Map json) =>
    $checkedCreate(
      'BusinessReportSummary',
      json,
      ($checkedConvert) {
        final val = BusinessReportSummary(
          id: $checkedConvert('id', (v) => v as String),
          missionId: $checkedConvert('mission_id', (v) => v as String),
          objectiveId: $checkedConvert('objective_id', (v) => v as String),
          objectiveDesc: $checkedConvert('objective_desc', (v) => v as String),
          combinedSummary:
              $checkedConvert('combined_summary', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'missionId': 'mission_id',
        'objectiveId': 'objective_id',
        'objectiveDesc': 'objective_desc',
        'combinedSummary': 'combined_summary',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$BusinessReportSummaryToJson(
        BusinessReportSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mission_id': instance.missionId,
      'objective_id': instance.objectiveId,
      'objective_desc': instance.objectiveDesc,
      'combined_summary': instance.combinedSummary,
      'created_at': instance.createdAt,
    };

PublishHistoryItem _$PublishHistoryItemFromJson(Map json) => $checkedCreate(
      'PublishHistoryItem',
      json,
      ($checkedConvert) {
        final val = PublishHistoryItem(
          id: $checkedConvert('id', (v) => v as String),
          siteName: $checkedConvert('site_name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          approver: $checkedConvert('approver', (v) => v as String),
          resultUrl: $checkedConvert('result_url', (v) => v as String),
          riskLevel: $checkedConvert('risk_level', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
          decidedAt:
              $checkedConvert('decided_at', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'siteName': 'site_name',
        'resultUrl': 'result_url',
        'riskLevel': 'risk_level',
        'createdAt': 'created_at',
        'decidedAt': 'decided_at'
      },
    );

Map<String, dynamic> _$PublishHistoryItemToJson(PublishHistoryItem instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'site_name': instance.siteName,
    'description': instance.description,
    'action': instance.action,
    'approver': instance.approver,
    'result_url': instance.resultUrl,
    'risk_level': instance.riskLevel,
    'created_at': instance.createdAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('decided_at', instance.decidedAt);
  return val;
}

ApprovalItem _$ApprovalItemFromJson(Map json) => $checkedCreate(
      'ApprovalItem',
      json,
      ($checkedConvert) {
        final val = ApprovalItem(
          id: $checkedConvert('id', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String),
          riskLevel: $checkedConvert('risk_level', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          taskId: $checkedConvert('task_id', (v) => v as String),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          decidedAt: $checkedConvert('decided_at', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'riskLevel': 'risk_level',
        'taskId': 'task_id',
        'createdAt': 'created_at',
        'decidedAt': 'decided_at'
      },
    );

Map<String, dynamic> _$ApprovalItemToJson(ApprovalItem instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'action': instance.action,
    'reason': instance.reason,
    'risk_level': instance.riskLevel,
    'status': instance.status,
    'task_id': instance.taskId,
    'created_at': instance.createdAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('decided_at', instance.decidedAt);
  return val;
}

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

_$KernelCheckpointsResponseImpl _$$KernelCheckpointsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$KernelCheckpointsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KernelCheckpointsResponseImpl(
          checkpoints: $checkedConvert(
              'checkpoints', (v) => _checkpointsFromJson(v as List)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$KernelCheckpointsResponseImplToJson(
        _$KernelCheckpointsResponseImpl instance) =>
    <String, dynamic>{
      'checkpoints': _checkpointsToJson(instance.checkpoints),
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

_$SynthesizeListResponseImpl _$$SynthesizeListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SynthesizeListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SynthesizeListResponseImpl(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => SynthesisItem.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SynthesizeListResponseImplToJson(
        _$SynthesizeListResponseImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
    };

_$SocietyStatusResponseImpl _$$SocietyStatusResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SocietyStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SocietyStatusResponseImpl(
          totalAgents:
              $checkedConvert('total_agents', (v) => (v as num).toInt()),
          activeAgents:
              $checkedConvert('active_agents', (v) => (v as num).toInt()),
          tasksQueued:
              $checkedConvert('tasks_queued', (v) => (v as num).toInt()),
          tasksRunning:
              $checkedConvert('tasks_running', (v) => (v as num).toInt()),
          tasksCompleted:
              $checkedConvert('tasks_completed', (v) => (v as num).toInt()),
          tasksFailed:
              $checkedConvert('tasks_failed', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalAgents': 'total_agents',
        'activeAgents': 'active_agents',
        'tasksQueued': 'tasks_queued',
        'tasksRunning': 'tasks_running',
        'tasksCompleted': 'tasks_completed',
        'tasksFailed': 'tasks_failed'
      },
    );

Map<String, dynamic> _$$SocietyStatusResponseImplToJson(
        _$SocietyStatusResponseImpl instance) =>
    <String, dynamic>{
      'total_agents': instance.totalAgents,
      'active_agents': instance.activeAgents,
      'tasks_queued': instance.tasksQueued,
      'tasks_running': instance.tasksRunning,
      'tasks_completed': instance.tasksCompleted,
      'tasks_failed': instance.tasksFailed,
    };

_$SocietySpawnResponseImpl _$$SocietySpawnResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SocietySpawnResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SocietySpawnResponseImpl(
          agentId: $checkedConvert('agent_id', (v) => v as String),
          role: $checkedConvert('role', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'agentId': 'agent_id'},
    );

Map<String, dynamic> _$$SocietySpawnResponseImplToJson(
        _$SocietySpawnResponseImpl instance) =>
    <String, dynamic>{
      'agent_id': instance.agentId,
      'role': instance.role,
      'status': instance.status,
    };

_$SocietyAgentsResponseImpl _$$SocietyAgentsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SocietyAgentsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SocietyAgentsResponseImpl(
          agents: $checkedConvert(
              'agents',
              (v) => (v as List<dynamic>)
                  .map((e) => SocietyAgent.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SocietyAgentsResponseImplToJson(
        _$SocietyAgentsResponseImpl instance) =>
    <String, dynamic>{
      'agents': instance.agents,
    };

_$SocietyTaskResponseImpl _$$SocietyTaskResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SocietyTaskResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SocietyTaskResponseImpl(
          taskId: $checkedConvert('task_id', (v) => v as String),
          agentId: $checkedConvert('agent_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          task: $checkedConvert(
              'task', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {'taskId': 'task_id', 'agentId': 'agent_id'},
    );

Map<String, dynamic> _$$SocietyTaskResponseImplToJson(
        _$SocietyTaskResponseImpl instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'agent_id': instance.agentId,
      'status': instance.status,
      'task': instance.task,
    };

_$SocietyTenderResponseImpl _$$SocietyTenderResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SocietyTenderResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SocietyTenderResponseImpl(
          taskId: $checkedConvert('task_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          taskSpec: $checkedConvert(
              'task_spec', (v) => Map<String, dynamic>.from(v as Map)),
          deadline: $checkedConvert('deadline', (v) => v as String),
          eligibleRoles: $checkedConvert('eligible_roles',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'taskId': 'task_id',
        'taskSpec': 'task_spec',
        'eligibleRoles': 'eligible_roles'
      },
    );

Map<String, dynamic> _$$SocietyTenderResponseImplToJson(
        _$SocietyTenderResponseImpl instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'status': instance.status,
      'task_spec': instance.taskSpec,
      'deadline': instance.deadline,
      'eligible_roles': instance.eligibleRoles,
    };

_$SocietyBidResponseImpl _$$SocietyBidResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SocietyBidResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SocietyBidResponseImpl(
          taskId: $checkedConvert('task_id', (v) => v as String),
          agentId: $checkedConvert('agent_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          score: $checkedConvert('score', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'taskId': 'task_id', 'agentId': 'agent_id'},
    );

Map<String, dynamic> _$$SocietyBidResponseImplToJson(
    _$SocietyBidResponseImpl instance) {
  final val = <String, dynamic>{
    'task_id': instance.taskId,
    'agent_id': instance.agentId,
    'status': instance.status,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('score', instance.score);
  return val;
}

_$SocietyAwardResponseImpl _$$SocietyAwardResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SocietyAwardResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SocietyAwardResponseImpl(
          taskId: $checkedConvert('task_id', (v) => v as String),
          agentId: $checkedConvert('agent_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'taskId': 'task_id', 'agentId': 'agent_id'},
    );

Map<String, dynamic> _$$SocietyAwardResponseImplToJson(
        _$SocietyAwardResponseImpl instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'agent_id': instance.agentId,
      'status': instance.status,
    };

_$SocietyBlackboardWriteResponseImpl
    _$$SocietyBlackboardWriteResponseImplFromJson(Map json) => $checkedCreate(
          r'_$SocietyBlackboardWriteResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$SocietyBlackboardWriteResponseImpl(
              success: $checkedConvert('success', (v) => v as bool),
              key: $checkedConvert('key', (v) => v as String),
            );
            return val;
          },
        );

Map<String, dynamic> _$$SocietyBlackboardWriteResponseImplToJson(
        _$SocietyBlackboardWriteResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'key': instance.key,
    };

_$SocietyBlackboardReadResponseImpl
    _$$SocietyBlackboardReadResponseImplFromJson(Map json) => $checkedCreate(
          r'_$SocietyBlackboardReadResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$SocietyBlackboardReadResponseImpl(
              found: $checkedConvert('found', (v) => v as bool),
              key: $checkedConvert('key', (v) => v as String),
              value: $checkedConvert('value', (v) => v),
              tags: $checkedConvert('tags',
                  (v) => (v as List<dynamic>).map((e) => e as String).toList()),
              ttl: $checkedConvert('ttl', (v) => (v as num?)?.toInt()),
            );
            return val;
          },
        );

Map<String, dynamic> _$$SocietyBlackboardReadResponseImplToJson(
    _$SocietyBlackboardReadResponseImpl instance) {
  final val = <String, dynamic>{
    'found': instance.found,
    'key': instance.key,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('value', instance.value);
  val['tags'] = instance.tags;
  writeNotNull('ttl', instance.ttl);
  return val;
}

_$SocietyBlackboardQueryResponseImpl
    _$$SocietyBlackboardQueryResponseImplFromJson(Map json) => $checkedCreate(
          r'_$SocietyBlackboardQueryResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$SocietyBlackboardQueryResponseImpl(
              entries: $checkedConvert(
                  'entries',
                  (v) => (v as List<dynamic>)
                      .map((e) => BlackboardEntry.fromJson(
                          Map<String, dynamic>.from(e as Map)))
                      .toList()),
            );
            return val;
          },
        );

Map<String, dynamic> _$$SocietyBlackboardQueryResponseImplToJson(
        _$SocietyBlackboardQueryResponseImpl instance) =>
    <String, dynamic>{
      'entries': instance.entries,
    };

_$ProceduralListResponseImpl _$$ProceduralListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ProceduralListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProceduralListResponseImpl(
          skills: $checkedConvert(
              'skills',
              (v) => (v as List<dynamic>)
                  .map((e) => ProceduralSkill.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProceduralListResponseImplToJson(
        _$ProceduralListResponseImpl instance) =>
    <String, dynamic>{
      'skills': instance.skills,
      'total': instance.total,
    };

_$ProceduralApplicableResponseImpl _$$ProceduralApplicableResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProceduralApplicableResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProceduralApplicableResponseImpl(
          skills: $checkedConvert(
              'skills',
              (v) => (v as List<dynamic>)
                  .map((e) => ProceduralSkill.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          goal: $checkedConvert('goal', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProceduralApplicableResponseImplToJson(
        _$ProceduralApplicableResponseImpl instance) =>
    <String, dynamic>{
      'skills': instance.skills,
      'goal': instance.goal,
    };

_$ProceduralUseResponseImpl _$$ProceduralUseResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ProceduralUseResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProceduralUseResponseImpl(
          skillId: $checkedConvert('skill_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
          newConfidence:
              $checkedConvert('new_confidence', (v) => (v as num).toDouble()),
          newUsageCount:
              $checkedConvert('new_usage_count', (v) => (v as num).toInt()),
          reward: $checkedConvert('reward', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'skillId': 'skill_id',
        'newConfidence': 'new_confidence',
        'newUsageCount': 'new_usage_count'
      },
    );

Map<String, dynamic> _$$ProceduralUseResponseImplToJson(
    _$ProceduralUseResponseImpl instance) {
  final val = <String, dynamic>{
    'skill_id': instance.skillId,
    'success': instance.success,
    'new_confidence': instance.newConfidence,
    'new_usage_count': instance.newUsageCount,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('reward', instance.reward);
  return val;
}

_$ProceduralStatsResponseImpl _$$ProceduralStatsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProceduralStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProceduralStatsResponseImpl(
          totalSkills:
              $checkedConvert('total_skills', (v) => (v as num).toInt()),
          verifiedSkills:
              $checkedConvert('verified_skills', (v) => (v as num).toInt()),
          avgConfidence:
              $checkedConvert('avg_confidence', (v) => (v as num).toDouble()),
          avgSuccessRate:
              $checkedConvert('avg_success_rate', (v) => (v as num).toDouble()),
          totalUsages:
              $checkedConvert('total_usages', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalSkills': 'total_skills',
        'verifiedSkills': 'verified_skills',
        'avgConfidence': 'avg_confidence',
        'avgSuccessRate': 'avg_success_rate',
        'totalUsages': 'total_usages'
      },
    );

Map<String, dynamic> _$$ProceduralStatsResponseImplToJson(
        _$ProceduralStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_skills': instance.totalSkills,
      'verified_skills': instance.verifiedSkills,
      'avg_confidence': instance.avgConfidence,
      'avg_success_rate': instance.avgSuccessRate,
      'total_usages': instance.totalUsages,
    };

_$ProceduralSearchResponseImpl _$$ProceduralSearchResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProceduralSearchResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProceduralSearchResponseImpl(
          skills: $checkedConvert(
              'skills',
              (v) => (v as List<dynamic>)
                  .map((e) => ProceduralSkill.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          query: $checkedConvert('query', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProceduralSearchResponseImplToJson(
        _$ProceduralSearchResponseImpl instance) =>
    <String, dynamic>{
      'skills': instance.skills,
      'query': instance.query,
    };

_$ProceduralComposeResponseImpl _$$ProceduralComposeResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProceduralComposeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProceduralComposeResponseImpl(
          skillId: $checkedConvert('skill_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          verified: $checkedConvert('verified', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'skillId': 'skill_id'},
    );

Map<String, dynamic> _$$ProceduralComposeResponseImplToJson(
        _$ProceduralComposeResponseImpl instance) =>
    <String, dynamic>{
      'skill_id': instance.skillId,
      'name': instance.name,
      'description': instance.description,
      'verified': instance.verified,
    };

_$CoreStatusResponseImpl _$$CoreStatusResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreStatusResponseImpl(
          initialized: $checkedConvert('initialized', (v) => v as bool),
          loopRunning: $checkedConvert('loop_running', (v) => v as bool),
          loopInterval:
              $checkedConvert('loop_interval', (v) => (v as num).toDouble()),
          cycleCount: $checkedConvert('cycle_count', (v) => (v as num).toInt()),
          activeModel: $checkedConvert('active_model', (v) => v as String),
          identity: $checkedConvert(
              'identity', (v) => Map<String, dynamic>.from(v as Map)),
          selfState: $checkedConvert(
              'self_state', (v) => Map<String, dynamic>.from(v as Map)),
          kernelStatus: $checkedConvert(
              'kernel_status', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {
        'loopRunning': 'loop_running',
        'loopInterval': 'loop_interval',
        'cycleCount': 'cycle_count',
        'activeModel': 'active_model',
        'selfState': 'self_state',
        'kernelStatus': 'kernel_status'
      },
    );

Map<String, dynamic> _$$CoreStatusResponseImplToJson(
        _$CoreStatusResponseImpl instance) =>
    <String, dynamic>{
      'initialized': instance.initialized,
      'loop_running': instance.loopRunning,
      'loop_interval': instance.loopInterval,
      'cycle_count': instance.cycleCount,
      'active_model': instance.activeModel,
      'identity': instance.identity,
      'self_state': instance.selfState,
      'kernel_status': instance.kernelStatus,
    };

_$CoreInitializeResponseImpl _$$CoreInitializeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreInitializeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreInitializeResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CoreInitializeResponseImplToJson(
        _$CoreInitializeResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };

_$CoreLoopResponseImpl _$$CoreLoopResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreLoopResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreLoopResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          interval: $checkedConvert('interval', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CoreLoopResponseImplToJson(
    _$CoreLoopResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('interval', instance.interval);
  return val;
}

_$CoreMissionResponseImpl _$$CoreMissionResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreMissionResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreMissionResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          missionId: $checkedConvert('mission_id', (v) => v as String),
          result: $checkedConvert('result', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'missionId': 'mission_id'},
    );

Map<String, dynamic> _$$CoreMissionResponseImplToJson(
    _$CoreMissionResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
    'mission_id': instance.missionId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('result', instance.result);
  return val;
}

_$CoreGoalResponseImpl _$$CoreGoalResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreGoalResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreGoalResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          goalId: $checkedConvert('goal_id', (v) => v as String),
          stepsExecuted:
              $checkedConvert('steps_executed', (v) => (v as num).toInt()),
          result: $checkedConvert('result', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'goalId': 'goal_id',
        'stepsExecuted': 'steps_executed'
      },
    );

Map<String, dynamic> _$$CoreGoalResponseImplToJson(
    _$CoreGoalResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
    'goal_id': instance.goalId,
    'steps_executed': instance.stepsExecuted,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('result', instance.result);
  return val;
}

_$CoreIdentityResponseImpl _$$CoreIdentityResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreIdentityResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreIdentityResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          purpose: $checkedConvert('purpose', (v) => v as String),
          values: $checkedConvert('values',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );

Map<String, dynamic> _$$CoreIdentityResponseImplToJson(
        _$CoreIdentityResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'purpose': instance.purpose,
      'values': instance.values,
      'created_at': instance.createdAt.toIso8601String(),
      'version': instance.version,
    };

_$CoreModelsResponseImpl _$$CoreModelsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreModelsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreModelsResponseImpl(
          activeModel: $checkedConvert('active_model', (v) => v as String),
          fallbackChain: $checkedConvert('fallback_chain',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          availableModels: $checkedConvert(
              'available_models',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ModelInfo.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'activeModel': 'active_model',
        'fallbackChain': 'fallback_chain',
        'availableModels': 'available_models'
      },
    );

Map<String, dynamic> _$$CoreModelsResponseImplToJson(
        _$CoreModelsResponseImpl instance) =>
    <String, dynamic>{
      'active_model': instance.activeModel,
      'fallback_chain': instance.fallbackChain,
      'available_models': instance.availableModels,
    };

_$CoreSwitchModelResponseImpl _$$CoreSwitchModelResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CoreSwitchModelResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreSwitchModelResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          activeModel: $checkedConvert('active_model', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'activeModel': 'active_model'},
    );

Map<String, dynamic> _$$CoreSwitchModelResponseImplToJson(
        _$CoreSwitchModelResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'active_model': instance.activeModel,
    };

_$CoreInvokeModelResponseImpl _$$CoreInvokeModelResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CoreInvokeModelResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreInvokeModelResponseImpl(
          modelId: $checkedConvert('model_id', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          tokensUsed: $checkedConvert('tokens_used', (v) => (v as num).toInt()),
          latencyMs:
              $checkedConvert('latency_ms', (v) => (v as num).toDouble()),
          cached: $checkedConvert('cached', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'modelId': 'model_id',
        'tokensUsed': 'tokens_used',
        'latencyMs': 'latency_ms'
      },
    );

Map<String, dynamic> _$$CoreInvokeModelResponseImplToJson(
    _$CoreInvokeModelResponseImpl instance) {
  final val = <String, dynamic>{
    'model_id': instance.modelId,
    'content': instance.content,
    'tokens_used': instance.tokensUsed,
    'latency_ms': instance.latencyMs,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cached', instance.cached);
  return val;
}

_$CoreCheckpointResponseImpl _$$CoreCheckpointResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreCheckpointResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreCheckpointResponseImpl(
          checkpointId: $checkedConvert('checkpoint_id', (v) => v as String),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'checkpointId': 'checkpoint_id'},
    );

Map<String, dynamic> _$$CoreCheckpointResponseImplToJson(
        _$CoreCheckpointResponseImpl instance) =>
    <String, dynamic>{
      'checkpoint_id': instance.checkpointId,
      'timestamp': instance.timestamp.toIso8601String(),
    };

_$CoreRestoreCheckpointResponseImpl
    _$$CoreRestoreCheckpointResponseImplFromJson(Map json) => $checkedCreate(
          r'_$CoreRestoreCheckpointResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$CoreRestoreCheckpointResponseImpl(
              success: $checkedConvert('success', (v) => v as bool),
              checkpointId:
                  $checkedConvert('checkpoint_id', (v) => v as String),
            );
            return val;
          },
          fieldKeyMap: const {'checkpointId': 'checkpoint_id'},
        );

Map<String, dynamic> _$$CoreRestoreCheckpointResponseImplToJson(
        _$CoreRestoreCheckpointResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'checkpoint_id': instance.checkpointId,
    };

_$CoreCheckpointsResponseImpl _$$CoreCheckpointsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CoreCheckpointsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreCheckpointsResponseImpl(
          checkpoints: $checkedConvert(
              'checkpoints',
              (v) => (v as List<dynamic>)
                  .map((e) => CheckpointInfo.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CoreCheckpointsResponseImplToJson(
        _$CoreCheckpointsResponseImpl instance) =>
    <String, dynamic>{
      'checkpoints': instance.checkpoints,
    };

_$CoreAuditResponseImpl _$$CoreAuditResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreAuditResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreAuditResponseImpl(
          audit: $checkedConvert(
              'audit',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      AuditEntry.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CoreAuditResponseImplToJson(
        _$CoreAuditResponseImpl instance) =>
    <String, dynamic>{
      'audit': instance.audit,
    };

_$CoreShutdownResponseImpl _$$CoreShutdownResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CoreShutdownResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CoreShutdownResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CoreShutdownResponseImplToJson(
        _$CoreShutdownResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };

_$UnifiedLoopStatusResponseImpl _$$UnifiedLoopStatusResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$UnifiedLoopStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$UnifiedLoopStatusResponseImpl(
          loopState: $checkedConvert('loop_state', (v) => v as String),
          currentPhase: $checkedConvert('current_phase', (v) => v as String),
          cyclesCompleted:
              $checkedConvert('cycles_completed', (v) => (v as num).toInt()),
          missionsCompleted:
              $checkedConvert('missions_completed', (v) => (v as num).toInt()),
          skillsAcquired:
              $checkedConvert('skills_acquired', (v) => (v as num).toInt()),
          errorCount: $checkedConvert('error_count', (v) => (v as num).toInt()),
          lastError: $checkedConvert('last_error', (v) => v as String?),
          activeGoalId: $checkedConvert('active_goal_id', (v) => v as String?),
          activePlanId: $checkedConvert('active_plan_id', (v) => v as String?),
          currentStepId:
              $checkedConvert('current_step_id', (v) => v as String?),
          activeModelId:
              $checkedConvert('active_model_id', (v) => v as String?),
          availableModels: $checkedConvert('available_models',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          resourceUsage: $checkedConvert(
              'resource_usage',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          uptime: $checkedConvert('uptime', (v) => (v as num).toDouble()),
          instanceId: $checkedConvert('instance_id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String?),
          version: $checkedConvert('version', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'loopState': 'loop_state',
        'currentPhase': 'current_phase',
        'cyclesCompleted': 'cycles_completed',
        'missionsCompleted': 'missions_completed',
        'skillsAcquired': 'skills_acquired',
        'errorCount': 'error_count',
        'lastError': 'last_error',
        'activeGoalId': 'active_goal_id',
        'activePlanId': 'active_plan_id',
        'currentStepId': 'current_step_id',
        'activeModelId': 'active_model_id',
        'availableModels': 'available_models',
        'resourceUsage': 'resource_usage',
        'instanceId': 'instance_id'
      },
    );

Map<String, dynamic> _$$UnifiedLoopStatusResponseImplToJson(
    _$UnifiedLoopStatusResponseImpl instance) {
  final val = <String, dynamic>{
    'loop_state': instance.loopState,
    'current_phase': instance.currentPhase,
    'cycles_completed': instance.cyclesCompleted,
    'missions_completed': instance.missionsCompleted,
    'skills_acquired': instance.skillsAcquired,
    'error_count': instance.errorCount,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('last_error', instance.lastError);
  writeNotNull('active_goal_id', instance.activeGoalId);
  writeNotNull('active_plan_id', instance.activePlanId);
  writeNotNull('current_step_id', instance.currentStepId);
  writeNotNull('active_model_id', instance.activeModelId);
  writeNotNull('available_models', instance.availableModels);
  writeNotNull('resource_usage', instance.resourceUsage);
  val['uptime'] = instance.uptime;
  writeNotNull('instance_id', instance.instanceId);
  writeNotNull('name', instance.name);
  writeNotNull('version', instance.version);
  return val;
}

_$UnifiedLoopHistoryResponseImpl _$$UnifiedLoopHistoryResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$UnifiedLoopHistoryResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$UnifiedLoopHistoryResponseImpl(
          entries: $checkedConvert(
              'entries',
              (v) => (v as List<dynamic>)
                  .map((e) => UnifiedLoopHistoryEntry.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$UnifiedLoopHistoryResponseImplToJson(
        _$UnifiedLoopHistoryResponseImpl instance) =>
    <String, dynamic>{
      'entries': instance.entries,
    };

_$UnifiedLoopHistoryEntryImpl _$$UnifiedLoopHistoryEntryImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$UnifiedLoopHistoryEntryImpl',
      json,
      ($checkedConvert) {
        final val = _$UnifiedLoopHistoryEntryImpl(
          id: $checkedConvert('id', (v) => v as String),
          cycleId: $checkedConvert('cycle_id', (v) => (v as num).toInt()),
          phase: $checkedConvert('phase', (v) => v as String),
          timestamp: $checkedConvert('timestamp', (v) => (v as num).toDouble()),
          details: $checkedConvert('details', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
          durationMs: $checkedConvert('duration_ms', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'cycleId': 'cycle_id', 'durationMs': 'duration_ms'},
    );

Map<String, dynamic> _$$UnifiedLoopHistoryEntryImplToJson(
        _$UnifiedLoopHistoryEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cycle_id': instance.cycleId,
      'phase': instance.phase,
      'timestamp': instance.timestamp,
      'details': instance.details,
      'success': instance.success,
      'duration_ms': instance.durationMs,
    };

_$UnifiedLoopControlResponseImpl _$$UnifiedLoopControlResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$UnifiedLoopControlResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$UnifiedLoopControlResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
          interval: $checkedConvert('interval', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$UnifiedLoopControlResponseImplToJson(
    _$UnifiedLoopControlResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  writeNotNull('interval', instance.interval);
  return val;
}

_$GoalsListResponseImpl _$$GoalsListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GoalsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GoalsListResponseImpl(
          goals: $checkedConvert(
              'goals',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      GoalSummary.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GoalsListResponseImplToJson(
        _$GoalsListResponseImpl instance) =>
    <String, dynamic>{
      'goals': instance.goals,
    };

_$GoalSummaryImpl _$$GoalSummaryImplFromJson(Map json) => $checkedCreate(
      r'_$GoalSummaryImpl',
      json,
      ($checkedConvert) {
        final val = _$GoalSummaryImpl(
          id: $checkedConvert('id', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          priority: $checkedConvert('priority', (v) => (v as num).toDouble()),
          progress: $checkedConvert('progress', (v) => (v as num).toDouble()),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
          updatedAt:
              $checkedConvert('updated_at', (v) => (v as num).toDouble()),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at', 'updatedAt': 'updated_at'},
    );

Map<String, dynamic> _$$GoalSummaryImplToJson(_$GoalSummaryImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'description': instance.description,
    'status': instance.status,
    'priority': instance.priority,
    'progress': instance.progress,
    'created_at': instance.createdAt,
    'updated_at': instance.updatedAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  return val;
}

_$GoalDetailResponseImpl _$$GoalDetailResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GoalDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GoalDetailResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          priority: $checkedConvert('priority', (v) => (v as num).toDouble()),
          progress: $checkedConvert('progress', (v) => (v as num).toDouble()),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
          updatedAt:
              $checkedConvert('updated_at', (v) => (v as num).toDouble()),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          parentId: $checkedConvert('parent_id', (v) => v as String?),
          successCriteria:
              $checkedConvert('success_criteria', (v) => v as String?),
          constraints: $checkedConvert('constraints',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          requiredCapabilities: $checkedConvert('required_capabilities',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          subgoals: $checkedConvert(
              'subgoals',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      GoalSummary.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
        'parentId': 'parent_id',
        'successCriteria': 'success_criteria',
        'requiredCapabilities': 'required_capabilities'
      },
    );

Map<String, dynamic> _$$GoalDetailResponseImplToJson(
    _$GoalDetailResponseImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'description': instance.description,
    'status': instance.status,
    'priority': instance.priority,
    'progress': instance.progress,
    'created_at': instance.createdAt,
    'updated_at': instance.updatedAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  writeNotNull('parent_id', instance.parentId);
  writeNotNull('success_criteria', instance.successCriteria);
  writeNotNull('constraints', instance.constraints);
  writeNotNull('required_capabilities', instance.requiredCapabilities);
  writeNotNull('subgoals', instance.subgoals);
  return val;
}

_$GoalResumeResponseImpl _$$GoalResumeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GoalResumeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GoalResumeResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          goalId: $checkedConvert('goal_id', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
          action: $checkedConvert('action', (v) => v as String?),
          detail: $checkedConvert('detail', (v) => v as String?),
          resumed: $checkedConvert('resumed', (v) => v as bool?),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {'goalId': 'goal_id'},
    );

Map<String, dynamic> _$$GoalResumeResponseImplToJson(
    _$GoalResumeResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('goal_id', instance.goalId);
  writeNotNull('error', instance.error);
  writeNotNull('action', instance.action);
  writeNotNull('detail', instance.detail);
  writeNotNull('resumed', instance.resumed);
  writeNotNull('metadata', instance.metadata);
  return val;
}

_$GoalCreateResponseImpl _$$GoalCreateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GoalCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GoalCreateResponseImpl(
          goalId: $checkedConvert('goal_id', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          priority: $checkedConvert('priority', (v) => (v as num).toDouble()),
          progress: $checkedConvert('progress', (v) => (v as num).toDouble()),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
          updatedAt:
              $checkedConvert('updated_at', (v) => (v as num).toDouble()),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {
        'goalId': 'goal_id',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$$GoalCreateResponseImplToJson(
    _$GoalCreateResponseImpl instance) {
  final val = <String, dynamic>{
    'goal_id': instance.goalId,
    'description': instance.description,
    'status': instance.status,
    'priority': instance.priority,
    'progress': instance.progress,
    'created_at': instance.createdAt,
    'updated_at': instance.updatedAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  return val;
}

_$GoalUpdateResponseImpl _$$GoalUpdateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GoalUpdateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GoalUpdateResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          priority: $checkedConvert('priority', (v) => (v as num).toDouble()),
          progress: $checkedConvert('progress', (v) => (v as num).toDouble()),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
          updatedAt:
              $checkedConvert('updated_at', (v) => (v as num).toDouble()),
          metadata: $checkedConvert(
              'metadata',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at', 'updatedAt': 'updated_at'},
    );

Map<String, dynamic> _$$GoalUpdateResponseImplToJson(
    _$GoalUpdateResponseImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'description': instance.description,
    'status': instance.status,
    'priority': instance.priority,
    'progress': instance.progress,
    'created_at': instance.createdAt,
    'updated_at': instance.updatedAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  return val;
}

_$GoalDecomposeResponseImpl _$$GoalDecomposeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GoalDecomposeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GoalDecomposeResponseImpl(
          subgoals: $checkedConvert(
              'subgoals',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      GoalSummary.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GoalDecomposeResponseImplToJson(
        _$GoalDecomposeResponseImpl instance) =>
    <String, dynamic>{
      'subgoals': instance.subgoals,
    };

_$EpisodicListResponseImpl _$$EpisodicListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$EpisodicListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$EpisodicListResponseImpl(
          episodes: $checkedConvert(
              'episodes',
              (v) => (v as List<dynamic>)
                  .map((e) => EpisodicMemory.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$EpisodicListResponseImplToJson(
        _$EpisodicListResponseImpl instance) =>
    <String, dynamic>{
      'episodes': instance.episodes,
    };

_$EpisodicSearchResponseImpl _$$EpisodicSearchResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$EpisodicSearchResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$EpisodicSearchResponseImpl(
          episodes: $checkedConvert(
              'episodes',
              (v) => (v as List<dynamic>)
                  .map((e) => EpisodicMemory.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$EpisodicSearchResponseImplToJson(
        _$EpisodicSearchResponseImpl instance) =>
    <String, dynamic>{
      'episodes': instance.episodes,
    };

_$EpisodicStatsResponseImpl _$$EpisodicStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$EpisodicStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$EpisodicStatsResponseImpl(
          totalEpisodes:
              $checkedConvert('total_episodes', (v) => (v as num).toInt()),
          successfulEpisodes:
              $checkedConvert('successful_episodes', (v) => (v as num).toInt()),
          failedEpisodes:
              $checkedConvert('failed_episodes', (v) => (v as num).toInt()),
          avgConfidence:
              $checkedConvert('avg_confidence', (v) => (v as num).toDouble()),
          outcomesByType: $checkedConvert(
              'outcomes_by_type', (v) => Map<String, int>.from(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalEpisodes': 'total_episodes',
        'successfulEpisodes': 'successful_episodes',
        'failedEpisodes': 'failed_episodes',
        'avgConfidence': 'avg_confidence',
        'outcomesByType': 'outcomes_by_type'
      },
    );

Map<String, dynamic> _$$EpisodicStatsResponseImplToJson(
        _$EpisodicStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_episodes': instance.totalEpisodes,
      'successful_episodes': instance.successfulEpisodes,
      'failed_episodes': instance.failedEpisodes,
      'avg_confidence': instance.avgConfidence,
      'outcomes_by_type': instance.outcomesByType,
    };

_$HippocampusSchemaQueryResponseImpl
    _$$HippocampusSchemaQueryResponseImplFromJson(Map json) => $checkedCreate(
          r'_$HippocampusSchemaQueryResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$HippocampusSchemaQueryResponseImpl(
              schemas: $checkedConvert(
                  'schemas',
                  (v) => (v as List<dynamic>)
                      .map((e) => SchemaInfo.fromJson(
                          Map<String, dynamic>.from(e as Map)))
                      .toList()),
            );
            return val;
          },
        );

Map<String, dynamic> _$$HippocampusSchemaQueryResponseImplToJson(
        _$HippocampusSchemaQueryResponseImpl instance) =>
    <String, dynamic>{
      'schemas': instance.schemas,
    };

_$HippocampusSchemaApplyResponseImpl
    _$$HippocampusSchemaApplyResponseImplFromJson(Map json) => $checkedCreate(
          r'_$HippocampusSchemaApplyResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$HippocampusSchemaApplyResponseImpl(
              success: $checkedConvert('success', (v) => v as bool),
              schemaId: $checkedConvert('schema_id', (v) => v as String),
              result: $checkedConvert('result', (v) => v as String?),
            );
            return val;
          },
          fieldKeyMap: const {'schemaId': 'schema_id'},
        );

Map<String, dynamic> _$$HippocampusSchemaApplyResponseImplToJson(
    _$HippocampusSchemaApplyResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
    'schema_id': instance.schemaId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('result', instance.result);
  return val;
}

_$KnowledgeQueryResponseImpl _$$KnowledgeQueryResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$KnowledgeQueryResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KnowledgeQueryResponseImpl(
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => KnowledgeItem.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$KnowledgeQueryResponseImplToJson(
        _$KnowledgeQueryResponseImpl instance) =>
    <String, dynamic>{
      'results': instance.results,
    };

_$KnowledgeStatsResponseImpl _$$KnowledgeStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$KnowledgeStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KnowledgeStatsResponseImpl(
          totalBeliefs:
              $checkedConvert('total_beliefs', (v) => (v as num).toInt()),
          domains: $checkedConvert('domains', (v) => (v as num).toInt()),
          avgConfidence:
              $checkedConvert('avg_confidence', (v) => (v as num).toDouble()),
          retrievalEngine:
              $checkedConvert('retrieval_engine', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalBeliefs': 'total_beliefs',
        'avgConfidence': 'avg_confidence',
        'retrievalEngine': 'retrieval_engine'
      },
    );

Map<String, dynamic> _$$KnowledgeStatsResponseImplToJson(
        _$KnowledgeStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_beliefs': instance.totalBeliefs,
      'domains': instance.domains,
      'avg_confidence': instance.avgConfidence,
      'retrieval_engine': instance.retrievalEngine,
    };

_$KnowledgeLearnResponseImpl _$$KnowledgeLearnResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$KnowledgeLearnResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$KnowledgeLearnResponseImpl(
          beliefId: $checkedConvert('belief_id', (v) => v as String),
          confidence:
              $checkedConvert('confidence', (v) => (v as num).toDouble()),
          action: $checkedConvert('action', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'beliefId': 'belief_id'},
    );

Map<String, dynamic> _$$KnowledgeLearnResponseImplToJson(
        _$KnowledgeLearnResponseImpl instance) =>
    <String, dynamic>{
      'belief_id': instance.beliefId,
      'confidence': instance.confidence,
      'action': instance.action,
    };

_$BeliefAddResponseImpl _$$BeliefAddResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BeliefAddResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BeliefAddResponseImpl(
          beliefId: $checkedConvert('belief_id', (v) => v as String),
          proposition: $checkedConvert('proposition', (v) => v as String),
          confidence:
              $checkedConvert('confidence', (v) => (v as num).toDouble()),
          domain: $checkedConvert('domain', (v) => v as String),
          source: $checkedConvert('source', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'beliefId': 'belief_id'},
    );

Map<String, dynamic> _$$BeliefAddResponseImplToJson(
        _$BeliefAddResponseImpl instance) =>
    <String, dynamic>{
      'belief_id': instance.beliefId,
      'proposition': instance.proposition,
      'confidence': instance.confidence,
      'domain': instance.domain,
      'source': instance.source,
    };

_$BeliefsQueryResponseImpl _$$BeliefsQueryResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BeliefsQueryResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BeliefsQueryResponseImpl(
          beliefs: $checkedConvert(
              'beliefs',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Belief.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BeliefsQueryResponseImplToJson(
        _$BeliefsQueryResponseImpl instance) =>
    <String, dynamic>{
      'beliefs': instance.beliefs,
    };

_$VectorSearchResponseImpl _$$VectorSearchResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$VectorSearchResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$VectorSearchResponseImpl(
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => VectorSearchResult.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$VectorSearchResponseImplToJson(
        _$VectorSearchResponseImpl instance) =>
    <String, dynamic>{
      'results': instance.results,
    };

_$VectorSearchStatsResponseImpl _$$VectorSearchStatsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$VectorSearchStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$VectorSearchStatsResponseImpl(
          totalVectors:
              $checkedConvert('total_vectors', (v) => (v as num).toInt()),
          retrievalEngine:
              $checkedConvert('retrieval_engine', (v) => v as String),
          dimensions: $checkedConvert('dimensions', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalVectors': 'total_vectors',
        'retrievalEngine': 'retrieval_engine'
      },
    );

Map<String, dynamic> _$$VectorSearchStatsResponseImplToJson(
        _$VectorSearchStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_vectors': instance.totalVectors,
      'retrieval_engine': instance.retrievalEngine,
      'dimensions': instance.dimensions,
    };

_$AutoResumeResponseImpl _$$AutoResumeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AutoResumeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AutoResumeResponseImpl(
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => AutoResumeResult.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AutoResumeResponseImplToJson(
        _$AutoResumeResponseImpl instance) =>
    <String, dynamic>{
      'results': instance.results,
    };

_$AutoResumeResultImpl _$$AutoResumeResultImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AutoResumeResultImpl',
      json,
      ($checkedConvert) {
        final val = _$AutoResumeResultImpl(
          goalId: $checkedConvert('goal_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
          autoExecuted: $checkedConvert('auto_executed', (v) => v as bool),
          priorStatus: $checkedConvert('prior_status', (v) => v as String),
          error: $checkedConvert('error', (v) => v as String?),
          description: $checkedConvert('description', (v) => v as String?),
          action: $checkedConvert('action', (v) => v as String?),
          detail: $checkedConvert('detail', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'goalId': 'goal_id',
        'autoExecuted': 'auto_executed',
        'priorStatus': 'prior_status'
      },
    );

Map<String, dynamic> _$$AutoResumeResultImplToJson(
    _$AutoResumeResultImpl instance) {
  final val = <String, dynamic>{
    'goal_id': instance.goalId,
    'success': instance.success,
    'auto_executed': instance.autoExecuted,
    'prior_status': instance.priorStatus,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('error', instance.error);
  writeNotNull('description', instance.description);
  writeNotNull('action', instance.action);
  writeNotNull('detail', instance.detail);
  return val;
}

_$McpStatusResponseImpl _$$McpStatusResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$McpStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$McpStatusResponseImpl(
          enabled: $checkedConvert('enabled', (v) => v as bool),
          servers: $checkedConvert(
              'servers',
              (v) => (v as List<dynamic>)
                  .map((e) => McpServerStatus.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$McpStatusResponseImplToJson(
        _$McpStatusResponseImpl instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'servers': instance.servers,
    };

_$McpServerStatusImpl _$$McpServerStatusImplFromJson(Map json) =>
    $checkedCreate(
      r'_$McpServerStatusImpl',
      json,
      ($checkedConvert) {
        final val = _$McpServerStatusImpl(
          name: $checkedConvert('name', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          toolCount: $checkedConvert('tool_count', (v) => (v as num).toInt()),
          tools: $checkedConvert('tools',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'toolCount': 'tool_count'},
    );

Map<String, dynamic> _$$McpServerStatusImplToJson(
    _$McpServerStatusImpl instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'status': instance.status,
    'tool_count': instance.toolCount,
    'tools': instance.tools,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('error', instance.error);
  return val;
}

_$McpConnectResponseImpl _$$McpConnectResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$McpConnectResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$McpConnectResponseImpl(
          server: $checkedConvert('server', (v) => v as String),
          toolsRegistered:
              $checkedConvert('tools_registered', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'toolsRegistered': 'tools_registered'},
    );

Map<String, dynamic> _$$McpConnectResponseImplToJson(
        _$McpConnectResponseImpl instance) =>
    <String, dynamic>{
      'server': instance.server,
      'tools_registered': instance.toolsRegistered,
    };

_$McpDisconnectResponseImpl _$$McpDisconnectResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$McpDisconnectResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$McpDisconnectResponseImpl(
          disconnected: $checkedConvert('disconnected', (v) => v as bool),
          toolsRemoved:
              $checkedConvert('tools_removed', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'toolsRemoved': 'tools_removed'},
    );

Map<String, dynamic> _$$McpDisconnectResponseImplToJson(
        _$McpDisconnectResponseImpl instance) =>
    <String, dynamic>{
      'disconnected': instance.disconnected,
      'tools_removed': instance.toolsRemoved,
    };

_$McpCallResponseImpl _$$McpCallResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$McpCallResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$McpCallResponseImpl(
          result: $checkedConvert('result', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$$McpCallResponseImplToJson(
    _$McpCallResponseImpl instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('result', instance.result);
  return val;
}

_$SelfProfileResponseImpl _$$SelfProfileResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SelfProfileResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfProfileResponseImpl(
          totalOutcomes:
              $checkedConvert('total_outcomes', (v) => (v as num).toInt()),
          overallSuccessRate: $checkedConvert(
              'overall_success_rate', (v) => (v as num?)?.toDouble()),
          byTaskType: $checkedConvert(
              'by_task_type',
              (v) => (v as List<dynamic>)
                  .map((e) => SelfTypeStat.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          strengths: $checkedConvert(
              'strengths',
              (v) => (v as List<dynamic>)
                  .map((e) => SelfTypeStat.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          weaknesses: $checkedConvert(
              'weaknesses',
              (v) => (v as List<dynamic>)
                  .map((e) => SelfTypeStat.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          traits: $checkedConvert(
              'traits', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalOutcomes': 'total_outcomes',
        'overallSuccessRate': 'overall_success_rate',
        'byTaskType': 'by_task_type'
      },
    );

Map<String, dynamic> _$$SelfProfileResponseImplToJson(
    _$SelfProfileResponseImpl instance) {
  final val = <String, dynamic>{
    'total_outcomes': instance.totalOutcomes,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('overall_success_rate', instance.overallSuccessRate);
  val['by_task_type'] = instance.byTaskType;
  val['strengths'] = instance.strengths;
  val['weaknesses'] = instance.weaknesses;
  val['traits'] = instance.traits;
  return val;
}

_$SelfTypeStatImpl _$$SelfTypeStatImplFromJson(Map json) => $checkedCreate(
      r'_$SelfTypeStatImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfTypeStatImpl(
          taskType: $checkedConvert('task_type', (v) => v as String),
          attempts: $checkedConvert('attempts', (v) => (v as num).toInt()),
          successRate:
              $checkedConvert('success_rate', (v) => (v as num).toDouble()),
          avgDuration:
              $checkedConvert('avg_duration', (v) => (v as num).toDouble()),
          avgQuality:
              $checkedConvert('avg_quality', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'taskType': 'task_type',
        'successRate': 'success_rate',
        'avgDuration': 'avg_duration',
        'avgQuality': 'avg_quality'
      },
    );

Map<String, dynamic> _$$SelfTypeStatImplToJson(_$SelfTypeStatImpl instance) {
  final val = <String, dynamic>{
    'task_type': instance.taskType,
    'attempts': instance.attempts,
    'success_rate': instance.successRate,
    'avg_duration': instance.avgDuration,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('avg_quality', instance.avgQuality);
  return val;
}

_$SelfAssessResponseImpl _$$SelfAssessResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SelfAssessResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfAssessResponseImpl(
          taskType: $checkedConvert('task_type', (v) => v as String),
          experience: $checkedConvert(
              'experience',
              (v) => v == null
                  ? null
                  : SelfTypeStat.fromJson(Map<String, dynamic>.from(v as Map))),
          novel: $checkedConvert('novel', (v) => v as bool),
          knownWeakness: $checkedConvert('known_weakness', (v) => v as bool),
          recommendation: $checkedConvert('recommendation', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'taskType': 'task_type',
        'knownWeakness': 'known_weakness'
      },
    );

Map<String, dynamic> _$$SelfAssessResponseImplToJson(
    _$SelfAssessResponseImpl instance) {
  final val = <String, dynamic>{
    'task_type': instance.taskType,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('experience', instance.experience);
  val['novel'] = instance.novel;
  val['known_weakness'] = instance.knownWeakness;
  val['recommendation'] = instance.recommendation;
  return val;
}

_$SelfTraitResponseImpl _$$SelfTraitResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SelfTraitResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfTraitResponseImpl(
          recorded: $checkedConvert('recorded', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SelfTraitResponseImplToJson(
        _$SelfTraitResponseImpl instance) =>
    <String, dynamic>{
      'recorded': instance.recorded,
    };

_$SelfImproveStatusResponseImpl _$$SelfImproveStatusResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$SelfImproveStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfImproveStatusResponseImpl(
          enabled: $checkedConvert('enabled', (v) => v as bool),
          totalProposals:
              $checkedConvert('total_proposals', (v) => (v as num).toInt()),
          pendingProposals:
              $checkedConvert('pending_proposals', (v) => (v as num).toInt()),
          approvedProposals:
              $checkedConvert('approved_proposals', (v) => (v as num).toInt()),
          executedProposals:
              $checkedConvert('executed_proposals', (v) => (v as num).toInt()),
          rejectedProposals:
              $checkedConvert('rejected_proposals', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalProposals': 'total_proposals',
        'pendingProposals': 'pending_proposals',
        'approvedProposals': 'approved_proposals',
        'executedProposals': 'executed_proposals',
        'rejectedProposals': 'rejected_proposals'
      },
    );

Map<String, dynamic> _$$SelfImproveStatusResponseImplToJson(
        _$SelfImproveStatusResponseImpl instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'total_proposals': instance.totalProposals,
      'pending_proposals': instance.pendingProposals,
      'approved_proposals': instance.approvedProposals,
      'executed_proposals': instance.executedProposals,
      'rejected_proposals': instance.rejectedProposals,
    };

_$SelfImproveGapsResponseImpl _$$SelfImproveGapsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$SelfImproveGapsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfImproveGapsResponseImpl(
          gaps: $checkedConvert(
              'gaps',
              (v) => (v as List<dynamic>)
                  .map((e) => SelfImproveGap.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SelfImproveGapsResponseImplToJson(
        _$SelfImproveGapsResponseImpl instance) =>
    <String, dynamic>{
      'gaps': instance.gaps,
    };

_$SelfImproveProposeResponseImpl _$$SelfImproveProposeResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$SelfImproveProposeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfImproveProposeResponseImpl(
          proposalId: $checkedConvert('proposal_id', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          codeDraft: $checkedConvert('code_draft', (v) => v as String?),
          estimatedImpact:
              $checkedConvert('estimated_impact', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'proposalId': 'proposal_id',
        'codeDraft': 'code_draft',
        'estimatedImpact': 'estimated_impact'
      },
    );

Map<String, dynamic> _$$SelfImproveProposeResponseImplToJson(
    _$SelfImproveProposeResponseImpl instance) {
  final val = <String, dynamic>{
    'proposal_id': instance.proposalId,
    'type': instance.type,
    'description': instance.description,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('code_draft', instance.codeDraft);
  writeNotNull('estimated_impact', instance.estimatedImpact);
  return val;
}

_$SelfImproveProposalsResponseImpl _$$SelfImproveProposalsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$SelfImproveProposalsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfImproveProposalsResponseImpl(
          proposals: $checkedConvert(
              'proposals',
              (v) => (v as List<dynamic>)
                  .map((e) => SelfImproveProposal.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SelfImproveProposalsResponseImplToJson(
        _$SelfImproveProposalsResponseImpl instance) =>
    <String, dynamic>{
      'proposals': instance.proposals,
    };

_$SelfImproveDecideResponseImpl _$$SelfImproveDecideResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$SelfImproveDecideResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfImproveDecideResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SelfImproveDecideResponseImplToJson(
    _$SelfImproveDecideResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$SelfImproveExecuteResponseImpl _$$SelfImproveExecuteResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$SelfImproveExecuteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SelfImproveExecuteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
          result: $checkedConvert('result', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SelfImproveExecuteResponseImplToJson(
    _$SelfImproveExecuteResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  writeNotNull('result', instance.result);
  return val;
}

_$ScoutScanResponseImpl _$$ScoutScanResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ScoutScanResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScoutScanResponseImpl(
          scanId: $checkedConvert('scan_id', (v) => v as String),
          signalsFound:
              $checkedConvert('signals_found', (v) => (v as num).toInt()),
          opportunitiesCreated: $checkedConvert(
              'opportunities_created', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'scanId': 'scan_id',
        'signalsFound': 'signals_found',
        'opportunitiesCreated': 'opportunities_created'
      },
    );

Map<String, dynamic> _$$ScoutScanResponseImplToJson(
        _$ScoutScanResponseImpl instance) =>
    <String, dynamic>{
      'scan_id': instance.scanId,
      'signals_found': instance.signalsFound,
      'opportunities_created': instance.opportunitiesCreated,
    };

_$ScoutScanHistoryResponseImpl _$$ScoutScanHistoryResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ScoutScanHistoryResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScoutScanHistoryResponseImpl(
          scans: $checkedConvert(
              'scans',
              (v) => (v as List<dynamic>)
                  .map((e) => ScoutScanRecord.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ScoutScanHistoryResponseImplToJson(
        _$ScoutScanHistoryResponseImpl instance) =>
    <String, dynamic>{
      'scans': instance.scans,
    };

_$ScoutSignalsResponseImpl _$$ScoutSignalsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ScoutSignalsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScoutSignalsResponseImpl(
          signals: $checkedConvert(
              'signals',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ScoutSignal.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ScoutSignalsResponseImplToJson(
        _$ScoutSignalsResponseImpl instance) =>
    <String, dynamic>{
      'signals': instance.signals,
    };

_$ScoutOpportunitiesResponseImpl _$$ScoutOpportunitiesResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ScoutOpportunitiesResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScoutOpportunitiesResponseImpl(
          opportunities: $checkedConvert(
              'opportunities',
              (v) => (v as List<dynamic>)
                  .map((e) => ScoutOpportunity.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ScoutOpportunitiesResponseImplToJson(
        _$ScoutOpportunitiesResponseImpl instance) =>
    <String, dynamic>{
      'opportunities': instance.opportunities,
    };

_$ScoutOpportunityDetailResponseImpl
    _$$ScoutOpportunityDetailResponseImplFromJson(Map json) => $checkedCreate(
          r'_$ScoutOpportunityDetailResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$ScoutOpportunityDetailResponseImpl(
              opportunity: $checkedConvert(
                  'opportunity',
                  (v) => ScoutOpportunity.fromJson(
                      Map<String, dynamic>.from(v as Map))),
              relatedSignals: $checkedConvert(
                  'related_signals',
                  (v) => (v as List<dynamic>)
                      .map((e) => ScoutSignal.fromJson(
                          Map<String, dynamic>.from(e as Map)))
                      .toList()),
            );
            return val;
          },
          fieldKeyMap: const {'relatedSignals': 'related_signals'},
        );

Map<String, dynamic> _$$ScoutOpportunityDetailResponseImplToJson(
        _$ScoutOpportunityDetailResponseImpl instance) =>
    <String, dynamic>{
      'opportunity': instance.opportunity,
      'related_signals': instance.relatedSignals,
    };

_$ScoutDecisionResponseImpl _$$ScoutDecisionResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ScoutDecisionResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScoutDecisionResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ScoutDecisionResponseImplToJson(
    _$ScoutDecisionResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$ScoutDeleteResponseImpl _$$ScoutDeleteResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ScoutDeleteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScoutDeleteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ScoutDeleteResponseImplToJson(
    _$ScoutDeleteResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$ScoutPreferencesResponseImpl _$$ScoutPreferencesResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ScoutPreferencesResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScoutPreferencesResponseImpl(
          preferences: $checkedConvert(
              'preferences', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ScoutPreferencesResponseImplToJson(
        _$ScoutPreferencesResponseImpl instance) =>
    <String, dynamic>{
      'preferences': instance.preferences,
    };

_$ScoutStatsResponseImpl _$$ScoutStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ScoutStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScoutStatsResponseImpl(
          totalScans: $checkedConvert('total_scans', (v) => (v as num).toInt()),
          totalSignals:
              $checkedConvert('total_signals', (v) => (v as num).toInt()),
          totalOpportunities:
              $checkedConvert('total_opportunities', (v) => (v as num).toInt()),
          avgScore: $checkedConvert('avg_score', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalScans': 'total_scans',
        'totalSignals': 'total_signals',
        'totalOpportunities': 'total_opportunities',
        'avgScore': 'avg_score'
      },
    );

Map<String, dynamic> _$$ScoutStatsResponseImplToJson(
        _$ScoutStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_scans': instance.totalScans,
      'total_signals': instance.totalSignals,
      'total_opportunities': instance.totalOpportunities,
      'avg_score': instance.avgScore,
    };

_$StrategistReviewResponseImpl _$$StrategistReviewResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$StrategistReviewResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$StrategistReviewResponseImpl(
          reviewId: $checkedConvert('review_id', (v) => v as String),
          opportunitiesReviewed: $checkedConvert(
              'opportunities_reviewed', (v) => (v as num).toInt()),
          plansCreated:
              $checkedConvert('plans_created', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'reviewId': 'review_id',
        'opportunitiesReviewed': 'opportunities_reviewed',
        'plansCreated': 'plans_created'
      },
    );

Map<String, dynamic> _$$StrategistReviewResponseImplToJson(
        _$StrategistReviewResponseImpl instance) =>
    <String, dynamic>{
      'review_id': instance.reviewId,
      'opportunities_reviewed': instance.opportunitiesReviewed,
      'plans_created': instance.plansCreated,
    };

_$StrategistReviewHistoryResponseImpl
    _$$StrategistReviewHistoryResponseImplFromJson(Map json) => $checkedCreate(
          r'_$StrategistReviewHistoryResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$StrategistReviewHistoryResponseImpl(
              reviews: $checkedConvert(
                  'reviews',
                  (v) => (v as List<dynamic>)
                      .map((e) => StrategistReviewRecord.fromJson(
                          Map<String, dynamic>.from(e as Map)))
                      .toList()),
            );
            return val;
          },
        );

Map<String, dynamic> _$$StrategistReviewHistoryResponseImplToJson(
        _$StrategistReviewHistoryResponseImpl instance) =>
    <String, dynamic>{
      'reviews': instance.reviews,
    };

_$StrategistPlansResponseImpl _$$StrategistPlansResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$StrategistPlansResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$StrategistPlansResponseImpl(
          plans: $checkedConvert(
              'plans',
              (v) => (v as List<dynamic>)
                  .map((e) => StrategistPlan.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$StrategistPlansResponseImplToJson(
        _$StrategistPlansResponseImpl instance) =>
    <String, dynamic>{
      'plans': instance.plans,
    };

_$StrategistPlanDetailResponseImpl _$$StrategistPlanDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$StrategistPlanDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$StrategistPlanDetailResponseImpl(
          plan: $checkedConvert(
              'plan',
              (v) =>
                  StrategistPlan.fromJson(Map<String, dynamic>.from(v as Map))),
          steps: $checkedConvert('steps',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$StrategistPlanDetailResponseImplToJson(
        _$StrategistPlanDetailResponseImpl instance) =>
    <String, dynamic>{
      'plan': instance.plan,
      'steps': instance.steps,
    };

_$StrategistDecisionResponseImpl _$$StrategistDecisionResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$StrategistDecisionResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$StrategistDecisionResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$StrategistDecisionResponseImplToJson(
    _$StrategistDecisionResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$StrategistRankedResponseImpl _$$StrategistRankedResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$StrategistRankedResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$StrategistRankedResponseImpl(
          opportunities: $checkedConvert(
              'opportunities',
              (v) => (v as List<dynamic>)
                  .map((e) => StrategistRankedOpportunity.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$StrategistRankedResponseImplToJson(
        _$StrategistRankedResponseImpl instance) =>
    <String, dynamic>{
      'opportunities': instance.opportunities,
    };

_$AgentProfilesListResponseImpl _$$AgentProfilesListResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$AgentProfilesListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentProfilesListResponseImpl(
          profiles: $checkedConvert(
              'profiles',
              (v) => (v as List<dynamic>)
                  .map((e) => AgentProfile.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AgentProfilesListResponseImplToJson(
        _$AgentProfilesListResponseImpl instance) =>
    <String, dynamic>{
      'profiles': instance.profiles,
    };

_$AgentProfileDetailResponseImpl _$$AgentProfileDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$AgentProfileDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentProfileDetailResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          systemPrompt: $checkedConvert('system_prompt', (v) => v as String),
          icon: $checkedConvert('icon', (v) => v as String),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          builtin: $checkedConvert('builtin', (v) => v as bool),
          active: $checkedConvert('active', (v) => v as bool),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'systemPrompt': 'system_prompt',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$$AgentProfileDetailResponseImplToJson(
        _$AgentProfileDetailResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'system_prompt': instance.systemPrompt,
      'icon': instance.icon,
      'tags': instance.tags,
      'builtin': instance.builtin,
      'active': instance.active,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

_$AgentProfilesBuiltinResponseImpl _$$AgentProfilesBuiltinResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$AgentProfilesBuiltinResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentProfilesBuiltinResponseImpl(
          profiles: $checkedConvert(
              'profiles',
              (v) => (v as List<dynamic>)
                  .map((e) => BuiltinAgentProfile.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AgentProfilesBuiltinResponseImplToJson(
        _$AgentProfilesBuiltinResponseImpl instance) =>
    <String, dynamic>{
      'profiles': instance.profiles,
    };

_$AgentProfileImpl _$$AgentProfileImplFromJson(Map json) => $checkedCreate(
      r'_$AgentProfileImpl',
      json,
      ($checkedConvert) {
        final val = _$AgentProfileImpl(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          systemPrompt: $checkedConvert('system_prompt', (v) => v as String),
          icon: $checkedConvert('icon', (v) => v as String),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          builtin: $checkedConvert('builtin', (v) => v as bool),
          active: $checkedConvert('active', (v) => v as bool),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'systemPrompt': 'system_prompt',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$$AgentProfileImplToJson(_$AgentProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'system_prompt': instance.systemPrompt,
      'icon': instance.icon,
      'tags': instance.tags,
      'builtin': instance.builtin,
      'active': instance.active,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

_$StrategistConfigResponseImpl _$$StrategistConfigResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$StrategistConfigResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$StrategistConfigResponseImpl(
          config: $checkedConvert(
              'config', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$StrategistConfigResponseImplToJson(
        _$StrategistConfigResponseImpl instance) =>
    <String, dynamic>{
      'config': instance.config,
    };

_$BuilderProjectsResponseImpl _$$BuilderProjectsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$BuilderProjectsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BuilderProjectsResponseImpl(
          projects: $checkedConvert(
              'projects',
              (v) => (v as List<dynamic>)
                  .map((e) => BuilderProject.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BuilderProjectsResponseImplToJson(
        _$BuilderProjectsResponseImpl instance) =>
    <String, dynamic>{
      'projects': instance.projects,
    };

_$BuilderProjectDetailResponseImpl _$$BuilderProjectDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$BuilderProjectDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BuilderProjectDetailResponseImpl(
          project: $checkedConvert(
              'project',
              (v) =>
                  BuilderProject.fromJson(Map<String, dynamic>.from(v as Map))),
          steps: $checkedConvert(
              'steps',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      BuilderStep.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BuilderProjectDetailResponseImplToJson(
        _$BuilderProjectDetailResponseImpl instance) =>
    <String, dynamic>{
      'project': instance.project,
      'steps': instance.steps,
    };

_$BuilderStatusResponseImpl _$$BuilderStatusResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BuilderStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BuilderStatusResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BuilderStatusResponseImplToJson(
    _$BuilderStatusResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$BuilderStepsResponseImpl _$$BuilderStepsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BuilderStepsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BuilderStepsResponseImpl(
          steps: $checkedConvert(
              'steps',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      BuilderStep.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BuilderStepsResponseImplToJson(
        _$BuilderStepsResponseImpl instance) =>
    <String, dynamic>{
      'steps': instance.steps,
    };

_$BuilderStepExecuteResponseImpl _$$BuilderStepExecuteResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$BuilderStepExecuteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BuilderStepExecuteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
          output: $checkedConvert('output', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BuilderStepExecuteResponseImplToJson(
    _$BuilderStepExecuteResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  writeNotNull('output', instance.output);
  return val;
}

_$BuilderBuildResponseImpl _$$BuilderBuildResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BuilderBuildResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BuilderBuildResponseImpl(
          projectId: $checkedConvert('project_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'projectId': 'project_id'},
    );

Map<String, dynamic> _$$BuilderBuildResponseImplToJson(
    _$BuilderBuildResponseImpl instance) {
  final val = <String, dynamic>{
    'project_id': instance.projectId,
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$BuilderStatsResponseImpl _$$BuilderStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BuilderStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BuilderStatsResponseImpl(
          totalProjects:
              $checkedConvert('total_projects', (v) => (v as num).toInt()),
          completedProjects:
              $checkedConvert('completed_projects', (v) => (v as num).toInt()),
          activeProjects:
              $checkedConvert('active_projects', (v) => (v as num).toInt()),
          totalStepsExecuted: $checkedConvert(
              'total_steps_executed', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalProjects': 'total_projects',
        'completedProjects': 'completed_projects',
        'activeProjects': 'active_projects',
        'totalStepsExecuted': 'total_steps_executed'
      },
    );

Map<String, dynamic> _$$BuilderStatsResponseImplToJson(
        _$BuilderStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_projects': instance.totalProjects,
      'completed_projects': instance.completedProjects,
      'active_projects': instance.activeProjects,
      'total_steps_executed': instance.totalStepsExecuted,
    };

_$LauncherLaunchesResponseImpl _$$LauncherLaunchesResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$LauncherLaunchesResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LauncherLaunchesResponseImpl(
          launches: $checkedConvert(
              'launches',
              (v) => (v as List<dynamic>)
                  .map((e) => LauncherLaunch.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LauncherLaunchesResponseImplToJson(
        _$LauncherLaunchesResponseImpl instance) =>
    <String, dynamic>{
      'launches': instance.launches,
    };

_$LauncherLaunchDetailResponseImpl _$$LauncherLaunchDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$LauncherLaunchDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LauncherLaunchDetailResponseImpl(
          launch: $checkedConvert(
              'launch',
              (v) =>
                  LauncherLaunch.fromJson(Map<String, dynamic>.from(v as Map))),
          content: $checkedConvert(
              'content',
              (v) => (v as List<dynamic>)
                  .map((e) => LauncherContent.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LauncherLaunchDetailResponseImplToJson(
        _$LauncherLaunchDetailResponseImpl instance) =>
    <String, dynamic>{
      'launch': instance.launch,
      'content': instance.content,
    };

_$LauncherContentResponseImpl _$$LauncherContentResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$LauncherContentResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LauncherContentResponseImpl(
          content: $checkedConvert(
              'content',
              (v) => (v as List<dynamic>)
                  .map((e) => LauncherContent.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LauncherContentResponseImplToJson(
        _$LauncherContentResponseImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
    };

_$LauncherApproveResponseImpl _$$LauncherApproveResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$LauncherApproveResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LauncherApproveResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LauncherApproveResponseImplToJson(
    _$LauncherApproveResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$LauncherUpdateResponseImpl _$$LauncherUpdateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LauncherUpdateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LauncherUpdateResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LauncherUpdateResponseImplToJson(
    _$LauncherUpdateResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$LauncherConfigResponseImpl _$$LauncherConfigResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LauncherConfigResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LauncherConfigResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LauncherConfigResponseImplToJson(
    _$LauncherConfigResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$LauncherStartResponseImpl _$$LauncherStartResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LauncherStartResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LauncherStartResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LauncherStartResponseImplToJson(
    _$LauncherStartResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$LauncherRetryResponseImpl _$$LauncherRetryResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LauncherRetryResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LauncherRetryResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LauncherRetryResponseImplToJson(
    _$LauncherRetryResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$LauncherStatsResponseImpl _$$LauncherStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LauncherStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LauncherStatsResponseImpl(
          totalLaunches:
              $checkedConvert('total_launches', (v) => (v as num).toInt()),
          successfulLaunches:
              $checkedConvert('successful_launches', (v) => (v as num).toInt()),
          failedLaunches:
              $checkedConvert('failed_launches', (v) => (v as num).toInt()),
          pendingLaunches:
              $checkedConvert('pending_launches', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalLaunches': 'total_launches',
        'successfulLaunches': 'successful_launches',
        'failedLaunches': 'failed_launches',
        'pendingLaunches': 'pending_launches'
      },
    );

Map<String, dynamic> _$$LauncherStatsResponseImplToJson(
        _$LauncherStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_launches': instance.totalLaunches,
      'successful_launches': instance.successfulLaunches,
      'failed_launches': instance.failedLaunches,
      'pending_launches': instance.pendingLaunches,
    };

_$GrowthProposalsResponseImpl _$$GrowthProposalsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$GrowthProposalsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GrowthProposalsResponseImpl(
          proposals: $checkedConvert(
              'proposals',
              (v) => (v as List<dynamic>)
                  .map((e) => GrowthProposal.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GrowthProposalsResponseImplToJson(
        _$GrowthProposalsResponseImpl instance) =>
    <String, dynamic>{
      'proposals': instance.proposals,
    };

_$GrowthProposalDetailResponseImpl _$$GrowthProposalDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$GrowthProposalDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GrowthProposalDetailResponseImpl(
          proposal: $checkedConvert(
              'proposal',
              (v) =>
                  GrowthProposal.fromJson(Map<String, dynamic>.from(v as Map))),
          metrics: $checkedConvert(
              'metrics', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GrowthProposalDetailResponseImplToJson(
        _$GrowthProposalDetailResponseImpl instance) =>
    <String, dynamic>{
      'proposal': instance.proposal,
      'metrics': instance.metrics,
    };

_$GrowthDecideResponseImpl _$$GrowthDecideResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GrowthDecideResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GrowthDecideResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GrowthDecideResponseImplToJson(
    _$GrowthDecideResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$GrowthMetricsResponseImpl _$$GrowthMetricsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GrowthMetricsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GrowthMetricsResponseImpl(
          metrics: $checkedConvert(
              'metrics',
              (v) => (v as List<dynamic>)
                  .map((e) => GrowthMetric.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GrowthMetricsResponseImplToJson(
        _$GrowthMetricsResponseImpl instance) =>
    <String, dynamic>{
      'metrics': instance.metrics,
    };

_$GrowthMetricsProjectResponseImpl _$$GrowthMetricsProjectResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$GrowthMetricsProjectResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GrowthMetricsProjectResponseImpl(
          metrics: $checkedConvert(
              'metrics',
              (v) => (v as List<dynamic>)
                  .map((e) => GrowthMetric.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GrowthMetricsProjectResponseImplToJson(
        _$GrowthMetricsProjectResponseImpl instance) =>
    <String, dynamic>{
      'metrics': instance.metrics,
    };

_$GrowthRecommendationsResponseImpl
    _$$GrowthRecommendationsResponseImplFromJson(Map json) => $checkedCreate(
          r'_$GrowthRecommendationsResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$GrowthRecommendationsResponseImpl(
              recommendations: $checkedConvert(
                  'recommendations',
                  (v) => (v as List<dynamic>)
                      .map((e) => GrowthRecommendation.fromJson(
                          Map<String, dynamic>.from(e as Map)))
                      .toList()),
            );
            return val;
          },
        );

Map<String, dynamic> _$$GrowthRecommendationsResponseImplToJson(
        _$GrowthRecommendationsResponseImpl instance) =>
    <String, dynamic>{
      'recommendations': instance.recommendations,
    };

_$GrowthReviewResponseImpl _$$GrowthReviewResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GrowthReviewResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GrowthReviewResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
          report: $checkedConvert('report', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GrowthReviewResponseImplToJson(
    _$GrowthReviewResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  writeNotNull('report', instance.report);
  return val;
}

_$GrowthSummaryResponseImpl _$$GrowthSummaryResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GrowthSummaryResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GrowthSummaryResponseImpl(
          totalProposals:
              $checkedConvert('total_proposals', (v) => (v as num).toInt()),
          approvedProposals:
              $checkedConvert('approved_proposals', (v) => (v as num).toInt()),
          totalEstimatedImpact: $checkedConvert(
              'total_estimated_impact', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalProposals': 'total_proposals',
        'approvedProposals': 'approved_proposals',
        'totalEstimatedImpact': 'total_estimated_impact'
      },
    );

Map<String, dynamic> _$$GrowthSummaryResponseImplToJson(
        _$GrowthSummaryResponseImpl instance) =>
    <String, dynamic>{
      'total_proposals': instance.totalProposals,
      'approved_proposals': instance.approvedProposals,
      'total_estimated_impact': instance.totalEstimatedImpact,
    };

_$GrowthActionsResponseImpl _$$GrowthActionsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$GrowthActionsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$GrowthActionsResponseImpl(
          actions: $checkedConvert(
              'actions',
              (v) => (v as List<dynamic>)
                  .map((e) => GrowthAction.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GrowthActionsResponseImplToJson(
        _$GrowthActionsResponseImpl instance) =>
    <String, dynamic>{
      'actions': instance.actions,
    };

_$NotifSendResponseImpl _$$NotifSendResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$NotifSendResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifSendResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifSendResponseImplToJson(
    _$NotifSendResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$NotifApprovalRequestResponseImpl _$$NotifApprovalRequestResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$NotifApprovalRequestResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifApprovalRequestResponseImpl(
          approvalId: $checkedConvert('approval_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'approvalId': 'approval_id'},
    );

Map<String, dynamic> _$$NotifApprovalRequestResponseImplToJson(
        _$NotifApprovalRequestResponseImpl instance) =>
    <String, dynamic>{
      'approval_id': instance.approvalId,
      'success': instance.success,
    };

_$NotifApprovalsListResponseImpl _$$NotifApprovalsListResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$NotifApprovalsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifApprovalsListResponseImpl(
          approvals: $checkedConvert(
              'approvals',
              (v) => (v as List<dynamic>)
                  .map((e) => NotifApproval.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifApprovalsListResponseImplToJson(
        _$NotifApprovalsListResponseImpl instance) =>
    <String, dynamic>{
      'approvals': instance.approvals,
    };

_$NotifApprovalDetailResponseImpl _$$NotifApprovalDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$NotifApprovalDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifApprovalDetailResponseImpl(
          approval: $checkedConvert(
              'approval',
              (v) =>
                  NotifApproval.fromJson(Map<String, dynamic>.from(v as Map))),
          history: $checkedConvert('history',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifApprovalDetailResponseImplToJson(
        _$NotifApprovalDetailResponseImpl instance) =>
    <String, dynamic>{
      'approval': instance.approval,
      'history': instance.history,
    };

_$NotifApprovalDecideResponseImpl _$$NotifApprovalDecideResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$NotifApprovalDecideResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifApprovalDecideResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifApprovalDecideResponseImplToJson(
    _$NotifApprovalDecideResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$NotifDigestResponseImpl _$$NotifDigestResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$NotifDigestResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifDigestResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifDigestResponseImplToJson(
    _$NotifDigestResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$NotifAlertResponseImpl _$$NotifAlertResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$NotifAlertResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifAlertResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifAlertResponseImplToJson(
    _$NotifAlertResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$NotifTemplatesResponseImpl _$$NotifTemplatesResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$NotifTemplatesResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifTemplatesResponseImpl(
          templates: $checkedConvert(
              'templates',
              (v) => (v as List<dynamic>)
                  .map((e) => NotifTemplate.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifTemplatesResponseImplToJson(
        _$NotifTemplatesResponseImpl instance) =>
    <String, dynamic>{
      'templates': instance.templates,
    };

_$NotifTemplateResponseImpl _$$NotifTemplateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$NotifTemplateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifTemplateResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifTemplateResponseImplToJson(
    _$NotifTemplateResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$NotifDeleteResponseImpl _$$NotifDeleteResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$NotifDeleteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifDeleteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifDeleteResponseImplToJson(
    _$NotifDeleteResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$NotifChannelsResponseImpl _$$NotifChannelsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$NotifChannelsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifChannelsResponseImpl(
          channels: $checkedConvert('channels',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$NotifChannelsResponseImplToJson(
        _$NotifChannelsResponseImpl instance) =>
    <String, dynamic>{
      'channels': instance.channels,
    };

_$NotifStatsResponseImpl _$$NotifStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$NotifStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$NotifStatsResponseImpl(
          totalSent: $checkedConvert('total_sent', (v) => (v as num).toInt()),
          totalFailed:
              $checkedConvert('total_failed', (v) => (v as num).toInt()),
          totalPending:
              $checkedConvert('total_pending', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalSent': 'total_sent',
        'totalFailed': 'total_failed',
        'totalPending': 'total_pending'
      },
    );

Map<String, dynamic> _$$NotifStatsResponseImplToJson(
        _$NotifStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_sent': instance.totalSent,
      'total_failed': instance.totalFailed,
      'total_pending': instance.totalPending,
    };

_$ExtStatusResponseImpl _$$ExtStatusResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtStatusResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtStatusResponseImpl(
          running: $checkedConvert('running', (v) => v as bool),
          activeTasks:
              $checkedConvert('active_tasks', (v) => (v as num).toInt()),
          queuedTasks:
              $checkedConvert('queued_tasks', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'activeTasks': 'active_tasks',
        'queuedTasks': 'queued_tasks'
      },
    );

Map<String, dynamic> _$$ExtStatusResponseImplToJson(
        _$ExtStatusResponseImpl instance) =>
    <String, dynamic>{
      'running': instance.running,
      'active_tasks': instance.activeTasks,
      'queued_tasks': instance.queuedTasks,
    };

_$ExtHealthResponseImpl _$$ExtHealthResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtHealthResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtHealthResponseImpl(
          healthy: $checkedConvert('healthy', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtHealthResponseImplToJson(
    _$ExtHealthResponseImpl instance) {
  final val = <String, dynamic>{
    'healthy': instance.healthy,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$ExtTaskCreateResponseImpl _$$ExtTaskCreateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtTaskCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtTaskCreateResponseImpl(
          taskId: $checkedConvert('task_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'taskId': 'task_id'},
    );

Map<String, dynamic> _$$ExtTaskCreateResponseImplToJson(
        _$ExtTaskCreateResponseImpl instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'success': instance.success,
    };

_$ExtTaskDetailResponseImpl _$$ExtTaskDetailResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtTaskDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtTaskDetailResponseImpl(
          taskId: $checkedConvert('task_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          result: $checkedConvert('result', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'taskId': 'task_id'},
    );

Map<String, dynamic> _$$ExtTaskDetailResponseImplToJson(
    _$ExtTaskDetailResponseImpl instance) {
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

_$ExtInterruptResponseImpl _$$ExtInterruptResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtInterruptResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtInterruptResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtInterruptResponseImplToJson(
    _$ExtInterruptResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$ExtCancelResponseImpl _$$ExtCancelResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtCancelResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtCancelResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtCancelResponseImplToJson(
    _$ExtCancelResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$ExtTasksListResponseImpl _$$ExtTasksListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtTasksListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtTasksListResponseImpl(
          tasks: $checkedConvert(
              'tasks',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ExtTask.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtTasksListResponseImplToJson(
        _$ExtTasksListResponseImpl instance) =>
    <String, dynamic>{
      'tasks': instance.tasks,
    };

_$ProactiveJobsResponseImpl _$$ProactiveJobsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ProactiveJobsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProactiveJobsResponseImpl(
          jobs: $checkedConvert(
              'jobs',
              (v) => (v as List<dynamic>)
                  .map((e) => ProactiveJob.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProactiveJobsResponseImplToJson(
        _$ProactiveJobsResponseImpl instance) =>
    <String, dynamic>{
      'jobs': instance.jobs,
    };

_$ProactiveJobCreateResponseImpl _$$ProactiveJobCreateResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProactiveJobCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProactiveJobCreateResponseImpl(
          jobId: $checkedConvert('job_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'jobId': 'job_id'},
    );

Map<String, dynamic> _$$ProactiveJobCreateResponseImplToJson(
        _$ProactiveJobCreateResponseImpl instance) =>
    <String, dynamic>{
      'job_id': instance.jobId,
      'success': instance.success,
    };

_$ProactiveDeleteResponseImpl _$$ProactiveDeleteResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProactiveDeleteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProactiveDeleteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProactiveDeleteResponseImplToJson(
    _$ProactiveDeleteResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$ProactiveRunResponseImpl _$$ProactiveRunResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ProactiveRunResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProactiveRunResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProactiveRunResponseImplToJson(
    _$ProactiveRunResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$ExtMemPrefsResponseImpl _$$ExtMemPrefsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtMemPrefsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtMemPrefsResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtMemPrefsResponseImplToJson(
    _$ExtMemPrefsResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$ExtMemPrefDetailResponseImpl _$$ExtMemPrefDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ExtMemPrefDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtMemPrefDetailResponseImpl(
          key: $checkedConvert('key', (v) => v as String),
          value: $checkedConvert('value', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtMemPrefDetailResponseImplToJson(
        _$ExtMemPrefDetailResponseImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
    };

_$ExtMemPrefsListResponseImpl _$$ExtMemPrefsListResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ExtMemPrefsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtMemPrefsListResponseImpl(
          preferences: $checkedConvert(
              'preferences', (v) => Map<String, String>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtMemPrefsListResponseImplToJson(
        _$ExtMemPrefsListResponseImpl instance) =>
    <String, dynamic>{
      'preferences': instance.preferences,
    };

_$ExtMemFactsResponseImpl _$$ExtMemFactsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtMemFactsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtMemFactsResponseImpl(
          factId: $checkedConvert('fact_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'factId': 'fact_id'},
    );

Map<String, dynamic> _$$ExtMemFactsResponseImplToJson(
        _$ExtMemFactsResponseImpl instance) =>
    <String, dynamic>{
      'fact_id': instance.factId,
      'success': instance.success,
    };

_$ExtMemFactsListResponseImpl _$$ExtMemFactsListResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ExtMemFactsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtMemFactsListResponseImpl(
          facts: $checkedConvert(
              'facts',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ExtMemFact.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtMemFactsListResponseImplToJson(
        _$ExtMemFactsListResponseImpl instance) =>
    <String, dynamic>{
      'facts': instance.facts,
    };

_$ExtMemProjectsResponseImpl _$$ExtMemProjectsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtMemProjectsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtMemProjectsResponseImpl(
          projectId: $checkedConvert('project_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'projectId': 'project_id'},
    );

Map<String, dynamic> _$$ExtMemProjectsResponseImplToJson(
        _$ExtMemProjectsResponseImpl instance) =>
    <String, dynamic>{
      'project_id': instance.projectId,
      'success': instance.success,
    };

_$ExtMemProjectDetailResponseImpl _$$ExtMemProjectDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ExtMemProjectDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtMemProjectDetailResponseImpl(
          projectId: $checkedConvert('project_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'projectId': 'project_id'},
    );

Map<String, dynamic> _$$ExtMemProjectDetailResponseImplToJson(
        _$ExtMemProjectDetailResponseImpl instance) =>
    <String, dynamic>{
      'project_id': instance.projectId,
      'name': instance.name,
      'description': instance.description,
    };

_$ExtMemContextResponseImpl _$$ExtMemContextResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtMemContextResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtMemContextResponseImpl(
          context: $checkedConvert('context', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtMemContextResponseImplToJson(
        _$ExtMemContextResponseImpl instance) =>
    <String, dynamic>{
      'context': instance.context,
    };

_$ExtInterruptionsResponseImpl _$$ExtInterruptionsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ExtInterruptionsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtInterruptionsResponseImpl(
          interruptions: $checkedConvert(
              'interruptions',
              (v) => (v as List<dynamic>)
                  .map((e) => ExtInterruption.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtInterruptionsResponseImplToJson(
        _$ExtInterruptionsResponseImpl instance) =>
    <String, dynamic>{
      'interruptions': instance.interruptions,
    };

_$ExtVoiceCommandResponseImpl _$$ExtVoiceCommandResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ExtVoiceCommandResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtVoiceCommandResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          result: $checkedConvert('result', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtVoiceCommandResponseImplToJson(
    _$ExtVoiceCommandResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('result', instance.result);
  return val;
}

_$ExtToolsResponseImpl _$$ExtToolsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtToolsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtToolsResponseImpl(
          tools: $checkedConvert('tools',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtToolsResponseImplToJson(
        _$ExtToolsResponseImpl instance) =>
    <String, dynamic>{
      'tools': instance.tools,
    };

_$ExtConfigResponseImpl _$$ExtConfigResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ExtConfigResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExtConfigResponseImpl(
          config: $checkedConvert(
              'config', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ExtConfigResponseImplToJson(
        _$ExtConfigResponseImpl instance) =>
    <String, dynamic>{
      'config': instance.config,
    };

_$CapabilitiesListResponseImpl _$$CapabilitiesListResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CapabilitiesListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CapabilitiesListResponseImpl(
          capabilities: $checkedConvert(
              'capabilities',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Capability.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CapabilitiesListResponseImplToJson(
        _$CapabilitiesListResponseImpl instance) =>
    <String, dynamic>{
      'capabilities': instance.capabilities,
    };

_$CapabilitiesSearchResponseImpl _$$CapabilitiesSearchResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CapabilitiesSearchResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CapabilitiesSearchResponseImpl(
          capabilities: $checkedConvert(
              'capabilities',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Capability.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CapabilitiesSearchResponseImplToJson(
        _$CapabilitiesSearchResponseImpl instance) =>
    <String, dynamic>{
      'capabilities': instance.capabilities,
    };

_$CapabilitiesStatsResponseImpl _$$CapabilitiesStatsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CapabilitiesStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CapabilitiesStatsResponseImpl(
          totalCapabilities:
              $checkedConvert('total_capabilities', (v) => (v as num).toInt()),
          verifiedCapabilities: $checkedConvert(
              'verified_capabilities', (v) => (v as num).toInt()),
          totalUsages:
              $checkedConvert('total_usages', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalCapabilities': 'total_capabilities',
        'verifiedCapabilities': 'verified_capabilities',
        'totalUsages': 'total_usages'
      },
    );

Map<String, dynamic> _$$CapabilitiesStatsResponseImplToJson(
        _$CapabilitiesStatsResponseImpl instance) =>
    <String, dynamic>{
      'total_capabilities': instance.totalCapabilities,
      'verified_capabilities': instance.verifiedCapabilities,
      'total_usages': instance.totalUsages,
    };

_$CapabilityDetailResponseImpl _$$CapabilityDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CapabilityDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CapabilityDetailResponseImpl(
          capability: $checkedConvert('capability',
              (v) => Capability.fromJson(Map<String, dynamic>.from(v as Map))),
          composableWith: $checkedConvert(
              'composable_with',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Capability.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
          relations: $checkedConvert(
              'relations',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Capability.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {'composableWith': 'composable_with'},
    );

Map<String, dynamic> _$$CapabilityDetailResponseImplToJson(
        _$CapabilityDetailResponseImpl instance) =>
    <String, dynamic>{
      'capability': instance.capability,
      'composable_with': instance.composableWith,
      'relations': instance.relations,
    };

_$CapabilityVerifyResponseImpl _$$CapabilityVerifyResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CapabilityVerifyResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CapabilityVerifyResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CapabilityVerifyResponseImplToJson(
    _$CapabilityVerifyResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$CapabilityComposableResponseImpl _$$CapabilityComposableResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CapabilityComposableResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CapabilityComposableResponseImpl(
          composable: $checkedConvert(
              'composable',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Capability.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CapabilityComposableResponseImplToJson(
        _$CapabilityComposableResponseImpl instance) =>
    <String, dynamic>{
      'composable': instance.composable,
    };

_$CapabilityRelationsResponseImpl _$$CapabilityRelationsResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$CapabilityRelationsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$CapabilityRelationsResponseImpl(
          relations: $checkedConvert(
              'relations',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Capability.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CapabilityRelationsResponseImplToJson(
        _$CapabilityRelationsResponseImpl instance) =>
    <String, dynamic>{
      'relations': instance.relations,
    };

_$WebhooksListResponseImpl _$$WebhooksListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WebhooksListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WebhooksListResponseImpl(
          webhooks: $checkedConvert(
              'webhooks',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Webhook.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$WebhooksListResponseImplToJson(
        _$WebhooksListResponseImpl instance) =>
    <String, dynamic>{
      'webhooks': instance.webhooks,
    };

_$WebhookCreateResponseImpl _$$WebhookCreateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WebhookCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WebhookCreateResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$$WebhookCreateResponseImplToJson(
        _$WebhookCreateResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'success': instance.success,
    };

_$WebhookUpdateResponseImpl _$$WebhookUpdateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WebhookUpdateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WebhookUpdateResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$WebhookUpdateResponseImplToJson(
    _$WebhookUpdateResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$WebhookDeleteResponseImpl _$$WebhookDeleteResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WebhookDeleteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WebhookDeleteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$WebhookDeleteResponseImplToJson(
    _$WebhookDeleteResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$DocsListResponseImpl _$$DocsListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$DocsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$DocsListResponseImpl(
          docs: $checkedConvert(
              'docs',
              (v) => (v as List<dynamic>)
                  .map((e) => Doc.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$DocsListResponseImplToJson(
        _$DocsListResponseImpl instance) =>
    <String, dynamic>{
      'docs': instance.docs,
    };

_$DocsDetailResponseImpl _$$DocsDetailResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$DocsDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$DocsDetailResponseImpl(
          name: $checkedConvert('name', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$DocsDetailResponseImplToJson(
        _$DocsDetailResponseImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'content': instance.content,
    };

_$ProjectsListResponseImpl _$$ProjectsListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ProjectsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProjectsListResponseImpl(
          projects: $checkedConvert(
              'projects',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Project.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProjectsListResponseImplToJson(
        _$ProjectsListResponseImpl instance) =>
    <String, dynamic>{
      'projects': instance.projects,
    };

_$ProjectCreateResponseImpl _$$ProjectCreateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ProjectCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProjectCreateResponseImpl(
          projectId: $checkedConvert('project_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'projectId': 'project_id'},
    );

Map<String, dynamic> _$$ProjectCreateResponseImplToJson(
        _$ProjectCreateResponseImpl instance) =>
    <String, dynamic>{
      'project_id': instance.projectId,
      'success': instance.success,
    };

_$ProjectProgressResponseImpl _$$ProjectProgressResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProjectProgressResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProjectProgressResponseImpl(
          projectId: $checkedConvert('project_id', (v) => v as String),
          progress: $checkedConvert('progress', (v) => (v as num).toDouble()),
          status: $checkedConvert('status', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'projectId': 'project_id'},
    );

Map<String, dynamic> _$$ProjectProgressResponseImplToJson(
        _$ProjectProgressResponseImpl instance) =>
    <String, dynamic>{
      'project_id': instance.projectId,
      'progress': instance.progress,
      'status': instance.status,
    };

_$ProjectDeleteResponseImpl _$$ProjectDeleteResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ProjectDeleteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProjectDeleteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProjectDeleteResponseImplToJson(
    _$ProjectDeleteResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$SchedulesListResponseImpl _$$SchedulesListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SchedulesListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SchedulesListResponseImpl(
          schedules: $checkedConvert(
              'schedules',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Schedule.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$SchedulesListResponseImplToJson(
        _$SchedulesListResponseImpl instance) =>
    <String, dynamic>{
      'schedules': instance.schedules,
    };

_$ScheduleCreateResponseImpl _$$ScheduleCreateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ScheduleCreateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScheduleCreateResponseImpl(
          scheduleId: $checkedConvert('schedule_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'scheduleId': 'schedule_id'},
    );

Map<String, dynamic> _$$ScheduleCreateResponseImplToJson(
        _$ScheduleCreateResponseImpl instance) =>
    <String, dynamic>{
      'schedule_id': instance.scheduleId,
      'success': instance.success,
    };

_$ScheduleUpdateResponseImpl _$$ScheduleUpdateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ScheduleUpdateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScheduleUpdateResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ScheduleUpdateResponseImplToJson(
    _$ScheduleUpdateResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$ScheduleEnabledResponseImpl _$$ScheduleEnabledResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ScheduleEnabledResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ScheduleEnabledResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ScheduleEnabledResponseImplToJson(
    _$ScheduleEnabledResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$AnalyticsSummaryResponseImpl _$$AnalyticsSummaryResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$AnalyticsSummaryResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AnalyticsSummaryResponseImpl(
          totalRequests:
              $checkedConvert('total_requests', (v) => (v as num).toInt()),
          totalErrors:
              $checkedConvert('total_errors', (v) => (v as num).toInt()),
          avgLatency:
              $checkedConvert('avg_latency', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalRequests': 'total_requests',
        'totalErrors': 'total_errors',
        'avgLatency': 'avg_latency'
      },
    );

Map<String, dynamic> _$$AnalyticsSummaryResponseImplToJson(
        _$AnalyticsSummaryResponseImpl instance) =>
    <String, dynamic>{
      'total_requests': instance.totalRequests,
      'total_errors': instance.totalErrors,
      'avg_latency': instance.avgLatency,
    };

_$AnalyticsDailyResponseImpl _$$AnalyticsDailyResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AnalyticsDailyResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AnalyticsDailyResponseImpl(
          points: $checkedConvert(
              'points',
              (v) => (v as List<dynamic>)
                  .map((e) => AnalyticsDailyPoint.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AnalyticsDailyResponseImplToJson(
        _$AnalyticsDailyResponseImpl instance) =>
    <String, dynamic>{
      'points': instance.points,
    };

_$AnalyticsProvidersResponseImpl _$$AnalyticsProvidersResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$AnalyticsProvidersResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AnalyticsProvidersResponseImpl(
          providers: $checkedConvert(
              'providers',
              (v) => (v as List<dynamic>)
                  .map((e) => AnalyticsProviderStat.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AnalyticsProvidersResponseImplToJson(
        _$AnalyticsProvidersResponseImpl instance) =>
    <String, dynamic>{
      'providers': instance.providers,
    };

_$AnalyticsToolsResponseImpl _$$AnalyticsToolsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AnalyticsToolsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AnalyticsToolsResponseImpl(
          tools: $checkedConvert(
              'tools',
              (v) => (v as List<dynamic>)
                  .map((e) => AnalyticsToolStat.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AnalyticsToolsResponseImplToJson(
        _$AnalyticsToolsResponseImpl instance) =>
    <String, dynamic>{
      'tools': instance.tools,
    };

_$LogsLLMResponseImpl _$$LogsLLMResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LogsLLMResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LogsLLMResponseImpl(
          logs: $checkedConvert(
              'logs',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      LogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LogsLLMResponseImplToJson(
        _$LogsLLMResponseImpl instance) =>
    <String, dynamic>{
      'logs': instance.logs,
    };

_$LogsToolsResponseImpl _$$LogsToolsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LogsToolsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LogsToolsResponseImpl(
          logs: $checkedConvert(
              'logs',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      LogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LogsToolsResponseImplToJson(
        _$LogsToolsResponseImpl instance) =>
    <String, dynamic>{
      'logs': instance.logs,
    };

_$PluginsListResponseImpl _$$PluginsListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$PluginsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PluginsListResponseImpl(
          plugins: $checkedConvert(
              'plugins',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      Plugin.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$PluginsListResponseImplToJson(
        _$PluginsListResponseImpl instance) =>
    <String, dynamic>{
      'plugins': instance.plugins,
    };

_$PluginInstallResponseImpl _$$PluginInstallResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$PluginInstallResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PluginInstallResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$PluginInstallResponseImplToJson(
    _$PluginInstallResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

_$VisionAnalyzeResponseImpl _$$VisionAnalyzeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$VisionAnalyzeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$VisionAnalyzeResponseImpl(
          description: $checkedConvert('description', (v) => v as String),
          objects: $checkedConvert('objects',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          text: $checkedConvert('text',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$VisionAnalyzeResponseImplToJson(
        _$VisionAnalyzeResponseImpl instance) =>
    <String, dynamic>{
      'description': instance.description,
      'objects': instance.objects,
      'text': instance.text,
    };

_$VisionOCRResponseImpl _$$VisionOCRResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$VisionOCRResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$VisionOCRResponseImpl(
          text: $checkedConvert('text', (v) => v as String),
          confidence:
              $checkedConvert('confidence', (v) => (v as num).toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$VisionOCRResponseImplToJson(
        _$VisionOCRResponseImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'confidence': instance.confidence,
    };

_$WorkingMemoryAddResponseImpl _$$WorkingMemoryAddResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$WorkingMemoryAddResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WorkingMemoryAddResponseImpl(
          slotId: $checkedConvert('slot_id', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'slotId': 'slot_id'},
    );

Map<String, dynamic> _$$WorkingMemoryAddResponseImplToJson(
        _$WorkingMemoryAddResponseImpl instance) =>
    <String, dynamic>{
      'slot_id': instance.slotId,
    };

_$WorkingMemorySearchResponseImpl _$$WorkingMemorySearchResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$WorkingMemorySearchResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WorkingMemorySearchResponseImpl(
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => WorkingMemoryItem.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$WorkingMemorySearchResponseImplToJson(
        _$WorkingMemorySearchResponseImpl instance) =>
    <String, dynamic>{
      'results': instance.results,
    };

_$WorkingMemoryCapacityResponseImpl
    _$$WorkingMemoryCapacityResponseImplFromJson(Map json) => $checkedCreate(
          r'_$WorkingMemoryCapacityResponseImpl',
          json,
          ($checkedConvert) {
            final val = _$WorkingMemoryCapacityResponseImpl(
              totalSlots:
                  $checkedConvert('total_slots', (v) => (v as num).toInt()),
              usedSlots:
                  $checkedConvert('used_slots', (v) => (v as num).toInt()),
              freeSlots:
                  $checkedConvert('free_slots', (v) => (v as num).toInt()),
              byType: $checkedConvert(
                  'by_type', (v) => Map<String, int>.from(v as Map)),
              totalAttention: $checkedConvert(
                  'total_attention', (v) => (v as num).toDouble()),
            );
            return val;
          },
          fieldKeyMap: const {
            'totalSlots': 'total_slots',
            'usedSlots': 'used_slots',
            'freeSlots': 'free_slots',
            'byType': 'by_type',
            'totalAttention': 'total_attention'
          },
        );

Map<String, dynamic> _$$WorkingMemoryCapacityResponseImplToJson(
        _$WorkingMemoryCapacityResponseImpl instance) =>
    <String, dynamic>{
      'total_slots': instance.totalSlots,
      'used_slots': instance.usedSlots,
      'free_slots': instance.freeSlots,
      'by_type': instance.byType,
      'total_attention': instance.totalAttention,
    };

_$WMAddResponseImpl _$$WMAddResponseImplFromJson(Map json) => $checkedCreate(
      r'_$WMAddResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WMAddResponseImpl(
          itemId: $checkedConvert('item_id', (v) => v as String),
          success: $checkedConvert('success', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'itemId': 'item_id'},
    );

Map<String, dynamic> _$$WMAddResponseImplToJson(_$WMAddResponseImpl instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'success': instance.success,
    };

_$WMRetrieveResponseImpl _$$WMRetrieveResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WMRetrieveResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WMRetrieveResponseImpl(
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      WMItem.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$WMRetrieveResponseImplToJson(
        _$WMRetrieveResponseImpl instance) =>
    <String, dynamic>{
      'results': instance.results,
    };

_$WMDecayResponseImpl _$$WMDecayResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WMDecayResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WMDecayResponseImpl(
          removed: $checkedConvert('removed', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$WMDecayResponseImplToJson(
        _$WMDecayResponseImpl instance) =>
    <String, dynamic>{
      'removed': instance.removed,
    };

_$BrowserActionResponseImpl _$$BrowserActionResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BrowserActionResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BrowserActionResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          content: $checkedConvert('content', (v) => v as String?),
          url: $checkedConvert('url', (v) => v as String?),
          screenshotPath:
              $checkedConvert('screenshot_path', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'screenshotPath': 'screenshot_path'},
    );

Map<String, dynamic> _$$BrowserActionResponseImplToJson(
    _$BrowserActionResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('content', instance.content);
  writeNotNull('url', instance.url);
  writeNotNull('screenshot_path', instance.screenshotPath);
  writeNotNull('error', instance.error);
  return val;
}

_$SandboxExecuteResponseImpl _$$SandboxExecuteResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$SandboxExecuteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$SandboxExecuteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          output: $checkedConvert('output', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
          exitCode: $checkedConvert('exit_code', (v) => (v as num?)?.toInt()),
          executionTimeMs: $checkedConvert(
              'execution_time_ms', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'exitCode': 'exit_code',
        'executionTimeMs': 'execution_time_ms'
      },
    );

Map<String, dynamic> _$$SandboxExecuteResponseImplToJson(
    _$SandboxExecuteResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('output', instance.output);
  writeNotNull('error', instance.error);
  writeNotNull('exit_code', instance.exitCode);
  writeNotNull('execution_time_ms', instance.executionTimeMs);
  return val;
}

_$MissionListResponseImpl _$$MissionListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$MissionListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$MissionListResponseImpl(
          missions: $checkedConvert(
              'missions',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      MissionInfo.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$MissionListResponseImplToJson(
        _$MissionListResponseImpl instance) =>
    <String, dynamic>{
      'missions': instance.missions,
    };

_$BusinessAnalyzeResponseImpl _$$BusinessAnalyzeResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$BusinessAnalyzeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BusinessAnalyzeResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          missionId: $checkedConvert('mission_id', (v) => v as String),
          objectiveId: $checkedConvert('objective_id', (v) => v as String),
          objectiveDesc: $checkedConvert('objective_desc', (v) => v as String),
          agentResponses: $checkedConvert(
              'agent_responses', (v) => Map<String, String>.from(v as Map)),
          combinedSummary:
              $checkedConvert('combined_summary', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'missionId': 'mission_id',
        'objectiveId': 'objective_id',
        'objectiveDesc': 'objective_desc',
        'agentResponses': 'agent_responses',
        'combinedSummary': 'combined_summary',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$$BusinessAnalyzeResponseImplToJson(
        _$BusinessAnalyzeResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mission_id': instance.missionId,
      'objective_id': instance.objectiveId,
      'objective_desc': instance.objectiveDesc,
      'agent_responses': instance.agentResponses,
      'combined_summary': instance.combinedSummary,
      'created_at': instance.createdAt,
    };

_$BusinessReportsListResponseImpl _$$BusinessReportsListResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$BusinessReportsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BusinessReportsListResponseImpl(
          reports: $checkedConvert(
              'reports',
              (v) => (v as List<dynamic>)
                  .map((e) => BusinessReportSummary.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          count: $checkedConvert('count', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BusinessReportsListResponseImplToJson(
        _$BusinessReportsListResponseImpl instance) =>
    <String, dynamic>{
      'reports': instance.reports,
      'count': instance.count,
    };

_$BusinessReportDetailResponseImpl _$$BusinessReportDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$BusinessReportDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BusinessReportDetailResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          missionId: $checkedConvert('mission_id', (v) => v as String),
          objectiveId: $checkedConvert('objective_id', (v) => v as String),
          objectiveDesc: $checkedConvert('objective_desc', (v) => v as String),
          agentResponses: $checkedConvert(
              'agent_responses', (v) => Map<String, String>.from(v as Map)),
          combinedSummary:
              $checkedConvert('combined_summary', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'missionId': 'mission_id',
        'objectiveId': 'objective_id',
        'objectiveDesc': 'objective_desc',
        'agentResponses': 'agent_responses',
        'combinedSummary': 'combined_summary',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$$BusinessReportDetailResponseImplToJson(
        _$BusinessReportDetailResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mission_id': instance.missionId,
      'objective_id': instance.objectiveId,
      'objective_desc': instance.objectiveDesc,
      'agent_responses': instance.agentResponses,
      'combined_summary': instance.combinedSummary,
      'created_at': instance.createdAt,
    };

_$PublishProposeResponseImpl _$$PublishProposeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$PublishProposeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PublishProposeResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          siteName: $checkedConvert('site_name', (v) => v as String),
          filesJson: $checkedConvert('files_json', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          approver: $checkedConvert('approver', (v) => v as String),
          resultUrl: $checkedConvert('result_url', (v) => v as String),
          error: $checkedConvert('error', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
          decidedAt:
              $checkedConvert('decided_at', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'siteName': 'site_name',
        'filesJson': 'files_json',
        'resultUrl': 'result_url',
        'createdAt': 'created_at',
        'decidedAt': 'decided_at'
      },
    );

Map<String, dynamic> _$$PublishProposeResponseImplToJson(
    _$PublishProposeResponseImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'site_name': instance.siteName,
    'files_json': instance.filesJson,
    'description': instance.description,
    'action': instance.action,
    'approver': instance.approver,
    'result_url': instance.resultUrl,
    'error': instance.error,
    'created_at': instance.createdAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('decided_at', instance.decidedAt);
  return val;
}

_$PublishHistoryListResponseImpl _$$PublishHistoryListResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$PublishHistoryListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PublishHistoryListResponseImpl(
          proposals: $checkedConvert(
              'proposals',
              (v) => (v as List<dynamic>)
                  .map((e) => PublishHistoryItem.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$PublishHistoryListResponseImplToJson(
        _$PublishHistoryListResponseImpl instance) =>
    <String, dynamic>{
      'proposals': instance.proposals,
    };

_$PublishHistoryDetailResponseImpl _$$PublishHistoryDetailResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$PublishHistoryDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PublishHistoryDetailResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          siteName: $checkedConvert('site_name', (v) => v as String),
          filesJson: $checkedConvert('files_json', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          approver: $checkedConvert('approver', (v) => v as String),
          resultUrl: $checkedConvert('result_url', (v) => v as String),
          error: $checkedConvert('error', (v) => v as String),
          riskLevel: $checkedConvert('risk_level', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => (v as num).toDouble()),
          decidedAt:
              $checkedConvert('decided_at', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'siteName': 'site_name',
        'filesJson': 'files_json',
        'resultUrl': 'result_url',
        'riskLevel': 'risk_level',
        'createdAt': 'created_at',
        'decidedAt': 'decided_at'
      },
    );

Map<String, dynamic> _$$PublishHistoryDetailResponseImplToJson(
    _$PublishHistoryDetailResponseImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'site_name': instance.siteName,
    'files_json': instance.filesJson,
    'description': instance.description,
    'action': instance.action,
    'approver': instance.approver,
    'result_url': instance.resultUrl,
    'error': instance.error,
    'risk_level': instance.riskLevel,
    'created_at': instance.createdAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('decided_at', instance.decidedAt);
  return val;
}

_$PublishDecideResponseImpl _$$PublishDecideResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$PublishDecideResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$PublishDecideResponseImpl(
          status: $checkedConvert('status', (v) => v as String),
          siteName: $checkedConvert('site_name', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String),
          proposalId: $checkedConvert('proposal_id', (v) => v as String),
          riskLevel: $checkedConvert('risk_level', (v) => v as String),
          autoApplied: $checkedConvert('auto_applied', (v) => v as bool?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'siteName': 'site_name',
        'proposalId': 'proposal_id',
        'riskLevel': 'risk_level',
        'autoApplied': 'auto_applied'
      },
    );

Map<String, dynamic> _$$PublishDecideResponseImplToJson(
    _$PublishDecideResponseImpl instance) {
  final val = <String, dynamic>{
    'status': instance.status,
    'site_name': instance.siteName,
    'url': instance.url,
    'proposal_id': instance.proposalId,
    'risk_level': instance.riskLevel,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('auto_applied', instance.autoApplied);
  writeNotNull('error', instance.error);
  return val;
}

_$ApprovalRequestResponseImpl _$$ApprovalRequestResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ApprovalRequestResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ApprovalRequestResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String),
          riskLevel: $checkedConvert('risk_level', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          createdAt: $checkedConvert('created_at', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'riskLevel': 'risk_level', 'createdAt': 'created_at'},
    );

Map<String, dynamic> _$$ApprovalRequestResponseImplToJson(
        _$ApprovalRequestResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'reason': instance.reason,
      'risk_level': instance.riskLevel,
      'status': instance.status,
      'created_at': instance.createdAt,
    };

_$ApprovalsListResponseImpl _$$ApprovalsListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ApprovalsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ApprovalsListResponseImpl(
          approvals: $checkedConvert(
              'approvals',
              (v) => (v as List<dynamic>)
                  .map((e) => ApprovalItem.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ApprovalsListResponseImplToJson(
        _$ApprovalsListResponseImpl instance) =>
    <String, dynamic>{
      'approvals': instance.approvals,
    };

_$ApprovalDecideResponseImpl _$$ApprovalDecideResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ApprovalDecideResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ApprovalDecideResponseImpl(
          id: $checkedConvert('id', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String),
          riskLevel: $checkedConvert('risk_level', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          taskId: $checkedConvert('task_id', (v) => v as String),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          decidedAt: $checkedConvert('decided_at', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'riskLevel': 'risk_level',
        'taskId': 'task_id',
        'createdAt': 'created_at',
        'decidedAt': 'decided_at'
      },
    );

Map<String, dynamic> _$$ApprovalDecideResponseImplToJson(
        _$ApprovalDecideResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'reason': instance.reason,
      'risk_level': instance.riskLevel,
      'status': instance.status,
      'task_id': instance.taskId,
      'created_at': instance.createdAt,
      'decided_at': instance.decidedAt,
    };

_$ApprovalModeResponseImpl _$$ApprovalModeResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ApprovalModeResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ApprovalModeResponseImpl(
          mode: $checkedConvert('mode', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ApprovalModeResponseImplToJson(
        _$ApprovalModeResponseImpl instance) =>
    <String, dynamic>{
      'mode': instance.mode,
    };

_$ProvisionerSearchResponseImpl _$$ProvisionerSearchResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProvisionerSearchResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProvisionerSearchResponseImpl(
          report: $checkedConvert('report', (v) => v as String),
          findingsCount:
              $checkedConvert('findings_count', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'findingsCount': 'findings_count'},
    );

Map<String, dynamic> _$$ProvisionerSearchResponseImplToJson(
        _$ProvisionerSearchResponseImpl instance) =>
    <String, dynamic>{
      'report': instance.report,
      'findings_count': instance.findingsCount,
    };

_$ProvisionerProvisionResponseImpl _$$ProvisionerProvisionResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProvisionerProvisionResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProvisionerProvisionResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          provider: $checkedConvert('provider', (v) => v as String),
          apiKey: $checkedConvert('api_key', (v) => v as String?),
          envVar: $checkedConvert('env_var', (v) => v as String?),
          validated: $checkedConvert('validated', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'apiKey': 'api_key', 'envVar': 'env_var'},
    );

Map<String, dynamic> _$$ProvisionerProvisionResponseImplToJson(
    _$ProvisionerProvisionResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'provider': instance.provider,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('api_key', instance.apiKey);
  writeNotNull('env_var', instance.envVar);
  val['validated'] = instance.validated;
  val['message'] = instance.message;
  return val;
}

_$ProvisionerAuditResponseImpl _$$ProvisionerAuditResponseImplFromJson(
        Map json) =>
    $checkedCreate(
      r'_$ProvisionerAuditResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ProvisionerAuditResponseImpl(
          entries: $checkedConvert(
              'entries',
              (v) => (v as List<dynamic>)
                  .map((e) => ProvisionerAuditEntry.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProvisionerAuditResponseImplToJson(
        _$ProvisionerAuditResponseImpl instance) =>
    <String, dynamic>{
      'entries': instance.entries,
    };

_$ProvisionerAuditEntryImpl _$$ProvisionerAuditEntryImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ProvisionerAuditEntryImpl',
      json,
      ($checkedConvert) {
        final val = _$ProvisionerAuditEntryImpl(
          id: $checkedConvert('id', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          timestamp: $checkedConvert('timestamp', (v) => v as String),
          provider: $checkedConvert('provider', (v) => v as String?),
          result: $checkedConvert('result', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ProvisionerAuditEntryImplToJson(
    _$ProvisionerAuditEntryImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'action': instance.action,
    'status': instance.status,
    'timestamp': instance.timestamp,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('provider', instance.provider);
  writeNotNull('result', instance.result);
  return val;
}

_$EmailToolResponseImpl _$$EmailToolResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$EmailToolResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$EmailToolResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String),
          configured: $checkedConvert('configured', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$EmailToolResponseImplToJson(
    _$EmailToolResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'message': instance.message,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('configured', instance.configured);
  return val;
}

_$WebhookToolResponseImpl _$$WebhookToolResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$WebhookToolResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$WebhookToolResponseImpl(
          ok: $checkedConvert('ok', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String),
          configured: $checkedConvert('configured', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$WebhookToolResponseImplToJson(
    _$WebhookToolResponseImpl instance) {
  final val = <String, dynamic>{
    'ok': instance.ok,
    'message': instance.message,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('configured', instance.configured);
  return val;
}

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

_$TaskStreamEventImpl _$$TaskStreamEventImplFromJson(Map json) =>
    $checkedCreate(
      r'_$TaskStreamEventImpl',
      json,
      ($checkedConvert) {
        final val = _$TaskStreamEventImpl(
          type: $checkedConvert('type', (v) => v as String),
          taskId: $checkedConvert('task_id', (v) => v as String?),
          sessionId: $checkedConvert('session_id', (v) => v as String?),
          status: $checkedConvert('status', (v) => v as String?),
          currentStep:
              $checkedConvert('current_step', (v) => (v as num?)?.toInt()),
          goal: $checkedConvert('goal', (v) => v as String?),
          stepId: $checkedConvert('step_id', (v) => v as String?),
          stepName: $checkedConvert('step_name', (v) => v as String?),
          stepDescription:
              $checkedConvert('step_description', (v) => v as String?),
          agentName: $checkedConvert('agent_name', (v) => v as String?),
          toolName: $checkedConvert('tool_name', (v) => v as String?),
          toolStatus: $checkedConvert('tool_status', (v) => v as String?),
          toolResult: $checkedConvert('tool_result', (v) => v as String?),
          llmToken: $checkedConvert('llm_token', (v) => v as String?),
          verificationStatus:
              $checkedConvert('verification_status', (v) => v as String?),
          memoryAction: $checkedConvert('memory_action', (v) => v as String?),
          skillName: $checkedConvert('skill_name', (v) => v as String?),
          confidence:
              $checkedConvert('confidence', (v) => (v as num?)?.toDouble()),
          progress: $checkedConvert('progress', (v) => (v as num?)?.toDouble()),
          message: $checkedConvert('message', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
          timestamp:
              $checkedConvert('timestamp', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'taskId': 'task_id',
        'sessionId': 'session_id',
        'currentStep': 'current_step',
        'stepId': 'step_id',
        'stepName': 'step_name',
        'stepDescription': 'step_description',
        'agentName': 'agent_name',
        'toolName': 'tool_name',
        'toolStatus': 'tool_status',
        'toolResult': 'tool_result',
        'llmToken': 'llm_token',
        'verificationStatus': 'verification_status',
        'memoryAction': 'memory_action',
        'skillName': 'skill_name'
      },
    );

Map<String, dynamic> _$$TaskStreamEventImplToJson(
    _$TaskStreamEventImpl instance) {
  final val = <String, dynamic>{
    'type': instance.type,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('task_id', instance.taskId);
  writeNotNull('session_id', instance.sessionId);
  writeNotNull('status', instance.status);
  writeNotNull('current_step', instance.currentStep);
  writeNotNull('goal', instance.goal);
  writeNotNull('step_id', instance.stepId);
  writeNotNull('step_name', instance.stepName);
  writeNotNull('step_description', instance.stepDescription);
  writeNotNull('agent_name', instance.agentName);
  writeNotNull('tool_name', instance.toolName);
  writeNotNull('tool_status', instance.toolStatus);
  writeNotNull('tool_result', instance.toolResult);
  writeNotNull('llm_token', instance.llmToken);
  writeNotNull('verification_status', instance.verificationStatus);
  writeNotNull('memory_action', instance.memoryAction);
  writeNotNull('skill_name', instance.skillName);
  writeNotNull('confidence', instance.confidence);
  writeNotNull('progress', instance.progress);
  writeNotNull('message', instance.message);
  writeNotNull('error', instance.error);
  writeNotNull('timestamp', instance.timestamp);
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

_$LearnCompleteResponseImpl _$$LearnCompleteResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$LearnCompleteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LearnCompleteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          result: $checkedConvert('result', (v) => v as String),
          learned: $checkedConvert('learned', (v) => v as bool),
          skillHints: $checkedConvert('skill_hints', (v) => v as String?),
          researchFindings:
              $checkedConvert('research_findings', (v) => v as String?),
          sandboxVerified:
              $checkedConvert('sandbox_verified', (v) => v as bool?),
          testCode: $checkedConvert('test_code', (v) => v as String?),
          riskLevel: $checkedConvert('risk_level', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'skillHints': 'skill_hints',
        'researchFindings': 'research_findings',
        'sandboxVerified': 'sandbox_verified',
        'testCode': 'test_code',
        'riskLevel': 'risk_level'
      },
    );

Map<String, dynamic> _$$LearnCompleteResponseImplToJson(
    _$LearnCompleteResponseImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
    'result': instance.result,
    'learned': instance.learned,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('skill_hints', instance.skillHints);
  writeNotNull('research_findings', instance.researchFindings);
  writeNotNull('sandbox_verified', instance.sandboxVerified);
  writeNotNull('test_code', instance.testCode);
  writeNotNull('risk_level', instance.riskLevel);
  writeNotNull('error', instance.error);
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

_$AutonomousStatusImpl _$$AutonomousStatusImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AutonomousStatusImpl',
      json,
      ($checkedConvert) {
        final val = _$AutonomousStatusImpl(
          enabled: $checkedConvert('enabled', (v) => v as bool),
          running: $checkedConvert('running', (v) => v as bool),
          mission: $checkedConvert('mission', (v) => v as String?),
          currentObjective:
              $checkedConvert('current_objective', (v) => v as String?),
          cycleCount:
              $checkedConvert('cycle_count', (v) => (v as num?)?.toInt()),
          lastCycleAt:
              $checkedConvert('last_cycle_at', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'currentObjective': 'current_objective',
        'cycleCount': 'cycle_count',
        'lastCycleAt': 'last_cycle_at'
      },
    );

Map<String, dynamic> _$$AutonomousStatusImplToJson(
    _$AutonomousStatusImpl instance) {
  final val = <String, dynamic>{
    'enabled': instance.enabled,
    'running': instance.running,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('mission', instance.mission);
  writeNotNull('current_objective', instance.currentObjective);
  writeNotNull('cycle_count', instance.cycleCount);
  writeNotNull('last_cycle_at', instance.lastCycleAt);
  return val;
}

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
