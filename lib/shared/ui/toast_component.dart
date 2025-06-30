import 'package:flutter/material.dart';

class MyTip extends StatelessWidget {
  final TipType _type;
  final String _message;

  const MyTip({super.key, required TipType type, required String message})
    : _type = type,
      _message = message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25.0),
      color: _type.color,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _type.icon,
        const SizedBox(width: 12.0),
        Flexible(
          child: Text(_message, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    ),
  );
}

enum TipType {
  success(color: Colors.greenAccent, icon: Icon(Icons.check)),
  info(color: Colors.grey, icon: Icon(Icons.info)),
  warning(color: Colors.yellowAccent, icon: Icon(Icons.warning)),
  error(color: Colors.redAccent, icon: Icon(Icons.close));

  final Color color;
  final Icon icon;

  const TipType({required this.color, required this.icon});
}
