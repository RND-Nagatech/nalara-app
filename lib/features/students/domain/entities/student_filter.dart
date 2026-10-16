enum StudentFilter {
  active,
  archived,
  all;

  String? get status => switch (this) {
    active => 'active',
    archived => 'archived',
    all => null,
  };
}
