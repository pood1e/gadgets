import 'package:gadgets/shared/utils/platform_detector.dart';

enum SupportLayout {
  /// 小屏设备布局
  mobile,

  /// 大屏设备布局
  desktop;

  /// 根据屏幕尺寸和当前约束判断布局
  static SupportLayout judge(double screenWidth, double maxWidth) {
    if (maxWidth >= 800 && screenWidth >= 1024) {
      return desktop;
    }
    return mobile;
  }

  /// 根据设备类型获取默认的布局
  static SupportLayout getDefaultLayoutByPlatform({
    PlatformDetector detector = defaultPlatformDetector,
  }) {
    if (detector.isAndroid || detector.isIOS) {
      return SupportLayout.mobile;
    }
    return SupportLayout.desktop;
  }
}
