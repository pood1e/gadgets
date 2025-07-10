import 'package:flutter/cupertino.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_usecase.dart';
import 'package:gadgets/modules/clipboard/repositories/clipboard_repository.dart';
import 'package:gadgets/modules/clipboard/repositories/clipboard_repository_remote.dart';
import 'package:gadgets/modules/clipboard/ui/clipboard.dart';
import 'package:gadgets/modules/clipboard/view_models/clipboard_view_model.dart';
import 'package:provider/provider.dart';

class ClipboardApp extends StatelessWidget {
  const ClipboardApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider(
        create: (ctx) =>
            RemoteClipboardNotifyRepository(service: ctx.read())
                as ClipboardNotifyRepository,
        dispose: (ctx, repository) => repository.close(),
      ),
      Provider(
        create: (ctx) =>
            RemoteClipboardDataRepository(service: ctx.read())
                as ClipboardDataRepository,
      ),
      Provider(
        create: (context) => ClipboardAutoDisconnect(context.read(), 20),
        dispose: (_, value) => value.dispose(),
      ),
      Provider(
        create: (context) => ClipboardConfigUseCase(context.read()),
        dispose: (_, value) => value.dispose(),
      ),
      Provider(
        create: (context) => ClipboardTipUseCase(),
        dispose: (_, value) => value.dispose(),
      ),
      Provider(
        create: (context) => ClipboardOperationUseCase(
          configUseCase: context.read(),
          repository: context.read(),
          tipUseCase: context.read(),
        ),
      ),
      Provider(
        create: (context) => ClipboardDataScannerUseCase(
          configUseCase: context.read(),
          tipUseCase: context.read(),
          repository: context.read(),
        ),
        dispose: (_, value) => value.dispose(),
      ),
      Provider(
        create: (context) => ClipboardDataUseCase(
          useCase: context.read(),
          repository: context.read(),
        ),
        dispose: (_, value) => value.dispose(),
      ),
      Provider(
        create: (context) => ClipboardDataOperationViewModel(
          useCase: context.read(),
          tipUseCase: context.read(),
        ),
      ),
    ],
    child: const ClipboardPage(),
  );
}
