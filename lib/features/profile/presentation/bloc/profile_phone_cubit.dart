import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/value_objects/phone_number.dart';
import '../../domain/teacher_profile_repository.dart';

class ProfilePhoneState {
  final bool editing, saving;
  final String draft;
  final String? error;
  const ProfilePhoneState({
    this.editing = false,
    this.saving = false,
    this.draft = '',
    this.error,
  });
  bool get canSave =>
      editing && !saving && PhoneNumber.normalize(draft) != null;
}

class ProfilePhoneCubit extends Cubit<ProfilePhoneState> {
  final TeacherProfileRepository repository;
  int _generation = 0;
  ProfilePhoneCubit(this.repository) : super(const ProfilePhoneState());

  void edit(String? phone) {
    if (state.saving) return;
    _generation++;
    emit(ProfilePhoneState(editing: true, draft: phone ?? ''));
  }

  void change(String draft) {
    if (!state.editing || state.saving) return;
    emit(ProfilePhoneState(editing: true, draft: draft));
  }

  void cancel() {
    _generation++;
    if (!isClosed) emit(const ProfilePhoneState());
  }

  Future<String?> save() async {
    if (!state.canSave) return null;
    final generation = ++_generation;
    final draft = state.draft;
    emit(ProfilePhoneState(editing: true, saving: true, draft: draft));
    try {
      final phone = await repository.updatePhone(draft);
      if (isClosed || generation != _generation) return null;
      emit(const ProfilePhoneState());
      return phone;
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          ProfilePhoneState(
            editing: true,
            draft: draft,
            error: error.toString(),
          ),
        );
      }
      return null;
    }
  }
}
