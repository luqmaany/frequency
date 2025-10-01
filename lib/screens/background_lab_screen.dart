import 'package:flutter/material.dart';
import 'package:convey/widgets/celebration_explosions_background.dart';
import 'package:convey/widgets/retro_radio_button.dart';

class BackgroundLabScreen extends StatelessWidget {
  const BackgroundLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Lab'),
      ),
      body: Stack(
        children: [
          // Background
          const SizedBox.expand(
            child: CelebrationExplosionsBackground(
              burstsPerSecond: 6,
              strokeWidth: 2.0,
              ringSpacing: 8.0,
              baseOpacity: 0.10,
              highlightOpacity: 0.5,
              minEndRadiusFactor: 0.10,
              maxEndRadiusFactor: 0.40,
            ),
          ),
          // Buttons overlay
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Retro Radio Buttons',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RetroRadioButton(
                    label: 'STATION 1',
                    onPressed: () => print('Button 1 pressed'),
                    width: 140,
                    height: 55,
                  ),
                  const SizedBox(height: 20),
                  RetroRadioButton(
                    label: 'STATION 2',
                    onPressed: () => print('Button 2 pressed'),
                    width: 140,
                    height: 55,
                  ),
                  const SizedBox(height: 20),
                  RetroRadioButton(
                    label: 'STATION 3',
                    onPressed: () => print('Button 3 pressed'),
                    width: 140,
                    height: 55,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RetroRadioButton(
                        label: 'POWER',
                        onPressed: () => print('Power pressed'),
                        width: 100,
                        height: 45,
                      ),
                      const SizedBox(width: 20),
                      RetroRadioButton(
                        label: 'VOLUME',
                        onPressed: () => print('Volume pressed'),
                        width: 100,
                        height: 45,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
