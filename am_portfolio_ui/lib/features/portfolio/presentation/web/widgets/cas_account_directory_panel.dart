import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/data/dtos/cas_dto.dart';
import '../../../providers/cas_providers.dart';

/// Demat + MF account directory from latest CAS (status, DP/Client, nominee, link).
class CasAccountDirectoryPanel extends ConsumerWidget {
  const CasAccountDirectoryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(casAccountsProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        return ExpansionTile(
          title: Text('Account directory (${rows.length})'),
          subtitle: const Text('CDSL CAS demat & MF folios'),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Account')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('DP / Client')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Nominee')),
                  DataColumn(label: Text('Broker')),
                  DataColumn(label: Text('Value')),
                ],
                rows: [
                  for (final r in rows) _row(r),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _nomineeCell(DematAccountDto r) {
    final name = r.nominee?.trim();
    if (name != null && name.isNotEmpty) {
      if (r.nomineeRegistered == false) return '$name (not registered)';
      if (r.nomineeRegistered == true) return '$name (registered)';
      return name;
    }
    if (r.nomineeRegistered == false) return 'Not registered';
    return '';
  }

  DataRow _row(DematAccountDto r) {
    final account = r.accountType == 'mf'
        ? (r.folio ?? r.accountNo)
        : (r.boid ?? r.accountNo);
    final dpClient = [
      if (r.dpId != null && r.dpId!.isNotEmpty) r.dpId,
      if (r.clientId != null && r.clientId!.isNotEmpty) r.clientId,
    ].join(' / ');
    return DataRow(
      cells: [
        DataCell(Text(r.accountType ?? '')),
        DataCell(Text(account)),
        DataCell(Text(r.status ?? (r.active == true ? 'Active' : ''))),
        DataCell(Text(dpClient)),
        DataCell(Text(r.email ?? '')),
        DataCell(Text(_nomineeCell(r))),
        DataCell(Text(r.isLinked ? (r.mappedBroker ?? '') : 'Not linked')),
        DataCell(Text(
          r.holdingValue != null ? r.holdingValue!.toStringAsFixed(2) : '',
        )),
      ],
    );
  }
}
