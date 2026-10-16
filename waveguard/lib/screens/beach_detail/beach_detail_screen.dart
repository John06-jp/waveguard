import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/public_data_provider.dart';
import '../../widgets/shared.dart';

void openBeach(BuildContext context, String id) => Navigator.push<void>(
  context,
  MaterialPageRoute(builder: (_) => BeachDetailScreen(beachId: id)),
);

class BeachDetailScreen extends StatelessWidget {
  const BeachDetailScreen({required this.beachId, super.key});
  final String beachId;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    final beaches = data.snapshot?.beaches.where((b) => b.id == beachId);
    final beach = beaches == null || beaches.isEmpty ? null : beaches.first;
    final incidents =
        data.snapshot?.incidents.where((i) => i.beachId == beachId).toList() ??
        [];
    return Scaffold(
      appBar: AppBar(title: const Text('Beach information')),
      body: PageBody(
        children: [
          const DataNotices(),
          if (beach == null)
            const EmptyState(
              'Beach unavailable',
              'This record is no longer available.',
            )
          else ...[
            Text(beach.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              beach.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            if (beach.hasCantil)
              const CantilWarning()
            else
              const Notice(
                'No cantil flag is recorded. This does not mean the beach is safe.',
              ),
            const SectionTitle(
              'Regional conditions',
              subtitle:
                  'This status covers Lianga, not this beach individually.',
            ),
            if (data.snapshot?.advisory != null)
              AdvisoryCard(
                advisory: data.snapshot!.advisory!,
                outdated: data.outdated,
                demo: data.isDemo,
              )
            else
              const EmptyState(
                'Advisory unavailable',
                'Check with local authorities for current guidance.',
              ),
            const SectionTitle('Past incidents'),
            if (incidents.isEmpty)
              const EmptyState(
                'No incident records',
                'No past incidents are available for this beach. This is not a safety guarantee.',
              ),
            ...incidents.map(
              (incident) => Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.type,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(stamp(incident.date)),
                      const SizedBox(height: 8),
                      Text(incident.summary),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const Attribution(),
        ],
      ),
    );
  }
}
