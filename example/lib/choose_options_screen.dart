import 'package:flutter/material.dart';
import 'package:opencv_edge_detection_example/camera_processing_screen.dart';
import 'package:opencv_edge_detection_example/scan_image_page.dart';

class ChooseOptionsScreen extends StatelessWidget {
  const ChooseOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              child: Text('Image streaming'),
              onPressed: () => _onImageStreaming(context),
            ),
            ElevatedButton(
              child: Text('Live image'),
              onPressed: () => _onImage(context),
            ),
          ],
        ),
      ),
    );
  }

  void _onImageStreaming(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CameraProcessingScreen()),
    );
  }

  void _onImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanImagePage()),
    );
  }
}
