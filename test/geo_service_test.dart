import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/geo_service.dart';

/// The privacy guarantee: precise GPS is rounded to a coarse (~1km) grid
/// before it is ever stored or shared. These lock that behaviour in.
void main() {
  group('GeoService.coarsen', () {
    test('rounds to 2 decimal places (~1.1km)', () {
      final c = GeoService.coarsen(51.657123, -0.396512);
      expect(c.lat, 51.66);
      expect(c.lng, -0.40);
    });

    test('drops sub-100m precision that could pinpoint a home', () {
      final a = GeoService.coarsen(51.6571, -0.3965);
      final b = GeoService.coarsen(51.6573, -0.3968); // ~30m away
      expect(a, equals(b)); // collapse to the same coarse cell
    });

    test('two genuinely different areas stay distinct', () {
      final watford = GeoService.coarsen(51.6565, -0.3903);
      final harrow = GeoService.coarsen(51.5836, -0.3464);
      expect(watford, isNot(equals(harrow)));
    });

    test('handles negative and zero coordinates', () {
      expect(GeoService.coarsen(0, 0), const CoarseLocation(0, 0));
      final c = GeoService.coarsen(-33.868820, 151.209296); // Sydney
      expect(c.lat, -33.87);
      expect(c.lng, 151.21);
    });
  });
}
