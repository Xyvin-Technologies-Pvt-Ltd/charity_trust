import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:Annujoom/src/data/services/file_opener_service.dart';
import 'package:open_filex/open_filex.dart';

part 'file_opener_provider.g.dart';

/// File opener service provider
@riverpod
FileOpenerService fileOpenerService(Ref ref) {
  return FileOpenerService();
}

/// Open file - returns OpenResult
@riverpod
Future<OpenResult> openFile(Ref ref, String filePath) async {
  final service = ref.watch(fileOpenerServiceProvider);
  return await service.openFile(filePath);
}

/// Open PDF file
@riverpod
Future<OpenResult> openPdf(Ref ref, String filePath) async {
  final service = ref.watch(fileOpenerServiceProvider);
  return await service.openPdf(filePath);
}

/// Check if file exists
@riverpod
Future<bool> fileExists(Ref ref, String filePath) async {
  final service = ref.watch(fileOpenerServiceProvider);
  return await service.fileExists(filePath);
}

/// Get file size
@riverpod
Future<int> getFileSize(Ref ref, String filePath) async {
  final service = ref.watch(fileOpenerServiceProvider);
  return await service.getFileSize(filePath);
}

/// Delete file
@riverpod
Future<void> deleteFile(Ref ref, String filePath) async {
  final service = ref.watch(fileOpenerServiceProvider);
  return await service.deleteFile(filePath);
}
