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
  DateTime? _from;
  DateTime? _to;
  int _reloadKey = 0;

  static const _actions = [
    'ALL',
    'STOCK_IN',
    'STOCK_OUT',
    'ORDER_CREATED',
    'ORDER_RECEIVED',
    'ORDER_CANCELLED',
    'ITEM_CREATED',
    'ITEM_EDITED',
    'ITEM_DELETED',
    'SUPPLIER_CREATED',
    'SUPPLIER_EDITED',
    'SUPPLIER_DELETED',
    'SUPPLIER_PAYMENT',
    'EXPENSE_CREATED',
    'EXPENSE_DELETED',
    'STOCK_IN_DELETED',
    'STOCK_OUT_DELETED',
  ];

  void _reload() => setState(() => _reloadKey++);

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = DateTime(picked.year, picked.month, picked.day);
      } else {
        _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      key: ValueKey(_reloadKey),
      future: ref.read(activityLogServiceProvider).getAll(
            actionFilter: _actionFilter,
            search: _search.isEmpty ? null : _search,
            from: _from,
            to: _to,
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
                    onChanged: (v) {
                      setState(() => _search = v);
                      _reload();
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: true),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_from == null ? 'From' : '${_from!.day}/${_from!.month}/${_from!.year}'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: false),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_to == null ? 'To' : '${_to!.day}/${_to!.month}/${_to!.year}'),
                      ),
                      if (_from != null || _to != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _from = null;
                              _to = null;
                            });
                            _reload();
                          },
                          child: const Text('Clear dates'),
                        ),
                      ],
                    ],
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
                                onSelected: (_) {
                                  setState(() => _actionFilter = a);
                                  _reload();
                                },
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
