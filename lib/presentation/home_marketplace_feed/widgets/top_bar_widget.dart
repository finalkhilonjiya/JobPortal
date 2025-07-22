// File: widgets/top_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TopBarWidget extends StatefulWidget {
  final String currentLocation;
  final VoidCallback onLocationTap;

  const TopBarWidget({
    Key? key,
    required this.currentLocation,
    required this.onLocationTap,
  }) : super(key: key);

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  String _currentLocation = 'Detecting...';
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    if (_isDetectingLocation) return;
    
    setState(() {
      _isDetectingLocation = true;
      _currentLocation = 'Detecting...';
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location denied';
            _isDetectingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location disabled';
          _isDetectingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get place name from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocation = '${place.locality ?? place.subAdministrativeArea ?? 'Unknown'}, ${place.administrativeArea ?? ''}';
          _isDetectingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Location unavailable';
        _isDetectingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and Title - Flexible to prevent overflow
          Flexible(
            flex: 1,
            child: Row(
              children: [
                Container(
                  height: 8.w,
                  width: 8.w,
                  decoration: BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Flexible(
                  child: Text(
                    'khilonjiya.com',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Add some spacing
          SizedBox(width: 2.w),
          
          // Location - Flexible to prevent overflow
          Flexible(
            flex: 1,
            child: InkWell(
              onTap: _detectLocation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Color(0xFF2563EB),
                    size: 5.w,
                  ),
                  SizedBox(width: 1.w),
                  Flexible(
                    child: Text(
                      _currentLocation,
                      style: TextStyle(fontSize: 11.sp),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  if (_isDetectingLocation)
                    SizedBox(
                      width: 4.w,
                      height: 4.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2563EB),
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                      size: 5.w,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}