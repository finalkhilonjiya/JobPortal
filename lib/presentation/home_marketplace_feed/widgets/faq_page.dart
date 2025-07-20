// File: screens/marketplace/faq_page.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FAQPage extends StatelessWidget {
  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I create a listing?',
      'answer': 'Tap the "+" button at the bottom of the screen and follow the simple steps to create your listing.',
    },
    {
      'question': 'Is it free to post listings?',
      'answer': 'Yes, basic listings are completely free. Premium listings are available for ₹299 for enhanced visibility.',
    },
    {
      'question': 'How do I contact a seller?',
      'answer': 'You can contact sellers directly through the call or WhatsApp buttons on each listing.',
    },
    {
      'question': 'How long do listings stay active?',
      'answer': 'Free listings stay active for 30 days. Premium listings get extended visibility.',
    },
    {
      'question': 'Can I edit my listing after posting?',
      'answer': 'Yes, you can edit or delete your listings anytime from your profile section.',
    },
    {
      'question': 'Is my personal information safe?',
      'answer': 'We take privacy seriously. Only the information you choose to share in your listing is visible to buyers.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
        title: Text(
          'FAQ',
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
          // FAQ List
          ...faqs.map((faq) => _buildFAQItem(faq)).toList(),
          
          SizedBox(height: 4.h),
          
          // Contact Section
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Still need help?',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.phone, color: Color(0xFF2563EB)),
                    SizedBox(width: 2.w),
                    Text(
                      '+91 98765 43210',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(Icons.email, color: Color(0xFF2563EB)),
                    SizedBox(width: 2.w),
                    Text(
                      'support@khilonjiya.com',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, String> faq) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
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
      child: ExpansionTile(
        title: Text(
          faq['question']!,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              faq['answer']!,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}