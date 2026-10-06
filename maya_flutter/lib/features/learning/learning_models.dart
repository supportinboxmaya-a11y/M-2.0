class FeedbackStats {
  final int total;
  final int positive;
  final int negative;
  final double? satisfaction;

  FeedbackStats({
    required this.total,
    required this.positive,
    required this.negative,
    this.satisfaction,
  });

  factory FeedbackStats.fromJson(Map<String, dynamic> json) {
    return FeedbackStats(
      total: json['total'] as int? ?? 0,
      positive: json['positive'] as int? ?? 0,
      negative: json['negative'] as int? ?? 0,
      satisfaction: (json['satisfaction'] as num?)?.toDouble(),
    );
  }
}

class Lesson {
  final double ts;
  final String goal;
  final String comment;

  Lesson({
    required this.ts,
    required this.goal,
    required this.comment,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      ts: (json['ts'] as num?)?.toDouble() ?? 0.0,
      goal: json['goal'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
    );
  }
}

class LearningStatsResponse {
  final FeedbackStats feedback;
  final List<Lesson> lessons;
  final Map<String, dynamic> prompts;

  LearningStatsResponse({
    required this.feedback,
    required this.lessons,
    required this.prompts,
  });

  factory LearningStatsResponse.fromJson(Map<String, dynamic> json) {
    return LearningStatsResponse(
      feedback: FeedbackStats.fromJson(
          json['feedback'] as Map<String, dynamic>? ?? {}),
      lessons: (json['lessons'] as List<dynamic>? ?? [])
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
      prompts: json['prompts'] as Map<String, dynamic>? ?? {},
    );
  }
}

class ExperienceEpisode {
  final int id;
  final double ts;
  final String goal;
  final List<dynamic> steps;
  final String outcome;
  final double confidence;
  final double? similarity;

  ExperienceEpisode({
    required this.id,
    required this.ts,
    required this.goal,
    required this.steps,
    required this.outcome,
    required this.confidence,
    this.similarity,
  });

  factory ExperienceEpisode.fromJson(Map<String, dynamic> json) {
    return ExperienceEpisode(
      id: json['id'] as int? ?? 0,
      ts: (json['ts'] as num?)?.toDouble() ?? 0.0,
      goal: json['goal'] as String? ?? '',
      steps: json['steps'] as List<dynamic>? ?? [],
      outcome: json['outcome'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      similarity: (json['similarity'] as num?)?.toDouble(),
    );
  }
}

class LearningExperienceResponse {
  final List<ExperienceEpisode>? similar;
  final List<ExperienceEpisode>? history;
  final Map<String, dynamic>? successRate;

  LearningExperienceResponse({
    this.similar,
    this.history,
    this.successRate,
  });

  factory LearningExperienceResponse.fromJson(Map<String, dynamic> json) {
    return LearningExperienceResponse(
      similar: (json['similar'] as List<dynamic>?)
          ?.map((e) => ExperienceEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
      history: (json['history'] as List<dynamic>?)
          ?.map((e) => ExperienceEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
      successRate: json['success_rate'] as Map<String, dynamic>?,
    );
  }
}

class LearningCompressResponse {
  final bool dryRun;
  final String memoryType;
  final Map<String, dynamic> result;

  LearningCompressResponse({
    required this.dryRun,
    required this.memoryType,
    required this.result,
  });

  factory LearningCompressResponse.fromJson(Map<String, dynamic> json) {
    return LearningCompressResponse(
      dryRun: json['dry_run'] as bool? ?? true,
      memoryType: json['memory_type'] as String? ?? 'chat',
      result: json['result'] as Map<String, dynamic>? ?? {},
    );
  }
}

class PromptVariant {
  final int ok;
  final int fail;
  final double score;

  PromptVariant({
    required this.ok,
    required this.fail,
    required this.score,
  });

  factory PromptVariant.fromJson(Map<String, dynamic> json) {
    return PromptVariant(
      ok: json['ok'] as int? ?? 0,
      fail: json['fail'] as int? ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LearningPromptsResponse {
  final Map<String, Map<String, PromptVariant>> prompts;

  LearningPromptsResponse({required this.prompts});

  factory LearningPromptsResponse.fromJson(Map<String, dynamic> json) {
    final promptsMap = json['prompts'] as Map<String, dynamic>? ?? {};
    return LearningPromptsResponse(
      prompts: promptsMap.map((k, v) => MapEntry(
            k,
            (v as Map<String, dynamic>).map((k2, v2) => MapEntry(
                  k2,
                  PromptVariant.fromJson(v2 as Map<String, dynamic>),
                )),
          )),
    );
  }
}
