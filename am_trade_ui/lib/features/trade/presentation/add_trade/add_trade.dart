/// Add Trade Package
///
/// Streamlined 4-step trade entry system with:
/// - Step 1: Instrument Details (symbol, exchange, derivatives)
/// - Step 2: Entry & Exit (direction, dates, prices, attachments)
/// - Step 3: Optional Details (psychology, reasoning - skippable)
/// - Step 4: Review & Submit
///
/// Design Philosophy:
/// - Minimize typing - use dropdowns, chips, buttons
/// - Click-and-select focused
/// - Optional psychology/reasoning to reduce friction
/// - Visual selectors for better UX

library;

// Components
export 'components/add_trade_form.dart';
// Pages
export 'pages/add_trade_web_page.dart';
// Widgets
export 'widgets/add_trade_fab.dart';
export 'widgets/attachment_picker.dart';
export 'widgets/direction_selector.dart';
export 'widgets/quick_selection_chips.dart';
export 'widgets/status_selector.dart';
