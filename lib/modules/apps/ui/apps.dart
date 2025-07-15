import 'package:flutter/material.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:gadgets/shared/utils/support_layout.dart';
import 'package:gadgets/shared/view_models/layout_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const _verticalCardWidth = 100.0;
const _verticalCardHeight = 120.0;
const _verticalRatio = _verticalCardWidth / _verticalCardHeight;
const _verticalCardSpace = 8.0;
const _horizontalCardWidth = 200.0;
const _horizontalCardHeight = 96.0;
const _horizontalRatio = _horizontalCardWidth / _horizontalCardHeight;
const _horizontalCardSpace = 4.0;
const _minSpace = 16.0;

class AppCenterView extends StatelessWidget {
  const AppCenterView({super.key});

  int _calcMobileCrossAxisCount(
    double maxWidth,
    double elementWidth,
    double space,
  ) {
    int cnt = ((maxWidth + space) / (elementWidth + space)).floor();
    if (cnt == 0) {
      cnt = 1;
    }
    return cnt;
  }

  @override
  Widget build(BuildContext context) {
    final apps = context.read<NavigationViewModel>().appRoutes;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<LayoutViewModel>(
        builder: (context, vm, child) => LayoutBuilder(
          builder: (context, constraints) {
            if (vm.currentLayout == SupportLayout.mobile) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _calcMobileCrossAxisCount(
                    constraints.maxWidth,
                    _verticalCardWidth,
                    _minSpace,
                  ),
                  crossAxisSpacing: _minSpace,
                  mainAxisSpacing: _minSpace,
                  childAspectRatio: _verticalRatio,
                ),
                itemCount: apps.length,
                itemBuilder: (context, index) => _VerticalCard(
                  key: ValueKey('app-vertical-${apps[index].id}'),
                  define: apps[index],
                ),
              );
            }
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _calcMobileCrossAxisCount(
                  constraints.maxWidth,
                  _horizontalCardWidth,
                  _minSpace,
                ),
                crossAxisSpacing: _minSpace,
                mainAxisSpacing: _minSpace,
                childAspectRatio: _horizontalRatio,
              ),
              itemCount: apps.length,
              itemBuilder: (context, index) => _HorizontalCard(
                key: ValueKey('app-horizontal-${apps[index].id}'),
                define: apps[index],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VerticalCard extends StatelessWidget {
  final RouteDefine _define;

  const _VerticalCard({super.key, required RouteDefine define})
    : _define = define;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: _verticalCardWidth,
      height: _verticalCardHeight,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.go(_define.route.path);
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: _verticalCardSpace,
              children: [
                SizedBox(width: 64, height: 64, child: _define.icon),
                Text(
                  _define.localizationOf(context).title,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _HorizontalCard extends StatelessWidget {
  final RouteDefine _define;

  const _HorizontalCard({super.key, required RouteDefine define})
    : _define = define;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: _horizontalCardWidth,
      height: _horizontalCardHeight,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.go(_define.route.path);
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: _horizontalCardSpace,
                children: [
                  SizedBox(width: 64, height: 64, child: _define.icon),
                  Expanded(
                    child: Center(
                      child: Text(
                        _define.localizationOf(context).title,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
