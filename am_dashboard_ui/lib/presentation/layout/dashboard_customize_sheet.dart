import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_model.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_provider.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_store.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet to show/hide and reorder dashboard widgets.
class DashboardCustomizeSheet extends ConsumerWidget {
  const DashboardCustomizeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: DashboardCustomizeSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDashboardCustomizeEnabled) return const SizedBox.shrink();

    final layout = mergeWithDefaultLayout(ref.watch(dashboardLayoutProvider));
    final notifier = ref.read(dashboardLayoutProvider.notifier);
    final slots = [...layout.slots]..sort((a, b) => a.order.compareTo(b.order));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Customize dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose which widgets appear and their order.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: slots.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  return ListTile(
                    title: Text(slot.id.label),
                    subtitle: Text(slot.id.module),
                    leading: Switch(
                      value: slot.visible,
                      onChanged: (v) => notifier.toggleVisibility(slot.id, v),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: index == 0
                              ? null
                              : () => notifier.moveSlot(slot.id, -1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          onPressed: index == slots.length - 1
                              ? null
                              : () => notifier.moveSlot(slot.id, 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await notifier.resetToDefault();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Reset to default'),
            ),
          ],
        ),
      ),
    );
  }
}
