// File: lib/services/jobs_service.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _bucket = 'job-files';
  static const bool _useSignedUrls = false;

  Future<void> applyForJob({
    required String jobId,
    required Map<String, dynamic> applicationData,
    required PlatformFile resumeFile,

    /// Photo from image_picker
    required Uint8List photoBytes,
    required String photoFileName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userId = user.id;

    // 1) Ensure job exists and active
    final job = await _supabase
        .from('job_listings')
        .select('id, applications_count, status')
        .eq('id', jobId)
        .maybeSingle();

    if (job == null) throw Exception("Job not found");

    final jobStatus = (job['status'] ?? 'active').toString().toLowerCase();
    if (jobStatus != 'active') {
      throw Exception("This job is not accepting applications");
    }

    // 2) Duplicate apply check
    final existingBridge = await _supabase
        .from('job_applications_listings')
        .select('id')
        .eq('user_id', userId)
        .eq('listing_id', jobId)
        .maybeSingle();

    if (existingBridge != null) {
      throw Exception('You have already applied for this job');
    }

    // 3) Resume bytes
    final resumeBytes = resumeFile.bytes;
    if (resumeBytes == null) {
      throw Exception("Resume file could not be read. Please select again.");
    }

    // 4) Upload resume + photo
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
      fileName: photoFileName,
      contentType: 'image/jpeg',
    );

    // 5) Insert job_applications row (name is required)
    final created = await _supabase
        .from('job_applications')
        .insert({
          'user_id': userId,
          'name': (applicationData['name'] ?? '').toString().trim(),
          'email': (applicationData['email'] ?? '').toString().trim(),
          'phone': (applicationData['phone'] ?? '').toString().trim(),
          'skills': _skillsToList(applicationData['skills']),
          'resume_file_url': resumeUrl,
          'photo_file_url': photoUrl,
          'status': 'submitted',
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final applicationId = created['id'].toString();

    // 6) Insert bridge row
    await _supabase.from('job_applications_listings').insert({
      'application_id': applicationId,
      'listing_id': jobId,
      'user_id': userId,
      'applied_at': DateTime.now().toIso8601String(),
      'application_status': 'applied',
    });

    // 7) Increment applications_count
    final currentCount = _toInt(job['applications_count']);

    await _supabase
        .from('job_listings')
        .update({'applications_count': currentCount + 1})
        .eq('id', jobId);
  }

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

  List<String> _skillsToList(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final text = raw.toString();
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}