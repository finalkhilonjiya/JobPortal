import 'package:flutter/material.dart';

class CompanyDashboard extends StatelessWidget {
  const CompanyDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Employer Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // future: notifications
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            const Text(
              'Welcome back 👋',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage your jobs and applicants',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            Row(
              children: const [
                _StatCard(
                  title: 'Active Jobs',
                  value: '0',
                  icon: Icons.work_outline,
                ),
                SizedBox(width: 12),
                _StatCard(
                  title: 'Applications',
                  value: '0',
                  icon: Icons.people_outline,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: const [
                _StatCard(
                  title: 'Shortlisted',
                  value: '0',
                  icon: Icons.check_circle_outline,
                ),
                SizedBox(width: 12),
                _StatCard(
                  title: 'Rejected',
                  value: '0',
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Actions
            const Text(
              'Quick actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _ActionTile(
              icon: Icons.add_circle_outline,
              title: 'Post a new job',
              subtitle: 'Create and publish a job listing',
              onTap: () {
                // TODO: navigate to create job
              },
            ),

            _ActionTile(
              icon: Icons.list_alt,
              title: 'Manage job posts',
              subtitle: 'View, edit or close job listings',
              onTap: () {
                // TODO: navigate to job list
              },
            ),

            _ActionTile(
              icon: Icons.people,
              title: 'View applications',
              subtitle: 'Review candidates and applications',
              onTap: () {
                // TODO: navigate to applications
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------ UI COMPONENTS ------------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}