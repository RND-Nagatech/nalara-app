import '../../../shared/errors/app_failure.dart';
import '../domain/teaching_guide.dart';

class TeachingGuideModel {
  final Map<String, dynamic> json;
  const TeachingGuideModel(this.json);

  bool _flag(String name) {
    final value = json[name];
    if (value is! bool) {
      throw const AppFailure(
        'Data panduan belum sesuai. Perbarui backend lalu muat ulang.',
        code: 'INVALID_RESPONSE',
      );
    }
    return value;
  }

  bool get dismissed => _flag('dismissed');

  TeachingGuide toEntity() => TeachingGuide(
    dismissed: dismissed,
    hasSubject: _flag('hasSubject'),
    hasStudent: _flag('hasStudent'),
    hasSchedule: _flag('hasSchedule'),
    hasTarget: _flag('hasTarget'),
    parentConnected: _flag('parentConnected'),
  );
}
