import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';

class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  /// Tool-call plumbing messages (assistant tool-call requests, plain tool
  /// results) are kept in the transcript for the API/Hive but hidden from
  /// the visible chat list unless they carry a payload worth showing (QR /
  /// GitHub card).
  bool _isVisible(ChatMessage message) {
    if (message.role == ChatRole.tool) {
      return message.isQr || message.isGithubCard;
    }
    if (message.toolCalls != null && message.toolCalls!.isNotEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('AI Chat'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final visible = controller.messages.where(_isVisible).toList();
                return ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: visible[index]);
                  },
                );
              }),
            ),
            Obx(
              () => controller.isLoading.value
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.isImageMode.value
                                ? 'Generating image...'
                                : controller.isStreaming.value
                                ? 'Streaming...'
                                : 'Assistant is typing...',
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const Divider(height: 1),
            _buildInputRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Obx(
            () => IconButton(
              onPressed: controller.toggleImageMode,
              tooltip: controller.isImageMode.value
                  ? 'Switch to chat mode'
                  : 'Switch to image generation mode',
              icon: Icon(
                Icons.image_outlined,
                color: controller.isImageMode.value
                    ? colorScheme.primary
                    : null,
              ),
              style: IconButton.styleFrom(
                backgroundColor: controller.isImageMode.value
                    ? colorScheme.primaryContainer
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Obx(
            () => IconButton(
              onPressed: controller.toggleUseTools,
              tooltip: controller.useTools.value
                  ? 'Tools enabled (tap to disable)'
                  : 'Tools disabled (tap to enable)',
              icon: Icon(
                Icons.build_outlined,
                color: controller.useTools.value ? colorScheme.primary : null,
              ),
              style: IconButton.styleFrom(
                backgroundColor: controller.useTools.value
                    ? colorScheme.primaryContainer
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => TextField(
                controller: controller.textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendMessage(),
                decoration: InputDecoration(
                  hintText: controller.isImageMode.value
                      ? 'Describe an image to generate...'
                      : 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  suffixIcon: _buildMicButton(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => controller.isStreaming.value
                ? IconButton.filled(
                    onPressed: controller.stopGenerating,
                    icon: const Icon(Icons.stop),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  )
                : IconButton.filled(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.sendMessage,
                    icon: Icon(
                      controller.isImageMode.value
                          ? Icons.auto_awesome
                          : Icons.send,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(
      () => IconButton(
        onPressed: controller.toggleListening,
        tooltip: controller.isListening.value
            ? 'Listening... tap to stop'
            : 'Tap to speak',
        icon: Icon(
          controller.isListening.value ? Icons.mic : Icons.mic_none,
          color: controller.isListening.value ? colorScheme.error : null,
        ),
      ),
    );
  }
}
