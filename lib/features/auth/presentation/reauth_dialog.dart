import 'package:flutter/material.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class ReauthDialog extends StatefulWidget {
  const ReauthDialog({super.key});

  @override
  State<ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<ReauthDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm your password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'For security, enter your password again to delete your account.',
          ),
          const SizedBox(height: 16),
          ProofTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: true,
            onFieldSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    Navigator.pop(context, password);
  }
}
