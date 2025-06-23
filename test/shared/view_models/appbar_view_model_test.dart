import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';

void main() {
  group('AppbarViewModel', () {
    late AppbarViewModel viewModel;

    setUp(() {
      viewModel = AppbarViewModel();
    });

    test('should hava default config', () {
      // Arrange ignore
      // Act & Assert
      expect(viewModel.currentConfig, isNotNull);
    });

    test('should notify listeners when state changes', () {
      // Arrange
      bool notified = false;
      viewModel.addListener(() => notified = true);
      const config = AppBarConfig(id: 'other', title: 'other');

      // Act
      viewModel.changeConfig(config);

      // Assert
      expect(viewModel.currentConfig, config);
      expect(notified, true);
    });
  });
}
