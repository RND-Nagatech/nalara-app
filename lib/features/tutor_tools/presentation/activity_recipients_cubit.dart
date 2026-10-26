import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/load_activity_options.dart';

class ActivityRecipientsState {
  final Set<String> studentIds;
  final String? groupId, notice;
  ActivityRecipientsState({
    Iterable<String> studentIds = const [],
    this.groupId,
    this.notice,
  }) : studentIds = Set.unmodifiable(studentIds);
}

class ActivityRecipientsCubit extends Cubit<ActivityRecipientsState> {
  ActivityOptions _options;
  final bool locked;
  ActivityRecipientsCubit(ActivityOptions options, {String? studentId})
    : _options = options,
      locked = studentId != null,
      super(ActivityRecipientsState(studentIds: [?studentId]));

  void updateOptions(ActivityOptions options) {
    if (isClosed) return;
    _options = options;
    emit(
      ActivityRecipientsState(
        studentIds: state.studentIds,
        groupId: state.groupId,
        notice:
            state.groupId != null &&
                !options.groups.any((g) => g.id == state.groupId)
            ? 'Grup tidak lagi tersedia. Pilihan siswa tetap disimpan; periksa kembali sebelum membagikan.'
            : state.notice,
      ),
    );
  }

  void selectGroup(String? id) {
    if (isClosed || locked) return;
    if (id == null || id.isEmpty) {
      emit(ActivityRecipientsState(studentIds: state.studentIds));
      return;
    }
    final group = _options.groups.where((g) => g.id == id).firstOrNull;
    if (group == null) {
      emit(
        ActivityRecipientsState(
          studentIds: state.studentIds,
          notice:
              'Grup tidak tersedia. Pilih grup lain atau pilih siswa secara manual.',
        ),
      );
      return;
    }
    final ids = group.activeMemberIds(_options.students);
    final skipped = group.studentIds.length - ids.length;
    emit(
      ActivityRecipientsState(
        studentIds: ids,
        groupId: id,
        notice: ids.isEmpty
            ? 'Belum ada anggota aktif pada grup ini. Pilih siswa atau perbarui grup.'
            : skipped > 0
            ? '${ids.length} siswa aktif dipilih. $skipped anggota tidak aktif/tidak tersedia dilewati.'
            : '${ids.length} anggota grup dipilih. Anda masih bisa menyesuaikan pilihan siswa.',
      ),
    );
  }

  void selectStudents(Set<String> ids) {
    if (!isClosed && !locked) emit(ActivityRecipientsState(studentIds: ids));
  }

  String? validate(Set<String>? ids) {
    if (ids == null || ids.isEmpty) return 'Pilih minimal satu siswa';
    if (ids.length > 100) return 'Maksimal 100 siswa per aktivitas';
    final active = _options.students
        .where((s) => s.status == 'active')
        .map((s) => s.id)
        .toSet();
    if (ids.any((id) => !active.contains(id))) {
      return 'Pilihan siswa tidak lagi aktif/tersedia. Periksa kembali.';
    }
    return null;
  }
}
