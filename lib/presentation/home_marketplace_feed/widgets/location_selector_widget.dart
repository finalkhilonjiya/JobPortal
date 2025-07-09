import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

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
          color: AppTheme.lightTheme.colorScheme.primaryContainer.withAlpha(77),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: useGpsLocation 
                ? AppTheme.lightTheme.colorScheme.primary.withAlpha(77)
                : AppTheme.lightTheme.colorScheme.outline.withAlpha(77),
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
      builder: (context) => Container(
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
            
            // Location List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 2.w),
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  final isSelected = selectedLocation == location;
                  final isDetectLocation = location == 'Detect Location';
                  
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.primaryContainer.withAlpha(77),
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
                      onLocationChanged(location);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}