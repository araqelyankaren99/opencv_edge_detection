import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_edge_detection_example/utils/image_processor.dart';
import 'package:opencv_edge_detection_example/presentation/result_screen.dart';
import 'package:opencv_edge_detection_example/utils/util.dart';
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
  int? _countdown;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
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
      ResolutionPreset.ultraHigh,
      enableAudio: false,
    );

    await _cameraController?.initialize();
    await _cameraController?.lockCaptureOrientation(
      DeviceOrientation.portraitUp,
    );
    await _cameraController?.setFlashMode(FlashMode.off);
    setState(() {});
  }

  Future<void> _onImageStream(CameraImage cameraImage) async {
    if (_isProcessing || _hasNavigated) {
      return;
    }

    _isProcessing = true;
    final outputFilePath = '$_appTempDirectoryPath/temp.jpeg';

    try {
      final edgeDetectionResult = await processCameraImage(
        cameraImage: cameraImage,
        outputFilePath: outputFilePath,
      );

      if (edgeDetectionResult == null) {
        return;
      }

      if (!mounted) return;

      _hasNavigated = true;
      _cameraController?.stopImageStream();

      if (Platform.isAndroid) {
        await rotateImage(File(outputFilePath), angle: 90);
      }

      if (!mounted) {
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
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _cameraPreviewWidget(),
          if (_countdown != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withValues(alpha: 0.5),
                child: Text(
                  _countdownText,
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 25,left: 15,right: 15),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _startStreaming,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text('Start streaming'),
                    ),
                  ),
                  Expanded(child: SizedBox()),
                  ElevatedButton(
                    onPressed: _stopStreaming,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text('Stop streaming'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Future<void> _startStreaming()async {
    int seconds = 3;
    setState(() {
      _countdown = seconds;
      _countdownText = 'Start streaming $seconds';
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds--;
      if (seconds > 0) {
        setState(() {
          _countdownText = 'Start streaming $seconds';
        });
      } else {
        timer.cancel();
        setState(() {
          _countdown = null;
        });
        _cameraController?.startImageStream(_onImageStream);
      }
    });
  }

  void _stopStreaming() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
  }

  Widget _cameraPreviewWidget() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return _loaderWidget();
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }
}
