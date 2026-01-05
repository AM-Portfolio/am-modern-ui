# Add Trade Package

Streamlined 4-step trade entry system focused on **click-and-select** interactions to minimize typing.

## 📦 Package Structure

```
lib/features/trade/presentation/add_trade/
├── add_trade.dart                      # Package exports
├── components/
│   └── add_trade_form.dart            # Main 4-step form
├── pages/
│   └── add_trade_web_page.dart        # Web page wrapper
└── widgets/
    ├── add_trade_fab.dart             # Floating action button
    ├── attachment_picker.dart         # File upload component
    ├── direction_selector.dart        # Visual Long/Short selector
    ├── quick_selection_chips.dart     # Multi-select chips (reusable)
    └── status_selector.dart           # Status chips (Open/Closed/Pending)
```

## 🎯 Design Philosophy

### Minimize Typing
- **Dropdowns** for enums (exchange, segment, broker, etc.)
- **Visual buttons** for direction (Long/Short)
- **Chips** for status, psychology, reasoning
- **Date pickers** instead of text fields
- **Number steppers** for quantities (future enhancement)

### Optional Psychology & Reasoning
- Step 3 is **completely optional** - users can skip
- Reduces friction for quick trade entry
- Advanced users can add detailed analysis

### Visual First
- Large clickable cards for direction selection
- Color-coded status chips
- Icon-based navigation
- Modern card layouts

## 🚀 4-Step Flow

### Step 1: Instrument Details ⭐ Required
- Symbol (text input - minimal typing)
- Exchange (dropdown)
- Segment (dropdown)
- Series (dropdown - optional)
- Derivative info (optional section):
  - Type (dropdown)
  - Strike price
  - Option type
  - Expiry date

### Step 2: Entry & Exit 💰 Required
- **Direction**: Visual selector (Long/Short cards)
- **Status**: Chip selector (Open/Closed/Pending)
- **Entry**:
  - Date (date picker)
  - Price (number input)
  - Quantity (number input)
  - Broker (dropdown)
  - Order type (dropdown)
- **Exit** (conditional - only if status = Closed):
  - Date, price, quantity
- **Attachments**: File upload section

### Step 3: Optional Details 🧠 OPTIONAL
- Strategy (single text field)
- **Psychology** (quick-select chips):
  - Entry psychology factors
  - Exit psychology factors
- **Reasoning** (quick-select chips):
  - Technical reasons
  - Fundamental reasons
- Additional notes (text area)

### Step 4: Review & Submit ✅
- Comprehensive review of all entered data
- Organized by sections
- Edit capability (future)
- Save button

## 🎨 Components

### DirectionSelector
Visual card selector for Long/Short:
```dart
DirectionSelector(
  selectedDirection: _selectedDirection,
  onDirectionSelected: (direction) => setState(() => _selectedDirection = direction),
)
```

### StatusSelector
Chip-based status selector:
```dart
StatusSelector(
  selectedStatus: _selectedStatus,
  onStatusSelected: (status) => setState(() => _selectedStatus = status),
)
```

### QuickSelectionChips<T>
Reusable multi-select chip component:
```dart
QuickSelectionChips<PsychologyFactors>(
  title: 'Entry Psychology',
  availableOptions: PsychologyFactors.values,
  selectedOptions: _selectedEntryPsychology,
  onSelectionChanged: (selected) => setState(() => _selectedEntryPsychology = selected),
  labelBuilder: (factor) => factor.toString().split('.').last,
)
```

### AttachmentPicker
File upload for screenshots/documents:
```dart
AttachmentPicker(
  attachments: _attachments,
  onAttachmentsChanged: (files) => setState(() => _attachments = files),
)
```

## 📱 Usage

### Import the Package
```dart
import 'package:am_investment_ui/features/trade/presentation/add_trade/add_trade.dart';
```

### Use in Routing
```dart
// In app.dart
import 'features/trade/presentation/add_trade/pages/add_trade_web_page.dart';

case '/trade/add':
  final args = settings.arguments! as Map<String, dynamic>;
  return MaterialPageRoute(
    builder: (context) => AddTradeWebPage(
      portfolioId: args['portfolioId']! as String,
      portfolioName: args['portfolioName'] as String?,
    ),
  );
```

### Add FAB to Trade Screen
```dart
import 'package:am_investment_ui/features/trade/presentation/add_trade/widgets/add_trade_fab.dart';

floatingActionButton: AddTradeFab(portfolioId: portfolioId),
```

## 🔄 Migration from Old Template

### Old Template (6 steps)
1. Instrument
2. Entry
3. Exit
4. Psychology
5. Reasoning
6. Review

### New Template (4 steps)
1. Instrument
2. Entry & Exit (combined)
3. Optional Details (psychology + reasoning, skippable)
4. Review

### Key Changes
- ✅ Reduced steps from 6 → 4
- ✅ Combined Entry/Exit into single step
- ✅ Made psychology/reasoning optional
- ✅ Added visual selectors (direction, status)
- ✅ Added attachment support
- ✅ Organized into package structure
- ✅ Minimized text input requirements

## ✨ Features

### Completed
- ✅ 4-step wizard with progress indicator
- ✅ Visual direction selector (Long/Short)
- ✅ Visual status selector (chips)
- ✅ Multi-select chips for psychology/reasoning
- ✅ Attachment picker (UI ready)
- ✅ Responsive design (desktop/tablet/mobile)
- ✅ Package structure
- ✅ All enum dropdowns

### Todo
- ⏳ Number steppers for price/quantity
- ⏳ File picker integration (currently placeholder)
- ⏳ Complete review step with edit buttons
- ⏳ BLoC integration for save
- ⏳ Form validation with error messages
- ⏳ Auto-save drafts
- ⏳ Edit mode support (initialData)

## 🎯 User Experience Goals

1. **Faster Entry**: Reduce time to add trade from 5 minutes → 2 minutes
2. **Less Typing**: 80% reduction in text input fields
3. **Optional Depth**: Quick entry for beginners, detailed for advanced
4. **Visual Feedback**: Clear indication of selections
5. **Error Prevention**: Dropdowns prevent invalid values

## 📊 Metrics

### Input Methods (Old vs New)
| Type | Old Template | New Template |
|------|--------------|--------------|
| Text Fields | 15 | 5 |
| Dropdowns | 8 | 8 |
| Date Pickers | 3 | 3 |
| Visual Selectors | 0 | 2 |
| Multi-Select Chips | 5 | 4 |

### Steps
- **Before**: 6 mandatory steps
- **After**: 3 mandatory + 1 optional step

## 🔗 Related Files

### Original Implementation (Deprecated)
- `lib/features/trade/presentation/components/templates/add_trade_template.dart` (1,500+ lines)
- `lib/features/trade/presentation/web/pages/add_trade_web_page.dart`
- `lib/features/trade/presentation/widgets/add_trade_fab.dart`

### New Package
- `lib/features/trade/presentation/add_trade/` (organized package)

## 📝 Notes

- Psychology and reasoning are **optional by design** to reduce friction
- Attachments support is UI-ready, awaiting file picker integration
- Review step needs comprehensive implementation similar to old template
- Form validation is minimal - needs enhancement
- BLoC integration pending

---

**Version**: 2.0 (Streamlined)  
**Last Updated**: 2025-11-22
