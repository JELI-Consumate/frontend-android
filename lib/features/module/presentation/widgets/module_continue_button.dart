import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';

class ModuleContinueButton extends StatelessWidget {
  const ModuleContinueButton({
    super.key,
    required this.hasNext,
    required this.busy,
    required this.onPressed,
  });

  final bool hasNext;

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: hasNext ? 'Selanjutnya' : 'Selesai',
      trailingIcon: hasNext ? Icons.arrow_forward : Icons.check,
      isLoading: busy,
      onPressed: onPressed,
    );
  }
}
