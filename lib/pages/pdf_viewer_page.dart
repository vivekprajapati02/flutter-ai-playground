import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatefulWidget {
  final String documentId;
  final String baseUrl;
  final String? filename;
  final int? initialPage;

  const PdfViewerPage({
    super.key,
    required this.documentId,
    required this.baseUrl,
    this.filename,
    this.initialPage,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfController = PdfViewerController();
  bool _loadFailed = false;

  @override
  Widget build(BuildContext context) {
    // NOTE: no raw-PDF-bytes endpoint exists in the given backend contract
    // yet. This assumes the user will add something like
    // GET /documents/{document_id}/file returning application/pdf bytes.
    final url = '${widget.baseUrl}/documents/${widget.documentId}/file';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.filename ?? 'Document'),
      ),
      body: _loadFailed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'PDF preview unavailable',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Could not load the PDF from the backend. Make sure a raw-file '
                      'endpoint (e.g. GET /documents/{id}/file) is implemented.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          : SfPdfViewer.network(
              url,
              controller: _pdfController,
              onDocumentLoadFailed: (details) {
                setState(() => _loadFailed = true);
              },
              onDocumentLoaded: (details) {
                final page = widget.initialPage;
                if (page != null && page > 0 && page <= details.document.pages.count) {
                  _pdfController.jumpToPage(page);
                }
              },
            ),
    );
  }
}
