import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/services_provider.dart';

class ActivityLogsScreen extends ConsumerStatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  ConsumerState<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends ConsumerState<ActivityLogsScreen> {
  String _search = '';
  String _actionFilter = 'ALL';

  static const _actions = [
    'ALL',
    'STOCK_IN',
    'STOCK_OUT',
    'ORDER_CREATED',
    'ORDER_RECEIVED',
    'SUPPLIER_PAYMENT',
    'ITEM_CREATED',
    'EXPENSE_CREATED',
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref.read(activityLogServiceProvider).getAll(
            actionFilter: _actionFilter,
            search: _search.isEmpty ? null : _search,
          ),
      builder: (context, snap) {
        final logs = snap.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity Logs', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search logs...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _actions
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(a == 'ALL' ? 'All' : a.replaceAll('_', ' ')),
                                selected: _actionFilter == a,
                                onSelected: (_) => setState(() => _actionFilter = a),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: snap.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : logs.isEmpty
                      ? const Center(child: Text('No activity logs'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: logs.length,
                          itemBuilder: (_, i) {
                            final log = logs[i];
                            return ListTile(
                              title: Text(log.details, style: const TextStyle(fontSize: 13)),
                              subtitle: Text(
                                '${log.action} · ${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year} ${log.createdAt.hour}:${log.createdAt.minute.toString().padLeft(2, '0')}',
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
