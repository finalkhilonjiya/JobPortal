// lib/presentation/company/create_organization_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState
    extends State<CreateOrganizationScreen> {
  final SupabaseClient _db = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _businessTypes = [];

  final TextEditingController _name = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _desc = TextEditingController();

  String? _selectedDistrictId;
  String? _selectedBusinessTypeId;

  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _primary = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  @override
  void dispose() {
    _name.dispose();
    _website.dispose();
    _desc.dispose();
    super.dispose();
  }

  User _requireUser() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired");
    return u;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadMasters() async {
    setState(() => _loading = true);

    try {
      final dRes = await _db
          .from('assam_districts_master')
          .select('id, district_name')
          .order('district_name');

      final bRes = await _db
          .from('business_types_master')
          .select('id, type_name')
          .eq('is_active', true)
          .order('type_name');

      _districts = List<Map<String, dynamic>>.from(dRes);
      _businessTypes = List<Map<String, dynamic>>.from(bRes);
    } catch (_) {
      _toast("Failed to load data");
    }

    setState(() => _loading = false);
  }

  // ============================================================
  // CREATE ORGANIZATION (FINAL CLEAN)
  // ============================================================
  Future<void> _create() async {
    final user = _requireUser();

    final name = _name.text.trim();

    if (name.isEmpty) {
      _toast("Organization name required");
      return;
    }

    if (_selectedBusinessTypeId == null) {
      _toast("Select business type");
      return;
    }

    if (_selectedDistrictId == null) {
      _toast("Select district");
      return;
    }

    setState(() => _saving = true);

    try {
      // 1️⃣ Prevent duplicate
      final existing = await _db
          .from('company_members')
          .select('company_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      // 2️⃣ Get district name
      final districtObj = _districts.firstWhere(
        (d) => d['id'].toString() == _selectedDistrictId,
      );

      final districtName = districtObj['district_name'];

      // 3️⃣ Create company
      final company = await _db
          .from('companies')
          .insert({
            "name": name,
            "business_type_id": _selectedBusinessTypeId,
            "website": _website.text.trim(),
            "description": _desc.text.trim(),
            "headquarters_city": districtName,
            "headquarters_state": "Assam",
            "created_by": user.id,
            "owner_id": user.id,
          })
          .select()
          .single();

      final companyId = company['id'];

      // 4️⃣ Link user (role = member)
      await _db.from('company_members').upsert({
        "company_id": companyId,
        "user_id": user.id,
        "role": "member",   // ✅ FINAL
        "status": "active",
      }, onConflict: 'user_id');

      // 5️⃣ Return success (dashboard will reload)
      if (!mounted) return;
      Navigator.pop(context, true);

    } catch (e) {
      _toast("Failed: $e");
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Create Organization",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        foregroundColor: _text,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Get started",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Create your organization to start hiring",
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _muted,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _label("Organization name"),
                  _input(_name, "ABC Pvt Ltd"),

                  const SizedBox(height: 14),

                  _label("Business type"),
                  _dropdown(
                    value: _selectedBusinessTypeId,
                    hint: "Select type",
                    items: _businessTypes,
                    labelKey: 'type_name',
                    onChanged: (v) =>
                        setState(() => _selectedBusinessTypeId = v),
                  ),

                  const SizedBox(height: 14),

                  _label("District"),
                  _dropdown(
                    value: _selectedDistrictId,
                    hint: "Select district",
                    items: _districts,
                    labelKey: 'district_name',
                    onChanged: (v) =>
                        setState(() => _selectedDistrictId = v),
                  ),

                  const SizedBox(height: 14),

                  _label("Website"),
                  _input(_website, "https://"),

                  const SizedBox(height: 14),

                  _label("Description"),
                  _input(_desc, "About company", maxLines: 4),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _create,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _saving ? "Creating..." : "Continue",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 13,
            color: _muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _input(TextEditingController c, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem<String>(
                value: e['id'].toString(),
                child: Text(e[labelKey].toString()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}