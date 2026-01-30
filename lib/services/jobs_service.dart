import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class JobsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ===============================
  /// APPLY FOR A JOB (SAFE & ATOMIC)
  /// ===============================
  Future<void> applyForJob({
    required String jobId,
    required Map<String, dynamic> applicationData,
    File? resumeFile,
    File? photoFile,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userId = user.id;

    /// 1️⃣ CHECK: Already applied?
    final existing = await _supabase
        .from('job_applications_listings')
        .select('id')
        .eq('user_id', userId)
        .eq('listing_id', jobId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You have already applied for this job');
    }

    /// 2️⃣ Upload files (if any)
    String? resumeUrl;
    String? photoUrl;

    if (resumeFile != null) {
      final path =
          'resumes/$userId/${DateTime.now().millisecondsSinceEpoch}_${applicationData['resume_file_name']}';

      await _supabase.storage.from('job-files').upload(path, resumeFile);
      resumeUrl = _supabase.storage.from('job-files').getPublicUrl(path);
    }

    if (photoFile != null) {
      final path =
          'photos/$userId/${DateTime.now().millisecondsSinceEpoch}_${applicationData['photo_file_name']}';

      await _supabase.storage.from('job-files').upload(path, photoFile);
      photoUrl = _supabase.storage.from('job-files').getPublicUrl(path);
    }

    /// 3️⃣ Insert into job_applications
    final applicationInsert = await _supabase
        .from('job_applications')
        .insert({
          ...applicationData,
          'user_id': userId,
          'resume_file_url': resumeUrl,
          'photo_file_url': photoUrl,
          'status': 'submitted',
        })
        .select()
        .single();

    final applicationId = applicationInsert['id'];

    /// 4️⃣ Link application to job
    await _supabase.from('job_applications_listings').insert({
      'application_id': applicationId,
      'listing_id': jobId,
      'user_id': userId,
      'application_status': 'applied',
    });

    /// 5️⃣ Increment job application count
    await _supabase.rpc(
      'increment_job_application_count',
      params: {'job_id': jobId},
    );

    /// 6️⃣ Track activity
    await _supabase.from('user_job_activity').insert({
      'user_id': userId,
      'job_id': jobId,
      'activity_type': 'applied',
    });
  }
}
