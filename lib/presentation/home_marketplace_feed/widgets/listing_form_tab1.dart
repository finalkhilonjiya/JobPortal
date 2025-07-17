// ===== File 1: widgets/listing_form_tab1.dart =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import './category_data.dart';

class ListingFormTab1 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ListingFormTab1({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ListingFormTab1> createState() => _ListingFormTab1State();
}

class _ListingFormTab1State extends State<ListingFormTab1> {
  final ImagePicker _picker = ImagePicker();
  List<String> _subcategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.formData['category'].isNotEmpty) {
      _updateSubcategories(widget.formData['category']);
    }
  }

  void _updateSubcategories(String category) {
    setState(() {
      _subcategories = CategoryData.getSubcategories(category);
      widget.formData['subcategory'] = '';
      widget.onDataChanged({'subcategory': ''});
    });
  }

  Future<void> _pickImage() async {
    if (widget.formData['images'].length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum 6 images allowed')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      List<File> currentImages = List<File>.from(widget.formData['images']);
      currentImages.add(File(image.path));
      widget.onDataChanged({'images': currentImages});
    }
  }

  void _removeImage(int index) {
    List<File> currentImages = List<File>.from(widget.formData['images']);
    currentImages.removeAt(index);
    widget.onDataChanged({'images': currentImages});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Ad Title *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter a descriptive title for your ad',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => widget.onDataChanged({'title': value}),
            controller: TextEditingController(text: widget.formData['title']),
          ),
          SizedBox(height: 2.h),

          // Category
          Text(
            'Category *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            value: widget.formData['category'].isEmpty ? null : widget.formData['category'],
            decoration: InputDecoration(
              hintText: 'Select a category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: CategoryData.mainCategories.map((category) {
              return DropdownMenuItem(
                value: category['name'],
                child: Row(
                  children: [
                    Icon(category['icon'], size: 20, color: Color(0xFF2563EB)),
                    SizedBox(width: 2.w),
                    Text(category['name']),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                widget.onDataChanged({'category': value});
                _updateSubcategories(value);
              }
            },
          ),
          SizedBox(height: 2.h),

          // Subcategory
          if (widget.formData['category'].isNotEmpty) ...[
            Text(
              'Subcategory *',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            DropdownButtonFormField<String>(
              value: widget.formData['subcategory'].isEmpty ? null : widget.formData['subcategory'],
              decoration: InputDecoration(
                hintText: 'Select a subcategory',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _subcategories.map((subcategory) {
                return DropdownMenuItem(
                  value: subcategory,
                  child: Text(subcategory),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  widget.onDataChanged({'subcategory': value});
                }
              },
            ),
            SizedBox(height: 2.h),
          ],

          // Images
          Text(
            'Images * (Min 1, Max 6)',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Container(
            height: 12.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...List.generate(
                  widget.formData['images'].length,
                  (index) => Container(
                    width: 25.w,
                    margin: EdgeInsets.only(right: 2.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            widget.formData['images'][index],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.formData['images'].length < 6)
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: 25.w,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Color(0xFF2563EB), size: 30),
                          SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: TextStyle(fontSize: 10.sp, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'First image will be the cover photo',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}