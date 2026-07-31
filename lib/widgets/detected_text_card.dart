import 'package:flutter/material.dart';

class DetectedTextCard extends StatelessWidget {
  final String text;
  final VoidCallback onCopy;

  const DetectedTextCard({
    super.key,
    required this.text,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Extracted text',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Copy to clipboard',
                  onPressed: onCopy,
                ),
              ],
            ),
            const Divider(),
            SelectableText(text, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
