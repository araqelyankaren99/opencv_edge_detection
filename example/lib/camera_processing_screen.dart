import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_edge_detection_example/image_processor.dart';
import 'package:opencv_edge_detection_example/result_screen.dart';
import 'package:opencv_edge_detection_example/util.dart';
import 'package:path_provider/path_provider.dart';

class CameraProcessingScreen extends StatefulWidget {
  const CameraProcessingScreen({super.key});

  @override
  State<CameraProcessingScreen> createState() => _CameraProcessingScreenState();
}

class _CameraProcessingScreenState extends State<CameraProcessingScreen> {
  CameraController? _cameraController;
  late String _appTempDirectoryPath;
  bool _isProcessing = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _cameraController?.dispose();
    _deleteTempFile();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final directory = await getTemporaryDirectory();
    _appTempDirectoryPath = directory.path;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController?.initialize();
    await _cameraController?.lockCaptureOrientation(DeviceOrientation.portraitUp);
    await _cameraController?.setFlashMode(FlashMode.off);
    setState(() {});
    await Future.delayed(Duration(seconds: 2));
    _cameraController?.startImageStream(_onImageStream);
  }

  Future<void> _onImageStream(CameraImage cameraImage) async {
    if (_isProcessing || _hasNavigated) {
      return;
    }

    _isProcessing = true;
    final outputFilePath = '$_appTempDirectoryPath/temp.jpeg';

    try {
      final edgeDetectionResult = await processImage(
        cameraImage,
        outputFilePath,
      );

      if (edgeDetectionResult == null) {
        return;
      }

      if (!mounted) return;

      _hasNavigated = true;
      _cameraController?.stopImageStream();

      if(Platform.isAndroid){
        await rotateImage(File(outputFilePath),angle: 90);
      }

      if(!mounted){
        return;
      }

      imageCache.clear();
      imageCache.clearLiveImages();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ResultScreen(croppedFilePath: outputFilePath),
        ),
            (_) => false,
      );
    } catch (_) {
      await _deleteTempFile();
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _deleteTempFile() async {
    final file = File('$_appTempDirectoryPath/temp.jpeg');
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? _loaderWidget()
          : CameraPreview(_cameraController!),
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
}
