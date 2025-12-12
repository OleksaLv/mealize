import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => message;
}

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _bucketName = 'mealize_images';

  Future<String> uploadFile(File file, String folder) async {
    if (!file.existsSync()) {
      throw StorageException('File does not exist at path: ${file.path}');
    }

    try {
      final fileExt = path.extension(file.path);
      final fileName = '${const Uuid().v4()}$fileExt';
      final storagePath = '$folder/$fileName';

      await _client.storage.from(_bucketName).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final publicUrl =
          _client.storage.from(_bucketName).getPublicUrl(storagePath);
      
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('Supabase Storage Error: ${e.message}');
      throw StorageException('Failed to upload file: ${e.message}');
    } catch (e) {
      debugPrint('Unknown Storage Error: $e');
      throw StorageException('An unexpected error occurred during file upload.');
    }
  }

  Future<void> deleteFile(String imageUrl) async {
    try {
      if (!imageUrl.contains('/$_bucketName/')) return;

      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      final bucketIndex = pathSegments.indexOf(_bucketName);
      
      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
         final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
         
         await _client.storage.from(_bucketName).remove([filePath]);
      }
    } catch (e) {
      debugPrint('Failed to delete file: $e');
    }
  }
}