import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './category_data.dart';

class ListingFormTab2 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ListingFormTab2({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ListingFormTab2> createState() => _ListingFormTab2State();
}

class _ListingFormTab2State extends State<ListingFormTab2> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();

  // Multi-select conditions
  Set<String> _selectedConditions = {};

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.formData['price'];
    _descriptionController.text = widget.formData['description'];
    _brandController.text = widget.formData['brand'];
    _modelController.text = widget.formData['model'];
    _yearController.text = widget.formData['yearOfPurchase'];
    _kmController.text = widget.formData['kilometresDriven'];
    _bedroomsController.text = widget.formData['bedrooms'];
    _bathroomsController.text = widget.formData['bathrooms'];

    // Initialize selected conditions from formData
    if (widget.formData['conditions'] != null) {
      if (widget.formData['conditions'] is List) {
        _selectedConditions = Set<String>.from(widget.formData['conditions']);
      } else if (widget.formData['conditions'] is Set) {
        _selectedConditions = widget.formData['conditions'] as Set<String>;
      }
    }
  }

  bool _showFieldForCategory(String field) {
    final category = widget.formData['category'];
    return CategoryData.shouldShowField(category, field);
  }

  // Get condition options based on selected category
  List<String> _getConditionOptionsForCategory() {
    final category = widget.formData['category'];

    switch (category) {
      case 'Room for Rent':
        return [
          'Furnished',
          'Not Furnished',
          'Shared Bathroom',
          'Single Occupancy',
          'Double Occupancy',
        ];
      case 'PG Accommodation':
        return [
          'Furnished',
          'Not Furnished',
          'Shared Bathroom',
          'Single Occupancy',
          'Double Occupancy',
        ];
      case 'Homestays':
        return [
          'Furnished',
          'Not Furnished',
          'Single Occupancy',
          'Double Occupancy',
        ];
      case 'Properties for Sale':
        return [
          'New',
          'Furnished',
          'Not Furnished',
          'Sale Permission Available',
        ];
      default:
        return ['Furnished', 'Not Furnished'];
    }
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
      
      // Update form data with selected conditions
      widget.onDataChanged({
        'conditions': _selectedConditions.toList(),
        'condition': _selectedConditions.isEmpty ? 'good' : _selectedConditions.first.toLowerCase().replaceAll(' ', '_'),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          Text(
            'Price *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter price',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => widget.onDataChanged({'price': value}),
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  value: widget.formData['priceType'],
                  underline: SizedBox(),
                  items: ['Fixed', 'Negotiable'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      widget.onDataChanged({'priceType': value});
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Description
          Text(
            'Description * (Min 10 words)',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe your property in detail...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              widget.onDataChanged({'description': value});
              setState(() {});
            },
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Words: ${_descriptionController.text.split(' ').where((word) => word.isNotEmpty).length}',
            style: TextStyle(
              fontSize: 10.sp,
              color: _descriptionController.text.split(' ').where((word) => word.isNotEmpty).length >= 10
                  ? Colors.green
                  : Colors.red,
            ),
          ),
          SizedBox(height: 2.h),

          // Multi-Select Conditions
          Text(
            'Property Features * (Select all that apply)',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _getConditionOptionsForCategory().map((condition) {
              final isSelected = _selectedConditions.contains(condition);
              return FilterChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (selected) => _toggleCondition(condition),
                selectedColor: Color(0xFF2563EB).withOpacity(0.2),
                checkmarkColor: Color(0xFF2563EB),
                labelStyle: TextStyle(
                  color: isSelected ? Color(0xFF2563EB) : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? Color(0xFF2563EB) : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              );
            }).toList(),
          ),
          if (_selectedConditions.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 0.5.h),
              child: Text(
                'Please select at least one feature',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.red,
                ),
              ),
            ),
          SizedBox(height: 2.h),

          // Category-specific fields
          if (_showFieldForCategory('brand')) ...[
            Text(
              'Brand',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _brandController,
              decoration: InputDecoration(
                hintText: 'Enter brand name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => widget.onDataChanged({'brand': value}),
            ),
            SizedBox(height: 2.h),
          ],

          if (_showFieldForCategory('model')) ...[
            Text(
              'Model',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _modelController,
              decoration: InputDecoration(
                hintText: 'Enter model',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => widget.onDataChanged({'model': value}),
            ),
            SizedBox(height: 2.h),
          ],

          if (_showFieldForCategory('yearOfPurchase')) ...[
            Text(
              'Year of Purchase/Manufacture',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter year',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => widget.onDataChanged({'yearOfPurchase': value}),
            ),
            SizedBox(height: 2.h),
          ],

          // Vehicle-specific fields
          if (_showFieldForCategory('kilometresDriven')) ...[
            Text(
              'Kilometers Driven',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter kilometers',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => widget.onDataChanged({'kilometresDriven': value}),
            ),
            SizedBox(height: 2.h),
          ],

          if (_showFieldForCategory('fuelType')) ...[
            Text(
              'Fuel Type',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            DropdownButtonFormField<String>(
              value: widget.formData['fuelType'].isEmpty ? null : widget.formData['fuelType'],
              decoration: InputDecoration(
                hintText: 'Select fuel type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: ['Petrol', 'Diesel', 'Electric', 'CNG', 'Hybrid'].map((fuel) {
                return DropdownMenuItem(value: fuel, child: Text(fuel));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  widget.onDataChanged({'fuelType': value});
                }
              },
            ),
            SizedBox(height: 2.h),
          ],

          if (_showFieldForCategory('transmissionType')) ...[
            Text(
              'Transmission Type',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Row(
              children: ['Manual', 'Automatic'].map((type) {
                return Expanded(
                  child: RadioListTile<String>(
                    title: Text(type),
                    value: type,
                    groupValue: widget.formData['transmissionType'],
                    onChanged: (value) {
                      if (value != null) {
                        widget.onDataChanged({'transmissionType': value});
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 2.h),
          ],

          // Property-specific fields
          if (_showFieldForCategory('bedrooms')) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bedrooms',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 1.h),
                      TextField(
                        controller: _bedroomsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'No. of bedrooms',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => widget.onDataChanged({'bedrooms': value}),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bathrooms',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 1.h),
                      TextField(
                        controller: _bathroomsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'No. of bathrooms',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => widget.onDataChanged({'bathrooms': value}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],

          // Availability
          SizedBox(height: 2.h),
          Text(
            'Availability',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            children: ['Immediately', 'In few days'].map((availability) {
              return ChoiceChip(
                label: Text(availability),
                selected: widget.formData['availability'] == availability,
                onSelected: (selected) {
                  if (selected) {
                    widget.onDataChanged({'availability': availability});
                  }
                },
                selectedColor: Color(0xFF2563EB).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: widget.formData['availability'] == availability
                      ? Color(0xFF2563EB)
                      : Colors.black,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}