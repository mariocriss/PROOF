import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:proof/features/experience/application/experience_debug_service.dart';
import 'package:proof/features/experience/application/experience_providers.dart';
import 'package:proof/features/experience/domain/experience_event_ids.dart';
import 'package:proof/features/experience/domain/experience_receipt.dart';
import 'package:proof/features/experience/presentation/gallery/experience_diagnostics_panel.dart';
import 'package:proof/features/experience/presentation/gallery/experience_test_mode_panel.dart';
import 'package:proof/shared/providers/app_providers.dart';

/// Debug-only internal QA controls for real-flow testing.
class ExperienceTestControlsScreen extends ConsumerStatefulWidget {
  const ExperienceTestControlsScreen({super.key});

  @override
  ConsumerState<ExperienceTestControlsScreen> createState() =>
      _ExperienceTestControlsScreenState();
}

class _ExperienceTestControlsScreenState
    extends ConsumerState<ExperienceTestControlsScreen> {
  List<ExperienceReceipt> _receipts = [];
  bool _loading = false;

  String? get _uid => ref.read(authStateProvider).valueOrNull?.uid;

  Future<void> _refresh() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final debug = ref.read(experienceDebugServiceProvider);
      final all = await debug.listReceipts(uid);
      if (mounted) setState(() => _receipts = all);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearReceipts() async {
    final uid = _uid;
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear experience receipts?'),
        content: const Text(
          'This permanently deletes experience receipts for your account only.\n\n'
          'Not affected: proofs, skills, verifications, account data.\n\n'
          'After clearing, reference moments may play again on the next real trigger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear receipts'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(experienceDebugServiceProvider).clearAllReceipts(uid);
    await _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Experience receipts cleared')),
      );
    }
  }

  Future<void> _preview(String kind) async {
    final uid = _uid ?? 'debug-user';
    final debug = ref.read(experienceDebugServiceProvider);
    final event = switch (kind) {
      'onboarding' => debug.mockOnboarding(uid),
      'first' => debug.mockFirstProof(uid),
      _ => debug.mockCoachVerify(uid),
    };
    await Clipboard.setData(ClipboardData(text: event.id));
    await debug.previewEvent(event);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preview queued (no receipt written). Dismiss overlay to replay.',
          ),
        ),
      );
    }
  }

  Future<void> _testReceiptPermissions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test receipt permissions?'),
        content: const Text(
          'Creates, reads, updates, then deletes a disposable debug receipt '
          'under your own experienceReceipts collection.\n\n'
          'Does not touch proofs, skills, or account data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Run test'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result =
        await ref.read(experienceDebugServiceProvider).testReceiptPermissions();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(result.allPassed ? 'Permissions OK' : 'Permissions failed'),
        content: SingleChildScrollView(
          child: SelectableText(
            result.report,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.report));
              Navigator.pop(ctx);
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode);
    final uid = _uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Experience Test Controls'),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton(
            onPressed: () => context.push('/debug/experience-gallery'),
            child: const Text('Gallery'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ExperienceTestModePanel(),
          const SizedBox(height: 16),
          const ExperienceDiagnosticsPanel(),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _uid == null ? null : _testReceiptPermissions,
            child: const Text('Test receipt permissions'),
          ),
          const SizedBox(height: 24),
          Text(
            'Preview only (mock data, no receipts)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _btn('Preview Passport Issuance', () => _preview('onboarding')),
          _btn('Preview First Proof', () => _preview('first')),
          _btn('Preview Coach Verification', () => _preview('coach')),
          const Divider(height: 32),
          Text('Deterministic IDs', style: Theme.of(context).textTheme.titleMedium),
          if (uid != null) ...[
            _idTile('Issuance', ExperienceEventIds.onboardingCompleted(uid)),
            _idTile('First proof', ExperienceEventIds.firstProofCreated(uid)),
            _idTile(
              'Coach verify (example)',
              ExperienceEventIds.coachVerified(
                'proof-id',
                ExperienceEventIds.verificationVersionFromProof(
                  verifiedByCoachId: 'coach-id',
                ),
              ),
            ),
          ],
          const Divider(height: 32),
          Row(
            children: [
              Text('Receipts', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_receipts.isEmpty)
            const Text('No receipts for this account.')
          else
            ..._receipts.map(
              (r) => ListTile(
                title: Text(r.id, style: const TextStyle(fontSize: 12)),
                subtitle: Text('${r.eventType.value} · ${r.status.value}'),
                dense: true,
                onTap: () => Clipboard.setData(ClipboardData(text: r.id)),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            onPressed: uid == null ? null : _clearReceipts,
            child: const Text('Clear my experience receipts'),
          ),
        ],
      ),
    );
  }

  Widget _idTile(String label, String id) {
    return ListTile(
      dense: true,
      title: Text(label),
      subtitle: SelectableText(id, style: const TextStyle(fontSize: 11)),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () => Clipboard.setData(ClipboardData(text: id)),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
      ),
    );
  }
}
