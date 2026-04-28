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
  final _city = TextEditingController(); // ✅ FIXED
  final _website = TextEditingController();

  String? _logoPath;

  bool _loading = true;
  bool _saving = false;

  String? _logoUrl;
  String? _companyId;

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

    _name.text = profile['full_name'] ?? '';
    _phone.text = profile['mobile_number'] ?? '';

    _companyName.text = company['name'] ?? '';
    _description.text = company['description'] ?? '';

    // ✅ FIXED (NO location column)
    _city.text = company['headquarters_city'] ?? '';

    _website.text = company['website'] ?? '';

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
      // USER
      await supabase.from('user_profiles').update({
        'full_name': _name.text.trim(),
        'mobile_number': _phone.text.trim(),
      }).eq('id', user!.id);

      // COMPANY
      await supabase.from('companies').update({
        'description': _description.text.trim(),
        'headquarters_city': _city.text.trim(), // ✅ FIXED
        'website': _website.text.trim(),
        'logo_url': _logoPath,
      }).eq('id', _companyId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => _saving = false);
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
        title: const Text("Profile"),
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
              // LOGO
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
                _input(_phone, "Phone",
                    type: TextInputType.number),
              ]),

              _section("Company Info", [
                // 🔒 LOCKED FIELD
                _input(
                  _companyName,
                  "Company Name",
                  enabled: false,
                ),

                _input(_city, "City"),
                _input(_website, "Website", required: false),
                _input(_description, "About Company",
                    maxLines: 3, required: false),
              ]),

              const SizedBox(height: 20),

              // ✅ SMALL SLEEK BUTTON
              SizedBox(
                width: double.infinity,
                height: 44, // smaller
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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
                            color: Colors.white, // ✅ visible
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

  // ================= UI HELPERS =================

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
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
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

          if (label == "Phone") {
            if (v!.length != 10) return "Enter valid 10 digit number";
          }

          if (label == "Website" && v!.isNotEmpty) {
            if (!v.startsWith("http")) {
              return "Enter valid URL";
            }
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor:
              enabled ? Colors.white : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _companyName.dispose();
    _description.dispose();
    _city.dispose();
    _website.dispose();
    super.dispose();
  }
}