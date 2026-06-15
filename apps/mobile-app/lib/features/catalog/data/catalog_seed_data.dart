import '../domain/models/master_category.dart';
import '../domain/models/master_product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Industry Master Catalog — bundled seed data for Tanzania SMEs.
//
// Used as the offline fallback when Firestore has not yet been populated, and
// to pre-populate the local Drift cache on first use so the catalog works
// without any network round-trip.
//
// All prices are in TSh (Tanzanian Shillings) and are suggestions only.
// Users must set their own cost/selling prices after import.
// ─────────────────────────────────────────────────────────────────────────────

// ── Business type IDs ────────────────────────────────────────────────────────
// These must match the normalised keys returned by _normalizeBusinessType() in
// category_providers.dart.
const String _kPharmacy = 'pharmacy';
const String _kRestaurant = 'restaurant';
const String _kElectronics = 'electronics';
const String _kRetail = 'retail';
const String _kWholesale = 'wholesale';
const String _kSalon = 'salon';
const String _kHardware = 'hardware';
const String _kAgriculture = 'agriculture';
const String _kTailoring = 'tailoring';
const String _kTransport = 'transport';

// ─────────────────────────────────────────────────────────────────────────────
// Categories
// ─────────────────────────────────────────────────────────────────────────────

final List<MasterCategory> masterCatalogCategories = [
  // ── Pharmacy ───────────────────────────────────────────────────────────────
  _cat('pharmacy_painkillers', _kPharmacy, 'Painkillers', icon: 'medication'),
  _cat('pharmacy_antibiotics', _kPharmacy, 'Antibiotics', icon: 'medication'),
  _cat('pharmacy_vitamins', _kPharmacy, 'Vitamins & Supplements', icon: 'science'),
  _cat('pharmacy_baby', _kPharmacy, 'Baby Care', icon: 'child_care'),
  _cat('pharmacy_first_aid', _kPharmacy, 'First Aid', icon: 'health_and_safety'),
  _cat('pharmacy_personal_care', _kPharmacy, 'Personal Care', icon: 'spa'),
  _cat('pharmacy_medical_equipment', _kPharmacy, 'Medical Equipment', icon: 'medical_services'),
  _cat('pharmacy_herbal', _kPharmacy, 'Herbal Products', icon: 'eco'),
  _cat('pharmacy_otc', _kPharmacy, 'Over The Counter', icon: 'local_pharmacy'),

  // ── Restaurant ─────────────────────────────────────────────────────────────
  _cat('resto_grains', _kRestaurant, 'Grains & Flours', icon: 'restaurant'),
  _cat('resto_oil_fats', _kRestaurant, 'Oils & Fats', icon: 'restaurant'),
  _cat('resto_spices', _kRestaurant, 'Spices & Condiments', icon: 'restaurant'),
  _cat('resto_beverages', _kRestaurant, 'Beverages', icon: 'local_bar'),
  _cat('resto_meat', _kRestaurant, 'Meat & Poultry', icon: 'restaurant'),
  _cat('resto_vegetables', _kRestaurant, 'Vegetables & Produce', icon: 'local_florist'),
  _cat('resto_packaging', _kRestaurant, 'Packaging Materials', icon: 'inventory'),
  _cat('resto_dairy', _kRestaurant, 'Dairy & Eggs', icon: 'egg'),

  // ── Electronics ────────────────────────────────────────────────────────────
  _cat('elec_phones', _kElectronics, 'Smartphones', icon: 'smartphone'),
  _cat('elec_accessories', _kElectronics, 'Accessories & Cables', icon: 'cable'),
  _cat('elec_chargers', _kElectronics, 'Chargers & Power Banks', icon: 'battery_charging_full'),
  _cat('elec_audio', _kElectronics, 'Audio & Headphones', icon: 'headphones'),
  _cat('elec_laptops', _kElectronics, 'Laptops & Computers', icon: 'laptop'),
  _cat('elec_tv', _kElectronics, 'TVs & Displays', icon: 'tv'),
  _cat('elec_smart_home', _kElectronics, 'Smart Home Devices', icon: 'home'),

  // ── Retail / Supermarket ───────────────────────────────────────────────────
  _cat('retail_groceries', _kRetail, 'Groceries', icon: 'local_grocery_store'),
  _cat('retail_beverages', _kRetail, 'Beverages', icon: 'local_bar'),
  _cat('retail_snacks', _kRetail, 'Snacks & Confectionery', icon: 'fastfood'),
  _cat('retail_household', _kRetail, 'Household Items', icon: 'home'),
  _cat('retail_personal_care', _kRetail, 'Personal Care', icon: 'spa'),
  _cat('retail_cleaning', _kRetail, 'Cleaning Supplies', icon: 'cleaning_services'),
  _cat('retail_stationery', _kRetail, 'Stationery', icon: 'edit'),

  // ── Wholesale ──────────────────────────────────────────────────────────────
  _cat('wholesale_groceries', _kWholesale, 'Groceries (Bulk)', icon: 'local_grocery_store'),
  _cat('wholesale_household', _kWholesale, 'Household Products', icon: 'home'),
  _cat('wholesale_cleaning', _kWholesale, 'Cleaning Supplies', icon: 'cleaning_services'),
  _cat('wholesale_packaging', _kWholesale, 'Packaging', icon: 'inventory'),
  _cat('wholesale_general', _kWholesale, 'General Merchandise', icon: 'store'),

  // ── Salon & Barber ─────────────────────────────────────────────────────────
  _cat('salon_hair_products', _kSalon, 'Hair Products', icon: 'content_cut'),
  _cat('salon_skin_care', _kSalon, 'Skin Care', icon: 'spa'),
  _cat('salon_nail', _kSalon, 'Nail Products', icon: 'brush'),
  _cat('salon_equipment', _kSalon, 'Salon Equipment', icon: 'chair'),
  _cat('salon_cosmetics', _kSalon, 'Cosmetics & Makeup', icon: 'face_retouching_natural'),
  _cat('salon_wigs', _kSalon, 'Wigs & Extensions', icon: 'face_retouching_natural'),

  // ── Hardware ───────────────────────────────────────────────────────────────
  _cat('hw_building', _kHardware, 'Building Materials', icon: 'construction'),
  _cat('hw_electrical', _kHardware, 'Electrical Supplies', icon: 'electrical_services'),
  _cat('hw_plumbing', _kHardware, 'Plumbing Supplies', icon: 'plumbing'),
  _cat('hw_tools', _kHardware, 'Hand & Power Tools', icon: 'handyman'),
  _cat('hw_paint', _kHardware, 'Paint & Coatings', icon: 'format_paint'),
  _cat('hw_safety', _kHardware, 'Safety Equipment', icon: 'safety_check'),

  // ── Agriculture ────────────────────────────────────────────────────────────
  _cat('agri_seeds', _kAgriculture, 'Seeds', icon: 'grass'),
  _cat('agri_fertilizers', _kAgriculture, 'Fertilizers', icon: 'science'),
  _cat('agri_pesticides', _kAgriculture, 'Pesticides & Herbicides', icon: 'bug_report'),
  _cat('agri_feeds', _kAgriculture, 'Animal Feeds', icon: 'pets'),
  _cat('agri_produce', _kAgriculture, 'Produce & Harvest', icon: 'agriculture'),
  _cat('agri_tools', _kAgriculture, 'Farming Tools', icon: 'handyman'),

  // ── Tailoring / Boutique ───────────────────────────────────────────────────
  _cat('tailor_mens', _kTailoring, "Men's Clothing", icon: 'man'),
  _cat('tailor_womens', _kTailoring, "Women's Clothing", icon: 'woman'),
  _cat('tailor_kids', _kTailoring, "Children's Clothing", icon: 'child_friendly'),
  _cat('tailor_shoes', _kTailoring, 'Shoes & Footwear', icon: 'directions_walk'),
  _cat('tailor_fabrics', _kTailoring, 'Fabrics & Textiles', icon: 'dry_cleaning'),
  _cat('tailor_accessories', _kTailoring, 'Bags & Accessories', icon: 'shopping_bag'),

  // ── Transport / Automotive ─────────────────────────────────────────────────
  _cat('auto_fuel', _kTransport, 'Fuel & Lubricants', icon: 'local_gas_station'),
  _cat('auto_tyres', _kTransport, 'Tyres & Tubes', icon: 'tire_repair'),
  _cat('auto_spare', _kTransport, 'Spare Parts', icon: 'build'),
  _cat('auto_accessories', _kTransport, 'Accessories', icon: 'car_repair'),
  _cat('auto_maintenance', _kTransport, 'Maintenance Supplies', icon: 'build_circle'),
];

MasterCategory _cat(String id, String bizType, String name, {String icon = ''}) {
  return MasterCategory(
    id: id,
    businessTypeId: bizType,
    categoryName: name,
    icon: icon,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Products
// ─────────────────────────────────────────────────────────────────────────────

final List<MasterProduct> masterCatalogProducts = [
  // ══════════════════════════════════════════════════════════════════════════
  // PHARMACY
  // ══════════════════════════════════════════════════════════════════════════

  // Painkillers
  _prod('ph_paracetamol_500', _kPharmacy, 'pharmacy_painkillers', 'Paracetamol 500mg',
      unit: 'strips', cost: 400, sell: 600,
      kw: ['paracetamol', 'panadol', 'dawa ya maumivu', 'analgesic', 'fever']),
  _prod('ph_paracetamol_syrup', _kPharmacy, 'pharmacy_painkillers', 'Paracetamol Syrup 120mg/5ml',
      unit: 'bottles', cost: 1800, sell: 2500,
      kw: ['paracetamol syrup', 'panadol syrup', 'watoto', 'children fever']),
  _prod('ph_ibuprofen_200', _kPharmacy, 'pharmacy_painkillers', 'Ibuprofen 200mg',
      unit: 'strips', cost: 500, sell: 800,
      kw: ['ibuprofen', 'brufen', 'pain', 'anti-inflammatory', 'maumivu']),
  _prod('ph_diclofenac_50', _kPharmacy, 'pharmacy_painkillers', 'Diclofenac 50mg',
      unit: 'strips', cost: 600, sell: 900,
      kw: ['diclofenac', 'voltaren', 'joint pain', 'maumivu ya viungo']),
  _prod('ph_aspirin_100', _kPharmacy, 'pharmacy_painkillers', 'Aspirin 100mg',
      unit: 'strips', cost: 400, sell: 600,
      kw: ['aspirin', 'aspro', 'dawa ya moyo', 'blood thinner']),

  // Antibiotics
  _prod('ph_amoxicillin_250', _kPharmacy, 'pharmacy_antibiotics', 'Amoxicillin 250mg Capsules',
      unit: 'strips', cost: 1000, sell: 1500,
      kw: ['amoxicillin', 'amoxil', 'antibiotic', 'maambukizi']),
  _prod('ph_amoxicillin_500', _kPharmacy, 'pharmacy_antibiotics', 'Amoxicillin 500mg Capsules',
      unit: 'strips', cost: 1500, sell: 2200,
      kw: ['amoxicillin 500', 'amoxil 500', 'antibiotic', 'maambukizi']),
  _prod('ph_metronidazole_200', _kPharmacy, 'pharmacy_antibiotics', 'Metronidazole 200mg',
      unit: 'strips', cost: 700, sell: 1100,
      kw: ['metronidazole', 'flagyl', 'dawa ya tumbo', 'amoebiasis']),
  _prod('ph_cotrimoxazole', _kPharmacy, 'pharmacy_antibiotics', 'Cotrimoxazole 480mg',
      unit: 'strips', cost: 500, sell: 800,
      kw: ['cotrimoxazole', 'septrin', 'bactrim', 'maambukizi']),
  _prod('ph_ciprofloxacin_500', _kPharmacy, 'pharmacy_antibiotics', 'Ciprofloxacin 500mg',
      unit: 'strips', cost: 1200, sell: 1800,
      kw: ['ciprofloxacin', 'cipro', 'antibiotic', 'urinary tract']),
  _prod('ph_doxycycline_100', _kPharmacy, 'pharmacy_antibiotics', 'Doxycycline 100mg',
      unit: 'strips', cost: 900, sell: 1400,
      kw: ['doxycycline', 'vibramycin', 'malaria', 'antibiotic']),

  // Vitamins
  _prod('ph_vitamin_c', _kPharmacy, 'pharmacy_vitamins', 'Vitamin C 500mg',
      unit: 'strips', cost: 800, sell: 1200,
      kw: ['vitamin c', 'ascorbic acid', 'immune', 'kinga']),
  _prod('ph_multivitamin', _kPharmacy, 'pharmacy_vitamins', 'Multivitamin Tablets',
      unit: 'bottles', cost: 5000, sell: 8000,
      kw: ['multivitamin', 'vitamini', 'supplement', 'nguvu']),
  _prod('ph_zinc_sulphate', _kPharmacy, 'pharmacy_vitamins', 'Zinc Sulphate 20mg',
      unit: 'strips', cost: 600, sell: 900,
      kw: ['zinc', 'zinc sulphate', 'diarrhea', 'kuhara', 'immune']),
  _prod('ph_folic_acid', _kPharmacy, 'pharmacy_vitamins', 'Folic Acid 5mg',
      unit: 'strips', cost: 400, sell: 600,
      kw: ['folic acid', 'folate', 'pregnancy', 'mimba', 'mama']),
  _prod('ph_iron_tabs', _kPharmacy, 'pharmacy_vitamins', 'Ferrous Sulphate (Iron) 200mg',
      unit: 'strips', cost: 500, sell: 800,
      kw: ['iron', 'ferrous sulphate', 'anaemia', 'upungufu wa damu', 'pregnancy']),

  // Baby Care
  _prod('ph_ors_sachet', _kPharmacy, 'pharmacy_baby', 'ORS Sachet (Oral Rehydration)',
      unit: 'sachets', cost: 200, sell: 400,
      kw: ['ors', 'oral rehydration', 'kuhara', 'diarrhoea', 'watoto']),
  _prod('ph_gripe_water', _kPharmacy, 'pharmacy_baby', 'Gripe Water',
      unit: 'bottles', cost: 2500, sell: 4000,
      kw: ['gripe water', 'mtoto', 'colic', 'baby stomach']),
  _prod('ph_baby_paracetamol', _kPharmacy, 'pharmacy_baby', 'Baby Paracetamol Drops',
      unit: 'bottles', cost: 3000, sell: 4500,
      kw: ['baby paracetamol', 'drops', 'watoto', 'homa', 'fever']),

  // First Aid
  _prod('ph_cotton_wool', _kPharmacy, 'pharmacy_first_aid', 'Cotton Wool 100g',
      unit: 'rolls', cost: 1000, sell: 1500,
      kw: ['cotton wool', 'pamba', 'first aid', 'wound']),
  _prod('ph_bandage', _kPharmacy, 'pharmacy_first_aid', 'Crepe Bandage 10cm',
      unit: 'rolls', cost: 1500, sell: 2500,
      kw: ['bandage', 'bendeji', 'wound dressing', 'first aid']),
  _prod('ph_plaster', _kPharmacy, 'pharmacy_first_aid', 'Adhesive Plaster (Band-Aid)',
      unit: 'boxes', cost: 800, sell: 1500,
      kw: ['plaster', 'band aid', 'wound', 'kidonda', 'first aid']),
  _prod('ph_antiseptic', _kPharmacy, 'pharmacy_first_aid', 'Dettol Antiseptic 250ml',
      unit: 'bottles', cost: 3500, sell: 5000,
      kw: ['dettol', 'antiseptic', 'disinfectant', 'wound cleaning', 'kidonda']),
  _prod('ph_gloves', _kPharmacy, 'pharmacy_first_aid', 'Disposable Gloves (Box of 100)',
      unit: 'boxes', cost: 8000, sell: 12000,
      kw: ['gloves', 'mipira', 'disposable', 'medical']),

  // Personal Care
  _prod('ph_condoms', _kPharmacy, 'pharmacy_personal_care', 'Condoms (Box of 12)',
      unit: 'boxes', cost: 800, sell: 1500,
      kw: ['condom', 'kondom', 'family planning', 'protection']),
  _prod('ph_bp_pills', _kPharmacy, 'pharmacy_otc', 'Amlodipine 5mg',
      unit: 'strips', cost: 800, sell: 1200,
      kw: ['amlodipine', 'blood pressure', 'shinikizo la damu', 'bp']),
  _prod('ph_metformin', _kPharmacy, 'pharmacy_otc', 'Metformin 500mg',
      unit: 'strips', cost: 600, sell: 1000,
      kw: ['metformin', 'glucophage', 'diabetes', 'ugonjwa wa sukari']),
  _prod('ph_albendazole', _kPharmacy, 'pharmacy_otc', 'Albendazole 400mg',
      unit: 'tablets', cost: 500, sell: 800,
      kw: ['albendazole', 'zentel', 'deworming', 'minyoo', 'worms']),

  // ══════════════════════════════════════════════════════════════════════════
  // RESTAURANT / FOOD
  // ══════════════════════════════════════════════════════════════════════════

  // Grains
  _prod('re_rice_kg', _kRestaurant, 'resto_grains', 'Rice (Mchele) 1kg',
      unit: 'kg', cost: 2200, sell: 2800,
      kw: ['mchele', 'rice', 'wali', 'chakula']),
  _prod('re_flour_kg', _kRestaurant, 'resto_grains', 'Wheat Flour (Unga wa Ngano) 1kg',
      unit: 'kg', cost: 1800, sell: 2200,
      kw: ['unga', 'flour', 'ngano', 'wheat']),
  _prod('re_maize_flour', _kRestaurant, 'resto_grains', 'Maize Flour (Unga wa Mahindi) 2kg',
      unit: 'kg', cost: 2000, sell: 2500,
      kw: ['unga wa mahindi', 'maize flour', 'ugali']),
  _prod('re_sugar_kg', _kRestaurant, 'resto_grains', 'Sugar (Sukari) 1kg',
      unit: 'kg', cost: 2500, sell: 3000,
      kw: ['sukari', 'sugar', 'sweetener']),

  // Oils & Fats
  _prod('re_cooking_oil_1l', _kRestaurant, 'resto_oil_fats', 'Cooking Oil 1 Litre',
      unit: 'bottles', cost: 4500, sell: 5500,
      kw: ['mafuta ya kupikia', 'cooking oil', 'vegetable oil']),
  _prod('re_butter', _kRestaurant, 'resto_oil_fats', 'Margarine / Butter 250g',
      unit: 'pcs', cost: 2500, sell: 3200,
      kw: ['siagi', 'butter', 'margarine', 'blueband']),

  // Spices
  _prod('re_salt', _kRestaurant, 'resto_spices', 'Table Salt (Chumvi) 500g',
      unit: 'packets', cost: 400, sell: 600,
      kw: ['chumvi', 'salt', 'chakula']),
  _prod('re_tomato_paste', _kRestaurant, 'resto_spices', 'Tomato Paste 400g',
      unit: 'cans', cost: 1500, sell: 2000,
      kw: ['tomato paste', 'nyanya', 'tomato']),
  _prod('re_royco', _kRestaurant, 'resto_spices', 'Royco Seasoning Cubes (Box)',
      unit: 'boxes', cost: 2000, sell: 2800,
      kw: ['royco', 'mchuzi mix', 'seasoning', 'spices', 'mchuzi']),
  _prod('re_ketchup', _kRestaurant, 'resto_spices', 'Tomato Sauce / Ketchup 500ml',
      unit: 'bottles', cost: 3000, sell: 4000,
      kw: ['ketchup', 'tomato sauce', 'tomato ketchup']),

  // Beverages
  _prod('re_water_500', _kRestaurant, 'resto_beverages', 'Drinking Water 500ml',
      unit: 'bottles', cost: 300, sell: 500,
      kw: ['maji', 'water', 'drinking water', 'mineral water']),
  _prod('re_water_1l', _kRestaurant, 'resto_beverages', 'Drinking Water 1.5L',
      unit: 'bottles', cost: 600, sell: 1000,
      kw: ['maji', 'water', '1.5 litre', 'mineral water']),
  _prod('re_soda_330', _kRestaurant, 'resto_beverages', 'Soda / Soft Drink 330ml',
      unit: 'bottles', cost: 800, sell: 1200,
      kw: ['soda', 'soft drink', 'fanta', 'coke', 'pepsi', 'kinywaji']),
  _prod('re_juice_500', _kRestaurant, 'resto_beverages', 'Juice 500ml',
      unit: 'bottles', cost: 1500, sell: 2000,
      kw: ['juice', 'juisi', 'fruit juice', 'kinywaji']),

  // Packaging
  _prod('re_takeaway_box', _kRestaurant, 'resto_packaging', 'Takeaway Food Box (Pack of 50)',
      unit: 'packs', cost: 5000, sell: 7000,
      kw: ['takeaway box', 'food container', 'packaging']),
  _prod('re_plastic_bags', _kRestaurant, 'resto_packaging', 'Plastic Carrier Bags (Bundle)',
      unit: 'bundles', cost: 2000, sell: 3000,
      kw: ['plastic bags', 'mifuko', 'carrier bags', 'packaging']),

  // ══════════════════════════════════════════════════════════════════════════
  // ELECTRONICS
  // ══════════════════════════════════════════════════════════════════════════

  _prod('el_iphone_15', _kElectronics, 'elec_phones', 'Apple iPhone 15 128GB',
      unit: 'pcs', cost: 1100000, sell: 1350000,
      kw: ['iphone 15', 'apple', 'iphone', 'smartphone']),
  _prod('el_samsung_a15', _kElectronics, 'elec_phones', 'Samsung Galaxy A15',
      unit: 'pcs', cost: 280000, sell: 350000,
      kw: ['samsung a15', 'samsung galaxy', 'android', 'smartphone']),
  _prod('el_samsung_a55', _kElectronics, 'elec_phones', 'Samsung Galaxy A55',
      unit: 'pcs', cost: 550000, sell: 680000,
      kw: ['samsung a55', 'samsung galaxy', 'android', 'smartphone']),
  _prod('el_tecno_spark', _kElectronics, 'elec_phones', 'Tecno Spark 20',
      unit: 'pcs', cost: 200000, sell: 260000,
      kw: ['tecno', 'tecno spark', 'android', 'simu']),
  _prod('el_infinix_hot', _kElectronics, 'elec_phones', 'Infinix Hot 40',
      unit: 'pcs', cost: 230000, sell: 300000,
      kw: ['infinix', 'infinix hot', 'android', 'simu']),
  _prod('el_itel_a70', _kElectronics, 'elec_phones', 'itel A70',
      unit: 'pcs', cost: 120000, sell: 160000,
      kw: ['itel', 'itel a70', 'android', 'simu nafuu']),
  _prod('el_charger_typec', _kElectronics, 'elec_chargers', 'USB-C Charger 65W',
      unit: 'pcs', cost: 15000, sell: 25000,
      kw: ['charger', 'type c', 'usb c', 'chaja', 'fast charger']),
  _prod('el_charger_cable', _kElectronics, 'elec_accessories', 'USB-C to USB-C Cable 1m',
      unit: 'pcs', cost: 4000, sell: 8000,
      kw: ['cable', 'usb c', 'charging cable', 'waya']),
  _prod('el_earphones', _kElectronics, 'elec_audio', 'Wired Earphones with Mic',
      unit: 'pcs', cost: 5000, sell: 9000,
      kw: ['earphones', 'headphones', 'earbuds', 'masikio']),
  _prod('el_power_bank', _kElectronics, 'elec_chargers', 'Power Bank 10000mAh',
      unit: 'pcs', cost: 20000, sell: 32000,
      kw: ['power bank', 'battery', 'portable charger', 'chaja']),
  _prod('el_screen_protector', _kElectronics, 'elec_accessories', 'Tempered Glass Screen Protector',
      unit: 'pcs', cost: 2000, sell: 5000,
      kw: ['screen protector', 'tempered glass', 'glass', 'simu']),
  _prod('el_phone_case', _kElectronics, 'elec_accessories', 'Phone Back Cover / Case',
      unit: 'pcs', cost: 3000, sell: 6000,
      kw: ['phone case', 'back cover', 'cover', 'simu']),
  _prod('el_bluetooth_speaker', _kElectronics, 'elec_audio', 'Bluetooth Speaker Portable',
      unit: 'pcs', cost: 25000, sell: 40000,
      kw: ['bluetooth speaker', 'speaker', 'spika', 'wireless']),
  _prod('el_laptop_hp', _kElectronics, 'elec_laptops', 'HP Laptop 15.6" Core i5',
      unit: 'pcs', cost: 950000, sell: 1200000,
      kw: ['hp laptop', 'laptop', 'computer', 'kompyuta']),
  _prod('el_laptop_lenovo', _kElectronics, 'elec_laptops', 'Lenovo IdeaPad Core i3',
      unit: 'pcs', cost: 700000, sell: 900000,
      kw: ['lenovo', 'laptop', 'computer', 'kompyuta']),
  _prod('el_flash_disk', _kElectronics, 'elec_accessories', 'USB Flash Disk 32GB',
      unit: 'pcs', cost: 8000, sell: 15000,
      kw: ['flash disk', 'usb', 'flash drive', 'memory', 'kumbukumbu']),

  // ══════════════════════════════════════════════════════════════════════════
  // RETAIL / GENERAL SHOP
  // ══════════════════════════════════════════════════════════════════════════

  _prod('rt_rice_2kg', _kRetail, 'retail_groceries', 'Rice 2kg Packet',
      unit: 'packets', cost: 4500, sell: 5500,
      kw: ['mchele', 'rice', '2kg', 'wali']),
  _prod('rt_sugar_2kg', _kRetail, 'retail_groceries', 'Sugar 2kg Packet',
      unit: 'packets', cost: 5000, sell: 6000,
      kw: ['sukari', 'sugar', '2kg']),
  _prod('rt_cooking_oil_2l', _kRetail, 'retail_groceries', 'Cooking Oil 2 Litres',
      unit: 'bottles', cost: 8500, sell: 10500,
      kw: ['mafuta', 'cooking oil', '2 litre', 'vegetable oil']),
  _prod('rt_maize_flour_2kg', _kRetail, 'retail_groceries', 'Unga wa Mahindi 2kg',
      unit: 'packets', cost: 4000, sell: 5000,
      kw: ['unga', 'maize flour', 'ugali', 'mahindi']),
  _prod('rt_milk_500', _kRetail, 'retail_groceries', 'Milk 500ml (Fresh)',
      unit: 'packets', cost: 1500, sell: 2000,
      kw: ['maziwa', 'milk', 'fresh milk', 'fresh']),
  _prod('rt_bread', _kRetail, 'retail_groceries', 'Bread Loaf (Mkate)',
      unit: 'loaves', cost: 1800, sell: 2500,
      kw: ['mkate', 'bread', 'loaf', 'chakula']),
  _prod('rt_eggs_tray', _kRetail, 'retail_groceries', 'Eggs (Mayai) - Tray of 30',
      unit: 'trays', cost: 15000, sell: 18000,
      kw: ['mayai', 'eggs', 'tray', 'chakula']),
  _prod('rt_soda_coke', _kRetail, 'retail_beverages', 'Coca Cola 330ml',
      unit: 'bottles', cost: 800, sell: 1200,
      kw: ['coke', 'coca cola', 'soda', 'kinywaji']),
  _prod('rt_water_500', _kRetail, 'retail_beverages', 'Mineral Water 500ml',
      unit: 'bottles', cost: 300, sell: 500,
      kw: ['maji', 'water', 'mineral water', 'kinywaji']),
  _prod('rt_soap_bar', _kRetail, 'retail_personal_care', 'Bar Soap (Sabuni) 175g',
      unit: 'bars', cost: 800, sell: 1200,
      kw: ['sabuni', 'soap', 'bar soap', 'usafi']),
  _prod('rt_toothpaste', _kRetail, 'retail_personal_care', 'Toothpaste (Dawa ya Meno) 75ml',
      unit: 'tubes', cost: 1500, sell: 2200,
      kw: ['toothpaste', 'dawa ya meno', 'oral care', 'mswaki']),
  _prod('rt_shampoo', _kRetail, 'retail_personal_care', 'Shampoo 400ml',
      unit: 'bottles', cost: 3000, sell: 4500,
      kw: ['shampoo', 'nywele', 'hair wash', 'sabuni ya nywele']),
  _prod('rt_detergent', _kRetail, 'retail_cleaning', 'Detergent Powder 500g',
      unit: 'packets', cost: 1500, sell: 2200,
      kw: ['detergent', 'sabuni ya nguo', 'washing powder', 'omo']),
  _prod('rt_bleach', _kRetail, 'retail_cleaning', 'Bleach 1 Litre',
      unit: 'bottles', cost: 2000, sell: 3000,
      kw: ['bleach', 'jik', 'disinfectant', 'safisha']),
  _prod('rt_exercise_book', _kRetail, 'retail_stationery', 'Exercise Book A5',
      unit: 'pcs', cost: 300, sell: 500,
      kw: ['exercise book', 'daftari', 'notebook', 'shule']),
  _prod('rt_pen', _kRetail, 'retail_stationery', 'Ball Point Pen',
      unit: 'pcs', cost: 100, sell: 200,
      kw: ['pen', 'kalamu', 'biro', 'stationery']),

  // ══════════════════════════════════════════════════════════════════════════
  // WHOLESALE
  // ══════════════════════════════════════════════════════════════════════════

  _prod('ws_rice_25kg', _kWholesale, 'wholesale_groceries', 'Rice 25kg Bag',
      unit: 'bags', cost: 55000, sell: 65000,
      kw: ['mchele', 'rice', '25kg', 'gunia', 'jumla']),
  _prod('ws_sugar_50kg', _kWholesale, 'wholesale_groceries', 'Sugar 50kg Bag',
      unit: 'bags', cost: 125000, sell: 140000,
      kw: ['sukari', 'sugar', '50kg', 'gunia', 'jumla']),
  _prod('ws_flour_50kg', _kWholesale, 'wholesale_groceries', 'Wheat Flour 50kg Bag',
      unit: 'bags', cost: 90000, sell: 105000,
      kw: ['unga', 'flour', '50kg', 'gunia', 'jumla']),
  _prod('ws_cooking_oil_20l', _kWholesale, 'wholesale_groceries', 'Cooking Oil 20 Litres (Jerry Can)',
      unit: 'jerry cans', cost: 90000, sell: 105000,
      kw: ['mafuta', 'cooking oil', '20 litre', 'jerry can', 'jumla']),
  _prod('ws_soap_carton', _kWholesale, 'wholesale_household', 'Bar Soap Carton (72 bars)',
      unit: 'cartons', cost: 55000, sell: 65000,
      kw: ['sabuni', 'soap', 'carton', 'jumla']),
  _prod('ws_detergent_carton', _kWholesale, 'wholesale_cleaning', 'Detergent Powder Carton (500g x 20)',
      unit: 'cartons', cost: 28000, sell: 35000,
      kw: ['detergent', 'sabuni ya nguo', 'carton', 'omo', 'jumla']),

  // ══════════════════════════════════════════════════════════════════════════
  // SALON & BARBER
  // ══════════════════════════════════════════════════════════════════════════

  _prod('sl_dark_lovely', _kSalon, 'salon_hair_products', 'Dark & Lovely Relaxer Kit',
      unit: 'kits', cost: 5000, sell: 8000,
      kw: ['dark lovely', 'relaxer', 'hair relaxer', 'nywele']),
  _prod('sl_afro_sheen', _kSalon, 'salon_hair_products', 'Afro Sheen Hair Grease',
      unit: 'jars', cost: 3000, sell: 5000,
      kw: ['afro sheen', 'hair grease', 'mafuta ya nywele', 'nywele']),
  _prod('sl_hair_oil', _kSalon, 'salon_hair_products', 'Hair Oil 200ml',
      unit: 'bottles', cost: 4000, sell: 6500,
      kw: ['hair oil', 'mafuta ya nywele', 'argan oil', 'nywele']),
  _prod('sl_shampoo_salon', _kSalon, 'salon_hair_products', 'Professional Shampoo 1L',
      unit: 'bottles', cost: 8000, sell: 13000,
      kw: ['shampoo', 'professional', 'hair wash', 'salon']),
  _prod('sl_conditioner', _kSalon, 'salon_hair_products', 'Hair Conditioner 1L',
      unit: 'bottles', cost: 8000, sell: 13000,
      kw: ['conditioner', 'hair conditioner', 'nywele']),
  _prod('sl_hair_color', _kSalon, 'salon_hair_products', 'Hair Color / Dye',
      unit: 'kits', cost: 5000, sell: 9000,
      kw: ['hair color', 'hair dye', 'hair colour', 'nywele']),
  _prod('sl_wig_synthetic', _kSalon, 'salon_wigs', 'Synthetic Wig (Short)',
      unit: 'pcs', cost: 20000, sell: 35000,
      kw: ['wig', 'synthetic wig', 'nywele bandia', 'nywele']),
  _prod('sl_nail_polish', _kSalon, 'salon_nail', 'Nail Polish (various colors)',
      unit: 'bottles', cost: 1500, sell: 3000,
      kw: ['nail polish', 'nail color', 'kucha', 'nail']),
  _prod('sl_nail_remover', _kSalon, 'salon_nail', 'Nail Polish Remover 100ml',
      unit: 'bottles', cost: 1500, sell: 2500,
      kw: ['nail remover', 'acetone', 'kucha', 'nail polish remover']),
  _prod('sl_face_cream', _kSalon, 'salon_skin_care', 'Face Cream (Nivea / Ponds)',
      unit: 'jars', cost: 4000, sell: 7000,
      kw: ['face cream', 'nivea', 'ponds', 'cream', 'moisturizer']),
  _prod('sl_razor_blades', _kSalon, 'salon_equipment', 'Razor Blades (Pack of 5)',
      unit: 'packs', cost: 1000, sell: 1800,
      kw: ['razor', 'blade', 'razor blade', 'kinyozi', 'shaving']),

  // ══════════════════════════════════════════════════════════════════════════
  // HARDWARE & BUILDING MATERIALS
  // ══════════════════════════════════════════════════════════════════════════

  _prod('hw_cement_bag', _kHardware, 'hw_building', 'Cement Bag 50kg',
      unit: 'bags', cost: 18000, sell: 22000,
      kw: ['cement', 'simiti', '50kg', 'building', 'ujenzi']),
  _prod('hw_sand_tipper', _kHardware, 'hw_building', 'River Sand (per Tipper)',
      unit: 'tippers', cost: 80000, sell: 100000,
      kw: ['sand', 'mchanga', 'tipper', 'building', 'ujenzi']),
  _prod('hw_iron_sheet', _kHardware, 'hw_building', 'Corrugated Iron Sheet 3m',
      unit: 'pcs', cost: 22000, sell: 28000,
      kw: ['iron sheet', 'bati', 'roofing', 'paa', 'mabati']),
  _prod('hw_paint_5l', _kHardware, 'hw_paint', 'Emulsion Paint 5 Litres',
      unit: 'tins', cost: 25000, sell: 35000,
      kw: ['paint', 'rangi', 'emulsion', 'wall paint']),
  _prod('hw_paint_20l', _kHardware, 'hw_paint', 'Emulsion Paint 20 Litres',
      unit: 'tins', cost: 90000, sell: 120000,
      kw: ['paint', 'rangi', 'emulsion', 'wall paint', '20 litre']),
  _prod('hw_pvc_pipe', _kHardware, 'hw_plumbing', 'PVC Pipe 1/2 inch 6m',
      unit: 'pcs', cost: 8000, sell: 12000,
      kw: ['pvc pipe', 'mabomba', 'plumbing', 'bomba']),
  _prod('hw_electric_cable', _kHardware, 'hw_electrical', 'Electrical Cable 2.5mm (per 100m)',
      unit: 'rolls', cost: 80000, sell: 100000,
      kw: ['cable', 'electric cable', 'waya', 'electrical']),
  _prod('hw_wire_nails', _kHardware, 'hw_building', 'Wire Nails 2" (1kg)',
      unit: 'kg', cost: 2500, sell: 3500,
      kw: ['nails', 'msumari', 'wire nails', 'building']),
  _prod('hw_safety_helmet', _kHardware, 'hw_safety', 'Safety Helmet',
      unit: 'pcs', cost: 8000, sell: 15000,
      kw: ['helmet', 'safety helmet', 'hard hat', 'PPE', 'ujenzi']),

  // ══════════════════════════════════════════════════════════════════════════
  // AGRICULTURE
  // ══════════════════════════════════════════════════════════════════════════

  _prod('ag_maize_seed', _kAgriculture, 'agri_seeds', 'Maize Seeds 2kg (Hybrid)',
      unit: 'packets', cost: 15000, sell: 20000,
      kw: ['mahindi', 'maize seed', 'hybrid seed', 'mbegu']),
  _prod('ag_sunflower_seed', _kAgriculture, 'agri_seeds', 'Sunflower Seeds 2kg',
      unit: 'packets', cost: 12000, sell: 18000,
      kw: ['sunflower', 'alizeti', 'seed', 'mbegu']),
  _prod('ag_bean_seed', _kAgriculture, 'agri_seeds', 'Bean Seeds 1kg',
      unit: 'kg', cost: 4000, sell: 6000,
      kw: ['maharagwe', 'beans', 'seed', 'mbegu']),
  _prod('ag_urea', _kAgriculture, 'agri_fertilizers', 'Urea Fertilizer 50kg',
      unit: 'bags', cost: 55000, sell: 68000,
      kw: ['urea', 'mbolea', 'fertilizer', 'nitrogen']),
  _prod('ag_dap', _kAgriculture, 'agri_fertilizers', 'DAP Fertilizer 50kg',
      unit: 'bags', cost: 85000, sell: 100000,
      kw: ['dap', 'mbolea', 'fertilizer', 'phosphate']),
  _prod('ag_npk', _kAgriculture, 'agri_fertilizers', 'NPK Fertilizer 50kg',
      unit: 'bags', cost: 75000, sell: 90000,
      kw: ['npk', 'mbolea', 'fertilizer', 'compound']),
  _prod('ag_herbicide', _kAgriculture, 'agri_pesticides', 'Round Up Herbicide 1L',
      unit: 'bottles', cost: 15000, sell: 20000,
      kw: ['roundup', 'herbicide', 'magugu', 'weed killer']),
  _prod('ag_insecticide', _kAgriculture, 'agri_pesticides', 'Lambda Insecticide 500ml',
      unit: 'bottles', cost: 12000, sell: 18000,
      kw: ['insecticide', 'wadudu', 'pest control', 'dawa ya wadudu']),
  _prod('ag_chicken_feed', _kAgriculture, 'agri_feeds', 'Layers Mash 50kg (Chicken Feed)',
      unit: 'bags', cost: 35000, sell: 42000,
      kw: ['chicken feed', 'malisho', 'kuku', 'layers mash']),
  _prod('ag_pig_feed', _kAgriculture, 'agri_feeds', 'Pig Feed 50kg',
      unit: 'bags', cost: 40000, sell: 50000,
      kw: ['pig feed', 'nguruwe', 'malisho', 'feed']),

  // ══════════════════════════════════════════════════════════════════════════
  // TAILORING / BOUTIQUE
  // ══════════════════════════════════════════════════════════════════════════

  _prod('ta_kitenge', _kTailoring, 'tailor_fabrics', 'Kitenge Fabric (2 yards)',
      unit: 'yards', cost: 8000, sell: 12000,
      kw: ['kitenge', 'fabric', 'nguo', 'material', 'african print']),
  _prod('ta_cotton_fabric', _kTailoring, 'tailor_fabrics', 'Cotton Fabric (per yard)',
      unit: 'yards', cost: 5000, sell: 8000,
      kw: ['cotton', 'fabric', 'material', 'nguo']),
  _prod('ta_zip', _kTailoring, 'tailor_accessories', 'Zip / Zipper 20cm',
      unit: 'pcs', cost: 300, sell: 600,
      kw: ['zip', 'zipper', 'nguo', 'sewing']),
  _prod('ta_buttons', _kTailoring, 'tailor_accessories', 'Buttons (Pack of 12)',
      unit: 'packs', cost: 400, sell: 800,
      kw: ['buttons', 'vifungo', 'nguo', 'sewing']),
  _prod('ta_mens_shirt', _kTailoring, 'tailor_mens', "Men's Formal Shirt",
      unit: 'pcs', cost: 15000, sell: 25000,
      kw: ['mens shirt', 'shati', 'formal', 'nguo za wanaume']),
  _prod('ta_ladies_dress', _kTailoring, 'tailor_womens', 'Ladies Dress',
      unit: 'pcs', cost: 20000, sell: 35000,
      kw: ['dress', 'gauni', 'ladies dress', 'nguo za wanawake']),
  _prod('ta_kids_uniform', _kTailoring, 'tailor_kids', 'School Uniform Set (Child)',
      unit: 'sets', cost: 15000, sell: 25000,
      kw: ['school uniform', 'uniform', 'sare', 'watoto', 'shule']),
  _prod('ta_leather_shoes', _kTailoring, 'tailor_shoes', 'Leather Shoes (Men)',
      unit: 'pairs', cost: 30000, sell: 50000,
      kw: ['shoes', 'leather shoes', 'viatu', 'formal shoes']),
  _prod('ta_sneakers', _kTailoring, 'tailor_shoes', 'Sneakers / Canvas Shoes',
      unit: 'pairs', cost: 20000, sell: 35000,
      kw: ['sneakers', 'canvas', 'viatu vya michezo', 'shoes']),
  _prod('ta_handbag', _kTailoring, 'tailor_accessories', 'Ladies Handbag',
      unit: 'pcs', cost: 15000, sell: 28000,
      kw: ['handbag', 'bag', 'mkoba', 'ladies bag']),

  // ══════════════════════════════════════════════════════════════════════════
  // TRANSPORT / AUTOMOTIVE
  // ══════════════════════════════════════════════════════════════════════════

  _prod('au_engine_oil_1l', _kTransport, 'auto_fuel', 'Engine Oil 1L (Castrol / Shell)',
      unit: 'bottles', cost: 8000, sell: 12000,
      kw: ['engine oil', 'oil', 'mafuta ya gari', 'castrol', 'shell']),
  _prod('au_engine_oil_4l', _kTransport, 'auto_fuel', 'Engine Oil 4L',
      unit: 'bottles', cost: 30000, sell: 42000,
      kw: ['engine oil', 'oil', 'mafuta ya gari', '4 litre']),
  _prod('au_tyre_tube', _kTransport, 'auto_tyres', 'Tyre Inner Tube 195/65R15',
      unit: 'pcs', cost: 25000, sell: 40000,
      kw: ['tyre tube', 'tube', 'mpira', 'tyre inner tube']),
  _prod('au_tyre_full', _kTransport, 'auto_tyres', 'Car Tyre 195/65R15',
      unit: 'pcs', cost: 120000, sell: 160000,
      kw: ['tyre', 'tire', 'mpira', 'car tyre']),
  _prod('au_battery_car', _kTransport, 'auto_spare', 'Car Battery 12V 55Ah',
      unit: 'pcs', cost: 130000, sell: 175000,
      kw: ['car battery', 'battery', 'betri', 'gari']),
  _prod('au_brake_pads', _kTransport, 'auto_spare', 'Brake Pads (Front Set)',
      unit: 'sets', cost: 30000, sell: 50000,
      kw: ['brake pads', 'brakes', 'brake', 'gari']),
  _prod('au_air_filter', _kTransport, 'auto_spare', 'Air Filter',
      unit: 'pcs', cost: 15000, sell: 25000,
      kw: ['air filter', 'filter', 'gari', 'engine']),
  _prod('au_oil_filter', _kTransport, 'auto_spare', 'Oil Filter',
      unit: 'pcs', cost: 8000, sell: 15000,
      kw: ['oil filter', 'filter', 'gari', 'engine']),
  _prod('au_car_wax', _kTransport, 'auto_maintenance', 'Car Wax / Polish 500ml',
      unit: 'bottles', cost: 8000, sell: 15000,
      kw: ['car wax', 'wax', 'polish', 'gari', 'cleaning']),
];

MasterProduct _prod(
  String id,
  String bizType,
  String categoryId,
  String name, {
  required String unit,
  required double cost,
  required double sell,
  required List<String> kw,
}) {
  // Derive category name from the category id for quick display
  final cat = masterCatalogCategories
      .where((c) => c.id == categoryId)
      .map((c) => c.categoryName)
      .firstOrNull ?? '';
  return MasterProduct(
    id: id,
    businessTypeId: bizType,
    categoryId: categoryId,
    categoryName: cat,
    productName: name,
    defaultUnit: unit,
    suggestedCostPrice: cost,
    suggestedSellingPrice: sell,
    searchableKeywords: kw,
  );
}
