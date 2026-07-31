import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/rag_document.dart';
import '../models/rag_message.dart';
import '../models/rag_source.dart';

class RagServiceException implements Exception {
  final String message;
  RagServiceException(this.message);

  @override
  String toString() => message;
}

class RagService {
  late final Dio _dio;

  RagService({required String baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          responseHeader: true,
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint('[RAG] $obj'),
        ),
      );
    }
  }

  Future<List<RagDocument>> listDocuments() async {
    try {
      final response = await _dio.get('/documents');
      // Backend wraps the array as {"documents": [...], "total": N}.
      final raw = response.data;
      final data = raw is Map ? raw['documents'] as List<dynamic> : raw as List<dynamic>;
      return data
          .map((e) => RagDocument.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw RagServiceException(_mapDioError(e));
    }
  }

  Future<RagDocument> uploadDocument(
    String filePath, {
    void Function(double progress)? onProgress,
  }) async {
    final filename = filePath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    try {
      final response = await _dio.post(
        '/documents/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      return RagDocument.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw RagServiceException(_mapDioError(e));
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _dio.delete('/documents/$documentId');
    } on DioException catch (e) {
      throw RagServiceException(_mapDioError(e));
    }
  }

  Future<RagMessage> ask(String question, {String? documentId}) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {
          'question': question,
          if (documentId != null) 'document_id': documentId,
        },
      );
      final data = response.data as Map<String, dynamic>;
      // NOTE: exact response field names ("answer" vs "response"/"result")
      // are unverified against the real backend — adjust once confirmed.
      final answer = data['answer'] as String? ?? '';
      final sourcesJson = data['sources'] as List<dynamic>? ?? [];
      final sources = sourcesJson
          .map((e) => RagSource.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return RagMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: answer.trim().isEmpty ? '(no answer returned)' : answer.trim(),
        isUser: false,
        sources: sources,
      );
    } on DioException catch (e) {
      throw RagServiceException(_mapDioError(e));
    }
  }

  /// Used by "Test connection" in Settings — returns false rather than
  /// throwing, since the caller only needs a boolean success state.
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException {
      return false;
    }
  }

  String _mapDioError(DioException e) {
    final message = _resolveDioErrorMessage(e);
    if (kDebugMode) {
      debugPrint(
        '[RAG] *** Mapped error ***\n'
        '[RAG] request: ${e.requestOptions.method} ${e.requestOptions.uri}\n'
        '[RAG] statusCode: ${e.response?.statusCode}\n'
        '[RAG] dioErrorType: ${e.type}\n'
        '[RAG] rawMessage: ${e.message}\n'
        '[RAG] responseBody: ${e.response?.data}\n'
        '[RAG] shownToUser: $message',
      );
    }
    return message;
  }

  String _resolveDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. The backend may be slow or unreachable.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the backend. Check the base URL in Settings and that the server is running.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        String? apiMessage;
        if (data is Map && data['detail'] != null) {
          apiMessage = data['detail'] is String
              ? data['detail'] as String
              : data['detail'].toString();
        }
        if (status == 429) {
          return 'Rate limit exceeded. Please wait and try again.';
        }
        if (status == 404) {
          return apiMessage ?? 'Not found.';
        }
        return apiMessage ?? 'Backend returned an error (status $status).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'Something went wrong: ${e.message}';
    }
  }
}
