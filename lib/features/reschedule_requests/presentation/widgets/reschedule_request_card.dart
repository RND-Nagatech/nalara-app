import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../utils/color.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/reschedule_request.dart';

abstract final class RescheduleRequestsStyle {
  static const cream = NalaraColors.cream,
      green = NalaraColors.green,
      muted = NalaraColors.muted,
      sage = NalaraColors.lightGreen,
      red = NalaraColors.danger;
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12.5,
    height: 1.5,
    color: muted,
  );
}

class RescheduleRequestCard extends StatelessWidget {
  final RescheduleRequest request;
  final String timezone;
  final String? studentName, studentGrade;
  final bool parent, busy, grouped, showDivider;
  final BorderRadius borderRadius;
  final VoidCallback? onApprove,
      onReject,
      onPropose,
      onCancel,
      onAccept,
      onDecline;
  const RescheduleRequestCard({
    super.key,
    required this.request,
    required this.timezone,
    this.studentName,
    this.studentGrade,
    this.parent = false,
    this.busy = false,
    this.grouped = false,
    this.showDivider = false,
    this.borderRadius = BorderRadius.zero,
    this.onApprove,
    this.onReject,
    this.onPropose,
    this.onCancel,
    this.onAccept,
    this.onDecline,
  });

  String get _status => switch (request.status) {
    'pending' =>
      request.hasProposal
          ? 'Menunggu jawaban Orang Tua'
          : 'Menunggu persetujuan Guru',
    'approved' => 'Disetujui',
    'rejected' => 'Ditolak',
    'cancelled' => 'Dibatalkan',
    'expired' => 'Kedaluwarsa',
    _ => request.status,
  };

  String _time(DateTime start, DateTime end) {
    final a = DateTimeUtils.local(start, timezone),
        b = DateTimeUtils.local(end, timezone);
    final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
    return '${DateTimeUtils.full(start, timezone)} – ${sameDay ? DateTimeUtils.time(end, timezone) : DateTimeUtils.full(end, timezone)}';
  }

  Widget _interval(
    String label,
    DateTime start,
    DateTime end, {
    bool emphasis = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RescheduleRequestsStyle.body.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          _time(start, end),
          style: RescheduleRequestsStyle.body.copyWith(
            color: emphasis ? NalaraColors.ink : NalaraColors.muted,
            fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final name = request.studentName.trim().isEmpty
        ? studentName?.trim() ?? ''
        : request.studentName;
    final grade = request.studentGrade.trim().isEmpty
        ? studentGrade?.trim() ?? ''
        : request.studentGrade;
    final pending = request.status == 'pending';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          name.isEmpty ? 'Siswa' : name,
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: NalaraColors.ink,
          ),
        ),
        if (grade.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(grade, style: RescheduleRequestsStyle.body),
        ],
        const SizedBox(height: 5),
        Text(
          _status,
          key: ValueKey('reschedule-status-${request.id}'),
          style: RescheduleRequestsStyle.body.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: pending
                ? NalaraColors.sessionAmber
                : request.status == 'approved'
                ? NalaraColors.green
                : NalaraColors.muted,
          ),
        ),
        _interval('Jadwal awal', request.oldStartAt, request.oldEndAt),
        _interval(
          'Waktu yang diminta',
          request.requestedStartAt,
          request.requestedEndAt,
          emphasis: true,
        ),
        if (request.hasProposal)
          _interval(
            'Tawaran waktu dari Guru',
            request.proposedStartAt!,
            request.proposedEndAt!,
            emphasis: true,
          ),
        const SizedBox(height: 6),
        Text(
          'Zona waktu: $timezone',
          style: RescheduleRequestsStyle.body.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 10),
        Text(
          'Alasan: ${request.reason}',
          style: RescheduleRequestsStyle.body.copyWith(color: NalaraColors.ink),
        ),
        if (request.reviewNote.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Catatan Guru: ${request.reviewNote}',
            style: RescheduleRequestsStyle.body,
          ),
        ],
        if (busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (pending) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (parent && request.hasProposal) ...[
                FilledButton(
                  key: ValueKey('reschedule-accept-${request.id}'),
                  onPressed: busy ? null : onAccept,
                  child: const Text('Terima tawaran'),
                ),
                TextButton(
                  key: ValueKey('reschedule-decline-${request.id}'),
                  onPressed: busy ? null : onDecline,
                  child: const Text('Tolak tawaran'),
                ),
              ],
              if (parent)
                TextButton(
                  key: ValueKey('reschedule-cancel-${request.id}'),
                  onPressed: busy ? null : onCancel,
                  child: const Text('Batalkan permintaan'),
                )
              else ...[
                if (!request.hasProposal)
                  FilledButton(
                    key: ValueKey('reschedule-approve-${request.id}'),
                    onPressed: busy ? null : onApprove,
                    child: const Text('Setujui'),
                  ),
                TextButton(
                  key: ValueKey('reschedule-reject-${request.id}'),
                  onPressed: busy ? null : onReject,
                  child: const Text('Tolak'),
                ),
                if (!request.hasProposal)
                  TextButton(
                    key: ValueKey('reschedule-propose-${request.id}'),
                    onPressed: busy ? null : onPropose,
                    child: const Text('Tawarkan waktu lain'),
                  ),
              ],
            ],
          ),
        ],
      ],
    );
    if (!grouped) return NalaraSurfaceCard(child: content);
    return Material(
      color: NalaraColors.surface,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.all(16), child: content),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                key: ValueKey('reschedule-divider-${request.id}'),
                height: 1,
                thickness: 1,
                color: NalaraColors.headerDivider,
              ),
            ),
        ],
      ),
    );
  }
}
