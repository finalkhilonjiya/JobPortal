import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PriceConditionWidget extends StatefulWidget {
  final String price;
  final bool isNegotiable;
  final String condition;
  final Function(String) onPriceChanged;
  final Function(bool) onNegotiableChanged;
  final Function(String) onConditionChanged;

  const PriceConditionWidget({
    super.key,
    required this.price,
    required this.isNegotiable,
    required this.condition,
    required this.onPriceChanged,
    required this.onNegotiableChanged,
    required this.onConditionChanged,
  });

  @override
  State<PriceConditionWidget> createState() => _PriceConditionWidgetState();
}

class _PriceConditionWidgetState extends State<PriceConditionWidget> {
  late TextEditingController _priceController;
  String _selectedCurrency = '\$';

  final List<String> _currencies = ['\$', '€', '£', '¥', '₹'];

  final List<Map<String, dynamic>> _conditions = [
    {
      'value': 'new',
      'title': 'New',
      'description': 'Brand new, never used',
      'icon': 'new_releases',
    },
    {
      'value': 'like_new',
      'title': 'Like New',
      'description': 'Excellent condition, barely used',
      'icon': 'star',
    },
    {
      'value': 'good',
      'title': 'Good',
      'description': 'Minor signs of wear, fully functional',
      'icon': 'thumb_up',
    },
    {
      'value': 'fair',
      'title': 'Fair',
      'description': 'Noticeable wear, but works well',
      'icon': 'check_circle_outline',
    },
    {
      'value': 'poor',
      'title': 'Poor',
      'description': 'Heavy wear, may need repairs',
      'icon': 'warning',
    },
  ];

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.price);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Select Currency',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            ...(_currencies.map((currency) => ListTile(
                  title: Text(currency),
                  trailing: _selectedCurrency == currency
                      ? CustomIconWidget(
                          iconName: 'check',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCurrency = currency;
                    });
                    Navigator.pop(context);
                  },
                ))),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price & Condition',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            'Set your price and describe the condition of your item',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),

          // Price section
          Text(
            'Price *',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              // Currency selector
              GestureDetector(
                onTap: _showCurrencyPicker,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCurrency,
                        style: AppTheme.lightTheme.textTheme.titleMedium,
                      ),
                      SizedBox(width: 1.w),
                      CustomIconWidget(
                        iconName: 'arrow_drop_down',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              // Price input
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0.00',
                  ),
                  onChanged: widget.onPriceChanged,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Negotiable toggle
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price Negotiable',
                        style: AppTheme.lightTheme.textTheme.titleSmall,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Allow buyers to make offers',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.isNegotiable,
                  onChanged: widget.onNegotiableChanged,
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Condition section
          Text(
            'Condition *',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Text(
            'Select the condition that best describes your item',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),

          // Condition options
          Column(
            children: _conditions.map((condition) {
              final isSelected = widget.condition == condition['value'];
              return Container(
                margin: EdgeInsets.only(bottom: 2.h),
                child: GestureDetector(
                  onTap: () =>
                      widget.onConditionChanged(condition['value'] as String),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primaryContainer
                          : AppTheme.lightTheme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: condition['value'] as String,
                          groupValue: widget.condition,
                          onChanged: (value) {
                            if (value != null) {
                              widget.onConditionChanged(value);
                            }
                          },
                        ),
                        SizedBox(width: 2.w),
                        CustomIconWidget(
                          iconName: condition['icon'] as String,
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                condition['title'] as String,
                                style: AppTheme.lightTheme.textTheme.titleSmall
                                    ?.copyWith(
                                  color: isSelected
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme
                                          .lightTheme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                condition['description'] as String,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 3.h),

          // Pricing tips
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
                      iconName: 'tips_and_updates',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Pricing Tips',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                ...[
                  'Research similar items to set competitive prices',
                  'Consider the item\'s age and condition',
                  'Factor in original purchase price',
                  'Leave room for negotiation if enabled',
                  'Be realistic about depreciation',
                ].map((tip) => Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomIconWidget(
                            iconName: 'monetization_on',
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
