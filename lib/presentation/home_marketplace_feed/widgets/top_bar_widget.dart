// File: lib/presentation/home_marketplace_feed/widgets/top_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TopBarWidget extends StatefulWidget {
  final String currentLocation;
  final Function(double latitude, double longitude, String locationName)? onLocationDetected;
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;

  const TopBarWidget({
    Key? key,
    required this.currentLocation,
    required this.onMenuTap,
    required this.onSearchTap,
    this.onLocationDetected,
  }) : super(key: key);

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  String _currentLocation = 'Detecting...';
  bool _isDetecting = false;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    if (_isDetecting) return;

    setState(() => _isDetecting = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location disabled';
          _isDetecting = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _lat = position.latitude;
      _lng = position.longitude;

      final placemarks = await placemarkFromCoordinates(_lat!, _lng!);
      final place = placemarks.first;

      final locationName =
          place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Your location';

      setState(() {
        _currentLocation = locationName;
        _isDetecting = false;
      });

      widget.onLocationDetected?.call(_lat!, _lng!, locationName);
    } catch (_) {
      setState(() {
        _currentLocation = 'Location unavailable';
        _isDetecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(3.w, 1.2.h, 3.w, 1.2.h),
      child: Row(
        children: [
          /// HAMBURGER
          InkWell(
            onTap: widget.onMenuTap,
            child: Icon(Icons.menu, size: 6.w, color: Colors.black87),
          ),

          SizedBox(width: 3.w),

          /// SEARCH BAR
          Expanded(
            child: InkWell(
              onTap: widget.onSearchTap,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 5.w, color: Colors.grey.shade600),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        "Search in '$_currentLocation'",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (_isDetecting)
                      SizedBox(
                        width: 4.w,
                        height: 4.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
