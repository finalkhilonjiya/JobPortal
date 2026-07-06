// File: lib/presentation/company/candidates/candidate_database_page.dart

import 'package:flutter/material.dart';

import '../../../services/candidate_database_service.dart';
import '../../../services/employer_subscription_service.dart';
import '../subscription/employer_subscription_page.dart';

class CandidateDatabasePage extends StatefulWidget {

  final String companyId;

  const CandidateDatabasePage({
    Key? key,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CandidateDatabasePage> createState() => _CandidateDatabasePageState();
}

class _CandidateDatabasePageState extends State<CandidateDatabasePage> {

  final CandidateDatabaseService _service = CandidateDatabaseService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _hasFullAccess = false;
  List<Map<String, dynamic>> _candidates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? search}) async {

    setState(() => _loading = true);

    try {
      final rows = await _service.getCandidates(search: search);

      if (!mounted) return;

      setState(() {
        _candidates = rows;
        _hasFullAccess =
            rows.isNotEmpty ? (rows.first['has_full_access'] == true) : _hasFullAccess;
        _loading = false;
      });
    } catch (e) {

      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load candidates: $e")),
      );
    }
  }

  void _goToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployerSubscriptionPage(companyId: widget.companyId),
      ),
    ).then((_) => _load(search: _searchCtrl.text));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Candidate Database",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [

          if (!_hasFullAccess) _lockedBanner(),

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search by name, title, or skill",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => _load(search: v),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _candidates.isEmpty
                    ? const Center(child: Text("No candidates found"))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _candidates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _candidateCard(_candidates[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _lockedBanner() {

    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF7ED),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Color(0xFFEA580C), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "You're browsing in preview mode. Get Khilonjiya Premium to view resumes and contact details.",
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: _goToSubscription,
            child: const Text("Unlock"),
          ),
        ],
      ),
    );
  }

  Widget _candidateCard(Map<String, dynamic> c) {

    final name = (c['full_name'] ?? 'Candidate').toString();
    final title = (c['current_job_title'] ?? '').toString();
    final company = (c['current_company'] ?? '').toString();
    final city = (c['current_city'] ?? '').toString();
    final state = (c['current_state'] ?? '').toString();
    final exp = c['total_experience_years'];
    final skills = (c['skills'] is List)
        ? List<String>.from(c['skills'])
        : <String>[];
    final hasAccess = c['has_full_access'] == true;
    final boosted = c['is_boost_enabled'] == true;
    final avatar = (c['avatar_url'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: boosted
            ? Border.all(color: const Color(0xFF16A34A), width: 1.2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?")
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (boosted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Boosted",
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (title.isNotEmpty || company.isNotEmpty)
                      Text(
                        [title, company].where((e) => e.isNotEmpty).join(" at "),
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    if (city.isNotEmpty || state.isNotEmpty)
                      Text(
                        [city, state].where((e) => e.isNotEmpty).join(", "),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (exp != null) ...[
            const SizedBox(height: 8),
            Text("$exp years experience",
                style: const TextStyle(fontSize: 12.5)),
          ],

          if (skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.take(6).map((s) {
                return Chip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: Text(hasAccess ? "View Resume" : "View Resume 🔒"),
                  onPressed: () {
                    if (!hasAccess) {
                      _goToSubscription();
                      return;
                    }
                    final url = (c['resume_url'] ?? '').toString();
                    if (url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("This candidate hasn't uploaded a resume"),
                        ),
                      );
                      return;
                    }
                    // TODO: open `url` with your existing PDF/webview viewer
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.call, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  label: Text(hasAccess ? "Contact" : "Contact 🔒"),
                  onPressed: () {
                    if (!hasAccess) {
                      _goToSubscription();
                      return;
                    }
                    // hasAccess == true means mobile_number / actual_email
                    // are populated on `c` — wire up your call/email sheet here.
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
