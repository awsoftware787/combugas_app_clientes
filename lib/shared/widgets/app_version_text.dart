import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_version_service.dart';

class AppVersionText extends ConsumerWidget {
  const AppVersionText({
    super.key,
    this.color = Colors.white70,
    this.textAlign = TextAlign.center,
  });

  final Color color;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<String>(
    future: ref.watch(appVersionProvider),
    builder: (context, snapshot) {
      final version = snapshot.data;
      if (version == null || version.isEmpty) {
        return const SizedBox.shrink();
      }
      return Text(
        version,
        key: const ValueKey('app-version'),
        textAlign: textAlign,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      );
    },
  );
}
