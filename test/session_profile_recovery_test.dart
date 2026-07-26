import 'package:flutter_test/flutter_test.dart';

enum SessionProfileGate { loading, recovery, ready }

SessionProfileGate sessionProfileGate({
  required bool authenticated,
  required bool loading,
  required bool hasProfile,
  required bool hasError,
  required bool timedOut,
}) {
  if (!authenticated || hasProfile) return SessionProfileGate.ready;
  if (hasError || (!loading && !hasProfile) || timedOut) {
    return SessionProfileGate.recovery;
  }
  return SessionProfileGate.loading;
}

void main() {
  test('profile failures and missing terminal profiles recover', () {
    expect(
      sessionProfileGate(
        authenticated: true,
        loading: true,
        hasProfile: false,
        hasError: true,
        timedOut: false,
      ),
      SessionProfileGate.recovery,
    );
    expect(
      sessionProfileGate(
        authenticated: true,
        loading: false,
        hasProfile: false,
        hasError: false,
        timedOut: false,
      ),
      SessionProfileGate.recovery,
    );
  });

  test('only a pending profile remains loading', () {
    expect(
      sessionProfileGate(
        authenticated: true,
        loading: true,
        hasProfile: false,
        hasError: false,
        timedOut: false,
      ),
      SessionProfileGate.loading,
    );
  });
}
