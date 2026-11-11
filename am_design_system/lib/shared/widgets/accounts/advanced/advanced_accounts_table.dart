import 'package:flutter/material.dart';

import '../../../../core/theme/color_extensions.dart';
import 'advanced_account_row.dart';

/// Table layout for [AdvancedAccountsTemplate] — mock-1 density + badges.
class AdvancedAccountsTable extends StatelessWidget {
  const AdvancedAccountsTable({
    required this.accounts,
    required this.accent,
    required this.onSort,
    super.key,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onRowTap,
  });

  final List<AdvancedAccountRow> accounts;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Color accent;
  final void Function(int columnIndex, bool ascending) onSort;
  final ValueChanged<AdvancedAccountRow>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return KeyedSubtree(
                key: ValueKey(account.id),
                child: _buildRow(context, account, index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _headerCell(context, 'BROKER', 1, 0),
            _headerCell(context, 'TYPE', 1, 1),
            _headerCell(context, 'ACCOUNT LEGAL NAME', 2, 2),
            _headerCell(context, 'DP / ACCOUNT ID', 2, 3),
            _headerCell(context, 'NOMINEE STATUS', 2, 4),
            _headerCell(context, 'LINKED EMAIL', 2, 5),
            _headerCell(context, 'MOBILE', 1, 6),
            _headerCell(context, 'STATUS', 1, 7),
            _headerCell(context, 'VALUE', 1, 8, isNumeric: true),
          ],
        ),
      );

  Widget _headerCell(
    BuildContext context,
    String label,
    int flex,
    int columnIndex, {
    bool isNumeric = false,
  }) {
    final isSorted = sortColumnIndex == columnIndex;
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(columnIndex, isSorted ? !sortAscending : true),
        child: Row(
          mainAxisAlignment:
              isNumeric ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.3,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSorted)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    AdvancedAccountRow account,
    int index,
  ) {
    final theme = Theme.of(context);
    final muted = context.textSecondary;
    final valueColor = account.isInactive
        ? muted
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onRowTap != null ? () => onRowTap!(account) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: index.isEven
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(child: _brokerCell(context, account)),
            Expanded(child: _typeBadge(context, account)),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.displayTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent.withValues(alpha: 0.95),
                    ),
                  ),
                  if (account.displaySubtitle.isNotEmpty)
                    Text(
                      account.displaySubtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                account.displayAccountId,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: muted,
                ),
              ),
            ),
            Expanded(flex: 2, child: _nomineeBadge(context, account)),
            Expanded(
              flex: 2,
              child: Text(
                account.displayEmail,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
            Expanded(
              child: Text(
                account.displayMobile,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
            Expanded(child: _statusCell(context, account)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    account.displayValue,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                  if (account.displayWeightPct.isNotEmpty)
                    Text(
                      account.displayWeightPct,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(BuildContext context, AdvancedAccountRow account) {
    final isPrimary = account.type == 'demat' ||
        account.type == 'broker' ||
        account.type == 'mf' ||
        account.type == 'nps';
    final color = isPrimary ? accent : context.textSecondary;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          account.displayType,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _brokerCell(BuildContext context, AdvancedAccountRow account) {
    final name = account.displayBroker;
    if (name == '—') {
      return Text('—', style: TextStyle(fontSize: 12, color: context.textSecondary));
    }
    final tint = AdvancedAccountRow.brokerTint(account.broker, accent);
    final mark = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: tint.withValues(alpha: 0.55)),
          ),
          child: Text(
            mark,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: tint,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _nomineeBadge(BuildContext context, AdvancedAccountRow account) {
    if (!account.showNomineeBadge && account.displayNominee == '—') {
      return Text('—', style: TextStyle(fontSize: 12, color: context.textSecondary));
    }
    final missing =
        account.nomineeMissing || account.displayNominee == 'No nominee';
    final color = missing ? context.statusError : context.statusSuccess;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.7)),
          color: color.withValues(alpha: 0.08),
        ),
        child: Text(
          account.displayNominee,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _statusCell(BuildContext context, AdvancedAccountRow account) {
    final kind = account.statusKind;
    final Color dot;
    switch (kind) {
      case AccountStatusKind.active:
        dot = context.statusSuccess;
      case AccountStatusKind.inactive:
        dot = context.textTertiary;
      case AccountStatusKind.frozen:
        dot = context.statusWarning;
      case AccountStatusKind.unknown:
        dot = context.textSecondary;
    }
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            account.displayStatus,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
