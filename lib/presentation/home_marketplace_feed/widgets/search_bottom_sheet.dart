import 'package:flutter/material.dart';

class SearchBottomSheet extends StatefulWidget {
  final List<String> trendingSearches;
  final Function(String, String) onSearch;
  const SearchBottomSheet({
    Key? key,
    required this.trendingSearches,
    required this.onSearch,
  }) : super(key: key);
  @override
  _SearchBottomSheetState createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Search', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    labelText: 'What are you looking for?',
                    hintText: 'e.g., iPhone, Car, Apartment',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., Guwahati, Assam',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),
                if (widget.trendingSearches.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.trendingSearches.map((search) => ActionChip(
                        label: Text(search),
                        onPressed: () {
                          _itemController.text = search;
                          widget.onSearch(search, _locationController.text);
                          Navigator.pop(context);
                        },
                      )).toList(),
                    ),
                  ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSearch(_itemController.text, _locationController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Searching for  [1m${_itemController.text} [0m in ${_locationController.text}')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2563EB),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Search', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _itemController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
