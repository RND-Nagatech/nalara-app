import 'package:nalara/features/tuition_fees/domain/tuition_fee.dart';
import 'package:nalara/features/tuition_fees/domain/tuition_repository.dart';

class TuitionFake implements TuitionRepository {
  TuitionOverview value = const TuitionOverview(
    fee: null,
    teacherName: 'Guru',
    teacherPhone: '+6281234567890',
    timezone: 'Asia/Jakarta',
    automaticReminders: true,
  );
  final reads = <String>[];
  int saves = 0;
  Object? error;
  @override
  Future<TuitionOverview> get(String studentId) async {
    reads.add(studentId);
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<void> save(
    String studentId, {
    required int amount,
    required String dueDate,
    required String status,
    required int version,
  }) async {
    if (error != null) throw error!;
    saves++;
    value = TuitionOverview(
      fee: TuitionFee(
        id: 'fee',
        studentId: studentId,
        dueDate: dueDate,
        status: status,
        amount: amount,
        version: version + 1,
      ),
      teacherName: value.teacherName,
      teacherPhone: value.teacherPhone,
      timezone: value.timezone,
      automaticReminders: value.automaticReminders,
    );
  }
}
