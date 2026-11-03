import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final Profile p = Api.profile.value!;
  late final name = TextEditingController(text: p.fullName);
  late final email = TextEditingController(text: p.email);
  late final bio = TextEditingController(text: p.bio);
  late final agency = TextEditingController(text: p.agencyName);
  late final agencyAddr = TextEditingController(text: p.agencyAddress);
  late final phones = TextEditingController(text: p.extraPhones.join(', '));
  late String role = p.role;
  late String avatar = p.avatarUrl;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [name, email, bio, agency, agencyAddr, phones]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
      if (x == null) return;
      setState(() => _busy = true);
      final url = await Api.uploadBytes(await x.readAsBytes(), 'jpg');
      if (mounted) setState(() => avatar = url);
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    if (name.text.trim().length < 2) {
      toast(context, 'Please enter your name.');
      return;
    }
    setState(() => _busy = true);
    try {
      await Api.saveProfile({
        'full_name': name.text.trim(),
        'email': email.text.trim().isEmpty ? null : email.text.trim(),
        'bio': bio.text.trim(),
        'avatar_url': avatar.isEmpty ? null : avatar,
        if (p.role != 'admin') 'role': role,
        'agency_name': agency.text.trim().isEmpty ? null : agency.text.trim(),
        'agency_address': agencyAddr.text.trim().isEmpty ? null : agencyAddr.text.trim(),
        'extra_phones': phones.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      });
      if (!mounted) return;
      toast(context, 'Profile updated.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pro = kProRoles.contains(role);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Edit profile', style: AppText.h2)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Center(
            child: GestureDetector(
              onTap: _busy ? null : _pickAvatar,
              child: Stack(children: [
                Avatar(name: name.text, url: avatar, size: 96),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: AppColors.ink, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const FormLabel('Full name'),
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: inputDeco('Your name', icon: Icons.person_outline_rounded)),
          const SizedBox(height: 14),
          const FormLabel('Email (optional)'),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: inputDeco('you@example.com', icon: Icons.mail_outline_rounded)),
          const SizedBox(height: 14),
          if (p.role != 'admin') ...[
            const FormLabel('I am a'),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final r in kRoles) PillChip(label: kRoleLabel[r] ?? r, selected: role == r, onTap: () => setState(() => role = r))]),
            const SizedBox(height: 14),
          ],
          if (pro) ...[
            const FormLabel('Agency / company'),
            TextField(controller: agency, decoration: inputDeco('Company name', icon: Icons.business_rounded)),
            const SizedBox(height: 14),
            const FormLabel('Office address'),
            TextField(controller: agencyAddr, decoration: inputDeco('Office address', icon: Icons.place_outlined)),
            const SizedBox(height: 14),
            const FormLabel('Other contact numbers'),
            TextField(controller: phones, decoration: inputDeco('Comma separated', icon: Icons.phone_outlined)),
            const SizedBox(height: 14),
          ],
          const FormLabel('About you'),
          TextField(controller: bio, maxLines: 4, maxLength: 300, decoration: inputDeco('A few words about you or your agency')),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}

class NotifPrefsScreen extends StatefulWidget {
  const NotifPrefsScreen({super.key});

  @override
  State<NotifPrefsScreen> createState() => _NotifPrefsScreenState();
}

class _NotifPrefsScreenState extends State<NotifPrefsScreen> {
  static const _items = [
    ('new_matches', 'New matches', 'When a listing matches a saved search'),
    ('price_drops', 'Price drops', 'On properties you shortlisted'),
    ('leads', 'Leads and visits', 'Enquiries and visit requests on your listings'),
    ('chat', 'Chat messages', 'New messages from owners and buyers'),
    ('promotions', 'Offers and updates', 'Product news and tips'),
  ];
  late Map<String, dynamic> _prefs = Map<String, dynamic>.from(Api.profile.value?.notifPrefs ?? {});

  Future<void> _set(String k, bool v) async {
    setState(() => _prefs[k] = v);
    try {
      await Api.saveProfile({'notif_prefs': _prefs});
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Notification settings', style: AppText.h2)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: softShadow(12)),
            child: Column(children: [
              for (final it in _items)
                SwitchListTile(
                  activeColor: AppColors.primary,
                  title: Text(it.$2, style: AppText.title),
                  subtitle: Text(it.$3, style: AppText.bodyS),
                  value: _prefs[it.$1] != false,
                  onChanged: (v) => _set(it.$1, v),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          const Text('Alerts appear inside the app. Phone push notifications are coming in a later update.', style: AppText.bodyS),
        ],
      ),
    );
  }
}
