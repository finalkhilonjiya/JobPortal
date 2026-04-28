// File: lib/presentation/profile/employer_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() =>
      _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _companyName = TextEditingController();
  final _description = TextEditingController();
  final _website = TextEditingController();

  List<String> _districts = [];
  String? _selectedDistrict;

  String? _logoPath;
  String? _logoUrl;
  String? _companyId;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ================= LOAD =================
  Future<void> _load() async {
    final user = supabase.auth.currentUser;

    final profile = await supabase
        .from('user_profiles')
        .select()
        .eq('id', user!.id)
        .single();

    final member = await supabase
        .from('company_members')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

    _companyId = member['company_id'];

    final company = await supabase
        .from('companies')
        .select()
        .eq('id', _companyId!)
        .single();

    // load districts
    final districtsRes = await supabase
        .from('assam_districts_master')
        .select('district_name')
        .order('district_name');

    _districts = List<Map<String, dynamic>>.from(districtsRes)
        .map((e) => e['district_name'] as String)
        .toList();

    _name.text = profile['full_name'] ?? '';
    _phone.text = profile['mobile_number'] ?? '';

    _companyName.text = company['name'] ?? '';
    _description.text = company['description'] ?? '';
    _website.text = company['website'] ?? '';

    _selectedDistrict = company['headquarters_city'];

    final raw = (company['logo_url'] ?? '').toString().trim();
    _logoPath = raw;

    if (raw.isNotEmpty) {
      _logoUrl = supabase.storage
          .from('company-assets')
          .getPublicUrl(raw);
    }

    setState(() => _loading = false);
  }

  // ================= LOGO =================
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null || _companyId == null) return;

    final path = 'company-logos/$_companyId.jpg';

    await supabase.storage.from('company-assets').upload(
          path,
          File(file.path),
          fileOptions: const FileOptions(upsert: true),
        );

    _logoPath = path;

    final url = supabase.storage
        .from('company-assets')
        .getPublicUrl(path);

    setState(() => _logoUrl = url);
  }

  // ================= SAVE =================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = supabase.auth.currentUser;

    setState(() => _saving = true);

    try {
      await supabase.from('user_profiles').update({
        'full_name': _name.text.trim(),
      }).eq('id', user!.id);

      await supabase.from('companies').update({
        'description': _description.text.trim(),
        'headquarters_city': _selectedDistrict,
        'website': _website.text.trim(),
        'logo_url': _logoPath,
      }).eq('id', _companyId!);

      if (!mounted) return;

      setState(() => _saving = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SlimSuccessDialog(
          message: "Profile updated successfully",
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Employer Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          _logoUrl != null ? NetworkImage(_logoUrl!) : null,
                      child: _logoUrl == null
                          ? const Icon(Icons.camera_alt, size: 22)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    const Text("Upload Logo"),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _section("Personal Info", [
                _input(_name, "Full Name"),
                _input(
                  _phone,
                  "Phone",
                  enabled: false, // locked
                ),
              ]),

              _section("Employer Info", [
                _input(
                  _companyName,
                  "Employer Name",
                  enabled: false,
                ),

                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: _dec("District"),
                  items: _districts
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedDistrict = v),
                ),

                _input(_website, "Website", required: false),
                _input(_description, "About Employer",
                    maxLines: 3, required: false),
              ]),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A), // ✅ GREEN
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Update",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...children
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    bool required = true,
    bool enabled = true,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        enabled: enabled,
        keyboardType: type,
        maxLines: maxLines,
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return "$label is required";
          }
          return null;
        },
        decoration: _dec(label),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _companyName.dispose();
    _description.dispose();
    _website.dispose();
    super.dispose();
  }
}

// ================= SUCCESS DIALOG =================

class _SlimSuccessDialog extends StatefulWidget {
  final String message;

  const _SlimSuccessDialog({required this.message});

  @override
  State<_SlimSuccessDialog> createState() => _SlimSuccessDialogState();
}

class _SlimSuccessDialogState extends State<_SlimSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 20)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _TickPainter(_progress.value),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  final double progress;
  _TickPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final start = Offset(size.width * 0.2, size.height * 0.55);
    final mid = Offset(size.width * 0.45, size.height * 0.75);
    final end = Offset(size.width * 0.8, size.height * 0.3);

    final path = Path();

    if (progress < 0.5) {
      final p = progress / 0.5;
      path.moveTo(start.dx, start.dy);
      path.lineTo(
        start.dx + (mid.dx - start.dx) * p,
        start.dy + (mid.dy - start.dy) * p,
      );
    } else {
      path.moveTo(start.dx, start.dy);
      path.lineTo(mid.dx, mid.dy);

      final p = (progress - 0.5) / 0.5;
      path.lineTo(
        mid.dx + (end.dx - mid.dx) * p,
        mid.dy + (end.dy - mid.dy) * p,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TickPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}