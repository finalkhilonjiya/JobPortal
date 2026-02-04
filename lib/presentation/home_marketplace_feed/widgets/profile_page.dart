import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './packages_page.dart';
import './my_listings_page.dart';

import '../../login_screen/mobile_auth_service.dart';
import '../../../services/listing_service.dart';

import '../../role_selection/role_selection_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final MobileAuthService _authService = MobileAuthService();
  final ListingService _listingService = ListingService();

  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  String _userName = 'User';
  String _userEmail = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      final userId = _authService.userId;

      if (currentUser == null || userId == null) {
        setState(() {
          _userName = 'User';
          _userEmail = '';
          _userPhone = '';
          _isLoading = false;
        });
        return;
      }

      // Fetch profile from DB
      final profile = await _listingService.getUserProfile(userId);

      // Supabase User fields (SAFE)
      final meta = currentUser.userMetadata ?? {};

      setState(() {
        _userProfile = profile;

        _userName =
            profile['full_name']?.toString() ??
            meta['full_name']?.toString() ??
            meta['name']?.toString() ??
            'User';

        _userEmail =
            profile['email']?.toString() ??
            currentUser.email?.toString() ??
            '';

        _userPhone =
            profile['mobile_number']?.toString() ??
            meta['mobile_number']?.toString() ??
            '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

      // If auth issue → force logout + go role selection
      if (e.toString().contains('auth') || e.toString().contains('401')) {
        await _authService.logout();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (_) => false,
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  _userProfile?['avatar_url'] != null
                                      ? NetworkImage(
                                          _userProfile!['avatar_url'],
                                        )
                                      : null,
                              child: _userProfile?['avatar_url'] == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color(0xFF2563EB),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_userEmail.isNotEmpty) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            _userEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                        if (_userPhone.isNotEmpty) ...[
                          SizedBox(height: 0.5.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 4.w,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  _userPhone,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Menu Options
                  _buildMenuItem(
                    context,
                    icon: Icons.list_alt,
                    title: 'My Listings',
                    subtitle: 'Manage your ads',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyListingsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.star,
                    title: 'Packages',
                    subtitle: 'Premium listing plans',
                    isHighlighted: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PackagesPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings coming soon')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.payment,
                    title: 'Payments',
                    subtitle: 'Payment methods & history',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payment gateway integration coming soon',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'FAQs and contact support',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Help & Support coming soon'),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version and info',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Khilonjiya',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2024 Khilonjiya.com',
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out from your account',
                    isDestructive: true,
                    onTap: _showLogoutConfirmation,
                  ),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : isHighlighted
                    ? const Color(0xFF2563EB).withOpacity(0.1)
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive
                ? Colors.red
                : isHighlighted
                    ? const Color(0xFF2563EB)
                    : Colors.grey[700],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
            color: isDestructive ? Colors.red : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 4.w,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}