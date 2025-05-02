import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const PdfPreviewScreen({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Önizleme & Paylaş'),
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        allowSharing: true,
        allowPrinting: true,
        canChangePageFormat: false,
        pdfFileName: "cv_ai_builder.pdf", // Paylaşırken dosya adı
      ),
    );
  }
}