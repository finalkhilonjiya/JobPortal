import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PriceAlertDialogWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(double) onSetAlert;

  const PriceAlertDialogWidget({
    Key? key,
    required this.item,
    required this.onSetAlert,
  }) : super(key: key);

  @override
  State<PriceAlertDialogWidget> createState() => _PriceAlertDialogWidgetState();
}

class _PriceAlertDialogWidgetState extends State<PriceAlertDialogWidget> {
  final TextEditingController _thresholdController = TextEditingController();
  String _alertType = 'below';
  bool _isPercentage = false;
  double _currentPrice = 0.0;

  @override
  void initState() {
    super.initState();
    // Parse current price
    final priceString = widget.item["price"] ?? "\$0";
    _currentPrice = double.tryParse(priceString.replaceAll('\$', '')) ?? 0.0;

    // Set default threshold to 10% below current price
    final defaultThreshold = _currentPrice * 0.9;
    _thresholdController.text = defaultThreshold.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  void _setAlert() {
    final thresholdValue = double.tryParse(_thresholdController.text);
    if (thresholdValue != null && thresholdValue > 0) {
      widget.onSetAlert(thresholdValue);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'notifications',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Set Price Alert',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Item Info
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomImageWidget(
                      imageUrl: widget.item["image"] ?? "",
                      width: 15.w,
                      height: 15.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item["title"] ?? "",
                          style: AppTheme.lightTheme.textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Current Price: ${widget.item["price"]}',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Alert Type Selection
            Text(
              'Alert me when price goes:',
              style: AppTheme.lightTheme.textTheme.titleSmall,
            ),
            SizedBox(height: 1.h),

            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: 'below',
                    groupValue: _alertType,
                    onChanged: (value) {
                      setState(() {
                        _alertType = value!;
                      });
                    },
                    title: Text(
                      'Below',
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'above',
                    groupValue: _alertType,
                    onChanged: (value) {
                      setState(() {
                        _alertType = value!;
                      });
                    },
                    title: Text(
                      'Above',
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Threshold Input
            Text(
              'Threshold Amount:',
              style: AppTheme.lightTheme.textTheme.titleSmall,
            ),
            SizedBox(height: 1.h),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _thresholdController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      hintText: 'Enter amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    'USD',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Quick Percentage Options
            Text(
              'Quick Options:',
              style: AppTheme.lightTheme.textTheme.titleSmall,
            ),
            SizedBox(height: 1.h),

            Wrap(
              spacing: 2.w,
              children: [5, 10, 15, 20].map((percentage) {
                final amount = _currentPrice * (1 - percentage / 100);
                return ActionChip(
                  label: Text('$percentage% off'),
                  onPressed: () {
                    setState(() {
                      _thresholdController.text = amount.toStringAsFixed(0);
                    });
                  },
                  backgroundColor:
                      AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                );
              }).toList(),
            ),

            SizedBox(height: 4.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _setAlert,
                    child: Text('Set Alert'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Info Text
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'You\'ll receive a notification when the price ${_alertType == 'below' ? 'drops below' : 'goes above'} your threshold.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color:
                            AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
