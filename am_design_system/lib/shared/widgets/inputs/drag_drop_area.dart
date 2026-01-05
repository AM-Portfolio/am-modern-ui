import 'package:flutter/material.dart';
import '../../models/file_upload_models.dart';

/// Drag and drop area for file upload
class DragDropArea extends StatelessWidget {
  const DragDropArea({
    required this.state,
    required this.callbacks,
    super.key,
    this.allowedExtensions = const ['xlsx', 'xls', 'csv'],
    this.title = 'Drag & drop files here or click to select',
    this.subtitle = 'Support for Excel (.xlsx, .xls) and CSV files',
  });
  final FileUploadState state;
  final FileUploadCallbacks callbacks;
  final List<String> allowedExtensions;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final iconSize = (screenWidth * 0.1).clamp(48.0, 80.0);
      final titleFontSize = (screenWidth * 0.032).clamp(16.0, 22.0);
      final subtitleFontSize = (screenWidth * 0.025).clamp(12.0, 16.0);
      final verticalPadding = (screenHeight * 0.05).clamp(20.0, 50.0);

      return DragTarget<List<String>>(
        onWillAcceptWithDetails: (data) => true,
        onAcceptWithDetails: (details) => callbacks.onDropFiles?.call(details.data),
        builder: (context, candidateData, rejectedData) => GestureDetector(
          onTap: callbacks.onPickFiles,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: state.isDragOver
                        ? const Color(0xFFFF9800).withOpacity(0.2)
                        : const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(iconSize / 2),
                  ),
                  child: Icon(
                    state.isDragOver
                        ? Icons.cloud_download
                        : Icons.cloud_upload,
                    size: iconSize * 0.5,
                    color: const Color(0xFFFF9800),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  state.isDragOver ? 'Drop your files here' : title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: state.isDragOver
                        ? const Color(0xFFFF9800)
                        : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.025),
                ElevatedButton.icon(
                  onPressed: callbacks.onPickFiles,
                  icon: Icon(Icons.folder_open, size: titleFontSize * 0.8),
                  label: Text(
                    'Choose Files',
                    style: TextStyle(fontSize: titleFontSize * 0.8),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
