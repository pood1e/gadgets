import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/utils/platform_detector.dart';
import 'package:gadgets/shared/utils/support_layout.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'support_layout_test.mocks.dart';

@GenerateNiceMocks([MockSpec<PlatformDetector>()])
void main() {
  group('SupportLayout', () {
    group('judge method', () {
      test(
        'should return desktop when width >= 800 and screenWidth >= 1024',
        () {
          // Arrange & Act & Assert
          expect(SupportLayout.judge(1024, 800), equals(SupportLayout.desktop));
        },
      );

      test('should return mobile when screenWidth < 1024', () {
        // Arrange & Act & Assert
        expect(SupportLayout.judge(1000, 800), equals(SupportLayout.mobile));
      });

      test('should return mobile when screenWidth < 1024', () {
        // Arrange & Act & Assert
        expect(SupportLayout.judge(1024, 750), equals(SupportLayout.mobile));
      });
    });

    group('getDefaultLayoutByPlatform method', () {
      late PlatformDetector detector;

      setUp(() {
        detector = MockPlatformDetector();
      });

      test('should return mobile when platform is android', () {
        // Arrange
        when(detector.isAndroid).thenAnswer((_) => true);
        when(detector.isIOS).thenAnswer((_) => false);

        // Act & Assert
        expect(
          SupportLayout.getDefaultLayoutByPlatform(detector: detector),
          SupportLayout.mobile,
        );
      });

      test('should return mobile when platform is ios', () {
        // Arrange
        when(detector.isAndroid).thenAnswer((_) => false);
        when(detector.isIOS).thenAnswer((_) => true);

        // Act & Assert
        expect(
          SupportLayout.getDefaultLayoutByPlatform(detector: detector),
          SupportLayout.mobile,
        );
      });

      test(
        'should return desktop when platform is not ios and not android',
        () {
          // Arrange
          when(detector.isAndroid).thenAnswer((_) => false);
          when(detector.isIOS).thenAnswer((_) => false);

          // Act & Assert
          expect(
            SupportLayout.getDefaultLayoutByPlatform(detector: detector),
            SupportLayout.desktop,
          );
        },
      );
    });
  });
}
