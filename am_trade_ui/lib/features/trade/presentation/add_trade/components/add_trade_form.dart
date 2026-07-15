import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import '../../../internal/domain/entities/trade_controller_entities.dart';
import '../../../internal/domain/enums/broker_types.dart';
import '../../../internal/domain/enums/derivative_types.dart';
import '../../../internal/domain/enums/exchange_types.dart';
import '../../../internal/domain/enums/fundamental_reasons.dart';
import '../../../internal/domain/enums/market_segments.dart';
import '../../../internal/domain/enums/option_types.dart';
import '../../../internal/domain/enums/order_types.dart';
import '../../../internal/domain/enums/psychology_factors.dart';
import '../../../internal/domain/enums/technical_reasons.dart';
import '../../../internal/domain/enums/trade_directions.dart';
import '../../../internal/domain/enums/trade_statuses.dart';
import '../mappers/trade_form_mapper.dart';
import '../steps/optional_details_step.dart';
import '../steps/review_step.dart';
// Modular step components
import '../steps/trade_details_step.dart';
import '../validators/trade_form_validator.dart';

/// Modular 3-step Add Trade Form
/// Step 1: Trade Details (instrument + entry/exit combined)
/// Step 2: Optional Details (psychology, reasoning, strategy - OPTIONAL)
/// Step 3: Review & Submit
class AddTradeForm extends StatefulWidget {
  const AddTradeForm({super.key, this.onCancel, this.onSave, this.isLoading = false, this.initialData});
  final VoidCallback? onCancel;
  final Function(TradeDetails)? onSave;
  final bool isLoading;
  final TradeDetails? initialData;

  @override
  State<AddTradeForm> createState() => _AddTradeFormState();
}

class _AddTradeFormState extends State<AddTradeForm> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Combined Trade Details
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _isinController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  ExchangeTypes? _selectedExchange;
  MarketSegments? _selectedSegment;
  DerivativeTypes? _selectedDerivativeType;
  OptionTypes? _selectedOptionType;
  final TextEditingController _strikePriceController = TextEditingController();
  DateTime? _expiryDate;

  // Entry & Exit (same step)
  TradeDirections _selectedDirection = TradeDirections.long;
  TradeStatuses _selectedStatus = TradeStatuses.open;
  DateTime? _entryDate;
  final TextEditingController _entryPriceController = TextEditingController();
  final TextEditingController _entryQuantityController = TextEditingController();
  DateTime? _exitDate;
  final TextEditingController _exitPriceController = TextEditingController();
  final TextEditingController _exitQuantityController = TextEditingController();
  BrokerTypes? _selectedBroker;
  OrderTypes? _selectedOrderType;
  List<String> _attachments = [];

  // Step 2: Optional Details
  final TextEditingController _strategyController = TextEditingController();
  List<EntryPsychologyFactors> _selectedEntryPsychology = [];
  List<ExitPsychologyFactors> _selectedExitPsychology = [];
  List<TechnicalReasons> _selectedTechnicalReasons = [];
  List<FundamentalReasons> _selectedFundamentalReasons = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final trade = widget.initialData!;
    _symbolController.text = trade.instrumentInfo.symbol ?? '';
    _isinController.text = trade.instrumentInfo.isin ?? '';
    _descriptionController.text = trade.instrumentInfo.description ?? '';
    _selectedExchange = trade.instrumentInfo.exchange;
    _selectedSegment = trade.instrumentInfo.segment;

    if (trade.instrumentInfo.derivativeInfo != null) {
      _selectedDerivativeType = trade.instrumentInfo.derivativeInfo!.derivativeType;
      _selectedOptionType = trade.instrumentInfo.derivativeInfo!.optionType;
      _strikePriceController.text = trade.instrumentInfo.derivativeInfo!.strikePrice?.toString() ?? '';
      _expiryDate = trade.instrumentInfo.derivativeInfo!.expiryDate;
    }

    _selectedDirection = trade.tradePositionType;
    _selectedStatus = trade.status;
    _selectedBroker = trade.tradeExecutions?.isNotEmpty == true ? trade.tradeExecutions!.first.basicInfo?.brokerType : null;
    _selectedOrderType = trade.tradeExecutions?.isNotEmpty == true ? trade.tradeExecutions!.first.executionInfo?.orderType : null;
    
    _entryDate = trade.entryInfo.timestamp;
    _entryPriceController.text = trade.entryInfo.price?.toString() ?? '';
    _entryQuantityController.text = trade.entryInfo.quantity?.toString() ?? '';

    if (trade.exitInfo != null) {
      _exitDate = trade.exitInfo!.timestamp;
      _exitPriceController.text = trade.exitInfo!.price?.toString() ?? '';
      _exitQuantityController.text = trade.exitInfo!.quantity?.toString() ?? '';
    }

    _strategyController.text = trade.strategy ?? '';
    _notesController.text = trade.notes ?? '';
    _attachments = trade.attachments?.map((a) => a.fileUrl ?? '').toList() ?? [];
    
    if (trade.psychologyData != null) {
      _selectedEntryPsychology = trade.psychologyData!.entryPsychologyFactors ?? [];
      _selectedExitPsychology = trade.psychologyData!.exitPsychologyFactors ?? [];
    }

    if (trade.entryReasoning != null) {
      _selectedTechnicalReasons = trade.entryReasoning!.technicalReasons ?? [];
      _selectedFundamentalReasons = trade.entryReasoning!.fundamentalReasons ?? [];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _symbolController.dispose();
    _isinController.dispose();
    _descriptionController.dispose();
    _strikePriceController.dispose();
    _entryPriceController.dispose();
    _entryQuantityController.dispose();
    _exitPriceController.dispose();
    _exitQuantityController.dispose();
    _strategyController.dispose();
    _notesController.dispose();
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
    AppLogger.methodEntry('_saveTrade', tag: 'AddTradeForm');
    AppLogger.info('💾 User clicked Save Trade button', tag: 'AddTradeForm');

    try {
      AppLogger.debug('🔍 Validating required fields...', tag: 'AddTradeForm');
      final cleanSymbol = _symbolController.text.trim().toUpperCase();

      // Validate required fields
      TradeFormValidator.validateRequiredFields(
        symbol: cleanSymbol,
        selectedExchange: _selectedExchange,
        selectedSegment: _selectedSegment,
        entryDate: _entryDate,
        entryPrice: _entryPriceController.text,
        entryQuantity: _entryQuantityController.text,
        selectedBroker: _selectedBroker,
      );

      AppLogger.info('Required fields validation passed', tag: 'AddTradeForm');
      AppLogger.debug('Parsing numeric values...', tag: 'AddTradeForm');

      // Parse numeric values
      final entryPrice = double.tryParse(_entryPriceController.text);
      final entryQuantity = double.tryParse(_entryQuantityController.text);
      final exitPrice = _exitPriceController.text.isNotEmpty ? double.tryParse(_exitPriceController.text) : null;
      final exitQuantity = _exitQuantityController.text.isNotEmpty
          ? double.tryParse(_exitQuantityController.text)
          : null;
      final strikePrice = _strikePriceController.text.isNotEmpty ? double.tryParse(_strikePriceController.text) : null;

      AppLogger.debug(
        'Parsed values - entryPrice: $entryPrice, entryQuantity: $entryQuantity, exitPrice: $exitPrice',
        tag: 'AddTradeForm',
      );

      // Validate numeric values
      TradeFormValidator.validateNumericValues(entryPrice: entryPrice, entryQuantity: entryQuantity);

      AppLogger.info('Numeric validation passed', tag: 'AddTradeForm');

      // Validate closed trade data
      TradeFormValidator.validateClosedTrade(
        status: _selectedStatus,
        exitDate: _exitDate,
        exitPrice: exitPrice,
        exitQuantity: exitQuantity,
      );

      AppLogger.info('Closed trade validation passed', tag: 'AddTradeForm');
      AppLogger.debug('Building TradeDetails entity...', tag: 'AddTradeForm');

      // Map form data to TradeDetails entity
      final tradeDetails = TradeFormMapper.mapToTradeDetails(
        symbol: cleanSymbol,
        exchange: _selectedExchange,
        segment: _selectedSegment,
        isin: _isinController.text.isNotEmpty ? _isinController.text : null,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        derivativeType: _selectedDerivativeType,
        strikePrice: strikePrice,
        optionType: _selectedOptionType,
        expiryDate: _expiryDate,
        entryDate: _entryDate,
        entryPrice: entryPrice!,
        entryQuantity: entryQuantity!,
        exitDate: _exitDate,
        exitPrice: exitPrice,
        exitQuantity: exitQuantity,
        direction: _selectedDirection,
        status: _selectedStatus,
        entryPsychology: _selectedEntryPsychology,
        exitPsychology: _selectedExitPsychology,
        technicalReasons: _selectedTechnicalReasons,
        fundamentalReasons: _selectedFundamentalReasons,
        strategy: _strategyController.text.isNotEmpty ? _strategyController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        portfolioId: widget.initialData?.portfolioId,
        attachments: _attachments,
        selectedBroker: _selectedBroker,
        selectedOrderType: _selectedOrderType,
      );

      AppLogger.info(
        'TradeDetails entity created - symbol: $cleanSymbol, portfolioId: ${widget.initialData?.portfolioId}',
        tag: 'AddTradeForm',
      );

      // Call the parent's onSave callback
      if (widget.onSave != null) {
        AppLogger.info('📤 Calling onSave callback to parent', tag: 'AddTradeForm');
        widget.onSave!(tradeDetails);
      } else {
        AppLogger.warning('No onSave callback provided!', tag: 'AddTradeForm');
      }

      AppLogger.methodExit('_saveTrade', tag: 'AddTradeForm', result: 'success');
    } catch (e) {
      AppLogger.error('Trade save failed', tag: 'AddTradeForm', error: e, stackTrace: StackTrace.current);

      // Show error if validation or construction fails
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save trade: ${e.toString()}'), backgroundColor: Colors.red));
    }
    
  }

  void _onInstrumentSelected(Map<String, dynamic> instrument) {
    setState(() {
      _symbolController.text = instrument['symbol'] ?? 
                              instrument['tradingSymbol'] ?? 
                              instrument['tradingsymbol'] ?? 
                              instrument['name'] ?? 
                              '';
      _descriptionController.text = instrument['description'] ?? 
                                   instrument['displayName'] ?? 
                                   instrument['name'] ?? 
                                   '';
      
      // Auto-select exchange if available
      if (instrument['exchange'] != null) {
        final exchangeStr = instrument['exchange'].toString().toLowerCase();
        if (exchangeStr == 'nse') _selectedExchange = ExchangeTypes.nse;
        if (exchangeStr == 'bse') _selectedExchange = ExchangeTypes.bse;
      }
      
      // Auto-select segment if available
      if (instrument['segment'] != null) {
        final segmentStr = instrument['segment'].toString().toUpperCase();
        if (segmentStr == 'EQUITY') _selectedSegment = MarketSegments.equity;
      }
    });
    
    AppLogger.info(
      'Instrument selected: ${_symbolController.text} - ${_descriptionController.text}', 
      tag: 'AddTradeForm'
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    return Column(
      children: [
        // Progress Stepper
        _buildProgressStepper(theme),

        // Content Area with Modular Step Components
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Step 1: Trade Details (modular component)
              SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 16 : 10),
                child: TradeDetailsStep(
                  symbolController: _symbolController,
                  selectedExchange: _selectedExchange,
                  onExchangeChanged: (value) => setState(() => _selectedExchange = value),
                  selectedSegment: _selectedSegment,
                  onSegmentChanged: (value) => setState(() => _selectedSegment = value),
                  selectedDirection: _selectedDirection,
                  onDirectionChanged: (value) => setState(() => _selectedDirection = value),
                  selectedStatus: _selectedStatus,
                  onStatusChanged: (value) => setState(() => _selectedStatus = value),
                  entryDate: _entryDate,
                  onEntryDateSelected: (date) => setState(() => _entryDate = date),
                  entryPriceController: _entryPriceController,
                  entryQuantityController: _entryQuantityController,
                  exitDate: _exitDate,
                  onExitDateSelected: (date) => setState(() => _exitDate = date),
                  exitPriceController: _exitPriceController,
                  exitQuantityController: _exitQuantityController,
                  selectedBroker: _selectedBroker,
                  onBrokerChanged: (value) => setState(() => _selectedBroker = value),
                  selectedOrderType: _selectedOrderType,
                  onOrderTypeChanged: (value) => setState(() => _selectedOrderType = value),
                  selectedDerivativeType: _selectedDerivativeType,
                  onDerivativeTypeChanged: (value) => setState(() => _selectedDerivativeType = value),
                  strikePriceController: _strikePriceController,
                  selectedOptionType: _selectedOptionType,
                  onOptionTypeChanged: (value) => setState(() => _selectedOptionType = value),
                  expiryDate: _expiryDate,
                  onExpiryDateSelected: (date) => setState(() => _expiryDate = date),
                  attachments: _attachments,
                  onAttachmentsChanged: (files) => setState(() => _attachments = files),
                  userId: () {
                    final authState = context.read<AuthCubit>().state;
                    return authState is Authenticated ? authState.user.id : '';
                  }(),
                  onInstrumentSelected: _onInstrumentSelected,
                ),
              ),

              // Step 2: Optional Details (modular component)
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: OptionalDetailsStep(
                  strategyController: _strategyController,
                  selectedEntryPsychology: _selectedEntryPsychology,
                  onEntryPsychologyChanged: (factors) => setState(() => _selectedEntryPsychology = factors),
                  selectedExitPsychology: _selectedExitPsychology,
                  onExitPsychologyChanged: (factors) => setState(() => _selectedExitPsychology = factors),
                  selectedTechnicalReasons: _selectedTechnicalReasons,
                  onTechnicalReasonsChanged: (reasons) => setState(() => _selectedTechnicalReasons = reasons),
                  selectedFundamentalReasons: _selectedFundamentalReasons,
                  onFundamentalReasonsChanged: (reasons) => setState(() => _selectedFundamentalReasons = reasons),
                  notesController: _notesController,
                ),
              ),

              // Step 3: Review (modular component — padding owned by ReviewStep)
              SingleChildScrollView(
                child: ReviewStep(
                  symbol: _symbolController.text,
                  selectedExchange: _selectedExchange,
                  selectedSegment: _selectedSegment,
                  selectedDirection: _selectedDirection,
                  selectedStatus: _selectedStatus,
                  entryDate: _entryDate,
                  entryPrice: _entryPriceController.text,
                  entryQuantity: _entryQuantityController.text,
                  exitDate: _exitDate,
                  exitPrice: _exitPriceController.text,
                  exitQuantity: _exitQuantityController.text,
                  selectedBroker: _selectedBroker,
                  selectedOrderType: _selectedOrderType,
                  strategy: _strategyController.text,
                  selectedDerivativeType: _selectedDerivativeType,
                  strikePrice: _strikePriceController.text,
                  selectedOptionType: _selectedOptionType,
                  expiryDate: _expiryDate,
                  selectedEntryPsychology: _selectedEntryPsychology,
                  selectedExitPsychology: _selectedExitPsychology,
                  selectedTechnicalReasons: _selectedTechnicalReasons,
                  selectedFundamentalReasons: _selectedFundamentalReasons,
                  attachments: _attachments,
                  notes: _notesController.text,
                ),
              ),
            ],
          ),
        ),

        // Navigation Buttons
        _buildNavigationButtons(theme, isDesktop),
      ],
    );
  }

  Widget _buildProgressStepper(ThemeData theme) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 6 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isCompact ? 22 : 28,
                        height: isCompact ? 22 : 28,
                        decoration: BoxDecoration(
                          color: isActive || isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  Icons.check,
                                  color: theme.colorScheme.onPrimary,
                                  size: isCompact ? 12 : 16,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: isCompact ? 11 : 13,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: isCompact ? 4 : 6),
                      Flexible(
                        child: Text(
                          _getStepTitle(index),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: isCompact ? 11 : 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < _totalSteps - 1)
                  SizedBox(
                    width: isCompact ? 8 : 16,
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Trade Details';
      case 1:
        return 'Optional';
      case 2:
        return 'Review';
      default:
        return '';
    }
  }

  Widget _buildNavigationButtons(ThemeData theme, bool isDesktop) {
    final isCompact = !isDesktop && MediaQuery.sizeOf(context).width < 700;
    final horizontalPad = isCompact ? 12.0 : (isDesktop ? 24.0 : 16.0);
    final verticalPad = isCompact ? 8.0 : (isDesktop ? 24.0 : 16.0);
    final bottomNavReserve = PlatformConstants.globalBottomNavReserve(context);
    final isLastStep = _currentStep == _totalSteps - 1;
    final gap = isCompact ? 8.0 : 12.0;

    final primaryLabel = isLastStep ? 'Save Trade' : 'Next';
    final primaryIcon = isLastStep ? Icons.save_outlined : Icons.arrow_forward;

    // Intrinsic-sized primary action — same pattern as web (never stretch full width).
    final primaryButton = ElevatedButton(
      onPressed: widget.isLoading
          ? null
          : isLastStep
              ? _saveTrade
              : _nextStep,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 40),
        visualDensity: isCompact ? VisualDensity.compact : VisualDensity.standard,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 20,
          vertical: isCompact ? 10 : 12,
        ),
      ),
      child: widget.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCompact) ...[
                  Icon(primaryIcon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(primaryLabel, maxLines: 1),
              ],
            ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        verticalPad,
        horizontalPad,
        verticalPad + bottomNavReserve,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            isCompact
                ? OutlinedButton(
                    onPressed: widget.isLoading ? null : _previousStep,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Previous'),
                  )
                : OutlinedButton.icon(
                    onPressed: widget.isLoading ? null : _previousStep,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  )
          else
            const Spacer(),
          if (_currentStep > 0) const Spacer(),
          if (widget.onCancel != null)
            TextButton(
              onPressed: widget.isLoading ? null : widget.onCancel,
              style: TextButton.styleFrom(
                visualDensity: isCompact ? VisualDensity.compact : null,
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
              ),
              child: const Text('Cancel'),
            ),
          SizedBox(width: gap),
          primaryButton,
        ],
      ),
    );
  }
}

