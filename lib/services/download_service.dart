import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import 'storage_service.dart';

typedef DownloadProgressCallback = void Function(
  int receivedBytes,
  int totalBytes,
  double progressPercentage,
);

class DownloadService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': '*/*',
      },
    ),
  );

  Future<String> getDownloadDirectoryPath({String? userId}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final userFolder = (userId != null && userId.isNotEmpty)
        ? 'user_$userId'
        : 'user_guest';
    final downloadDir = Directory('${appDir.path}/downloads/$userFolder');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<String> getReaderCacheDirectoryPath() async {
    final cacheDir = await getTemporaryDirectory();
    final readerDir = Directory('${cacheDir.path}/reader_cache');
    if (!await readerDir.exists()) {
      await readerDir.create(recursive: true);
    }
    return readerDir.path;
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_').toLowerCase();
  }

  Future<File> downloadBook({
    required Book book,
    required StorageService storageService,
    DownloadProgressCallback? onProgress,
  }) async {
    final dirPath = await getDownloadDirectoryPath(
      userId: storageService.currentUserId,
    );
    final safeName = _sanitizeFilename(book.id);
    final filePath = '$dirPath/$safeName.pdf';
    final targetFile = File(filePath);

    try {
      await _dio.download(
        book.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            final progress = received / total;
            onProgress(received, total, progress);
          }
        },
      );
    } catch (e) {
      debugPrint('Dio download error for ${book.id}: $e');
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      rethrow;
    }

    // Register with rich metadata in storage service
    await storageService.registerBookDownload(
      book: book,
      localPath: filePath,
      fileSize: book.fileSize,
    );

    return targetFile;
  }

  Future<File> getOrFetchBookForReading({
    required Book book,
    required StorageService storageService,
    DownloadProgressCallback? onProgress,
  }) async {
    // 1. Check if already downloaded in My Library
    final downloadedPath = storageService.getDownloadedFilePath(book.id);
    if (downloadedPath != null && File(downloadedPath).existsSync()) {
      return File(downloadedPath);
    }

    // 2. Check reader cache
    final cacheDir = await getReaderCacheDirectoryPath();
    final safeName = _sanitizeFilename(book.id);
    final cachedPath = '$cacheDir/$safeName.pdf';
    final cachedFile = File(cachedPath);
    if (await cachedFile.exists() && (await cachedFile.length()) > 5000) {
      return cachedFile;
    }

    // 3. Download to reader cache
    try {
      await _dio.download(
        book.downloadUrl,
        cachedPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            final progress = received / total;
            onProgress(received, total, progress);
          }
        },
      );
      return cachedFile;
    } catch (e) {
      debugPrint('Reader cache fetch exception for ${book.id}: $e');
      if (await cachedFile.exists()) {
        await cachedFile.delete();
      }
      rethrow;
    }
  }

  Future<OpenResult> openWithExternalViewer(String filePath) async {
    return await OpenFilex.open(filePath);
  }

  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
    return false;
  }
}
