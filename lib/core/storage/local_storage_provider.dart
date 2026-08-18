import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_storage.dart';

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw StateError('LocalStorage debe inicializarse antes de ejecutar la app.');
});
