import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/reschedule_request.dart';

abstract final class RescheduleRequestsStyle {
  static const cream = Color(0xFFF7F3EC),
      green = Color(0xFF155A49),
      muted = Color(0xFF6E7377),
      sage = Color(0xFFEDF5EF),
      red = Color(0xFFB83432);
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.5,
    color: muted,
  );
}

class RescheduleRequestCard extends StatelessWidget {
  final RescheduleRequest request;
  final String timezone;
  final String? studentName, studentGrade;
  final bool parent, busy;
  final VoidCallback? onApprove, onReject, onPropose;
  final VoidCallback? onCancel, onAccept, onDecline;

  const RescheduleRequestCard({
    super.key,
    required this.request,
    required this.timezone,
    this.studentName,
    this.studentGrade,
    this.parent = false,
    this.busy = false,
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
          : 'Menunggu persetujuan',
    'approved' => 'Disetujui',
    'rejected' => 'Ditolak',
    'cancelled' => 'Dibatalkan',
    'expired' => 'Kedaluwarsa',
    _ => request.status,
  };

  String _time(DateTime start, DateTime end) {
    final localStart = DateTimeUtils.local(start, timezone);
    final localEnd = DateTimeUtils.local(end, timezone);
    final sameDay =
        localStart.year == localEnd.year &&
        localStart.month == localEnd.month &&
        localStart.day == localEnd.day;
    return '${DateTimeUtils.full(start, timezone)} – '
        '${sameDay ? DateTimeUtils.time(end, timezone) : DateTimeUtils.full(end, timezone)}';
  }

  @override
  Widget build(BuildContext context) {
    final name = request.studentName.trim().isEmpty
        ? studentName?.trim() ?? ''
        : request.studentName;
    final grade = request.studentGrade.trim().isEmpty
        ? studentGrade?.trim() ?? ''
        : request.studentGrade;
    final pending = request.status == 'pending';
    return NalaraSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name.isEmpty ? 'Siswa' : name,
            style: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (grade.isNotEmpty)
            Text(grade, style: RescheduleRequestsStyle.body),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              key: ValueKey('reschedule-status-${request.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: request.status == 'approved'
                    ? RescheduleRequestsStyle.sage
                    : pending
                    ? const Color(0xFFFFF5DF)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _status,
                style: RescheduleRequestsStyle.body.copyWith(
                  color: request.status == 'approved'
                      ? RescheduleRequestsStyle.green
                      : pending
                      ? const Color(0xFF80632C)
                      : RescheduleRequestsStyle.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Jadwal awal: ${_time(request.oldStartAt, request.oldEndAt)}',
            style: RescheduleRequestsStyle.body,
          ),
          const SizedBox(height: 5),
          Text(
            'Jadwal diminta: ${_time(request.requestedStartAt, request.requestedEndAt)}',
            style: RescheduleRequestsStyle.body.copyWith(
              color: RescheduleRequestsStyle.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text('Zona waktu: $timezone', style: RescheduleRequestsStyle.body),
          const SizedBox(height: 10),
          Text(
            'Alasan: ${request.reason}',
            style: RescheduleRequestsStyle.body,
          ),
          if (request.hasProposal) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RescheduleRequestsStyle.sage,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Tawaran waktu dari Guru: '
                '${_time(request.proposedStartAt!, request.proposedEndAt!)}',
                style: RescheduleRequestsStyle.body.copyWith(
                  color: RescheduleRequestsStyle.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (request.reviewNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Catatan Guru: ${request.reviewNote}',
              style: RescheduleRequestsStyle.body,
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
          if (pending) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (parent && request.hasProposal) ...[
                  OutlinedButton(
                    key: ValueKey('reschedule-decline-${request.id}'),
                    onPressed: busy ? null : onDecline,
                    child: const Text('Tolak tawaran'),
                  ),
                  FilledButton(
                    key: ValueKey('reschedule-accept-${request.id}'),
                    onPressed: busy ? null : onAccept,
                    child: const Text('Terima tawaran'),
                  ),
                ],
                if (parent)
                  OutlinedButton(
                    key: ValueKey('reschedule-cancel-${request.id}'),
                    onPressed: busy ? null : onCancel,
                    child: const Text('Batalkan permintaan'),
                  )
                else ...[
                  OutlinedButton(
                    key: ValueKey('reschedule-reject-${request.id}'),
                    onPressed: busy ? null : onReject,
                    child: const Text('Tolak'),
                  ),
                  if (!request.hasProposal) ...[
                    FilledButton(
                      key: ValueKey('reschedule-approve-${request.id}'),
                      onPressed: busy ? null : onApprove,
                      child: const Text('Setujui'),
                    ),
                    OutlinedButton.icon(
                      key: ValueKey('reschedule-propose-${request.id}'),
                      onPressed: busy ? null : onPropose,
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: const Text('Tawarkan waktu lain'),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
