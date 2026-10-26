import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../shared/widgets/nalara_empty_state.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../shared/widgets/teacher_bottom_navigation.dart';
import '../../../../shared/widgets/parent_bottom_navigation.dart';
import '../../../../shared/widgets/student_bottom_navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/feedback_notice.dart';
import '../../../../utils/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _navigationInFlight = false;

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

  Future<void> _open(String route) async {
    if (_navigationInFlight) return;
    _navigationInFlight = true;
    FocusScope.of(context).unfocus();
    try {
      if (isTeacherShellLocation(route) ||
          parentNavigationLocations.contains(route) ||
          studentNavigationLocations.contains(route)) {
        context.go(route);
      } else {
        await context.push(route);
      }
    } finally {
      _navigationInFlight = false;
    }
  }

  Future<void> _openSupport() async {
    if (_navigationInFlight) return;
    _navigationInFlight = true;
    try {
      final launched = await launchUrl(
        Uri.parse(AppLinks.supportUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        await showNalaraNotice(
          context,
          'Halaman support belum dapat dibuka. Coba lagi atau hubungi helpdesk.nagatech@gmail.com.',
          title: 'Support belum terbuka',
          type: NalaraNoticeType.error,
        );
      }
    } finally {
      _navigationInFlight = false;
    }
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
          if (widget.routePrefix == '/teacher') ...[
            NalaraSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Panduan mulai mengajar',
                    style: HelpCenterStyle.body.copyWith(
                      color: HelpCenterStyle.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Temukan tutorial interaktif di Lainnya → Panduan mulai mengajar untuk menyiapkan bidang belajar, siswa, jadwal, dan target.',
                    style: HelpCenterStyle.body,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const ValueKey('help-open-teaching-guide'),
                    onPressed: () => _open('/teacher/getting-started'),
                    child: const Text('Buka panduan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
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
          const SizedBox(height: 14),
          _support(),
        ],
      ),
    );
  }

  Widget _empty() => NalaraEmptyState(
    key: const ValueKey('help-empty-search'),
    imagePath: 'assets/Empty/empty siswa.png',
    title: 'Panduan tidak ditemukan',
    message: widget.searchHint,
    action: TextButton(
      key: const ValueKey('help-reset-search'),
      onPressed: _clearSearch,
      child: const Text('Lihat semua panduan'),
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
              foregroundColor: HelpCenterStyle.green,
              overlayColor: Colors.transparent,
              textStyle: HelpCenterStyle.body.copyWith(
                color: HelpCenterStyle.green,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: HelpCenterStyle.green,
              ),
            ),
            child: Text(
              'Baca kebijakan privasi',
              style: HelpCenterStyle.body.copyWith(
                color: HelpCenterStyle.green,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: HelpCenterStyle.green,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _support() => Padding(
    key: const ValueKey('help-support'),
    padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Butuh bantuan langsung?',
          style: HelpCenterStyle.body.copyWith(
            color: HelpCenterStyle.ink,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Hubungi tim NALARA untuk kendala akun, jadwal, pembayaran, atau masalah teknis lainnya.',
          style: HelpCenterStyle.body,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('help-open-support'),
            onPressed: _openSupport,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              foregroundColor: HelpCenterStyle.green,
              overlayColor: Colors.transparent,
              textStyle: HelpCenterStyle.body.copyWith(
                color: HelpCenterStyle.green,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: HelpCenterStyle.green,
              ),
            ),
            child: Text(
              'Hubungi Support NALARA',
              style: HelpCenterStyle.body.copyWith(
                color: HelpCenterStyle.green,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: HelpCenterStyle.green,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
