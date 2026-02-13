import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class JobSearchPage extends StatefulWidget {
  const JobSearchPage({Key? key}) : super(key: key);

  @override
  State<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends State<JobSearchPage> {
  final SupabaseClient _db = Supabase.instance.client;
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _debounce;

  bool _loading = false;
  bool _disposed = false;

  Set<String> _savedJobIds = {};
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {}

    if (!_disposed) setState(() {});
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------
  void _onQueryChanged(String q) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (_disposed) return;

      final query = q.trim();

      if (query.isEmpty) {
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }

      await _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (_disposed) return;

    setState(() => _loading = true);

    try {
      final nowIso = DateTime.now().toIso8601String();

      final res = await _db
          .from('job_listings')
          .select('''
            *,
            companies (
              id,
              name,
              logo_url,
              industry,
              is_verified,
              rating,
              total_reviews
            )
          ''')
          .eq('status', 'active')
          .gte('expires_at', nowIso)
          .or(
            'job_title.ilike.%$query%,'
            'district.ilike.%$query%,'
            'companies.name.ilike.%$query%',
          )
          .order('created_at', ascending: false)
          .limit(50);

      final list = List<Map<String, dynamic>>.from(res);

      if (!_disposed) {
        setState(() {
          _results = list;
        });
      }
    } catch (_) {
      if (!_disposed) setState(() => _results = []);
    } finally {
      if (!_disposed) setState(() => _loading = false);
    }
  }

  // ------------------------------------------------------------
  // EVENTS
  // ------------------------------------------------------------
  Future<void> _toggleSaveJob(String jobId) async {
    final isSaved = await _homeService.toggleSaveJob(jobId);
    if (_disposed) return;

    setState(() {
      isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
    });
  }

  void _openJobDetails(Map<String, dynamic> job) {
    _homeService.trackJobView(job['id'].toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsPage(
          job: job,
          isSaved: _savedJobIds.contains(job['id'].toString()),
          onSaveToggle: () => _toggleSaveJob(job['id'].toString()),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,

                  // ✅ FIX: KhilonjiyaUI.text is a Color, not TextStyle
                  style: KhilonjiyaUI.body.copyWith(fontSize: 14),

                  decoration: InputDecoration(
                    hintText: "Search jobs, employers, district...",
                    hintStyle: KhilonjiyaUI.sub.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchCtrl.text.trim().isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _results = [];
                                _loading = false;
                              });
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchCtrl.text.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            "Type something to search jobs",
            style: KhilonjiyaUI.sub,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            "No jobs found",
            style: KhilonjiyaUI.sub,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final job = _results[i];
        final id = job['id'].toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: JobCardWidget(
            job: job,
            isSaved: _savedJobIds.contains(id),
            onSaveToggle: () => _toggleSaveJob(id),
            onTap: () => _openJobDetails(job),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}