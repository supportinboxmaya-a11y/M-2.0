import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'extended_projects_models.dart';

final extendedProjectsProvider =
    FutureProvider<ExtendedProjectsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/extended/memory/projects');
  return ExtendedProjectsResponse.fromJson(response);
});
