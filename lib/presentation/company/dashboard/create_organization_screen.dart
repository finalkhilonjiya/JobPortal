// lib/presentation/company/dashboard/create_organization_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/employer_dashboard_service.dart';
import '../../../routes/app_routes.dart';

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final SupabaseClient _db = Supabase.instance.client;
  final EmployerDashboardService _service = EmployerDashboardService();

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _businessTypes = [];

  final TextEditingController _name = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _desc = TextEditingController();

  String? _selectedDistrictId;
  String? _selectedBusinessTypeId;

  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE6E8EC);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

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
    if (u == null) throw Exception("Session expired. Please login again.");
    return u;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadMasters() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final dRes = await _db
          .from('assam_districts_master')
          .select('id, district_name')
          .order('district_name', ascending: true);

      _districts = List<Map<String, dynamic>>.from(dRes);

      final bRes = await _db
          .from('business_types_master')
          .select('id, type_name')
          .eq('is_active', true)
          .order('type_name', ascending: true);

      _businessTypes = List<Map<String, dynamic>>.from(bRes);
    } catch (e) {
      _toast("Failed to load dropdowns");
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // CREATE ORGANIZATION
  // ------------------------------------------------------------
  Future<void> _create() async {
    _requireUser();

    final name = _name.text.trim();

    if (name.isEmpty) {
      _toast("Organization name required");
      return;
    }

    if ((_selectedBusinessTypeId ?? '').isEmpty) {
      _toast("Business type required");
      return;
    }

    if ((_selectedDistrictId ?? '').isEmpty) {
      _toast("District required");
      return;
    }

    if (!mounted) return;
    setState(() => _saving = true);

    try {
      await _service.createOrganization(
        name: name,
        businessTypeId: _selectedBusinessTypeId!,
        districtId: _selectedDistrictId!,
        website: _website.text.trim(),
        description: _desc.text.trim(),
      );

      if (!mounted) return;

      // ✅ IMPORTANT FIX: re-trigger HomeRouter
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    } catch (e) {
      _toast("Failed: $e");
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.7,
        title: const Text("Create Organization"),
        foregroundColor: _text,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  24 + keyboardBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title("Organization Details"),
                    const SizedBox(height: 6),
                    _sub(
                      "Create your organization to start posting jobs.",
                    ),
                    const SizedBox(height: 18),

                    _label("Organization name *"),
                    const SizedBox(height: 8),
                    _input(controller: _name, hint: "Eg. ABC Construction"),

                    const SizedBox(height: 14),
                    _label("Business type *"),
                    const SizedBox(height: 8),
                    _dropdown(
                      value: _selectedBusinessTypeId,
                      hint: "Select business type",
                      items: _businessTypes,
                      labelKey: 'type_name',
                      onChanged: (v) =>
                          setState(() => _selectedBusinessTypeId = v),
                    ),

                    const SizedBox(height: 14),
                    _label("District *"),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    _input(
                      controller: _website,
                      hint: "https://",
                      keyboardType: TextInputType.url,
                    ),

                    const SizedBox(height: 14),
                    _label("Description"),
                    const SizedBox(height: 8),
                    _input(
                      controller: _desc,
                      hint: "About your company",
                      minLines: 3,
                      maxLines: 5,
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _create,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _saving ? "Creating..." : "Create Organization",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _title(String t) =>
      const Text("Organization Details", style: TextStyle(fontWeight: FontWeight.w900));

  Widget _sub(String t) =>
      Text(t, style: const TextStyle(color: _muted));

  Widget _label(String t) =>
      Text(t, style: const TextStyle(fontWeight: FontWeight.w700));

  Widget _input({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}