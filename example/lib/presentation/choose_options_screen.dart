import 'package:flutter/material.dart';
import 'package:opencv_edge_detection_example/presentation/camera_processing_screen.dart';
import 'package:opencv_edge_detection_example/presentation/image_picker_screen.dart';
import 'package:opencv_edge_detection_example/presentation/scan_image_page.dart';

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
            SizedBox(height: 5),
            ElevatedButton(
              child: Text('Live image'),
              onPressed: () => _onImage(context),
            ),
            SizedBox(height: 5),
            ElevatedButton(
              child: Text('Image picker'),
              onPressed: () => _onImagePicker(context),
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

  void _onImagePicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ImagePickerScreen()),
    );
  }
}
