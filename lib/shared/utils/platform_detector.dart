import 'dart:io';

abstract class PlatformDetector {
  bool get isAndroid;

  bool get isIOS;

  const PlatformDetector();
}

class _DefaultPlatformDetector extends PlatformDetector {
  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;

  const _DefaultPlatformDetector();
}

const defaultPlatformDetector = _DefaultPlatformDetector() as PlatformDetector;
