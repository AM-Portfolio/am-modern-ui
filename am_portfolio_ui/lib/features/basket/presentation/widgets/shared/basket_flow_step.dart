/// Steps in the custom basket creation flow.
enum BasketFlowStep {
  preview(1, 'Preview'),
  customize(2, 'Customize'),
  finalReview(3, 'Final Review'),
  confirm(4, 'Confirm & Create');

  const BasketFlowStep(this.stepNumber, this.label);

  final int stepNumber;
  final String label;
}
