import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TermsPrivacyWidget extends StatefulWidget {
  const TermsPrivacyWidget({Key? key}) : super(key: key);

  @override
  State<TermsPrivacyWidget> createState() => _TermsPrivacyWidgetState();
}

class _TermsPrivacyWidgetState extends State<TermsPrivacyWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _termsContent = [
    {
      "title": "Account Registration",
      "content":
          "By creating an account on MarketPlace Pro, you agree to provide accurate and complete information. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account."
    },
    {
      "title": "User Conduct",
      "content":
          "Users must not engage in fraudulent activities, post misleading listings, or violate any applicable laws. We reserve the right to suspend or terminate accounts that violate our community guidelines."
    },
    {
      "title": "Listing Guidelines",
      "content":
          "All listings must be accurate, legal, and comply with our content policies. Prohibited items include illegal goods, counterfeit products, and items that violate intellectual property rights."
    },
    {
      "title": "Transaction Terms",
      "content":
          "MarketPlace Pro facilitates connections between buyers and sellers but is not responsible for the actual transactions. Users are responsible for their own transactions and any disputes that may arise."
    },
    {
      "title": "Limitation of Liability",
      "content":
          "MarketPlace Pro shall not be liable for any direct, indirect, incidental, or consequential damages arising from the use of our platform or services."
    },
  ];

  final List<Map<String, dynamic>> _privacyContent = [
    {
      "title": "Information We Collect",
      "content":
          "We collect information you provide directly, such as your name, email, phone number, and profile information. We also collect usage data and device information to improve our services."
    },
    {
      "title": "How We Use Your Information",
      "content":
          "Your information is used to provide and improve our services, facilitate transactions, send notifications, and ensure platform security. We do not sell your personal information to third parties."
    },
    {
      "title": "Information Sharing",
      "content":
          "We may share your information with other users as necessary for transactions, with service providers who assist our operations, and as required by law or to protect our rights."
    },
    {
      "title": "Data Security",
      "content":
          "We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction."
    },
    {
      "title": "Your Rights",
      "content":
          "You have the right to access, update, or delete your personal information. You can also opt out of certain communications and control your privacy settings within the app."
    },
    {
      "title": "Contact Us",
      "content":
          "If you have questions about this Privacy Policy or our data practices, please contact us at privacy@marketplacepro.com or through the app's support section."
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Legal Information',
                    style: AppTheme.lightTheme.textTheme.headlineSmall,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor:
                  AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Terms of Service'),
                Tab(text: 'Privacy Policy'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContentList(_termsContent),
                _buildContentList(_privacyContent),
              ],
            ),
          ),

          // Bottom button
          Padding(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I Understand'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList(List<Map<String, dynamic>> content) {
    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: content.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final item = content[index];
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title'] as String,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                item['content'] as String,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}
