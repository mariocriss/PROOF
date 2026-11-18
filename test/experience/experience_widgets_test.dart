import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proof/features/experience/domain/experience_event.dart';
import 'package:proof/features/experience/domain/experience_event_type.dart';
import 'package:proof/features/experience/domain/experience_message_resolver.dart';
import 'package:proof/features/experience/domain/passport_stamp.dart';
import 'package:proof/features/experience/presentation/widgets/experience_guide_caption.dart';
import 'package:proof/features/experience/presentation/widgets/passport_stamp_widget.dart';

void main() {
  testWidgets('stamp has semantics label', (tester) async {
    const instance = PassportStampInstance(
      definition: PassportStampDefinition.selfReportedCircle,
      label: '24:10',
      descriptor: '5K',
      dateLabel: 'Jan 1, 2026',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PassportStampWidget(instance: instance)),
      ),
    );
    expect(find.bySemanticsLabel(instance.accessibleLabel), findsOneWidget);
  });

  testWidgets('guide caption scales with text without overflow crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: ExperienceGuideCaption(
                primary:
                    'Your first proof. Everything else builds from here.',
                secondary: 'Your story has begun.',
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('PROOF Registrar'), findsOneWidget);
  });

  testWidgets('guide off essential content still resolvable', (tester) async {
    const resolver = ExperienceMessageResolver();
    final messages = resolver.resolve(
      type: ExperienceEventType.firstProofCreated,
      context: const ExperienceContext(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text(messages.ctaLabel),
        ),
      ),
    );
    expect(find.text('View My Passport'), findsOneWidget);
  });
}
