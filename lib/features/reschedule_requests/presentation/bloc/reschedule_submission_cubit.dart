import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/errors/app_failure.dart';

enum RescheduleSubmissionStatus { idle, sending, waiting, failed }

class RescheduleSubmissionState {
  final RescheduleSubmissionStatus status;
  final String? error;
  const RescheduleSubmissionState(this.status, {this.error});
  bool get busy => status == RescheduleSubmissionStatus.sending;
  bool get waiting => status == RescheduleSubmissionStatus.waiting;
  bool get locked => busy || waiting;
}

/// A successful/confirmed pending request cannot be submitted again, even in
/// the frame between the API response and closing the modal.
class RescheduleSubmissionCubit extends Cubit<RescheduleSubmissionState> {
  RescheduleSubmissionCubit()
    : super(const RescheduleSubmissionState(RescheduleSubmissionStatus.idle));

  Future<bool> send(
    Future<void> Function() submit,
    Future<bool> Function() checkPending,
  ) async {
    if (isClosed || state.locked) return false;
    emit(const RescheduleSubmissionState(RescheduleSubmissionStatus.sending));
    try {
      await submit();
    } catch (error) {
      if (isClosed) return false;
      var pending = error is AppFailure && error.code == 'RESCHEDULE_PENDING';
      if (!pending) {
        // A lost response can occur after commit. Read before allowing retry;
        // a failed recovery is not confirmation and must preserve the draft.
        try {
          pending = await checkPending();
        } catch (_) {
          /* original error */
        }
      }
      if (isClosed) return false;
      if (!pending) {
        emit(
          RescheduleSubmissionState(
            RescheduleSubmissionStatus.failed,
            error: error.toString(),
          ),
        );
        return false;
      }
    }
    if (isClosed) return false;
    emit(const RescheduleSubmissionState(RescheduleSubmissionStatus.waiting));
    return true;
  }
}
