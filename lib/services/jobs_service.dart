// File: lib/services/jobs_service.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Supabase storage bucket
  static const String _bucket = 'job-files';

  // You are using public bucket (your URLs are public)
  static const bool _useSignedUrls = false;

  /// Apply for a job:
  /// - Upload resume + photo to Supabase Storage
  /// - Insert into job_applications
  /// - Insert into job_applications_listings (bridge)
  /// - Increment job_listings.applications_count
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

    // ------------------------------------------------------------
    // 1) Validate required fields for your schema
    // job_applications requires:
    // user_id, name, phone, email, skills (text not null)
    // ------------------------------------------------------------
    final name = (applicationData['name'] ?? '').toString().trim();
    final email = (applicationData['email'] ?? '').toString().trim();
    final phone = (applicationData['phone'] ?? '').toString().trim();

    // skills in schema is TEXT NOT NULL
    // we store comma separated string
    final skillsText = _normalizeSkills(applicationData['skills']);

    if (name.isEmpty) throw Exception("Full name is required");
    if (phone.isEmpty) throw Exception("Phone number is required");
    if (email.isEmpty) throw Exception("Email is required");
    if (skillsText.isEmpty) throw Exception("Skills are required");

    // ------------------------------------------------------------
    // 2) Ensure job exists and active
    // ------------------------------------------------------------
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

    // ------------------------------------------------------------
    // 3) Duplicate apply check
    // job_applications_listings has:
    // user_id + listing_id
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
    // 4) Resume bytes
    // ------------------------------------------------------------
    final resumeBytes = resumeFile.bytes;
    if (resumeBytes == null) {
      throw Exception("Resume file could not be read. Please select again.");
    }

    // ------------------------------------------------------------
    // 5) Upload resume + photo
    // ------------------------------------------------------------
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

    // ------------------------------------------------------------
    // 6) Insert job_applications row
    // IMPORTANT: match schema columns exactly
    // ------------------------------------------------------------
    final created = await _supabase
        .from('job_applications')
        .insert({
          'user_id': userId,
          'name': name,
          'phone': phone,
          'email': email,

          // Optional fields (we keep null if not provided)
          'district': _nullIfEmpty(applicationData['district']),
          'address': _nullIfEmpty(applicationData['address']),
          'gender': _nullIfEmpty(applicationData['gender']),
          'date_of_birth': applicationData['date_of_birth'],

          'education': _nullIfEmpty(applicationData['education']),
          'experience_level': _nullIfEmpty(applicationData['experience_level']),
          'experience_details':
              _nullIfEmpty(applicationData['experience_details']),

          // REQUIRED by schema: skills text NOT NULL
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
    // 7) Insert bridge row (job_applications_listings)
    // ------------------------------------------------------------
    await _supabase.from('job_applications_listings').insert({
      'application_id': applicationId,
      'listing_id': jobId,
      'user_id': userId,
      'application_status': 'applied',
    });

    // ------------------------------------------------------------
    // 8) Increment applications_count
    // ------------------------------------------------------------
    final currentCount = _toInt(job['applications_count']);

    await _supabase
        .from('job_listings')
        .update({'applications_count': currentCount + 1})
        .eq('id', jobId);
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
    final safeName = _safeFileName(fileName);

    // Your Supabase public URL example:
    // .../job-files/photos/<userId>/<timestamp>_IMG.jpeg
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

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  String _safeFileName(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return 'file';

    return trimmed
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '');
  }

  String _normalizeSkills(dynamic raw) {
    if (raw == null) return '';

    // if someone passed list
    if (raw is List) {
      final items = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return items.join(', ');
    }

    // text
    final text = raw.toString().trim();
    if (text.isEmpty) return '';

    // normalize: "a, b ,c" -> "a, b, c"
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

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}