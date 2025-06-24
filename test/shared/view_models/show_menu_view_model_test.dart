import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/view_models/show_menu_view_model.dart';

void main() {
  test('should not show menu when default', () {
    // Arrange
    final viewModel = ShowMenuViewModel();
    // Act & Assert
    expect(viewModel.showMenu, false);
  });
  test('should show menu when collapsed and hovered', () {
    // Arrange
    final viewModel = ShowMenuViewModel();
    expect(viewModel.showMenu, false);

    // Act
    viewModel.updateHover(true);
    viewModel.updateCollapse(true);

    // Assert
    expect(viewModel.showMenu, true);
  });
}
