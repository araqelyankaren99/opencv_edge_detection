import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_edge_detection_example/utils/image_processor.dart';
import 'package:opencv_edge_detection_example/presentation/result_screen.dart';
import 'package:opencv_edge_detection_example/utils/util.dart';
import 'package:path_provider/path_provider.dart';

class ScanImagePage extends StatefulWidget {
  const ScanImagePage({super.key});

  @override
  State<ScanImagePage> createState() => _ScanImagePageState();
}

class _ScanImagePageState extends State<ScanImagePage> {
  CameraController? _controller;
  late String _appTempDirectoryPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final directory = await getTemporaryDirectory();
    _appTempDirectoryPath = directory.path;
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return;
    }
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.ultraHigh,
      enableAudio: false,
    );
    await _controller?.initialize();
    await _controller?.lockCaptureOrientation(DeviceOrientation.portraitUp);
    _controller?.setFlashMode(FlashMode.off);
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _detectEdgesEx() async {
    if (_controller?.value.isInitialized == true &&
        _controller?.value.isTakingPicture == false) {
      _isLoading = true;
      setState(() {});
      final captureImageFile = await _controller?.takePicture();
      if (captureImageFile == null) {
        _isLoading = false;
        setState(() {});
        return;
      }
      final captureImageFilePath = captureImageFile.path;
      if (!mounted || captureImageFilePath.isEmpty) {
        return;
      }

      imageCache.clear();

      final tempFilePath = '$_appTempDirectoryPath/temp.jpeg';
      final edgeDetectionResult = await processLiveImage(inputPath:  captureImageFilePath,outputPath:  tempFilePath);
      if (edgeDetectionResult == null) {
        _isLoading = false;
        setState(() {});
        return;
      }
      if (!mounted) {
        return;
      }
      await rotateImage(File(tempFilePath), angle: 270);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ResultScreen(croppedFilePath: tempFilePath),
        ),
            (_) => false,
      );
    }
  }

  Widget _cameraWidget() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  Widget _loaderWidget() {
    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.white.withAlpha((0.5 * 255).toInt()),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _controller == null
              ? _loaderWidget()
              : _controller?.value.isInitialized == false
              ? _loaderWidget()
              : Stack(
                children: [
                  _cameraWidget(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: _isLoading ?
                       CircularProgressIndicator():
                      ElevatedButton(
                        onPressed: _detectEdgesEx,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            Icon(Icons.camera_alt),
                            SizedBox(width: 5),
                            Text('Pick image'),
                          ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
