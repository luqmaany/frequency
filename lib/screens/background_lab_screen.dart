import 'package:flutter/material.dart';
import 'package:convey/widgets/dual_radial_interference_background.dart';

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
          child: DualRadialInterferenceBackground(
            verticalPositionFactor: 0.5,
            sourcesHorizontalOffsetFactor: 0.52,
            colorCyclesPerLoop: 0.05,
          ),
        ),
      ),
    );
  }
}
