// File: widgets/listing_form_tab3.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/google_places_service.dart';
import 'dart:async';

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
  final GooglePlacesService _placesService = GooglePlacesService();
  
  bool _isDetectingLocation = false;
  bool _isSearching = false;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _locationFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.formData['sellerName'];
    _phoneController.text = widget.formData['sellerPhone'];
    _locationController.text = widget.formData['location'];
    
    _locationController.addListener(_onLocationTextChanged);
    _locationFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_locationFocusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onLocationTextChanged() {
    _debounceTimer?.cancel();

    final query = _locationController.text.trim();

    if (query.length < 2) {
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final results = await _placesService.searchPlaces(query);

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });

        if (results.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 8.w,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(maxHeight: 40.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return InkWell(
                    onTap: () => _onSuggestionSelected(suggestion),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 3.w,
                      ),
                      decoration: BoxDecoration(
                        border: index != _suggestions.length - 1
                            ? Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Color(0xFF2563EB),
                            size: 5.w,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.mainText,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (suggestion.secondaryText.isNotEmpty)
                                  Text(
                                    suggestion.secondaryText,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    _removeOverlay();
    FocusScope.of(context).unfocus();

    setState(() {
      _locationController.text = suggestion.description;
      _isSearching = true;
    });

    // Get place details (lat/lng)
    final details = await _placesService.getPlaceDetails(suggestion.placeId);

    if (details != null && mounted) {
      setState(() => _isSearching = false);

      debugPrint('Selected place: ${details.formattedAddress}');
      debugPrint('Coordinates: Lat ${details.latitude}, Lng ${details.longitude}');

      // Update form data
      widget.onDataChanged({
        'location': details.formattedAddress,
        'latitude': details.latitude,
        'longitude': details.longitude,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location captured: ${details.formattedAddress}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location details'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

      // Reverse geocode using Google Places
      final address = await _placesService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (address != null && mounted) {
        setState(() {
          _locationController.text = address;
          _isDetectingLocation = false;
        });

        debugPrint('Reverse geocoded address: $address');

        // Update form data
        widget.onDataChanged({
          'location': address,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location captured: $address'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw 'Failed to get address from coordinates';
      }
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

          // Location with Google Places Autocomplete
          Text(
            'Location *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextField(
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search for a location',
                      prefixIcon: Icon(Icons.location_on, color: Color(0xFF2563EB)),
                      suffixIcon: _isSearching
                          ? Container(
                              width: 48,
                              height: 48,
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2563EB),
                              ),
                            )
                          : _locationController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _locationController.clear();
                                    _removeOverlay();
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
                  ),
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
                            'Powered by Google Places • Accurate location helps buyers find listings near them',
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