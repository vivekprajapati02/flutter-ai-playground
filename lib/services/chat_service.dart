import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/chat_message.dart';
import 'tool_service.dart';

class ChatServiceException implements Exception {
  final String message;
  ChatServiceException(this.message);

  @override
  String toString() => message;
}

class ChatToolLoopResult {
  final ChatMessage finalMessage;
  final List<ChatMessage> toolMessages;
  ChatToolLoopResult({required this.finalMessage, required this.toolMessages});
}

class ChatService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-5.4-mini';
  static const String _imageModel = 'dall-e-3';

  late final Dio _dio;

  ChatService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Sends the full conversation history and returns the assistant's reply text.
  Future<String> sendMessage(List<ChatMessage> history) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'sk-REPLACE_WITH_YOUR_KEY') {
      throw ChatServiceException(
        'Missing OpenAI API key. Add OPENAI_API_KEY to your .env file.',
      );
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _model,
          'messages': history.map((m) => m.toApiJson()).toList(),
          'temperature': 0.7,
        },
      );

      final choices = response.data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw ChatServiceException('No response returned from OpenAI.');
      }

      final content = choices.first['message']?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw ChatServiceException('Empty response from OpenAI.');
      }

      return content.trim();
    } on DioException catch (e) {
      throw ChatServiceException(_mapDioError(e));
    }
  }

  /// Streams assistant reply text deltas as they arrive via Server-Sent Events.
  Stream<String> sendMessageStream(
    List<ChatMessage> history, {
    CancelToken? cancelToken,
  }) async* {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'sk-REPLACE_WITH_YOUR_KEY') {
      throw ChatServiceException(
        'Missing OpenAI API key. Add OPENAI_API_KEY to your .env file.',
      );
    }

    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: {
          'model': _model,
          'messages': history.map((m) => m.toApiJson()).toList(),
          'temperature': 0.7,
          'stream': true,
        },
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ChatServiceException(_mapDioError(e));
    }

    var buffer = '';

    await for (final chunk in response.data!.stream) {
      buffer += utf8.decode(chunk, allowMalformed: true);

      // SSE frames are separated by a blank line ("\n\n"); a chunk can end
      // mid-line, so only process complete frames and keep the remainder.
      while (buffer.contains('\n\n')) {
        final idx = buffer.indexOf('\n\n');
        final frame = buffer.substring(0, idx);
        buffer = buffer.substring(idx + 2);

        for (final line in frame.split('\n')) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;
          final payload = trimmed.substring(5).trim();
          if (payload == '[DONE]') return;
          if (payload.isEmpty) continue;

          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) continue;
            final delta = choices.first['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {
            continue;
          }
        }
      }
    }
  }

  /// Sends an image generation prompt and returns the generated image URL.
  Future<String> generateImage(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'sk-REPLACE_WITH_YOUR_KEY') {
      throw ChatServiceException(
        'Missing OpenAI API key. Add OPENAI_API_KEY to your .env file.',
      );
    }

    try {
      final response = await _dio.post(
        '/images/generations',
        data: {
          'model': _imageModel,
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
        },
      );

      final data = response.data['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        throw ChatServiceException('No image returned from OpenAI.');
      }

      final url = data.first['url'] as String?;
      if (url == null || url.isEmpty) {
        throw ChatServiceException('Empty image URL from OpenAI.');
      }

      return url;
    } on DioException catch (e) {
      throw ChatServiceException(_mapDioError(e));
    }
  }

  static const List<Map<String, dynamic>> _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'open_camera',
        'description': 'Opens the device camera so the user can take a photo.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'open_gallery',
        'description':
            'Opens the device photo gallery so the user can pick an image.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'calculate_bmi',
        'description':
            'Calculates Body Mass Index (BMI) and category from weight and height.',
        'parameters': {
          'type': 'object',
          'properties': {
            'weight_kg': {
              'type': 'number',
              'description': 'Weight in kilograms',
            },
            'height_cm': {
              'type': 'number',
              'description': 'Height in centimeters',
            },
          },
          'required': ['weight_kg', 'height_cm'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'generate_qr_code',
        'description':
            'Generates a QR code image encoding the given text or URL.',
        'parameters': {
          'type': 'object',
          'properties': {
            'data': {
              'type': 'string',
              'description': 'The text or URL to encode',
            },
          },
          'required': ['data'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'convert_currency',
        'description':
            'Converts an amount from one currency to another using current exchange rates.',
        'parameters': {
          'type': 'object',
          'properties': {
            'amount': {'type': 'number'},
            'from': {
              'type': 'string',
              'description': 'ISO currency code, e.g. USD',
            },
            'to': {
              'type': 'string',
              'description': 'ISO currency code, e.g. EUR',
            },
          },
          'required': ['amount', 'from', 'to'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'fetch_github_profile',
        'description': 'Fetches a public GitHub user profile summary.',
        'parameters': {
          'type': 'object',
          'properties': {
            'username': {'type': 'string'},
          },
          'required': ['username'],
        },
      },
    },
  ];

  /// Full tool-calling round trip: sends history + tool schema, executes any
  /// requested tool calls locally via [toolService], feeds results back, and
  /// repeats until a plain assistant text reply is returned. This entire
  /// round trip is intentionally non-streaming — reassembling incrementally
  /// streamed tool-call argument fragments is not worth the complexity here.
  Future<ChatToolLoopResult> sendMessageWithTools(
    List<ChatMessage> history,
    ToolService toolService,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'sk-REPLACE_WITH_YOUR_KEY') {
      throw ChatServiceException(
        'Missing OpenAI API key. Add OPENAI_API_KEY to your .env file.',
      );
    }

    var workingHistory = List<ChatMessage>.from(history);
    final producedMessages = <ChatMessage>[];

    const maxRounds = 4;
    for (var round = 0; round < maxRounds; round++) {
      Map<String, dynamic> data;
      try {
        final response = await _dio.post(
          '/chat/completions',
          data: {
            'model': _model,
            'messages': workingHistory.map((m) => m.toApiJson()).toList(),
            'tools': _tools,
            'tool_choice': 'auto',
            'temperature': 0.7,
          },
        );
        data = response.data as Map<String, dynamic>;
      } on DioException catch (e) {
        throw ChatServiceException(_mapDioError(e));
      }

      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw ChatServiceException('No response returned from OpenAI.');
      }
      final choice = choices.first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>;
      final finishReason = choice['finish_reason'] as String?;
      final toolCalls = message['tool_calls'] as List<dynamic>?;

      if (finishReason == 'tool_calls' &&
          toolCalls != null &&
          toolCalls.isNotEmpty) {
        final assistantToolCallMsg = ChatMessage(
          content: (message['content'] as String?) ?? '',
          role: ChatRole.assistant,
          toolCalls: toolCalls
              .map((c) => Map<String, dynamic>.from(c as Map))
              .toList(),
        );
        workingHistory.add(assistantToolCallMsg);
        producedMessages.add(assistantToolCallMsg);

        for (final call in toolCalls) {
          final callMap = call as Map<String, dynamic>;
          final id = callMap['id'] as String;
          final fn = callMap['function'] as Map<String, dynamic>;
          final name = fn['name'] as String;
          final argsString = fn['arguments'] as String? ?? '{}';
          Map<String, dynamic> args;
          try {
            args = jsonDecode(argsString) as Map<String, dynamic>;
          } catch (_) {
            args = {};
          }

          final result = await toolService.executeTool(name, args);

          final toolResultMsg = ChatMessage(
            content: jsonEncode(result.data),
            role: ChatRole.tool,
            toolCallId: id,
            toolName: name,
            qrData: result.qrData,
            githubProfile: result.githubProfile,
          );
          workingHistory.add(toolResultMsg);
          producedMessages.add(toolResultMsg);
        }
        continue;
      }

      final content = message['content'] as String?;
      final finalMsg = ChatMessage(
        content: (content == null || content.trim().isEmpty)
            ? '(no additional text from the model)'
            : content.trim(),
        role: ChatRole.assistant,
      );
      return ChatToolLoopResult(
        finalMessage: finalMsg,
        toolMessages: producedMessages,
      );
    }

    throw ChatServiceException(
      'Tool call loop did not resolve after $maxRounds rounds.',
    );
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        String? apiMessage;
        if (data is Map && data['error'] is Map) {
          apiMessage = data['error']['message'] as String?;
        }
        if (status == 401) {
          return 'Invalid API key. Check OPENAI_API_KEY in your .env file.';
        }
        if (status == 429) {
          return 'Rate limit or quota exceeded. Please try again later.';
        }
        return apiMessage ?? 'OpenAI returned an error (status $status).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'Something went wrong: ${e.message}';
    }
  }
}
