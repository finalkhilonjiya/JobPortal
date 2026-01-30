import 'package:flutter/material.dart';
import '../../services/employer_job_service.dart';
import 'employer_job_applicants_page.dart';

class EmployerJobsPage extends StatelessWidget {
  final _service = EmployerJobService();

  EmployerJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Jobs')),
      body: FutureBuilder(
        future: _service.getMyJobs(),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = s.data as List<Map<String, dynamic>>;

          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs posted'));
          }

          return ListView.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final j = jobs[i];
              return ListTile(
                title: Text(j['job_title']),
                subtitle: Text('${j['applications_count']} applicants'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployerJobApplicantsPage(
                        jobId: j['id'],
                        jobTitle: j['job_title'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
