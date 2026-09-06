import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_ai_ui/data/ai_session_models.dart';
import 'package:am_ai_ui/presentation/providers/ai_session_provider.dart';
import 'package:am_ai_ui/presentation/widgets/ai_history_drawer.dart';

class _StubSessionNotifier extends AiSessionNotifier {
  _StubSessionNotifier(this.initial);

  final SessionListState initial;

  @override
  SessionListState build() => initial;

  @override
  Future<void> refresh() async {}

  @override
  Future<bool> deleteSession(String sessionId) async {
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != sessionId).toList(),
    );
    return true;
  }
}

void main() {
  final sample = AiSessionSummary(
    id: 'sess-a',
    title: 'Morning portfolio',
    productId: 'am_app',
    agentType: 'fin_portfolio',
    channel: 'user_app',
    createdAt: DateTime.utc(2026, 9, 1, 8),
    updatedAt: DateTime.utc(2026, 9, 2, 9, 15),
  );

  Widget wrap(Widget child, {SessionListState? state}) {
    return ProviderScope(
      overrides: [
        aiSessionProvider.overrideWith(
          () => _StubSessionNotifier(
            state ??
                SessionListState(sessions: [sample], isLoading: false),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          endDrawer: child,
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows session title and date; tap selects', (tester) async {
    String? selected;
    await tester.pumpWidget(
      wrap(
        AiHistoryDrawer(
          onSelectSession: (id) => selected = id,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Chat history'), findsOneWidget);
    expect(find.text('Morning portfolio'), findsOneWidget);
    expect(find.textContaining('fin_portfolio'), findsOneWidget);

    await tester.tap(find.text('Morning portfolio'));
    await tester.pumpAndSettle();
    expect(selected, 'sess-a');
  });

  testWidgets('delete removes session from list after confirm', (tester) async {
    await tester.pumpWidget(
      wrap(
        AiHistoryDrawer(onSelectSession: (_) {}),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete chat?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Morning portfolio'), findsNothing);
    expect(find.textContaining('No saved chats'), findsOneWidget);
  });

  testWidgets('empty state message when no sessions', (tester) async {
    await tester.pumpWidget(
      wrap(
        AiHistoryDrawer(onSelectSession: (_) {}),
        state: const SessionListState(sessions: [], isLoading: false),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No saved chats yet'), findsOneWidget);
  });
}
