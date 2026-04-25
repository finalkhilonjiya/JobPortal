enum UserRole {
  jobSeeker,
  employer,
  construction, // ✅ ADDED
}

extension UserRoleApi on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.jobSeeker:
        return "job_seeker";
      case UserRole.employer:
        return "employer";
      case UserRole.construction:
        return "construction"; // ✅ ADDED
    }
  }
}

UserRole parseUserRole(String? role) {
  final v = (role ?? "").trim().toLowerCase();

  if (v == "employer") return UserRole.employer;
  if (v == "construction") return UserRole.construction; // ✅ ADDED

  // correct new DB values
  if (v == "job_seeker") return UserRole.jobSeeker;

  // old values (backward compatibility)
  if (v == "jobseeker") return UserRole.jobSeeker;
  if (v == "buyer") return UserRole.jobSeeker;

  // default safe fallback
  return UserRole.jobSeeker;
}