import 'package:flutter/material.dart';

import '../models/rag_message.dart';
import '../models/rag_source.dart';
import 'rag_source_card.dart';

class RagMessageBubble extends StatelessWidget {
  final RagMessage message;
  final void Function(RagSource source) onSourceTap;

  const RagMessageBubble({
    super.key,
    required this.message,
    required this.onSourceTap,
  });

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
          maxWidth: MediaQuery.of(context).size.width * 0.8,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.content, style: TextStyle(color: textColor, fontSize: 15)),
            if (!isUser && message.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.sources
                    .map(
                      (source) => RagSourceCard(
                        source: source,
                        onTap: () => onSourceTap(source),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
