import 'package:flutter/material.dart';
import 'package:convey/widgets/celebration_explosions_background.dart';

class BackgroundLabScreen extends StatelessWidget {
  const BackgroundLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Lab'),
      ),
      body: const Center(
        child: SizedBox.expand(
          child: CelebrationExplosionsBackground(
            burstsPerSecond: 3.5,
            strokeWidth: 2.0,
            ringSpacing: 8.0,
            baseOpacity: 0.10,
            highlightOpacity: 0.55,
          ),
        ),
      ),
    );
  }
}
