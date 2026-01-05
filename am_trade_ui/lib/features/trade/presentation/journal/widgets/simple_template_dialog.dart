import 'dart:ui';
import 'package:flutter/material.dart';

/// Enhanced template with rich pre-filled content
class EnhancedTemplateDialog extends StatefulWidget {
  const EnhancedTemplateDialog({
    required this.onTemplateSelected,
    super.key,
  });

  final Function(String templateName, String richContent) onTemplateSelected;

  @override
  State<EnhancedTemplateDialog> createState() => _EnhancedTemplateDialogState();
}

class _EnhancedTemplateDialogState extends State<EnhancedTemplateDialog> {
  String? _selectedTemplate;
  String? _previewContent;

  // Rich template definitions with pre-filled content
  final Map<String, Map<String, dynamic>> _templates = {
    'Daily Game Plan': {
      'description': 'Complete daily trading preparation checklist',
      'icon': Icons.calendar_today,
      'color': Color(0xFF6C5DD3),
      'content': r'''📋 PRE-MARKET CHECKLIST ✅

□ Check economic calendar
□ Review overnight news
□ Identify key support/resistance levels
□ Set daily risk limits
□ Review watchlist

🎯 FUTURES 📊

▼ ES (S&P 500)
[Current Level: _____]
Key Levels:
• Resistance: _____
• Support: _____
• Bias: Bullish/Bearish/Neutral

▼ NQ (Nasdaq)
[Current Level: _____]
Key Levels:
• Resistance: _____
• Support: _____
• Bias: Bullish/Bearish/Neutral

📈 MARKET SENTIMENT

Overall Market Bias: _____
VIX Level: _____
Sector Rotation: _____

🎯 WATCHLIST

1. Symbol: _____ | Setup: _____ | Entry: _____ | Stop: _____
2. Symbol: _____ | Setup: _____ | Entry: _____ | Stop: _____
3. Symbol: _____ | Setup: _____ | Entry: _____ | Stop: _____

💭 TRADING PLAN

Focus for Today:
_____

Risk Management:
• Max Loss: $_____
• Max Position Size: _____
• Number of Trades: _____

🎯 GOALS

1. _____
2. _____
3. _____
''',
    },
    'All-in-One/Daily': {
      'description': 'Comprehensive daily trading journal',
      'icon': Icons.dashboard,
      'color': Color(0xFF9C27B0),
      'content': r'''📊 ALL-IN-ONE DAILY JOURNAL

📋 PRE-MARKET CHECKLIST ✅

□ Check economic calendar
□ Review overnight news  
□ Analyze futures movement
□ Set daily risk limits
□ Review watchlist

🎯 FUTURES 📈

▼ ES
Current: _____ | Bias: _____
Key Levels: R: _____ | S: _____

▼ NQ  
Current: _____ | Bias: _____
Key Levels: R: _____ | S: _____

📈 MARKET ANALYSIS

Sentiment: _____
VIX: _____
Sector Focus: _____

🎯 TRADES EXECUTED

Trade #1:
• Symbol: _____
• Entry: _____ | Exit: _____
• P/L: $_____
• Notes: _____

Trade #2:
• Symbol: _____
• Entry: _____ | Exit: _____
• P/L: $_____
• Notes: _____

💭 WHAT WENT WELL

✅ _____
✅ _____
✅ _____

⚠️ WHAT TO IMPROVE

❌ _____
❌ _____
❌ _____

📝 KEY LESSONS

1. _____
2. _____
3. _____

🎯 TOMORROW'S PLAN

_____
''',
    },
    'Pre-Market Prep': {
      'description': 'Morning preparation and analysis',
      'icon': Icons.wb_sunny_outlined,
      'color': Color(0xFFFF6B6B),
      'content': r'''☀️ PRE-MARKET PREPARATION

📅 Date: _____

📊 MARKET OVERVIEW

Futures:
• ES: _____ (___%)
• NQ: _____ (___%)
• YM: _____ (___%)

VIX: _____
Market Sentiment: _____

📰 NEWS & CATALYSTS

Economic Calendar:
• _____
• _____

Key News:
• _____
• _____

🎯 WATCHLIST

High Priority:
1. _____ - Setup: _____ | Entry: _____ | Target: _____
2. _____ - Setup: _____ | Entry: _____ | Target: _____
3. _____ - Setup: _____ | Entry: _____ | Target: _____

Medium Priority:
1. _____ - Setup: _____ | Entry: _____ | Target: _____
2. _____ - Setup: _____ | Entry: _____ | Target: _____

📈 SECTOR ANALYSIS

Strong Sectors:
• _____
• _____

Weak Sectors:
• _____
• _____

🎯 TRADING PLAN

Focus: _____
Max Risk: $_____
Position Sizing: _____

Key Levels to Watch:
• SPY: R: _____ | S: _____
• QQQ: R: _____ | S: _____

💭 MINDSET

Mental State: _____
Confidence Level: _____/10
Focus Areas: _____
''',
    },
    'Trade Recap': {
      'description': 'Detailed individual trade analysis',
      'icon': Icons.assessment_outlined,
      'color': Color(0xFF4ECDC4),
      'content': r'''📊 TRADE RECAP

📅 Date: _____
🏷️ Symbol: _____
⏰ Time: Entry: _____ | Exit: _____

💰 TRADE DETAILS

Entry Price: $_____
Exit Price: $_____
Position Size: _____ shares
P/L: $_____ (____%)

📈 SETUP

Pattern: _____
Timeframe: _____
Catalyst: _____

Key Levels:
• Entry: $_____
• Stop Loss: $_____
• Target 1: $_____
• Target 2: $_____

📊 TECHNICAL ANALYSIS

Indicators Used:
□ Moving Averages
□ RSI
□ MACD
□ Volume Profile
□ Support/Resistance

Chart Pattern: _____

🎯 EXECUTION

Entry Reason:
_____

Exit Reason:
_____

Trade Management:
_____

✅ WHAT WENT WELL

1. _____
2. _____
3. _____

❌ WHAT TO IMPROVE

1. _____
2. _____
3. _____

📝 KEY LESSONS

_____

💭 EMOTIONAL STATE

Before Trade: _____
During Trade: _____
After Trade: _____

🎯 NEXT TIME

Action Items:
1. _____
2. _____
3. _____
''',
    },
    'Weekly Review': {
      'description': 'Comprehensive weekly performance analysis',
      'icon': Icons.calendar_view_week,
      'color': Color(0xFFFFBE0B),
      'content': r'''📊 WEEKLY REVIEW

📅 Week of: _____

💰 PERFORMANCE SUMMARY

Total P/L: $_____
Win Rate: _____%
Total Trades: _____
Winning Trades: _____
Losing Trades: _____

Best Trade: $_____ (_____) 
Worst Trade: $_____ (_____)

📈 STATISTICS

Average Win: $_____
Average Loss: $_____
Risk/Reward Ratio: _____
Profit Factor: _____

🎯 BEST TRADES

Trade #1:
Symbol: _____ | P/L: $_____ | Why it worked: _____

Trade #2:
Symbol: _____ | P/L: $_____ | Why it worked: _____

Trade #3:
Symbol: _____ | P/L: $_____ | Why it worked: _____

❌ WORST TRADES

Trade #1:
Symbol: _____ | P/L: $_____ | What went wrong: _____

Trade #2:
Symbol: _____ | P/L: $_____ | What went wrong: _____

📊 PATTERNS OBSERVED

Winning Patterns:
• _____
• _____
• _____

Losing Patterns:
• _____
• _____
• _____

✅ STRENGTHS THIS WEEK

1. _____
2. _____
3. _____

⚠️ AREAS TO IMPROVE

1. _____
2. _____
3. _____

📝 KEY LESSONS

1. _____
2. _____
3. _____

🎯 NEXT WEEK'S GOALS

1. _____
2. _____
3. _____

💭 MINDSET & DISCIPLINE

Emotional Control: _____/10
Rule Following: _____/10
Patience: _____/10

Notes: _____
''',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface.withOpacity(0.95),
                    Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Left side - Template list
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: _templates.entries.map((entry) {
                              return _buildTemplateCard(context, entry.key, entry.value);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side - Preview
                  Expanded(
                    child: Column(
                      children: [
                        _buildPreviewHeader(context),
                        Expanded(child: _buildPreview(context)),
                        _buildActions(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5DD3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF6C5DD3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Template',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Select a pre-filled template',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, String name, Map<String, dynamic> template) {
    final isSelected = _selectedTemplate == name;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTemplate = name;
              _previewContent = template['content'] as String;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6C5DD3).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C5DD3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (template['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    template['icon'] as IconData,
                    color: template['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 11,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF6C5DD3),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 20),
          const SizedBox(width: 8),
          Text(
            'Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (_previewContent == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a template to preview',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          _previewContent!,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _selectedTemplate == null
                ? null
                : () {
                    widget.onTemplateSelected(
                      _selectedTemplate!,
                      _previewContent!,
                    );
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.check),
            label: const Text('Use Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5DD3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
