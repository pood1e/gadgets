import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/main.dart';
import 'package:gadgets/modules/apps/l10n/apps_localizations.dart';
import 'package:gadgets/modules/apps/ui/apps.dart';
import 'package:gadgets/shared/routing/router.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:gadgets/shared/utils/support_layout.dart';
import 'package:gadgets/shared/view_models/layout_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/test_localizations.dart';
import '../../../test_utils/test_constants.dart';

void main() {
  group('AppCenter', () {
    createTestWidget({SupportLayout? layout}) {
      final navigations = [
        RouteDefine(
          id: 'apps',
          icon: const Icon(Icons.apps),
          localizationOf: (ctx) => AppsLocalizations.of(ctx)!,
          localizationDelegate: AppsLocalizations.delegate,
          route: GoRoute(
            path: '/',
            builder: (context, state) => const AppCenterView(),
          ),
        ),
      ];
      final appRoutes = [
        RouteDefine(
          id: 'app1',
          icon: const Icon(Icons.face),
          localizationOf: (ctx) => TestLocalizations.of(ctx)!,
          localizationDelegate: TestLocalizations.delegate,
          route: GoRoute(
            path: '/app1',
            builder: (context, state) => Container(),
          ),
        ),
        RouteDefine(
          id: 'app2',
          icon: const Icon(Icons.icecream),
          localizationOf: (ctx) => TestLocalizations.of(ctx)!,
          localizationDelegate: TestLocalizations.delegate,
          route: GoRoute(
            path: '/app2',
            builder: (context, state) => Container(),
          ),
        ),
      ];
      final router = createRouterByNavigations(
        [...appRoutes, ...navigations],
        '/',
        (_, _, child) => child,
      );

      return MultiProvider(
        providers: [
          Provider.value(
            value: NavigationViewModel(
              navigations: navigations,
              appRoutes: appRoutes,
            ),
          ),
          ChangeNotifierProvider.value(
            value: LayoutViewModel(layout: layout ?? SupportLayout.desktop),
          ),
          Provider.value(value: presetL10ViewModel),
        ],
        child: MyApp(router: router),
      );
    }

    group('layout', () {
      testWidgets('show vertical card when layout is mobile', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(layout: SupportLayout.mobile));

        // Assert
        expect(find.byKey(const ValueKey("app-vertical-app1")), findsOneWidget);
        expect(find.byKey(const ValueKey("app-vertical-app2")), findsOneWidget);
      });

      testWidgets('show horizontal card when layout is desktop', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(layout: SupportLayout.desktop),
        );

        // Assert
        expect(
          find.byKey(const ValueKey("app-horizontal-app1")),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey("app-horizontal-app2")),
          findsOneWidget,
        );
      });
    });

    group('route', () {
      testWidgets('route change successfully', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.tap(find.byIcon(Icons.face));
        await tester.pumpAndSettle();

        // Assert
        expect(getRouter(tester).state.fullPath, '/app1');
      });
    });
  });
}
