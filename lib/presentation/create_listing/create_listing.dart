import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({Key? key}) : super(key: key);

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
      ),
      body: Center(
        child: Text('Create Listing UI goes here'),
      ),
    );
  }
}
