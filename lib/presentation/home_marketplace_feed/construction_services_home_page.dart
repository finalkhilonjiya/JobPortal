import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'rcc_works_form.dart';
import 'assam_type_form.dart';
import 'electrical_works_form.dart';
import 'false_ceiling_form.dart';
import 'plumbing_form.dart';
import 'interior_design_form.dart';

class ConstructionServicesHomePage extends StatefulWidget {
  const ConstructionServicesHomePage({Key? key}) : super(key: key);

  @override
  State<ConstructionServicesHomePage> createState() =>
      _ConstructionServicesHomePageState();
}

class _ConstructionServicesHomePageState
    extends State<ConstructionServicesHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWelcomeBanner(),
              _buildServicesGrid(context),
              _buildFeaturesSection(),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  // ================= BANNER =================

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 6.w),
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
      child: AspectRatio(
        aspectRatio: 1280 / 636,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/constructionbanner.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.all(6.w),
                child: Center(
                  child: Text(
                    'Khilonjiya Construction Services',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= SERVICES GRID =================

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      ServiceItem(
        title: 'RCC Works',
        subtitle: 'Reinforced concrete construction',
        icon: Icons.construction,
        colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => RCCWorksForm())),
      ),
      ServiceItem(
        title: 'Assam Type',
        subtitle: 'Traditional Assamese architecture',
        icon: Icons.home,
        colors: [Color(0xFFFFF3E0), Color(0xFFFFCC02)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => AssamTypeForm())),
      ),
      ServiceItem(
        title: 'Electrical Works',
        subtitle: 'Complete electrical solutions',
        icon: Icons.electrical_services,
        colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => ElectricalWorksForm())),
      ),
      ServiceItem(
        title: 'False Ceiling',
        subtitle: 'Modern ceiling designs',
        icon: Icons.architecture,
        colors: [Color(0xFFF3E5F5), Color(0xFFCE93D8)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => FalseCeilingForm())),
      ),
      ServiceItem(
        title: 'Plumbing',
        subtitle: 'Complete plumbing solutions',
        icon: Icons.plumbing,
        colors: [Color(0xFFFFF8E1), Color(0xFFFFCC02)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => PlumbingForm())),
      ),
      ServiceItem(
        title: 'Interior Design',
        subtitle: 'Custom interior solutions',
        icon: Icons.design_services,
        colors: [Color(0xFFFCE4EC), Color(0xFFF48FB1)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => InteriorDesignForm())),
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
        itemBuilder: (_, index) {
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
                gradient: LinearGradient(colors: service.colors),
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
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ================= FEATURES =================

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
            color: Color(0xFF2563EB),
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