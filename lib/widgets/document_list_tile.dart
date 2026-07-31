import 'package:flutter/material.dart';

import '../models/rag_document.dart';

class DocumentListTile extends StatelessWidget {
  final RagDocument document;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const DocumentListTile({
    super.key,
    required this.document,
    required this.onDelete,
    this.onTap,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          'This will permanently delete "${document.filename}" and its index.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        title: Text(document.filename, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${document.pageCount} pages · ${document.chunkCount} chunks · ${_formatDate(document.createdAt)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete document',
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }
}
