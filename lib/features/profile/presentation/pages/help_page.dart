import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../bloc/help_center_cubit.dart';
import '../content/help_topics.dart';
import '../widgets/help_center_header.dart';
import '../widgets/help_center_style.dart';
import '../widgets/help_topic_card.dart';

class HelpPage extends StatefulWidget {
  final List<HelpTopic> topics;
  final String routePrefix, searchHint;
  const HelpPage({
    super.key,
    this.topics = helpTopics,
    this.routePrefix = '/teacher',
    this.searchHint =
        'Coba kata kunci seperti jadwal, progress, atau kode referral.',
  });

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  late final _cubit = HelpCenterCubit(topics: widget.topics);
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _cubit.close();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    _cubit.search('');
  }

  void _open(String route) {
    FocusScope.of(context).unfocus();
    context.push(route);
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: HelpCenterStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: HelpCenterStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  NalaraHeader(child: _navigation()),
                  Expanded(
                    child: BlocBuilder<HelpCenterCubit, HelpCenterState>(
                      bloc: _cubit,
                      builder: (context, state) => _content(context, state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _navigation() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('help-back'),
          tooltip: 'Kembali',
          onPressed: () => finishForm(context, '${widget.routePrefix}/more'),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: HelpCenterStyle.green,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Pusat Bantuan',
            style: TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 17,
              height: 1.4,
              color: HelpCenterStyle.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _content(BuildContext context, HelpCenterState state) {
    final topics = state.topics;
    return SingleChildScrollView(
      key: const PageStorageKey('help-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HelpCenterHeader(),
          TextField(
            key: const ValueKey('help-search'),
            controller: _search,
            onChanged: _cubit.search,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            style: HelpCenterStyle.body.copyWith(color: HelpCenterStyle.ink),
            decoration: InputDecoration(
              hintText: 'Cari panduan atau kata kunci',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: HelpCenterStyle.muted,
                size: 22,
              ),
              suffixIcon: state.query.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('help-clear-search'),
                      tooltip: 'Hapus pencarian',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Semantics(
                header: true,
                child: Text(
                  state.query.trim().isEmpty
                      ? 'Panduan penggunaan'
                      : 'Hasil pencarian',
                  style: HelpCenterStyle.body.copyWith(
                    color: HelpCenterStyle.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${topics.length} ${state.query.trim().isEmpty ? 'topik' : 'hasil'}',
                style: HelpCenterStyle.body.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (topics.isEmpty)
            _empty()
          else
            for (final topic in topics)
              HelpTopicCard(
                key: ValueKey('help-topic-${topic.id}'),
                topic: topic,
                expanded: state.expandedId == topic.id,
                onToggle: () => _cubit.toggle(topic.id),
                onOpen: topic.route == null ? null : () => _open(topic.route!),
              ),
          const SizedBox(height: 14),
          _privacy(),
        ],
      ),
    );
  }

  Widget _empty() => Container(
    key: const ValueKey('help-empty-search'),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: NalaraCardStyle.border),
      boxShadow: const [
        BoxShadow(
          color: NalaraCardStyle.shadow,
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Panduan tidak ditemukan',
          style: HelpCenterStyle.body.copyWith(
            color: HelpCenterStyle.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(widget.searchHint, style: HelpCenterStyle.body),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('help-reset-search'),
            onPressed: _clearSearch,
            child: const Text('Lihat semua panduan'),
          ),
        ),
      ],
    ),
  );

  Widget _privacy() => Padding(
    key: const ValueKey('help-privacy'),
    padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Jaga keamanan akun Anda',
          style: HelpCenterStyle.body.copyWith(
            color: HelpCenterStyle.ink,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Jangan bagikan kata sandi atau kode OTP kepada siapa pun.',
          style: HelpCenterStyle.body,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('help-open-privacy'),
            onPressed: () => _open('/legal/kebijakan-privasi'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              foregroundColor: HelpCenterStyle.ink,
              overlayColor: Colors.transparent,
              textStyle: HelpCenterStyle.body.copyWith(
                color: HelpCenterStyle.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Baca kebijakan privasi'),
          ),
        ),
      ],
    ),
  );
}
