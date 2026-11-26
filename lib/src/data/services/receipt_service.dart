import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Receipt service for downloading and sharing PDF receipts
/// Uses file_saver for cross-platform Downloads folder access with path_provider fallback
class ReceiptService {
  final Dio _dio;

  ReceiptService({Dio? dio}) : _dio = dio ?? Dio();

  /// Download receipt PDF from URL to Downloads folder
  /// Returns the file path if successful
  Future<String> downloadReceipt(String receiptUrl) async {
    try {
      final fileName = _extractFileName(receiptUrl);

      // Download file to bytes
      final response = await _dio.get<List<int>>(
        receiptUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      if (response.data == null || response.data!.isEmpty) {
        throw Exception('Failed to download receipt data');
      }

      final bytes = Uint8List.fromList(response.data!);
      String path = '';

      try {
        path = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
      } catch (saveError) {
        print('FileSaver failed: $saveError. Falling back to documents directory.');
      }

      // Check if file_saver succeeded and file actually exists
      if (path.isEmpty ||
          path.contains('Something went wrong') ||
          !await File(path).exists()) {
        final docsDir = await getApplicationDocumentsDirectory();
        final fallbackFile = File('${docsDir.path}/$fileName.pdf');
        await fallbackFile.writeAsBytes(bytes);
        path = fallbackFile.path;
      }

      return path;
    } catch (e) {
      throw Exception('Failed to download receipt: $e');
    }
  }

  /// Share receipt PDF
  /// Downloads and shares via native share sheet
  Future<void> shareReceipt(String receiptUrl) async {
    try {
      final fileName = _extractFileName(receiptUrl);
      
      // Download file to bytes
      final response = await _dio.get<List<int>>(
        receiptUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null) {
        throw Exception('Failed to download receipt data');
      }

      // Create temporary file for sharing
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName.pdf');
      await tempFile.writeAsBytes(response.data!);

      final file = XFile(tempFile.path);

      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          subject: 'Donation Receipt',
          text: 'Please find my donation receipt attached.',
        ),
      );
    } catch (e) {
      throw Exception('Failed to share receipt: $e');
    }
  }

  /// Extract base filename from URL without extension
  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final rawName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      final decoded = rawName.isNotEmpty ? Uri.decodeComponent(rawName) : '';
      if (decoded.isNotEmpty) {
        final clean = decoded
            .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
            .replaceAll(RegExp(r'[^\w\-_.]'), '_');
        return clean.isNotEmpty
            ? clean
            : 'receipt_${DateTime.now().millisecondsSinceEpoch}';
      }
      return 'receipt_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'receipt_${DateTime.now().millisecondsSinceEpoch}';
    }
  }


}
