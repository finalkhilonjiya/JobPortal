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

  // ------------------------------------------------------------
  // FILTERS — State / District / Qualification
  // ------------------------------------------------------------
  static const List<String> _neStates = [
    'Assam',
    'Arunachal Pradesh',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Tripura',
    'Sikkim',
  ];

  static const List<String> _qualificationOptions = [
    "Any",
    "Any Graduate",
    "Below 10th",
    "10th Pass",
    "12th Pass",
    "ITI",
    "Diploma",
    "Polytechnic",
    "BA",
    "BSc",
    "BCom",
    "BBA",
    "BCA",
    "B.Tech / BE",
    "MA",
    "MSc",
    "MCom",
    "MBA",
    "MCA",
    "M.Tech / ME",
    "CA",
    "CS",
    "ICWA",
    "PhD",
    "Other",
  ];

  String? _filterState;
  String? _filterDistrict;
  String? _filterQualification;

  List<String> _districtOptions = [];

  bool get _hasActiveFilters =>
      (_filterState ?? '').isNotEmpty ||
      (_filterDistrict ?? '').isNotEmpty ||
      (_filterQualification ?? '').isNotEmpty;

  bool get _hasAnyCriteria =>
      _searchCtrl.text.trim().isNotEmpty || _hasActiveFilters;

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

      if (!_hasAnyCriteria) {
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }

      await _search();
    });
  }

  Future<void> _search() async {
    if (_disposed) return;

    setState(() => _loading = true);

    try {
      final nowIso = DateTime.now().toIso8601String();
      final query = _searchCtrl.text.trim();

      var builder = _db
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
          .gte('expires_at', nowIso);

      if (query.isNotEmpty) {
        builder = builder.or(
          'job_title.ilike.%$query%,'
          'district.ilike.%$query%,'
          'companies.name.ilike.%$query%',
        );
      }

      if ((_filterState ?? '').isNotEmpty) {
        builder = builder.eq('location_state', _filterState!);
      }

      if ((_filterDistrict ?? '').isNotEmpty) {
        builder = builder.eq('district', _filterDistrict!);
      }

      if ((_filterQualification ?? '').isNotEmpty &&
          _filterQualification != 'Any') {
        // Jobs that specifically require this qualification, plus jobs
        // open to "Any" qualification (those are a match for everyone).
        builder = builder.or(
          'education_required.eq.$_filterQualification,'
          'education_required.eq.Any',
        );
      }

      final res = await builder.order('created_at', ascending: false).limit(50);

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
  // FILTER SHEET
  // ------------------------------------------------------------
  Future<void> _openFilterSheet() async {

    String? state = _filterState;
    String? district = _filterDistrict;
    String? qualification = _filterQualification;

    List<String> districtOptions = List.of(_districtOptions);
    bool loadingDistricts = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {

            Future<void> loadDistricts(String s) async {
              setSheetState(() => loadingDistricts = true);
              try {
                final res = await _db
                    .from('ne_states_districts_master')
                    .select('district_name')
                    .eq('state_name', s)
                    .order('district_name', ascending: true);
                final items = List<Map<String, dynamic>>.from(res)
                    .map((e) => (e['district_name'] ?? '').toString())
                    .where((e) => e.isNotEmpty)
                    .toList();
                setSheetState(() {
                  districtOptions = items;
                  loadingDistricts = false;
                });
              } catch (_) {
                setSheetState(() {
                  districtOptions = [];
                  loadingDistricts = false;
                });
              }
            }

            // Load districts for a pre-selected state the first time the
            // sheet opens (e.g. reopening filters after applying earlier).
            if ((state ?? '').isNotEmpty &&
                districtOptions.isEmpty &&
                !loadingDistricts) {
              loadingDistricts = true;
              loadDistricts(state!);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        const Text(
                          "Filter Jobs",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              state = null;
                              district = null;
                              qualification = null;
                              districtOptions = [];
                            });
                          },
                          child: const Text("Clear"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text("State",
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: state,
                      hint: const Text("Any state"),
                      decoration: _filterInputDecoration(),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("Any state")),
                        ..._neStates.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))),
                      ],
                      onChanged: (v) {
                        setSheetState(() {
                          state = v;
                          district = null;
                          districtOptions = [];
                        });
                        if (v != null) loadDistricts(v);
                      },
                    ),

                    const SizedBox(height: 12),

                    const Text("District",
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: districtOptions.contains(district) ? district : null,
                      hint: Text(state == null
                          ? "Select a state first"
                          : (loadingDistricts ? "Loading..." : "Any district")),
                      decoration: _filterInputDecoration(),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("Any district")),
                        ...districtOptions.map((d) => DropdownMenuItem<String>(value: d, child: Text(d))),
                      ],
                      onChanged: (state == null || loadingDistricts)
                          ? null
                          : (v) => setSheetState(() => district = v),
                    ),

                    const SizedBox(height: 12),

                    const Text("Qualification",
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: qualification,
                      hint: const Text("Any qualification"),
                      decoration: _filterInputDecoration(),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("Any qualification")),
                        ..._qualificationOptions
                            .map((q) => DropdownMenuItem<String>(value: q, child: Text(q))),
                      ],
                      onChanged: (v) => setSheetState(() => qualification = v),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KhilonjiyaUI.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() {
                            _filterState = state;
                            _filterDistrict = district;
                            _filterQualification = qualification;
                            _districtOptions = districtOptions;
                          });
                          if (_hasAnyCriteria) {
                            _search();
                          } else {
                            setState(() => _results = []);
                          }
                        },
                        child: const Text("Apply Filters"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _filterInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
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
            const SizedBox(width: 6),
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
                              _onQueryChanged('');
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
            const SizedBox(width: 4),
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.filter_list),
                  if (_hasActiveFilters)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: KhilonjiyaUI.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _openFilterSheet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeFiltersRow() {
    final chips = <Widget>[];

    if ((_filterState ?? '').isNotEmpty) {
      chips.add(_filterChip("State: $_filterState", () {
        setState(() {
          _filterState = null;
          _filterDistrict = null;
          _districtOptions = [];
        });
        _hasAnyCriteria ? _search() : setState(() => _results = []);
      }));
    }
    if ((_filterDistrict ?? '').isNotEmpty) {
      chips.add(_filterChip("District: $_filterDistrict", () {
        setState(() => _filterDistrict = null);
        _hasAnyCriteria ? _search() : setState(() => _results = []);
      }));
    }
    if ((_filterQualification ?? '').isNotEmpty) {
      chips.add(_filterChip("Qualification: $_filterQualification", () {
        setState(() => _filterQualification = null);
        _hasAnyCriteria ? _search() : setState(() => _results = []);
      }));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: KhilonjiyaUI.primary.withOpacity(0.10),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasAnyCriteria) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            "Type something or use filters to search jobs",
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
          _activeFiltersRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
