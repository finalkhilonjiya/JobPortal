import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FolderStructureWidget extends StatelessWidget {
  final Map<String, bool> expandedFolders;
  final String selectedFile;
  final Function(String) onFileSelected;
  final Function(String) onFolderToggle;

  const FolderStructureWidget({
    Key? key,
    required this.expandedFolders,
    required this.selectedFile,
    required this.onFileSelected,
    required this.onFolderToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Structure',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),

          // Root folder
          _buildFolderItem(
            'marketplace_pro',
            'root',
            isRoot: true,
            isExpanded: true,
          ),

          // Lib folder
          _buildFolderItem(
            'lib',
            'lib',
            level: 1,
            isExpanded: expandedFolders['lib']!,
          ),

          if (expandedFolders['lib']!) ...[
            // Main.dart file
            _buildFileItem('main.dart', 'lib/main.dart', level: 2),

            // Services folder (highlighted)
            _buildFolderItem(
              'services',
              'lib/services',
              level: 2,
              isExpanded: expandedFolders['lib/services']!,
              isHighlighted: true,
            ),

            if (expandedFolders['lib/services']!) ...[
              _buildFileItem(
                'supabase_service.dart',
                'lib/services/supabase_service.dart',
                level: 3,
                isHighlighted: true,
              ),
            ],

            // Other folders
            _buildFolderItem(
              'presentation',
              'lib/presentation',
              level: 2,
              isExpanded: expandedFolders['lib/presentation']!,
            ),

            _buildFolderItem(
              'utils',
              'lib/utils',
              level: 2,
              isExpanded: expandedFolders['lib/utils']!,
            ),

            _buildFolderItem(
              'core',
              'lib/core',
              level: 2,
              isExpanded: expandedFolders['lib/core']!,
            ),

            _buildFolderItem(
              'theme',
              'lib/theme',
              level: 2,
              isExpanded: expandedFolders['lib/theme']!,
            ),

            _buildFolderItem(
              'widgets',
              'lib/widgets',
              level: 2,
              isExpanded: expandedFolders['lib/widgets']!,
            ),

            _buildFolderItem(
              'routes',
              'lib/routes',
              level: 2,
              isExpanded: expandedFolders['lib/routes']!,
            ),
          ],

          SizedBox(height: 2.h),

          // Configuration Notice
          _buildConfigurationNotice(),
        ],
      ),
    );
  }

  Widget _buildFolderItem(
    String name,
    String path, {
    int level = 0,
    bool isRoot = false,
    bool isExpanded = false,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: level * 4.w),
      child: InkWell(
        onTap: () => onFolderToggle(path),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.blue[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isHighlighted
                ? Border.all(color: Colors.blue[200]!, width: 1)
                : null,
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName:
                    isExpanded ? 'keyboard_arrow_down' : 'keyboard_arrow_right',
                color: Colors.grey[600]!,
                size: 4.w,
              ),
              SizedBox(width: 1.w),
              CustomIconWidget(
                iconName: isRoot ? 'folder_open' : 'folder',
                color: isHighlighted ? Colors.blue[600]! : Colors.orange[600]!,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                  color: isHighlighted ? Colors.blue[800] : Colors.grey[700],
                ),
              ),
              if (isHighlighted) ...[
                SizedBox(width: 2.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'NEW',
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(
    String name,
    String path, {
    int level = 0,
    bool isHighlighted = false,
  }) {
    final isSelected = selectedFile == path;

    return Padding(
      padding: EdgeInsets.only(left: level * 4.w),
      child: InkWell(
        onTap: () => onFileSelected(path),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
                : isHighlighted
                    ? Colors.blue[50]
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isSelected
                ? Border.all(color: AppTheme.lightTheme.primaryColor, width: 1)
                : isHighlighted
                    ? Border.all(color: Colors.blue[200]!, width: 1)
                    : null,
          ),
          child: Row(
            children: [
              SizedBox(width: 5.w),
              CustomIconWidget(
                iconName: _getFileIcon(name),
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : isHighlighted
                        ? Colors.blue[600]!
                        : Colors.grey[600]!,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: isSelected || isHighlighted
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : isHighlighted
                          ? Colors.blue[800]
                          : Colors.grey[700],
                ),
              ),
              if (isHighlighted) ...[
                SizedBox(width: 2.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DEMO',
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationNotice() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: Colors.green[600]!,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Configuration Guide',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '• Replace YOUR_SUPABASE_URL with your actual Supabase URL\n• Replace YOUR_SUPABASE_ANON_KEY with your anon key\n• Keep credentials secure and never commit them to version control',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.green[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getFileIcon(String fileName) {
    if (fileName.endsWith('.dart')) {
      return 'code';
    } else if (fileName.endsWith('.yaml') || fileName.endsWith('.yml')) {
      return 'settings';
    } else if (fileName.endsWith('.json')) {
      return 'data_object';
    } else {
      return 'description';
    }
  }
}
