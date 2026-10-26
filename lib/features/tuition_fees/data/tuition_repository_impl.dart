import '../domain/tuition_fee.dart';
import '../domain/tuition_repository.dart';
import 'tuition_model.dart';
import 'tuition_remote_source.dart';

class TuitionRepositoryImpl implements TuitionRepository {
  final TuitionRemoteSource remote;
  TuitionRepositoryImpl(this.remote);
  @override
  Future<TuitionOverview> get(String studentId) async =>
      TuitionModel(await remote.get(studentId)).toEntity();
  @override
  Future<void> save(
    String studentId, {
    required int amount,
    required String dueDate,
    required String status,
    required int version,
  }) => remote.save(studentId, {
    'amount': amount,
    'dueDate': dueDate,
    'status': status,
    'version': version,
  });
}

class ParentTuitionReader implements TuitionReader {
  final TuitionRemoteSource remote;
  ParentTuitionReader(this.remote);
  @override
  Future<TuitionOverview> get(String studentId) async =>
      TuitionModel(await remote.get(studentId)).toEntity();
}
