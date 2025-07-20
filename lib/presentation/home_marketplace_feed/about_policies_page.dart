// File: screens/marketplace/about_policies_page.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AboutPoliciesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
        title: Text(
          'About & Policies',
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildSection(
            'About khilonjiya.com',
            'khilonjiya.com is your trusted online marketplace for buying, selling, and finding jobs in India. We connect millions of buyers and sellers across the country, making it easy to find what you need or sell what you don\'t.',
          ),
          _buildSection(
            'Privacy Policy',
            '''We respect your privacy and are committed to protecting your personal data. This privacy policy explains:

• What data we collect and why
• How we use your information
• Your rights regarding your data
• How we protect your information

We collect only necessary information to provide our services and never share your personal data with third parties without your consent.''',
          ),
          _buildSection(
            'Terms of Service',
            '''By using khilonjiya.com, you agree to:

• Provide accurate information in your listings
• Not post prohibited or illegal items
• Respect other users and communicate professionally
• Complete transactions honestly and fairly
• Report any suspicious activity

Violation of these terms may result in account suspension.''',
          ),
          _buildSection(
            'User Agreement',
            '''As a user of khilonjiya.com, you acknowledge that:

• You are responsible for your listings and transactions
• We are a platform and not party to transactions
• You will resolve disputes directly with other users
• You will not misuse the platform for fraudulent activities''',
          ),
          _buildSection(
            'Refund Policy',
            '''For premium services:

• Refunds are available within 24 hours of purchase
• No refunds after your listing goes live
• Contact support for refund requests
• Refunds processed within 5-7 business days''',
          ),
          _buildSection(
            'Community Guidelines',
            '''To maintain a safe marketplace:

• Be honest and transparent in all dealings
• Treat others with respect
• Report inappropriate content
• Don\'t spam or post duplicate listings
• Follow local laws and regulations''',
          ),
          _buildSection(
            'Safety Tips',
            '''Stay safe while buying/selling:

• Meet in public places for transactions
• Verify items before payment
• Don\'t share sensitive personal information
• Use secure payment methods
• Trust your instincts''',
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'For questions about these policies, contact us at legal@khilonjiya.com',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}