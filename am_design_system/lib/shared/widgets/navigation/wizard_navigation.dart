import 'package:flutter/material.dart';

/// Wizard navigation widget with back and next buttons
class WizardNavigation extends StatelessWidget {
  const WizardNavigation({
    required this.currentStep,
    required this.totalSteps,
    required this.canProceed,
    super.key,
    this.onBack,
    this.onNext,
    this.onCancel,
    this.nextButtonText,
    this.backButtonText,
    this.cancelButtonText,
  });
  final int currentStep;
  final int totalSteps;
  final bool canProceed;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onCancel;
  final String? nextButtonText;
  final String? backButtonText;
  final String? cancelButtonText;

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep >= totalSteps - 1;
    final effectiveNextText =
        nextButtonText ?? (isLastStep ? 'Finish' : 'Next');
    final effectiveBackText = backButtonText ?? 'Back';
    final effectiveCancelText = cancelButtonText ?? 'Cancel';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button (only show if not on first step)
        if (currentStep > 0)
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: Text(effectiveBackText),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
          )
        else
          const SizedBox.shrink(),

        // Cancel and Next buttons
        Row(
          children: [
            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                child: Text(
                  effectiveCancelText,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            if (onCancel != null) const SizedBox(width: 12),
            ElevatedButton(
              onPressed: canProceed ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                effectiveNextText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
