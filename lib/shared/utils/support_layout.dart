import 'package:gadgets/shared/utils/platform_detector.dart';

enum SupportLayout {
  /// 小屏设备布局
  mobile,

  /// 大屏设备布局
  desktop;

  /// 根据当前约束判断布局
  static SupportLayout judge(double maxWidth) {
    if (maxWidth >= 800) {
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
