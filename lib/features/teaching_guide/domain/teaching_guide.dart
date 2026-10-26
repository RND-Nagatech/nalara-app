enum TeachingGuideStep { subject, student, schedule, target }

class TeachingGuide {
  final bool tutorialSeen, hasSubject, hasStudent, hasSchedule, hasTarget;
  final bool parentConnected;

  const TeachingGuide({
    required this.tutorialSeen,
    required this.hasSubject,
    required this.hasStudent,
    required this.hasSchedule,
    required this.hasTarget,
    required this.parentConnected,
  });

  bool completed(TeachingGuideStep step) => switch (step) {
    TeachingGuideStep.subject => hasSubject,
    TeachingGuideStep.student => hasStudent,
    TeachingGuideStep.schedule => hasSchedule,
    TeachingGuideStep.target => hasTarget,
  };

  int get completedCount => TeachingGuideStep.values.where(completed).length;
  int get remainingCount => TeachingGuideStep.values.length - completedCount;
  bool canStart(TeachingGuideStep step) => switch (step) {
    TeachingGuideStep.subject || TeachingGuideStep.student => true,
    TeachingGuideStep.schedule ||
    TeachingGuideStep.target => hasSubject && hasStudent,
  };
  bool get isComplete => completedCount == TeachingGuideStep.values.length;
  TeachingGuideStep? get nextStep {
    for (final step in TeachingGuideStep.values) {
      if (!completed(step)) return step;
    }
    return null;
  }

  TeachingGuide withTutorialSeen(bool value) => TeachingGuide(
    tutorialSeen: value,
    hasSubject: hasSubject,
    hasStudent: hasStudent,
    hasSchedule: hasSchedule,
    hasTarget: hasTarget,
    parentConnected: parentConnected,
  );
}

abstract interface class TeachingGuideRepository {
  Future<TeachingGuide> get();
  Future<bool> acknowledgeTutorial();
}
