import 'package:flutter/material.dart';
import 'package:proof/shared/models/user_report_model.dart';
import 'package:proof/shared/widgets/proof_widgets.dart';

class ReportUserDialog extends StatefulWidget {
  const ReportUserDialog({
    super.key,
    required this.reportedHandle,
  });

  final String reportedHandle;

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  UserReportReason _reason = UserReportReason.spam;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report @${widget.reportedHandle}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<UserReportReason>(
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: UserReportReason.values
                  .map(
                    (reason) => DropdownMenuItem(
                      value: reason,
                      child: Text(reason.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _reason = value);
              },
            ),
            const SizedBox(height: 12),
            ProofTextField(
              controller: _detailsController,
              label: 'Details (optional)',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            ReportUserResult(
              reason: _reason,
              details: _detailsController.text.trim(),
            ),
          ),
          child: const Text('Submit report'),
        ),
      ],
    );
  }
}

class ReportUserResult {
  const ReportUserResult({
    required this.reason,
    required this.details,
  });

  final UserReportReason reason;
  final String details;
}
