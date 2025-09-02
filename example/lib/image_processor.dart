import 'package:camera/camera.dart';
import 'package:opencv_edge_detection/opencv_edge_detection.dart';
import 'package:opencv_edge_detection_example/util.dart';

Future<EdgeDetectionResult?> processImage(CameraImage cameraImage , String outputFilePath) async {
  final bytes = convertCameraImageToUint8List(cameraImage);
  final width = cameraImage.width;
  final height = cameraImage.height;
  final edgeDetectionResult = await OpencvEdgeDetection().processLiveStreamImage(
    bytes: bytes,
    outputPathStr: outputFilePath,
    imageHeight: height,
    imageWidth: width,
  );

  return edgeDetectionResult;
}