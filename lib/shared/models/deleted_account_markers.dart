/// Markers and labels used when account deletion anonymizes retained records.
class DeletedAccountMarkers {
  DeletedAccountMarkers._();

  /// Replaces the reported user's public handle on retained moderation reports.
  static const reportedHandle = '[deleted]';

  /// User-facing attribution when a verifying coach account no longer exists.
  static const coachUnavailableLabel =
      'Verified by coach — account no longer available';
}
