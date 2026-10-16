import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/public_data_provider.dart';
import '../../widgets/shared.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _hours = 24;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    final cutoff = data.clock().toUtc().subtract(Duration(hours: _hours));
    final entries =
        data.snapshot?.history
            .where((e) => !e.timestamp.isBefore(cutoff))
            .toList() ??
        [];
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return RefreshIndicator(
      onRefresh: data.load,
      child: PageBody(
        children: [
          Text(
            'The coast over time',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('Past regional statuses, newest first.'),
          const SizedBox(height: 20),
          const DataNotices(),
          Wrap(
            spacing: 8,
            children: [24, 48, 72]
                .map(
                  (hours) => ChoiceChip(
                    label: Text('$hours hours'),
                    selected: _hours == hours,
                    onSelected: (_) => setState(() => _hours = hours),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty && !data.loading)
            const EmptyState(
              'No history in this window',
              'Choose a longer period or retry when records are available.',
            ),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(stamp(entry.timestamp))),
                      const SizedBox(width: 10),
                      StatusChip(entry.level),
                    ],
                  ),
                  const Divider(height: 24),
                ],
              ),
            ),
          ),
          const Notice(
            'Incident records are available on the map and in beach details.',
          ),
          const Attribution(),
        ],
      ),
    );
  }
}
