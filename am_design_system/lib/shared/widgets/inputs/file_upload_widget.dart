import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/file_upload_models.dart';
import 'drag_drop_area.dart';
import '../displays/file_list.dart';

/// Complete file upload widget that handles drag & drop and file management
class FileUploadWidget extends StatefulWidget {
  const FileUploadWidget({
    super.key,
    this.allowedExtensions = const ['xlsx', 'xls', 'csv'],
    this.onFilesSelected,
    this.onUploadFiles,
    this.onShowError,
    this.onShowSuccess,
  });
  final List<String> allowedExtensions;
  final Function(List<PlatformFile>)? onFilesSelected;
  final Future<void> Function(List<PlatformFile>)? onUploadFiles;
  final Function(String)? onShowError;
  final Function(String)? onShowSuccess;

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  FileUploadState _state = const FileUploadState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border.all(
        color: _state.isDragOver
            ? const Color(0xFFFF9800)
            : Colors.grey.withOpacity(0.3),
        width: _state.isDragOver ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(12),
      color: _state.isDragOver
          ? const Color(0xFFFF9800).withOpacity(0.05)
          : Colors.grey.withOpacity(0.02),
    ),
    child: Column(
      children: [
        if (!_state.hasFiles) ...[
          DragDropArea(
            state: _state,
            callbacks: FileUploadCallbacks(
              onPickFiles: _pickFiles,
              onDropFiles: _handleDroppedFiles,
              onShowError: widget.onShowError,
              onShowSuccess: widget.onShowSuccess,
            ),
            allowedExtensions: widget.allowedExtensions,
          ),
        ] else ...[
          FileList(files: _state.selectedFiles!, onRemoveFile: _removeFile),
          const SizedBox(height: 16),
          _buildUploadActions(),
        ],
      ],
    ),
  );

  Widget _buildUploadActions() => Row(
    children: [
      TextButton.icon(
        onPressed: _pickFiles,
        icon: const Icon(Icons.add),
        label: const Text('Add More Files'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF9800)),
      ),
      const Spacer(),
      if (_state.isUploading)
        const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
              ),
            ),
            SizedBox(width: 8),
            Text('Uploading...'),
          ],
        )
      else
        ElevatedButton.icon(
          onPressed: _uploadFiles,
          icon: const Icon(Icons.upload),
          label: const Text('Upload Files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
    ],
  );

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _state = _state.copyWith(selectedFiles: result.files);
        });
        widget.onFilesSelected?.call(result.files);
      }
    } catch (e) {
      widget.onShowError?.call('Error picking files: ${e.toString()}');
    }
  }

  void _removeFile(PlatformFile file) {
    final updatedFiles = List<PlatformFile>.from(_state.selectedFiles ?? []);
    updatedFiles.removeWhere((f) => f.name == file.name);

    setState(() {
      _state = _state.copyWith(
        selectedFiles: updatedFiles.isEmpty ? null : updatedFiles,
      );
    });

    widget.onFilesSelected?.call(updatedFiles);
  }

  Future<void> _uploadFiles() async {
    if (!_state.hasFiles) return;

    setState(() {
      _state = _state.copyWith(isUploading: true);
    });

    try {
      if (widget.onUploadFiles != null) {
        await widget.onUploadFiles!(_state.selectedFiles!);
        widget.onShowSuccess?.call('Files uploaded successfully!');
      }
    } catch (e) {
      widget.onShowError?.call('Upload failed: ${e.toString()}');
    } finally {
      setState(() {
        _state = _state.copyWith(isUploading: false);
      });
    }
  }

  Future<void> _handleDroppedFiles(List<String> filePaths) async {
    try {
      final validFiles = <PlatformFile>[];

      for (final filePath in filePaths) {
        final extension = filePath.split('.').last.toLowerCase();
        if (widget.allowedExtensions.contains(extension)) {
          final file = await _createPlatformFileFromPath(filePath);
          if (file != null) {
            validFiles.add(file);
          }
        }
      }

      if (validFiles.isNotEmpty) {
        final existingFiles = _state.selectedFiles ?? <PlatformFile>[];
        final allFiles = [...existingFiles];

        for (final newFile in validFiles) {
          final isDuplicate = allFiles.any(
            (existing) =>
                existing.name == newFile.name && existing.size == newFile.size,
          );
          if (!isDuplicate) {
            allFiles.add(newFile);
          }
        }

        setState(() {
          _state = _state.copyWith(selectedFiles: allFiles, isDragOver: false);
        });

        widget.onFilesSelected?.call(allFiles);

        if (validFiles.length < filePaths.length) {
          widget.onShowError?.call(
            'Some files were skipped. Only ${widget.allowedExtensions.join(', ')} files are supported.',
          );
        }
      } else {
        widget.onShowError?.call(
          'No valid files found. Only ${widget.allowedExtensions.join(', ')} files are supported.',
        );
      }
    } catch (e) {
      widget.onShowError?.call(
        'Error processing dropped files: ${e.toString()}',
      );
    }
  }

  Future<PlatformFile?> _createPlatformFileFromPath(String filePath) async {
    try {
      final fileName = filePath.split('/').last.split(r'\').last;

      return PlatformFile(
        name: fileName,
        size: 0, // Would need to get actual file size
        path: filePath,
      );
    } catch (e) {
      return null;
    }
  }
}
