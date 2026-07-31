import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import 'github_profile_card.dart';
import 'qr_result_card.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;

    final bubbleColor = message.isError
        ? colorScheme.errorContainer
        : isUser
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest;

    final textColor = message.isError
        ? colorScheme.onErrorContainer
        : isUser
            ? colorScheme.onPrimary
            : colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: message.isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Failed to load image'),
                  ),
                ),
              )
            : message.isQr
            ? QrResultCard(data: message.qrData!)
            : message.isGithubCard
            ? GithubProfileCard(profile: message.githubProfile!)
            : Text(
                message.isStreaming ? '${message.content}▍' : message.content,
                style: TextStyle(color: textColor, fontSize: 15),
              ),
      ),
    );
  }
}
