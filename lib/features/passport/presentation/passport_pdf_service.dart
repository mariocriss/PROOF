import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:proof/features/passport/domain/passport_export_data.dart';
import 'package:proof/features/passport/presentation/pdf/passport_pdf_document.dart';
import 'package:proof/shared/models/physical_identity.dart';
import 'package:proof/shared/models/proof_model.dart';
import 'package:proof/shared/models/skill_model.dart';
import 'package:proof/shared/models/timeline_event.dart';
import 'package:share_plus/share_plus.dart';

class PassportPdfService {
  PassportPdfService._();

  static Future<PassportExportData> buildExportData({
    required PhysicalIdentity identity,
    required List<SkillModel> skills,
    required List<ProofModel> proofs,
    required List<TimelineEvent> timeline,
    String? gymName,
    String? coachName,
    DateTime Function()? now,
  }) {
    return Future.value(
      PassportExportData.fromPassport(
        identity: identity,
        skills: skills,
        proofs: proofs,
        timeline: timeline,
        gymName: gymName,
        coachName: coachName,
        now: now,
      ),
    );
  }

  static Future<Uint8List> generatePdfBytes(PassportExportData data) async {
    final avatarBytes = await _loadAvatarBytes(data.avatarUrl);
    return PassportPdfDocument.build(data, avatarBytes: avatarBytes);
  }

  static Future<File> writePdfFile({
    required PassportExportData data,
    required Uint8List bytes,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${data.suggestedFilename}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Preview then allow share/save via the printing package.
  static Future<void> previewAndShare({
    required BuildContext context,
    required PassportExportData data,
  }) async {
    final bytes = await generatePdfBytes(data);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PassportPdfPreviewScreen(
          data: data,
          pdfBytes: bytes,
        ),
      ),
    );
  }

  /// Direct share without preview (fallback).
  static Future<void> sharePdfFile({
    required PassportExportData data,
    required Uint8List bytes,
  }) async {
    final file = await writePdfFile(data: data, bytes: bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: '${data.displayName} — PROOF Physical Passport',
        text: 'PROOF Physical Passport for ${data.displayName}\n${data.publicUrl}',
      ),
    );
  }

  static Future<Uint8List?> _loadAvatarBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      final response =
          await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
        if (builder.length > 2 * 1024 * 1024) return null;
      }
      return builder.takeBytes();
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }
}

class PassportPdfPreviewScreen extends StatelessWidget {
  const PassportPdfPreviewScreen({
    super.key,
    required this.data,
    required this.pdfBytes,
  });

  final PassportExportData data;
  final Uint8List pdfBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Physical Passport PDF'),
        actions: [
          IconButton(
            tooltip: 'Share or save',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () async {
              await PassportPdfService.sharePdfFile(
                data: data,
                bytes: pdfBytes,
              );
            },
          ),
          IconButton(
            tooltip: 'Print or save',
            icon: const Icon(Icons.print_outlined),
            onPressed: () async {
              await Printing.layoutPdf(
                name: data.suggestedFilename,
                onLayout: (_) async => pdfBytes,
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => pdfBytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowSharing: true,
        allowPrinting: true,
        pdfFileName: data.suggestedFilename,
        actions: const [],
      ),
    );
  }
}
