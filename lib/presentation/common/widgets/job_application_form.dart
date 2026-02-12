import 'package:flutter/material.dart';

import 'package:khilonjiya_com/core/ui/khilonjiya_ui.dart';

class JobApplicationForm extends StatelessWidget {
  final String jobId;

  const JobApplicationForm({
    Key? key,
    required this.jobId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: KhilonjiyaUI.text,
        elevation: 1,
        title: const Text("Apply"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: KhilonjiyaUI.cardDecoration(radius: 20),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Job Application Form", style: KhilonjiyaUI.hTitle),
              const SizedBox(height: 8),
              Text(
                "Placeholder screen.\nYou will implement this later.",
                style: KhilonjiyaUI.body.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Job ID: $jobId",
                style: KhilonjiyaUI.sub.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // return false (not applied)
                    Navigator.pop(context, false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhilonjiyaUI.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Back",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}