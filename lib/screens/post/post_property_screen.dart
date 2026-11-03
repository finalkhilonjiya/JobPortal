import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/anim.dart';
import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/location.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';

class _Pic {
  final String? url;
  final Uint8List? bytes;
  _Pic.url(this.url) : bytes = null;
  _Pic.bytes(this.bytes) : url = null;
}

/// 6-step wizard used for both posting and editing.
class PostPropertyScreen extends StatefulWidget {
  final Property? existing;
  const PostPropertyScreen({super.key, this.existing});

  @override
  State<PostPropertyScreen> createState() => _PostPropertyScreenState();
}

class _PostPropertyScreenState extends State<PostPropertyScreen> {
  static const _titles = ['Basics', 'Location', 'Details', 'Features', 'Photos', 'Review'];
  final _picker = ImagePicker();
  int _step = 0;
  bool _busy = false;
  String _progress = '';
  bool _locating = false;

  // step 1
  String purpose = 'rent';
  String category = 'flat';
  String listedBy = 'owner';
  final title = TextEditingController();
  // step 2
  final city = TextEditingController();
  final locality = TextEditingController();
  final address = TextEditingController();
  final pincode = TextEditingController();
  final landmark = TextEditingController();
  final nearby = TextEditingController();
  double? lat;
  double? lng;
  // step 3
  final price = TextEditingController();
  String priceUnit = 'month';
  final deposit = TextEditingController();
  final maintenance = TextEditingController();
  int bedrooms = 2;
  int bathrooms = 1;
  int balconies = 0;
  final area = TextEditingController();
  final carpet = TextEditingController();
  final floorNo = TextEditingController();
  final totalFloors = TextEditingController();
  final age = TextEditingController();
  String furnishing = '';
  String facing = '';
  String parking = '';
  bool hasLift = false;
  String construction = 'ready';
  DateTime? possession;
  String ownership = '';
  final rera = TextEditingController();
  final projectName = TextEditingController();
  final builderName = TextEditingController();
  bool noBrokerage = false;
  String pgGender = '';
  String food = '';
  String sharing = '';
  // step 4
  final Set<String> amenities = {};
  final description = TextEditingController();
  // step 5
  final List<_Pic> pics = [];
  final List<_Pic> plans = [];
  Uint8List? videoBytes;
  String videoName = '';
  String existingVideo = '';
  final tour = TextEditingController();
  // step 6
  final phone = TextEditingController();

  bool get _edit => widget.existing != null;
  bool get _land => kLandCats.contains(category);
  bool get _noBeds => kNoBedroomCats.contains(category);
  bool get _stay => kStayCats.contains(category);

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    final prof = Api.profile.value;
    if (prof != null) {
      phone.text = digitsOnly(prof.phone).length >= 10 ? digitsOnly(prof.phone).substring(digitsOnly(prof.phone).length - 10) : '';
      if (prof.role == 'agent' || prof.role == 'broker') listedBy = 'broker';
      if (prof.role == 'builder') listedBy = 'builder';
    }
    if (p != null) _fill(p);
  }

  void _fill(Property p) {
    purpose = p.purpose;
    category = p.category;
    listedBy = p.listedBy;
    title.text = p.title;
    city.text = p.city;
    locality.text = p.locality;
    address.text = p.address;
    pincode.text = p.pincode;
    landmark.text = p.landmark;
    nearby.text = p.nearby.join(', ');
    lat = p.latitude;
    lng = p.longitude;
    price.text = p.price.round().toString();
    priceUnit = p.priceUnit;
    deposit.text = p.securityDeposit?.round().toString() ?? '';
    maintenance.text = p.maintenance?.round().toString() ?? '';
    bedrooms = p.bedrooms ?? 0;
    bathrooms = p.bathrooms ?? 0;
    balconies = p.balconies ?? 0;
    area.text = p.areaSqft?.round().toString() ?? '';
    carpet.text = p.carpetArea?.round().toString() ?? '';
    floorNo.text = p.floorNo?.toString() ?? '';
    totalFloors.text = p.totalFloors?.toString() ?? '';
    age.text = p.ageYears?.toString() ?? '';
    furnishing = p.furnishing;
    facing = p.facing;
    parking = p.parking;
    hasLift = p.hasLift;
    construction = p.constructionStatus.isEmpty ? 'ready' : p.constructionStatus;
    possession = DateTime.tryParse(p.possessionDate);
    ownership = p.ownership;
    rera.text = p.reraNumber;
    projectName.text = p.projectName;
    builderName.text = p.builderName;
    noBrokerage = p.noBrokerage;
    pgGender = p.pgGender;
    food = p.food;
    sharing = p.sharing;
    amenities.addAll(p.amenities);
    description.text = p.description;
    pics.addAll(p.images.map((e) => _Pic.url(e)));
    plans.addAll(p.floorPlans.map((e) => _Pic.url(e)));
    existingVideo = p.videoUrl;
    tour.text = p.tourUrl;
    Api.contactPhone(p.id).then((v) {
      if (v != null && mounted) {
        final d = digitsOnly(v);
        setState(() => phone.text = d.length >= 10 ? d.substring(d.length - 10) : d);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [title, city, locality, address, pincode, landmark, nearby, price, deposit, maintenance, area, carpet, floorNo, totalFloors, age, rera, projectName, builderName, description, tour, phone]) {
      c.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------ helpers
  num? _n(TextEditingController c) => num.tryParse(c.text.replaceAll(',', '').trim());
  int? _i(TextEditingController c) => int.tryParse(c.text.trim());
  String? _s(String v) => v.trim().isEmpty ? null : v.trim();

  void _setCategory(String k) {
    setState(() {
      category = k;
      if (k == 'homestay') {
        priceUnit = 'night';
      } else if (purpose == 'sale') {
        priceUnit = 'total';
      } else {
        priceUnit = 'month';
      }
      if (kNoBedroomCats.contains(k)) {
        bedrooms = 0;
        bathrooms = 0;
      } else if (bedrooms == 0) {
        bedrooms = 1;
        bathrooms = 1;
      }
      if (k == 'project') {
        purpose = 'sale';
        priceUnit = 'total';
        listedBy = 'builder';
      }
    });
  }

  void _setPurpose(String v) {
    setState(() {
      purpose = v;
      priceUnit = category == 'homestay' ? 'night' : (v == 'sale' ? 'total' : 'month');
    });
  }

  Future<void> _useLocation() async {
    setState(() => _locating = true);
    final r = await LocationService.current();
    if (!mounted) return;
    setState(() => _locating = false);
    if (r.spot == null) {
      toast(context, r.error ?? 'Could not get location.');
      return;
    }
    setState(() {
      lat = r.spot!.lat;
      lng = r.spot!.lng;
      if (city.text.isEmpty) city.text = r.spot!.city;
      if (locality.text.isEmpty) locality.text = r.spot!.area;
    });
    toast(context, 'Location captured. Please check the city and area.');
  }

  Future<void> _addPhotos({bool plan = false}) async {
    final list = plan ? plans : pics;
    final max = plan ? 3 : 12;
    final left = max - list.length;
    if (left <= 0) {
      toast(context, 'You can add up to $max images here.');
      return;
    }
    try {
      List<XFile> files;
      if (left == 1) {
        final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1800);
        files = x == null ? [] : [x];
      } else {
        files = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1800, limit: left);
      }
      for (final f in files.take(left)) {
        final b = await f.readAsBytes();
        list.add(_Pic.bytes(b));
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) toast(context, 'Could not pick photos: ${errText(e)}');
    }
  }

  Future<void> _takePhoto() async {
    if (pics.length >= 12) return;
    try {
      final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1800);
      if (x == null) return;
      pics.add(_Pic.bytes(await x.readAsBytes()));
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) toast(context, 'Could not open the camera.');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final x = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
      if (x == null) return;
      final b = await x.readAsBytes();
      if (b.length > 45 * 1024 * 1024) {
        if (mounted) toast(context, 'Video is too large. Please pick one under 45 MB.');
        return;
      }
      setState(() {
        videoBytes = b;
        videoName = x.name;
      });
    } catch (e) {
      if (mounted) toast(context, 'Could not pick the video.');
    }
  }

  // ------------------------------------------------------------ validation
  String? _validate(int step) {
    switch (step) {
      case 0:
        if (title.text.trim().length < 5) return 'Add a title (at least 5 characters).';
        return null;
      case 1:
        if (city.text.trim().isEmpty) return 'Enter the city.';
        if (locality.text.trim().isEmpty) return 'Enter the locality or area.';
        if (pincode.text.trim().isNotEmpty && pincode.text.trim().length != 6) return 'Pincode should be 6 digits.';
        return null;
      case 2:
        final pr = _n(price);
        if (pr == null || pr <= 0) return 'Enter a valid price.';
        if (!_noBeds && !_stay && bedrooms == 0 && category != 'room') return 'Select the number of bedrooms.';
        return null;
      case 3:
        if (description.text.trim().length < 20) return 'Write a short description (at least 20 characters).';
        return null;
      case 4:
        if (pics.isEmpty) return 'Add at least one photo.';
        return null;
      case 5:
        if (digitsOnly(phone.text).length != 10) return 'Enter a valid 10-digit contact number.';
        return null;
    }
    return null;
  }

  void _next() {
    final err = _validate(_step);
    if (err != null) {
      toast(context, err);
      return;
    }
    FocusScope.of(context).unfocus();
    if (_step < _titles.length - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
    }
  }

  // ------------------------------------------------------------ submit
  Future<List<String>> _upload(List<_Pic> list, String label) async {
    final out = <String>[];
    for (int i = 0; i < list.length; i++) {
      final p = list[i];
      if (p.url != null) {
        out.add(p.url!);
      } else {
        if (mounted) setState(() => _progress = 'Uploading $label ${i + 1} of ${list.length}...');
        out.add(await Api.uploadBytes(p.bytes!, 'jpg'));
      }
    }
    return out;
  }

  Future<void> _submit() async {
    for (int i = 0; i < 6; i++) {
      final e = _validate(i);
      if (e != null) {
        setState(() => _step = i);
        toast(context, e);
        return;
      }
    }
    setState(() {
      _busy = true;
      _progress = 'Preparing...';
    });
    try {
      final images = await _upload(pics, 'photo');
      final planUrls = await _upload(plans, 'floor plan');
      String video = existingVideo;
      if (videoBytes != null) {
        setState(() => _progress = 'Uploading video...');
        video = await Api.uploadBytes(videoBytes!, 'mp4', contentType: 'video/mp4');
      }
      setState(() => _progress = 'Saving listing...');

      final data = <String, dynamic>{
        'title': title.text.trim(),
        'description': description.text.trim(),
        'purpose': purpose,
        'category': category,
        'price': _n(price),
        'price_unit': priceUnit,
        'security_deposit': purpose == 'sale' ? null : _n(deposit),
        'maintenance': _n(maintenance),
        'city': city.text.trim(),
        'locality': locality.text.trim(),
        'address': address.text.trim(),
        'pincode': _s(pincode.text),
        'landmark': _s(landmark.text),
        'latitude': lat,
        'longitude': lng,
        'bedrooms': _noBeds ? null : bedrooms,
        'bathrooms': _noBeds ? null : bathrooms,
        'balconies': _noBeds ? null : balconies,
        'area_sqft': _n(area),
        'carpet_area': _n(carpet),
        'floor_no': _i(floorNo),
        'total_floors': _i(totalFloors),
        'age_years': _i(age),
        'construction_status': purpose == 'sale' ? construction : null,
        'possession_date': possession == null ? null : possession!.toIso8601String().substring(0, 10),
        'facing': _s(facing),
        'parking': _s(parking),
        'has_lift': hasLift,
        'ownership': _s(ownership),
        'rera_number': _s(rera.text),
        'listed_by': listedBy,
        'no_brokerage': noBrokerage,
        'project_name': _s(projectName.text),
        'builder_name': _s(builderName.text),
        'furnishing': _s(furnishing),
        'amenities': amenities.toList(),
        'nearby': nearby.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'images': images,
        'floor_plans': planUrls,
        'video_url': _s(video),
        'tour_url': _s(tour.text),
        'pg_gender': _stay ? _s(pgGender) : null,
        'food': _stay ? _s(food) : null,
        'sharing': _stay ? _s(sharing) : null,
      };

      String status;
      String id;
      if (_edit) {
        await Api.updateProperty(widget.existing!.id, data);
        id = widget.existing!.id;
        status = widget.existing!.status;
      } else {
        final created = await Api.createProperty(data);
        id = created.id;
        status = created.status;
      }
      await Api.setContactPhone(id, normalizePhone(phone.text));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 44, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            Text(_edit ? 'Listing updated' : (status == 'active' ? 'Your listing is live!' : 'Submitted for review'), style: AppText.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              status == 'pending'
                  ? 'Our team will review it shortly. You will get a notification once it is approved.'
                  : 'People can now find it and contact you. You can manage it from your dashboard.',
              style: AppText.bodyM,
              textAlign: TextAlign.center,
            ),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, errText(e));
    }
  }

  // ------------------------------------------------------------ UI
  @override
  Widget build(BuildContext context) {
    final last = _step == _titles.length - 1;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: _busy ? null : _back),
          title: Text(_edit ? 'Edit property' : 'Post property'),
        ),
        body: Column(
          children: [
            _stepper(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(a), child: c)),
                child: SingleChildScrollView(
                  key: ValueKey<int>(_step),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                  child: _stepBody(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
              child: SafeArea(
                top: false,
                child: _busy
                    ? Row(children: [
                        const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
                        const SizedBox(width: 14),
                        Expanded(child: Text(_progress, style: AppText.bodyM)),
                      ])
                    : FilledButton(onPressed: _next, child: Text(last ? (_edit ? 'Save changes' : 'Publish listing') : 'Continue')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(children: [
        Row(
          children: List.generate(_titles.length, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: i <= _step ? AppColors.primary : AppColors.line, borderRadius: BorderRadius.circular(5)),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text('Step ${_step + 1} of ${_titles.length}', style: AppText.bodyS),
          const Spacer(),
          Text(_titles[_step], style: AppText.label.copyWith(color: AppColors.primary)),
        ]),
      ]),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _basics();
      case 1:
        return _location();
      case 2:
        return _details();
      case 3:
        return _features();
      case 4:
        return _photos();
      default:
        return _review();
    }
  }

  Widget _field(String label, TextEditingController c, {String hint = '', TextInputType? type, int lines = 1, int? max, IconData? icon, String? prefix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FormLabel(label),
        TextField(
          controller: c,
          keyboardType: type,
          maxLines: lines,
          maxLength: max,
          textCapitalization: type == null ? TextCapitalization.sentences : TextCapitalization.none,
          decoration: inputDeco(hint, icon: icon, prefixText: prefix).copyWith(counterText: ''),
        ),
      ]),
    );
  }

  Widget _chooser(String label, List<String> values, String current, ValueChanged<String> onPick, {Map<String, String>? labels, bool allowNone = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FormLabel(label),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in values)
            PillChip(
              label: labels?[v] ?? cap(v),
              selected: current == v,
              onTap: () => setState(() => onPick(allowNone && current == v ? '' : v)),
            ),
        ]),
      ]),
    );
  }

  Widget _counter(String label, int value, ValueChanged<int> on, {int min = 0, int max = 10}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(children: [
          Text(label, style: AppText.bodyS),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _roundBtn(Icons.remove_rounded, value > min ? () => setState(() => on(value - 1)) : null),
            Text('$value', style: AppText.h3),
            _roundBtn(Icons.add_rounded, value < max ? () => setState(() => on(value + 1)) : null),
          ]),
        ]),
      ),
    );
  }

  Widget _roundBtn(IconData i, VoidCallback? f) => GestureDetector(
        onTap: f,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: f == null ? AppColors.line : AppColors.soft, shape: BoxShape.circle),
          child: Icon(i, size: 18, color: f == null ? AppColors.text3 : AppColors.primary),
        ),
      );

  // step 1
  Widget _basics() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('What are you listing?', style: AppText.h2),
      const SizedBox(height: 16),
      _chooser('I want to', ['rent', 'sale', 'lease'], purpose, _setPurpose, labels: {'rent': 'Rent out', 'sale': 'Sell', 'lease': 'Lease'}, allowNone: false),
      const FormLabel('Property type'),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
        children: [
          for (final c in kCategories)
            GestureDetector(
              onTap: () => _setCategory(c.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: category == c.key ? AppColors.soft : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: category == c.key ? AppColors.primary : AppColors.line, width: category == c.key ? 1.6 : 1),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(c.icon, color: category == c.key ? AppColors.primary : AppColors.text2, size: 26),
                  const SizedBox(height: 5),
                  Text(c.label, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: category == c.key ? AppColors.primaryDark : AppColors.text2)),
                ]),
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      _chooser('I am the', ['owner', 'broker', 'builder'], listedBy, (v) => listedBy = v.isEmpty ? listedBy : v, labels: {'owner': 'Owner', 'broker': 'Agent / broker', 'builder': 'Builder'}, allowNone: false),
      _field('Listing title', title, hint: 'e.g. Spacious 2 BHK near GS Road', max: 90, icon: Icons.title_rounded),
    ]);
  }

  // step 2
  Widget _location() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Where is it?', style: AppText.h2),
      const SizedBox(height: 14),
      Pressable(
        onTap: _locating ? null : _useLocation,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            _locating
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                : const Icon(Icons.my_location_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(lat == null ? 'Use my current location (recommended)' : 'Location captured ✓', style: AppText.title.copyWith(color: AppColors.primaryDark)),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 6),
      const Padding(
        padding: EdgeInsets.only(top: 4, bottom: 14),
        child: Text('Stand at the property and tap above. This lets buyers open the exact spot in Google Maps and find it with "Near me".', style: AppText.bodyS),
      ),
      _field('City', city, hint: 'e.g. Guwahati', icon: Icons.location_city_rounded),
      _field('Locality / area', locality, hint: 'e.g. Beltola', icon: Icons.place_outlined),
      _field('Address (optional)', address, hint: 'House no., street', lines: 2),
      Row(children: [
        Expanded(child: _field('Pincode', pincode, hint: '781028', type: TextInputType.number, max: 6)),
        const SizedBox(width: 12),
        Expanded(child: _field('Landmark', landmark, hint: 'Near...')),
      ]),
      _field('Nearby places (comma separated)', nearby, hint: 'School 400 m, Hospital 1 km, Bus stop 200 m', lines: 2),
    ]);
  }

  // step 3
  Widget _details() {
    final rentLike = purpose != 'sale';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Property details', style: AppText.h2),
      const SizedBox(height: 14),
      _field(purpose == 'sale' ? 'Expected price (₹)' : (priceUnit == 'night' ? 'Price per night (₹)' : 'Monthly rent (₹)'), price, type: TextInputType.number, hint: 'e.g. 15000', prefix: '₹ '),
      if (category == 'homestay')
        _chooser('Price is', ['night', 'month'], priceUnit, (v) => priceUnit = v.isEmpty ? priceUnit : v, labels: {'night': 'Per night', 'month': 'Per month'}, allowNone: false),
      if (rentLike) Row(children: [
        Expanded(child: _field('Security deposit (₹)', deposit, type: TextInputType.number, hint: 'Optional')),
        const SizedBox(width: 12),
        Expanded(child: _field('Maintenance (₹/mo)', maintenance, type: TextInputType.number, hint: 'Optional')),
      ]),
      if (!rentLike) _field('Maintenance (₹/mo)', maintenance, type: TextInputType.number, hint: 'Optional'),
      if (!_noBeds) ...[
        Row(children: [
          _counter('Bedrooms', bedrooms, (v) => bedrooms = v, max: 10),
          const SizedBox(width: 10),
          _counter('Bathrooms', bathrooms, (v) => bathrooms = v, max: 10),
          const SizedBox(width: 10),
          _counter('Balconies', balconies, (v) => balconies = v, max: 6),
        ]),
        const SizedBox(height: 16),
      ],
      Row(children: [
        Expanded(child: _field(_land ? 'Plot area (sq ft)' : 'Area (sq ft)', area, type: TextInputType.number, hint: 'e.g. 1200')),
        const SizedBox(width: 12),
        if (!_land) Expanded(child: _field('Carpet area', carpet, type: TextInputType.number, hint: 'Optional')),
      ]),
      if (_land)
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text('Tip: use the Land converter in Tools to convert bigha / katha / lecha into sq ft.', style: AppText.bodyS),
        ),
      if (!_land && !_noBeds) ...[
        Row(children: [
          Expanded(child: _field('Floor no.', floorNo, type: TextInputType.number, hint: '0 = ground')),
          const SizedBox(width: 12),
          Expanded(child: _field('Total floors', totalFloors, type: TextInputType.number, hint: 'e.g. 5')),
          const SizedBox(width: 12),
          Expanded(child: _field('Age (years)', age, type: TextInputType.number, hint: '0 = new')),
        ]),
        _chooser('Furnishing', kFurnishing, furnishing, (v) => furnishing = v, labels: kFurnishingLabel),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          title: const Text('Lift available', style: AppText.title),
          value: hasLift,
          onChanged: (v) => setState(() => hasLift = v),
        ),
      ],
      _chooser('Facing', kFacing, facing, (v) => facing = v),
      _chooser('Parking', ['car', 'bike', 'both', 'none'], parking, (v) => parking = v, labels: {'car': 'Car', 'bike': 'Bike', 'both': 'Car + bike', 'none': 'None'}),
      if (purpose == 'sale') ...[
        _chooser('Construction status', ['ready', 'under_construction'], construction, (v) => construction = v.isEmpty ? construction : v,
            labels: {'ready': 'Ready to move', 'under_construction': 'Under construction'}, allowNone: false),
        if (construction == 'under_construction')
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(context: context, initialDate: possession ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 8)));
                if (d != null) setState(() => possession = d);
              },
              icon: const Icon(Icons.event_rounded),
              label: Text(possession == null ? 'Possession date' : 'Possession: ${dateLabel(possession!)}'),
            ),
          ),
        _chooser('Ownership', ['freehold', 'leasehold', 'poa', 'cooperative'], ownership, (v) => ownership = v,
            labels: {'freehold': 'Freehold', 'leasehold': 'Leasehold', 'poa': 'Power of attorney', 'cooperative': 'Co-operative society'}),
        _field('RERA number (optional)', rera, hint: 'e.g. ASRERA/2025/0412'),
      ],
      if (category == 'project' || listedBy == 'builder') ...[
        _field('Project name', projectName, hint: 'e.g. Orange Heights'),
        _field('Builder / developer', builderName, hint: 'Company name'),
      ],
      if (_stay) ...[
        _chooser('Suitable for', ['male', 'female', 'any'], pgGender, (v) => pgGender = v, labels: {'male': 'Boys / men', 'female': 'Girls / women', 'any': 'Anyone'}),
        _chooser('Food', ['veg', 'nonveg', 'both', 'none'], food, (v) => food = v, labels: {'veg': 'Veg', 'nonveg': 'Non-veg', 'both': 'Veg + non-veg', 'none': 'No food'}),
        _chooser('Sharing', ['single', 'double', 'triple', 'dorm'], sharing, (v) => sharing = v, labels: {'single': 'Single', 'double': 'Double', 'triple': 'Triple', 'dorm': 'Dorm'}),
      ],
      if (rentLike && listedBy != 'owner')
        const SizedBox.shrink()
      else if (rentLike)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          title: const Text('Zero brokerage', style: AppText.title),
          subtitle: const Text('I am the owner and will not charge any brokerage', style: AppText.bodyS),
          value: noBrokerage,
          onChanged: (v) => setState(() => noBrokerage = v),
        ),
    ]);
  }

  // step 4
  Widget _features() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Amenities and description', style: AppText.h2),
      const SizedBox(height: 14),
      const FormLabel('Amenities'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final a in kAmenities)
          PillChip(label: a, selected: amenities.contains(a), onTap: () => setState(() {
                if (!amenities.add(a)) amenities.remove(a);
              })),
      ]),
      const SizedBox(height: 20),
      _field('Describe your property', description, lines: 7, max: 1500, hint: 'Mention the surroundings, condition, nearby facilities, rules for tenants, etc.'),
    ]);
  }

  // step 5
  Widget _photos() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Photos and media', style: AppText.h2),
      const SizedBox(height: 6),
      const Text('Good photos get 3x more enquiries. The first photo is the cover. Use real photos of your own property only.', style: AppText.bodyM),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pics.length + (pics.length < 12 ? 1 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemBuilder: (context, i) {
          if (i == pics.length) {
            return GestureDetector(
              onTap: () => showSheet<void>(
                context,
                SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                      title: const Text('Choose from gallery'),
                      onTap: () {
                        Navigator.pop(context);
                        _addPhotos();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                      title: const Text('Take a photo'),
                      onTap: () {
                        Navigator.pop(context);
                        _takePhoto();
                      },
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryLight, width: 1.2)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                  SizedBox(height: 4),
                  Text('Add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
            );
          }
          return _thumb(pics, i, cover: i == 0);
        },
      ),
      const SizedBox(height: 22),
      const Text('Floor plans (optional)', style: AppText.h3),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (int i = 0; i < plans.length; i++) SizedBox(width: 90, height: 90, child: _thumb(plans, i)),
        if (plans.length < 3)
          GestureDetector(
            onTap: () => _addPhotos(plan: true),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
              child: const Icon(Icons.add_rounded, color: AppColors.text3),
            ),
          ),
      ]),
      const SizedBox(height: 22),
      const Text('Video (optional)', style: AppText.h3),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _pickVideo,
        icon: const Icon(Icons.videocam_rounded),
        label: Text(videoBytes != null ? 'Video added: $videoName' : (existingVideo.isNotEmpty ? 'Video attached - tap to replace' : 'Add a walkthrough video')),
      ),
      const SizedBox(height: 14),
      _field('360° virtual tour link (optional)', tour, hint: 'https://...', type: TextInputType.url, icon: Icons.threed_rotation_rounded),
    ]);
  }

  Widget _thumb(List<_Pic> list, int i, {bool cover = false}) {
    final p = list[i];
    return Stack(fit: StackFit.expand, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: p.bytes != null ? Image.memory(p.bytes!, fit: BoxFit.cover) : PropertyImage(url: p.url ?? ''),
      ),
      if (cover)
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Text('COVER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ),
      Positioned(
        right: 4,
        top: 4,
        child: GestureDetector(
          onTap: () => setState(() => list.removeAt(i)),
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Color(0xAA000000), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
          ),
        ),
      ),
      if (!cover && list == pics)
        Positioned(
          left: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => setState(() {
              final x = list.removeAt(i);
              list.insert(0, x);
            }),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: Color(0xAA000000), shape: BoxShape.circle),
              child: const Icon(Icons.star_rounded, size: 15, color: Colors.white),
            ),
          ),
        ),
    ]);
  }

  // step 6
  Widget _review() {
    Widget row(String l, String v) => v.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 110, child: Text(l, style: AppText.bodyS)),
              Expanded(child: Text(v, style: AppText.label)),
            ]),
          );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Review and publish', style: AppText.h2),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (pics.isNotEmpty)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: pics.first.bytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(pics.first.bytes!, fit: BoxFit.cover))
                  : PropertyImage(url: pics.first.url ?? '', radius: BorderRadius.circular(16)),
            ),
          const SizedBox(height: 12),
          Text(title.text.trim(), style: AppText.h3),
          const SizedBox(height: 4),
          Text(formatPrice(_n(price) ?? 0, purpose: purpose, unit: priceUnit), style: AppText.price),
          const Divider(height: 24),
          row('Type', '${catOf(category).label} · ${kPurposeLabels[purpose] ?? purpose}'),
          row('Location', '${locality.text.trim()}, ${city.text.trim()}'),
          row('Area', area.text.trim().isEmpty ? '' : '${area.text.trim()} sq ft'),
          row('Bedrooms', _noBeds ? '' : '$bedrooms'),
          row('Photos', '${pics.length}'),
          row('Amenities', '${amenities.length}'),
        ]),
      ),
      const SizedBox(height: 20),
      _field('Contact number buyers will call', phone, type: TextInputType.phone, max: 10, hint: '10-digit mobile', prefix: '+91 ', icon: Icons.phone_rounded),
      const Text('Your number is shown only to logged-in users who tap "Call". You can also chat in-app.', style: AppText.bodyS),
    ]);
  }
}
