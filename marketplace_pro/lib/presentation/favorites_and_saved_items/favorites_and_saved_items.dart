import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/collection_folder_widget.dart';
import './widgets/favorite_item_card_widget.dart';
import './widgets/price_alert_dialog_widget.dart';

class FavoritesAndSavedItems extends StatefulWidget {
  const FavoritesAndSavedItems({Key? key}) : super(key: key);

  @override
  State<FavoritesAndSavedItems> createState() => _FavoritesAndSavedItemsState();
}

class _FavoritesAndSavedItemsState extends State<FavoritesAndSavedItems>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isMultiSelectMode = false;
  final Set<int> _selectedItems = {};
  String _sortBy = 'Recently Added';
  String _filterBy = 'All';
  bool _isRefreshing = false;

  // Mock data for favorites
  final List<Map<String, dynamic>> _favoriteItems = [
    {
      "id": 1,
      "title": "iPhone 14 Pro Max",
      "price": "\$899",
      "originalPrice": "\$999",
      "location": "New York, NY",
      "distance": "2.5 km",
      "image":
          "https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400",
      "dateSaved": DateTime.now().subtract(Duration(days: 2)),
      "priceChange": -10.0,
      "isAvailable": true,
      "category": "Electronics",
      "seller": "TechStore NYC",
      "views": 245,
      "isFeatured": true,
    },
    {
      "id": 2,
      "title": "Vintage Leather Sofa",
      "price": "\$450",
      "originalPrice": "\$450",
      "location": "Brooklyn, NY",
      "distance": "5.2 km",
      "image":
          "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400",
      "dateSaved": DateTime.now().subtract(Duration(days: 5)),
      "priceChange": 0.0,
      "isAvailable": true,
      "category": "Furniture",
      "seller": "HomeDecor Plus",
      "views": 89,
      "isFeatured": false,
    },
    {
      "id": 3,
      "title": "Mountain Bike - Trek",
      "price": "\$320",
      "originalPrice": "\$380",
      "location": "Manhattan, NY",
      "distance": "3.8 km",
      "image":
          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400",
      "dateSaved": DateTime.now().subtract(Duration(days: 1)),
      "priceChange": -15.8,
      "isAvailable": false,
      "category": "Sports",
      "seller": "BikeWorld",
      "views": 156,
      "isFeatured": false,
    },
    {
      "id": 4,
      "title": "Designer Handbag",
      "price": "\$180",
      "originalPrice": "\$200",
      "location": "Queens, NY",
      "distance": "7.1 km",
      "image":
          "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400",
      "dateSaved": DateTime.now().subtract(Duration(hours: 12)),
      "priceChange": -10.0,
      "isAvailable": true,
      "category": "Fashion",
      "seller": "LuxuryBags",
      "views": 78,
      "isFeatured": true,
    },
  ];

  // Mock data for collections
  final List<Map<String, dynamic>> _collections = [
    {
      "id": 1,
      "name": "Wishlist",
      "itemCount": 12,
      "icon": "favorite",
      "color": Colors.red,
      "items": [1, 2, 4],
    },
    {
      "id": 2,
      "name": "Electronics",
      "itemCount": 8,
      "icon": "devices",
      "color": Colors.blue,
      "items": [1],
    },
    {
      "id": 3,
      "name": "Home & Garden",
      "itemCount": 5,
      "icon": "home",
      "color": Colors.green,
      "items": [2],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshFavorites() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(int itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _removeSelectedItems() {
    setState(() {
      _favoriteItems.removeWhere((item) => _selectedItems.contains(item["id"]));
      _selectedItems.clear();
      _isMultiSelectMode = false;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 2.h),
            ...[
              'Recently Added',
              'Price: Low to High',
              'Price: High to Low',
              'Distance',
              'Name A-Z'
            ]
                .map((option) => ListTile(
                      title: Text(option),
                      trailing: _sortBy == option
                          ? CustomIconWidget(
                              iconName: 'check',
                              color: AppTheme.lightTheme.primaryColor,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _sortBy = option;
                        });
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 2.h),
            ...[
              'All',
              'Available Only',
              'Price Drops',
              'Electronics',
              'Furniture',
              'Fashion',
              'Sports'
            ]
                .map((option) => ListTile(
                      title: Text(option),
                      trailing: _filterBy == option
                          ? CustomIconWidget(
                              iconName: 'check',
                              color: AppTheme.lightTheme.primaryColor,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _filterBy = option;
                        });
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  void _showPriceAlertDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => PriceAlertDialogWidget(
        item: item,
        onSetAlert: (threshold) {
          // Handle price alert setup
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Price alert set for ${item["title"]}'),
              backgroundColor: AppTheme.getSuccessColor(true),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    List<Map<String, dynamic>> filtered = List.from(_favoriteItems);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              (item["title"] as String)
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              (item["category"] as String)
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    // Apply category filter
    if (_filterBy != 'All') {
      if (_filterBy == 'Available Only') {
        filtered =
            filtered.where((item) => item["isAvailable"] == true).toList();
      } else if (_filterBy == 'Price Drops') {
        filtered = filtered
            .where((item) => (item["priceChange"] as double) < 0)
            .toList();
      } else {
        filtered =
            filtered.where((item) => item["category"] == _filterBy).toList();
      }
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Price: Low to High':
        filtered.sort((a, b) {
          double priceA =
              double.parse((a["price"] as String).replaceAll('\$', ''));
          double priceB =
              double.parse((b["price"] as String).replaceAll('\$', ''));
          return priceA.compareTo(priceB);
        });
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) {
          double priceA =
              double.parse((a["price"] as String).replaceAll('\$', ''));
          double priceB =
              double.parse((b["price"] as String).replaceAll('\$', ''));
          return priceB.compareTo(priceA);
        });
        break;
      case 'Distance':
        filtered.sort((a, b) {
          double distA = double.parse((a["distance"] as String).split(' ')[0]);
          double distB = double.parse((b["distance"] as String).split(' ')[0]);
          return distA.compareTo(distB);
        });
        break;
      case 'Name A-Z':
        filtered.sort(
            (a, b) => (a["title"] as String).compareTo(b["title"] as String));
        break;
      default: // Recently Added
        filtered.sort((a, b) =>
            (b["dateSaved"] as DateTime).compareTo(a["dateSaved"] as DateTime));
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'favorite_border',
              size: 20.w,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 3.h),
            Text(
              'No Favorites Yet',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Start exploring the marketplace and save items you\'re interested in',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home-marketplace-feed');
              },
              child: Text('Explore Marketplace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final filteredItems = _getFilteredItems();

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshFavorites,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return FavoriteItemCardWidget(
            item: item,
            isSelected: _selectedItems.contains(item["id"]),
            isMultiSelectMode: _isMultiSelectMode,
            onTap: () {
              if (_isMultiSelectMode) {
                _toggleItemSelection(item["id"]);
              } else {
                Navigator.pushNamed(context, '/listing-detail');
              }
            },
            onLongPress: () {
              if (!_isMultiSelectMode) {
                _toggleMultiSelect();
                _toggleItemSelection(item["id"]);
              }
            },
            onRemove: () {
              setState(() {
                _favoriteItems.removeWhere((fav) => fav["id"] == item["id"]);
              });
            },
            onShare: () {
              // Handle share
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing ${item["title"]}')),
              );
            },
            onPriceAlert: () {
              _showPriceAlertDialog(item);
            },
            onSimilarItems: () {
              Navigator.pushNamed(context, '/search-and-filters');
            },
          );
        },
      ),
    );
  }

  Widget _buildCollectionsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _collections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: ElevatedButton.icon(
              onPressed: () {
                // Handle create new collection
                _showCreateCollectionDialog();
              },
              icon: CustomIconWidget(
                iconName: 'add',
                color: Colors.white,
                size: 20,
              ),
              label: Text('Create New Collection'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          );
        }

        final collection = _collections[index - 1];
        return CollectionFolderWidget(
          collection: collection,
          onTap: () {
            // Navigate to collection details
            _showCollectionItems(collection);
          },
          onEdit: () {
            // Handle edit collection
          },
          onDelete: () {
            setState(() {
              _collections.removeAt(index - 1);
            });
          },
        );
      },
    );
  }

  void _showCreateCollectionDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Collection'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Collection Name',
            hintText: 'Enter collection name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _collections.add({
                    "id": _collections.length + 1,
                    "name": nameController.text,
                    "itemCount": 0,
                    "icon": "folder",
                    "color": Colors.blue,
                    "items": [],
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCollectionItems(Map<String, dynamic> collection) {
    final collectionItems = _favoriteItems
        .where((item) => (collection["items"] as List).contains(item["id"]))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: 80.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: collection["icon"],
                  color: collection["color"],
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    collection["name"],
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: collectionItems.isEmpty
                  ? Center(
                      child: Text(
                        'No items in this collection',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: collectionItems.length,
                      itemBuilder: (context, index) {
                        return FavoriteItemCardWidget(
                          item: collectionItems[index],
                          isSelected: false,
                          isMultiSelectMode: false,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/listing-detail');
                          },
                          onLongPress: () {},
                          onRemove: () {},
                          onShare: () {},
                          onPriceAlert: () {},
                          onSimilarItems: () {},
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        actions: [
          if (_isMultiSelectMode) ...[
            TextButton(
              onPressed:
                  _selectedItems.isNotEmpty ? _removeSelectedItems : null,
              child: Text('Remove (${_selectedItems.length})'),
            ),
            IconButton(
              onPressed: _toggleMultiSelect,
              icon: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ] else ...[
            IconButton(
              onPressed: _showSortOptions,
              icon: CustomIconWidget(
                iconName: 'sort',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            IconButton(
              onPressed: _showFilterOptions,
              icon: CustomIconWidget(
                iconName: 'filter_list',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search favorites...',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: CustomIconWidget(
                          iconName: 'clear',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'favorite',
                        size: 18,
                        color: _tabController.index == 0
                            ? AppTheme.lightTheme.primaryColor
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 2.w),
                      Text('Items'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'folder',
                        size: 18,
                        color: _tabController.index == 1
                            ? AppTheme.lightTheme.primaryColor
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 2.w),
                      Text('Collections'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFavoritesTab(),
                _buildCollectionsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode && _selectedItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Handle bulk actions
                _showBulkActionsDialog();
              },
              icon: CustomIconWidget(
                iconName: 'more_horiz',
                color: Colors.white,
                size: 20,
              ),
              label: Text('Actions'),
            )
          : null,
    );
  }

  void _showBulkActionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              title: Text('Remove Selected'),
              onTap: () {
                Navigator.pop(context);
                _removeSelectedItems();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'folder_open',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: Text('Add to Collection'),
              onTap: () {
                Navigator.pop(context);
                // Handle add to collection
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: Text('Share Selected'),
              onTap: () {
                Navigator.pop(context);
                // Handle share multiple
              },
            ),
          ],
        ),
      ),
    );
  }
}
