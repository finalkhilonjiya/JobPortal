import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class CompactListingCardWidget extends StatelessWidget {
  final Map<String, dynamic> listing;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavoriteTap;
  final bool showDistance;

  const CompactListingCardWidget({
    Key? key,
    required this.listing,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
    required this.onFavoriteTap,
    this.showDistance = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final distance = listing['distance'] as double?;
    final phoneNumber = listing['seller']?['phone_number'] as String?;
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow.withOpacity(26/255.0),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Sponsored Badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Main Image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: listing['imageUrl'] ?? '',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.lightTheme.colorScheme.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.lightTheme.colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  
                  // Sponsored Badge
                  if (listing['isSponsored'] == true)
                    Positioned(
                      top: 2.w,
                      left: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: AppTheme.getWarningColor(true),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sponsored',
                          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  
                  // Favorite Button
                  Positioned(
                    top: 2.w,
                    right: 2.w,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(230/255.0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite 
                              ? AppTheme.lightTheme.colorScheme.error
                              : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  
                  // Distance Badge
                  if (showDistance && distance != null)
                    Positioned(
                      bottom: 2.w,
                      left: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(153/255.0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 10,
                            ),
                            SizedBox(width: 0.5.w),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      listing['title'] ?? 'No Title',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 1.h),
                    
                    // Price and Category
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing['price'] ?? 'Price not set',
                            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            listing['category'] ?? 'General',
                            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Location and Time
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            listing['location'] ?? 'Unknown',
                            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 0.5.h),
                    
                    // Time Posted
                    Text(
                      listing['timePosted'] ?? 'Recently',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Contact Actions Section
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceVariant.withOpacity(77/255.0),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Call Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleCall(context, phoneNumber),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.5.w),
                        decoration: BoxDecoration(
                          color: AppTheme.getSuccessColor(true),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Call',
                              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 2.w),
                  
                  // WhatsApp Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleWhatsApp(context, phoneNumber),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.5.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366), // WhatsApp green
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'WhatsApp',
                              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
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

  void _handleCall(BuildContext context, String? phoneNumber) async {
    HapticFeedback.lightImpact();
    
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showContactMessage(
        context,
        'Contact number not provided',
        'The seller has not shared their contact number. Please send a message through the app to connect with them.',
        Icons.phone_disabled,
      );
      return;
    }

    try {
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showContactMessage(
          context,
          'Unable to make call',
          'Your device does not support phone calls. Please send a message through the app instead.',
          Icons.phone_disabled,
        );
      }
    } catch (e) {
      _showContactMessage(
        context,
        'Call failed',
        'Unable to initiate the call. Please try again or send a message through the app.',
        Icons.error_outline,
      );
    }
  }

  void _handleWhatsApp(BuildContext context, String? phoneNumber) async {
    HapticFeedback.lightImpact();
    
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showContactMessage(
        context,
        'Contact number not provided',
        'The seller has not shared their contact number. Please send a message through the app to connect with them.',
        Icons.chat_bubble_outline,
      );
      return;
    }

    try {
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      // Remove + if present and add country code if needed
      String formattedNumber = cleanedNumber.startsWith('+') 
          ? cleanedNumber.substring(1)
          : cleanedNumber;
      
      if (formattedNumber.length == 10 && !formattedNumber.startsWith('91')) {
        formattedNumber = '91$formattedNumber';
      }
      
      final message = Uri.encodeComponent(
        'Hi! I\'m interested in your listing "${listing['title']}" on khilonjiya.com. Could you please provide more details?'
      );
      
      final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNumber?text=$message');
      
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        _showContactMessage(
          context,
          'WhatsApp not available',
          'WhatsApp is not installed on your device. Please send a message through the app instead.',
          Icons.chat_bubble_outline,
        );
      }
    } catch (e) {
      _showContactMessage(
        context,
        'WhatsApp failed',
        'Unable to open WhatsApp. Please try again or send a message through the app.',
        Icons.error_outline,
      );
    }
  }

  void _showContactMessage(BuildContext context, String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          icon,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 32,
        ),
        title: Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: AppTheme.lightTheme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to chat/messaging screen
              // Navigator.pushNamed(context, AppRoutes.chatMessaging, arguments: listing);
            },
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }
}
