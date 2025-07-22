// File: screens/marketplace/search_page.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import './widgets/square_product_card.dart';
import './widgets/shimmer_widgets.dart';
import '../../services/listing_service.dart';
import '../../services/location_service.dart';
import '../../widgets/location_autocomplete.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _keywordsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ListingService _listingService = ListingService();
  final LocationService _locationService = LocationService();
  
  String _selectedLocation = '';
  double? _selectedLat;
  double? _selectedLng;
  bool _isDetectingLocation = false;
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Set<String> _favoriteIds = {};

  @override
  void dispose() {
    _keywordsController.dispose();
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
      } else {
        // Fallback if no location found in database
        locationText = 'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      }
      
      setState(() {
        _locationController.text = locationText;
        _selectedLocation = locationText;
        _selectedLat = finalLat;
        _selectedLng = finalLng;
        _isDetectingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location: $locationText'),
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

  void _onLocationSelected(LocationResult location) {
    setState(() {
      _selectedLocation = location.displayName;
      _selectedLat = location.latitude;
      _selectedLng = location.longitude;
    });
  }

  void _performSearch() async {
    if (_keywordsController.text.isEmpty && _selectedLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter keywords or select a location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Call your listing service with location data
      final results = await _listingService.searchListings(
        keywords: _keywordsController.text.trim(),
        location: _selectedLocation,
        latitude: _selectedLat,
        longitude: _selectedLng,
        sortBy: 'Newest First',
      );
      
      // Also fetch user favorites if authenticated
      Set<String> favorites = {};
      try {
        favorites = await _listingService.getUserFavorites();
      } catch (e) {
        // Ignore favorites error if user not authenticated
        print('Could not fetch favorites: $e');
      }
      
      setState(() {
        _searchResults = results;
        _favoriteIds = favorites;
        _isSearching = false;
      });

      // Show message if no results found
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No listings found for your search'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearSearch() {
    setState(() {
      _keywordsController.clear();
      _locationController.clear();
      _selectedLocation = '';
      _selectedLat = null;
      _selectedLng = null;
      _searchResults = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
        title: Text(
          'Search Listings',
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasSearched)
            TextButton(
              onPressed: _clearSearch,
              child: Text(
                'Clear',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Form
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Keywords Field
                Text(
                  'Keywords',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _keywordsController,
                  decoration: InputDecoration(
                    hintText: 'What are you looking for?',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF2563EB)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                ),
                SizedBox(height: 2.h),

                // Location Field with Supabase Autocomplete
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
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
                
                // Show location indicator if location is selected
                if (_selectedLat != null && _selectedLng != null)
                  Container(
                    margin: EdgeInsets.only(top: 2.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location selected',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                _selectedLocation,
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
                
                SizedBox(height: 2.h),

                // Search Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2563EB),
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSearching
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: _isSearching
                ? ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: 4,
                    itemBuilder: (_, __) => ShimmerProductCard(),
                  )
                : _hasSearched && _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 20.w,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No results found',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Try different keywords or location',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isNotEmpty
                        ? ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final listing = _searchResults[index];
                              return SquareProductCard(
                                data: listing,
                                isFavorite: _favoriteIds.contains(listing['id']),
                                onFavoriteToggle: () async {
                                  try {
                                    final isFavorited = await _listingService.toggleFavorite(listing['id']);
                                    setState(() {
                                      if (isFavorited) {
                                        _favoriteIds.add(listing['id']);
                                      } else {
                                        _favoriteIds.remove(listing['id']);
                                      }
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Please login to add favorites'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                },
                                onTap: () {
                                  // Navigate to listing details
                                },
                                onCall: () {
                                  // Make phone call
                                },
                                onWhatsApp: () {
                                  // Open WhatsApp
                                },
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 20.w,
                                  color: Colors.grey[400],
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