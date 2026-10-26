import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/app_timezones.dart';
import '../../domain/teacher_profile_repository.dart';

class ProfileTimezoneState {
  final String saved, draft;
  final bool saving;
  final String? error;
  const ProfileTimezoneState({
    required this.saved,
    required this.draft,
    this.saving = false,
    this.error,
  });
  bool get canSave => !saving && draft != saved && AppTimezones.supports(draft);
}

class ProfileTimezoneCubit extends Cubit<ProfileTimezoneState> {
  final TeacherProfileRepository repository;
  final void Function(String)? onSaved;
  ProfileTimezoneCubit(this.repository, String timezone, {this.onSaved})
    : super(ProfileTimezoneState(saved: timezone, draft: timezone));

  void select(String timezone) {
    if (isClosed || state.saving || !AppTimezones.supports(timezone)) return;
    emit(ProfileTimezoneState(saved: state.saved, draft: timezone));
  }

  Future<String?> save() async {
    if (isClosed || !state.canSave) return null;
    final saved = state.saved, draft = state.draft;
    emit(ProfileTimezoneState(saved: saved, draft: draft, saving: true));
    try {
      final timezone = await repository.updateTimezone(draft);
      // Confirmed settings outlive their editor. The session-guarded owner
      // callback must never access a widget or BuildContext.
      onSaved?.call(timezone);
      if (isClosed) return null;
      emit(ProfileTimezoneState(saved: timezone, draft: timezone));
      return timezone;
    } catch (error) {
      if (!isClosed) {
        emit(
          ProfileTimezoneState(
            saved: saved,
            draft: draft,
            error: error.toString(),
          ),
        );
      }
      return null;
    }
  }
}
