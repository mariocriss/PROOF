import 'package:flutter_test/flutter_test.dart';
import 'package:proof/core/constants/app_constants.dart';

void main() {
  test('app name is PROOF', () {
    expect(AppConstants.appName, 'PROOF');
  });
}
