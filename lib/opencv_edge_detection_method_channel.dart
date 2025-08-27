import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'opencv_edge_detection_platform_interface.dart';

/// An implementation of [OpencvEdgeDetectionPlatform] that uses method channels.
class MethodChannelOpencvEdgeDetection extends OpencvEdgeDetectionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('opencv_edge_detection');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
