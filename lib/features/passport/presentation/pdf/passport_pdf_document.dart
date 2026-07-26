import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:proof/core/utils/date_utils.dart';
import 'package:proof/features/passport/domain/passport_export_data.dart';

/// PROOF brand colors for print-friendly PDFs.
class PassportPdfColors {
  PassportPdfColors._();

  static const PdfColor accent = PdfColor.fromInt(0xFF2C4A3E);
  static const PdfColor ink = PdfColor.fromInt(0xFF1A1A18);
  static const PdfColor muted = PdfColor.fromInt(0xFF5C5C58);
  static const PdfColor lightMuted = PdfColor.fromInt(0xFF9B9B96);
  static const PdfColor border = PdfColor.fromInt(0xFFE8E7E3);
  static const PdfColor surface = PdfColor.fromInt(0xFFF7F6F3);
  static const PdfColor white = PdfColors.white;
}

class PassportPdfDocument {
  PassportPdfDocument._();

  static Future<Uint8List> build(
    PassportExportData data, {
    Uint8List? avatarBytes,
  }) async {
    final doc = pw.Document(
      title: '${data.displayName} — PROOF Physical Passport',
      author: 'PROOF',
      subject: 'Physical Identity Passport',
      creator: 'PROOF',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 42),
        header: (context) => _PdfHeader(data: data),
        footer: (context) => _PdfFooter(data: data),
        build: (context) => [
          _IdentitySection(data: data, avatarBytes: avatarBytes),
          pw.SizedBox(height: 18),
          _SummarySection(data: data),
          if (data.domains.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _DomainSection(domains: data.domains),
          ],
          if (data.featuredSkills.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _SectionTitle('Featured Skills'),
            pw.SizedBox(height: 10),
            ...data.featuredSkills.map(
              (skill) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: _SkillCard(skill: skill, featured: true),
              ),
            ),
          ],
          if (data.skillsByDomain.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _SectionTitle('Skills & Evidence'),
            pw.SizedBox(height: 8),
            ..._skillsByDomainBlocks(data),
          ],
          if (data.timeline.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _SectionTitle('Physical Timeline'),
            pw.SizedBox(height: 8),
            ...data.timeline.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _TimelineRow(item: item),
              ),
            ),
          ],
          if (data.milestones.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _SectionTitle('Milestones'),
            pw.SizedBox(height: 8),
            ...data.milestones.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _MilestoneRow(item: item),
              ),
            ),
          ],
          if (data.appendixProofs.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _SectionTitle('Selected Proof Records'),
            pw.SizedBox(height: 4),
            pw.Text(
              'Strongest and most recent proofs across skills. '
              'Media files are not embedded.',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PassportPdfColors.muted,
              ),
            ),
            pw.SizedBox(height: 8),
            ...data.appendixProofs.map(
              (proof) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: _ProofRow(proof: proof),
              ),
            ),
          ],
          pw.SizedBox(height: 18),
          _ConfidenceExplainer(),
        ],
      ),
    );

    return doc.save();
  }

  static List<pw.Widget> _skillsByDomainBlocks(PassportExportData data) {
    final widgets = <pw.Widget>[];
    final domains = data.skillsByDomain.keys.toList()..sort();
    for (final domain in domains) {
      final skills = data.skillsByDomain[domain]!;
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 6),
          child: pw.Text(
            domain.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.1,
              color: PassportPdfColors.accent,
            ),
          ),
        ),
      );
      for (final skill in skills) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _SkillCard(skill: skill, featured: false),
          ),
        );
      }
    }
    return widgets;
  }
}

class _PdfHeader extends pw.StatelessWidget {
  _PdfHeader({required this.data});

  final PassportExportData data;

  @override
  pw.Widget build(pw.Context context) {
    if (context.pageNumber > 1) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'PROOF · Physical Passport',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PassportPdfColors.muted,
              ),
            ),
            pw.Text(
              '@${data.handle}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PassportPdfColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PROOF',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2.5,
                    color: PassportPdfColors.accent,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Physical Passport',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PassportPdfColors.ink,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Generated ${data.generatedDateLabel}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PassportPdfColors.muted,
                  ),
                ),
                pw.Text(
                  '@${data.handle}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PassportPdfColors.muted,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            children: [
              if (data.publicUrl != null) ...[
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: data.publicUrl!,
                  width: 64,
                  height: 64,
                  color: PassportPdfColors.ink,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Live profile',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PassportPdfColors.lightMuted,
                  ),
                ),
              ] else
                pw.Text(
                  'Offline PDF\nsnapshot',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PassportPdfColors.lightMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PdfFooter extends pw.StatelessWidget {
  _PdfFooter({required this.data});

  final PassportExportData data;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PassportPdfColors.border, width: 0.6),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (data.publicUrl != null)
                pw.UrlLink(
                  destination: data.publicUrl!,
                  child: pw.Text(
                    'PROOF  ·  ${data.publicUrl}',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PassportPdfColors.accent,
                    ),
                  ),
                )
              else
                pw.Text(
                  'PROOF  ·  PDF snapshot (no public web profile)',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PassportPdfColors.muted,
                  ),
                ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PassportPdfColors.muted,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            data.publicUrl != null
                ? 'Generated ${data.generatedDateLabel}. '
                    'This document is a snapshot of the athlete\'s PROOF Physical Passport '
                    'at the time of generation. View the live profile for the latest record.'
                : 'Generated ${data.generatedDateLabel}. '
                    'This document is a PDF snapshot of the athlete\'s PROOF Physical Passport '
                    'at the time of generation. A public web profile is not configured for this build.',
            style: const pw.TextStyle(
              fontSize: 6.5,
              color: PassportPdfColors.lightMuted,
              lineSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends pw.StatelessWidget {
  _SectionTitle(this.title);

  final String title;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.2,
        color: PassportPdfColors.accent,
      ),
    );
  }
}

class _IdentitySection extends pw.StatelessWidget {
  _IdentitySection({required this.data, this.avatarBytes});

  final PassportExportData data;
  final Uint8List? avatarBytes;

  @override
  pw.Widget build(pw.Context context) {
    final meta = <String>[
      if (data.location != null) data.location!,
      if (data.gymName != null) data.gymName!,
      if (data.coachName != null) 'Coach: ${data.coachName}',
      'Member since ${data.memberSinceLabel}',
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PassportPdfColors.border),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (avatarBytes != null) ...[
            pw.ClipOval(
              child: pw.Image(
                pw.MemoryImage(avatarBytes!),
                width: 56,
                height: 56,
                fit: pw.BoxFit.cover,
              ),
            ),
            pw.SizedBox(width: 14),
          ] else ...[
            pw.Container(
              width: 56,
              height: 56,
              decoration: pw.BoxDecoration(
                color: PassportPdfColors.surface,
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: PassportPdfColors.border),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                _initials(data.displayName),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PassportPdfColors.accent,
                ),
              ),
            ),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.displayName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PassportPdfColors.ink,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '@${data.handle}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PassportPdfColors.accent,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    meta.join('  ·  '),
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PassportPdfColors.muted,
                    ),
                  ),
                ],
                if (data.bio != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    data.bio!,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PassportPdfColors.ink,
                      lineSpacing: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _SummarySection extends pw.StatelessWidget {
  _SummarySection({required this.data});

  final PassportExportData data;

  @override
  pw.Widget build(pw.Context context) {
    final metrics = <_Metric>[
      _Metric('${data.totalSkills}', 'Skills'),
      _Metric('${data.totalProofs}', 'Proofs'),
      _Metric('${data.coachVerifiedProofs}', 'Coach Verified'),
      _Metric(data.overallConfidenceLabel, 'Confidence'),
      _Metric(data.identityAgeLabel, 'Active'),
      if (data.gymName != null) _Metric(data.gymName!, 'Gym'),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _SectionTitle('Physical Identity Summary'),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics
              .map(
                (m) => pw.Container(
                  width: 155,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PassportPdfColors.surface,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PassportPdfColors.border),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        m.value,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PassportPdfColors.ink,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        m.label.toUpperCase(),
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PassportPdfColors.muted,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.value, this.label);
  final String value;
  final String label;
}

class _DomainSection extends pw.StatelessWidget {
  _DomainSection({required this.domains});

  final List<PassportExportDomain> domains;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _SectionTitle('Domain Overview'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(
            color: PassportPdfColors.border,
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(2.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PassportPdfColors.surface),
              children: [
                _tableHeader('Domain'),
                _tableHeader('Skills'),
                _tableHeader('Proofs'),
                _tableHeader('Top skill'),
              ],
            ),
            ...domains.map(
              (d) => pw.TableRow(
                children: [
                  _tableCell(d.name),
                  _tableCell('${d.skillCount}'),
                  _tableCell('${d.proofCount}'),
                  _tableCell(d.topSkillName ?? '-'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: PassportPdfColors.muted,
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8, color: PassportPdfColors.ink),
      ),
    );
  }
}

class _SkillCard extends pw.StatelessWidget {
  _SkillCard({required this.skill, required this.featured});

  final PassportExportSkill skill;
  final bool featured;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PassportPdfColors.border),
        borderRadius: pw.BorderRadius.circular(6),
        color: featured ? PassportPdfColors.surface : PassportPdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      skill.name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PassportPdfColors.ink,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      skill.domain,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PassportPdfColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (skill.statusLabel != null)
                pw.Text(
                  skill.statusLabel!,
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PassportPdfColors.muted,
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _kv('Current result', skill.formattedResult ?? '-'),
              ),
              pw.Expanded(
                child: _kv('Confidence', skill.confidenceLabel),
              ),
              pw.Expanded(
                child: _kv(
                  'Proofs',
                  '${skill.proofCount}',
                ),
              ),
            ],
          ),
          if (skill.evidenceSummary.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Evidence  ${skill.evidenceSummary}',
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PassportPdfColors.muted,
              ),
            ),
          ],
          if (skill.trendLabel != null || skill.lastUpdated != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              [
                if (skill.trendLabel != null) 'Trend: ${skill.trendLabel}',
                if (skill.lastUpdated != null)
                  'Updated ${ProofDateUtils.formatDate(skill.lastUpdated!)}',
              ].join('  ·  '),
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PassportPdfColors.lightMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _kv(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(
            fontSize: 6.5,
            color: PassportPdfColors.lightMuted,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PassportPdfColors.ink,
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends pw.StatelessWidget {
  _TimelineRow({required this.item});

  final PassportExportTimelineItem item;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 72,
          child: pw.Text(
            item.dateLabel,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PassportPdfColors.muted,
            ),
          ),
        ),
        pw.Container(
          width: 8,
          height: 8,
          margin: const pw.EdgeInsets.only(top: 2, right: 8),
          decoration: const pw.BoxDecoration(
            color: PassportPdfColors.accent,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.title,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PassportPdfColors.ink,
                ),
              ),
              if (item.description != null)
                pw.Text(
                  item.description!,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PassportPdfColors.muted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MilestoneRow extends pw.StatelessWidget {
  _MilestoneRow({required this.item});

  final PassportExportTimelineItem item;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PassportPdfColors.border),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.title,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PassportPdfColors.ink,
                  ),
                ),
                if (item.description != null)
                  pw.Text(
                    item.description!,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PassportPdfColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          pw.Text(
            item.dateLabel,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PassportPdfColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofRow extends pw.StatelessWidget {
  _ProofRow({required this.proof});

  final PassportExportProof proof;

  @override
  pw.Widget build(pw.Context context) {
    final meta = <String>[
      proof.dateLabel,
      proof.evidenceSource,
      if (proof.location != null) proof.location!,
      if (proof.hasMedia) 'Media attached',
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PassportPdfColors.border, width: 0.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  proof.skillName,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PassportPdfColors.ink,
                  ),
                ),
              ),
              pw.Text(
                proof.resultLabel,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PassportPdfColors.accent,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            meta.join('  ·  '),
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PassportPdfColors.muted,
            ),
          ),
          if (proof.notes != null)
            pw.Text(
              proof.notes!,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PassportPdfColors.lightMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfidenceExplainer extends pw.StatelessWidget {
  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PassportPdfColors.surface,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PassportPdfColors.border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ABOUT PROOF CONFIDENCE',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.8,
              color: PassportPdfColors.accent,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'PROOF Confidence reflects the strength and consistency of the '
            'evidence supporting a physical result. It may consider the number '
            'of proofs, diversity of evidence sources, long-term consistency, '
            'verification history and profile activity. Performance and '
            'confidence are evaluated separately. This document is not a legal '
            'certification.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PassportPdfColors.muted,
              lineSpacing: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
