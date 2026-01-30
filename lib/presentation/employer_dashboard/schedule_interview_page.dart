import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/interview_service.dart';

class ScheduleInterviewPage extends StatefulWidget {
  final String applicationListingId;

  const ScheduleInterviewPage({
    Key? key,
    required this.applicationListingId,
  }) : super(key: key);

  @override
  State<ScheduleInterviewPage> createState() =>
      _ScheduleInterviewPageState();
}

class _ScheduleInterviewPageState extends State<ScheduleInterviewPage> {
  final _service = InterviewService();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Interview'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _datePicker(),
            SizedBox(height: 2.h),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Employer Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Interview'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            SizedBox(width: 3.w),
            Text(
              _selectedDate == null
                  ? 'Select Interview Date & Time'
                  : _selectedDate!.toLocal().toString(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_selectedDate == null) return;

    setState(() => _loading = true);

    await _service.scheduleInterview(
      applicationListingId: widget.applicationListingId,
      interviewDate: _selectedDate!,
      employerNotes: _notesCtrl.text,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
