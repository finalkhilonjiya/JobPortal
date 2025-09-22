import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class JobsPortalHomePage extends StatelessWidget {
  const JobsPortalHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(context),
            
            // Body Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Welcome Banner
                    _buildWelcomeBanner(),
                    
                    // Main Action Buttons
                    _buildMainActionButtons(context),
                    
                    // Quick Stats
                    _buildQuickStats(),
                    
                    // Featured Jobs Section
                    _buildFeaturedJobsSection(),
                    
                    // Why Choose Us
                    _buildWhyChooseUs(),
                    
                    SizedBox(height: 10.h), // Space for bottom nav
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
              Row(
                children: [
                  Icon(Icons.location_on, size: 4.w, color: Colors.grey),
                  SizedBox(width: 1.w),
                  Text(
                    'Guwahati, Assam',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
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
  }

  Widget _buildMainActionButtons(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      child: Column(
        children: [
          // Apply for Jobs Button
          Container(
            width: double.infinity,
            height: 15.h,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to job application form
                _navigateToJobApplication(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work, size: 8.w),
                  SizedBox(height: 2.w),
                  Text(
                    'Apply for Jobs',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.w),
                  Text(
                    'Find opportunities that match your skills',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 4.w),
          
          // List Jobs Button
          Container(
            width: double.infinity,
            height: 15.h,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to job listing form
                _navigateToJobListing(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF2563EB),
                side: BorderSide(color: Color(0xFF2563EB), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 8.w),
                  SizedBox(height: 2.w),
                  Text(
                    'List Jobs',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
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
    final jobs = [
      {'title': 'Software Developer', 'company': 'Tech Assam', 'location': 'Guwahati'},
      {'title': 'Civil Engineer', 'company': 'BuildCorp', 'location': 'Dibrugarh'},
      {'title': 'Teacher', 'company': 'Modern School', 'location': 'Silchar'},
    ];

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
          ...jobs.map((job) => Container(
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

  void _navigateToJobApplication(BuildContext context) {
    // Navigate to job application form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobApplicationFormPage(),
      ),
    );
  }

  void _navigateToJobListing(BuildContext context) {
    // Navigate to job listing form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobListingFormPage(),
      ),
    );
  }
}

// Placeholder for Job Application Form
class JobApplicationFormPage extends StatelessWidget {
  const JobApplicationFormPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for Jobs'),
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Job Application Form',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Job application form will be implemented here.'),
          ],
        ),
      ),
    );
  }
}

// Placeholder for Job Listing Form
class JobListingFormPage extends StatelessWidget {
  const JobListingFormPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List Jobs'),
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Job Listing Form',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Job listing form will be implemented here.'),
          ],
        ),
      ),
    );
  }