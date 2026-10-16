import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/public_data_provider.dart';
import '../../widgets/shared.dart';
import '../beach_detail/beach_detail_screen.dart';

class BeachesScreen extends StatelessWidget {
  const BeachesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    final beaches = data.snapshot?.beaches ?? [];
    return RefreshIndicator(
      onRefresh: data.load,
      child: PageBody(
        children: [
          const DataNotices(),
          if (beaches.isEmpty && !data.loading)
            const EmptyState(
              'No beaches available',
              'Verified beach records will appear here when available.',
            ),
          ...beaches.map(
            (beach) =>
                BeachTile(beach, onTap: () => openBeach(context, beach.id)),
          ),
          const Notice(
            'A missing hazard flag does not establish that a beach is safe.',
          ),
          const Attribution(),
        ],
      ),
    );
  }
}
