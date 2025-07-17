import 'package:flutter/material.dart';

class ListingDetailsFullscreen extends StatelessWidget {
  final Map<String, dynamic> listing;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const ListingDetailsFullscreen({
    Key? key,
    required this.listing,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onCall,
    required this.onWhatsApp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(listing['title'] ?? 'Listing Details')),
      body: Center(child: Text('Listing Details Placeholder')),
    );
  }
}