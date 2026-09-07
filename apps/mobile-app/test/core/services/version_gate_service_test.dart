import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/version_gate_service.dart';

void main() {
  group('VersionGateService.parseVersion', () {
    test('parses a plain three-part version', () {
      expect(VersionGateService.parseVersion('1.2.3'), [1, 2, 3]);
    });

    test('pads missing minor/patch with zeros', () {
      expect(VersionGateService.parseVersion('2'), [2, 0, 0]);
      expect(VersionGateService.parseVersion('2.5'), [2, 5, 0]);
    });

    test('ignores a +build suffix (package_info version name form)', () {
      expect(VersionGateService.parseVersion('1.1.2+3'), [1, 1, 2]);
    });

    test('ignores a -prerelease suffix', () {
      expect(VersionGateService.parseVersion('1.4.0-beta.2'), [1, 4, 0]);
    });

    test('returns null for non-strings and unparseable input', () {
      expect(VersionGateService.parseVersion(null), isNull);
      expect(VersionGateService.parseVersion(42), isNull);
      expect(VersionGateService.parseVersion(''), isNull);
      expect(VersionGateService.parseVersion('not-a-version'), isNull);
    });
  });

  group('version ordering (via parseVersion + manual compare)', () {
    int cmp(String a, String b) {
      final pa = VersionGateService.parseVersion(a)!;
      final pb = VersionGateService.parseVersion(b)!;
      for (var i = 0; i < 3; i++) {
        final d = pa[i].compareTo(pb[i]);
        if (d != 0) return d;
      }
      return 0;
    }

    test('1.1.2 is older than 1.2.0', () {
      expect(cmp('1.1.2', '1.2.0'), lessThan(0));
    });

    test('1.10.0 is newer than 1.9.0 (numeric, not lexical)', () {
      expect(cmp('1.10.0', '1.9.0'), greaterThan(0));
    });

    test('equal versions compare equal regardless of build suffix', () {
      expect(cmp('1.1.2+3', '1.1.2+9'), 0);
    });
  });
}
