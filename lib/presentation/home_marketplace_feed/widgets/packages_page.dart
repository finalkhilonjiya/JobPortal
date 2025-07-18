import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PackagesPage extends StatelessWidget {
  final List<Map<String, dynamic>> packages = [
    {
      'name': 'Basic',
      'price': 0,
      'duration': 'Free',
      'features': [
        'Post up to 5 ads per month',
        'Basic listing visibility',
        'Standard support',
        '30 days listing duration',
      ],
      'color': Colors.grey,
      'isPopular': false,
    },
    {
      'name': 'Premium',
      'price': 499,
      'duration': 'per month',
      'features': [
        'Post unlimited ads',
        'Featured listings',
        'Priority in search results',
        'Premium badge on ads',
        '60 days listing duration',
        'Dedicated support',
      ],
      'color': Color(0xFF2563EB),
      'isPopular': true,
    },
    {
      'name': 'Business',
      'price': 1999,
      'duration': 'per month',
      'features': [
        'Everything in Premium',
        'Bulk listing management',
        'Analytics dashboard',
        'API access',
        '90 days listing duration',
        'Priority 24/7 support',
        'Custom branding',
      ],
      'color': Color(0xFFFFD700),
      'isPopular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2563EB),
        title: Text('Premium Packages', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Upgrade to premium for better visibility and more features',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 3.h),
            ...packages.map((package) => _buildPackageCard(context, package)),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, Map<String, dynamic> package) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: package['isPopular']
                    ? package['color']
                    : Colors.grey[300]!,
                width: package['isPopular'] ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      package['name'],
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: package['color'],
                      ),
                    ),
                    if (package['price'] > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${package['price']}',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            package['duration'],
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: 2.h),
                ...package['features'].map<Widget>((feature) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.5.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: package['color'],
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (package['price'] == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('You are already on the Basic plan')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment gateway will be integrated soon'),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: package['color'],
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      package['price'] == 0 ? 'Current Plan' : 'Choose Plan',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (package['isPopular'])
            Positioned(
              top: -1,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
