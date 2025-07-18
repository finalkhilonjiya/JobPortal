import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MyListingsPage extends StatefulWidget {
  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2563EB),
        title: Text('My Listings', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Sold'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListingsList('active'),
          _buildListingsList('sold'),
          _buildListingsList('expired'),
        ],
      ),
    );
  }

  Widget _buildListingsList(String status) {
    // Mock data
    final listings = List.generate(5, (index) => {
      'title': 'Product Title $index',
      'price': (index + 1) * 10000,
      'views': (index + 1) * 100,
      'favorites': (index + 1) * 10,
      'status': status,
      'image': 'https://picsum.photos/200/200?random=$index',
    });

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    listing['image'],
                    width: 20.w,
                    height: 20.w,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '₹${listing['price']}',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Icon(Icons.visibility, size: 4.w, color: Colors.grey),
                          SizedBox(width: 1.w),
                          Text('${listing['views']}', style: TextStyle(fontSize: 10.sp)),
                          SizedBox(width: 4.w),
                          Icon(Icons.favorite, size: 4.w, color: Colors.grey),
                          SizedBox(width: 1.w),
                          Text('${listing['favorites']}', style: TextStyle(fontSize: 10.sp)),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(child: Text('Edit'), value: 'edit'),
                    PopupMenuItem(child: Text('Delete'), value: 'delete'),
                    if (status == 'active')
                      PopupMenuItem(child: Text('Mark as Sold'), value: 'sold'),
                  ],
                  onSelected: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$value action coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}