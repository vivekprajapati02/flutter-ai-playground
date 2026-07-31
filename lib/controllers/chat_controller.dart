import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../services/history_service.dart';
import '../services/tool_service.dart';

class ChatController extends GetxController {
  final ChatService _chatService = ChatService();
  final ToolService _toolService = ToolService();
  final HistoryService _historyService = HistoryService();
  final SpeechToText _speech = SpeechToText();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isStreaming = false.obs;
  final RxBool isImageMode = false.obs;
  final RxBool useTools = true.obs;
  final RxBool isListening = false.obs;
  final RxBool speechAvailable = false.obs;

  String? _conversationId;
  String _conversationTitle = 'New Chat';
  CancelToken? _streamCancelToken;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          isListening.value = false;
          Get.snackbar(
            'Error',
            'Speech recognition error: ${error.errorMsg}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );
      speechAvailable.value = available;
    } catch (_) {
      speechAvailable.value = false;
    }
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      isListening.value = false;
    }
  }

  /// Toggles voice input on/off. Tap once to start listening, tap again
  /// (or the app auto-stops on silence) to finish and keep the transcript.
  Future<void> toggleListening() async {
    if (isListening.value) {
      await stopListening();
      return;
    }
    await startListening();
  }

  Future<void> startListening() async {
    if (isLoading.value || isListening.value) return;

    // Speech plugin may report unavailable until (re)initialized, e.g. if
    // the microphone permission was only just granted by the OS.
    if (!speechAvailable.value) {
      await _initSpeech();
    }
    if (!speechAvailable.value) {
      Get.snackbar(
        'Voice input unavailable',
        'Speech recognition is not available on this device. Check microphone permission in system settings.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final existingText = textController.text;
    isListening.value = true;
    final started = await _speech.listen(
      onResult: (result) {
        final transcript = result.recognizedWords;
        textController.text = existingText.isEmpty
            ? transcript
            : '$existingText $transcript';
        textController.selection = TextSelection.fromPosition(
          TextPosition(offset: textController.text.length),
        );
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
    if (!started) {
      isListening.value = false;
      Get.snackbar(
        'Voice input unavailable',
        'Could not start speech recognition.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> stopListening() async {
    if (!isListening.value) return;
    await _speech.stop();
    isListening.value = false;
  }

  void toggleImageMode() {
    isImageMode.value = !isImageMode.value;
  }

  void toggleUseTools() {
    useTools.value = !useTools.value;
  }

  /// Called by HistoryPage when resuming a saved conversation.
  void loadConversation(Conversation conversation) {
    _conversationId = conversation.id;
    _conversationTitle = conversation.title;
    messages.assignAll(conversation.messages);
    _scrollToBottom();
  }

  /// Starts a fresh, unsaved conversation.
  void startNewChat() {
    _conversationId = null;
    _conversationTitle = 'New Chat';
    messages.clear();
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isLoading.value) return;

    if (isImageMode.value) {
      await _sendImagePrompt(text);
    } else if (useTools.value) {
      await _sendChatMessageWithTools(text);
    } else {
      await _sendChatMessageStreaming(text);
    }
  }

  Future<void> _sendChatMessageWithTools(String text) async {
    final userMessage = ChatMessage(content: text, role: ChatRole.user);
    messages.add(userMessage);
    textController.clear();
    _scrollToBottom();

    isLoading.value = true;
    try {
      final result = await _chatService.sendMessageWithTools(
        messages.toList(),
        _toolService,
      );
      messages.addAll(result.toolMessages);
      messages.add(result.finalMessage);
      await _autoSaveConversation();
    } on ChatServiceException catch (e) {
      messages.add(
        ChatMessage(content: e.message, role: ChatRole.assistant, isError: true),
      );
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      final msg = 'Unexpected error: $e';
      messages.add(
        ChatMessage(content: msg, role: ChatRole.assistant, isError: true),
      );
      Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  Future<void> _sendChatMessageStreaming(String text) async {
    final userMessage = ChatMessage(content: text, role: ChatRole.user);
    messages.add(userMessage);
    textController.clear();
    _scrollToBottom();

    final placeholderIndex = messages.length;
    messages.add(
      ChatMessage(content: '', role: ChatRole.assistant, isStreaming: true),
    );

    isLoading.value = true;
    isStreaming.value = true;
    _streamCancelToken = CancelToken();

    final buffer = StringBuffer();
    try {
      await for (final delta in _chatService.sendMessageStream(
        messages.sublist(0, placeholderIndex),
        cancelToken: _streamCancelToken,
      )) {
        buffer.write(delta);
        messages[placeholderIndex] = messages[placeholderIndex].copyWith(
          content: buffer.toString(),
        );
      }
      messages[placeholderIndex] = messages[placeholderIndex].copyWith(
        content: buffer.toString(),
        isStreaming: false,
      );
      await _autoSaveConversation();
    } on ChatServiceException catch (e) {
      messages[placeholderIndex] = messages[placeholderIndex].copyWith(
        content: buffer.isEmpty ? e.message : buffer.toString(),
        isError: buffer.isEmpty,
        isStreaming: false,
      );
      if (buffer.isEmpty) {
        Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        messages[placeholderIndex] = messages[placeholderIndex].copyWith(
          isStreaming: false,
        );
      } else {
        messages[placeholderIndex] = messages[placeholderIndex].copyWith(
          content: buffer.isEmpty ? 'Unexpected error: $e' : buffer.toString(),
          isError: buffer.isEmpty,
          isStreaming: false,
        );
      }
    } finally {
      isLoading.value = false;
      isStreaming.value = false;
      _streamCancelToken = null;
      _scrollToBottom();
    }
  }

  void stopGenerating() {
    _streamCancelToken?.cancel('User stopped generation');
  }

  Future<void> _sendImagePrompt(String prompt) async {
    final userMessage = ChatMessage(content: prompt, role: ChatRole.user);
    messages.add(userMessage);
    textController.clear();
    _scrollToBottom();

    isLoading.value = true;
    try {
      final url = await _chatService.generateImage(prompt);
      messages.add(
        ChatMessage(content: prompt, role: ChatRole.assistant, imageUrl: url),
      );
      await _autoSaveConversation();
    } on ChatServiceException catch (e) {
      messages.add(
        ChatMessage(content: e.message, role: ChatRole.assistant, isError: true),
      );
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      final msg = 'Unexpected error: $e';
      messages.add(
        ChatMessage(content: msg, role: ChatRole.assistant, isError: true),
      );
      Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  Future<void> _autoSaveConversation() async {
    final id = _conversationId ??= DateTime.now().microsecondsSinceEpoch.toString();
    final existing = _historyService.getById(id);
    final userMessages = messages.where((m) => m.isUser);
    final firstUserMessage = userMessages.isEmpty ? null : userMessages.first;
    final conversation =
        existing ??
        Conversation(
          id: id,
          title: _conversationTitle == 'New Chat' && firstUserMessage != null
              ? _deriveTitle(firstUserMessage.content)
              : _conversationTitle,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    conversation.messages = messages.toList();
    await _historyService.save(conversation);
  }

  String _deriveTitle(String firstUserText) =>
      firstUserText.length > 40 ? '${firstUserText.substring(0, 40)}...' : firstUserText;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    _speech.stop();
    _speech.cancel();
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
