import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/app_config.dart';
import 'api_service.dart';

final mayaApiProvider = Provider<MayaApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MayaApi(apiService.dio);
});

class MayaApi {
  final Dio _dio;

  MayaApi(this._dio);

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(
      path,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteJson(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postFormData(String path,
      {required Map<String, dynamic> data}) async {
    final formData = FormData.fromMap(data);
    final response = await _dio.post(
      path,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return response.data as Map<String, dynamic>;
  }
}
