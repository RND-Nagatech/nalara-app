import 'package:flutter/material.dart';
import '../../../profile/presentation/pages/help_page.dart';
import '../content/parent_help_topics.dart';

class ParentHelpPage extends StatelessWidget {
  const ParentHelpPage({super.key});

  @override
  Widget build(BuildContext context) => const HelpPage(
    routePrefix: '/parent',
    searchHint:
        'Coba kata kunci seperti anak, biaya bimbel, atau ganti jadwal.',
    topics: parentHelpTopics,
  );
}
