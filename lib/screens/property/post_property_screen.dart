import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../widgets/common.dart';

class PostPropertyScreen extends StatefulWidget {
  const PostPropertyScreen({super.key});

  @override
  State<PostPropertyScreen> createState() => _PostPropertyScreenState();
}

class _PostPropertyScreenState extends State<PostPropertyScreen> {
  static const int _maxPhotos = 8;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _locality = TextEditingController();
  final _address = TextEditingController();
  final _beds = TextEditingController();
  final _baths = TextEditingController();
  final _area = TextEditingController();
  final _phone = TextEditingController();

  String _purpose = 'rent';
  String _category = 'flat';
  String? _furnishing;
  final Set<String> _amenities = <String>{};
  final List<XFile> _photos = <XFile>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AuthService.phone().then((p) {
      if (!mounted || p == null) return;
      _phone.text = p.replaceFirst('+91', '');
    });
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _desc,
      _price,
      _city,
      _locality,
      _address,
      _beds,
      _baths,
      _area,
      _phone
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    try {
      final picker = ImagePicker();
      List<XFile> files;
      if (remaining == 1) {
        // pickMultiImage needs limit >= 2, so use a single pick for the last slot.
        final one = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 72,
          maxWidth: 1600,
        );
        files = one == null ? <XFile>[] : <XFile>[one];
      } else {
        files = await picker.pickMultiImage(
          imageQuality: 72,
          maxWidth: 1600,
          limit: remaining,
        );
      }
      if (files.isEmpty) return;
      setState(() => _photos.addAll(files.take(remaining)));
    } catch (_) {
      if (mounted) showSnack(context, 'Could not open gallery', error: true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      showSnack(context, 'Add at least one photo', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final urls = await PropertyService.uploadImages(_photos);
      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'purpose': _purpose,
        'category': _category,
        'price': num.parse(digitsOnly(_price.text)),
        'price_unit': defaultPriceUnit(_purpose, _category),
        'city': _city.text.trim(),
        'locality': _locality.text.trim(),
        'address': _address.text.trim(),
        'bedrooms': int.tryParse(_beds.text.trim()),
        'bathrooms': int.tryParse(_baths.text.trim()),
        'area_sqft': num.tryParse(_area.text.trim()),
        'furnishing': _furnishing,
        'amenities': _amenities.toList(),
        'images': urls,
        'status': 'active',
      };
      await PropertyService.create(data, normalizePhone(_phone.text));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, 'Could not post property. Please try again.',
          error: true);
    }
  }

  String? _required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t, style: AppText.h3),
      );

  @override
  Widget build(BuildContext context) {
    final unit = defaultPriceUnit(_purpose, _category);
    final priceHint = unit == 'month'
        ? 'Monthly rent in ₹'
        : unit == 'night'
            ? 'Price per night in ₹'
            : 'Total price in ₹';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: hAppBar('Post your property'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            _label('I want to'),
            Wrap(
              spacing: 8,
              children: [
                for (final e in kPurposes.entries)
                  FilterPill(
                    label: e.key == 'rent' ? 'Rent out' : 'Sell',
                    selected: _purpose == e.key,
                    onTap: () => setState(() => _purpose = e.key),
                  ),
              ],
            ),
            _label('Property type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in kCategories.entries)
                  FilterPill(
                    label: e.value,
                    icon: kCategoryIcons[e.key],
                    selected: _category == e.key,
                    onTap: () => setState(() => _category = e.key),
                  ),
              ],
            ),
            _label('Photos (${_photos.length}/$_maxPhotos)'),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_photos.length < _maxPhotos)
                    GestureDetector(
                      onTap: _pickPhotos,
                      child: Container(
                        width: 96,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppColors.primary),
                            SizedBox(height: 6),
                            Text('Add',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  for (var i = 0; i < _photos.length; i++)
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          margin: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(File(_photos[i].path),
                                fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AppColors.scrim,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            _label('Basic details'),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco('Title',
                  hint: 'e.g. 2 BHK flat near Main Road'),
              validator: (v) => _required(v, 'Title'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: inputDeco(priceHint, prefixText: '₹ '),
              validator: (v) => _required(v, 'Price'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco('Description',
                  hint: 'Tell seekers what makes this place special'),
            ),
            _label('Location'),
            TextFormField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: inputDeco('City'),
              validator: (v) => _required(v, 'City'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locality,
              textCapitalization: TextCapitalization.words,
              decoration: inputDeco('Locality / area'),
              validator: (v) => _required(v, 'Locality'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco('Full address (optional)'),
            ),
            if (_category != 'plot') ...[
              _label('Property details'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _beds,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: inputDeco('Bedrooms'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _baths,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: inputDeco('Bathrooms'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _area,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: inputDeco('Area (sq.ft)'),
            ),
            if (_category != 'plot') ...[
              _label('Furnishing'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in kFurnishing.entries)
                    FilterPill(
                      label: e.value,
                      selected: _furnishing == e.key,
                      onTap: () => setState(() =>
                          _furnishing = _furnishing == e.key ? null : e.key),
                    ),
                ],
              ),
              _label('Amenities'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in kAmenities)
                    FilterPill(
                      label: a,
                      selected: _amenities.contains(a),
                      onTap: () => setState(() {
                        if (!_amenities.remove(a)) _amenities.add(a);
                      }),
                    ),
                ],
              ),
            ],
            _label('Contact'),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: inputDeco('Phone number seekers can call',
                      prefixText: '+91  ')
                  .copyWith(counterText: ''),
              validator: (v) => digitsOnly(v ?? '').length == 10
                  ? null
                  : 'Enter a valid 10-digit number',
            ),
            const SizedBox(height: 6),
            Text(
              'Your number is shown only to logged-in users who tap "Get owner number".',
              style: AppText.small,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Post property',
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
