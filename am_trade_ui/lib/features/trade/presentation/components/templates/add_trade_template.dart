import 'package:flutter/material.dart';

import 'package:am_common/am_common.dart';
import '../../../internal/domain/entities/trade_controller_entities.dart';
import '../../../internal/domain/enums/broker_types.dart';
import '../../../internal/domain/enums/derivative_types.dart';
import '../../../internal/domain/enums/exchange_types.dart';
import '../../../internal/domain/enums/fundamental_reasons.dart';
import '../../../internal/domain/enums/market_segments.dart';
import '../../../internal/domain/enums/option_types.dart';
import '../../../internal/domain/enums/order_types.dart';
import '../../../internal/domain/enums/psychology_factors.dart';
import '../../../internal/domain/enums/series_types.dart';
import '../../../internal/domain/enums/technical_reasons.dart';
import '../../../internal/domain/enums/trade_directions.dart';
import '../../../internal/domain/enums/trade_statuses.dart';
import '../../add_trade/widgets/trade_attachment_section.dart';

/// Modern, responsive template for adding new trades
/// Features:
/// - Multi-step form with smart validation
/// - Conditional fields based on instrument type
/// - Auto-save draft functionality
/// - Responsive layout (desktop/tablet/mobile)
/// - Smart defaults and suggestions
class AddTradeTemplate extends StatefulWidget {
  const AddTradeTemplate({
    required this.portfolioId,
    required this.onSave,
    required this.userId,
    super.key,
    this.onCancel,
    this.initialData,
    this.isLoading = false,
  });

  final String portfolioId;
  final String userId;
  final Function(TradeDetails) onSave;
  final VoidCallback? onCancel;
  final TradeDetails? initialData;
  final bool isLoading;

  @override
  State<AddTradeTemplate> createState() => _AddTradeTemplateState();
}

class _AddTradeTemplateState extends State<AddTradeTemplate> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Form controllers and state
  late final TextEditingController _symbolController;
  late final TextEditingController _isinController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _entryPriceController;
  late final TextEditingController _entryQuantityController;
  late final TextEditingController _exitPriceController;
  late final TextEditingController _exitQuantityController;
  late final TextEditingController _strikePriceController;
  late final TextEditingController _strategyController;
  late final TextEditingController _notesController;
  late final TextEditingController _psychologyNotesController;

  // Dropdown selections
  ExchangeTypes? _selectedExchange;
  MarketSegments? _selectedSegment;
  SeriesTypes? _selectedSeries;
  TradeDirections _selectedDirection = TradeDirections.long;
  TradeStatuses _selectedStatus = TradeStatuses.open;
  BrokerTypes? _selectedBroker;
  DerivativeTypes? _selectedDerivativeType;
  OptionTypes? _selectedOptionType;
  OrderTypes? _selectedOrderType;

  // Date selections
  DateTime? _entryDate;
  DateTime? _exitDate;
  DateTime? _expiryDate;

  // Multi-select enums
  final List<EntryPsychologyFactors> _selectedEntryPsychology = [];
  final List<ExitPsychologyFactors> _selectedExitPsychology = [];
  final List<BehaviorPatterns> _selectedBehaviorPatterns = [];
  final List<TechnicalReasons> _selectedTechnicalReasons = [];
  final List<FundamentalReasons> _selectedFundamentalReasons = [];

  // Tags
  final List<String> _tags = [];

  // Attachments
  final List<String> _attachmentUrls = [];

  @override
  void initState() {
    super.initState();
    AppLogger.info(
      '[AddTradeTemplate] Template initialized - portfolioId: ${widget.portfolioId}, userId: ${widget.userId}, hasInitialData: ${widget.initialData != null}',
      tag: 'AddTradeTemplate',
    );
    _initControllers();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _initControllers() {
    _symbolController = TextEditingController();
    _isinController = TextEditingController();
    _descriptionController = TextEditingController();
    _entryPriceController = TextEditingController();
    _entryQuantityController = TextEditingController();
    _exitPriceController = TextEditingController();
    _exitQuantityController = TextEditingController();
    _strikePriceController = TextEditingController();
    _strategyController = TextEditingController();
    _notesController = TextEditingController();
    _psychologyNotesController = TextEditingController();
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _symbolController.text = data.symbol ?? '';
    _descriptionController.text = data.instrumentInfo.description ?? '';
    _selectedExchange = data.instrumentInfo.exchange;
    _selectedSegment = data.instrumentInfo.segment;
    _selectedDirection = data.tradePositionType;
    _selectedStatus = data.status;
    // Load more fields as needed
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _isinController.dispose();
    _descriptionController.dispose();
    _entryPriceController.dispose();
    _entryQuantityController.dispose();
    _exitPriceController.dispose();
    _exitQuantityController.dispose();
    _strikePriceController.dispose();
    _strategyController.dispose();
    _notesController.dispose();
    _psychologyNotesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _saveTrade() {
    if (_formKey.currentState!.validate()) {
      final tradeDetails = _buildTradeDetails();
      widget.onSave(tradeDetails);
    }
  }

  TradeDetails _buildTradeDetails() {
    final instrumentInfo = InstrumentInfo(
      symbol: _symbolController.text.trim(),
      isin: _isinController.text.trim().isEmpty ? null : _isinController.text.trim(),
      exchange: _selectedExchange,
      segment: _selectedSegment,
      series: _selectedSeries,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      derivativeInfo: _selectedDerivativeType != null
          ? DerivativeInfo(
              derivativeType: _selectedDerivativeType,
              strikePrice: _strikePriceController.text.isEmpty ? null : double.tryParse(_strikePriceController.text),
              expiryDate: _expiryDate,
              optionType: _selectedOptionType,
            )
          : null,
    );

    final entryInfo = EntryExitInfo(
      timestamp: _entryDate ?? DateTime.now(),
      price: double.tryParse(_entryPriceController.text),
      quantity: int.tryParse(_entryQuantityController.text),
    );

    final exitInfo = _selectedStatus != TradeStatuses.open && _exitDate != null
        ? EntryExitInfo(
            timestamp: _exitDate,
            price: double.tryParse(_exitPriceController.text),
            quantity: int.tryParse(_exitQuantityController.text),
          )
        : null;

    final psychologyData = TradePsychologyData(
      entryPsychologyFactors: _selectedEntryPsychology.isEmpty ? null : _selectedEntryPsychology,
      exitPsychologyFactors: _selectedExitPsychology.isEmpty ? null : _selectedExitPsychology,
      behaviorPatterns: _selectedBehaviorPatterns.isEmpty ? null : _selectedBehaviorPatterns,
      psychologyNotes: _psychologyNotesController.text.trim().isEmpty ? null : _psychologyNotesController.text.trim(),
    );

    final reasoning = TradeEntryExitReasoning(
      technicalReasons: _selectedTechnicalReasons.isEmpty ? null : _selectedTechnicalReasons,
      fundamentalReasons: _selectedFundamentalReasons.isEmpty ? null : _selectedFundamentalReasons,
    );

    return TradeDetails(
      tradeId: '', // Will be generated by backend
      portfolioId: widget.portfolioId,
      instrumentInfo: instrumentInfo,
      status: _selectedStatus,
      tradePositionType: _selectedDirection,
      entryInfo: entryInfo,
      symbol: _symbolController.text.trim(),
      strategy: _strategyController.text.trim().isEmpty ? null : _strategyController.text.trim(),
      exitInfo: exitInfo,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      tags: _tags.isEmpty ? null : _tags,
      psychologyData: psychologyData,
      entryReasoning: reasoning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 800 && screenWidth < 1200;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.surface, theme.colorScheme.surface.withOpacity(0.95)],
        ),
      ),
      child: Column(
        children: [
          // Header with progress indicator
          _buildHeader(theme, isDesktop),

          // Progress stepper
          _buildProgressStepper(theme, isDesktop),

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildInstrumentStep(theme, isDesktop, isTablet),
                  _buildEntryDetailsStep(theme, isDesktop, isTablet),
                  _buildExitDetailsStep(theme, isDesktop, isTablet),
                  _buildPsychologyStep(theme, isDesktop, isTablet),
                  _buildReasoningStep(theme, isDesktop, isTablet),
                  _buildReviewStep(theme, isDesktop, isTablet),
                ],
              ),
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(theme, isDesktop),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDesktop) {
    AppLogger.debug(
      '[AddTradeTemplate] Building header - isDesktop: $isDesktop, currentStep: $_currentStep/$_totalSteps',
      tag: 'AddTradeTemplate',
    );
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          // Back button only
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onCancel,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 18, color: theme.colorScheme.onSurface),
                      const SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStepper(ThemeData theme, bool isDesktop) => Container(
    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 16),
    child: Row(
      children: List.generate(_totalSteps, (index) {
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;
        final stepLabels = ['Instrument', 'Entry', 'Exit', 'Psychology', 'Reasoning', 'Review'];

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 20)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurrent ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(height: 8),
                      Text(
                        stepLabels[index],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (index < _totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
        );
      }),
    ),
  );

  Widget _buildInstrumentStep(ThemeData theme, bool isDesktop, bool isTablet) => SingleChildScrollView(
    padding: EdgeInsets.all(isDesktop ? 24 : 16),
    child: _buildResponsiveCard(
      theme,
      isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Instrument Information', Icons.assessment),
          const SizedBox(height: 24),
          _buildResponsiveGrid(
            isDesktop,
            isTablet,
            children: [
              _buildTextField(
                controller: _symbolController,
                label: 'Symbol *',
                hint: 'e.g., RELIANCE, NIFTY',
                icon: Icons.local_offer,
                validator: (value) => value?.isEmpty ?? true ? 'Symbol is required' : null,
              ),
              _buildTextField(
                controller: _isinController,
                label: 'ISIN',
                hint: 'e.g., INE002A01018',
                icon: Icons.fingerprint,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResponsiveGrid(
            isDesktop,
            isTablet,
            children: [
              _buildDropdownField<ExchangeTypes>(
                value: _selectedExchange,
                label: 'Exchange *',
                hint: 'Select exchange',
                icon: Icons.business,
                items: ExchangeTypes.values,
                onChanged: (value) => setState(() => _selectedExchange = value),
                itemBuilder: (type) => type.toString().split('.').last.toUpperCase(),
              ),
              _buildDropdownField<MarketSegments>(
                value: _selectedSegment,
                label: 'Segment',
                hint: 'Select segment',
                icon: Icons.category,
                items: MarketSegments.values,
                onChanged: (value) => setState(() => _selectedSegment = value),
                itemBuilder: (type) => type.toString().split('.').last.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResponsiveGrid(
            isDesktop,
            isTablet,
            children: [
              _buildDropdownField<SeriesTypes>(
                value: _selectedSeries,
                label: 'Series',
                hint: 'Select series',
                icon: Icons.layers,
                items: SeriesTypes.values,
                onChanged: (value) => setState(() => _selectedSeries = value),
                itemBuilder: (type) => type.toString().split('.').last.toUpperCase(),
              ),
              _buildDropdownField<DerivativeTypes>(
                value: _selectedDerivativeType,
                label: 'Derivative Type',
                hint: 'Select if derivative',
                icon: Icons.analytics,
                items: DerivativeTypes.values,
                onChanged: (value) => setState(() => _selectedDerivativeType = value),
                itemBuilder: (type) => type.toString().split('.').last.toUpperCase(),
              ),
            ],
          ),
          if (_selectedDerivativeType != null) ...[
            const SizedBox(height: 16),
            _buildResponsiveGrid(
              isDesktop,
              isTablet,
              children: [
                _buildTextField(
                  controller: _strikePriceController,
                  label: 'Strike Price',
                  hint: 'e.g., 2500.00',
                  icon: Icons.gavel,
                  keyboardType: TextInputType.number,
                ),
                _buildDropdownField<OptionTypes>(
                  value: _selectedOptionType,
                  label: 'Option Type',
                  hint: 'Call or Put',
                  icon: Icons.compare_arrows,
                  items: OptionTypes.values,
                  onChanged: (value) => setState(() => _selectedOptionType = value),
                  itemBuilder: (type) => type.toString().split('.').last.toUpperCase(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDateField(
              context: context,
              label: 'Expiry Date',
              hint: 'Select expiry',
              icon: Icons.calendar_today,
              selectedDate: _expiryDate,
              onDateSelected: (date) => setState(() => _expiryDate = date),
            ),
          ],
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Additional details about the instrument',
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              AppLogger.debug(
                '[AddTradeTemplate] Building TradeAttachmentSection - current attachments: ${_attachmentUrls.length}',
                tag: 'AddTradeTemplate',
              );
              return TradeAttachmentSection(
                imageUrls: _attachmentUrls,
                onAttachmentsChanged: (urls) {
                  AppLogger.info(
                    '[AddTradeTemplate] Attachments changed - previous: ${_attachmentUrls.length}, new: ${urls.length}',
                    tag: 'AddTradeTemplate',
                  );
                  setState(() {
                    _attachmentUrls.clear();
                    _attachmentUrls.addAll(urls);
                  });
                },
                userId: widget.userId,
                isEditMode: true,
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildEntryDetailsStep(ThemeData theme, bool isDesktop, bool isTablet) => SingleChildScrollView(
    padding: EdgeInsets.all(isDesktop ? 24 : 16),
    child: _buildResponsiveCard(
      theme,
      isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Entry Details', Icons.login),
          const SizedBox(height: 24),
          _buildResponsiveGrid(
            isDesktop,
            isTablet,
            children: [
              _buildDropdownField<TradeDirections>(
                value: _selectedDirection,
                label: 'Direction *',
                hint: 'Long or Short',
                icon: Icons.trending_up,
                items: TradeDirections.values,
                onChanged: (value) => setState(() => _selectedDirection = value!),
                itemBuilder: (type) => type.toString().split('.').last.toUpperCase(),
              ),
              _buildDropdownField<TradeStatuses>(
                value: _selectedStatus,
                label: 'Status *',
                hint: 'Open or Closed',
                icon: Icons.flag,
                items: TradeStatuses.values,
                onChanged: (value) => setState(() => _selectedStatus = value!),
                itemBuilder: (type) => type.toString().split('.').last.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDateField(
            context: context,
            label: 'Entry Date *',
            hint: 'Select entry date',
            icon: Icons.event,
            selectedDate: _entryDate,
            onDateSelected: (date) => setState(() => _entryDate = date),
            validator: _entryDate == null ? 'Entry date is required' : null,
          ),
          const SizedBox(height: 16),
          _buildResponsiveGrid(
            isDesktop,
            isTablet,
            children: [
              _buildTextField(
                controller: _entryPriceController,
                label: 'Entry Price *',
                hint: 'e.g., 2450.50',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Entry price is required' : null,
              ),
              _buildTextField(
                controller: _entryQuantityController,
                label: 'Quantity *',
                hint: 'e.g., 100',
                icon: Icons.tag,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Quantity is required' : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResponsiveGrid(
            isDesktop,
            isTablet,
            children: [
              _buildDropdownField<BrokerTypes>(
                value: _selectedBroker,
                label: 'Broker',
                hint: 'Select broker',
                icon: Icons.account_balance,
                items: BrokerTypes.values,
                onChanged: (value) => setState(() => _selectedBroker = value),
                itemBuilder: (type) => type.toString().split('.').last.toUpperCase(),
              ),
              _buildDropdownField<OrderTypes>(
                value: _selectedOrderType,
                label: 'Order Type',
                hint: 'Market/Limit/etc.',
                icon: Icons.receipt,
                items: OrderTypes.values,
                onChanged: (value) => setState(() => _selectedOrderType = value),
                itemBuilder: (type) => type.toString().split('.').last.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _strategyController,
            label: 'Strategy',
            hint: 'e.g., Swing Trading, Scalping',
            icon: Icons.psychology,
          ),
        ],
      ),
    ),
  );

  Widget _buildExitDetailsStep(ThemeData theme, bool isDesktop, bool isTablet) => SingleChildScrollView(
    padding: EdgeInsets.all(isDesktop ? 24 : 16),
    child: _buildResponsiveCard(
      theme,
      isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Exit Details', Icons.logout),
          const SizedBox(height: 24),
          if (_selectedStatus == TradeStatuses.open)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Exit details are optional for open trades. You can add them later when you close the position.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _buildDateField(
              context: context,
              label: 'Exit Date',
              hint: 'Select exit date',
              icon: Icons.event,
              selectedDate: _exitDate,
              onDateSelected: (date) => setState(() => _exitDate = date),
            ),
            const SizedBox(height: 16),
            _buildResponsiveGrid(
              isDesktop,
              isTablet,
              children: [
                _buildTextField(
                  controller: _exitPriceController,
                  label: 'Exit Price',
                  hint: 'e.g., 2550.00',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _exitQuantityController,
                  label: 'Exit Quantity',
                  hint: 'e.g., 100',
                  icon: Icons.tag,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildPsychologyStep(ThemeData theme, bool isDesktop, bool isTablet) => SingleChildScrollView(
    padding: EdgeInsets.all(isDesktop ? 24 : 16),
    child: _buildResponsiveCard(
      theme,
      isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Psychology & Behavior', Icons.psychology_outlined),
          const SizedBox(height: 24),
          _buildMultiSelectChips<EntryPsychologyFactors>(
            theme,
            'Entry Psychology',
            EntryPsychologyFactors.values,
            _selectedEntryPsychology,
            (factor) => factor.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
          ),
          const SizedBox(height: 24),
          _buildMultiSelectChips<ExitPsychologyFactors>(
            theme,
            'Exit Psychology',
            ExitPsychologyFactors.values,
            _selectedExitPsychology,
            (factor) => factor.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
          ),
          const SizedBox(height: 24),
          _buildMultiSelectChips<BehaviorPatterns>(
            theme,
            'Behavior Patterns',
            BehaviorPatterns.values,
            _selectedBehaviorPatterns,
            (pattern) => pattern.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _psychologyNotesController,
            label: 'Psychology Notes',
            hint: 'Describe your mental state, emotions, and thought process',
            icon: Icons.notes,
            maxLines: 5,
          ),
        ],
      ),
    ),
  );

  Widget _buildReasoningStep(ThemeData theme, bool isDesktop, bool isTablet) => SingleChildScrollView(
    padding: EdgeInsets.all(isDesktop ? 24 : 16),
    child: _buildResponsiveCard(
      theme,
      isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Trade Reasoning', Icons.lightbulb_outline),
          const SizedBox(height: 24),
          _buildMultiSelectChips<TechnicalReasons>(
            theme,
            'Technical Reasons',
            TechnicalReasons.values,
            _selectedTechnicalReasons,
            (reason) => reason.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
          ),
          const SizedBox(height: 24),
          _buildMultiSelectChips<FundamentalReasons>(
            theme,
            'Fundamental Reasons',
            FundamentalReasons.values,
            _selectedFundamentalReasons,
            (reason) => reason.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
          ),
        ],
      ),
    ),
  );

  Widget _buildReviewStep(ThemeData theme, bool isDesktop, bool isTablet) => SingleChildScrollView(
    padding: EdgeInsets.all(isDesktop ? 24 : 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primaryContainer.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.check_circle_outline, color: theme.colorScheme.onPrimary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Your Trade',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please review all details before submitting',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Responsive layout
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: [
                    _buildModernReviewCard(theme, 'Instrument Details', Icons.assessment, [
                      _buildDetailRow(theme, 'Symbol', _symbolController.text, Icons.local_offer),
                      if (_isinController.text.isNotEmpty)
                        _buildDetailRow(theme, 'ISIN', _isinController.text, Icons.fingerprint),
                      if (_selectedExchange != null)
                        _buildDetailRow(
                          theme,
                          'Exchange',
                          _selectedExchange.toString().split('.').last.toUpperCase(),
                          Icons.business,
                        ),
                      if (_selectedSegment != null)
                        _buildDetailRow(
                          theme,
                          'Segment',
                          _selectedSegment.toString().split('.').last.toUpperCase(),
                          Icons.category,
                        ),
                      if (_selectedSeries != null)
                        _buildDetailRow(
                          theme,
                          'Series',
                          _selectedSeries.toString().split('.').last.toUpperCase(),
                          Icons.layers,
                        ),
                      if (_descriptionController.text.isNotEmpty)
                        _buildDetailRow(theme, 'Description', _descriptionController.text, Icons.description),
                    ]),
                    if (_selectedDerivativeType != null) ...[
                      const SizedBox(height: 16),
                      _buildModernReviewCard(theme, 'Derivative Info', Icons.analytics, [
                        _buildDetailRow(
                          theme,
                          'Type',
                          _selectedDerivativeType.toString().split('.').last.toUpperCase(),
                          Icons.category,
                        ),
                        if (_strikePriceController.text.isNotEmpty)
                          _buildDetailRow(theme, 'Strike Price', _strikePriceController.text, Icons.gavel),
                        if (_selectedOptionType != null)
                          _buildDetailRow(
                            theme,
                            'Option Type',
                            _selectedOptionType.toString().split('.').last.toUpperCase(),
                            Icons.compare_arrows,
                          ),
                        if (_expiryDate != null)
                          _buildDetailRow(
                            theme,
                            'Expiry',
                            _expiryDate!.toLocal().toString().split(' ')[0],
                            Icons.calendar_today,
                          ),
                      ]),
                    ],
                    const SizedBox(height: 16),
                    _buildModernReviewCard(theme, 'Entry Details', Icons.login, [
                      _buildDetailRow(
                        theme,
                        'Direction',
                        _selectedDirection.toString().split('.').last.toUpperCase(),
                        Icons.trending_up,
                      ),
                      _buildDetailRow(
                        theme,
                        'Status',
                        _selectedStatus.toString().split('.').last.toUpperCase(),
                        Icons.flag,
                      ),
                      if (_entryDate != null)
                        _buildDetailRow(
                          theme,
                          'Entry Date',
                          _entryDate!.toLocal().toString().split(' ')[0],
                          Icons.event,
                        ),
                      _buildDetailRow(theme, 'Entry Price', '₹${_entryPriceController.text}', Icons.currency_rupee),
                      _buildDetailRow(theme, 'Quantity', _entryQuantityController.text, Icons.tag),
                      if (_selectedBroker != null)
                        _buildDetailRow(
                          theme,
                          'Broker',
                          _selectedBroker.toString().split('.').last.toUpperCase(),
                          Icons.account_balance,
                        ),
                      if (_selectedOrderType != null)
                        _buildDetailRow(
                          theme,
                          'Order Type',
                          _selectedOrderType.toString().split('.').last.toUpperCase(),
                          Icons.receipt,
                        ),
                      if (_strategyController.text.isNotEmpty)
                        _buildDetailRow(theme, 'Strategy', _strategyController.text, Icons.psychology),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right column
              Expanded(
                child: Column(
                  children: [
                    if (_selectedStatus != TradeStatuses.open && _exitDate != null)
                      _buildModernReviewCard(theme, 'Exit Details', Icons.logout, [
                        if (_exitDate != null)
                          _buildDetailRow(
                            theme,
                            'Exit Date',
                            _exitDate!.toLocal().toString().split(' ')[0],
                            Icons.event,
                          ),
                        if (_exitPriceController.text.isNotEmpty)
                          _buildDetailRow(theme, 'Exit Price', '₹${_exitPriceController.text}', Icons.currency_rupee),
                        if (_exitQuantityController.text.isNotEmpty)
                          _buildDetailRow(theme, 'Exit Quantity', _exitQuantityController.text, Icons.tag),
                      ]),
                    if (_selectedStatus != TradeStatuses.open && _exitDate != null) const SizedBox(height: 16),
                    if (_selectedEntryPsychology.isNotEmpty ||
                        _selectedExitPsychology.isNotEmpty ||
                        _selectedBehaviorPatterns.isNotEmpty)
                      _buildModernReviewCard(theme, 'Psychology & Behavior', Icons.psychology_outlined, [
                        if (_selectedEntryPsychology.isNotEmpty)
                          _buildChipDetailRow(
                            theme,
                            'Entry Psychology',
                            _selectedEntryPsychology
                                .map((e) => e.toString().split('.').last.replaceAll('_', ' '))
                                .toList(),
                          ),
                        if (_selectedExitPsychology.isNotEmpty)
                          _buildChipDetailRow(
                            theme,
                            'Exit Psychology',
                            _selectedExitPsychology
                                .map((e) => e.toString().split('.').last.replaceAll('_', ' '))
                                .toList(),
                          ),
                        if (_selectedBehaviorPatterns.isNotEmpty)
                          _buildChipDetailRow(
                            theme,
                            'Behavior Patterns',
                            _selectedBehaviorPatterns
                                .map((e) => e.toString().split('.').last.replaceAll('_', ' '))
                                .toList(),
                          ),
                        if (_psychologyNotesController.text.isNotEmpty)
                          _buildDetailRow(theme, 'Psychology Notes', _psychologyNotesController.text, Icons.notes),
                      ]),
                    if (_selectedEntryPsychology.isNotEmpty ||
                        _selectedExitPsychology.isNotEmpty ||
                        _selectedBehaviorPatterns.isNotEmpty)
                      const SizedBox(height: 16),
                    if (_selectedTechnicalReasons.isNotEmpty || _selectedFundamentalReasons.isNotEmpty)
                      _buildModernReviewCard(theme, 'Trade Reasoning', Icons.lightbulb_outline, [
                        if (_selectedTechnicalReasons.isNotEmpty)
                          _buildChipDetailRow(
                            theme,
                            'Technical Reasons',
                            _selectedTechnicalReasons
                                .map((e) => e.toString().split('.').last.replaceAll('_', ' '))
                                .toList(),
                          ),
                        if (_selectedFundamentalReasons.isNotEmpty)
                          _buildChipDetailRow(
                            theme,
                            'Fundamental Reasons',
                            _selectedFundamentalReasons
                                .map((e) => e.toString().split('.').last.replaceAll('_', ' '))
                                .toList(),
                          ),
                      ]),
                  ],
                ),
              ),
            ],
          )
        else
          // Mobile/Tablet layout - single column
          Column(
            children: [
              _buildModernReviewCard(theme, 'Instrument Details', Icons.assessment, [
                _buildDetailRow(theme, 'Symbol', _symbolController.text, Icons.local_offer),
                if (_isinController.text.isNotEmpty)
                  _buildDetailRow(theme, 'ISIN', _isinController.text, Icons.fingerprint),
                if (_selectedExchange != null)
                  _buildDetailRow(
                    theme,
                    'Exchange',
                    _selectedExchange.toString().split('.').last.toUpperCase(),
                    Icons.business,
                  ),
                if (_selectedSegment != null)
                  _buildDetailRow(
                    theme,
                    'Segment',
                    _selectedSegment.toString().split('.').last.toUpperCase(),
                    Icons.category,
                  ),
                if (_selectedSeries != null)
                  _buildDetailRow(
                    theme,
                    'Series',
                    _selectedSeries.toString().split('.').last.toUpperCase(),
                    Icons.layers,
                  ),
                if (_descriptionController.text.isNotEmpty)
                  _buildDetailRow(theme, 'Description', _descriptionController.text, Icons.description),
              ]),
              if (_selectedDerivativeType != null) ...[
                const SizedBox(height: 16),
                _buildModernReviewCard(theme, 'Derivative Info', Icons.analytics, [
                  _buildDetailRow(
                    theme,
                    'Type',
                    _selectedDerivativeType.toString().split('.').last.toUpperCase(),
                    Icons.category,
                  ),
                  if (_strikePriceController.text.isNotEmpty)
                    _buildDetailRow(theme, 'Strike Price', _strikePriceController.text, Icons.gavel),
                  if (_selectedOptionType != null)
                    _buildDetailRow(
                      theme,
                      'Option Type',
                      _selectedOptionType.toString().split('.').last.toUpperCase(),
                      Icons.compare_arrows,
                    ),
                  if (_expiryDate != null)
                    _buildDetailRow(
                      theme,
                      'Expiry',
                      _expiryDate!.toLocal().toString().split(' ')[0],
                      Icons.calendar_today,
                    ),
                ]),
              ],
              const SizedBox(height: 16),
              _buildModernReviewCard(theme, 'Entry Details', Icons.login, [
                _buildDetailRow(
                  theme,
                  'Direction',
                  _selectedDirection.toString().split('.').last.toUpperCase(),
                  Icons.trending_up,
                ),
                _buildDetailRow(theme, 'Status', _selectedStatus.toString().split('.').last.toUpperCase(), Icons.flag),
                if (_entryDate != null)
                  _buildDetailRow(theme, 'Entry Date', _entryDate!.toLocal().toString().split(' ')[0], Icons.event),
                _buildDetailRow(theme, 'Entry Price', '₹${_entryPriceController.text}', Icons.currency_rupee),
                _buildDetailRow(theme, 'Quantity', _entryQuantityController.text, Icons.tag),
                if (_selectedBroker != null)
                  _buildDetailRow(
                    theme,
                    'Broker',
                    _selectedBroker.toString().split('.').last.toUpperCase(),
                    Icons.account_balance,
                  ),
                if (_selectedOrderType != null)
                  _buildDetailRow(
                    theme,
                    'Order Type',
                    _selectedOrderType.toString().split('.').last.toUpperCase(),
                    Icons.receipt,
                  ),
                if (_strategyController.text.isNotEmpty)
                  _buildDetailRow(theme, 'Strategy', _strategyController.text, Icons.psychology),
              ]),
              if (_selectedStatus != TradeStatuses.open && _exitDate != null) ...[
                const SizedBox(height: 16),
                _buildModernReviewCard(theme, 'Exit Details', Icons.logout, [
                  if (_exitDate != null)
                    _buildDetailRow(theme, 'Exit Date', _exitDate!.toLocal().toString().split(' ')[0], Icons.event),
                  if (_exitPriceController.text.isNotEmpty)
                    _buildDetailRow(theme, 'Exit Price', '₹${_exitPriceController.text}', Icons.currency_rupee),
                  if (_exitQuantityController.text.isNotEmpty)
                    _buildDetailRow(theme, 'Exit Quantity', _exitQuantityController.text, Icons.tag),
                ]),
              ],
              if (_selectedEntryPsychology.isNotEmpty ||
                  _selectedExitPsychology.isNotEmpty ||
                  _selectedBehaviorPatterns.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildModernReviewCard(theme, 'Psychology & Behavior', Icons.psychology_outlined, [
                  if (_selectedEntryPsychology.isNotEmpty)
                    _buildChipDetailRow(
                      theme,
                      'Entry Psychology',
                      _selectedEntryPsychology.map((e) => e.toString().split('.').last.replaceAll('_', ' ')).toList(),
                    ),
                  if (_selectedExitPsychology.isNotEmpty)
                    _buildChipDetailRow(
                      theme,
                      'Exit Psychology',
                      _selectedExitPsychology.map((e) => e.toString().split('.').last.replaceAll('_', ' ')).toList(),
                    ),
                  if (_selectedBehaviorPatterns.isNotEmpty)
                    _buildChipDetailRow(
                      theme,
                      'Behavior Patterns',
                      _selectedBehaviorPatterns.map((e) => e.toString().split('.').last.replaceAll('_', ' ')).toList(),
                    ),
                  if (_psychologyNotesController.text.isNotEmpty)
                    _buildDetailRow(theme, 'Psychology Notes', _psychologyNotesController.text, Icons.notes),
                ]),
              ],
              if (_selectedTechnicalReasons.isNotEmpty || _selectedFundamentalReasons.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildModernReviewCard(theme, 'Trade Reasoning', Icons.lightbulb_outline, [
                  if (_selectedTechnicalReasons.isNotEmpty)
                    _buildChipDetailRow(
                      theme,
                      'Technical Reasons',
                      _selectedTechnicalReasons.map((e) => e.toString().split('.').last.replaceAll('_', ' ')).toList(),
                    ),
                  if (_selectedFundamentalReasons.isNotEmpty)
                    _buildChipDetailRow(
                      theme,
                      'Fundamental Reasons',
                      _selectedFundamentalReasons
                          .map((e) => e.toString().split('.').last.replaceAll('_', ' '))
                          .toList(),
                    ),
                ]),
              ],
            ],
          ),

        // Additional Notes
        const SizedBox(height: 24),
        _buildTextField(
          controller: _notesController,
          label: 'Additional Notes',
          hint: 'Any other information about this trade',
          icon: Icons.note_add,
          maxLines: 5,
        ),
      ],
    ),
  );

  Widget _buildResponsiveCard(ThemeData theme, bool isDesktop, {required Widget child}) => Container(
    constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
    margin: isDesktop ? const EdgeInsets.symmetric(horizontal: 40) : EdgeInsets.zero,
    padding: EdgeInsets.all(isDesktop ? 32 : 20),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
      ),
    ],
  );

  Widget _buildResponsiveGrid(bool isDesktop, bool isTablet, {required List<Widget> children}) {
    final columns = isDesktop ? 2 : (isTablet ? 2 : 1);

    if (columns == 1) {
      return Column(
        children: children.map((child) => Padding(padding: const EdgeInsets.only(bottom: 16), child: child)).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        columns,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 0 ? 16 : 0),
            child: index < children.length ? children[index] : const SizedBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
    ),
  );

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemBuilder,
  }) => DropdownButtonFormField<T>(
    value: value,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
    ),
    items: items.map((item) => DropdownMenuItem(value: item, child: Text(itemBuilder(item)))).toList(),
    onChanged: onChanged,
  );

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    required DateTime? selectedDate,
    required void Function(DateTime) onDateSelected,
    String? validator,
  }) => InkWell(
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        onDateSelected(date);
      }
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        errorText: validator,
      ),
      child: Text(
        selectedDate != null ? selectedDate.toLocal().toString().split(' ')[0] : hint,
        style: TextStyle(color: selectedDate != null ? null : Colors.grey),
      ),
    ),
  );

  Widget _buildMultiSelectChips<T>(
    ThemeData theme,
    String label,
    List<T> items,
    List<T> selectedItems,
    String Function(T) itemBuilder,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final isSelected = selectedItems.contains(item);
          return FilterChip(
            label: Text(itemBuilder(item)),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  selectedItems.add(item);
                } else {
                  selectedItems.remove(item);
                }
              });
            },
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.primary,
          );
        }).toList(),
      ),
    ],
  );

  Widget _buildNavigationButtons(ThemeData theme, bool isDesktop) => Container(
    padding: EdgeInsets.all(isDesktop ? 24 : 16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: widget.isLoading ? null : _previousStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          )
        else
          const SizedBox(),
        Row(
          children: [
            if (widget.onCancel != null)
              TextButton(onPressed: widget.isLoading ? null : widget.onCancel, child: const Text('Cancel')),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: widget.isLoading
                  ? null
                  : _currentStep == _totalSteps - 1
                  ? _saveTrade
                  : _nextStep,
              icon: widget.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_currentStep == _totalSteps - 1 ? Icons.save : Icons.arrow_forward),
              label: Text(_currentStep == _totalSteps - 1 ? 'Save Trade' : 'Next'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            ),
          ],
        ),
      ],
    ),
  );

  // Helper methods for review step
  Widget _buildModernReviewCard(ThemeData theme, String title, IconData icon, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: theme.colorScheme.onPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
        // Card content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    ),
  );

  Widget _buildDetailRow(ThemeData theme, String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildChipDetailRow(ThemeData theme, String label, List<String> items) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, size: 18, color: theme.colorScheme.primary.withOpacity(0.7)),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                  ),
                  child: Text(
                    item,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

