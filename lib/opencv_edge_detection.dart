
import 'opencv_edge_detection_platform_interface.dart';

class OpencvEdgeDetection {
  Future<String?> getPlatformVersion() {
    return OpencvEdgeDetectionPlatform.instance.getPlatformVersion();
  }
}
