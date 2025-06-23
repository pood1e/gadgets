import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class StaticLogo extends StatelessWidget {
  const StaticLogo({super.key});

  static const _logoSize = 32.0;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/svg/icon.svg',
    width: _logoSize,
    height: _logoSize,
  );
}
