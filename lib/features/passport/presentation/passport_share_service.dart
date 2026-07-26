import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proof/features/passport/domain/passport_credential_view_data.dart';
import 'package:proof/features/passport/domain/passport_export_data.dart';
import 'package:proof/features/passport/presentation/passport_pdf_service.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class PassportShareService {
  PassportShareService._();

  static bool _pdfExportInProgress = false;

  static bool get isPdfExportInProgress => _pdfExportInProgress;

  static Future<void> shareLink(PassportCredentialViewData data) async {
    await SharePlus.instance.share(
      ShareParams(
        text: _shareMessage(data),
        subject: '${data.identity.displayName} — PROOF Passport',
      ),
    );
  }

  static Future<void> copyLink(PassportCredentialViewData data) async {
    await Clipboard.setData(ClipboardData(text: data.publicUrl));
  }

  /// Generates a professional multi-page Physical Passport PDF,
  /// then opens a preview with share/save actions.
  static Future<void> sharePdf({
    required BuildContext context,
    required PhysicalIdentity identity,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    required List<TimelineEvent> timeline,
    String? gymName,
    String? coachName,
  }) async {
    if (_pdfExportInProgress) return;
    _pdfExportInProgress = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text('Generating Physical Passport PDF…'),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final exportData = await PassportPdfService.buildExportData(
        identity: identity,
        skills: skills,
        proofs: proofs,
        timeline: timeline,
        gymName: gymName,
        coachName: coachName,
      );

      // Validate export mapper privacy invariants before generating.
      _assertNoPrivateLeak(exportData);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await PassportPdfService.previewAndShare(
        context: context,
        data: exportData,
      );
    } catch (error) {
      if (context.mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate PDF. Please try again.'),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () {},
            ),
          ),
        );
      }
      debugPrint('Passport PDF export failed: $error');
    } finally {
      _pdfExportInProgress = false;
    }
  }

  /// Backwards-compatible entry used by older call sites that only had
  /// [PassportCredentialViewData]. Prefer [sharePdf] with full source lists.
  static Future<void> sharePdfFromCredential({
    required BuildContext context,
    required PassportCredentialViewData data,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    required List<TimelineEvent> timeline,
    String? gymName,
    String? coachName,
  }) {
    return sharePdf(
      context: context,
      identity: data.identity,
      skills: skills,
      proofs: proofs,
      timeline: timeline,
      gymName: gymName,
      coachName: coachName,
    );
  }

  static void showQrCode(BuildContext context, PassportCredentialViewData data) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Passport QR Code'),
          content: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: data.publicUrl,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  data.publicUrl,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showMoreOptions({
    required BuildContext context,
    required PassportCredentialViewData data,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    required List<TimelineEvent> timeline,
    String? gymName,
    String? coachName,
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy link'),
                onTap: () async {
                  await copyLink(data);
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passport link copied')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share passport'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await shareLink(data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Download PDF'),
                enabled: !_pdfExportInProgress,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await sharePdf(
                    context: context,
                    identity: data.identity,
                    skills: skills,
                    proofs: proofs,
                    timeline: timeline,
                    gymName: gymName,
                    coachName: coachName,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static String _shareMessage(PassportCredentialViewData data) {
    return 'My PROOF Physical Identity Passport\n\n'
        '${data.identity.displayName}\n'
        '${data.overallConfidence.label} · '
        '${data.proofsCount} proofs · '
        '${data.skillsCount} skills\n\n'
        '${data.publicUrl}';
  }

  static void _assertNoPrivateLeak(PassportExportData data) {
    // Lightweight runtime guard for accidental private-field leakage.
    // Export model has no email/phone/firebase id fields by design.
    assert(!data.publicUrl.contains('firebase'), 'Unexpected firebase URL');
    assert(data.handle.isNotEmpty, 'Handle required for public passport URL');
  }
}
