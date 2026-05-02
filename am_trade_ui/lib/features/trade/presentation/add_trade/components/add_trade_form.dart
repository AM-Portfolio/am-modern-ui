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
    // TODO: Load from initialData if editing
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

      // Validate required fields
      TradeFormValidator.validateRequiredFields(
        symbol: _symbolController.text,
        selectedExchange: _selectedExchange,
        selectedSegment: _selectedSegment,
        entryDate: _entryDate,
        entryPrice: _entryPriceController.text,
        entryQuantity: _entryQuantityController.text,
        selectedBroker: _selectedBroker,
      );

      AppLogger.info('✅ Required fields validation passed', tag: 'AddTradeForm');
      AppLogger.debug('📊 Parsing numeric values...', tag: 'AddTradeForm');

      // Parse numeric values
      final entryPrice = double.tryParse(_entryPriceController.text);
      final entryQuantity = double.tryParse(_entryQuantityController.text);
      final exitPrice = _exitPriceController.text.isNotEmpty ? double.tryParse(_exitPriceController.text) : null;
      final exitQuantity = _exitQuantityController.text.isNotEmpty
          ? double.tryParse(_exitQuantityController.text)
          : null;
      final strikePrice = _strikePriceController.text.isNotEmpty ? double.tryParse(_strikePriceController.text) : null;

      AppLogger.debug(
        '💰 Parsed values - entryPrice: $entryPrice, entryQuantity: $entryQuantity, exitPrice: $exitPrice',
        tag: 'AddTradeForm',
      );

      // Validate numeric values
      TradeFormValidator.validateNumericValues(entryPrice: entryPrice, entryQuantity: entryQuantity);

      AppLogger.info('✅ Numeric validation passed', tag: 'AddTradeForm');

      // Validate closed trade data
      TradeFormValidator.validateClosedTrade(
        status: _selectedStatus,
        exitDate: _exitDate,
        exitPrice: exitPrice,
        exitQuantity: exitQuantity,
      );

      AppLogger.info('✅ Closed trade validation passed', tag: 'AddTradeForm');
      AppLogger.debug('🏗️ Building TradeDetails entity...', tag: 'AddTradeForm');

      // Map form data to TradeDetails entity
      final tradeDetails = TradeFormMapper.mapToTradeDetails(
        symbol: _symbolController.text,
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
      );

      AppLogger.info(
        '✅ TradeDetails entity created - symbol: ${_symbolController.text}, portfolioId: ${widget.initialData?.portfolioId}',
        tag: 'AddTradeForm',
      );

      // Call the parent's onSave callback
      if (widget.onSave != null) {
        AppLogger.info('📤 Calling onSave callback to parent', tag: 'AddTradeForm');
        widget.onSave!(tradeDetails);
      } else {
        AppLogger.warning('⚠️ No onSave callback provided!', tag: 'AddTradeForm');
      }

      AppLogger.methodExit('_saveTrade', tag: 'AddTradeForm', result: 'success');
    } catch (e) {
      AppLogger.error('❌ Trade save failed', tag: 'AddTradeForm', error: e, stackTrace: StackTrace.current);

      // Show error if validation or construction fails
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save trade: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  void _onInstrumentSelected(Map<String, dynamic> instrument) {
    setState(() {
      _symbolController.text = instrument['symbol'] ?? '';
      _descriptionController.text = instrument['description'] ?? instrument['displayName'] ?? '';
      
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
      '🎯 Instrument selected: ${_symbolController.text} - ${_descriptionController.text}', 
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
                padding: const EdgeInsets.all(16),
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

              // Step 3: Review (modular component)
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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

  Widget _buildProgressStepper(ThemeData theme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1))),
    ),
    child: Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive || isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 16)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getStepTitle(index),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
          )
        else
          const SizedBox(),
        Row(
          children: [
            if (widget.onCancel != null)
              TextButton(onPressed: widget.isLoading ? null : widget.onCancel, child: const Text('Cancel')),
            const SizedBox(width: 16),
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
            ),
          ],
        ),
      ],
    ),
  );
}

