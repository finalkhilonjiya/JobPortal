import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/employer_job_service.dart';

class EmployerJobApplicantsPage extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  final _service = EmployerJobService();

  EmployerJobApplicantsPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(jobTitle)),
      body: FutureBuilder(
        future: _service.getApplicants(jobId),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final applicants = s.data as List<Map<String, dynamic>>;

          if (applicants.isEmpty) {
            return const Center(child: Text('No applications yet'));
          }

          return ListView.separated(
            itemCount: applicants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final a = applicants[i];
              final app = a['job_applications'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: app['photo_file_url'] != null
                      ? NetworkImage(app['photo_file_url'])
                      : null,
                  child: app['photo_file_url'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(app['name']),
                subtitle: Text(a['application_status']),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    await _service.updateStatus(
                      linkId: a['id'],
                      status: v,
                    );
                    (context as Element).markNeedsBuild();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'shortlisted', child: Text('Shortlist')),
                    PopupMenuItem(value: 'interviewed', child: Text('Interview')),
                    PopupMenuItem(value: 'rejected', child: Text('Reject')),
                  ],
                ),
                onTap: () {
                  _openResume(app['resume_file_url']);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openResume(String? url) {
    if (url == null) return;
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
