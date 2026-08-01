import 'package:flutter_test/flutter_test.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';

void main() {
  group('Category Model Tests', () {
    test('Category.fromMap parses correctly', () {
      final map = {
        'name': 'Premium EDP',
        'imageUrl': 'https://example.com/image.jpg',
        'description': 'Premium Eau De Parfum collection'
      };

      final category = Category.fromMap('test-id-123', map);

      expect(category.id, 'test-id-123');
      expect(category.name, 'Premium EDP');
      expect(category.imageUrl, 'https://example.com/image.jpg');
      expect(category.description, 'Premium Eau De Parfum collection');
    });

    test('Category.toMap outputs correctly', () {
      final category = Category(
        id: 'test-id-123',
        name: 'Attar Oils',
        imageUrl: 'https://example.com/attar.jpg',
        description: 'Concentrated perfume oils',
      );

      final map = category.toMap();

      expect(map['name'], 'Attar Oils');
      expect(map['imageUrl'], 'https://example.com/attar.jpg');
      expect(map['description'], 'Concentrated perfume oils');
    });
  });
}
