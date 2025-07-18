// File: widgets/location_autocomplete_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sizer/sizer.dart';

class LocationAutocompleteField extends StatefulWidget {
  final Function(String location, double? lat, double? lng) onLocationSelected;
  final String? initialValue;
  final String googleApiKey;

  const LocationAutocompleteField({
    Key? key,
    required this.onLocationSelected,
    required this.googleApiKey,
    this.initialValue,
  }) : super(key: key);

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
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
        throw 'Location permissions permanently denied';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get place name
      // For now, we'll use a simple approach
      String locationText = 'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      
      setState(() {
        _controller.text = locationText;
        _isDetectingLocation = false;
      });

      widget.onLocationSelected(
        locationText,
        position.latitude,
        position.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location detected successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isDetectingLocation = false);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
        Stack(
          children: [
            GooglePlaceAutoCompleteTextField(
              textEditingController: _controller,
              googleAPIKey: widget.googleApiKey,
              inputDecoration: InputDecoration(
                hintText: 'Enter location',
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF2563EB)),
                suffixIcon: _isDetectingLocation
                    ? Container(
                        width: 48,
                        height: 48,
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2563EB),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.my_location, color: Color(0xFF2563EB)),
                        onPressed: _detectCurrentLocation,
                        tooltip: 'Use current location',
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              debounceTime: 800,
              countries: ["in"], // Restrict to India
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) {
                // Called when user selects a place
                widget.onLocationSelected(
                  prediction.description ?? '',
                  double.tryParse(prediction.lat ?? ''),
                  double.tryParse(prediction.lng ?? ''),
                );
              },
              itemClick: (Prediction prediction) {
                _controller.text = prediction.description ?? '';
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: prediction.description?.length ?? 0),
                );
              },
              itemBuilder: (context, index, Prediction prediction) {
                return Container(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: Colors.grey),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prediction.structuredFormatting?.mainText ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (prediction.structuredFormatting?.secondaryText != null)
                              Text(
                                prediction.structuredFormatting!.secondaryText!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              seperatedBuilder: Divider(height: 1),
              isCrossBtnShown: false,
              containerHorizontalPadding: 0,
            ),
          ],
        ),
      ],
    );
  }
}