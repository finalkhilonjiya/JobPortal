import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar('Settings'),
      body: ListView(
        children: [
          _item('Notifications'),
          _item('Privacy'),
          _item('Account security'),
          _item('Language'),
        ],
      ),
    );
  }

  Widget _item(String t) => ListTile(
        title: Text(t, style: TextStyle(fontSize: 12.sp)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      );

  AppBar _appBar(String t) => AppBar(
        title: Text(t),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      );
}
