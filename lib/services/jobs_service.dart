import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Your storage bucket name
  static const String _bucket = 'job-files';

  /// If bucket is PRIVATE -> true (recommended later)
  static const bool _useSignedUrls = false;

  // ------------------------------------------------------------
  // APPLY FOR JOB
  // ------------------------------------------------------------
  Future<void> applyForJob({
    required String jobId,
    required Map<String, dynamic> applicationData,

    /// IMPORTANT:
    /// Use PlatformFile so Android 10+ does not crash
    required PlatformFile resumeFile,
    required PlatformFile photoFile,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userId = user.id;

    // ------------------------------------------------------------
    // 1) Ensure job exists and is active
    // ------------------------------------------------------------
    final job = await _supabase
        .from('job_listings')
        .select('id, applications_count, status')
        .eq('id', jobId)
        .maybeSingle();

    if (job == null) throw Exception("Job not found");

    final status = (job['status'] ?? 'active').toString().toLowerCase();
    if (status != 'active') {
      throw Exception("This job is not accepting applications");
    }

    // ------------------------------------------------------------
    // 2) Get / Create user's job_application row
    // ------------------------------------------------------------
    final existingApp = await _supabase
        .from('job_applications')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    String applicationId;

    if (existingApp == null) {
      final created = await _supabase
          .from('job_applications')
          .insert({
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      applicationId = created['id'].toString();
    } else {
      applicationId = existingApp['id'].toString();
    }

    // ------------------------------------------------------------
    // 3) Duplicate apply check (FINAL TRUTH)
    // ------------------------------------------------------------
    final existingBridge = await _supabase
        .from('job_applications_listings')
        .select('id')
        .eq('user_id', userId)
        .eq('listing_id', jobId)
        .maybeSingle();

    if (existingBridge != null) {
      throw Exception('You have already applied for this job');
    }

    // ------------------------------------------------------------
    // 4) Upload resume + photo (NO CRASH)
    // ------------------------------------------------------------
    final resumeBytes = resumeFile.bytes;
    final photoBytes = photoFile.bytes;

    if (resumeBytes == null) {
      throw Exception("Resume file could not be read. Please select again.");
    }
    if (photoBytes == null) {
      throw Exception("Photo file could not be read. Please select again.");
    }

    final resumeUrl = await _uploadBytes(
      userId: userId,
      folder: 'resumes',
      bytes: resumeBytes,
      fileName: resumeFile.name,
      contentType: 'application/pdf',
    );

    final photoUrl = await _uploadBytes(
      userId: userId,
      folder: 'photos',
      bytes: photoBytes,
      fileName: photoFile.name,
      contentType: 'image/jpeg',
    );

    // ------------------------------------------------------------
    // 5) Update job_applications with candidate info + file urls
    // ------------------------------------------------------------
    await _supabase.from('job_applications').update({
      ...applicationData,
      'resume_file_url': resumeUrl,
      'photo_file_url': photoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', applicationId);

    // ------------------------------------------------------------
    // 6) Insert bridge row (this is the actual "apply")
    // ------------------------------------------------------------
    await _supabase.from('job_applications_listings').insert({
      'application_id': applicationId,
      'listing_id': jobId,
      'user_id': userId, // ✅ REQUIRED
      'applied_at': DateTime.now().toIso8601String(),
      'application_status': 'applied',
    });

    // ------------------------------------------------------------
    // 7) Increment applications_count (SAFE)
    // ------------------------------------------------------------
    final currentCount = _toInt(job['applications_count']);

    await _supabase
        .from('job_listings')
        .update({'applications_count': currentCount + 1})
        .eq('id', jobId);

    // ------------------------------------------------------------
    // 8) Track activity (optional)
    // ------------------------------------------------------------
    try {
      await _supabase.from('user_job_activity').insert({
        'user_id': userId,
        'job_id': jobId,
        'activity_type': 'applied',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // ignore
    }
  }

  // ------------------------------------------------------------
  // STORAGE UPLOAD
  // ------------------------------------------------------------
  Future<String> _uploadBytes({
    required String userId,
    required String folder,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final safeName = fileName
        .trim()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '');

    final path =
        '$folder/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _supabase.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    if (!_useSignedUrls) {
      return _supabase.storage.from(_bucket).getPublicUrl(path);
    }

    final signed = await _supabase.storage.from(_bucket).createSignedUrl(
          path,
          60 * 60 * 24 * 7,
        );

    return signed;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}