import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_usecase.dart';
import 'package:gadgets/modules/clipboard/l10n/clipboard_localizations.dart';
import 'package:gadgets/modules/clipboard/l10n/clipboard_tip_l10n.dart';
import 'package:gadgets/modules/clipboard/view_models/clipboard_view_model.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/services/sse_service.dart';
import 'package:gadgets/shared/ui/toast_component.dart';
import 'package:gadgets/shared/utils/support_layout.dart';
import 'package:gadgets/shared/utils/unit_formater.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:gadgets/shared/view_models/layout_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ClipboardPage extends StatefulWidget {
  const ClipboardPage({super.key});

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage>
    with WidgetsBindingObserver {
  // toast 能力
  late final FToast _toast;
  late final ClipboardConnectionViewModel _viewModel;
  late final StreamSubscription<SseConnectionState> _subscription;
  late final StreamSubscription<ClipboardOperationState> _operationSubscription;

  // ui能力, 下传至具体组件
  void _showToast(TipType type, String message) {
    Widget toast = Tip(type: type, message: message);
    _toast.removeQueuedCustomToasts();
    _toast.showToast(
      child: toast,
      positionedToastBuilder: (context, child, gravity) =>
          Positioned(top: 16.0, left: 0, right: 0, child: child),
      toastDuration: const Duration(seconds: 2),
    );
  }

  @override
  void initState() {
    super.initState();
    _toast = FToast()..init(context);
    _viewModel = ClipboardConnectionViewModel(repository: context.read());
    // 设置连接状态监听
    _subscription = _viewModel.stream.listen((state) {
      if (mounted) {
        final localizations = ClipboardLocalizations.of(context)!;
        switch (state) {
          case SseRetryState():
            _showToast(
              TipType.info,
              "${localizations.retrying} ${state.time}/${state.maxRetries}",
            );
            break;
          case SseConnectingState():
            _showToast(TipType.info, localizations.connecting);
            break;
          case SseConnectedState():
            _showToast(TipType.success, localizations.connected);
            break;
          case SseDisconnectedState():
            _showToast(
              TipType.warning,
              "${localizations.disconnected}${localizations.splitter}${state.cause}",
            );
            break;
        }
      }
    });

    _operationSubscription = context
        .read<ClipboardDataOperationViewModel>()
        .stream
        .listen((state) {
          if (mounted) {
            final localizations = ClipboardLocalizations.of(context)!;
            final operation = ClipboardTipL10n.getByOperation(
              localizations,
              state.operation,
            );
            final splitter = localizations.splitter;
            if (!state.success) {
              final cause = ClipboardTipL10n.getByCause(
                localizations,
                state.cause,
              );
              _showToast(
                TipType.warning,
                "$operation$splitter${localizations.failed}$splitter${cause ?? ''}",
              );
              return;
            }
            if (state.operation == ClipboardOperation.copy) {
              final message = state.data as ClipboardMessage;
              Clipboard.setData(ClipboardData(text: message.content));
            }
            if (state.operation != ClipboardOperation.scan) {
              _showToast(
                TipType.success,
                '$operation$splitter${localizations.success}',
              );
            }
          }
        });

    // 设置appbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppbarViewModel>().changeConfig(
        AppBarConfig(
          id: 'clipboard',
          title: _ClipboardTitle(stream: _viewModel.stream),
          actions: [
            IconButton(
              onPressed: () => _viewModel.refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
      // 自动连接
      _viewModel.connect();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _viewModel.resume();
    } else if (state == AppLifecycleState.paused) {
      _viewModel.pause();
    }
  }

  @override
  void dispose() {
    _toast.removeQueuedCustomToasts();
    WidgetsBinding.instance.removeObserver(this);
    _operationSubscription.cancel();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: context.read<ClipboardConfigUseCase>().availableStream,
    initialData: false,
    builder: (context, snapshot) {
      final ignore = !snapshot.data!;
      return IgnorePointer(
        ignoring: ignore,
        child: Opacity(
          opacity: ignore ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              spacing: 4,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [_UsageComponent()],
                ),
                Expanded(child: _DataListView(showToast: _showToast)),
                _DataInputView(),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ClipboardTitle extends StatelessWidget {
  final Stream<SseConnectionState> _stream;

  const _ClipboardTitle({required Stream<SseConnectionState> stream})
    : _stream = stream;

  @override
  Widget build(BuildContext context) {
    final ClipboardLocalizations localizations = ClipboardLocalizations.of(
      context,
    )!;
    final text = Text(localizations.title);
    return StreamBuilder(
      stream: _stream,
      initialData: const SseDisconnectedState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return text;
        }
        final icon = switch (snapshot.data!.state) {
          SseConnectionStatus.disconnected => const Icon(
            Icons.link_off,
            color: Colors.red,
          ),
          SseConnectionStatus.connected => const Icon(
            Icons.link,
            color: Colors.green,
          ),
          SseConnectionStatus.connecting => Shimmer.fromColors(
            baseColor: Colors.grey,
            highlightColor: Colors.yellow,
            child: const Icon(Icons.settings_ethernet),
          ),
        };
        return Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [text, icon],
        );
      },
    );
  }
}

class _UsageComponent extends StatelessWidget {
  const _UsageComponent();

  @override
  Widget build(BuildContext context) {
    final useCase = context.read<ClipboardConfigUseCase>();
    return StreamBuilder(
      stream: useCase.stream,
      builder: (context, snapshot) {
        ClipboardUsage? usage = useCase.usage;
        ClipboardConfig? config = useCase.config;
        final configIsNull = config == null;
        final usageIsNull = usage == null;
        final bytesUsed = usageIsNull ? '-' : formatDataSize(usage.bytes);
        final countUsed = usageIsNull ? '-' : usage.count;
        final expire = configIsNull
            ? '-'
            : formatDurationLocalized(
                Duration(milliseconds: config.expire),
                AppLocalizations.of(context)!,
              );
        final maxBytes = configIsNull ? '-' : formatDataSize(config.maxBytes);
        final maxCount = configIsNull ? '-' : config.maxCount;
        final localizations = ClipboardLocalizations.of(context)!;
        return Wrap(
          spacing: 8,
          children: [
            _ResponsiveStatusChip(
              avatar: const Icon(Icons.list_alt),
              description: localizations.record,
              status: "$countUsed/$maxCount",
            ),
            _ResponsiveStatusChip(
              avatar: const Icon(Icons.data_usage),
              description: localizations.capacity,
              status: "$bytesUsed/$maxBytes",
            ),
            _ResponsiveStatusChip(
              avatar: const Icon(Icons.event_busy),
              description: localizations.expire,
              status: expire,
            ),
          ],
        );
      },
    );
  }
}

class _DataListView extends StatefulWidget {
  final void Function(TipType, String) showToast;

  const _DataListView({required this.showToast});

  @override
  State<_DataListView> createState() => _DataListViewState();
}

class _DataListViewState extends State<_DataListView> {
  late final ScrollController _scrollController;
  late final ClipboardDataViewModel _viewModel;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late final StreamSubscription<DataChangeState> _subscription;

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 && _viewModel.hasMore) {
      _viewModel.scan();
    }
  }

  Widget _slideIt(BuildContext context, int index, animation) {
    final item = _viewModel[index];
    final operationViewModel = context.read<ClipboardDataOperationViewModel>();
    return FadeTransition(
      opacity: animation,
      child: _MessageCard(
        key: ValueKey("clipboard-${item!.id}"),
        onCopy: () => operationViewModel.copy(item.id),
        onRemove: () => operationViewModel.remove(item.id),
        meta: item,
      ),
    );
  }

  Widget _slideOut(ClipboardMessageMeta meta, animation) => FadeTransition(
    opacity: animation,
    child: _MessageCard(key: ValueKey("clipboard-${meta.id}"), meta: meta),
  );

  @override
  void initState() {
    super.initState();
    _viewModel = ClipboardDataViewModel(
      useCase: context.read(),
      scannerUseCase: context.read(),
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _subscription = _viewModel.stream.listen((state) {
      switch (state) {
        case DataAddedState():
          _listKey.currentState?.insertItem(state.index);
          break;
        case DataRemovedState():
          _listKey.currentState?.removeItem(
            state.index,
            (_, animation) => _slideOut(state.meta, animation),
          );
          break;
        case DataAllRemovedState _:
          _listKey.currentState?.removeAllItems(
            (ctx, animation) => _slideOut(
              const ClipboardMessageMeta(
                id: 'preset',
                preview: '',
                length: 0,
                bytes: 0,
                timestamp: 0,
              ),
              animation,
            ),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedList(
    key: _listKey,
    itemBuilder: _slideIt,
    initialItemCount: 0,
    reverse: true,
    controller: _scrollController,
  );

  @override
  void dispose() {
    _subscription.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}

class _DataInputView extends StatefulWidget {
  @override
  State<_DataInputView> createState() => _DataInputViewState();
}

class _DataInputViewState extends State<_DataInputView> {
  late final TextEditingController _controller;

  late final StreamSubscription<ClipboardOperationState> _subscription;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _subscription = context
        .read<ClipboardDataOperationViewModel>()
        .stream
        .where(
          (state) => state.operation == ClipboardOperation.add && state.success,
        )
        .listen((_) => _controller.text = '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription.cancel();
    super.dispose();
  }

  void _addMessage() {
    context.read<ClipboardDataOperationViewModel>().addData(_controller.text);
  }

  void _clearMessage() {
    context.read<ClipboardDataOperationViewModel>().clear();
  }

  @override
  Widget build(BuildContext context) => ListTile(
    title: TextField(
      textInputAction: TextInputAction.go,
      controller: _controller,
      decoration: const InputDecoration(
        border: UnderlineInputBorder(),
        hintText: 'type something ...',
      ),
      onSubmitted: (_) => _addMessage(),
    ),
    trailing: Wrap(
      children: [
        IconButton(onPressed: _addMessage, icon: const Icon(Icons.send)),
        IconButton(
          onPressed: _clearMessage,
          icon: const Icon(Icons.delete_sweep),
        ),
      ],
    ),
  );
}

class _ResponsiveStatusChip extends StatelessWidget {
  final Widget? _avatar;
  final String? _description;
  final String? _status;

  const _ResponsiveStatusChip({
    Widget? avatar,
    String? description,
    String? status,
  }) : _avatar = avatar,
       _description = description,
       _status = status;

  @override
  Widget build(BuildContext context) => Consumer<LayoutViewModel>(
    builder: (context, layout, child) {
      final description = layout.currentLayout == SupportLayout.mobile
          ? ''
          : '$_description:';
      final widgets = _avatar != null
          ? [_avatar, const SizedBox(width: 4)]
          : [];
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        direction: Axis.horizontal,
        children: [...widgets, Text("$description$_status")],
      );
    },
  );
}

class _MessageCard extends StatelessWidget {
  final ClipboardMessageMeta _meta;
  final VoidCallback? _onCopy;
  final VoidCallback? _onRemove;

  const _MessageCard({
    super.key,
    required ClipboardMessageMeta meta,
    VoidCallback? onCopy,
    VoidCallback? onRemove,
  }) : _meta = meta,
       _onCopy = onCopy,
       _onRemove = onRemove;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(_meta.preview),
      trailing: Wrap(
        children: [
          IconButton(onPressed: _onCopy, icon: const Icon(Icons.copy)),
          IconButton(onPressed: _onRemove, icon: const Icon(Icons.close)),
        ],
      ),
    ),
  );
}
