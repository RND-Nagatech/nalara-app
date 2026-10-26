import 'tuition_fee.dart';

abstract class TuitionReader {
  Future<TuitionOverview> get(String studentId);
}

abstract class TuitionRepository implements TuitionReader {
  Future<void> save(
    String studentId, {
    required int amount,
    required String dueDate,
    required String status,
    required int version,
  });
}
