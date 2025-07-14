import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/additional_details_widget.dart';
import './widgets/category_selection_widget.dart';
import './widgets/listing_details_widget.dart';
import './widgets/location_picker_widget.dart';
import './widgets/photo_upload_widget.dart';
import './widgets/preview_listing_widget.dart';
import './widgets/price_condition_widget.dart';

class CreateListing extends StatefulWidget {
  const CreateListing({super.key});

  @override
  State<CreateListing> createState() => _CreateListingState();
}

class _CreateListingState extends State<CreateListing>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;
  int _currentStep = 0;
  bool _isLoading = false;

  // Form data
  final Map<String, dynamic> _listingData = {
    'photos': <String>[],
    'category': '',
    'title': '',
    'description': '',
    'price': '',
    'isNegotiable': false,
    'condition': '',
    'location': '',
    'additionalDetails': <String, dynamic>{},
  };

  final List<String> _stepTitles = [
    'Photos',
    'Category',
    'Details',
    'Price & Condition',
    'Location',
    'Additional Info',
    'Preview'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: _stepTitles.length, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validation for required fields
    if (_currentStep == 0 && (_listingData['photos'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo.')),
      );
      return;
    }
    if (_currentStep == 2 && (_listingData['title'] as String).trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }
    if (_currentStep == 2 && (_listingData['description'] as String).trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description is required.')),
      );
      return;
    }
    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabController.animateTo(_currentStep);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabController.animateTo(_currentStep);
    }
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _tabController.animateTo(step);
  }

  Future<void> _publishListing() async {
    // Final validation before publishing
    if ((_listingData['photos'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo.')),
      );
      return;
    }
    if ((_listingData['title'] as String).trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }
    if ((_listingData['description'] as String).trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description is required.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.getSuccessColor(true),
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              'Listing Published!',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
          ],
        ),
        content: Text(
          'Your listing has been successfully published and is now live on the marketplace.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/home-marketplace-feed');
            },
            child: const Text('View Listing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Create Another'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/home-marketplace-feed');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _listingData.clear();
      _listingData.addAll({
        'photos': <String>[],
        'category': '',
        'title': '',
        'description': '',
        'price': '',
        'isNegotiable': false,
        'condition': '',
        'location': '',
        'additionalDetails': <String, dynamic>{},
      });
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _tabController.animateTo(0);
  }

  bool _onWillPopSync() {
    if (_currentStep > 0) {
      _previousStep();
      return false;
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    if (_currentStep > 0) {
      _previousStep();
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _onWillPopSync(),
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Create Listing',
            style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
          ),
          leading: IconButton(
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          actions: [
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(8.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Column(
                children: [
                  // Progress indicator
                  Row(
                    children: List.generate(
                      _stepTitles.length,
                      (index) => Expanded(
                        child: Container(
                          height: 0.5.h,
                          margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  // Step indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of ${_stepTitles.length}',
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                      Text(
                        _stepTitles[_currentStep],
                        style: AppTheme.lightTheme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                  _tabController.animateTo(index);
                },
                children: [
                  PhotoUploadWidget(
                    photos: (_listingData['photos'] as List<String>),
                    onPhotosChanged: (photos) {
                      setState(() {
                        _listingData['photos'] = photos;
                      });
                    },
                  ),
                  CategorySelectionWidget(
                    selectedCategory: _listingData['category'] as String,
                    onCategorySelected: (category) {
                      setState(() {
                        _listingData['category'] = category;
                      });
                    },
                  ),
                  ListingDetailsWidget(
                    title: _listingData['title'] as String,
                    description: _listingData['description'] as String,
                    category: _listingData['category'] as String,
                    onTitleChanged: (title) {
                      setState(() {
                        _listingData['title'] = title;
                      });
                    },
                    onDescriptionChanged: (description) {
                      setState(() {
                        _listingData['description'] = description;
                      });
                    },
                  ),
                  PriceConditionWidget(
                    price: _listingData['price'] as String,
                    isNegotiable: _listingData['isNegotiable'] as bool,
                    condition: _listingData['condition'] as String,
                    onPriceChanged: (price) {
                      setState(() {
                        _listingData['price'] = price;
                      });
                    },
                    onNegotiableChanged: (isNegotiable) {
                      setState(() {
                        _listingData['isNegotiable'] = isNegotiable;
                      });
                    },
                    onConditionChanged: (condition) {
                      setState(() {
                        _listingData['condition'] = condition;
                      });
                    },
                  ),
                  LocationPickerWidget(
                    location: _listingData['location'] as String,
                    onLocationChanged: (location) {
                      setState(() {
                        _listingData['location'] = location;
                      });
                    },
                  ),
                  AdditionalDetailsWidget(
                    category: _listingData['category'] as String,
                    details: _listingData['additionalDetails']
                        as Map<String, dynamic>,
                    onDetailsChanged: (details) {
                      setState(() {
                        _listingData['additionalDetails'] = details;
                      });
                    },
                  ),
                  PreviewListingWidget(
                    listingData: _listingData,
                    onEdit: _goToStep,
                  ),
                ],
              ),
            ),
            // Bottom navigation
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) SizedBox(width: 4.w),
                    Expanded(
                      flex: 2,
                      child: _currentStep == _stepTitles.length - 1
                          ? ElevatedButton(
                              onPressed: _isLoading ? null : _publishListing,
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppTheme
                                              .lightTheme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : const Text('Publish Listing'),
                            )
                          : ElevatedButton(
                              onPressed: _nextStep,
                              child: const Text('Next'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
