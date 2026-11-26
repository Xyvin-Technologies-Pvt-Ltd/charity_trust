import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// Service for opening files with default applications
class FileOpenerService {
  /// Open a file with the default application
  /// Returns the result of the open operation
  Future<OpenResult> openFile(String filePath) async {
    try {
      if (!await File(filePath).exists()) {
        throw Exception('File not found: $filePath');
      }

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        // Fallback: If direct open fails, present native share sheet
        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], subject: 'Receipt'),
        );
      }
      return result;
    } catch (e) {
      try {
        if (await File(filePath).exists()) {
          await SharePlus.instance.share(
            ShareParams(files: [XFile(filePath)], subject: 'Receipt'),
          );
          return OpenResult(type: ResultType.done, message: 'Opened via share');
        }
      } catch (_) {}
      throw Exception('Failed to open file: $e');
    }
  }

  /// Open PDF file specifically
  Future<OpenResult> openPdf(String filePath) async {
    try {
      return await openFile(filePath);
    } catch (e) {
      throw Exception('Failed to open PDF: $e');
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      return await file.length();
    } catch (e) {
      throw Exception('Failed to get file size: $e');
    }
  }

  /// Delete a file
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}
