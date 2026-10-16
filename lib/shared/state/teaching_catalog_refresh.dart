import 'dart:async';

import 'package:flutter/widgets.dart';
import '../../utils/injector.dart';
import '../domain/teaching_catalog_changes.dart';

mixin TeachingCatalogRefresh<T extends StatefulWidget> on State<T> {
  StreamSubscription<void>? _catalogSubscription;

  void onTeachingCatalogChanged();

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<TeachingCatalogChanges>()) {
      _catalogSubscription = getIt<TeachingCatalogChanges>().stream.listen((_) {
        if (mounted) onTeachingCatalogChanged();
      });
    }
  }

  @override
  void dispose() {
    _catalogSubscription?.cancel();
    super.dispose();
  }
}
