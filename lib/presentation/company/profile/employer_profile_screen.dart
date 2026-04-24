import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/mobile_auth_service.dart';
import '../../../core/ui/khilonjiya_ui.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() =>
      _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;

    final data = await Supabase.instance.client
        .from('user_profiles')
        .select()
        .eq('id', user!.id)
        .single();

    _name.text = data['full_name'] ?? '';
    _phone.text = data['mobile_number'] ?? '';
    _company.text = data['current_company'] ?? '';

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final user = Supabase.instance.client.auth.currentUser;

    await Supabase.instance.client.from('user_profiles').update({
      'full_name': _name.text.trim(),
      'mobile_number': _phone.text.trim(),
      'current_company': _company.text.trim(),
    }).eq('id', user!.id);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Profile updated")));
  }

  Future<void> _logout() async {
    await MobileAuthService().logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/role-selection',
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 10),

            TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone")),
            const SizedBox(height: 10),

            TextField(controller: _company, decoration: const InputDecoration(labelText: "Company")),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _save,
              child: const Text("Save"),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}