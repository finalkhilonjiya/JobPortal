import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CodeSnippetWidget extends StatelessWidget {
  final String code;
  final String filePath;

  const CodeSnippetWidget({
    Key? key,
    required this.code,
    required this.filePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filePath.contains('supabase_service.dart')) ...[
            _buildConfigurationAnnotation(),
            SizedBox(height: 2.h),
          ],
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3.w,
                        height: 3.w,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Container(
                        width: 3.w,
                        height: 3.w,
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Container(
                        width: 3.w,
                        height: 3.w,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        filePath,
                        style: GoogleFonts.firaCode(
                          fontSize: 10.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                // Code content
                Container(
                  padding: EdgeInsets.all(3.w),
                  child: _buildSyntaxHighlightedCode(code),
                ),
              ],
            ),
          ),
          if (filePath.contains('supabase_service.dart')) ...[
            SizedBox(height: 2.h),
            _buildSecurityBestPractices(),
          ],
        ],
      ),
    );
  }

  Widget _buildConfigurationAnnotation() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'settings',
                color: Colors.blue[600]!,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Supabase Configuration',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'This service file contains the Supabase configuration with demo values. Replace the placeholder values with your actual Supabase project credentials:',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
          SizedBox(height: 1.h),
          _buildParameterExplanation('YOUR_SUPABASE_URL',
              'Your Supabase project URL from the dashboard'),
          _buildParameterExplanation('YOUR_SUPABASE_ANON_KEY',
              'Your Supabase anon/public key for client-side access'),
        ],
      ),
    );
  }

  Widget _buildParameterExplanation(String parameter, String explanation) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$parameter: ',
                    style: GoogleFonts.firaCode(
                      fontSize: 10.sp,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: explanation,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyntaxHighlightedCode(String code) {
    final lines = code.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line numbers
            Container(
              width: 8.w,
              padding: EdgeInsets.only(right: 2.w),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.firaCode(
                  fontSize: 10.sp,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.right,
              ),
            ),

            // Code line
            Expanded(
              child: _buildHighlightedLine(line),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHighlightedLine(String line) {
    // Simple syntax highlighting
    if (line.trim().startsWith('import ')) {
      return Text(
        line,
        style: GoogleFonts.firaCode(
          fontSize: 11.sp,
          color: Colors.purple[300],
        ),
      );
    } else if (line.trim().startsWith('class ')) {
      return Text(
        line,
        style: GoogleFonts.firaCode(
          fontSize: 11.sp,
          color: Colors.blue[300],
        ),
      );
    } else if (line.trim().startsWith('static ')) {
      return Text(
        line,
        style: GoogleFonts.firaCode(
          fontSize: 11.sp,
          color: Colors.orange[300],
        ),
      );
    } else if (line.contains('YOUR_SUPABASE_URL') ||
        line.contains('YOUR_SUPABASE_ANON_KEY')) {
      return RichText(
        text: TextSpan(
          children: _highlightPlaceholders(line),
        ),
      );
    } else if (line.trim().startsWith('//')) {
      return Text(
        line,
        style: GoogleFonts.firaCode(
          fontSize: 11.sp,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      );
    } else {
      return Text(
        line,
        style: GoogleFonts.firaCode(
          fontSize: 11.sp,
          color: Colors.grey[300],
        ),
      );
    }
  }

  List<TextSpan> _highlightPlaceholders(String line) {
    final List<TextSpan> spans = [];
    final RegExp placeholderRegex = RegExp(r"'(YOUR_SUPABASE_[^']*)'");

    int lastEnd = 0;
    for (final match in placeholderRegex.allMatches(line)) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: line.substring(lastEnd, match.start),
          style: GoogleFonts.firaCode(
            fontSize: 11.sp,
            color: Colors.grey[300],
          ),
        ));
      }

      // Add the highlighted placeholder
      spans.add(TextSpan(
        text: match.group(0),
        style: GoogleFonts.firaCode(
          fontSize: 11.sp,
          color: Colors.red[300],
          backgroundColor: Colors.red[900]?.withValues(alpha: 0.3 * 255),
          fontWeight: FontWeight.w600,
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastEnd),
        style: GoogleFonts.firaCode(
          fontSize: 11.sp,
          color: Colors.grey[300],
        ),
      ));
    }

    return spans;
  }

  Widget _buildSecurityBestPractices() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'security',
                color: Colors.orange[600]!,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Security Best Practices',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '• Never commit actual credentials to version control\n• Use environment variables for production deployment\n• Rotate your keys regularly\n• Keep your anon key secure - it provides public access\n• Monitor your Supabase usage and access logs',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.orange[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
