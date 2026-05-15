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
    {'value': 'Retail', 'en': 'Retail', 'sw': 'Uuzaji Rejareja', 'icon': 'store'},
    {'value': 'Wholesale', 'en': 'Wholesale', 'sw': 'Uuzaji wa Jumla', 'icon': 'storefront'},
    {'value': 'Supermarket', 'en': 'Supermarket', 'sw': 'Duka Kuu', 'icon': 'shopping_bag'},
    {'value': 'Grocery & Convenience', 'en': 'Grocery & Convenience', 'sw': 'Vyakula na Duka Dogo', 'icon': 'inventory_2'},
    {'value': 'Electronics & Mobile Phones', 'en': 'Electronics & Mobile Phones', 'sw': 'Vifaa vya Elektroniki na Simu', 'icon': 'phone_android'},
    {'value': 'Fashion & Boutique', 'en': 'Fashion & Boutique', 'sw': 'Mavazi na Boutique', 'icon': 'checkroom'},
    {'value': 'Tailoring & Textiles', 'en': 'Tailoring & Textiles', 'sw': 'Ususi na Vitambaa', 'icon': 'content_cut'},
    {'value': 'Beauty & Cosmetics', 'en': 'Beauty & Cosmetics', 'sw': 'Urembo na Vipodozi', 'icon': 'face'},
    {'value': 'Salon & Barber', 'en': 'Salon & Barber', 'sw': 'Saluni na Kinyozi', 'icon': 'content_cut'},
    {'value': 'Restaurant', 'en': 'Restaurant', 'sw': 'Mkahawa', 'icon': 'restaurant'},
    {'value': 'Cafe & Bakery', 'en': 'Cafe & Bakery', 'sw': 'Kahawa na Mikate', 'icon': 'bakery_dining'},
    {'value': 'Street Food', 'en': 'Street Food', 'sw': 'Chakula cha Mtaani', 'icon': 'lunch_dining'},
    {'value': 'Catering', 'en': 'Catering', 'sw': 'Upishi na Huduma za Chakula', 'icon': 'restaurant'},
    {'value': 'Agriculture', 'en': 'Agriculture', 'sw': 'Kilimo', 'icon': 'agriculture'},
    {'value': 'Agribusiness', 'en': 'Agribusiness', 'sw': 'Biashara ya Kilimo', 'icon': 'agriculture'},
    {'value': 'Livestock & Poultry', 'en': 'Livestock & Poultry', 'sw': 'Mifugo na Kuku', 'icon': 'pets'},
    {'value': 'Fishing', 'en': 'Fishing', 'sw': 'Uvuvi', 'icon': 'agriculture'},
    {'value': 'Manufacturing', 'en': 'Manufacturing', 'sw': 'Uzalishaji', 'icon': 'build'},
    {'value': 'Construction', 'en': 'Construction', 'sw': 'Ujenzi', 'icon': 'construction'},
    {'value': 'Hardware & Building Materials', 'en': 'Hardware & Building Materials', 'sw': 'Vifaa vya Ujenzi', 'icon': 'handyman'},
    {'value': 'Transportation & Logistics', 'en': 'Transportation & Logistics', 'sw': 'Usafirishaji na Logistiki', 'icon': 'local_shipping'},
    {'value': 'Travel & Tours', 'en': 'Travel & Tours', 'sw': 'Safari na Utalii', 'icon': 'travel_explore'},
    {'value': 'Hotel & Accommodation', 'en': 'Hotel & Accommodation', 'sw': 'Hoteli na Malazi', 'icon': 'hotel'},
    {'value': 'Pharmacy & Healthcare', 'en': 'Pharmacy & Healthcare', 'sw': 'Famasia na Afya', 'icon': 'medical_services'},
    {'value': 'Clinic & Laboratory', 'en': 'Clinic & Laboratory', 'sw': 'Kliniki na Maabara', 'icon': 'medical_services'},
    {'value': 'Education & Training', 'en': 'Education & Training', 'sw': 'Elimu na Mafunzo', 'icon': 'school'},
    {'value': 'Real Estate', 'en': 'Real Estate', 'sw': 'Mali Isiyohamishika', 'icon': 'real_estate_agent'},
    {'value': 'Financial Services', 'en': 'Financial Services', 'sw': 'Huduma za Kifedha', 'icon': 'account_balance'},
    {'value': 'ICT & Software', 'en': 'ICT & Software', 'sw': 'TEHAMA na Programu', 'icon': 'computer'},
    {'value': 'Printing & Stationery', 'en': 'Printing & Stationery', 'sw': 'Uchapishaji na Vifaa vya Ofisi', 'icon': 'print'},
    {'value': 'Automotive & Spare Parts', 'en': 'Automotive & Spare Parts', 'sw': 'Magari na Vipuri', 'icon': 'directions_car'},
    {'value': 'Fuel & Lubricants', 'en': 'Fuel & Lubricants', 'sw': 'Mafuta na Vilainishi', 'icon': 'local_gas_station'},
    {'value': 'E-commerce', 'en': 'E-commerce', 'sw': 'Biashara Mtandaoni', 'icon': 'shopping_bag'},
    {'value': 'Entertainment & Events', 'en': 'Entertainment & Events', 'sw': 'Burudani na Matukio', 'icon': 'campaign'},
    {'value': 'Cleaning Services', 'en': 'Cleaning Services', 'sw': 'Huduma za Usafi', 'icon': 'cleaning_services'},
    {'value': 'Security Services', 'en': 'Security Services', 'sw': 'Huduma za Ulinzi', 'icon': 'security'},
    {'value': 'NGO & Community Services', 'en': 'NGO & Community Services', 'sw': 'Asasi na Huduma za Jamii', 'icon': 'category'},
    {'value': 'Export & Import', 'en': 'Export & Import', 'sw': 'Uuzaji wa Nje na Uagizaji', 'icon': 'local_shipping'},
    {'value': 'Agricultural Inputs', 'en': 'Agricultural Inputs', 'sw': 'Vifaa na Pembejeo za Kilimo', 'icon': 'agriculture'},
    {'value': 'Media & Communications', 'en': 'Media & Communications', 'sw': 'Vyombo vya Habari na Mawasiliano', 'icon': 'campaign'},
    {'value': 'Jewelry & Crafts', 'en': 'Jewelry & Crafts', 'sw': 'Vito na Ufundi', 'icon': 'sell'},
    {'value': 'Furniture & Carpentry', 'en': 'Furniture & Carpentry', 'sw': 'Samani na Useremala', 'icon': 'home'},
    {'value': 'Water & Beverages', 'en': 'Water & Beverages', 'sw': 'Maji na Vinywaji', 'icon': 'local_drink'},
    {'value': 'Auto Repair', 'en': 'Auto Repair', 'sw': 'Matengenezo ya Magari', 'icon': 'build'},
    {'value': 'Other', 'en': 'Other', 'sw': 'Nyingine', 'icon': 'category'},
  ];

  static const List<Map<String, String>> defaultTanzaniaCities = [
    {'en': 'Dar es Salaam', 'sw': 'Dar es Salaam'},
    {'en': 'Dodoma', 'sw': 'Dodoma'},
    {'en': 'Mwanza', 'sw': 'Mwanza'},
    {'en': 'Arusha', 'sw': 'Arusha'},
    {'en': 'Mbeya', 'sw': 'Mbeya'},
    {'en': 'Tanga', 'sw': 'Tanga'},
    {'en': 'Morogoro', 'sw': 'Morogoro'},
    {'en': 'Iringa', 'sw': 'Iringa'},
    {'en': 'Tabora', 'sw': 'Tabora'},
    {'en': 'Kigoma', 'sw': 'Kigoma'},
    {'en': 'Moshi', 'sw': 'Moshi'},
    {'en': 'Shinyanga', 'sw': 'Shinyanga'},
    {'en': 'Singida', 'sw': 'Singida'},
    {'en': 'Songea', 'sw': 'Songea'},
    {'en': 'Bukoba', 'sw': 'Bukoba'},
    {'en': 'Musoma', 'sw': 'Musoma'},
    {'en': 'Sumbawanga', 'sw': 'Sumbawanga'},
    {'en': 'Geita', 'sw': 'Geita'},
    {'en': 'Kahama', 'sw': 'Kahama'},
    {'en': 'Mtwara', 'sw': 'Mtwara'},
    {'en': 'Lindi', 'sw': 'Lindi'},
    {'en': 'Njombe', 'sw': 'Njombe'},
    {'en': 'Mpanda', 'sw': 'Mpanda'},
    {'en': 'Babati', 'sw': 'Babati'},
    {'en': 'Kibaha', 'sw': 'Kibaha'},
    {'en': 'Handeni', 'sw': 'Handeni'},
    {'en': 'Korogwe', 'sw': 'Korogwe'},
    {'en': 'Bagamoyo', 'sw': 'Bagamoyo'},
    {'en': 'Ifakara', 'sw': 'Ifakara'},
    {'en': 'Sengerema', 'sw': 'Sengerema'},
    {'en': 'Nzega', 'sw': 'Nzega'},
    {'en': 'Bariadi', 'sw': 'Bariadi'},
    {'en': 'Masasi', 'sw': 'Masasi'},
    {'en': 'Newala', 'sw': 'Newala'},
    {'en': 'Tukuyu', 'sw': 'Tukuyu'},
    {'en': 'Tunduma', 'sw': 'Tunduma'},
    {'en': 'Tunduru', 'sw': 'Tunduru'},
    {'en': 'Tarime', 'sw': 'Tarime'},
    {'en': 'Kasulu', 'sw': 'Kasulu'},
    {'en': 'Kibondo', 'sw': 'Kibondo'},
    {'en': 'Uvinza', 'sw': 'Uvinza'},
    {'en': 'Same', 'sw': 'Same'},
    {'en': 'Kilosa', 'sw': 'Kilosa'},
    {'en': 'Mkuranga', 'sw': 'Mkuranga'},
    {'en': 'Chalinze', 'sw': 'Chalinze'},
    {'en': 'Kibaigwa', 'sw': 'Kibaigwa'},
    {'en': 'Vwawa', 'sw': 'Vwawa'},
    {'en': 'Mafinga', 'sw': 'Mafinga'},
    {'en': 'Pemba', 'sw': 'Pemba'},
    {'en': 'Wete', 'sw': 'Wete'},
    {'en': 'Chake Chake', 'sw': 'Chake Chake'},
    {'en': 'Other', 'sw': 'Nyingine'},
  ];

  /// Map an icon string from Firestore/default to a Flutter [IconData].
  static IconData iconFromName(String? name) {
    switch (name) {
      case 'store':
        return Icons.store;
      case 'storefront':
        return Icons.storefront;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'phone_android':
        return Icons.phone_android;
      case 'checkroom':
        return Icons.checkroom;
      case 'content_cut':
        return Icons.content_cut;
      case 'face':
        return Icons.face;
      case 'build':
        return Icons.build;
      case 'construction':
        return Icons.construction;
      case 'handyman':
        return Icons.handyman;
      case 'restaurant':
        return Icons.restaurant;
      case 'bakery_dining':
        return Icons.bakery_dining;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'agriculture':
        return Icons.agriculture;
      case 'pets':
        return Icons.pets;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'travel_explore':
        return Icons.travel_explore;
      case 'hotel':
        return Icons.hotel;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'real_estate_agent':
        return Icons.real_estate_agent;
      case 'account_balance':
        return Icons.account_balance;
      case 'computer':
        return Icons.computer;
      case 'print':
        return Icons.print;
      case 'directions_car':
        return Icons.directions_car;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'campaign':
        return Icons.campaign;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'security':
        return Icons.security;
      case 'sell':
        return Icons.sell;
      case 'local_drink':
        return Icons.local_drink;
      case 'category':
      default:
        return Icons.category;
    }
  }
}
