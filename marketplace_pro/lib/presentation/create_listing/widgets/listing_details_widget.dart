import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ListingDetailsWidget extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final Function(String) onTitleChanged;
  final Function(String) onDescriptionChanged;

  const ListingDetailsWidget({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
  });

  @override
  State<ListingDetailsWidget> createState() => _ListingDetailsWidgetState();
}

class _ListingDetailsWidgetState extends State<ListingDetailsWidget> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  final int _maxTitleLength = 80;
  final int _maxDescriptionLength = 1000;

  final List<String> _titleSuggestions = [
    'Brand New iPhone 15 Pro Max',
    'Vintage Leather Jacket',
    'Gaming Laptop - High Performance',
    'Antique Wooden Table',
    'Professional Camera Equipment',
    'Designer Handbag - Authentic',
    'Mountain Bike - Excellent Condition',
    'Home Theater System',
  ];

  final List<String> _descriptionTemplates = [
    'This item is in excellent condition and has been well maintained.',
    'Perfect for someone looking for quality at an affordable price.',
    'Rarely used, stored in a smoke-free environment.',
    'All original accessories and documentation included.',
    'Selling due to upgrade/moving/no longer needed.',
    'Great for beginners or professionals alike.',
    'Authentic and genuine product with proof of purchase.',
    'Fast shipping and secure packaging guaranteed.',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _descriptionController = TextEditingController(text: widget.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  List<String> _getCategorySuggestions() {
    final categoryKeywords = {
      'Electronics': ['smartphone', 'laptop', 'tablet', 'headphones', 'camera'],
      'Vehicles': ['car', 'motorcycle', 'bicycle', 'scooter', 'truck'],
      'Fashion': ['dress', 'shirt', 'shoes', 'jacket', 'bag'],
      'Home & Garden': ['sofa', 'table', 'chair', 'lamp', 'plant'],
      'Sports': ['bike', 'equipment', 'gear', 'fitness', 'outdoor'],
      'Books': ['novel', 'textbook', 'guide', 'manual', 'magazine'],
    };

    final keywords = categoryKeywords[widget.category] ?? [];
    return _titleSuggestions
        .where((suggestion) => keywords
            .any((keyword) => suggestion.toLowerCase().contains(keyword)))
        .take(3)
        .toList();
  }

  void _insertTemplate(String template) {
    final currentText = _descriptionController.text;
    final newText =
        currentText.isEmpty ? template : '$currentText\n\n$template';
    _descriptionController.text = newText;
    widget.onDescriptionChanged(newText);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listing Details',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            'Provide clear and detailed information about your item',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),

          // Title field
          Text(
            'Title *',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            maxLength: _maxTitleLength,
            decoration: InputDecoration(
              hintText: 'Enter a descriptive title for your item',
              counterText: '${_titleController.text.length}/$_maxTitleLength',
              suffixIcon: _titleController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _titleController.clear();
                        widget.onTitleChanged('');
                      },
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {});
              widget.onTitleChanged(value);
            },
          ),

          // Title suggestions
          if (widget.category.isNotEmpty && _titleController.text.isEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              'Suggestions for ${widget.category}:',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _getCategorySuggestions()
                  .map((suggestion) => GestureDetector(
                        onTap: () {
                          _titleController.text = suggestion;
                          widget.onTitleChanged(suggestion);
                          setState(() {});
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AppTheme
                                .lightTheme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                          child: Text(
                            suggestion,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],

          SizedBox(height: 3.h),

          // Description field
          Text(
            'Description *',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            maxLines: 8,
            maxLength: _maxDescriptionLength,
            decoration: InputDecoration(
              hintText:
                  'Describe your item in detail. Include condition, features, and any relevant information.',
              counterText:
                  '${_descriptionController.text.length}/$_maxDescriptionLength',
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              setState(() {});
              widget.onDescriptionChanged(value);
            },
          ),

          SizedBox(height: 2.h),

          // Description templates
          Text(
            'Quick Templates:',
            style: AppTheme.lightTheme.textTheme.titleSmall,
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 12.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _descriptionTemplates.length,
              itemBuilder: (context, index) {
                final template = _descriptionTemplates[index];
                return Container(
                  width: 70.w,
                  margin: EdgeInsets.only(right: 3.w),
                  child: GestureDetector(
                    onTap: () => _insertTemplate(template),
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'add',
                                color: AppTheme.lightTheme.colorScheme.primary,
                                size: 16,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Add Template',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Expanded(
                            child: Text(
                              template,
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 3.h),

          // Writing tips
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
                      'Writing Tips',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                ...[
                  'Be honest about the condition',
                  'Include brand, model, and specifications',
                  'Mention any defects or wear',
                  'Add dimensions or size information',
                  'Explain reason for selling',
                ].map((tip) => Padding(
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
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
