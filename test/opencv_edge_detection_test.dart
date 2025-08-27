import 'package:flutter_test/flutter_test.dart';
import 'package:opencv_edge_detection/opencv_edge_detection.dart';
import 'package:opencv_edge_detection/opencv_edge_detection_platform_interface.dart';
import 'package:opencv_edge_detection/opencv_edge_detection_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOpencvEdgeDetectionPlatform
    with MockPlatformInterfaceMixin
    implements OpencvEdgeDetectionPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final OpencvEdgeDetectionPlatform initialPlatform = OpencvEdgeDetectionPlatform.instance;

  test('$MethodChannelOpencvEdgeDetection is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelOpencvEdgeDetection>());
  });

  test('getPlatformVersion', () async {
    OpencvEdgeDetection opencvEdgeDetectionPlugin = OpencvEdgeDetection();
    MockOpencvEdgeDetectionPlatform fakePlatform = MockOpencvEdgeDetectionPlatform();
    OpencvEdgeDetectionPlatform.instance = fakePlatform;

    expect(await opencvEdgeDetectionPlugin.getPlatformVersion(), '42');
  });
}
