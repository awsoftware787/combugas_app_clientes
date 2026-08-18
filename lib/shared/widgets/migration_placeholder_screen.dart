import 'package:flutter/material.dart';

class MigrationPlaceholderScreen extends StatelessWidget {
  const MigrationPlaceholderScreen({
    super.key,
    this.title = 'Combugas Clientes',
    this.message = 'Funcionalidad pendiente de migración.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
