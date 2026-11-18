/// Receipt status semantics for the Experience Engine.
///
/// ## Lifecycle
/// pending → presenting → completed | dismissed | failed
///
/// ## completed
/// The meaningful final state was shown, or the user intentionally continued
/// via the primary CTA. **Never auto-replays.**
///
/// ## dismissed
/// The user intentionally skipped before completion (Skip button), or the
/// safe animation timeout fired (12s). Treated as intentional exit.
/// **Never auto-replays** unless product policy changes explicitly.
///
/// ## failed
/// Presentation threw or could not render. Domain state is unaffected.
/// **May retry** via [ExperienceCoordinator.resumePending] on next session.
///
/// ## presenting
/// Transient while overlay is visible. If the app is killed during
/// presenting, the receipt remains presenting or pending; on resume,
/// [listResumable] may offer the moment again (failed/pending/presenting).
///
/// ## Skip vs Continue
/// - Primary CTA → completed
/// - Skip → dismissed
/// - Timeout → dismissed (user is not trapped)
///
/// ## Navigation after completion
/// Navigation runs after overlay teardown. If navigation fails, receipt
/// is still marked completed — domain success is never rolled back.

library;
