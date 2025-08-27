import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'opencv_edge_detection_method_channel.dart';

abstract class OpencvEdgeDetectionPlatform extends PlatformInterface {
  /// Constructs a OpencvEdgeDetectionPlatform.
  OpencvEdgeDetectionPlatform() : super(token: _token);

  static final Object _token = Object();

  static OpencvEdgeDetectionPlatform _instance = MethodChannelOpencvEdgeDetection();

  /// The default instance of [OpencvEdgeDetectionPlatform] to use.
  ///
  /// Defaults to [MethodChannelOpencvEdgeDetection].
  static OpencvEdgeDetectionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OpencvEdgeDetectionPlatform] when
  /// they register themselves.
  static set instance(OpencvEdgeDetectionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
