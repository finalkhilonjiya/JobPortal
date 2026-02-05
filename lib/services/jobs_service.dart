import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// IMPORTANT:
  /// Your storage bucket name must exist.
  /// If you named it differently, change it here.
  static const String _bucket = 'job-files';

  /// If your bucket is PRIVATE, keep this true.
  /// If your bucket is PUBLIC, you can set false.
  static const bool _useSignedUrls = false;

  // ------------------------------------------------------------
  // APPLY FOR JOB
  // ------------------------------------------------------------
  Future<void> applyForJob({
    required String jobId,
    required Map<String, dynamic> applicationData,
    File? resumeFile,
    File? photoFile,
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
    //
    // Your schema:
    // job_applications.user_id -> user_profiles.id
    //
    // We keep ONE application row per user.
    //
    // ------------------------------------------------------------
    Map<String, dynamic>? existingApp = await _supabase
        .from('job_applications')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    String applicationId;

    if (existingApp == null) {
      // create it
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
    // 3) Duplicate apply check (CORRECT)
    // ------------------------------------------------------------
    final existingBridge = await _supabase
        .from('job_applications_listings')
        .select('id')
        .eq('application_id', applicationId)
        .eq('listing_id', jobId)
        .maybeSingle();

    if (existingBridge != null) {
      throw Exception('You have already applied for this job');
    }

    // ------------------------------------------------------------
    // 4) Upload resume + photo (SAFE)
    // ------------------------------------------------------------
    String? resumeUrl;
    String? photoUrl;

    if (resumeFile != null) {
      resumeUrl = await _uploadFile(
        userId: userId,
        folder: 'resumes',
        file: resumeFile,
        fileNameFromUi: applicationData['resume_file_name']?.toString(),
        contentType: 'application/pdf',
      );
    }

    if (photoFile != null) {
      photoUrl = await _uploadFile(
        userId: userId,
        folder: 'photos',
        file: photoFile,
        fileNameFromUi: applicationData['photo_file_name']?.toString(),
        contentType: 'image/jpeg',
      );
    }

    // ------------------------------------------------------------
    // 5) Update user's application profile
    // ------------------------------------------------------------
    //
    // IMPORTANT:
    // Your employer applicants screen reads:
    // job_applications -> user_profiles
    //
    // So most candidate data should be in user_profiles.
    //
    // But we still store resume/photo in job_applications.
    //
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
      'applied_at': DateTime.now().toIso8601String(),
      'application_status': 'applied',
    });

    // ------------------------------------------------------------
    // 7) Increment applications_count safely
    // ------------------------------------------------------------
    final currentCount = (job['applications_count'] ?? 0) as int;

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
      // ignore (activity table may not exist or may have RLS)
    }
  }

  // ------------------------------------------------------------
  // STORAGE UPLOAD (ANDROID SAFE)
  // ------------------------------------------------------------
  Future<String> _uploadFile({
    required String userId,
    required String folder,
    required File file,
    required String? fileNameFromUi,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();

    final safeName = (fileNameFromUi ?? 'file')
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

    // If bucket is public:
    if (!_useSignedUrls) {
      return _supabase.storage.from(_bucket).getPublicUrl(path);
    }

    // If bucket is private:
    final signed = await _supabase.storage.from(_bucket).createSignedUrl(
          path,
          60 * 60 * 24 * 7, // 7 days
        );

    return signed;
  }
}