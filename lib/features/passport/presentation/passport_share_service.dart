import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:proof/features/passport/domain/passport_credential_view_data.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class PassportShareService {
  PassportShareService._();

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

  static Future<void> sharePdf(PassportCredentialViewData data) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PROOF Physical Identity Passport',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                data.identity.displayName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('@${data.identity.handle}'),
              pw.SizedBox(height: 16),
              pw.Text('Identity status: ${data.identityBadgeLabel}'),
              pw.Text('Physical identity: ${data.overallConfidence.label}'),
              pw.SizedBox(height: 16),
              pw.Text('Skills: ${data.skillsCount}'),
              pw.Text('Proofs: ${data.proofsCount}'),
              pw.Text('Coach verified: ${data.coachVerifiedCount}'),
              pw.SizedBox(height: 24),
              pw.Text('Public passport: ${data.publicUrl}'),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/proof-passport-${data.identity.handle}.pdf',
    );
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: '${data.identity.displayName} — PROOF Passport',
      ),
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

  static void showMoreOptions(
    BuildContext context,
    PassportCredentialViewData data,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy link'),
                onTap: () async {
                  await copyLink(data);
                  if (context.mounted) {
                    Navigator.pop(context);
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
                  Navigator.pop(context);
                  await shareLink(data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Download PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  await sharePdf(data);
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
}
