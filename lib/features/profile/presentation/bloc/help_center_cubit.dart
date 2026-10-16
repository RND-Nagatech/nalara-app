import 'package:flutter_bloc/flutter_bloc.dart';
import '../content/help_topics.dart';

class HelpCenterState {
  final String query;
  final String? expandedId;
  final List<HelpTopic> source;
  const HelpCenterState({
    this.query = '',
    this.expandedId,
    this.source = helpTopics,
  });

  List<HelpTopic> get topics =>
      List.unmodifiable(source.where((topic) => topic.matches(query)));
}

class HelpCenterCubit extends Cubit<HelpCenterState> {
  HelpCenterCubit({List<HelpTopic> topics = helpTopics})
    : super(HelpCenterState(source: List.unmodifiable(topics)));

  void search(String query) {
    if (isClosed || query == state.query) return;
    emit(HelpCenterState(query: query, source: state.source));
  }

  void toggle(String id) {
    if (isClosed || !state.topics.any((topic) => topic.id == id)) return;
    emit(
      HelpCenterState(
        query: state.query,
        source: state.source,
        expandedId: state.expandedId == id ? null : id,
      ),
    );
  }
}
