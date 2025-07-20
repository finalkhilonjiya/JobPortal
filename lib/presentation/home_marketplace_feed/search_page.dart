// File: screens/marketplace/search_page.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_maps_webservice_ex/places.dart';
import 'package:geolocator/geolocator.dart';
import './widgets/square_product_card.dart';
import './widgets/shimmer_widgets.dart';
import '../../services/listing_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _keywordsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ListingService _listingService = ListingService();
  
  String _selectedLocation = '';
  double? _selectedLat;
  double? _selectedLng;
  bool _isDetectingLocation = false;
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Set<String> _favoriteIds = {};

  // TODO: Replace with your actual Google API key
  final String _googleApiKey = 'YOUR_GOOGLE_API_KEY_HERE';

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

      String locationText = 'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      
      setState(() {
        _locationController.text = locationText;
        _selectedLocation = locationText;
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
        _isDetectingLocation = false;
      });

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
      // TODO: Implement actual search when ready
      await Future.delayed(Duration(seconds: 2));
      
      setState(() {
        _searchResults = [
          {
            'id': '1',
            'title': 'Search Result 1',
            'price': 15000,
            'image': 'https://via.placeholder.com/300',
            'location': _selectedLocation.isNotEmpty ? _selectedLocation : 'Mumbai',
            'category': 'Electronics',
            'subcategory': 'Mobile Phones',
            'phone': '9876543210',
          },
          {
            'id': '2',
            'title': 'Search Result 2',
            'price': 25000,
            'image': 'https://via.placeholder.com/300',
            'location': _selectedLocation.isNotEmpty ? _selectedLocation : 'Delhi',
            'category': 'Electronics',
            'subcategory': 'Laptops',
            'phone': '9876543211',
          },
        ];
        _isSearching = false;
      });
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

                // Location Field with Autocomplete (no dropdown)
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                GestureDetector(
                  onTap: () async {
                    // Show the PlacesAutocomplete search dialog
                    Prediction? p = await PlacesAutocomplete.show(
                      context: context,
                      apiKey: _googleApiKey,
                      mode: Mode.overlay, // or Mode.fullscreen
                      language: "en",
                      components: [Component(Component.country, "in")],
                    );
                    if (p != null) {
                      setState(() {
                        _selectedLocation = p.description ?? '';
                        _locationController.text = p.description ?? '';
                        // Optionally, get lat/lng using GoogleMapsPlaces
                      });
                      // To get lat/lng, you need to use GoogleMapsPlaces
                      final places = GoogleMapsPlaces(apiKey: _googleApiKey);
                      final detail = await places.getDetailsByPlaceId(p.placeId!);
                      final location = detail.result.geometry?.location;
                      if (location != null) {
                        setState(() {
                          _selectedLat = location.lat;
                          _selectedLng = location.lng;
                        });
                      }
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
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
                      readOnly: true,
                    ),
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
                                onFavoriteToggle: () {
                                  setState(() {
                                    if (_favoriteIds.contains(listing['id'])) {
                                      _favoriteIds.remove(listing['id']);
                                    } else {
                                      _favoriteIds.add(listing['id']);
                                    }
                                  });
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
                                SizedBox(height: 2.h),
                                Text(
                                  'Search for products',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'Enter keywords or select location',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[500],
                                  ),
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