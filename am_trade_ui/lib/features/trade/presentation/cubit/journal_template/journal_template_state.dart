import 'package:equatable/equatable.dart';
import '../../../internal/domain/entities/journal_template.dart';

/// Base state for journal template
abstract class JournalTemplateState extends Equatable {
  const JournalTemplateState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class JournalTemplateInitial extends JournalTemplateState {
  const JournalTemplateInitial();
}

/// Loading state
class JournalTemplateLoading extends JournalTemplateState {
  const JournalTemplateLoading();
}

/// Loaded state with templates
class JournalTemplateLoaded extends JournalTemplateState {
  const JournalTemplateLoaded({
    required this.templates,
    this.selectedTemplate,
  });

  final List<JournalTemplate> templates;
  final JournalTemplate? selectedTemplate;

  @override
  List<Object?> get props => [templates, selectedTemplate];

  JournalTemplateLoaded copyWith({
    List<JournalTemplate>? templates,
    JournalTemplate? selectedTemplate,
  }) {
    return JournalTemplateLoaded(
      templates: templates ?? this.templates,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    );
  }
}

/// Error state
class JournalTemplateError extends JournalTemplateState {
  const JournalTemplateError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Template created successfully
class JournalTemplateCreated extends JournalTemplateState {
  const JournalTemplateCreated(this.template);

  final JournalTemplate template;

  @override
  List<Object?> get props => [template];
}

/// Template deleted successfully
class JournalTemplateDeleted extends JournalTemplateState {
  const JournalTemplateDeleted();
}

/// Template used successfully (journal entry created)
class JournalTemplateUsed extends JournalTemplateState {
  const JournalTemplateUsed(this.entryId);

  final String entryId;

  @override
  List<Object?> get props => [entryId];
}
