import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/branding_logo.dart';

class BrandingLogoState {
  final BrandingLogo? logo;
  final bool loading, saving, initialized;
  final String? error;
  const BrandingLogoState({
    this.logo,
    this.loading = false,
    this.saving = false,
    this.initialized = false,
    this.error,
  });
  bool get busy => loading || saving;
}

class BrandingLogoCubit extends Cubit<BrandingLogoState> {
  final BrandingLogoRepository repository;
  final BrandingLogoPicker picker;
  int _generation = 0;
  BrandingLogoCubit(this.repository, this.picker)
    : super(const BrandingLogoState());
  Future<void> load() async {
    if (isClosed || state.saving) return;
    final generation = ++_generation;
    final previous = state;
    emit(
      BrandingLogoState(
        logo: previous.logo,
        loading: true,
        initialized: previous.initialized,
      ),
    );
    try {
      final logo = await repository.read();
      if (!isClosed && generation == _generation) {
        emit(BrandingLogoState(logo: logo, initialized: true));
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          BrandingLogoState(
            logo: previous.logo,
            initialized: previous.initialized,
            error: error.toString(),
          ),
        );
      }
    }
  }

  Future<bool> choose({required bool Function() isCurrent}) async {
    if (isClosed || state.busy || !isCurrent()) return false;
    final previous = state;
    final generation = ++_generation;
    emit(
      BrandingLogoState(
        logo: previous.logo,
        saving: true,
        initialized: previous.initialized,
      ),
    );
    try {
      final selected = await picker.pick();
      if (isClosed || generation != _generation) return false;
      if (selected == null || !isCurrent()) {
        emit(previous);
        return false;
      }
      final logo = await repository.upload(selected);
      if (!isClosed && generation == _generation) {
        emit(BrandingLogoState(logo: logo, initialized: true));
      }
      return true;
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          BrandingLogoState(
            logo: previous.logo,
            initialized: previous.initialized,
            error: error.toString(),
          ),
        );
      }
      return false;
    }
  }

  Future<bool> remove() async {
    if (isClosed || state.busy) return false;
    final previous = state;
    final generation = ++_generation;
    emit(
      BrandingLogoState(
        logo: previous.logo,
        saving: true,
        initialized: previous.initialized,
      ),
    );
    try {
      await repository.remove();
      if (!isClosed && generation == _generation) {
        emit(const BrandingLogoState(initialized: true));
      }
      return true;
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          BrandingLogoState(
            logo: previous.logo,
            initialized: previous.initialized,
            error: error.toString(),
          ),
        );
      }
      return false;
    }
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
