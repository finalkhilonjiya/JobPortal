// File: widgets/listing_form_tab3.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.formData['sellerName'] ?? '';
    _phoneController.text = widget.formData['sellerPhone'] ?? '';
    _locationController.text = widget.formData['location'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    if (_isDetectingLocation) return;

    setState(() => _isDetectingLocation = true);

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions permanently denied. Please enable in settings.';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('GPS Position: Lat ${position.latitude}, Lng ${position.longitude}');

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        
        // Build full address
        String address = '';
        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += '${place.locality}, ';
        }
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          address += '${place.subAdministrativeArea}, ';
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          address += '${place.administrativeArea}';
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address += ' - ${place.postalCode}';
        }

        // Clean up address (remove trailing commas/spaces)
        address = address.trim();
        if (address.endsWith(',')) {
          address = address.substring(0, address.length - 1);
        }

        debugPrint('Reverse geocoded address: $address');

        setState(() {
          _locationController.text = address;
          _isDetectingLocation = false;
        });

        // Update form data with address and coordinates
        widget.onDataChanged({
          'location': address,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location captured successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'Could not determine address from coordinates';
      }
    } catch (e) {
      setState(() => _isDetectingLocation = false);
      debugPrint('Location detection error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to detect location: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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
            maxLength: 10,
            decoration: InputDecoration(
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone, color: Color(0xFF2563EB)),
              prefixText: '+91 ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              counterText: '',
            ),
            onChanged: (value) => widget.onDataChanged({'sellerPhone': value}),
          ),
          SizedBox(height: 2.h),

          // Location
          Text(
            'Location *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Enter location or detect',
                    prefixIcon: Icon(Icons.location_on, color: Color(0xFF2563EB)),
                    suffixIcon: _locationController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _locationController.clear();
                              widget.onDataChanged({
                                'location': '',
                                'latitude': null,
                                'longitude': null,
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => widget.onDataChanged({'location': value}),
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: _isDetectingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.my_location, color: Colors.white),
                  onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
                  tooltip: 'Use current location',
                ),
              ),
            ],
          ),

          // Location confirmation
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
                  Icon(Icons.check_circle, color: Colors.green, size: 5.w),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                      value: widget.formData['termsAccepted'] ?? false,
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
                            'Location helps buyers find listings near them',
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