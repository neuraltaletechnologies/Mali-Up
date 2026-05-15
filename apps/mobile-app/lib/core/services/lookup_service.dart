import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LookupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches business types from Firestore under `lookups/business_types`.
  /// Falls back to [defaultBusinessTypes] when no remote data is available.
  static Future<List<Map<String, dynamic>>> fetchBusinessTypes() async {
    try {
      final doc = await _firestore.collection('lookups').doc('business_types').get();
      if (doc.exists) {
        final data = doc.data();
        final items = data?['items'] as List<dynamic>?;
        if (items != null) {
          return items.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return defaultBusinessTypes;
  }

  /// Fetches city list from Firestore under `lookups/cities`.
  /// Falls back to [defaultTanzaniaCities] when remote unavailable.
  static Future<List<Map<String, String>>> fetchCities() async {
    try {
      final doc = await _firestore.collection('lookups').doc('cities').get();
      if (doc.exists) {
        final data = doc.data();
        final items = data?['items'] as List<dynamic>?;
        if (items != null) {
          return items.cast<Map<String, String>>();
        }
      }
    } catch (_) {}
    return defaultTanzaniaCities;
  }

  // Default fallback data (kept locally only as a safe fallback)
  static const List<Map<String, dynamic>> defaultBusinessTypes = [
    {'value': 'Retail', 'en': 'Retail', 'sw': 'Uuzaji', 'icon': 'store'},
    {'value': 'Wholesale', 'en': 'Wholesale', 'sw': 'Uuzaji wa Jumla', 'icon': 'store_mall_directory'},
    {'value': 'Service', 'en': 'Service', 'sw': 'Huduma', 'icon': 'room_service'},
    {'value': 'Manufacturing', 'en': 'Manufacturing', 'sw': 'Uzalishaji', 'icon': 'build'},
    {'value': 'Food & Beverage', 'en': 'Food & Beverage', 'sw': 'Chakula na Vinywaji', 'icon': 'restaurant'},
    {'value': 'Other', 'en': 'Other', 'sw': 'Nyingine', 'icon': 'category'},
  ];

  static const List<Map<String, String>> defaultTanzaniaCities = [
    {'en': 'Dar es Salaam', 'sw': 'Dar es Salaam'},
    {'en': 'Dodoma', 'sw': 'Dodoma'},
    {'en': 'Mwanza', 'sw': 'Mwanza'},
    {'en': 'Arusha', 'sw': 'Arusha'},
    {'en': 'Mbeya', 'sw': 'Mbeya'},
    {'en': 'Other', 'sw': 'Nyingine'},
  ];

  /// Map an icon string from Firestore/default to a Flutter [IconData].
  static IconData iconFromName(String? name) {
    switch (name) {
      case 'store':
        return Icons.store;
      case 'store_mall_directory':
        return Icons.store_mall_directory;
      case 'room_service':
        return Icons.room_service;
      case 'build':
        return Icons.build;
      case 'restaurant':
        return Icons.restaurant;
      case 'category':
      default:
        return Icons.category;
    }
  }
}
