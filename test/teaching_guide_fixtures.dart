import 'dart:async';
import 'package:nalara/features/teaching_guide/domain/teaching_guide.dart';

TeachingGuide guideValue({
  bool tutorialSeen = false,
  bool subject = false,
  bool student = false,
  bool schedule = false,
  bool target = false,
  bool parent = false,
}) => TeachingGuide(
  tutorialSeen: tutorialSeen,
  hasSubject: subject,
  hasStudent: student,
  hasSchedule: schedule,
  hasTarget: target,
  parentConnected: parent,
);

class TeachingGuideFake implements TeachingGuideRepository {
  TeachingGuide value;
  Object? loadError, saveError;
  int reads = 0;
  final saves = <bool>[];
  final pendingReads = <Completer<TeachingGuide>>[];
  Completer<bool>? pendingSave;
  TeachingGuideFake(this.value);

  @override
  Future<TeachingGuide> get() async {
    reads++;
    if (pendingReads.isNotEmpty) return pendingReads.removeAt(0).future;
    if (loadError != null) throw loadError!;
    return value;
  }

  @override
  Future<bool> acknowledgeTutorial() async {
    saves.add(true);
    if (saveError != null) throw saveError!;
    final result = pendingSave == null ? true : await pendingSave!.future;
    value = value.withTutorialSeen(result);
    return result;
  }
}
