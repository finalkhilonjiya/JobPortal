import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ConstructionServicesHomePage extends StatelessWidget {
  const ConstructionServicesHomePage({Key? key}) : super(key: key);

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
                    // Search Bar
                    _buildSearchBar(),
                    
                    // Welcome Banner
                    _buildWelcomeBanner(),
                    
                    // Services Grid
                    _buildServicesGrid(context),
                    
                    // Action Buttons
                    _buildActionButtons(context),
                    
                    // Features Section
                    _buildFeaturesSection(),
                    
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

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for services, contractors...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.w),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
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
            'Khilonjiya Construction Services',
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
            'Professional construction services for your dream home - Quality work with local expertise',
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

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      ServiceItem(
        title: 'RCC Works',
        subtitle: 'Reinforced concrete construction',
        icon: Icons.construction,
        colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
        onTap: () => _navigateToService(context, 'RCC Works'),
      ),
      ServiceItem(
        title: 'Assam Type',
        subtitle: 'Traditional Assamese architecture',
        icon: Icons.home,
        colors: [Color(0xFFFFF3E0), Color(0xFFFFCC02)],
        onTap: () => _navigateToService(context, 'Assam Type'),
      ),
      ServiceItem(
        title: 'Electrical Works',
        subtitle: 'Complete electrical solutions',
        icon: Icons.electrical_services,
        colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
        onTap: () => _navigateToService(context, 'Electrical Works'),
      ),
      ServiceItem(
        title: 'False Ceiling',
        subtitle: 'Modern ceiling designs',
        icon: Icons.architecture,
        colors: [Color(0xFFF3E5F5), Color(0xFFCE93D8)],
        onTap: () => _navigateToService(context, 'False Ceiling'),
      ),
      ServiceItem(
        title: 'Plumbing',
        subtitle: 'Complete plumbing solutions',
        icon: Icons.plumbing,
        colors: [Color(0xFFFFF8E1), Color(0xFFFFCC02)],
        onTap: () => _navigateToService(context, 'Plumbing'),
      ),
      ServiceItem(
        title: 'Interior Design',
        subtitle: 'Custom interior solutions',
        icon: Icons.design_services,
        colors: [Color(0xFFFCE4EC), Color(0xFFF48FB1)],
        onTap: () => _navigateToService(context, 'Interior Design'),
      ),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4.w,
          mainAxisSpacing: 4.w,
          childAspectRatio: 0.85,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return _buildServiceCard(services[index]);
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    return GestureDetector(
      onTap: service.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: service.colors,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                service.icon,
                size: 7.w,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 4.w),
            Text(
              service.title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.w),
            Text(
              service.subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showQuoteDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Get Free Quote',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _navigateToProjects(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF2563EB),
                side: BorderSide(color: Color(0xFF2563EB), width: 2),
                padding: EdgeInsets.symmetric(vertical: 4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Our Projects',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
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
            'Why Choose Us?',
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
              _buildFeatureItem(Icons.star, '15+ Years\nExperience'),
              _buildFeatureItem(Icons.workspace_premium, 'Local\nExpertise'),
              _buildFeatureItem(Icons.verified, 'Quality\nMaterials'),
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

  void _navigateToService(BuildContext context, String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailPage(serviceName: serviceName),
      ),
    );
  }

  void _showQuoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Get Free Quote'),
        content: Text('Contact us for a free consultation and quote for your construction needs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle contact action
            },
            child: Text('Contact Us'),
          ),
        ],
      ),
    );
  }

  void _navigateToProjects(BuildContext context) {
    // Navigate to projects page
    print('Navigate to Our Projects');
  }
}

class ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });
}

// Placeholder for Service Detail Page
class ServiceDetailPage extends StatelessWidget {
  final String serviceName;

  const ServiceDetailPage({Key? key, required this.serviceName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName),
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$serviceName Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Service packages and booking options will be displayed here.'),
          ],
        ),
      ),
    );
  }
}