// File: lib/presentation/home_marketplace_feed/expected_salary_edit_page.dart

import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

class ExpectedSalaryEditPage extends StatefulWidget {
  final int initialSalaryPerMonth;

  const ExpectedSalaryEditPage({
    Key? key,
    required this.initialSalaryPerMonth,
  }) : super(key: key);

  @override
  State<ExpectedSalaryEditPage> createState() => _ExpectedSalaryEditPageState();
}

class _ExpectedSalaryEditPageState extends State<ExpectedSalaryEditPage> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  final TextEditingController _controller = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.text =
        widget.initialSalaryPerMonth > 0 ? widget.initialSalaryPerMonth.toString() : '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _parseSalary() {
    final raw = _controller.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
  }

  Future<void> _save() async {
    if (_saving) return;

    final salary = _parseSalary();

    if (salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid monthly salary")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _homeService.updateExpectedSalaryPerMonth(salary);

      if (!mounted) return;
      Navigator.pop(context, salary);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: Text(
          "Expected salary (monthly)",
          style: KhilonjiyaUI.h2.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            decoration: KhilonjiyaUI.cardDecoration(radius: 16),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter salary per month (INR)",
                  style: KhilonjiyaUI.cardTitle,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Example: 25000",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: KhilonjiyaUI.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: KhilonjiyaUI.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: KhilonjiyaUI.primary,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KhilonjiyaUI.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "Save",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}