// ===== File 1: widgets/listing_form_tab3.dart =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ListingFormTab3 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ListingFormTab3({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ListingFormTab3> createState() => _ListingFormTab3State();
}

class _ListingFormTab3State extends State<ListingFormTab3> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.formData['sellerName'];
    _phoneController.text = widget.formData['sellerPhone'];
    _locationController.text = widget.formData['location'];
  }

  void _detectLocation() {
    // Mock location detection
    setState(() {
      _locationController.text = 'Guwahati, Assam';
      widget.onDataChanged({'location': 'Guwahati, Assam'});
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location detected successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller Name
          Text(
            'Seller Name *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person, color: Color(0xFF2563EB)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => widget.onDataChanged({'sellerName': value}),
          ),
          SizedBox(height: 2.h),

          // Phone Number
          Text(
            'Phone Number *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone, color: Color(0xFF2563EB)),
              prefixText: '+91 ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => widget.onDataChanged({'sellerPhone': value}),
          ),
          SizedBox(height: 2.h),

          // Location
          Text(
            'Location *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Enter your location',
              prefixIcon: Icon(Icons.location_on, color: Color(0xFF2563EB)),
              suffixIcon: IconButton(
                icon: Icon(Icons.my_location, color: Color(0xFF2563EB)),
                onPressed: _detectLocation,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => widget.onDataChanged({'location': value}),
          ),
          SizedBox(height: 2.h),

          // User Type
          Text(
            'User Type',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('Individual'),
                  subtitle: Text('I am selling personal items'),
                  value: 'Individual',
                  groupValue: widget.formData['userType'],
                  onChanged: (value) {
                    if (value != null) {
                      widget.onDataChanged({'userType': value});
                    }
                  },
                ),
                Divider(height: 1),
                RadioListTile<String>(
                  title: Text('Business/Dealer'),
                  subtitle: Text('I am a professional seller'),
                  value: 'Business/Dealer',
                  groupValue: widget.formData['userType'],
                  onChanged: (value) {
                    if (value != null) {
                      widget.onDataChanged({'userType': value});
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Terms & Conditions
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 1.h),
                Text(
                  '• Your ad will be live for 30 days\n'
                  '• We reserve the right to remove inappropriate content\n'
                  '• Provide accurate information about your product\n'
                  '• You are responsible for the transaction',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Checkbox(
                      value: widget.formData['termsAccepted'],
                      onChanged: (value) {
                        if (value != null) {
                          widget.onDataChanged({'termsAccepted': value});
                        }
                      },
                      activeColor: Color(0xFF2563EB),
                    ),
                    Expanded(
                      child: Text(
                        'I agree to the Terms & Conditions *',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Info Section
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Your contact details will be shared with interested buyers',
                    style: TextStyle(fontSize: 10.sp, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}