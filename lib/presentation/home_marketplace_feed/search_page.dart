import 'package:flutter/material.dart';

import 'package:khilonjiya_com/core/ui/khilonjiya_ui.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Search jobs, companies, skills...",
                        hintStyle: KhilonjiyaUI.sub,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: KhilonjiyaUI.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: KhilonjiyaUI.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: KhilonjiyaUI.primary.withOpacity(0.6),
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      // placeholder
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.search_rounded,
                    size: 46,
                    color: Colors.black.withOpacity(0.35),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      "Search coming soon",
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      "This is a placeholder screen.\nYou will implement search later.",
                      textAlign: TextAlign.center,
                      style: KhilonjiyaUI.sub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}