import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

base class _Coordinate extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;
}

base class _NativeDetectionResult extends Struct {
  external Pointer<_Coordinate> topLeft;
  external Pointer<_Coordinate> topRight;
  external Pointer<_Coordinate> bottomLeft;
  external Pointer<_Coordinate> bottomRight;
}

class EdgeDetectionResult {
  EdgeDetectionResult({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  Offset topLeft;
  Offset topRight;
  Offset bottomLeft;
  Offset bottomRight;

  @override
  String toString() =>
      'EdgeDetectionResult('
          'topLeft : $topLeft;'
          'topRight : $topRight;'
          'bottomLeft : $bottomLeft;'
          'bottomRight : $bottomRight)';
}

typedef _CDetectDocumentEdgesExCppStreamingFunc =
Pointer<_NativeDetectionResult> Function(
    Int32,
    Int32,
    Int32,
    Pointer<Uint8>,
    Pointer<Utf8>,
    );

typedef _DartDetectDocumentEdgesStreamingExFunc =
Pointer<_NativeDetectionResult> Function(
    int,
    int,
    int,
    Pointer<Uint8>,
    Pointer<Utf8>,
    );

typedef _CDetectDocumentEdgesFunc =
Pointer<_NativeDetectionResult> Function(Pointer<Utf8>, Pointer<Utf8>);

typedef _DetectDocumentEdgesFunc =
Pointer<_NativeDetectionResult> Function(Pointer<Utf8>, Pointer<Utf8>);

class OpencvEdgeDetection {
  factory OpencvEdgeDetection() {
    _instance ??= OpencvEdgeDetection._internal();
    return _instance!;
  }

  OpencvEdgeDetection._internal();

  static OpencvEdgeDetection? _instance;

  Future<EdgeDetectionResult?> processLiveStreamImage({
    required Uint8List bytes,
    required String outputPathStr,
    required int imageWidth,
    required int imageHeight,
  }) async {
    final int bytesPerPixel = 4;

    final edgeDetectionResult = await Isolate.run<EdgeDetectionResult>(
          () => _processImageInStreaming(
        width: imageWidth,
        height: imageHeight,
        bytesPerPixel: bytesPerPixel,
        rgbBytes: bytes,
        outputPathStr: outputPathStr,
      ),
    );

    final top = edgeDetectionResult.topLeft.dy;
    final left = edgeDetectionResult.bottomRight.dx;

    if (top == 0.0 && left == 1.0) {
      return null;
    }
    return edgeDetectionResult;
  }

  Future<EdgeDetectionResult?> processImage(
      String inputFilePath,
      String outputFilePath,
      ) async {
    if (inputFilePath.isEmpty) {
      return null;
    }

    final edgeDetectionResult = await Isolate.run<EdgeDetectionResult>(
          () =>
          _processImage(inputImage: inputFilePath, outputImage: outputFilePath),
    );

    final top = edgeDetectionResult.topLeft.dy;
    final left = edgeDetectionResult.bottomRight.dx;

    if (top == 0.0 && left == 1.0) {
      return null;
    }
    return edgeDetectionResult;
  }
}

Future<EdgeDetectionResult> _processImageInStreaming({
  required int width,
  required int height,
  required int bytesPerPixel,
  required Uint8List rgbBytes,
  required String outputPathStr,
}) async {
  final nativeLib =
  Platform.isAndroid
      ? DynamicLibrary.open('libopencv_edge_detection.so')
      : DynamicLibrary.process();

  final detectDocumentStreaming = nativeLib.lookupFunction<
      _CDetectDocumentEdgesExCppStreamingFunc,
      _DartDetectDocumentEdgesStreamingExFunc
  >('detect_document_edges_streaming');

  final Pointer<Uint8> imgPointer = malloc.allocate<Uint8>(rgbBytes.length);
  try {
    imgPointer.asTypedList(rgbBytes.length).setAll(0, rgbBytes);

    final Pointer<Utf8> outputPathPtr = outputPathStr.toNativeUtf8();
    try {
      final Pointer<_NativeDetectionResult> nativeResult =
      detectDocumentStreaming(
        width,
        height,
        bytesPerPixel,
        imgPointer,
        outputPathPtr,
      );

      final result = nativeResult.ref;

      return EdgeDetectionResult(
        topLeft: Offset(result.topLeft.ref.x, result.topLeft.ref.y),
        topRight: Offset(result.topRight.ref.x, result.topRight.ref.y),
        bottomLeft: Offset(result.bottomLeft.ref.x, result.bottomLeft.ref.y),
        bottomRight: Offset(result.bottomRight.ref.x, result.bottomRight.ref.y),
      );
    } finally {
      malloc.free(outputPathPtr);
    }
  } finally {
    malloc.free(imgPointer);
  }
}

Future<EdgeDetectionResult> _processImage({
  required String inputImage,
  required String outputImage,
}) async {
  final nativeLib =
  Platform.isAndroid
      ? DynamicLibrary.open('libopencv_edge_detection.so')
      : DynamicLibrary.process();

  final detectDocument = nativeLib
      .lookupFunction<_CDetectDocumentEdgesFunc, _DetectDocumentEdgesFunc>(
    'detect_document_edges',
  );
  final Pointer<Utf8> inputPathPtr = inputImage.toNativeUtf8();
  try {
    final Pointer<Utf8> outputPathPtr = outputImage.toNativeUtf8();
    try {
      final Pointer<_NativeDetectionResult> nativeResult =
      detectDocument(
        inputPathPtr,
        outputPathPtr,
      );
      final result = nativeResult.ref;
      return EdgeDetectionResult(
        topLeft: Offset(result.topLeft.ref.x, result.topLeft.ref.y),
        topRight: Offset(result.topRight.ref.x, result.topRight.ref.y),
        bottomLeft: Offset(result.bottomLeft.ref.x, result.bottomLeft.ref.y),
        bottomRight: Offset(result.bottomRight.ref.x, result.bottomRight.ref.y),
      );
    } finally {
      malloc.free(outputPathPtr);
    }
  } finally {
    malloc.free(inputPathPtr);
  }
}
