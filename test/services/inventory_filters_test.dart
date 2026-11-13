import 'package:flutter_test/flutter_test.dart';
import 'package:sar_app/services/inventory_filters.dart';

void main() {
  test('default filters serialize to empty map and zero active count', () {
    final f = InventoryFilters();
    expect(f.serialize(), isEmpty);
    expect(f.activeCount, 0);
  });

  test('select, range, and list filters serialize like the PWA', () {
    final f = InventoryFilters()
      ..apartmentType = 'Studio'
      ..minPrice = '100000'
      ..maxPrice = '500000'
      ..buildingStatus = ['Under Construction', 'Ready to move in']
      ..amenities = ['hasElevator'];
    expect(f.serialize(), {
      'apartmentType': 'Studio',
      'minPrice': '100000',
      'maxPrice': '500000',
      'buildingStatus': 'Under Construction,Ready to move in',
      'amenities': 'hasElevator',
    });
    expect(f.activeCount, 5);
  });

  test('unset sentinel and empty strings are omitted', () {
    final f = InventoryFilters()
      ..status = InventoryFilters.unset
      ..minArea = '';
    expect(f.serialize(), isEmpty);
  });

  test('copy is independent of the original', () {
    final f = InventoryFilters()
      ..bedrooms = '3'
      ..amenities = ['hasBalcony'];
    final c = f.copy();
    c.bedrooms = '2';
    c.amenities.add('hasElevator');
    expect(f.bedrooms, '3');
    expect(f.amenities, ['hasBalcony']);
    expect(c.serialize(), {
      'bedrooms': '2',
      'amenities': 'hasBalcony,hasElevator',
    });
  });

  test('inventory amenity list has the 15 browse-specific entries', () {
    expect(kAmenities.length, 15);
    expect(kAmenities.first.value, 'hasBalcony');
    expect(kAmenities.first.label, 'بلكونة');
  });
}
