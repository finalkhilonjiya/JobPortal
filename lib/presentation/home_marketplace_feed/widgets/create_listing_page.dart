// File: screens/marketplace/widgets/create_listing_page.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';
import './listing_form_tab1.dart';
import './listing_form_tab2.dart';
import './listing_form_tab3.dart';
import './category_data.dart';
import '../../../services/listing_service.dart';
import '../../login_screen/mobile_auth_service.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({Key? key}) : super(key: key);

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;
  final ListingService _listingService = ListingService();
  final MobileAuthService _authService = MobileAuthService();
  bool _isSubmitting = false;

  // Form Data - Added latitude and longitude
  final Map<String, dynamic> _formData = {
    'title': '',
    'category': '',
    'subcategory': '',
    'price': '',
    'priceType': 'Fixed',
    'description': '',
    'images': <File>[],
    'location': '',
    'latitude': null,    // Add this
    'longitude': null,   // Add this
    'sellerName': '',
    'sellerPhone': '',
    'userType': 'Individual',
    'condition': 'Used',
    'brand': '',
    'model': '',
    'yearOfPurchase': '',
    'warrantyStatus': 'None',
    'availability': 'Immediately',
    'kilometresDriven': '',
    'fuelType': '',
    'transmissionType': '',
    'bedrooms': '',
    'bathrooms': '',
    'furnishingStatus': '',
    'termsAccepted': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _canMoveToNextTab(int currentTab) {
    switch (currentTab) {
      case 0:
        // Tab 1: Basic Details
        return _formData['title'].isNotEmpty &&
               _formData['category'].isNotEmpty &&
               _formData['subcategory'].isNotEmpty &&
               _formData['images'].isNotEmpty;
      case 1:
        // Tab 2: Product Details
        return _formData['price'].isNotEmpty &&
               _formData['description'].length >= 10;
      case 2:
        // Tab 3: Contact & Additional Info
        return _formData['sellerName'].isNotEmpty &&
               _formData['sellerPhone'].isNotEmpty &&
               _formData['location'].isNotEmpty &&
               _formData['termsAccepted'];
      default:
        return false;
    }
  }

  void _nextTab() {
    if (_canMoveToNextTab(_currentTab)) {
      if (_currentTab < 2) {
        _tabController.animateTo(_currentTab + 1);
      } else {
        _submitListing();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previousTab() {
    if (_currentTab > 0) {
      _tabController.animateTo(_currentTab - 1);
    }
  }

  // Map condition strings to database enum values
  String _mapConditionToEnum(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return 'new';
      case 'like new':
        return 'like_new';
      case 'good':
        return 'good';
      case 'fair':
        return 'fair';
      case 'poor':
        return 'poor';
      default:
        return 'good';
    }
  }

  void _submitListing() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    try {
      // AUTHENTICATION DEBUGGING WITH VISUAL FEEDBACK
      await _authService.debugAuthState(context: context);
      
      // Small delay to let user see the auth state feedback
      await Future.delayed(Duration(milliseconds: 500));
      
      // Try to force restore session
      final restored = await _authService.forceRestoreSession(context: context);
      
      if (!restored) {
        // Try refresh as fallback
        final refreshed = await _authService.refreshSession();
        
        if (!refreshed) {
          // Close loading dialog
          Navigator.pop(context);
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 30),
                  SizedBox(width: 10),
                  Text('Session Issue'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Authentication troubleshooting:'),
                  SizedBox(height: 10),
                  Text('• No stored session found'),
                  Text('• Session restoration failed'),
                  Text('• Session refresh failed'),
                  SizedBox(height: 10),
                  Text('Please login again to continue.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/mobile_login', 
                      (route) => false
                    );
                  },
                  child: Text('Login Again'),
                ),
              ],
            ),
          );
          return;
        } else {
          // Refresh succeeded, show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session refreshed successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
      
      // Final auth verification
      await _authService.debugAuthState(context: context);
      await Future.delayed(Duration(milliseconds: 500));

      // Upload images first
      List<String> imageUrls = [];
      if (_formData['images'].isNotEmpty) {
        // Show image upload feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading ${_formData['images'].length} images...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
        
        imageUrls = await _listingService.uploadImages(_formData['images']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Images uploaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Prepare additional data based on category
      Map<String, dynamic> additionalData = {};

      // Add category-specific fields if they have values
      if (_formData['brand'].isNotEmpty) additionalData['brand'] = _formData['brand'];
      if (_formData['model'].isNotEmpty) additionalData['model'] = _formData['model'];
      if (_formData['yearOfPurchase'].isNotEmpty) additionalData['yearOfPurchase'] = _formData['yearOfPurchase'];
      if (_formData['warrantyStatus'].isNotEmpty) additionalData['warrantyStatus'] = _formData['warrantyStatus'];
      if (_formData['availability'].isNotEmpty) additionalData['availability'] = _formData['availability'];

      // Vehicle specific
      if (_formData['kilometresDriven'].isNotEmpty) additionalData['kilometresDriven'] = _formData['kilometresDriven'];
      if (_formData['fuelType'].isNotEmpty) additionalData['fuelType'] = _formData['fuelType'];
      if (_formData['transmissionType'].isNotEmpty) additionalData['transmissionType'] = _formData['transmissionType'];

      // Real estate specific
      if (_formData['bedrooms'].isNotEmpty) additionalData['bedrooms'] = _formData['bedrooms'];
      if (_formData['bathrooms'].isNotEmpty) additionalData['bathrooms'] = _formData['bathrooms'];
      if (_formData['furnishingStatus'].isNotEmpty) additionalData['furnishingStatus'] = _formData['furnishingStatus'];

      // Show listing creation feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creating listing...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      // Create listing with coordinates
      final result = await _listingService.createListing(
        title: _formData['title'],
        categoryId: _formData['subcategory'],
        description: _formData['description'],
        price: double.parse(_formData['price']),
        priceType: _formData['priceType'],
        condition: _mapConditionToEnum(_formData['condition']),
        location: _formData['location'],
        latitude: _formData['latitude'],
        longitude: _formData['longitude'],
        sellerName: _formData['sellerName'],
        sellerPhone: _formData['sellerPhone'],
        userType: _formData['userType'],
        imageUrls: imageUrls,
        additionalData: additionalData,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog with details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Success!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your listing has been created successfully.'),
              SizedBox(height: 10),
              Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Title: ${_formData['title']}'),
              Text('• Price: ₹${_formData['price']}'),
              Text('• Location: ${_formData['location']}'),
              if (imageUrls.isNotEmpty) Text('• Images: ${imageUrls.length} uploaded'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close listing page
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Determine error type and show appropriate feedback
      String errorTitle = 'Error';
      String errorMessage = e.toString();
      Color errorColor = Colors.red;
      
      if (e.toString().contains('Authentication required') || 
          e.toString().contains('Authentication expired') ||
          e.toString().contains('JWT') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        
        errorTitle = 'Authentication Error';
        errorColor = Colors.orange;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: errorColor, size: 30),
                SizedBox(width: 10),
                Text(errorTitle),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Authentication failed during listing creation.'),
                SizedBox(height: 10),
                Text('Technical details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(errorMessage, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                SizedBox(height: 10),
                Text('Please login again to continue.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/mobile_login', 
                    (route) => false
                  );
                },
                child: Text('Login Again'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
        );
      } else {
        // Show detailed error dialog for non-auth errors
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Text('Creation Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Failed to create your listing.'),
                SizedBox(height: 10),
                Text('Error details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    errorMessage, 
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace')
                  ),
                ),
                SizedBox(height: 10),
                Text('Please check your data and try again.', style: TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
        title: Text(
          'Create Listing',
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Color(0xFF2563EB),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF2563EB),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
              tabs: [
                Tab(
                  icon: Icon(Icons.info_outline, size: 20),
                  text: 'Basic Info',
                ),
                Tab(
                  icon: Icon(Icons.description_outlined, size: 20),
                  text: 'Details',
                ),
                Tab(
                  icon: Icon(Icons.contact_phone_outlined, size: 20),
                  text: 'Contact',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          ListingFormTab1(
            formData: _formData,
            onDataChanged: (data) => setState(() => _formData.addAll(data)),
          ),
          ListingFormTab2(
            formData: _formData,
            onDataChanged: (data) => setState(() => _formData.addAll(data)),
          ),
          ListingFormTab3(
            formData: _formData,
            onDataChanged: (data) => setState(() => _formData.addAll(data)),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentTab > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _previousTab,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    side: BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Previous',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ),
            if (_currentTab > 0) SizedBox(width: 3.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextTab,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentTab == 2 ? 'Submit' : 'Next',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}