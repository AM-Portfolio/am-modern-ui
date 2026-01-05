
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/import_data/import_data_models.dart';
import '../import_data_widgets.dart';


/// Dialog for importing data into portfolio
class ImportDataDialog extends ConsumerStatefulWidget {
  const ImportDataDialog({super.key});

  @override
  ConsumerState<ImportDataDialog> createState() => _ImportDataDialogState();

  /// Show the import data dialog
  static Future<ImportDataResult?> show(BuildContext context) =>
      showDialog<ImportDataResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ImportDataDialog(),
      );
}

class _ImportDataDialogState extends ConsumerState<ImportDataDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  ImportDataOption? _selectedOption;
  DocumentType? _selectedDocumentType;
  BrokerType? _selectedBroker;
  int _currentStep = 0;

  // File upload states
  List<PlatformFile>? _selectedFiles;

  // Step labels for the wizard
  static const List<String> _stepLabels = ['Method', 'Document', 'Broker'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) => FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;

              // Better responsive sizing
              final dialogWidth = screenWidth < 600
                  ? screenWidth * 0.95
                  : screenWidth < 1200
                  ? screenWidth * 0.8
                  : 800.0;

              return Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  minWidth: 280,
                  maxHeight: screenHeight * 0.9,
                  minHeight: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fixed header section with better padding
                    Padding(
                      padding: EdgeInsets.all(screenWidth < 600 ? 16.0 : 24.0),
                      child: Column(
                        children: [
                          DialogHeader(
                            icon: Icons.upload_file,
                            title: 'Import Data',
                            subtitle: _getStepTitle(),
                            onClose: () => Navigator.pop(context),
                          ),
                          SizedBox(height: screenWidth < 600 ? 12 : 16),
                          StepIndicator(
                            currentStep: _currentStep,
                            stepLabels: _stepLabels,
                          ),
                        ],
                      ),
                    ),

                    // Scrollable content section
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 600 ? 16.0 : 24.0,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: screenHeight * 0.25,
                              ),
                              child: _buildStepContent(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Fixed actions section with better padding
                    Padding(
                      padding: EdgeInsets.all(screenWidth < 600 ? 16.0 : 24.0),
                      child: WizardNavigation(
                        currentStep: _currentStep,
                        totalSteps: _stepLabels.length,
                        canProceed: _canProceed(),
                        onBack: _currentStep > 0
                            ? () => setState(() => _currentStep--)
                            : null,
                        onNext: _handleNext,
                        onCancel: () => Navigator.pop(context),
                        nextButtonText:
                            _currentStep == 2 && _selectedBroker != null
                            ? 'Import'
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildMethodSelection();
      case 1:
        return _buildDocumentTypeSelection();
      case 2:
        return _buildBrokerSelection();
      default:
        return _buildMethodSelection();
    }
  }

  Widget _buildMethodSelection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      ImportMethodSelector(
        selectedOption: _selectedOption,
        onOptionSelected: (option) {
          setState(() {
            _selectedOption = option;
            // Clear selected files when changing methods
            if (option != ImportDataOption.excel) {
              _selectedFiles = null;
            }
          });
        },
      ),

      // Show file upload area if Excel/CSV is selected
      if (_selectedOption == ImportDataOption.excel) ...[
        const SizedBox(height: 20),
        FileUploadWidget(
          onFilesSelected: (files) {
            setState(() {
              _selectedFiles = files;
            });
          },
          onUploadFiles: (files) async {
            // Just store files for now, actual upload happens when broker is selected
            setState(() {
              _selectedFiles = files;
            });
            _showSuccessSnackBar(
              'Files selected successfully! Complete the remaining steps to upload.',
            );
          },
          onShowError: _showErrorSnackBar,
          onShowSuccess: _showSuccessSnackBar,
        ),
      ],
    ],
  );

  Widget _buildDocumentTypeSelection() => DocumentTypeSelector(
    selectedDocumentType: _selectedDocumentType,
    onDocumentTypeSelected: (docType) {
      setState(() {
        _selectedDocumentType = docType;
      });
    },
  );

  Widget _buildBrokerSelection() => BrokerSelector(
    selectedBroker: _selectedBroker,
    onBrokerSelected: (broker) {
      setState(() {
        _selectedBroker = broker;
      });
    },
  );

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select import method';
      case 1:
        return 'Choose document type';
      case 2:
        return 'Select your broker';
      default:
        return 'Import your data';
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        if (_selectedOption == ImportDataOption.excel) {
          // For Excel/CSV option, files must be selected
          return _selectedOption != null &&
              _selectedFiles != null &&
              _selectedFiles!.isNotEmpty;
        }
        return _selectedOption != null;
      case 1:
        return _selectedDocumentType != null;
      case 2:
        return _selectedBroker != null;
      default:
        return false;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Final step - upload documents and return result
      await _uploadDocumentsAndFinish();
    }
  }

  /// Map our DocumentType enum to the service's DocumentCategory enum
  DocumentCategory _mapDocumentTypeToCategory(DocumentType documentType) {
    switch (documentType) {
      case DocumentType.brokerPortfolio:
        return DocumentCategory.brokerPortfolio;
      case DocumentType.mutualFund:
        return DocumentCategory.mutualFund;
      case DocumentType.npsStatement:
        return DocumentCategory.npsStatement;
      case DocumentType.companyFinancialReport:
        return DocumentCategory.companyFinancialReport;
      case DocumentType.stockPortfolio:
        return DocumentCategory.stockPortfolio;
      case DocumentType.nseIndices:
        return DocumentCategory.nseIndices;
      case DocumentType.tradeFno:
        return DocumentCategory.tradeFno;
      case DocumentType.tradeEq:
        return DocumentCategory.tradeEq;
    }
  }

  Future<void> _uploadDocumentsAndFinish() async {
    try {
      // Show loading state
      _showLoadingSnackBar('Uploading documents...');

      // Fix circular dependency by accessing provider through container
      final container = ProviderScope.containerOf(context);
      final documentService = container.read(documentUploadServiceProvider);
      final uploadResults = <DocumentUpload>[];

      // Upload each selected file
      if (_selectedFiles != null && _selectedFiles!.isNotEmpty) {
        for (final file in _selectedFiles!) {
          try {
            final documentUpload = await documentService.uploadDocument(
              file: kIsWeb ? file.bytes! : File(file.path!),
              fileName: file.name,
              category: _mapDocumentTypeToCategory(_selectedDocumentType!),
              portfolioId: 'default_portfolio', // TODO: Get from user context
              userId: 'current_user', // TODO: Get from auth context
              description:
                  'Import from ${_selectedBroker?.label} - ${_selectedDocumentType?.label}',
            );
            uploadResults.add(documentUpload);
          } catch (e) {
            debugPrint('Failed to upload file ${file.name}: $e');
            _showErrorSnackBar(
              'Failed to upload ${file.name}: ${e.toString()}',
            );
            return;
          }
        }
      }

      // Show success message with details
      final successMessage = uploadResults.isEmpty
          ? 'Import request created successfully for ${_selectedBroker?.label}!'
          : 'Documents uploaded successfully! ${uploadResults.length} file(s) processed for ${_selectedBroker?.label}.';

      _showSuccessSnackBar(successMessage);

      // Log the successful import for debugging
      debugPrint('Import completed successfully:');
      debugPrint('  - Broker: ${_selectedBroker?.label}');
      debugPrint('  - Document Type: ${_selectedDocumentType?.label}');
      debugPrint('  - Upload Method: ${_selectedOption?.label}');
      debugPrint('  - Files Uploaded: ${uploadResults.length}');
      if (uploadResults.isNotEmpty) {
        for (final upload in uploadResults) {
          debugPrint(
            '    - ${upload.identity.fileName} (${upload.identity.processId})',
          );
        }
      }

      // Wait a moment for user to see the success message
      await Future.delayed(const Duration(milliseconds: 1500));

      // Return result with upload information
      final result = ImportDataResult(
        option: _selectedOption!,
        documentType: _selectedDocumentType,
        brokerType: _selectedBroker,
      );
      Navigator.pop(context, result);
    } catch (e) {
      debugPrint('Error in upload process: $e');
      _showErrorSnackBar('Failed to process request: ${e.toString()}');
    }
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF9800),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
