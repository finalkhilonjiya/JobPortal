import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_api_headers/google_api_headers.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({Key? key}) : super(key: key);

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _mobileController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  List<File> _images = [];
  bool _isLoading = false;
  String? _selectedCategoryId;
  String? _selectedCondition;
  double? _latitude;
  double? _longitude;
  List<Map<String, Object>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final response = await Supabase.instance.client
        .from('categories')
        .select('id, name')
        .eq('is_active', true)
        .order('sort_order');
    setState(() {
      _categories = List<Map<String, Object>>.from(response.map((c) => c.cast<String, Object>()));
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked != null) {
      setState(() {
        _images = [..._images, ...picked.map((x) => File(x.path))];
        if (_images.length > 6) _images = _images.sublist(0, 6);
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    final storage = Supabase.instance.client.storage.from('listing-images');
    List<String> urls = [];
    for (final file in _images) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final res = await storage.upload(fileName, file);
      final url = storage.getPublicUrl(fileName);
      urls.add(url);
    }
    return urls;
  }

  Future<void> _handleLocationAutocomplete() async {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Places API key not set.')));
      return;
    }
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: apiKey,
      mode: Mode.overlay,
      language: 'en',
      components: [Component(Component.country, 'in')],
      hint: 'Search location',
    );
    if (p != null) {
      final places = GoogleMapsPlaces(
        apiKey: apiKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );
      final detail = await places.getDetailsByPlaceId(p.placeId!);
      final loc = detail.result.geometry?.location;
      setState(() {
        _locationController.text = detail.result.formattedAddress ?? p.description ?? '';
        _latitude = loc?.lat;
        _longitude = loc?.lng;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null || _selectedCondition == null || _images.isEmpty || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields and add at least one image.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final imageUrls = await _uploadImages();
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('listings').insert({
        'seller_id': user?.id,
        'category_id': _selectedCategoryId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'condition': _selectedCondition,
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'images': imageUrls,
        'status': 'active',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing created successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Listing')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Images (max 6)', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 1.h),
                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._images.map((img) => Stack(
                                key: Key('image_${img.path}'),
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 90,
                                    height: 90,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(img, fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      key: Key('remove_image_${img.path}'),
                                      onTap: () {
                                        setState(() => _images.remove(img));
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                          if (_images.length < 6)
                            GestureDetector(
                              key: const Key('add_image_btn'),
                              onTap: _pickImages,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      key: const Key('title_field'),
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      key: const Key('mobile_field'),
                      controller: _mobileController,
                      decoration: const InputDecoration(labelText: 'Mobile Number *'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Mobile number is required' : null,
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      key: const Key('desc_field'),
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description *'),
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      key: const Key('category_field'),
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category *'),
                      items: _categories
                          .map((cat) => DropdownMenuItem<String>(
                                value: cat['id'] as String,
                                child: Text(cat['name'] as String),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) => v == null ? 'Category is required' : null,
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      key: const Key('price_field'),
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Price is required' : null,
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      key: const Key('condition_field'),
                      value: _selectedCondition,
                      decoration: const InputDecoration(labelText: 'Condition *'),
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('New')),
                        DropdownMenuItem(value: 'like_new', child: Text('Like New')),
                        DropdownMenuItem(value: 'good', child: Text('Good')),
                        DropdownMenuItem(value: 'fair', child: Text('Fair')),
                        DropdownMenuItem(value: 'poor', child: Text('Poor')),
                      ],
                      onChanged: (v) => setState(() => _selectedCondition = v),
                      validator: (v) => v == null ? 'Condition is required' : null,
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      key: const Key('location_field'),
                      controller: _locationController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Location *'),
                      onTap: _handleLocationAutocomplete,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
                    ),
                    SizedBox(height: 2.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('submit_btn'),
                        onPressed: _isLoading ? null : _submit,
                        child: const Text('Post Listing'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
