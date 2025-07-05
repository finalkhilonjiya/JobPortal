import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LocationPickerWidget extends StatefulWidget {
  final String location;
  final Function(String) onLocationChanged;

  const LocationPickerWidget({
    super.key,
    required this.location,
    required this.onLocationChanged,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late TextEditingController _locationController;
  bool _useCurrentLocation = false;
  bool _showExactLocation = true;
  String _currentLocationText = '';

  final List<String> _recentLocations = [
    'New York, NY',
    'Los Angeles, CA',
    'Chicago, IL',
    'Houston, TX',
    'Phoenix, AZ',
  ];

  final List<String> _popularCities = [
    'New York, NY',
    'Los Angeles, CA',
    'Chicago, IL',
    'Houston, TX',
    'Phoenix, AZ',
    'Philadelphia, PA',
    'San Antonio, TX',
    'San Diego, CA',
    'Dallas, TX',
    'San Jose, CA',
  ];

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.location);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _getCurrentLocation() {
    // Simulate GPS location detection
    setState(() {
      _currentLocationText = 'San Francisco, CA';
    });
  }

  void _useGPSLocation() {
    setState(() {
      _useCurrentLocation = true;
      _locationController.text = _currentLocationText;
    });
    widget.onLocationChanged(_currentLocationText);
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Select Location',
                style: AppTheme.lightTheme.textTheme.titleLarge,
              ),
              SizedBox(height: 2.h),

              // Search field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Current location
                    ListTile(
                      leading: CustomIconWidget(
                        iconName: 'my_location',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 24,
                      ),
                      title: const Text('Use Current Location'),
                      subtitle: Text(_currentLocationText),
                      onTap: () {
                        Navigator.pop(context);
                        _useGPSLocation();
                      },
                    ),

                    const Divider(),

                    // Recent locations
                    if (_recentLocations.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 1.h),
                        child: Text(
                          'Recent Locations',
                          style: AppTheme.lightTheme.textTheme.titleSmall,
                        ),
                      ),
                      ...(_recentLocations.map((location) => ListTile(
                            leading: CustomIconWidget(
                              iconName: 'history',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            title: Text(location),
                            onTap: () {
                              Navigator.pop(context);
                              _locationController.text = location;
                              widget.onLocationChanged(location);
                              setState(() {
                                _useCurrentLocation = false;
                              });
                            },
                          ))),
                      const Divider(),
                    ],

                    // Popular cities
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      child: Text(
                        'Popular Cities',
                        style: AppTheme.lightTheme.textTheme.titleSmall,
                      ),
                    ),
                    ...(_popularCities.map((city) => ListTile(
                          leading: CustomIconWidget(
                            iconName: 'location_city',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          title: Text(city),
                          onTap: () {
                            Navigator.pop(context);
                            _locationController.text = city;
                            widget.onLocationChanged(city);
                            setState(() {
                              _useCurrentLocation = false;
                            });
                          },
                        ))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            'Set your location to help buyers find your item',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),

          // Current location card
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'location_on',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Location',
                            style: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            _currentLocationText,
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _useGPSLocation,
                      child: const Text('Use This'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Manual location input
          Text(
            'Or Enter Manually',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          GestureDetector(
            onTap: _showLocationPicker,
            child: AbsorbPointer(
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Tap to select location',
                  suffixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'arrow_drop_down',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Privacy settings
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'privacy_tip',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Privacy Settings',
                      style: AppTheme.lightTheme.textTheme.titleSmall,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Show exact location toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show Exact Location',
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _showExactLocation
                                ? 'Buyers will see your exact address'
                                : 'Buyers will see approximate area only',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _showExactLocation,
                      onChanged: (value) {
                        setState(() {
                          _showExactLocation = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Location tips
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Location Tips',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                ...[
                  'Accurate location helps buyers find you',
                  'Consider meeting in public places for safety',
                  'You can hide exact address until meeting',
                  'Local buyers are more likely to purchase',
                ].map((tip) => Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.getSuccessColor(true),
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              tip,
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
