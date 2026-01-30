import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class JobsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// APPLY FOR JOB (SAFE + DUPLICATE CHECK)
  Future<void> applyForJob({
    required String jobId,
    required Map<String, dynamic> applicationData,
    File? resumeFile,
    File? photoFile,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final userId = user.id;

    /// 1️⃣ Check duplicate apply
    final existing = await _supabase
        .from('job_applications_listings')
        .select('id')
        .eq('user_id', userId)
        .eq('listing_id', jobId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You have already applied for this job');
    }

    /// 2️⃣ Upload resume
    String? resumeUrl;
    if (resumeFile != null) {
      final path =
          'resumes/$userId/${DateTime.now().millisecondsSinceEpoch}_${applicationData['resume_file_name']}';
      await _supabase.storage.from('job-files').upload(path, resumeFile);
      resumeUrl = _supabase.storage.from('job-files').getPublicUrl(path);
    }

    /// 3️⃣ Upload photo
    String? photoUrl;
    if (photoFile != null) {
      final path =
          'photos/$userId/${DateTime.now().millisecondsSinceEpoch}_${applicationData['photo_file_name']}';
      await _supabase.storage.from('job-files').upload(path, photoFile);
      photoUrl = _supabase.storage.from('job-files').getPublicUrl(path);
    }

    /// 4️⃣ Insert application
    final application = await _supabase
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

    /// 5️⃣ Link application to job
    await _supabase.from('job_applications_listings').insert({
      'application_id': application['id'],
      'listing_id': jobId,
      'user_id': userId,
      'application_status': 'applied',
    });

    /// 6️⃣ Increment application count
    await _supabase
        .from('job_listings')
        .update({'applications_count': application['applications_count'] + 1})
        .eq('id', jobId);

    /// 7️⃣ Track activity
    await _supabase.from('user_job_activity').insert({
      'user_id': userId,
      'job_id': jobId,
      'activity_type': 'applied',
    });
  }
}
