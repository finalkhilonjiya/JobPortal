import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_service.dart';

class JobApplicationService {
  final SupabaseClient _db = Supabase.instance.client;
  final StorageService _storage = StorageService();

  /// Apply for a job:
  /// - Upload resume + photo to Supabase Storage
  /// - Insert into job_applications
  /// - Insert into job_applications_listings
  ///
  /// IMPORTANT:
  /// We do NOT update job_listings.applications_count manually.
  /// Because it will always go out of sync.
  Future<void> applyForJob({
    required String jobId,
    required Map<String, dynamic> applicationData,
    required PlatformFile resumeFile,
    required Uint8List photoBytes,
    required String photoFileName,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userId = user.id;

    // ------------------------------------------------------------
    // 1) Validate required fields
    // ------------------------------------------------------------
    final name = (applicationData['name'] ?? '').toString().trim();
    final email = (applicationData['email'] ?? '').toString().trim();
    final phone = (applicationData['phone'] ?? '').toString().trim();

    final skillsText = _normalizeSkills(applicationData['skills']);

    if (name.isEmpty) throw Exception("Full name is required");
    if (phone.isEmpty) throw Exception("Phone number is required");
    if (email.isEmpty) throw Exception("Email is required");
    if (skillsText.isEmpty) throw Exception("Skills are required");

    // ------------------------------------------------------------
    // 2) Ensure job exists + active
    // ------------------------------------------------------------
    final job = await _db
        .from('job_listings')
        .select('id,status,expires_at')
        .eq('id', jobId)
        .maybeSingle();

    if (job == null) throw Exception("Job not found");

    final jobStatus = (job['status'] ?? 'active').toString().toLowerCase();
    if (jobStatus != 'active') {
      throw Exception("This job is not accepting applications");
    }

    // Expiry check
    final expiresAtRaw = job['expires_at']?.toString();
    final expiresAt = expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw);
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw Exception("This job has expired");
    }

    // ------------------------------------------------------------
    // 3) Duplicate apply check (unique user_id + listing_id)
    // ------------------------------------------------------------
    final existingBridge = await _db
        .from('job_applications_listings')
        .select('id')
        .eq('user_id', userId)
        .eq('listing_id', jobId)
        .maybeSingle();

    if (existingBridge != null) {
      throw Exception('You have already applied for this job');
    }

    // ------------------------------------------------------------
    // 4) Resume bytes
    // ------------------------------------------------------------
    final resumeBytes = resumeFile.bytes;
    if (resumeBytes == null) {
      throw Exception("Resume file could not be read. Please select again.");
    }

    // ------------------------------------------------------------
    // 5) Upload resume + photo
    // ------------------------------------------------------------
    final resumeUrl = await _uploadResume(
      userId: userId,
      bytes: resumeBytes,
      fileName: resumeFile.name,
    );

    final photoUrl = await _uploadPhoto(
      userId: userId,
      bytes: photoBytes,
      fileName: photoFileName,
    );

    // ------------------------------------------------------------
    // 6) Insert job_applications
    // ------------------------------------------------------------
    final created = await _db
        .from('job_applications')
        .insert({
          'user_id': userId,
          'name': name,
          'phone': phone,
          'email': email,

          'district': _nullIfEmpty(applicationData['district']),
          'address': _nullIfEmpty(applicationData['address']),
          'gender': _nullIfEmpty(applicationData['gender']),
          'date_of_birth': applicationData['date_of_birth'],

          'education': _nullIfEmpty(applicationData['education']),
          'experience_level': _nullIfEmpty(applicationData['experience_level']),
          'experience_details': _nullIfEmpty(applicationData['experience_details']),

          'skills': skillsText,

          'expected_salary': _nullIfEmpty(applicationData['expected_salary']),
          'availability': _nullIfEmpty(applicationData['availability']),
          'additional_info': _nullIfEmpty(applicationData['additional_info']),

          'resume_file_name': resumeFile.name,
          'resume_file_url': resumeUrl,

          'photo_file_name': photoFileName,
          'photo_file_url': photoUrl,

          'status': 'submitted',
        })
        .select('id')
        .single();

    final applicationId = created['id'].toString();

    // ------------------------------------------------------------
    // 7) Insert bridge: job_applications_listings
    // ------------------------------------------------------------
    await _db.from('job_applications_listings').insert({
      'application_id': applicationId,
      'listing_id': jobId,
      'user_id': userId,
      'application_status': 'applied',
      'applied_at': DateTime.now().toIso8601String(),
    });
  }

  // ------------------------------------------------------------
  // Upload helpers
  // ------------------------------------------------------------

  Future<String> _uploadResume({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safeName = _storage.safeFileName(fileName);

    final path =
        'resumes/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    return _storage.uploadBytes(
      bucket: StorageService.bucketJobFiles,
      path: path,
      bytes: bytes,
      contentType: 'application/pdf',
    );
  }

  Future<String> _uploadPhoto({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safeName = _storage.safeFileName(fileName);

    final path =
        'photos/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    return _storage.uploadBytes(
      bucket: StorageService.bucketJobFiles,
      path: path,
      bytes: bytes,
      contentType: 'image/jpeg',
    );
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------

  String _normalizeSkills(dynamic raw) {
    if (raw == null) return '';

    if (raw is List) {
      final items = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return items.join(', ');
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return '';

    final parts = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return parts.join(', ');
  }

  dynamic _nullIfEmpty(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return s;
  }
}