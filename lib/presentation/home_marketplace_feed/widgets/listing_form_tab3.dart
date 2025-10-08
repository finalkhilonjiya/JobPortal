// File: widgets/listing_form_tab3.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import '../../../widgets/location_autocomplete.dart';
import '../../../services/location_service.dart';

class ListingFormTab3 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ListingFormTab3({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ListingFormTab3> createState() => _ListingFormTab3State();
}

class _ListingFormTab3State extends State<ListingFormTab3> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final LocationService _locationService = LocationService();
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.formData['sellerName'];
    _phoneController.text = widget.formData['sellerPhone'];
    _locationController.text = widget.formData['location'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions permanently denied';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('GPS Position: Lat ${position.latitude}, Lng ${position.longitude}');

      // Find nearest location from database
      final nearestLocation = await _locationService.findNearestLocation(
        position.latitude,
        position.longitude,
      );

      String locationText;
      double finalLat = position.latitude;
      double finalLng = position.longitude;

      if (nearestLocation != null) {
        locationText = nearestLocation.displayName;
        // Use the location's coordinates if it's an exact match
        if (!nearestLocation.displayName.startsWith('Near ')) {
          finalLat = nearestLocation.latitude;
          finalLng = nearestLocation.longitude;
        }
        debugPrint('Found nearest location: $locationText');
      } else {
        // Fallback if no location found in database
        locationText = 'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        debugPrint('No location found in database, using coordinates');
      }

      setState(() {
        _locationController.text = locationText;
        _isDetectingLocation = false;
      });

      // Update form data with location and coordinates
      debugPrint('Saving to formData: location=$locationText, lat=$finalLat, lng=$finalLng');
      widget.onDataChanged({
        'location': locationText,
        'latitude': finalLat,
        'longitude': finalLng,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location captured: $locationText'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isDetectingLocation = false);
      debugPrint('Location detection error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to detect location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onLocationSelected(LocationResult location) {
    setState(() {
      _locationController.text = location.displayName;
    });

    debugPrint('Location selected: ${location.displayName}, Lat: ${location.latitude}, Lng: ${location.longitude}');

    // Update form data with location and coordinates
    widget.onDataChanged({
      'location': location.displayName,
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller Name
          Text(
            'Seller Name *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person, color: Color(0xFF2563EB)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => widget.onDataChanged({'sellerName': value}),
          ),
          SizedBox(height: 2.h),

          // Phone Number
          Text(
            'Phone Number *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone, color: Color(0xFF2563EB)),
              prefixText: '+91 ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => widget.onDataChanged({'sellerPhone': value}),
          ),
          SizedBox(height: 2.h),

          // Location with Autocomplete
          Text(
            'Location *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: LocationAutocomplete(
                  controller: _locationController,
                  onLocationSelected: _onLocationSelected,
                  hintText: 'Enter city name (e.g., Guwahati)',
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: _isDetectingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        )
                      : Icon(Icons.my_location, color: Color(0xFF2563EB)),
                  onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
                  tooltip: 'Use current location',
                ),
              ),
            ],
          ),

          // Location confirmation with actual place name
          if (widget.formData['latitude'] != null && widget.formData['longitude'] != null)
            Container(
              margin: EdgeInsets.only(top: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location captured ✓',
                          style: TextStyle(
                            fontSize: 11.sp, 
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          widget.formData['location'] ?? '',
                          style: TextStyle(
                            fontSize: 10.sp, 
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          'Lat: ${widget.formData['latitude']?.toStringAsFixed(6)}, Lng: ${widget.formData['longitude']?.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 9.sp, 
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (!widget.formData['location'].toString().startsWith('Near'))
                          Text(
                            'Exact location match',
                            style: TextStyle(
                              fontSize: 9.sp, 
                              color: Colors.green[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 2.h),

          // User Type
          Text(
            'User Type',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('Individual'),
                  subtitle: Text('I am selling personal items'),
                  value: 'Individual',
                  groupValue: widget.formData['userType'],
                  onChanged: (value) {
                    if (value != null) {
                      widget.onDataChanged({'userType': value});
                    }
                  },
                ),
                Divider(height: 1),
                RadioListTile<String>(
                  title: Text('Business/Dealer'),
                  subtitle: Text('I am a professional seller'),
                  value: 'business',
                  groupValue: widget.formData['userType'],
                  onChanged: (value) {
                    if (value != null) {
                      widget.onDataChanged({'userType': value});
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Terms & Conditions
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 1.h),
                Text(
                  '• Your ad will be live for 30 days\n'
                  '• We reserve the right to remove inappropriate content\n'
                  '• Provide accurate information about your product\n'
                  '• You are responsible for the transaction\n'
                  '• Location coordinates help buyers find nearby listings',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Checkbox(
                      value: widget.formData['termsAccepted'],
                      onChanged: (value) {
                        if (value != null) {
                          widget.onDataChanged({'termsAccepted': value});
                        }
                      },
                      activeColor: Color(0xFF2563EB),
                    ),
                    Expanded(
                      child: Text(
                        'I agree to the Terms & Conditions *',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Info Section
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your contact details will be shared with interested buyers',
                        style: TextStyle(fontSize: 10.sp, color: Color(0xFF2563EB)),
                      ),
                      if (widget.formData['latitude'] != null && widget.formData['longitude'] != null)
                        Padding(
                          padding: EdgeInsets.only(top: 0.5.h),
                          child: Text(
                            'Location coordinates help buyers find listings near them and enable distance-based sorting',
                            style: TextStyle(fontSize: 9.sp, color: Color(0xFF2563EB)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}