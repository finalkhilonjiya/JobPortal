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

  // Form Data - Added conditions list for multi-select
  final Map<String, dynamic> _formData = {
    'title': '',
    'category': '',
    'subcategory': '',
    'price': '',
    'priceType': 'Fixed',
    'description': '',
    'images': <File>[],
    'location': '',
    'latitude': null,
    'longitude': null,
    'sellerName': '',
    'sellerPhone': '',
    'userType': 'Individual',
    'condition': 'good', // Single condition for backward compatibility
    'conditions': <String>[], // Multi-select conditions array
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
        // Tab 2: Product Details - Changed to 10 words minimum
        final wordCount = _formData['description'].toString().split(' ').where((word) => word.isNotEmpty).length;
        final hasConditions = _formData['conditions'] != null && 
                              (_formData['conditions'] as List).isNotEmpty;
        
        return _formData['price'].isNotEmpty &&
               wordCount >= 10 &&
               hasConditions;
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
      // Provide specific feedback based on current tab
      String errorMessage = _getValidationErrorMessage(_currentTab);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _getValidationErrorMessage(int tab) {
    switch (tab) {
      case 0:
        if (_formData['title'].isEmpty) return 'Please enter a title';
        if (_formData['category'].isEmpty) return 'Please select a category';
        if (_formData['subcategory'].isEmpty) return 'Please select a subcategory';
        if (_formData['images'].isEmpty) return 'Please add at least one image';
        return 'Please fill all required fields';
      
      case 1:
        if (_formData['price'].isEmpty) return 'Please enter a price';
        
        final wordCount = _formData['description'].toString().split(' ').where((word) => word.isNotEmpty).length;
        if (wordCount < 10) return 'Description must be at least 10 words';
        
        final hasConditions = _formData['conditions'] != null && 
                              (_formData['conditions'] as List).isNotEmpty;
        if (!hasConditions) return 'Please select at least one property feature';
        
        return 'Please fill all required fields';
      
      case 2:
        if (_formData['sellerName'].isEmpty) return 'Please enter your name';
        if (_formData['sellerPhone'].isEmpty) return 'Please enter your phone number';
        if (_formData['location'].isEmpty) return 'Please select a location';
        if (!_formData['termsAccepted']) return 'Please accept terms and conditions';
        return 'Please fill all required fields';
      
      default:
        return 'Please fill all required fields';
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
        return 'excellent';
      case 'furnished':
        return 'good';
      case 'not furnished':
        return 'fair';
      case 'like new':
        return 'excellent';
      case 'good':
        return 'good';
      case 'fair':
        return 'fair';
      case 'poor':
        return 'needs_renovation';
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
      // AUTHENTICATION DEBUGGING AND RESTORATION
      debugPrint('=== PRE-SUBMISSION AUTH CHECK ===');

      // Try to ensure valid session first
      final sessionValid = await _authService.ensureValidSession();
      debugPrint('Session validation result: $sessionValid');

      if (!sessionValid) {
        debugPrint('Session validation failed, trying force restore');
        // Try to force restore session
        final restored = await _authService.forceRestoreSession();
        debugPrint('Force restore result: $restored');

        if (!restored) {
          // Close loading dialog
          Navigator.pop(context);

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 30),
                  SizedBox(width: 10),
                  Text('Authentication Issue'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your session could not be restored.'),
                  SizedBox(height: 10),
                  Text('This may be due to:'),
                  Text('• Expired login session'),
                  Text('• Network connectivity issues'),
                  Text('• Server authentication problems'),
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
        }
      }

      debugPrint('Authentication successful, proceeding with listing creation');

      // Upload images first
      List<String> imageUrls = [];
      if (_formData['images'].isNotEmpty) {
        debugPrint('Uploading ${_formData['images'].length} images...');
        imageUrls = await _listingService.uploadImages(_formData['images']);
        debugPrint('Successfully uploaded images: $imageUrls');
      }

      // Prepare additional data based on category
      Map<String, dynamic> additionalData = {};

      // Add multi-select conditions to additional data
      if (_formData['conditions'] != null && (_formData['conditions'] as List).isNotEmpty) {
        additionalData['conditions'] = _formData['conditions'];
        debugPrint('Adding conditions to additional data: ${_formData['conditions']}');
      }

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

      debugPrint('About to call createListing with title: ${_formData['title']}');

      // Create listing with coordinates and conditions
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

      debugPrint('Listing creation successful: $result');

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
              if ((_formData['conditions'] as List).isNotEmpty)
                Text('• Features: ${(_formData['conditions'] as List).join(', ')}'),
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
      debugPrint('Listing creation error: $e');

      // Close loading dialog
      Navigator.pop(context);

      // Determine error type and show appropriate feedback
      if (e.toString().contains('Authentication required') || 
          e.toString().contains('Authentication expired') ||
          e.toString().contains('JWT') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 30),
                SizedBox(width: 10),
                Text('Authentication Error'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Authentication failed during listing creation.'),
                SizedBox(height: 10),
                Text('This usually means your login session has expired.'),
                SizedBox(height: 10),
                Text('Error details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    e.toString(), 
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace')
                  ),
                ),
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
                    e.toString(), 
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