// File: lib/presentation/home_marketplace_feed/jobs_portal_home_page.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'job_application_form.dart';
import 'job_listing_form.dart';

class JobsPortalHomePage extends StatefulWidget {
  const JobsPortalHomePage({Key? key}) : super(key: key);

  @override
  State<JobsPortalHomePage> createState() => _JobsPortalHomePageState();
}

class _JobsPortalHomePageState extends State<JobsPortalHomePage> {
  String _currentLocation = 'Detecting...';
  bool _isDetectingLocation = false;

  // Featured jobs data
  final List<Map<String, String>> _featuredJobs = [
    {
      'title': 'Software Developer',
      'company': 'Tech Assam',
      'location': 'Guwahati',
      'salary': '₹4-6 LPA',
      'experience': '2-4 years',
      'type': 'Full Time',
      'description': 'We are looking for an experienced Software Developer to join our team. Must have strong knowledge in Flutter, Dart, and mobile app development.',
      'requirements': '• Bachelor\'s degree in Computer Science\n• 2+ years of Flutter development\n• Strong problem-solving skills\n• Good communication skills',
      'postedDate': '2 days ago',
    },
    {
      'title': 'Civil Engineer',
      'company': 'BuildCorp',
      'location': 'Dibrugarh',
      'salary': '₹3-5 LPA',
      'experience': '3-5 years',
      'type': 'Full Time',
      'description': 'Experienced Civil Engineer needed for infrastructure projects. Must have expertise in structural design and project management.',
      'requirements': '• B.Tech in Civil Engineering\n• 3+ years experience in construction\n• AutoCAD proficiency\n• Site management experience',
      'postedDate': '5 days ago',
    },
    {
      'title': 'Teacher',
      'company': 'Modern School',
      'location': 'Silchar',
      'salary': '₹2.5-4 LPA',
      'experience': '1-3 years',
      'type': 'Full Time',
      'description': 'Looking for passionate teachers for Science and Mathematics. Must be able to engage students and create innovative learning experiences.',
      'requirements': '• B.Ed or equivalent degree\n• Subject expertise in Science/Math\n• Good classroom management\n• Student-centric approach',
      'postedDate': '1 week ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    if (_isDetectingLocation) return;

    setState(() {
      _isDetectingLocation = true;
      _currentLocation = 'Detecting...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location denied';
            _isDetectingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location disabled';
          _isDetectingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocation = '${place.locality ?? place.subAdministrativeArea ?? 'Unknown'}, ${place.administrativeArea ?? ''}';
          _isDetectingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Guwahati, Assam';
        _isDetectingLocation = false;
      });
    }
  }

  void _showJobDetails(Map<String, String> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 12.w,
                    height: 1.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 4.w),
                Row(
                  children: [
                    Container(
                      width: 15.w,
                      height: 15.w,
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.work,
                        color: Color(0xFF2563EB),
                        size: 8.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title']!,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 1.w),
                          Text(
                            job['company']!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.w),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 2.w,
                  children: [
                    _buildInfoChip(Icons.location_on, job['location']!),
                    _buildInfoChip(Icons.payment, job['salary']!),
                    _buildInfoChip(Icons.work_history, job['experience']!),
                    _buildInfoChip(Icons.schedule, job['type']!),
                    _buildInfoChip(Icons.access_time, job['postedDate']!),
                  ],
                ),
                SizedBox(height: 6.w),
                Text(
                  'Job Description',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.w),
                Text(
                  job['description']!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 4.w),
                Text(
                  'Requirements',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.w),
                Text(
                  job['requirements']!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 6.w),
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobApplicationForm(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.w),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 4.w, color: Color(0xFF2563EB)),
          SizedBox(width: 1.5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildWelcomeBanner(),
                    _buildMainActionButtons(context),
                    _buildQuickStats(),
                    _buildFeaturedJobsSection(),
                    _buildWhyChooseUs(),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            child: Image.asset(
              'assets/images/company_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 3.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'khilonjiya.com',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                onTap: _detectLocation,
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 4.w, color: Colors.grey),
                    SizedBox(width: 1.w),
                    Text(
                      _currentLocation,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                    if (_isDetectingLocation) ...[
                      SizedBox(width: 2.w),
                      SizedBox(
                        width: 3.w,
                        height: 3.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, size: 6.w),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/jobportalbanner.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient container if image not found
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(6.w),
              child: Column(
                children: [
                  Text(
                    'Khilonjiya Jobs Portal',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 3.w),
                  Text(
                    'Connect with opportunities in Assam - Find your perfect job or hire the right talent',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainActionButtons(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobApplicationForm(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 15.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/applyforjobs.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback design if image not found
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFF2563EB), width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work, size: 8.w, color: Color(0xFF2563EB)),
                          SizedBox(height: 2.w),
                          Text(
                            'Apply for Jobs',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(height: 1.w),
                          Text(
                            'Find opportunities that match your skills',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Color(0xFF2563EB).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 4.w),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobListingForm(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 15.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/listjobs.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback design if image not found
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFF2563EB), width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.post_add, size: 8.w, color: Color(0xFF2563EB)),
                          SizedBox(height: 2.w),
                          Text(
                            'List Jobs',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(height: 1.w),
                          Text(
                            'Post job openings and find candidates',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Color(0xFF2563EB).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('500+', 'Active Jobs', Icons.work)),
          SizedBox(width: 3.w),
          Expanded(child: _buildStatCard('1200+', 'Job Seekers', Icons.people)),
          SizedBox(width: 3.w),
          Expanded(child: _buildStatCard('300+', 'Companies', Icons.business)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF2563EB), size: 6.w),
          SizedBox(height: 2.w),
          Text(
            number,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedJobsSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Jobs',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 3.w),
          ..._featuredJobs.map((job) => InkWell(
            onTap: () => _showJobDetails(job),
            child: Container(
              margin: EdgeInsets.only(bottom: 3.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.work, color: Color(0xFF2563EB), size: 6.w),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title']!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          job['company']!,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          job['location']!,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 4.w, color: Colors.grey),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildWhyChooseUs() {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          Text(
            'Why Choose Khilonjiya Jobs?',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureItem(Icons.location_on, 'Local\nFocus'),
              _buildFeatureItem(Icons.verified_user, 'Verified\nJobs'),
              _buildFeatureItem(Icons.speed, 'Quick\nMatching'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 5.w),
        ),
        SizedBox(height: 2.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}