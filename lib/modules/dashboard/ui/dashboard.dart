import 'package:flutter/material.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppbarViewModel>().changeConfig(
        AppBarConfig(
          id: 'dashboard',
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
          ],
        ),
      );
    });
    return const Center(child: Text('dashboard'));
  }
}
