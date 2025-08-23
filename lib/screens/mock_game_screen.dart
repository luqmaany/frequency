import 'package:flutter/material.dart';

class MockGameScreen extends StatelessWidget {
  final String title;

  const MockGameScreen({super.key, this.title = 'Mock Game'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_esports, size: 80),
            const SizedBox(height: 16),
            const Text('This is a mock game screen'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
