import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'rcc_works_form.dart';
import 'assam_type_form.dart';
import 'electrical_works_form.dart';
import 'false_ceiling_form.dart';
import 'plumbing_form.dart';
import 'interior_design_form.dart';

class ConstructionServicesHomePage extends StatefulWidget {
  const ConstructionServicesHomePage({Key? key}) : super(key: key);

  @override
  State<ConstructionServicesHomePage> createState() => _ConstructionServicesHomePageState();
}

class _ConstructionServicesHomePageState extends State<ConstructionServicesHomePage> {
  String _currentLocation = 'Detecting...';
  bool _isDetectingLocation = false;

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
      // Check permission
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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get place name from coordinates
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
        _currentLocation = 'Guwahati, Assam'; // Fallback
        _isDetectingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header Section with Real Location
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

                    // ✅ REMOVED: Action Buttons section

                    // Features Section
                    _buildFeaturesSection(),

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
              // Real Location Display
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RCCWorksForm())),
      ),
      ServiceItem(
        title: 'Assam Type',
        subtitle: 'Traditional Assamese architecture',
        icon: Icons.home,
        colors: [Color(0xFFFFF3E0), Color(0xFFFFCC02)],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AssamTypeForm())),
      ),
      ServiceItem(
        title: 'Electrical Works',
        subtitle: 'Complete electrical solutions',
        icon: Icons.electrical_services,
        colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ElectricalWorksForm())),
      ),
      ServiceItem(
        title: 'False Ceiling',
        subtitle: 'Modern ceiling designs',
        icon: Icons.architecture,
        colors: [Color(0xFFF3E5F5), Color(0xFFCE93D8)],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FalseCeilingForm())),
      ),
      ServiceItem(
        title: 'Plumbing',
        subtitle: 'Complete plumbing solutions',
        icon: Icons.plumbing,
        colors: [Color(0xFFFFF8E1), Color(0xFFFFCC02)],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlumbingForm())),
      ),
      ServiceItem(
        title: 'Interior Design',
        subtitle: 'Custom interior solutions',
        icon: Icons.design_services,
        colors: [Color(0xFFFCE4EC), Color(0xFFF48FB1)],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InteriorDesignForm())),
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