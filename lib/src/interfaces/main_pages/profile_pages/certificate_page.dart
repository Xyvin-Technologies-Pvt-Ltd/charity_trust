import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:Annujoom/src/data/constants/color_constants.dart';
import 'package:Annujoom/src/data/constants/style_constants.dart';
import 'package:Annujoom/src/data/services/snackbar_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';

class CertificatePage extends StatefulWidget {
  const CertificatePage({super.key});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  final List<String> _certificateImages = [
    'assets/png/darpancertificate.png',
    'assets/png/darapan2.png',
  ];

  Future<Uint8List> _createPdfFromImages() async {
    final pdf = pw.Document();

    // Add each certificate image as a separate page
    // Page 1: darpancertificate.png
    // Page 2: darapan2.png
    for (int i = 0; i < _certificateImages.length; i++) {
      final imagePath = _certificateImages[i];
      final ByteData data = await rootBundle.load(imagePath);
      final Uint8List imageBytes = data.buffer.asUint8List();

      // Create PDF image from bytes
      final pdfImage = pw.MemoryImage(imageBytes);

      // Add page with the image
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  Future<void> _downloadPdf() async {
    try {
      final pdfBytes = await _createPdfFromImages();

      // Save PDF using file_saver
      final fileName =
          'DARPAN_Certificate_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: pdfBytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        // Show custom snackbar with View button
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(
                  child: Text(
                    'PDF saved successfully',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    try {
                      final result = await OpenFilex.open(filePath);
                      if (result.type != ResultType.done) {
                        if (mounted) {
                          SnackbarService().showSnackBar(
                            'Failed to open PDF',
                            type: SnackbarType.error,
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        SnackbarService().showSnackBar(
                          'Failed to open PDF: $e',
                          type: SnackbarType.error,
                        );
                      }
                    }
                  },
                  child: Text(
                    'View',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00C851),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService().showSnackBar(
          'Failed to download PDF: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    try {
      final pdfBytes = await _createPdfFromImages();

      // Create a temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/DARPAN_Certificate_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'DARPAN Certificate',
      );
    } catch (e) {
      if (mounted) {
        SnackbarService().showSnackBar(
          'Failed to share PDF: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  String _getGeneratedOnText() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    final hour =
        now.hour > 12 ? (now.hour - 12).toString() : now.hour.toString();
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return 'Generated on: $day-$month-$year $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios,
            color: kTextColor,
            size: 20,
          ),
        ),
        title: Text(
          'license'.tr(),
          style: kBodyTitleM,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/svg/download.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(kTextColor, BlendMode.srcIn),
            ),
            onPressed: _downloadPdf,
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/svg/share.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(kTextColor, BlendMode.srcIn),
            ),
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Certificate images
            ..._certificateImages.map((imagePath) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Image not found',
                              style: kSmallTitleR.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
