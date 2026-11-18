import 'package:flutter/material.dart';
import 'package:proof/features/experience/presentation/widgets/passport_book.dart';

/// Closed → open passport credential for issuance moment.
class PassportCredentialVisual extends StatelessWidget {
  const PassportCredentialVisual({
    super.key,
    required this.displayName,
    this.opened = false,
    this.reduceMotion = false,
    this.onTapClosed,
    this.animationSpeed = 1.0,
    this.width,
  });

  final String displayName;
  final bool opened;
  final bool reduceMotion;
  final VoidCallback? onTapClosed;
  final double animationSpeed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return PassportBookVisual(
      displayName: displayName,
      opened: opened,
      reduceMotion: reduceMotion,
      onTapClosed: onTapClosed,
      width: width,
    );
  }
}
