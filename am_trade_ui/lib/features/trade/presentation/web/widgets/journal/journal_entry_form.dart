import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../internal/domain/entities/journal_entry.dart';
import '../../../../providers/trade_internal_providers.dart';
import '../../../../trade_controller_providers.dart';
import '../../../cubit/journal/journal_cubit.dart';
import '../../../models/trade_holding_view_model.dart';
import 'components/journal_attachment_section.dart';
import 'components/journal_form_actions.dart';
import 'components/journal_trade_section.dart';
import 'sections/behavior_tracking_section.dart';
import 'sections/optional_fields_section.dart';
import 'utils/journal_form_helpers.dart';
import 'utils/journal_helpers.dart';
import 'widgets/rich_text_editor.dart';
import 'widgets/trade_overview_selector.dart';
import 'widgets/trade_preview_dialog.dart';
import 'hover_input_field.dart';

class JournalEntryForm extends ConsumerStatefulWidget {
  const JournalEntryForm({
        required this.cubit,
    required this.portfolioId,
    super.key,
    this.entry,
  });

    final JournalCubit cubit;
  final String portfolioId;
  final JournalEntry? entry;

  @override
  ConsumerState<JournalEntryForm> createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends ConsumerState<JournalEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  late TextEditingController _tradeIdController;
  late TextEditingController _urlController;
  late DateTime _entryDate;

  // Planning phase (pre-market)
  late TextEditingController _planningBehaviorController;
  String? _planningMood;
  String? _planningSentiment;

  // Mid phase (during trading)
  late TextEditingController _midBehaviorController;
  String? _midMood;
  String? _midSentiment;

  // End phase (market close)
  late TextEditingController _endBehaviorController;
  String? _endMood;
  String? _endSentiment;

  final Set<String> _selectedTags = {};
  List<String> _imageUrls = [];
  bool _isSubmitting = false;
  String? _urlPreview;
  bool _isUrlExpanded = false;

  // Trade overview states
  DateTime _tradeOverviewDate = DateTime.now();
  TradePeriodType _tradePeriod = TradePeriodType.daily;
  List<String> _relatedTradeIds = [];
  List<TradeHoldingViewModel> _availableTrades = [];
  bool _isEditMode = false; // View mode by default when editing existing entry

  @override
  void initState() {
    super.initState();

    // Set edit mode: true for new entries, false for existing (view mode)
    _isEditMode = widget.entry == null;

    _titleController = TextEditingController();
    _quillController = quill.QuillController(document: quill.Document(), selection: const TextSelection.collapsed(offset: 0));
    _tradeIdController = TextEditingController();
    _urlController = TextEditingController();
    _planningBehaviorController = TextEditingController();
    _midBehaviorController = TextEditingController();
    _endBehaviorController = TextEditingController();

    _initFormFields();

    _urlController.addListener(_onUrlChanged);

    _urlController.addListener(_onUrlChanged);

    // Load trades for the entry date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTradesForPeriod(_tradeOverviewDate, _tradePeriod);
    });
  }

  void _initFormFields() {
    _titleController.text = widget.entry?.title ?? '';

    final doc = widget.entry?.content != null && widget.entry!.content.isNotEmpty
        ? quill.Document.fromJson(jsonDecode(widget.entry!.content))
        : quill.Document();
    _quillController.document = doc;

    _tradeIdController.text = widget.entry?.tradeId ?? '';
    _entryDate = widget.entry?.entryDate ?? DateTime.now();

    final customFields = widget.entry?.customFields ?? {};
    
    _planningBehaviorController.text = customFields['planningBehavior'] ?? '';
    _planningMood = customFields['planningMood'];
    _planningSentiment = customFields['planningSentiment'];

    _midBehaviorController.text = customFields['midBehavior'] ?? '';
    _midMood = customFields['midMood'];
    _midSentiment = customFields['midSentiment'];

    _endBehaviorController.text = customFields['endBehavior'] ?? '';
    _endMood = customFields['endMood'] ??
        (widget.entry?.behaviorPatternSummaries.isNotEmpty == true
            ? JournalHelpers.mapMoodFromEntry(widget.entry!.behaviorPatternSummaries.first.mood)
            : null);
    _endSentiment = customFields['endSentiment'] ??
        (widget.entry?.behaviorPatternSummaries.isNotEmpty == true
            ? JournalHelpers.mapSentimentFromValue(widget.entry!.behaviorPatternSummaries.first.marketSentiment)
            : null);

    _selectedTags.clear();
    if (widget.entry?.behaviorPatternSummaries.isNotEmpty == true) {
      _selectedTags.addAll(widget.entry!.behaviorPatternSummaries.expand((pattern) => pattern.tags).toSet());
    }

    if (widget.entry?.attachments != null && widget.entry!.attachments.isNotEmpty) {
      _imageUrls = widget.entry!.attachments.map((a) => a.fileUrl).toList();
    } else if (widget.entry?.imageUrls != null) {
      _imageUrls = List.from(widget.entry!.imageUrls!);
    } else {
      _imageUrls = [];
    }

    if (widget.entry?.relatedTradeIds != null) {
      _relatedTradeIds = List.from(widget.entry!.relatedTradeIds!);
    } else {
      _relatedTradeIds = [];
    }

    _tradeOverviewDate = widget.entry?.entryDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _tradeIdController.dispose();
    _urlController.dispose();
    _planningBehaviorController.dispose();
    _midBehaviorController.dispose();
    _endBehaviorController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final text = _urlController.text.trim();
    if (text.isNotEmpty && (text.startsWith('http://') || text.startsWith('https://'))) {
      setState(() => _urlPreview = text);
    } else {
      setState(() => _urlPreview = null);
    }
  }

  Future<void> _loadTradesForPeriod(DateTime date, TradePeriodType period) async {
    try {
      DateTime startDate;
      DateTime endDate;

      switch (period) {
        case TradePeriodType.daily:
          final getTradeCalendarByDay = await ref.read(getTradeCalendarByDayProvider.future);
          final calendar = await getTradeCalendarByDay(widget.portfolioId, date: date);
          final trades = calendar.allTrades;
          if (mounted) {
            setState(() {
              _availableTrades = TradeHoldingViewModel.fromEntityList(trades);
            });
          }
          return;

        case TradePeriodType.weekly:
          startDate = date.subtract(Duration(days: date.weekday - 1));
          endDate = startDate.add(const Duration(days: 6));
          break;

        case TradePeriodType.monthly:
          final getTradeCalendarByMonth = await ref.read(getTradeCalendarByMonthProvider.future);
          final calendar = await getTradeCalendarByMonth(widget.portfolioId, year: date.year,
            month: date.month,
          );
          final trades = calendar.allTrades;
          if (mounted) {
            setState(() {
              _availableTrades = TradeHoldingViewModel.fromEntityList(trades);
            });
          }
          return;

        case TradePeriodType.yearly:
          startDate = DateTime(date.year);
          endDate = DateTime(date.year, 12, 31);
          break;
      }

      // For weekly and yearly, use date range
      final getTradeCalendarByDateRange = await ref.read(getTradeCalendarByDateRangeProvider.future);
      final calendar = await getTradeCalendarByDateRange(
        widget.portfolioId,
        startDate: startDate,
        endDate: endDate,
      );

      final trades = calendar.allTrades;
      if (mounted) {
        setState(() {
          _availableTrades = TradeHoldingViewModel.fromEntityList(trades);
        });
      }
    } catch (e) {
      // Log error silently for debugging if needed but don't leak to console
      // AppLogger.error('Error loading trades for period', error: e);
      if (mounted) {
        setState(() {
          _availableTrades = [];
        });
      }

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trades: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showTradePreview() async {
    // If in view mode with linked trades, load trades by IDs instead of by date
    if (!_isEditMode && _relatedTradeIds.isNotEmpty) {
      // Show loading indicator
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Load trades by their IDs using the trade controller provider
        final tradeDetails = await ref.read(tradeDetailsByIdsProvider(_relatedTradeIds).future);

        // Convert TradeDetails to TradeHoldingViewModel
        final linkedTrades = tradeDetails.map(TradeHoldingViewModel.fromEntity).toList();

        // Close loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show dialog with linked trades
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => TradePreviewDialog(
              date: _tradeOverviewDate,
              trades: linkedTrades,
              selectedTradeIds: _relatedTradeIds,
              periodType: _tradePeriod,
            ),
          );
        }
      } catch (e) {
        // Close loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load linked trades: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      return;
    }

    // Edit mode: show trade selection dialog with available trades
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => TradePreviewDialog(
        date: _tradeOverviewDate,
        trades: _availableTrades,
        selectedTradeIds: _relatedTradeIds,
        periodType: _tradePeriod,
      ),
    );

    if (result != null && _isEditMode) {
      setState(() => _relatedTradeIds = result);
    }
  }

  String _getQuillContent() {
    final delta = _quillController.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final content = _getQuillContent();
        final behaviorPatternSummaries = _buildBehaviorPatternSummaries();

        if (widget.entry == null) {
          await widget.cubit.addJournalEntry(
            title: _titleController.text,
            content: content,
            entryDate: _entryDate,
            tradeId: _tradeIdController.text.isEmpty ? null : _tradeIdController.text,
            behaviorPatternSummaries: behaviorPatternSummaries,
            imageUrls: _imageUrls.isEmpty ? null : _imageUrls,
            attachments: _imageUrls.isEmpty ? null : JournalFormHelpers.convertImageUrlsToAttachments(_imageUrls),
            relatedTradeIds: _relatedTradeIds.isEmpty ? null : _relatedTradeIds,
            customFields: JournalFormHelpers.buildCustomFields(
              planningBehavior: _planningBehaviorController.text,
              planningMood: _planningMood,
              planningSentiment: _planningSentiment,
              midBehavior: _midBehaviorController.text,
              midMood: _midMood,
              midSentiment: _midSentiment,
              endBehavior: _endBehaviorController.text,
              endMood: _endMood,
              endSentiment: _endSentiment,
            ),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Journal entry created successfully'), backgroundColor: Colors.green),
            );
            // Reset form for a new entry
            _titleController.clear();
            _quillController.document = quill.Document();
            _tradeIdController.clear();
            _urlController.clear();
            _planningBehaviorController.clear();
            _midBehaviorController.clear();
            _endBehaviorController.clear();
            setState(() {
              _planningMood = null;
              _planningSentiment = null;
              _midMood = null;
              _midSentiment = null;
              _endMood = null;
              _endSentiment = null;
              _selectedTags.clear();
              _imageUrls = [];
              _relatedTradeIds = [];
              _entryDate = DateTime.now();
            });
          }
        } else {
          await widget.cubit.editJournalEntry(
            entryId: widget.entry!.id,
            title: _titleController.text,
            content: content,
            entryDate: _entryDate,
            tradeId: _tradeIdController.text.isEmpty ? null : _tradeIdController.text,
            behaviorPatternSummaries: behaviorPatternSummaries,
            imageUrls: _imageUrls.isEmpty ? null : _imageUrls,
            attachments: _imageUrls.isEmpty ? null : JournalFormHelpers.convertImageUrlsToAttachments(_imageUrls),
            relatedTradeIds: _relatedTradeIds.isEmpty ? null : _relatedTradeIds,
            customFields: JournalFormHelpers.buildCustomFields(
              planningBehavior: _planningBehaviorController.text,
              planningMood: _planningMood,
              planningSentiment: _planningSentiment,
              midBehavior: _midBehaviorController.text,
              midMood: _midMood,
              midSentiment: _midSentiment,
              endBehavior: _endBehaviorController.text,
              endMood: _endMood,
              endSentiment: _endSentiment,
            ),
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Journal entry updated successfully'), backgroundColor: Colors.green),
            );
            setState(() => _isEditMode = false);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save entry: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  List<BehaviorPatternSummary>? _buildBehaviorPatternSummaries() {
    final summaries = <BehaviorPatternSummary>[];

    // Aggregate all behavior data into one summary
    final hasAnyData =
        _planningBehaviorController.text.isNotEmpty ||
        _midBehaviorController.text.isNotEmpty ||
        _endBehaviorController.text.isNotEmpty ||
        _planningMood != null ||
        _midMood != null ||
        _endMood != null ||
        _planningSentiment != null ||
        _midSentiment != null ||
        _endSentiment != null ||
        _selectedTags.isNotEmpty;

    if (!hasAnyData) return null;

    // Combine behavior summaries from all phases
    final summaryParts = <String>[];
    if (_planningBehaviorController.text.isNotEmpty) {
      summaryParts.add('Planning: ${_planningBehaviorController.text}');
    }
    if (_midBehaviorController.text.isNotEmpty) {
      summaryParts.add('Mid: ${_midBehaviorController.text}');
    }
    if (_endBehaviorController.text.isNotEmpty) {
      summaryParts.add('End: ${_endBehaviorController.text}');
    }

    final summary = summaryParts.isNotEmpty
        ? summaryParts.join(' | ')
        : 'Behavior tracking for ${_titleController.text}';

    // Use the most recent mood/sentiment (end > mid > planning)
    final mood = JournalHelpers.getMoodString(_endMood ?? _midMood ?? _planningMood);
    final sentiment = JournalHelpers.getSentimentValue(_endSentiment ?? _midSentiment ?? _planningSentiment);

    summaries.add(
      BehaviorPatternSummary(summary: summary, mood: mood, marketSentiment: sentiment, tags: _selectedTags.toList()),
    );

    return summaries;
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 650;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildLeftColumn(context)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildRightColumn()),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLeftColumn(context),
                    const SizedBox(height: 24),
                    _buildRightColumn(),
                  ],
                ),
              const SizedBox(height: 24),
              JournalFormActions(
                isEditMode: _isEditMode,
                isSubmitting: _isSubmitting,
                isNewEntry: widget.entry == null,
                onSubmit: _submit,
                onToggleEditMode: () => setState(() => _isEditMode = !_isEditMode),
                onCancel: () {
                  if (widget.entry != null) {
                    _initFormFields(); // Revert to original entry values
                  }
                  setState(() => _isEditMode = false);
                },
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _buildLeftColumn(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTitleField(),
      const SizedBox(height: 12),
      _buildBehaviorTracking(),
      const SizedBox(height: 12),
      RichTextEditor(controller: _quillController, readOnly: !_isEditMode),
    ],
  );

  Widget _buildTitleField() {
    final theme = Theme.of(context);
    return HoverInputField(
      child: TextFormField(
        controller: _titleController,
        enabled: _isEditMode,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _isEditMode ? null : theme.colorScheme.onSurface.withOpacity(0.9),
        ),
        decoration: InputDecoration(
          labelText: 'Title',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          hintText: 'e.g., "AAPL Breakout" or "Lesson: Don\'t Chase"',
          prefixIcon: const Icon(Icons.title, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
    );
  }

  Widget _buildRightColumn() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildOptionalFields(),
      const SizedBox(height: 12),

      // Trade Overview Section - enabled in view mode to allow viewing linked trades
      JournalTradeSection(
        selectedDate: _tradeOverviewDate,
        selectedPeriod: _tradePeriod,
        selectedTradeIds: _relatedTradeIds,
        availableTrades: _availableTrades,
        isEditMode: _isEditMode,
        onDateChanged: (date) {
          setState(() => _tradeOverviewDate = date);
          _loadTradesForPeriod(date, _tradePeriod);
        },
        onPeriodChanged: (period) {
          setState(() => _tradePeriod = period);
          _loadTradesForPeriod(_tradeOverviewDate, period);
        },
        onTradesSelected: (ids) => setState(() => _relatedTradeIds = ids),
        onViewTrades: _showTradePreview,
      ),
      const SizedBox(height: 12),

      // Attachment Section - clickable in view mode for viewing images
      JournalAttachmentSection(
        imageUrls: _imageUrls,
        onAttachmentsChanged: (urls) => setState(() => _imageUrls = urls),
        featureName: 'journal',
        isEditMode: _isEditMode,
      ),
    ],
  );

  Widget _buildOptionalFields() => OptionalFieldsSection(
    entryDate: _entryDate,
    tradeIdController: _tradeIdController,
    urlController: _urlController,
    isEditMode: _isEditMode,
    isUrlExpanded: _isUrlExpanded,
    urlPreview: _urlPreview,
    onDateSelect: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: _entryDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) setState(() => _entryDate = date);
    },
    onToggleUrlExpansion: () => setState(() => _isUrlExpanded = !_isUrlExpanded),
    onClearUrl: () {
      _urlController.clear();
      setState(() => _urlPreview = null);
    },
  );

  Widget _buildBehaviorTracking() => BehaviorTrackingSection(
    planningBehaviorController: _planningBehaviorController,
    planningMood: _planningMood,
    planningSentiment: _planningSentiment,
    midBehaviorController: _midBehaviorController,
    midMood: _midMood,
    midSentiment: _midSentiment,
    endBehaviorController: _endBehaviorController,
    endMood: _endMood,
    endSentiment: _endSentiment,
    onPlanningMoodChanged: (mood) => setState(() => _planningMood = mood),
    onPlanningSentimentChanged: (sentiment) => setState(() => _planningSentiment = sentiment),
    onMidMoodChanged: (mood) => setState(() => _midMood = mood),
    onMidSentimentChanged: (sentiment) => setState(() => _midSentiment = sentiment),
    onEndMoodChanged: (mood) => setState(() => _endMood = mood),
    onEndSentimentChanged: (sentiment) => setState(() => _endSentiment = sentiment),
    selectedTags: _selectedTags,
    onTagToggled: _toggleTag,
    isEditMode: _isEditMode,
  );

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }
}
