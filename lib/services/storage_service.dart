import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _db = Supabase.instance.client;

  /// Your Supabase storage bucket
  static const String bucketJobFiles = 'job-files';

  /// If bucket is public -> use public URL
  static const bool useSignedUrls = false;

  Future<String> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _db.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    if (!useSignedUrls) {
      return _db.storage.from(bucket).getPublicUrl(path);
    }

    return _db.storage.from(bucket).createSignedUrl(path, 60 * 60 * 24 * 7);
  }

  String safeFileName(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return 'file';

    return trimmed
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '');
  }
}