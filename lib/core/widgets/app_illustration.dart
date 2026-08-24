import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIllustration extends StatelessWidget {
  const AppIllustration({
    super.key,
    required this.asset,
    this.semanticLabel,
    this.maxHeight = 350,
  });

  final String asset;
  final String? semanticLabel;
  final double maxHeight;

  bool get _isSvg => asset.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: _isSvg
          ? SvgPicture.asset(
              asset,
              fit: BoxFit.contain,
              semanticsLabel: semanticLabel,
              excludeFromSemantics: semanticLabel == null,
            )
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              semanticLabel: semanticLabel,
              excludeFromSemantics: semanticLabel == null,
            ),
    );
  }
}
