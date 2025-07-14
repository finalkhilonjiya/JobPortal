import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:uuid/uuid.dart';

class EnhancedLocationSelectorWidget extends StatelessWidget {
  final String selectedLocation;
  final List<String> locations;
  final bool isLoading;
  final bool useGpsLocation;
  final Function(String) onLocationChanged;

  const EnhancedLocationSelectorWidget({
    Key? key,
    required this.selectedLocation,
    required this.locations,
    required this.onLocationChanged,
    this.isLoading = false,
    this.useGpsLocation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showLocationPicker(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primaryContainer.withValues(alpha: 77),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: useGpsLocation 
                ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 77)
                : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 77),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Location Icon
            Container(
              padding: EdgeInsets.all(1.5.w),
              decoration: BoxDecoration(
                color: useGpsLocation 
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                useGpsLocation ? Icons.my_location : Icons.location_on_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
            
            SizedBox(width: 2.w),
            
            // Location Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    useGpsLocation ? 'Current Location' : 'Location',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: 0.2.h),
                  Row(
                    children: [
                      if (isLoading) ...[
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 2.w),
                      ],
                      Expanded(
                        child: Text(
                          isLoading ? 'Detecting...' : _getDisplayLocation(),
                          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: useGpsLocation 
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Dropdown Arrow
            Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayLocation() {
    if (selectedLocation == 'Detect Location') {
      return useGpsLocation ? 'Current Location' : 'Tap to select';
    }
    return selectedLocation;
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LocationPickerModal(
        selectedLocation: selectedLocation,
        locations: locations,
        onLocationChanged: onLocationChanged,
      ),
    );
  }
}

class _LocationPickerModal extends StatefulWidget {
  final String selectedLocation;
  final List<String> locations;
  final Function(String) onLocationChanged;

  const _LocationPickerModal({
    required this.selectedLocation,
    required this.locations,
    required this.onLocationChanged,
  });

  @override
  State<_LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<_LocationPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  final FlutterGooglePlacesSdk _places = FlutterGooglePlacesSdk('YOUR_GOOGLE_API_KEY');
  final Uuid _uuid = Uuid();
  String _sessionToken = '';
  List<AutocompletePrediction> _predictions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _sessionToken = _uuid.v4();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final input = _searchController.text;
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final result = await _places.findAutocompletePredictions(
        input,
        sessionToken: _sessionToken,
        countries: ['IN'],
      );
      setState(() {
        _predictions = result.predictions;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 3.w),
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
                Icon(
                  Icons.location_on,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Select Location',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // Search Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a location',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Autocomplete Suggestions
          if (_isSearching)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (_predictions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text(prediction.fullText),
                    onTap: () {
                      widget.onLocationChanged(prediction.fullText);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            )
          else
            // Fallback to static locations if no search or no results
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 2.w),
                itemCount: widget.locations.length,
                itemBuilder: (context, index) {
                  final location = widget.locations[index];
                  final isSelected = widget.selectedLocation == location;
                  final isDetectLocation = location == 'Detect Location';
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.primaryContainer.withValues(alpha: 77),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDetectLocation ? Icons.my_location : Icons.location_city,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.lightTheme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      location,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: isDetectLocation
                        ? Text(
                            'Use GPS to find nearby listings',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onLocationChanged(location);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
