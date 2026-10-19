import '../domain/teaching_guide.dart';
import 'teaching_guide_model.dart';
import 'teaching_guide_remote_source.dart';

class TeachingGuideRepositoryImpl implements TeachingGuideRepository {
  final TeachingGuideRemoteSource source;
  const TeachingGuideRepositoryImpl(this.source);

  @override
  Future<TeachingGuide> get() async =>
      TeachingGuideModel(await source.get()).toEntity();

  @override
  Future<bool> setDismissed(bool dismissed) async =>
      TeachingGuideModel(await source.setDismissed(dismissed)).dismissed;
}
