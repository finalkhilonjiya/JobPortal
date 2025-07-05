import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/code_snippet_widget.dart';
import './widgets/folder_structure_widget.dart';
import './widgets/navigation_breadcrumb_widget.dart';

class ConfigurationSetup extends StatefulWidget {
  const ConfigurationSetup({Key? key}) : super(key: key);

  @override
  State<ConfigurationSetup> createState() => _ConfigurationSetupState();
}

class _ConfigurationSetupState extends State<ConfigurationSetup> {
  String selectedFile = 'lib/services/supabase_service.dart';
  Map<String, bool> expandedFolders = {
    'lib': true,
    'lib/services': true,
    'lib/presentation': false,
    'lib/utils': false,
    'lib/core': false,
    'lib/theme': false,
    'lib/widgets': false,
    'lib/routes': false,
  };

  final Map<String, String> fileContents = {
    'lib/services/supabase_service.dart': '''

class SupabaseService {
  static final supabase = Supabase.instance;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
  }
}''',
    'lib/main.dart': '''




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'MarketPlace Pro',
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.initial,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}''',
  };

  void _onFileSelected(String filePath) {
    setState(() {
      selectedFile = filePath;
    });
  }

  void _onFolderToggle(String folderPath) {
    setState(() {
      expandedFolders[folderPath] = !expandedFolders[folderPath]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Configuration Setup',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Navigation Breadcrumb
          NavigationBreadcrumbWidget(
            currentPath: selectedFile,
          ),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Folder Structure Panel
                Container(
                  width: 35.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: FolderStructureWidget(
                    expandedFolders: expandedFolders,
                    selectedFile: selectedFile,
                    onFileSelected: _onFileSelected,
                    onFolderToggle: _onFolderToggle,
                  ),
                ),

                // Code Display Panel
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // File Header
                        _buildFileHeader(),

                        // Code Content
                        Expanded(
                          child: CodeSnippetWidget(
                            code: fileContents[selectedFile] ?? '',
                            filePath: selectedFile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Notice
          _buildBottomNotice(),
        ],
      ),
    );
  }

  Widget _buildFileHeader() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'code',
            color: AppTheme.lightTheme.primaryColor,
            size: 5.w,
          ),
          SizedBox(width: 2.w),
          Text(
            selectedFile.split('/').last,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _copyToClipboard(fileContents[selectedFile] ?? ''),
            icon: CustomIconWidget(
              iconName: 'content_copy',
              color: Colors.grey[600]!,
              size: 4.w,
            ),
            tooltip: 'Copy to clipboard',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNotice() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(
          top: BorderSide(
            color: Colors.orange[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'warning',
            color: Colors.orange[600]!,
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'Important: Replace demo values with your actual Supabase credentials before deployment.',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Code copied to clipboard!',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
