import 'package:flutter/material.dart';

class CompanyDashboard extends StatelessWidget {
  const CompanyDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Company Dashboard\n(Job posts, applications, analytics)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
