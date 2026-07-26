import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proof/core/constants/app_features.dart';
import 'package:proof/core/constants/app_urls.dart';
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

  static bool get canSharePublicWebLink => AppFeatures.publicWebPassportEnabled;

  static Future<void> shareLink(PassportCredentialViewData data) async {
    if (!canSharePublicWebLink || data.publicUrl == null) {
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        text: _shareMessage(data),
        subject: '${data.identity.displayName} — PROOF Passport',
      ),
    );
  }

  static Future<void> copyLink(PassportCredentialViewData data) async {
    final url = data.publicUrl;
    if (url == null || url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
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
          const SnackBar(
            content: Text('Could not generate PDF. Please try again.'),
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
    final url = data.publicUrl;
    if (!canSharePublicWebLink || url == null) {
      showPublicPassportUnavailable(context);
      return;
    }

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
                  data: url,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  url,
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

  static void showPublicPassportUnavailable(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Public link unavailable'),
        content: const Text(AppUrls.publicPassportUnavailableMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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
              if (canSharePublicWebLink && data.publicUrl != null) ...[
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
              ],
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
    final url = data.publicUrl ?? '';
    return 'My PROOF Physical Identity Passport\n\n'
        '${data.identity.displayName}\n'
        '${data.overallConfidence.label} · '
        '${data.proofsCount} proofs · '
        '${data.skillsCount} skills\n\n'
        '$url';
  }

  static void _assertNoPrivateLeak(PassportExportData data) {
    final url = data.publicUrl;
    if (url != null) {
      assert(!url.contains('firebase'), 'Unexpected firebase URL');
    }
    assert(data.handle.isNotEmpty, 'Handle required for passport export');
  }
}
