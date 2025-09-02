import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

Uint8List convertCameraImageToUint8List(CameraImage cameraImage) {
  switch (cameraImage.format.group) {
    case ImageFormatGroup.bgra8888:
      return _convertBGRA8888ToBGRA8888Uint8List(cameraImage);
    case ImageFormatGroup.yuv420:
      return _convertYUV420ToBGRA8888Uint8List(cameraImage);
    case ImageFormatGroup.nv21:
      return _convertNV21ToUint8List(cameraImage);
    case ImageFormatGroup.jpeg:
      return _convertJPEGToUint8List(cameraImage);
    case ImageFormatGroup.unknown:
      return _convertUnknownToUint8List(cameraImage);
  }
}

Uint8List _convertBGRA8888ToBGRA8888Uint8List(CameraImage cameraImage){
  return cameraImage.planes[0].bytes;
}

Uint8List _convertYUV420ToBGRA8888Uint8List(CameraImage image) {
  final width = image.width;
  final height = image.height;

  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final yRowStride = yPlane.bytesPerRow;
  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel!;

  final bgra = Uint8List(width * height * 4);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final yIndex = y * yRowStride + x;
      final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

      if (yIndex >= yPlane.bytes.length ||
          uvIndex >= uPlane.bytes.length ||
          uvIndex >= vPlane.bytes.length) {
        continue;
      }

      final Y = yPlane.bytes[yIndex] & 0xFF;
      final U = uPlane.bytes[uvIndex] & 0xFF;
      final V = vPlane.bytes[uvIndex] & 0xFF;

      final c = Y - 16;
      final d = U - 128;
      final e = V - 128;

      int r = ((298 * c + 409 * e + 128) >> 8);
      int g = ((298 * c - 100 * d - 208 * e + 128) >> 8);
      int b = ((298 * c + 516 * d + 128) >> 8);

      // Apply brightness factor and clamp
      r = r.clamp(0, 255).toInt();
      g = g.clamp(0, 255).toInt();
      b = b.clamp(0, 255).toInt();

      final index = (y * width + x) * 4;
      bgra[index + 0] = b;
      bgra[index + 1] = g;
      bgra[index + 2] = r;
      bgra[index + 3] = 255;
    }
  }

  return bgra;
}

Uint8List _convertNV21ToUint8List(CameraImage image) {
  final width = image.width;
  final height = image.height;

  final yPlane = image.planes[0];
  final uvPlane = image.planes[1];

  final yBytes = yPlane.bytes;
  final uvBytes = uvPlane.bytes;

  final bgra = Uint8List(width * height * 4);

  final uvRowStride = uvPlane.bytesPerRow;
  final uvPixelStride = uvPlane.bytesPerPixel ?? 2;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final yIndex = y * yPlane.bytesPerRow + x;
      final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

      final Y = yBytes[yIndex] & 0xFF;
      final V = uvBytes[uvIndex] & 0xFF;
      final U = uvBytes[uvIndex + 1] & 0xFF;

      final c = (Y - 16).toInt().clamp(0, 255);
      final d = U - 128;
      final e = V - 128;

      int r = ((298 * c + 409 * e + 128) >> 8).clamp(0, 255);
      int g = ((298 * c - 100 * d - 208 * e + 128) >> 8).clamp(0, 255);
      int b = ((298 * c + 516 * d + 128) >> 8).clamp(0, 255);

      final pixelIndex = (y * width + x) * 4;
      bgra[pixelIndex + 0] = b;
      bgra[pixelIndex + 1] = g;
      bgra[pixelIndex + 2] = r;
      bgra[pixelIndex + 3] = 255;
    }
  }

  return bgra;
}

Uint8List _convertJPEGToUint8List(CameraImage image) {
  final jpegData = image.planes[0].bytes;
  final decoded = img.decodeImage(jpegData);
  if (decoded == null) {
    throw Exception('JPEG decoding failed');
  }

  final bgra = Uint8List(decoded.width * decoded.height * 4);
  int offset = 0;

  for (int y = 0; y < decoded.height; y++) {
    for (int x = 0; x < decoded.width; x++) {
      final pixel = decoded.getPixel(x, y);

      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;
      final a = pixel.a;

      bgra[offset++] = b.toInt();
      bgra[offset++] = g.toInt();
      bgra[offset++] = r.toInt();
      bgra[offset++] = a.toInt();
    }
  }

  return bgra;
}

Uint8List _convertUnknownToUint8List(CameraImage cameraImage) {
  return cameraImage.planes[0].bytes;
}

Future<File> rotateImage(
    File sourceImage, {
      required int angle,
    }) async {
  final bytes = await sourceImage.readAsBytes();

  final rotatedBytes = await Isolate.run(() {
    final original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception("Failed to decode image");
    }

    final rotated = img.copyRotate(original, angle: angle);
    return Uint8List.fromList(img.encodeJpg(rotated)); // or encodePng
  });

  await sourceImage.writeAsBytes(rotatedBytes);
  return sourceImage;
}