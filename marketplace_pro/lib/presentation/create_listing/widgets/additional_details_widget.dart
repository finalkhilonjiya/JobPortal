import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AdditionalDetailsWidget extends StatefulWidget {
  final String category;
  final Map<String, dynamic> details;
  final Function(Map<String, dynamic>) onDetailsChanged;

  const AdditionalDetailsWidget({
    super.key,
    required this.category,
    required this.details,
    required this.onDetailsChanged,
  });

  @override
  State<AdditionalDetailsWidget> createState() =>
      _AdditionalDetailsWidgetState();
}

class _AdditionalDetailsWidgetState extends State<AdditionalDetailsWidget> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    final fields = _getCategoryFields();
    for (final field in fields) {
      final key = field['key'] as String;
      _controllers[key] = TextEditingController(
        text: widget.details[key]?.toString() ?? '',
      );
    }
  }

  List<Map<String, dynamic>> _getCategoryFields() {
    switch (widget.category.toLowerCase()) {
      case 'electronics':
        return [
          {'key': 'brand', 'label': 'Brand', 'type': 'text', 'required': true},
          {'key': 'model', 'label': 'Model', 'type': 'text', 'required': false},
          {
            'key': 'color',
            'label': 'Color',
            'type': 'dropdown',
            'options': [
              'Black',
              'White',
              'Silver',
              'Gold',
              'Blue',
              'Red',
              'Other'
            ]
          },
          {
            'key': 'storage',
            'label': 'Storage/Memory',
            'type': 'dropdown',
            'options': [
              '16GB',
              '32GB',
              '64GB',
              '128GB',
              '256GB',
              '512GB',
              '1TB',
              'Other'
            ]
          },
          {
            'key': 'warranty',
            'label': 'Warranty Status',
            'type': 'dropdown',
            'options': ['Under Warranty', 'Expired', 'No Warranty', 'Unknown']
          },
        ];
      case 'vehicles':
        return [
          {'key': 'make', 'label': 'Make', 'type': 'text', 'required': true},
          {'key': 'model', 'label': 'Model', 'type': 'text', 'required': true},
          {'key': 'year', 'label': 'Year', 'type': 'number', 'required': true},
          {
            'key': 'mileage',
            'label': 'Mileage',
            'type': 'number',
            'required': false
          },
          {
            'key': 'fuel_type',
            'label': 'Fuel Type',
            'type': 'dropdown',
            'options': ['Gasoline', 'Diesel', 'Electric', 'Hybrid', 'Other']
          },
          {
            'key': 'transmission',
            'label': 'Transmission',
            'type': 'dropdown',
            'options': ['Manual', 'Automatic', 'CVT']
          },
        ];
      case 'fashion':
        return [
          {'key': 'brand', 'label': 'Brand', 'type': 'text', 'required': false},
          {
            'key': 'size',
            'label': 'Size',
            'type': 'dropdown',
            'options': ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'Other']
          },
          {'key': 'color', 'label': 'Color', 'type': 'text', 'required': false},
          {
            'key': 'material',
            'label': 'Material',
            'type': 'text',
            'required': false
          },
          {
            'key': 'gender',
            'label': 'Gender',
            'type': 'dropdown',
            'options': ['Men', 'Women', 'Unisex', 'Kids']
          },
        ];
      case 'home & garden':
        return [
          {'key': 'brand', 'label': 'Brand', 'type': 'text', 'required': false},
          {
            'key': 'dimensions',
            'label': 'Dimensions (L x W x H)',
            'type': 'text',
            'required': false
          },
          {
            'key': 'material',
            'label': 'Material',
            'type': 'text',
            'required': false
          },
          {'key': 'color', 'label': 'Color', 'type': 'text', 'required': false},
          {
            'key': 'assembly_required',
            'label': 'Assembly Required',
            'type': 'dropdown',
            'options': ['Yes', 'No', 'Partially Assembled']
          },
        ];
      case 'books':
        return [
          {
            'key': 'author',
            'label': 'Author',
            'type': 'text',
            'required': false
          },
          {'key': 'isbn', 'label': 'ISBN', 'type': 'text', 'required': false},
          {
            'key': 'publisher',
            'label': 'Publisher',
            'type': 'text',
            'required': false
          },
          {
            'key': 'edition',
            'label': 'Edition',
            'type': 'text',
            'required': false
          },
          {
            'key': 'language',
            'label': 'Language',
            'type': 'dropdown',
            'options': ['English', 'Spanish', 'French', 'German', 'Other']
          },
        ];
      default:
        return [
          {'key': 'brand', 'label': 'Brand', 'type': 'text', 'required': false},
          {'key': 'model', 'label': 'Model', 'type': 'text', 'required': false},
          {'key': 'color', 'label': 'Color', 'type': 'text', 'required': false},
          {
            'key': 'dimensions',
            'label': 'Dimensions',
            'type': 'text',
            'required': false
          },
        ];
    }
  }

  void _updateDetail(String key, String value) {
    final updatedDetails = Map<String, dynamic>.from(widget.details);
    updatedDetails[key] = value;
    widget.onDetailsChanged(updatedDetails);
  }

  Widget _buildTextField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    final label = field['label'] as String;
    final isRequired = field['required'] as bool? ?? false;
    final type = field['type'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isRequired ? ' *' : ''}',
          style: AppTheme.lightTheme.textTheme.titleSmall,
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: _controllers[key],
          keyboardType:
              type == 'number' ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: 'Enter $label',
          ),
          onChanged: (value) => _updateDetail(key, value),
        ),
      ],
    );
  }

  Widget _buildDropdownField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    final label = field['label'] as String;
    final isRequired = field['required'] as bool? ?? false;
    final options = field['options'] as List<String>;
    final currentValue = widget.details[key] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isRequired ? ' *' : ''}',
          style: AppTheme.lightTheme.textTheme.titleSmall,
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            hintText: 'Select $label',
          ),
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _updateDetail(key, value);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = _getCategoryFields();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            widget.category.isNotEmpty
                ? 'Provide specific details for ${widget.category} items'
                : 'Add more details about your item',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          if (widget.category.isEmpty) ...[
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 32,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Select a Category First',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Go back to the category selection step to see relevant fields for your item.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Category-specific fields
            ...fields.map((field) {
              final widget = field['type'] == 'dropdown'
                  ? _buildDropdownField(field)
                  : _buildTextField(field);

              return Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: widget,
              );
            }),

            SizedBox(height: 2.h),

            // Additional notes
            Text(
              'Additional Notes',
              style: AppTheme.lightTheme.textTheme.titleSmall,
            ),
            SizedBox(height: 1.h),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Any other details you\'d like to mention...',
              ),
              onChanged: (value) => _updateDetail('notes', value),
            ),

            SizedBox(height: 3.h),

            // Tips for this category
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'lightbulb',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Tips for ${widget.category}',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  ...(_getCategoryTips().map((tip) => Padding(
                        padding: EdgeInsets.only(bottom: 0.5.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomIconWidget(
                              iconName: 'check',
                              color: AppTheme.getSuccessColor(true),
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                tip,
                                style: AppTheme.lightTheme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getCategoryTips() {
    switch (widget.category.toLowerCase()) {
      case 'electronics':
        return [
          'Include original box and accessories if available',
          'Mention any scratches or functional issues',
          'Provide serial numbers for authenticity',
          'Include screenshots of device settings',
        ];
      case 'vehicles':
        return [
          'Include maintenance records if available',
          'Mention any accidents or repairs',
          'Provide VIN for verification',
          'Include recent inspection results',
        ];
      case 'fashion':
        return [
          'Provide accurate measurements',
          'Mention any stains or wear',
          'Include care instructions',
          'Show fit on model if possible',
        ];
      default:
        return [
          'Be specific about dimensions and weight',
          'Mention any defects or wear',
          'Include all accessories',
          'Provide proof of authenticity if applicable',
        ];
    }
  }
}
