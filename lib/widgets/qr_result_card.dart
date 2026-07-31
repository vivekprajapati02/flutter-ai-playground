import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrResultCard extends StatelessWidget {
  final String data;
  const QrResultCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QrImageView(data: data, size: 180, backgroundColor: Colors.white),
        const SizedBox(height: 8),
        Text(data, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
