// File: lib/services/jobs_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class JobsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit job application with file uploads
  Future<void> submitJobApplication(
    Map<String, dynamic> applicationData,
    File? resumeFile,
    File? photoFile,
  ) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user != null) {
        applicationData['user_id'] = user.id;
      }

      String? resumeUrl;
      String? photoUrl;

      // Upload resume file
      if (resumeFile != null) {
        final resumePath = 'resumes/${user?.id}/${DateTime.now().millisecondsSinceEpoch}_${applicationData['resume_file_name']}';
        await _supabase.storage
            .from('job-files')
            .upload(resumePath, resumeFile);

        resumeUrl = _supabase.storage
            .from('job-files')
            .getPublicUrl(resumePath);

        applicationData['resume_file_url'] = resumeUrl;
      }

      // Upload photo file
      if (photoFile != null) {
        final photoPath = 'photos/${user?.id}/${DateTime.now().millisecondsSinceEpoch}_${applicationData['photo_file_name']}';
        await _supabase.storage
            .from('job-files')
            .upload(photoPath, photoFile);

        photoUrl = _supabase.storage
            .from('job-files')
            .getPublicUrl(photoPath);

        applicationData['photo_file_url'] = photoUrl;
      }

      // Insert application data
      await _supabase
          .from('job_applications')
          .insert(applicationData);

    } catch (e) {
      throw Exception('Failed to submit job application: $e');
    }
  }

  /// Submit job listing with file upload
  Future<void> submitJobListing(
    Map<String, dynamic> jobListingData,
    File? jobDescriptionFile,
  ) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user != null) {
        jobListingData['user_id'] = user.id;
      }

      // Upload job description file if provided
      if (jobDescriptionFile != null) {
        final filePath = 'job-descriptions/${user?.id}/${DateTime.now().millisecondsSinceEpoch}_${jobListingData['job_description_file']}';
        await _supabase.storage
            .from('job-files')
            .upload(filePath, jobDescriptionFile);

        final fileUrl = _supabase.storage
            .from('job-files')
            .getPublicUrl(filePath);

        jobListingData['job_description_file_url'] = fileUrl;
      }

      // Insert job listing
      await _supabase
          .from('job_listings')
          .insert(jobListingData);

    } catch (e) {
      throw Exception('Failed to submit job listing: $e');
    }
  }

  /// Get active job listings
  Future<List<Map<String, dynamic>>> getActiveJobListings({
    String? category,
    String? district,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('job_listings')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (category != null) {
        query = query.eq('job_category', category);
      }

      if (district != null) {
        query = query.eq('district', district);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      throw Exception('Failed to fetch job listings: $e');
    }
  }
}