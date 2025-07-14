import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductListWidget extends StatelessWidget {
  const ProductListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual data from provider
    final products = [
      {
        'title': 'KING SIZE MATTRESS',
        'price': 12000,
        'image': 'https://via.placeholder.com/300',
        'location': 'ZOO TINIALI, GUWAHATI',
        'phone': '+911234567890', // Placeholder phone
      },
      {
        'title': 'FLIP 6,256GB IN PRISTINE CONDITION',
        'price': 66000,
        'image': 'https://via.placeholder.com/300',
        'location': 'HATIGAON, GUWAHATI',
        'phone': '+911234567891', // Placeholder phone
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MasonryGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final phone = product['phone'] ?? '+911234567890'; // Placeholder phone
          return Card(
            color: AppTheme.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    product['image'] as String,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${product['price']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryLight,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondaryLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product['location'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryLight,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse('tel:$phone');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              icon: const Icon(Icons.call, color: AppTheme.secondaryLight, size: 18),
                              label: const Text('Call', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.secondaryLight)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.secondaryLight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final whatsappUrl = Uri.parse('https://wa.me/${phone.replaceAll('+', '')}');
                                if (await canLaunchUrl(whatsappUrl)) {
                                  await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.whatsapp, color: Color(0xFF25D366), size: 18),
                              label: const Text('WhatsApp', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF25D366))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF25D366)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}