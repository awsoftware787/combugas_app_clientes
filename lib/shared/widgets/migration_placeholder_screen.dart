import 'package:flutter/material.dart';

class MigrationPlaceholderScreen extends StatelessWidget {
  const MigrationPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Combugas Clientes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
