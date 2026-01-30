enum UserRole { jobSeeker, employer }

UserRole parseUserRole(String? role) {
  if (role == 'employer') {
    return UserRole.employer;
  }
  return UserRole.jobSeeker;
}
