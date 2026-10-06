import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'extended_tasks_models.dart';

final extendedTasksProvider =
    FutureProvider<ExtendedTasksResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/extended/tasks');
  return ExtendedTasksResponse.fromJson(response);
});
