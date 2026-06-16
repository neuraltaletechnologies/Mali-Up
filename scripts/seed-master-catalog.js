'use strict';

/**
 * Mali Up — Master Catalog Seed Script
 *
 * Populates Firestore global collections:
 *   master_categories  — one doc per category
 *   master_products    — one doc per product
 *
 * Usage:
 *   1. Place your Firebase service account key at scripts/serviceAccountKey.json
 *   2. cd scripts && npm install
 *   3. npm run seed
 *
 * Idempotent: uses set({ merge: true }) — safe to re-run.
 * Batch size: 400 ops/batch (Firestore limit is 500).
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const BATCH_SIZE = 400;

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

function cat(id, businessTypeId, categoryName, description, icon) {
  return {
    id,
    businessTypeId,
    categoryName,
    description,
    icon,
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function prod(
  id,
  businessTypeId,
  categoryId,
  categoryName,
  productName,
  skuTemplate,
  defaultUnit,
  suggestedCostPrice,
  suggestedSellingPrice,
  searchableKeywords,
  barcode = '',
) {
  return {
    id,
    businessTypeId,
    categoryId,
    categoryName,
    productName,
    skuTemplate,
    barcode,
    defaultUnit,
    suggestedCostPrice,
    suggestedSellingPrice,
    searchableKeywords,
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function batchWrite(collectionName, docs) {
  let batch = db.batch();
  let count = 0;
  let total = 0;

  for (const doc of docs) {
    const ref = db.collection(collectionName).doc(doc.id);
    batch.set(ref, doc, { merge: true });
    count++;
    total++;

    if (count >= BATCH_SIZE) {
      await batch.commit();
      console.log(`  ✓ Committed ${total}/${docs.length} to ${collectionName}`);
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
    console.log(`  ✓ Committed ${total}/${docs.length} to ${collectionName}`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. PHARMACY (duka la dawa)
// ─────────────────────────────────────────────────────────────────────────────

const pharmacyCategories = [
  cat('pharm-painkillers', 'pharmacy', 'Dawa za Maumivu', 'Painkillers and anti-inflammatory drugs', '💊'),
  cat('pharm-antibiotics', 'pharmacy', 'Antibiotics', 'Bacterial infection treatments', '🔬'),
  cat('pharm-vitamins', 'pharmacy', 'Vitamini & Virutubisho', 'Vitamins and nutritional supplements', '🌿'),
  cat('pharm-firstaid', 'pharmacy', 'Huduma ya Kwanza', 'First aid supplies and wound care', '🩹'),
  cat('pharm-family', 'pharmacy', 'Afya ya Familia', 'Family planning and maternal health', '👶'),
  cat('pharm-equipment', 'pharmacy', 'Vifaa vya Kipimo', 'Medical devices and testing equipment', '🩺'),
  cat('pharm-skin', 'pharmacy', 'Urembo & Ngozi', 'Skincare and personal care products', '✨'),
  cat('pharm-malaria', 'pharmacy', 'Dawa za Malaria', 'Antimalarial and tropical disease treatments', '🦟'),
];

const pharmacyProducts = [
  prod('pharm-p001', 'pharmacy', 'pharm-painkillers', 'Dawa za Maumivu', 'Paracetamol 500mg (100 tabs)', 'PHARM-PARA-500', 'pack', 2500, 3500, ['paracetamol', 'panadol', 'maumivu ya kichwa', 'homa', 'fever']),
  prod('pharm-p002', 'pharmacy', 'pharm-painkillers', 'Dawa za Maumivu', 'Ibuprofen 400mg (10 tabs)', 'PHARM-IBU-400', 'pack', 1500, 2500, ['ibuprofen', 'maumivu', 'uvimbe', 'inflammation']),
  prod('pharm-p003', 'pharmacy', 'pharm-painkillers', 'Dawa za Maumivu', 'Aspirin 300mg (10 tabs)', 'PHARM-ASP-300', 'pack', 800, 1500, ['aspirin', 'maumivu', 'damu', 'blood thinner']),
  prod('pharm-p004', 'pharmacy', 'pharm-antibiotics', 'Antibiotics', 'Amoxicillin 250mg (21 caps)', 'PHARM-AMOX-250', 'pack', 3500, 5500, ['amoxicillin', 'antibiotic', 'maambukizi', 'infection']),
  prod('pharm-p005', 'pharmacy', 'pharm-antibiotics', 'Antibiotics', 'Metronidazole 400mg (21 tabs)', 'PHARM-METRO-400', 'pack', 2500, 4000, ['metronidazole', 'flagyl', 'tumbo', 'amoeba', 'parasites']),
  prod('pharm-p006', 'pharmacy', 'pharm-antibiotics', 'Antibiotics', 'Co-trimoxazole 480mg (20 tabs)', 'PHARM-COTRI-480', 'pack', 2000, 3500, ['cotrimoxazole', 'bactrim', 'mkojo', 'UTI', 'antibiotic']),
  prod('pharm-p007', 'pharmacy', 'pharm-antibiotics', 'Antibiotics', 'Erythromycin 250mg (28 tabs)', 'PHARM-ERY-250', 'pack', 4000, 6500, ['erythromycin', 'antibiotic', 'maambukizi', 'strep']),
  prod('pharm-p008', 'pharmacy', 'pharm-vitamins', 'Vitamini & Virutubisho', 'Vitamin C 500mg (30 tabs)', 'PHARM-VITC-500', 'pack', 3000, 5000, ['vitamin c', 'vitamini', 'kinga', 'immunity', 'ascorbic acid']),
  prod('pharm-p009', 'pharmacy', 'pharm-vitamins', 'Vitamini & Virutubisho', 'Folic Acid 5mg (30 tabs)', 'PHARM-FOLIC-5', 'pack', 2000, 3500, ['folic acid', 'folate', 'mimba', 'ujauzito', 'pregnancy']),
  prod('pharm-p010', 'pharmacy', 'pharm-vitamins', 'Vitamini & Virutubisho', 'Zinc Sulphate 20mg (30 tabs)', 'PHARM-ZINC-20', 'pack', 3000, 5000, ['zinc', 'zinki', 'kinga', 'ukuaji', 'growth']),
  prod('pharm-p011', 'pharmacy', 'pharm-vitamins', 'Vitamini & Virutubisho', 'Iron Supplements (30 tabs)', 'PHARM-IRON-200', 'pack', 2500, 4500, ['iron', 'chuma', 'damu', 'upungufu', 'anaemia']),
  prod('pharm-p012', 'pharmacy', 'pharm-vitamins', 'Vitamini & Virutubisho', 'Multivitamin Adults (30 tabs)', 'PHARM-MULTI-30', 'pack', 5000, 8000, ['multivitamin', 'vitamini', 'nguvu', 'energy', 'afya']),
  prod('pharm-p013', 'pharmacy', 'pharm-firstaid', 'Huduma ya Kwanza', 'ORS Sachets (10 pcs)', 'PHARM-ORS-10', 'pack', 2000, 3500, ['ORS', 'kuhara', 'maji', 'dehydration', 'diarrhoea']),
  prod('pharm-p014', 'pharmacy', 'pharm-firstaid', 'Huduma ya Kwanza', 'Gauze Bandage Roll (5cm x 5m)', 'PHARM-GAUZE-5', 'roll', 1500, 2500, ['bandage', 'bendeji', 'jeraha', 'wound', 'first aid']),
  prod('pharm-p015', 'pharmacy', 'pharm-firstaid', 'Huduma ya Kwanza', 'Cotton Wool 100g', 'PHARM-COTTON-100', 'pack', 2000, 3500, ['cotton wool', 'pamba', 'jeraha', 'wound', 'usafi']),
  prod('pharm-p016', 'pharmacy', 'pharm-firstaid', 'Huduma ya Kwanza', 'Dettol Antiseptic 500ml', 'PHARM-DETTOL-500', 'bottle', 6000, 9000, ['dettol', 'antiseptic', 'jeraha', 'wound', 'usafi']),
  prod('pharm-p017', 'pharmacy', 'pharm-firstaid', 'Huduma ya Kwanza', 'Surgical Gloves (Pair)', 'PHARM-GLOVE-PR', 'pair', 1000, 2000, ['gloves', 'glavu', 'usalama', 'latex', 'surgical']),
  prod('pharm-p018', 'pharmacy', 'pharm-family', 'Afya ya Familia', 'Condoms (12 pack)', 'PHARM-COND-12', 'pack', 2000, 4000, ['condoms', 'mpira', 'uzazi wa mpango', 'family planning', 'prevention']),
  prod('pharm-p019', 'pharmacy', 'pharm-family', 'Afya ya Familia', 'Pregnancy Test Kit', 'PHARM-PREG-TEST', 'pcs', 2500, 5000, ['pregnancy test', 'kipimo cha mimba', 'ujauzito', 'test kit']),
  prod('pharm-p020', 'pharmacy', 'pharm-equipment', 'Vifaa vya Kipimo', 'Digital Thermometer', 'PHARM-THERM-DIG', 'pcs', 5000, 9000, ['thermometer', 'kupima joto', 'homa', 'temperature', 'fever']),
  prod('pharm-p021', 'pharmacy', 'pharm-equipment', 'Vifaa vya Kipimo', 'Blood Pressure Monitor', 'PHARM-BP-MON', 'pcs', 35000, 55000, ['blood pressure', 'shinikizo la damu', 'BP machine', 'monitor']),
  prod('pharm-p022', 'pharmacy', 'pharm-equipment', 'Vifaa vya Kipimo', 'Glucometer Test Strips (50 pcs)', 'PHARM-GLUCO-50', 'pack', 15000, 22000, ['glucometer', 'sukari', 'diabetes', 'glucose', 'blood sugar']),
  prod('pharm-p023', 'pharmacy', 'pharm-skin', 'Urembo & Ngozi', 'Vaseline Petroleum Jelly 100g', 'PHARM-VAS-100', 'jar', 2500, 4000, ['vaseline', 'mafuta', 'ngozi', 'skin', 'moisturizer']),
  prod('pharm-p024', 'pharmacy', 'pharm-malaria', 'Dawa za Malaria', 'Artemether-Lumefantrine (AL) 6 tabs', 'PHARM-AL-6', 'pack', 4500, 7000, ['malaria', 'AL', 'artemether', 'lumefantrine', 'dawa ya malaria']),
  prod('pharm-p025', 'pharmacy', 'pharm-malaria', 'Dawa za Malaria', 'Albendazole 400mg (2 tabs)', 'PHARM-ALB-400', 'pack', 1500, 3000, ['albendazole', 'minyoo', 'worms', 'deworming', 'parasites']),
  prod('pharm-p026', 'pharmacy', 'pharm-malaria', 'Dawa za Malaria', 'Omeprazole 20mg (14 caps)', 'PHARM-OMEP-20', 'pack', 3000, 5000, ['omeprazole', 'tumbo', 'stomach', 'acidity', 'gastric']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 2. RESTAURANT (mkahawa / mgahawa)
// ─────────────────────────────────────────────────────────────────────────────

const restaurantCategories = [
  cat('rest-breakfast', 'restaurant', 'Chakula cha Asubuhi', 'Breakfast foods and beverages', '🌅'),
  cat('rest-lunch', 'restaurant', 'Chakula cha Mchana', 'Lunch main dishes', '🍽️'),
  cat('rest-dinner', 'restaurant', 'Chakula cha Jioni', 'Dinner and evening meals', '🌙'),
  cat('rest-drinks', 'restaurant', 'Vinywaji', 'Beverages hot and cold', '🥤'),
  cat('rest-snacks', 'restaurant', 'Vitafunio', 'Snacks and light bites', '🥨'),
  cat('rest-grills', 'restaurant', 'Nyama & Samaki', 'Grilled meats and fish', '🔥'),
];

const restaurantProducts = [
  prod('rest-p001', 'restaurant', 'rest-breakfast', 'Chakula cha Asubuhi', 'Mandazi (3 pcs)', 'REST-MAND-3', 'order', 500, 1000, ['mandazi', 'mkate wa kukaanga', 'breakfast', 'chai']),
  prod('rest-p002', 'restaurant', 'rest-breakfast', 'Chakula cha Asubuhi', 'Mkate wa Kusukari', 'REST-MKATE-SU', 'order', 300, 700, ['mkate', 'bread', 'breakfast', 'toast']),
  prod('rest-p003', 'restaurant', 'rest-breakfast', 'Chakula cha Asubuhi', 'Uji wa Mahindi', 'REST-UJI-MAH', 'bowl', 800, 1500, ['uji', 'porridge', 'mahindi', 'breakfast']),
  prod('rest-p004', 'restaurant', 'rest-breakfast', 'Chakula cha Asubuhi', 'Maandazi na Kande', 'REST-MAND-KAN', 'order', 1500, 3000, ['maandazi', 'kande', 'breakfast', 'chai']),
  prod('rest-p005', 'restaurant', 'rest-lunch', 'Chakula cha Mchana', 'Ugali na Maharage', 'REST-UG-MAH', 'plate', 2500, 5000, ['ugali', 'maharage', 'beans', 'lunch', 'chakula']),
  prod('rest-p006', 'restaurant', 'rest-lunch', 'Chakula cha Mchana', 'Ugali na Nyama ya Ng\'ombe', 'REST-UG-NGOM', 'plate', 5000, 10000, ['ugali', 'nyama', 'beef', 'lunch', 'chakula']),
  prod('rest-p007', 'restaurant', 'rest-lunch', 'Chakula cha Mchana', 'Mchele Wali na Samaki', 'REST-WALI-SAM', 'plate', 5000, 9000, ['wali', 'samaki', 'fish', 'rice', 'lunch']),
  prod('rest-p008', 'restaurant', 'rest-lunch', 'Chakula cha Mchana', 'Pilau ya Nyama', 'REST-PILAU-NY', 'plate', 6000, 12000, ['pilau', 'nyama', 'beef pilau', 'rice', 'spices']),
  prod('rest-p009', 'restaurant', 'rest-lunch', 'Chakula cha Mchana', 'Biryani ya Kuku', 'REST-BIR-KUKU', 'plate', 7000, 14000, ['biryani', 'kuku', 'chicken biryani', 'rice']),
  prod('rest-p010', 'restaurant', 'rest-lunch', 'Chakula cha Mchana', 'Chipsi za Kawaida', 'REST-CHIPSI', 'plate', 2000, 4000, ['chipsi', 'chips', 'french fries', 'viazi']),
  prod('rest-p011', 'restaurant', 'rest-lunch', 'Chakula cha Mchana', 'Chipsi Mayai', 'REST-CHIPSI-MAY', 'plate', 3000, 6000, ['chipsi mayai', 'chips eggs', 'omelette chips', 'street food']),
  prod('rest-p012', 'restaurant', 'rest-dinner', 'Chakula cha Jioni', 'Ugali na Mchuzi wa Kuku', 'REST-UG-KUKU', 'plate', 5000, 9000, ['ugali', 'kuku', 'chicken', 'mchuzi', 'dinner']),
  prod('rest-p013', 'restaurant', 'rest-dinner', 'Chakula cha Jioni', 'Supu ya Nyama', 'REST-SUPU-NY', 'bowl', 4000, 7000, ['supu', 'soup', 'nyama', 'beef soup', 'broth']),
  prod('rest-p014', 'restaurant', 'rest-dinner', 'Chakula cha Jioni', 'Mchuzi wa Nazi na Samaki', 'REST-NAZI-SAM', 'plate', 6000, 12000, ['nazi', 'coconut', 'samaki', 'fish', 'coastal']),
  prod('rest-p015', 'restaurant', 'rest-drinks', 'Vinywaji', 'Chai ya Kawaida', 'REST-CHAI', 'cup', 300, 700, ['chai', 'tea', 'kinywaji', 'hot drink']),
  prod('rest-p016', 'restaurant', 'rest-drinks', 'Vinywaji', 'Kahawa Chungu', 'REST-KAHAWA', 'cup', 500, 1000, ['kahawa', 'coffee', 'kinywaji', 'caffeine']),
  prod('rest-p017', 'restaurant', 'rest-drinks', 'Vinywaji', 'Soda 300ml', 'REST-SODA-300', 'bottle', 800, 1500, ['soda', 'cola', 'soft drink', 'kinywaji baridi']),
  prod('rest-p018', 'restaurant', 'rest-drinks', 'Vinywaji', 'Maji ya Kunywa 500ml', 'REST-MAJI-500', 'bottle', 500, 1000, ['maji', 'water', 'mineral water', 'kinywaji']),
  prod('rest-p019', 'restaurant', 'rest-drinks', 'Vinywaji', 'Juice ya Matunda 250ml', 'REST-JUICE-250', 'glass', 1000, 2000, ['juice', 'maji ya matunda', 'fruit juice', 'kinywaji']),
  prod('rest-p020', 'restaurant', 'rest-snacks', 'Vitafunio', 'Samosa (2 pcs)', 'REST-SAM-2', 'order', 500, 1500, ['samosa', 'vitafunio', 'snack', 'fried']),
  prod('rest-p021', 'restaurant', 'rest-snacks', 'Vitafunio', 'Mkate wa Mayai', 'REST-MK-MAY', 'order', 1500, 3000, ['mkate wa mayai', 'egg bread', 'snack', 'street food']),
  prod('rest-p022', 'restaurant', 'rest-grills', 'Nyama & Samaki', 'Nyama Choma (250g)', 'REST-CHOMA-250', 'portion', 8000, 15000, ['nyama choma', 'grilled meat', 'bbq', 'beef']),
  prod('rest-p023', 'restaurant', 'rest-grills', 'Nyama & Samaki', 'Kuku wa Kukaanga (Kizimba)', 'REST-KUKU-KAK', 'portion', 10000, 18000, ['kuku', 'fried chicken', 'kizimba', 'grilled chicken']),
  prod('rest-p024', 'restaurant', 'rest-grills', 'Nyama & Samaki', 'Samaki wa Kukaanga (Nzima)', 'REST-SAM-KAK', 'pcs', 8000, 15000, ['samaki', 'fried fish', 'tilapia', 'perch']),
  prod('rest-p025', 'restaurant', 'rest-grills', 'Nyama & Samaki', 'Mishkaki (5 pcs)', 'REST-MISH-5', 'order', 3000, 6000, ['mishkaki', 'skewers', 'nyama', 'grilled', 'street food']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 3. ELECTRONICS (vifaa vya umeme)
// ─────────────────────────────────────────────────────────────────────────────

const electronicsCategories = [
  cat('elec-phones', 'electronics', 'Simu & Accessories', 'Mobile phones and accessories', '📱'),
  cat('elec-audio', 'electronics', 'Audio & Visual', 'TVs, speakers and audio equipment', '📺'),
  cat('elec-computers', 'electronics', 'Kompyuta & Tablets', 'Computers, laptops and tablets', '💻'),
  cat('elec-power', 'electronics', 'Nguvu & Betri', 'Power banks, chargers and batteries', '🔋'),
  cat('elec-lighting', 'electronics', 'Taa & Umeme', 'LED lights and electrical fittings', '💡'),
  cat('elec-cables', 'electronics', 'Cables & Adapters', 'Cables, connectors and adapters', '🔌'),
];

const electronicsProducts = [
  prod('elec-p001', 'electronics', 'elec-phones', 'Simu & Accessories', 'Phone Case (Universal)', 'ELEC-CASE-UNI', 'pcs', 3000, 8000, ['phone case', 'kifuniko cha simu', 'cover', 'protection']),
  prod('elec-p002', 'electronics', 'elec-phones', 'Simu & Accessories', 'Screen Protector (Tempered Glass)', 'ELEC-SCRN-PROT', 'pcs', 3000, 8000, ['screen protector', 'kinga ya skrini', 'tempered glass', 'phone']),
  prod('elec-p003', 'electronics', 'elec-phones', 'Simu & Accessories', 'Earphones (Wired)', 'ELEC-EAR-WIR', 'pcs', 5000, 12000, ['earphones', 'headphones', 'earbuds', 'masikio', 'wired']),
  prod('elec-p004', 'electronics', 'elec-phones', 'Simu & Accessories', 'Bluetooth Earbuds', 'ELEC-EAR-BT', 'pcs', 15000, 35000, ['bluetooth earbuds', 'wireless earphones', 'TWS', 'masikio']),
  prod('elec-p005', 'electronics', 'elec-phones', 'Simu & Accessories', 'Phone Stand / Holder', 'ELEC-STAND-PH', 'pcs', 5000, 12000, ['phone stand', 'holder', 'desk stand', 'simu']),
  prod('elec-p006', 'electronics', 'elec-phones', 'Simu & Accessories', 'Fidget Selfie Stick', 'ELEC-SELFIE', 'pcs', 5000, 15000, ['selfie stick', 'monopod', 'tripod', 'picha']),
  prod('elec-p007', 'electronics', 'elec-audio', 'Audio & Visual', 'Bluetooth Speaker (Portable)', 'ELEC-SPK-BT', 'pcs', 20000, 45000, ['bluetooth speaker', 'spika', 'portable speaker', 'wireless']),
  prod('elec-p008', 'electronics', 'elec-audio', 'Audio & Visual', 'TV Remote Control (Universal)', 'ELEC-REMOTE-TV', 'pcs', 8000, 18000, ['remote control', 'remote ya TV', 'universal remote', 'television']),
  prod('elec-p009', 'electronics', 'elec-audio', 'Audio & Visual', 'HDMI Cable 1.5m', 'ELEC-HDMI-1.5', 'pcs', 8000, 18000, ['HDMI cable', 'cable', 'TV cable', 'monitor']),
  prod('elec-p010', 'electronics', 'elec-computers', 'Kompyuta & Tablets', 'USB Flash Drive 32GB', 'ELEC-USB-32', 'pcs', 8000, 18000, ['flash drive', 'USB', 'memory stick', 'storage']),
  prod('elec-p011', 'electronics', 'elec-computers', 'Kompyuta & Tablets', 'Mouse (USB Wired)', 'ELEC-MOUSE-USB', 'pcs', 8000, 18000, ['mouse', 'kompyuta', 'wired mouse', 'USB mouse']),
  prod('elec-p012', 'electronics', 'elec-computers', 'Kompyuta & Tablets', 'Keyboard (USB Wired)', 'ELEC-KEY-USB', 'pcs', 15000, 30000, ['keyboard', 'kibodi', 'kompyuta', 'USB keyboard']),
  prod('elec-p013', 'electronics', 'elec-computers', 'Kompyuta & Tablets', 'Laptop Bag 15.6"', 'ELEC-BAG-15', 'pcs', 20000, 45000, ['laptop bag', 'mfuko wa laptop', 'backpack', 'kompyuta']),
  prod('elec-p014', 'electronics', 'elec-power', 'Nguvu & Betri', 'Power Bank 10000mAh', 'ELEC-PB-10K', 'pcs', 20000, 45000, ['power bank', 'betri ya kuhamia', 'portable charger', 'simu']),
  prod('elec-p015', 'electronics', 'elec-power', 'Nguvu & Betri', 'Phone Charger (USB-C)', 'ELEC-CHG-USBC', 'pcs', 8000, 18000, ['charger', 'chaja', 'USB-C', 'fast charger']),
  prod('elec-p016', 'electronics', 'elec-power', 'Nguvu & Betri', 'Phone Charger (Micro USB)', 'ELEC-CHG-MICRO', 'pcs', 5000, 12000, ['charger', 'chaja', 'micro USB', 'Android charger']),
  prod('elec-p017', 'electronics', 'elec-power', 'Nguvu & Betri', 'Car Charger (Dual USB)', 'ELEC-CAR-CHG', 'pcs', 8000, 18000, ['car charger', 'chaja ya gari', 'dual USB', 'vehicle']),
  prod('elec-p018', 'electronics', 'elec-lighting', 'Taa & Umeme', 'LED Bulb 9W (Screw E27)', 'ELEC-LED-9W', 'pcs', 3000, 7000, ['LED bulb', 'balbu', 'taa', 'umeme', 'energy saving']),
  prod('elec-p019', 'electronics', 'elec-lighting', 'Taa & Umeme', 'Extension Cord 4-Way 3m', 'ELEC-EXT-4W3', 'pcs', 12000, 25000, ['extension cord', 'nyaya', 'power strip', 'socket']),
  prod('elec-p020', 'electronics', 'elec-cables', 'Cables & Adapters', 'USB-C to USB-A Cable 1m', 'ELEC-CAB-USBC', 'pcs', 5000, 12000, ['USB-C cable', 'data cable', 'charging cable', 'simu']),
  prod('elec-p021', 'electronics', 'elec-cables', 'Cables & Adapters', 'Micro USB Cable 1m', 'ELEC-CAB-MICRO', 'pcs', 3000, 8000, ['micro USB', 'data cable', 'Android cable', 'charging']),
  prod('elec-p022', 'electronics', 'elec-cables', 'Cables & Adapters', 'AUX Audio Cable 3.5mm 1.5m', 'ELEC-AUX-1.5', 'pcs', 3000, 8000, ['AUX cable', 'audio cable', 'stereo', 'headphone jack']),
  prod('elec-p023', 'electronics', 'elec-cables', 'Cables & Adapters', 'OTG Adapter (Micro USB)', 'ELEC-OTG-MICRO', 'pcs', 3000, 7000, ['OTG', 'adapter', 'USB OTG', 'on the go']),
  prod('elec-p024', 'electronics', 'elec-power', 'Nguvu & Betri', 'AA Batteries 4 pack', 'ELEC-BAT-AA4', 'pack', 3000, 6000, ['batteries', 'betri', 'AA', 'alkaline']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 4. RETAIL (duka la rejareja)
// ─────────────────────────────────────────────────────────────────────────────

const retailCategories = [
  cat('ret-food', 'retail', 'Chakula & Nafaka', 'Staple foods and grains', '🌾'),
  cat('ret-cleaning', 'retail', 'Usafi & Sabuni', 'Cleaning and hygiene products', '🧴'),
  cat('ret-personal', 'retail', 'Urembo & Usafi wa Mwili', 'Personal care and beauty', '💆'),
  cat('ret-household', 'retail', 'Vifaa vya Nyumbani', 'Household items and utensils', '🏠'),
  cat('ret-stationery', 'retail', 'Stationery & Ofisi', 'Writing materials and office supplies', '✏️'),
  cat('ret-kids', 'retail', 'Bidhaa za Watoto', 'Baby and children products', '🍼'),
];

const retailProducts = [
  prod('ret-p001', 'retail', 'ret-food', 'Chakula & Nafaka', 'Sukari Kilo 1', 'RET-SUG-1KG', 'kg', 2500, 3000, ['sukari', 'sugar', 'chakula', 'food']),
  prod('ret-p002', 'retail', 'ret-food', 'Chakula & Nafaka', 'Mchele Kg 1', 'RET-RICE-1KG', 'kg', 2500, 3200, ['mchele', 'rice', 'wali', 'chakula']),
  prod('ret-p003', 'retail', 'ret-food', 'Chakula & Nafaka', 'Unga wa Mahindi Kg 1', 'RET-FLOUR-1KG', 'kg', 1800, 2500, ['unga', 'mahindi', 'flour', 'ugali']),
  prod('ret-p004', 'retail', 'ret-food', 'Chakula & Nafaka', 'Mafuta ya Kupikia 1L', 'RET-OIL-1L', 'litre', 5000, 6500, ['mafuta', 'cooking oil', 'sunflower', 'chakula']),
  prod('ret-p005', 'retail', 'ret-food', 'Chakula & Nafaka', 'Chumvi Pakiti 500g', 'RET-SALT-500', 'pack', 500, 800, ['chumvi', 'salt', 'chakula', 'spice']),
  prod('ret-p006', 'retail', 'ret-food', 'Chakula & Nafaka', 'Maharage Kilo 1', 'RET-BEANS-1KG', 'kg', 2500, 3500, ['maharage', 'beans', 'dengu', 'chakula']),
  prod('ret-p007', 'retail', 'ret-food', 'Chakula & Nafaka', 'Unga wa Ngano 500g', 'RET-WHEAT-500', 'pack', 2000, 2800, ['unga wa ngano', 'wheat flour', 'mkate', 'baking']),
  prod('ret-p008', 'retail', 'ret-food', 'Chakula & Nafaka', 'Chai Majani 100g', 'RET-TEA-100', 'pack', 2000, 3000, ['chai', 'tea', 'kinywaji', 'leaves']),
  prod('ret-p009', 'retail', 'ret-food', 'Chakula & Nafaka', 'Maziwa UHT 500ml', 'RET-MILK-500', 'pack', 2000, 2800, ['maziwa', 'milk', 'UHT', 'dairy']),
  prod('ret-p010', 'retail', 'ret-food', 'Chakula & Nafaka', 'Pasta 400g', 'RET-PASTA-400', 'pack', 2000, 3000, ['pasta', 'macaroni', 'spaghetti', 'chakula']),
  prod('ret-p011', 'retail', 'ret-cleaning', 'Usafi & Sabuni', 'Sabuni ya Kufulia 400g', 'RET-SOAP-400', 'bar', 1500, 2200, ['sabuni', 'soap', 'washing', 'laundry']),
  prod('ret-p012', 'retail', 'ret-cleaning', 'Usafi & Sabuni', 'Unga wa Kufulia 1kg', 'RET-DET-1KG', 'pack', 4000, 5500, ['detergent', 'unga wa kufulia', 'washing powder', 'omo']),
  prod('ret-p013', 'retail', 'ret-cleaning', 'Usafi & Sabuni', 'Jiko la Kiberiti (Matchbox)', 'RET-MATCH', 'box', 300, 500, ['kiberiti', 'matchbox', 'matches', 'moto']),
  prod('ret-p014', 'retail', 'ret-cleaning', 'Usafi & Sabuni', 'Mshumaa (Candles 4 pcs)', 'RET-CANDLE-4', 'pack', 1000, 2000, ['mshumaa', 'candle', 'taa', 'mwanga']),
  prod('ret-p015', 'retail', 'ret-personal', 'Urembo & Usafi wa Mwili', 'Dawa ya Meno (Toothpaste) 100g', 'RET-TOOTH-100', 'tube', 2000, 3500, ['toothpaste', 'dawa ya meno', 'meno', 'dental']),
  prod('ret-p016', 'retail', 'ret-personal', 'Urembo & Usafi wa Mwili', 'Mswaki (Toothbrush)', 'RET-BRUSH', 'pcs', 800, 1500, ['mswaki', 'toothbrush', 'meno', 'oral care']),
  prod('ret-p017', 'retail', 'ret-personal', 'Urembo & Usafi wa Mwili', 'Shampoo 200ml', 'RET-SHAMP-200', 'bottle', 4000, 6500, ['shampoo', 'nywele', 'hair wash', 'personal care']),
  prod('ret-p018', 'retail', 'ret-personal', 'Urembo & Usafi wa Mwili', 'Chupi za Usafi (Sanitary Pads 8 pcs)', 'RET-PAD-8', 'pack', 2000, 3500, ['chupi', 'sanitary pads', 'hedhi', 'feminine hygiene']),
  prod('ret-p019', 'retail', 'ret-kids', 'Bidhaa za Watoto', 'Nepi (Diapers 10 pcs)', 'RET-DIAP-10', 'pack', 8000, 12000, ['nepi', 'diapers', 'pampers', 'mtoto', 'baby']),
  prod('ret-p020', 'retail', 'ret-stationery', 'Stationery & Ofisi', 'Daftari la Shule', 'RET-BOOK-SCH', 'pcs', 500, 1000, ['daftari', 'exercise book', 'shule', 'school book']),
  prod('ret-p021', 'retail', 'ret-stationery', 'Stationery & Ofisi', 'Kalamu ya Wino (Bic Pen)', 'RET-PEN', 'pcs', 200, 500, ['kalamu', 'pen', 'bic', 'stationery']),
  prod('ret-p022', 'retail', 'ret-food', 'Chakula & Nafaka', 'Nyanya za Makopo 400g', 'RET-TOM-400', 'tin', 2000, 3000, ['nyanya', 'tomato paste', 'tinned tomato', 'chakula']),
  prod('ret-p023', 'retail', 'ret-food', 'Chakula & Nafaka', 'Mayai (Dozen)', 'RET-EGG-12', 'dozen', 5500, 7000, ['mayai', 'eggs', 'kuku', 'protein']),
  prod('ret-p024', 'retail', 'ret-cleaning', 'Usafi & Sabuni', 'Sabuni ya Mwili 120g', 'RET-BSOAP-120', 'bar', 1200, 2000, ['sabuni ya mwili', 'bath soap', 'shower', 'usafi']),
  prod('ret-p025', 'retail', 'ret-food', 'Chakula & Nafaka', 'Biscuits (Assorted Pack)', 'RET-BISC-ASS', 'pack', 1500, 2500, ['biscuits', 'biskuti', 'vitafunio', 'snack']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 5. WHOLESALE (biashara ya jumla)
// ─────────────────────────────────────────────────────────────────────────────

const wholesaleCategories = [
  cat('whl-grains', 'wholesale', 'Nafaka & Mikunde', 'Bulk grains and legumes', '🌾'),
  cat('whl-oils', 'wholesale', 'Mafuta & Sukari', 'Bulk oils and sugar', '🍯'),
  cat('whl-cleaning', 'wholesale', 'Sabuni & Usafi', 'Bulk cleaning products', '🧼'),
  cat('whl-drinks', 'wholesale', 'Vinywaji vya Jumla', 'Beverages by case', '📦'),
  cat('whl-packaging', 'wholesale', 'Vifungashio', 'Packaging and bags', '🗃️'),
  cat('whl-misc', 'wholesale', 'Bidhaa Mchanganyiko', 'Mixed consumer goods', '🛒'),
];

const wholesaleProducts = [
  prod('whl-p001', 'wholesale', 'whl-grains', 'Nafaka & Mikunde', 'Mchele Mfuko 50kg', 'WHL-RICE-50', 'bag', 90000, 110000, ['mchele', 'rice', 'jumla', 'wholesale', 'mfuko']),
  prod('whl-p002', 'wholesale', 'whl-grains', 'Nafaka & Mikunde', 'Unga wa Mahindi 50kg', 'WHL-FLOUR-50', 'bag', 65000, 80000, ['unga', 'mahindi', 'flour', 'jumla', 'mfuko']),
  prod('whl-p003', 'wholesale', 'whl-grains', 'Nafaka & Mikunde', 'Maharage Mfuko 50kg', 'WHL-BEANS-50', 'bag', 90000, 110000, ['maharage', 'beans', 'jumla', 'mfuko']),
  prod('whl-p004', 'wholesale', 'whl-grains', 'Nafaka & Mikunde', 'Mahindi (Corn) 50kg', 'WHL-CORN-50', 'bag', 45000, 60000, ['mahindi', 'corn', 'jumla', 'mfuko']),
  prod('whl-p005', 'wholesale', 'whl-grains', 'Nafaka & Mikunde', 'Dengu Mfuko 25kg', 'WHL-DENGU-25', 'bag', 50000, 65000, ['dengu', 'lentils', 'jumla', 'mikunde']),
  prod('whl-p006', 'wholesale', 'whl-oils', 'Mafuta & Sukari', 'Sukari Mfuko 50kg', 'WHL-SUG-50', 'bag', 110000, 135000, ['sukari', 'sugar', 'jumla', 'mfuko']),
  prod('whl-p007', 'wholesale', 'whl-oils', 'Mafuta & Sukari', 'Mafuta ya Kupikia 20L', 'WHL-OIL-20', 'jerrycan', 90000, 115000, ['mafuta', 'cooking oil', 'jumla', 'lita 20']),
  prod('whl-p008', 'wholesale', 'whl-oils', 'Mafuta & Sukari', 'Chumvi Mfuko 25kg', 'WHL-SALT-25', 'bag', 8000, 12000, ['chumvi', 'salt', 'jumla', 'mfuko']),
  prod('whl-p009', 'wholesale', 'whl-cleaning', 'Sabuni & Usafi', 'Sabuni za Kufulia (72 bars)', 'WHL-SOAP-72', 'carton', 60000, 80000, ['sabuni', 'soap', 'jumla', 'laundry']),
  prod('whl-p010', 'wholesale', 'whl-cleaning', 'Sabuni & Usafi', 'Unga wa Kufulia OMO 10kg', 'WHL-DET-10', 'bag', 40000, 55000, ['detergent', 'omo', 'unga', 'jumla', 'washing']),
  prod('whl-p011', 'wholesale', 'whl-cleaning', 'Sabuni & Usafi', 'Kiberiti (Matchboxes x 10)', 'WHL-MATCH-10', 'bundle', 2500, 4000, ['kiberiti', 'matches', 'jumla', 'bundle']),
  prod('whl-p012', 'wholesale', 'whl-drinks', 'Vinywaji vya Jumla', 'Soda (Case 24 bottles)', 'WHL-SODA-24', 'case', 28000, 38000, ['soda', 'soft drink', 'case', 'jumla']),
  prod('whl-p013', 'wholesale', 'whl-drinks', 'Vinywaji vya Jumla', 'Maji ya Kunywa (Case 24 x 500ml)', 'WHL-WATER-24', 'case', 12000, 18000, ['maji', 'water', 'case', 'mineral water']),
  prod('whl-p014', 'wholesale', 'whl-drinks', 'Vinywaji vya Jumla', 'Juice (Case 12 x 1L)', 'WHL-JUICE-12', 'case', 30000, 42000, ['juice', 'maji ya matunda', 'case', 'jumla']),
  prod('whl-p015', 'wholesale', 'whl-misc', 'Bidhaa Mchanganyiko', 'Biscuits (Carton 12 packs)', 'WHL-BISC-12', 'carton', 18000, 26000, ['biskuti', 'biscuits', 'carton', 'jumla']),
  prod('whl-p016', 'wholesale', 'whl-misc', 'Bidhaa Mchanganyiko', 'Maandazi ya Makopo (Noodles Case)', 'WHL-NOODLE-12', 'carton', 20000, 30000, ['noodles', 'instant noodles', 'maandazi', 'case']),
  prod('whl-p017', 'wholesale', 'whl-misc', 'Bidhaa Mchanganyiko', 'Nyanya za Makopo (Case 24 tins)', 'WHL-TOM-24', 'case', 38000, 52000, ['nyanya', 'tomato paste', 'tins', 'case']),
  prod('whl-p018', 'wholesale', 'whl-packaging', 'Vifungashio', 'Mifuko ya Plastiki 1kg (1000 pcs)', 'WHL-BAG-1KG', 'bale', 15000, 22000, ['mifuko', 'plastic bags', 'packaging', 'jumla']),
  prod('whl-p019', 'wholesale', 'whl-packaging', 'Vifungashio', 'Mifuko ya Karatasi (Paper bags 500 pcs)', 'WHL-PAPER-500', 'pack', 20000, 30000, ['mifuko ya karatasi', 'paper bags', 'packaging']),
  prod('whl-p020', 'wholesale', 'whl-grains', 'Nafaka & Mikunde', 'Unga wa Ngano (Wheat) 50kg', 'WHL-WHEAT-50', 'bag', 85000, 105000, ['unga wa ngano', 'wheat flour', 'jumla', 'baking']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 6. SALON (saluni / bwalo la nywele)
// ─────────────────────────────────────────────────────────────────────────────

const salonCategories = [
  cat('sal-hair', 'salon', 'Nywele & Urembo', 'Hair treatments and styling', '💇'),
  cat('sal-color', 'salon', 'Rangi ya Nywele', 'Hair coloring and bleaching', '🎨'),
  cat('sal-nails', 'salon', 'Kucha & Manicure', 'Nail care and manicure', '💅'),
  cat('sal-skin', 'salon', 'Ngozi & Uso', 'Skincare and facial treatments', '🧖'),
  cat('sal-products', 'salon', 'Bidhaa za Nywele', 'Hair products for retail', '🧴'),
  cat('sal-tools', 'salon', 'Zana za Saluni', 'Salon tools and equipment', '✂️'),
];

const salonProducts = [
  prod('sal-p001', 'salon', 'sal-hair', 'Nywele & Urembo', 'Relaxer (Cream) 250ml', 'SAL-RELX-250', 'bottle', 8000, 18000, ['relaxer', 'nywele', 'hair relaxer', 'straightening', 'cream']),
  prod('sal-p002', 'salon', 'sal-hair', 'Nywele & Urembo', 'Hair Shampoo (Salon) 500ml', 'SAL-SHAMP-500', 'bottle', 8000, 16000, ['shampoo', 'nywele', 'salon shampoo', 'hair wash']),
  prod('sal-p003', 'salon', 'sal-hair', 'Nywele & Urembo', 'Hair Conditioner 500ml', 'SAL-COND-500', 'bottle', 8000, 16000, ['conditioner', 'nywele', 'hair conditioner', 'moisturize']),
  prod('sal-p004', 'salon', 'sal-hair', 'Nywele & Urembo', 'Braiding Extension (Pack)', 'SAL-BRAID', 'pack', 5000, 12000, ['braiding', 'extension', 'nywele bandia', 'hair extension']),
  prod('sal-p005', 'salon', 'sal-hair', 'Nywele & Urembo', 'Weave (Human Hair Look)', 'SAL-WEAVE', 'pack', 20000, 60000, ['weave', 'nywele bandia', 'hair weave', 'extension']),
  prod('sal-p006', 'salon', 'sal-color', 'Rangi ya Nywele', 'Hair Dye (Black) 100ml', 'SAL-DYE-BLK', 'tube', 8000, 18000, ['rangi', 'hair dye', 'nywele nyeusi', 'black dye']),
  prod('sal-p007', 'salon', 'sal-color', 'Rangi ya Nywele', 'Hair Dye (Brown) 100ml', 'SAL-DYE-BRN', 'tube', 8000, 18000, ['rangi', 'hair dye', 'nywele kahawia', 'brown dye']),
  prod('sal-p008', 'salon', 'sal-color', 'Rangi ya Nywele', 'Hair Bleach Powder 100g', 'SAL-BLEACH-100', 'pack', 5000, 12000, ['bleach', 'hair bleach', 'rangi', 'lighten hair']),
  prod('sal-p009', 'salon', 'sal-nails', 'Kucha & Manicure', 'Nail Polish (Assorted Colors)', 'SAL-NAIL-POL', 'bottle', 3000, 8000, ['nail polish', 'rangi ya kucha', 'manicure', 'nail color']),
  prod('sal-p010', 'salon', 'sal-nails', 'Kucha & Manicure', 'Nail Polish Remover 100ml', 'SAL-NAIL-REM', 'bottle', 3000, 7000, ['nail remover', 'kuondoa rangi', 'acetone', 'nail care']),
  prod('sal-p011', 'salon', 'sal-nails', 'Kucha & Manicure', 'Acrylic Nail Set', 'SAL-ACRYLIC', 'set', 15000, 35000, ['acrylic nails', 'fake nails', 'gel nails', 'kucha']),
  prod('sal-p012', 'salon', 'sal-skin', 'Ngozi & Uso', 'Face Cream (Lightening) 100ml', 'SAL-FACE-CREM', 'jar', 12000, 25000, ['face cream', 'cream ya uso', 'skin lightening', 'mwangaza']),
  prod('sal-p013', 'salon', 'sal-products', 'Bidhaa za Nywele', 'Hair Gel 250ml', 'SAL-GEL-250', 'jar', 5000, 12000, ['gel', 'hair gel', 'nywele', 'styling']),
  prod('sal-p014', 'salon', 'sal-products', 'Bidhaa za Nywele', 'Hair Oil (Coconut) 200ml', 'SAL-OIL-COCO', 'bottle', 6000, 14000, ['hair oil', 'mafuta ya nywele', 'coconut oil', 'nazi']),
  prod('sal-p015', 'salon', 'sal-products', 'Bidhaa za Nywele', 'Edge Control 100ml', 'SAL-EDGE-100', 'jar', 8000, 18000, ['edge control', 'nywele', 'baby hair', 'edges']),
  prod('sal-p016', 'salon', 'sal-tools', 'Zana za Saluni', 'Scissors (Professional Hair)', 'SAL-SCISS', 'pcs', 15000, 35000, ['scissors', 'mkasi', 'salon tools', 'hair cutting']),
  prod('sal-p017', 'salon', 'sal-tools', 'Zana za Saluni', 'Wide Tooth Comb', 'SAL-COMB-WT', 'pcs', 2000, 5000, ['comb', 'kitana', 'wide tooth', 'detangle']),
  prod('sal-p018', 'salon', 'sal-tools', 'Zana za Saluni', 'Hair Pins (Box of 100)', 'SAL-PINS-100', 'box', 3000, 7000, ['pins', 'pini za nywele', 'hair pins', 'styling']),
  prod('sal-p019', 'salon', 'sal-tools', 'Zana za Saluni', 'Rubber Bands (Bag of 200)', 'SAL-RBANDS', 'bag', 2000, 5000, ['rubber bands', 'elastic', 'nywele', 'hair bands']),
  prod('sal-p020', 'salon', 'sal-products', 'Bidhaa za Nywele', 'Hair Cream (Moisturizing) 500ml', 'SAL-CREM-500', 'jar', 8000, 18000, ['hair cream', 'moisturizer', 'nywele', 'leave-in conditioner']),
  prod('sal-p021', 'salon', 'sal-skin', 'Ngozi & Uso', 'Body Lotion 400ml', 'SAL-LOT-400', 'bottle', 8000, 18000, ['body lotion', 'cream ya mwili', 'ngozi', 'moisturizer']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 7. HARDWARE (duka la vifaa vya ujenzi)
// ─────────────────────────────────────────────────────────────────────────────

const hardwareCategories = [
  cat('hw-cement', 'hardware', 'Saruji & Ujenzi', 'Cement and building materials', '🏗️'),
  cat('hw-plumbing', 'hardware', 'Mabomba & Maji', 'Pipes and plumbing fittings', '🔧'),
  cat('hw-electrical', 'hardware', 'Umeme & Wiring', 'Electrical wiring and fittings', '⚡'),
  cat('hw-paint', 'hardware', 'Rangi & Kupaka', 'Paints and painting supplies', '🎨'),
  cat('hw-tools', 'hardware', 'Zana za Mikono', 'Hand tools and fasteners', '🔨'),
  cat('hw-roofing', 'hardware', 'Paa & Bati', 'Roofing materials', '🏠'),
];

const hardwareProducts = [
  prod('hw-p001', 'hardware', 'hw-cement', 'Saruji & Ujenzi', 'Saruji (Cement) 50kg', 'HW-CEM-50', 'bag', 22000, 28000, ['saruji', 'cement', 'ujenzi', 'concrete']),
  prod('hw-p002', 'hardware', 'hw-cement', 'Saruji & Ujenzi', 'Msumari wa Kawaida (Nails 1 inch)', 'HW-NAIL-1IN', 'kg', 2500, 4000, ['msumari', 'nails', 'ujenzi', 'iron nails']),
  prod('hw-p003', 'hardware', 'hw-cement', 'Saruji & Ujenzi', 'Wire Mesh (2x1m)', 'HW-MESH-2X1', 'sheet', 15000, 25000, ['wire mesh', 'waya', 'matumizi', 'fence', 'ujenzi']),
  prod('hw-p004', 'hardware', 'hw-cement', 'Saruji & Ujenzi', 'Steel Bar 12mm (6m)', 'HW-BAR-12', 'pcs', 35000, 50000, ['steel bar', 'chuma', 'reinforcement', 'ujenzi', 'slabs']),
  prod('hw-p005', 'hardware', 'hw-plumbing', 'Mabomba & Maji', 'PVC Pipe 1/2 inch (6m)', 'HW-PVC-HALF', 'pcs', 8000, 14000, ['PVC pipe', 'bomba', 'maji', 'plumbing', 'half inch']),
  prod('hw-p006', 'hardware', 'hw-plumbing', 'Mabomba & Maji', 'PVC Pipe 1 inch (6m)', 'HW-PVC-1IN', 'pcs', 15000, 24000, ['PVC pipe', 'bomba', 'maji', 'plumbing', '1 inch']),
  prod('hw-p007', 'hardware', 'hw-plumbing', 'Mabomba & Maji', 'PVC Elbow Fitting 1/2 inch', 'HW-ELBOW-HALF', 'pcs', 800, 1500, ['elbow', 'fitting', 'PVC', 'plumbing', 'bend']),
  prod('hw-p008', 'hardware', 'hw-plumbing', 'Mabomba & Maji', 'Tap (Water Faucet)', 'HW-TAP', 'pcs', 8000, 15000, ['tap', 'bomba la maji', 'faucet', 'maji']),
  prod('hw-p009', 'hardware', 'hw-electrical', 'Umeme & Wiring', 'Electrical Cable 1.5mm² (100m)', 'HW-CAB-1.5', 'roll', 50000, 75000, ['cable', 'waya', 'umeme', 'electrical', '1.5mm']),
  prod('hw-p010', 'hardware', 'hw-electrical', 'Umeme & Wiring', 'Electrical Cable 2.5mm² (100m)', 'HW-CAB-2.5', 'roll', 80000, 115000, ['cable', 'waya', 'umeme', 'electrical', '2.5mm']),
  prod('hw-p011', 'hardware', 'hw-electrical', 'Umeme & Wiring', 'Light Switch (Single)', 'HW-SWITCH-1', 'pcs', 2500, 5000, ['switch', 'swichi', 'umeme', 'light switch']),
  prod('hw-p012', 'hardware', 'hw-electrical', 'Umeme & Wiring', 'Power Socket (Double)', 'HW-SOCKET-2', 'pcs', 4000, 8000, ['socket', 'outlet', 'umeme', 'power socket']),
  prod('hw-p013', 'hardware', 'hw-paint', 'Rangi & Kupaka', 'Rangi ya Ndani (Interior Paint) 4L', 'HW-PAINT-INT4', 'tin', 30000, 48000, ['rangi', 'paint', 'interior', 'wall paint']),
  prod('hw-p014', 'hardware', 'hw-paint', 'Rangi & Kupaka', 'Rangi ya Nje (Exterior Paint) 4L', 'HW-PAINT-EXT4', 'tin', 35000, 55000, ['rangi', 'paint', 'exterior', 'outside paint']),
  prod('hw-p015', 'hardware', 'hw-paint', 'Rangi & Kupaka', 'Paint Roller Set (23cm)', 'HW-ROLLER-23', 'set', 8000, 16000, ['roller', 'kupaka rangi', 'paint roller', 'set']),
  prod('hw-p016', 'hardware', 'hw-paint', 'Rangi & Kupaka', 'Sandpaper (Pack of 10 sheets)', 'HW-SAND-10', 'pack', 5000, 10000, ['sandpaper', 'karatasi ya kusaga', 'surface prep', 'grit']),
  prod('hw-p017', 'hardware', 'hw-tools', 'Zana za Mikono', 'Nyundo (Hammer)', 'HW-HAMMER', 'pcs', 8000, 18000, ['nyundo', 'hammer', 'tools', 'construction']),
  prod('hw-p018', 'hardware', 'hw-tools', 'Zana za Mikono', 'Koleo (Screwdriver Set)', 'HW-SCREW-SET', 'set', 10000, 22000, ['koleo', 'screwdriver', 'tools', 'set']),
  prod('hw-p019', 'hardware', 'hw-tools', 'Zana za Mikono', 'Padlock 60mm', 'HW-LOCK-60', 'pcs', 8000, 18000, ['padlock', 'kufuli', 'lock', 'security']),
  prod('hw-p020', 'hardware', 'hw-roofing', 'Paa & Bati', 'Bati (Galvanized Sheet) 3m', 'HW-BATI-3M', 'sheet', 25000, 38000, ['bati', 'roofing sheet', 'galvanized', 'paa', 'roof']),
  prod('hw-p021', 'hardware', 'hw-roofing', 'Paa & Bati', 'Roofing Nails (1kg)', 'HW-RNAIL-1KG', 'kg', 3000, 6000, ['roofing nails', 'misumari ya bati', 'roof', 'nails']),
  prod('hw-p022', 'hardware', 'hw-cement', 'Saruji & Ujenzi', 'Binding Wire 1kg', 'HW-BWIRE-1', 'kg', 4000, 8000, ['binding wire', 'waya', 'construction', 'steel']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 8. AGRICULTURE (kilimo)
// ─────────────────────────────────────────────────────────────────────────────

const agricultureCategories = [
  cat('agri-seeds', 'agriculture', 'Mbegu', 'Seeds for various crops', '🌱'),
  cat('agri-fertilizer', 'agriculture', 'Mbolea', 'Fertilizers and soil conditioners', '🌿'),
  cat('agri-pesticide', 'agriculture', 'Dawa za Wadudu', 'Pesticides, herbicides and fungicides', '🧪'),
  cat('agri-tools', 'agriculture', 'Zana za Kilimo', 'Farming tools and equipment', '🌾'),
  cat('agri-irrigation', 'agriculture', 'Umwagiliaji', 'Irrigation equipment and supplies', '💧'),
  cat('agri-produce', 'agriculture', 'Mazao & Mifuko', 'Post-harvest storage and sacks', '📦'),
];

const agricultureProducts = [
  prod('agri-p001', 'agriculture', 'agri-seeds', 'Mbegu', 'Mbegu ya Mahindi (Hybrid) 2kg', 'AGRI-SEED-CORN2', 'packet', 15000, 25000, ['mbegu', 'mahindi', 'corn seeds', 'hybrid', 'kilimo']),
  prod('agri-p002', 'agriculture', 'agri-seeds', 'Mbegu', 'Mbegu ya Maharage 1kg', 'AGRI-SEED-BEAN1', 'packet', 8000, 15000, ['mbegu', 'maharage', 'bean seeds', 'kilimo']),
  prod('agri-p003', 'agriculture', 'agri-seeds', 'Mbegu', 'Mbegu ya Nyanya 10g', 'AGRI-SEED-TOM10', 'packet', 5000, 10000, ['mbegu', 'nyanya', 'tomato seeds', 'kilimo', 'mboga']),
  prod('agri-p004', 'agriculture', 'agri-seeds', 'Mbegu', 'Mbegu ya Vitunguu 10g', 'AGRI-SEED-ONION', 'packet', 5000, 10000, ['mbegu', 'vitunguu', 'onion seeds', 'kilimo']),
  prod('agri-p005', 'agriculture', 'agri-seeds', 'Mbegu', 'Mbegu ya Alizeti (Sunflower) 2kg', 'AGRI-SEED-SUN2', 'packet', 12000, 20000, ['alizeti', 'sunflower seeds', 'mbegu', 'kilimo']),
  prod('agri-p006', 'agriculture', 'agri-seeds', 'Mbegu', 'Mbegu ya Viazi Vitamu 1kg', 'AGRI-SEED-SPOT1', 'kg', 5000, 10000, ['viazi vitamu', 'sweet potato', 'mbegu', 'kilimo']),
  prod('agri-p007', 'agriculture', 'agri-seeds', 'Mbegu', 'Mbegu ya Pilipili Hoho 5g', 'AGRI-SEED-PEPP', 'packet', 5000, 10000, ['pilipili hoho', 'pepper seeds', 'mbegu', 'mboga']),
  prod('agri-p008', 'agriculture', 'agri-fertilizer', 'Mbolea', 'DAP Mbolea 50kg', 'AGRI-DAP-50', 'bag', 80000, 100000, ['DAP', 'mbolea', 'fertilizer', 'kilimo']),
  prod('agri-p009', 'agriculture', 'agri-fertilizer', 'Mbolea', 'CAN Mbolea 50kg', 'AGRI-CAN-50', 'bag', 65000, 82000, ['CAN', 'mbolea', 'fertilizer', 'calcium ammonium nitrate']),
  prod('agri-p010', 'agriculture', 'agri-fertilizer', 'Mbolea', 'NPK Mbolea 50kg', 'AGRI-NPK-50', 'bag', 85000, 108000, ['NPK', 'mbolea', 'fertilizer', 'compound fertilizer']),
  prod('agri-p011', 'agriculture', 'agri-fertilizer', 'Mbolea', 'Urea Mbolea 50kg', 'AGRI-UREA-50', 'bag', 70000, 90000, ['urea', 'mbolea', 'nitrogen fertilizer', 'kilimo']),
  prod('agri-p012', 'agriculture', 'agri-pesticide', 'Dawa za Wadudu', 'Dawa ya Wadudu (Insecticide) 1L', 'AGRI-INSECT-1', 'litre', 20000, 35000, ['dawa', 'insecticide', 'wadudu', 'kilimo', 'spray']),
  prod('agri-p013', 'agriculture', 'agri-pesticide', 'Dawa za Wadudu', 'Dawa ya Magugu (Herbicide) 1L', 'AGRI-HERB-1', 'litre', 25000, 40000, ['dawa', 'herbicide', 'magugu', 'weed killer']),
  prod('agri-p014', 'agriculture', 'agri-pesticide', 'Dawa za Wadudu', 'Fungicide (Ukungu) 500ml', 'AGRI-FUNGI-500', 'bottle', 15000, 28000, ['fungicide', 'ukungu', 'mold', 'fungal disease']),
  prod('agri-p015', 'agriculture', 'agri-tools', 'Zana za Kilimo', 'Jembe la Kawaida (Garden Hoe)', 'AGRI-HOE', 'pcs', 8000, 16000, ['jembe', 'hoe', 'kilimo', 'garden tool']),
  prod('agri-p016', 'agriculture', 'agri-tools', 'Zana za Kilimo', 'Panga (Machete)', 'AGRI-PANGA', 'pcs', 6000, 12000, ['panga', 'machete', 'kilimo', 'cutting tool']),
  prod('agri-p017', 'agriculture', 'agri-tools', 'Zana za Kilimo', 'Koleo la Kilimo (Spade)', 'AGRI-SPADE', 'pcs', 12000, 22000, ['koleo', 'spade', 'kilimo', 'digging']),
  prod('agri-p018', 'agriculture', 'agri-irrigation', 'Umwagiliaji', 'Bakuli la Dawa (Knapsack Sprayer) 15L', 'AGRI-SPRAY-15', 'pcs', 35000, 60000, ['sprayer', 'kirizi', 'dawa', 'pump sprayer', 'irrigation']),
  prod('agri-p019', 'agriculture', 'agri-irrigation', 'Umwagiliaji', 'Hose Pipe 1/2 inch (25m)', 'AGRI-HOSE-25', 'roll', 20000, 35000, ['hose pipe', 'mabomba ya maji', 'irrigation', 'garden']),
  prod('agri-p020', 'agriculture', 'agri-produce', 'Mazao & Mifuko', 'Mfuko wa Gunia (PP Bag 50kg)', 'AGRI-BAG-50', 'pcs', 1500, 3000, ['gunia', 'sack', 'mfuko', 'storage', 'harvest']),
  prod('agri-p021', 'agriculture', 'agri-produce', 'Mazao & Mifuko', 'Twine ya Sisal (Roll)', 'AGRI-TWINE', 'roll', 5000, 10000, ['twine', 'uzi', 'sisal', 'binding']),
  prod('agri-p022', 'agriculture', 'agri-fertilizer', 'Mbolea', 'Compost/Organic Fertilizer 20kg', 'AGRI-COMP-20', 'bag', 15000, 25000, ['compost', 'mbolea asili', 'organic', 'natural fertilizer']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 9. TAILORING (ushonaji)
// ─────────────────────────────────────────────────────────────────────────────

const tailoringCategories = [
  cat('tail-fabric', 'tailoring', 'Vitambaa', 'Fabrics and materials for sewing', '🧵'),
  cat('tail-notions', 'tailoring', 'Vifaa vya Ushonaji', 'Sewing notions and accessories', '🪡'),
  cat('tail-thread', 'tailoring', 'Nyuzi & Uzi', 'Threads and yarns', '🧶'),
  cat('tail-lining', 'tailoring', 'Liner & Backing', 'Lining and interfacing materials', '📋'),
  cat('tail-decoration', 'tailoring', 'Mapambo & Embroidery', 'Decorative elements and embroidery', '✨'),
];

const tailoringProducts = [
  prod('tail-p001', 'tailoring', 'tail-fabric', 'Vitambaa', 'Kitenge (African Print) 2 Yards', 'TAIL-KIT-2YD', 'yards', 8000, 18000, ['kitenge', 'ankara', 'african print', 'fabric', 'nguo']),
  prod('tail-p002', 'tailoring', 'tail-fabric', 'Vitambaa', 'Chiffon ya Uchawi 2 Yards', 'TAIL-CHIFF-2YD', 'yards', 8000, 18000, ['chiffon', 'fabric', 'vitambaa', 'lightweight']),
  prod('tail-p003', 'tailoring', 'tail-fabric', 'Vitambaa', 'Denim (Jeans) 2 Yards', 'TAIL-DEN-2YD', 'yards', 10000, 22000, ['denim', 'jeans', 'suruali', 'heavy fabric']),
  prod('tail-p004', 'tailoring', 'tail-fabric', 'Vitambaa', 'Cotton Plain (White) 2 Yards', 'TAIL-COTT-2YD', 'yards', 5000, 12000, ['cotton', 'pamba', 'plain fabric', 'white']),
  prod('tail-p005', 'tailoring', 'tail-fabric', 'Vitambaa', 'Kanga (Leso) 2 Yards', 'TAIL-KANGA-2YD', 'yards', 6000, 14000, ['kanga', 'leso', 'kikoi', 'fabric']),
  prod('tail-p006', 'tailoring', 'tail-fabric', 'Vitambaa', 'Vitenge vya Satin 2 Yards', 'TAIL-SATIN-2YD', 'yards', 12000, 25000, ['satin', 'vitambaa', 'evening wear', 'formal']),
  prod('tail-p007', 'tailoring', 'tail-notions', 'Vifaa vya Ushonaji', 'Zip/Zipper Assorted (10 pcs)', 'TAIL-ZIP-10', 'pack', 5000, 12000, ['zip', 'zipper', 'mfuko', 'closure', 'ushonaji']),
  prod('tail-p008', 'tailoring', 'tail-notions', 'Vifaa vya Ushonaji', 'Buttons (Assorted Box 50 pcs)', 'TAIL-BTN-50', 'box', 3000, 7000, ['buttons', 'vifungo', 'shirt buttons', 'ushonaji']),
  prod('tail-p009', 'tailoring', 'tail-notions', 'Vifaa vya Ushonaji', 'Elastic Band 2cm (Roll 10m)', 'TAIL-ELAS-10', 'roll', 5000, 10000, ['elastic', 'mpira', 'bando', 'waistband']),
  prod('tail-p010', 'tailoring', 'tail-notions', 'Vifaa vya Ushonaji', 'Tape Measure (150cm)', 'TAIL-TAPE', 'pcs', 2000, 5000, ['tape measure', 'kipimo', 'measuring tape', 'ushonaji']),
  prod('tail-p011', 'tailoring', 'tail-notions', 'Vifaa vya Ushonaji', 'Pins (Box of 100)', 'TAIL-PINS-100', 'box', 2000, 5000, ['pins', 'sindano', 'pini', 'sewing pins']),
  prod('tail-p012', 'tailoring', 'tail-notions', 'Vifaa vya Ushonaji', 'Needles Pack (Assorted)', 'TAIL-NEEDLE', 'pack', 2000, 5000, ['needles', 'sindano', 'hand sewing', 'needle pack']),
  prod('tail-p013', 'tailoring', 'tail-thread', 'Nyuzi & Uzi', 'Nyuzi ya Kushona (Black Thread 1000m)', 'TAIL-THR-BLK', 'spool', 3000, 7000, ['thread', 'nyuzi', 'black', 'sewing thread']),
  prod('tail-p014', 'tailoring', 'tail-thread', 'Nyuzi & Uzi', 'Nyuzi ya Kushona (White Thread 1000m)', 'TAIL-THR-WHT', 'spool', 3000, 7000, ['thread', 'nyuzi', 'white', 'sewing thread']),
  prod('tail-p015', 'tailoring', 'tail-thread', 'Nyuzi & Uzi', 'Nyuzi ya Embroidery (Assorted Colors)', 'TAIL-EMB-THR', 'set', 5000, 12000, ['embroidery thread', 'nyuzi', 'colorful', 'decoration']),
  prod('tail-p016', 'tailoring', 'tail-lining', 'Liner & Backing', 'Lining Fabric 2 Yards', 'TAIL-LINING-2YD', 'yards', 5000, 12000, ['lining', 'kitambaa cha ndani', 'backing', 'inner fabric']),
  prod('tail-p017', 'tailoring', 'tail-lining', 'Liner & Backing', 'Interfacing/Fusible Web 1 Yard', 'TAIL-INTERF-1YD', 'yards', 4000, 9000, ['interfacing', 'fusible', 'stiffener', 'collar']),
  prod('tail-p018', 'tailoring', 'tail-decoration', 'Mapambo & Embroidery', 'Lace Trim (3m)', 'TAIL-LACE-3M', 'roll', 5000, 12000, ['lace', 'mapambo', 'trim', 'decoration', 'nguo']),
  prod('tail-p019', 'tailoring', 'tail-decoration', 'Mapambo & Embroidery', 'Sequins (Pack)', 'TAIL-SEQ', 'pack', 3000, 8000, ['sequins', 'mapambo', 'glitter', 'sparkling']),
  prod('tail-p020', 'tailoring', 'tail-notions', 'Vifaa vya Ushonaji', 'Scissors (Fabric Cutting)', 'TAIL-SCISS-FAB', 'pcs', 10000, 25000, ['scissors', 'mkasi', 'fabric scissors', 'cutting']),
  prod('tail-p021', 'tailoring', 'tail-fabric', 'Vitambaa', 'Brocade Vitambaa 2 Yards', 'TAIL-BROC-2YD', 'yards', 15000, 32000, ['brocade', 'vitambaa', 'special occasion', 'formal wear']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 10. TRANSPORT (usafirishaji)
// ─────────────────────────────────────────────────────────────────────────────

const transportCategories = [
  cat('trans-oil', 'transport', 'Mafuta & Hydraulics', 'Engine oils and hydraulic fluids', '🛢️'),
  cat('trans-parts', 'transport', 'Vipuri vya Gari', 'Spare parts and filters', '⚙️'),
  cat('trans-tyres', 'transport', 'Matairi & Rims', 'Tyres and wheels', '🚗'),
  cat('trans-battery', 'transport', 'Betri za Gari', 'Vehicle batteries', '🔋'),
  cat('trans-body', 'transport', 'Mwili wa Gari', 'Body and exterior parts', '🚙'),
  cat('trans-tools', 'transport', 'Vifaa vya Gari', 'Vehicle tools and accessories', '🔧'),
];

const transportProducts = [
  prod('trans-p001', 'transport', 'trans-oil', 'Mafuta & Hydraulics', 'Engine Oil 20W-50 4L', 'TRANS-OIL-20W-4', 'litre', 20000, 35000, ['engine oil', 'mafuta ya injini', '20W-50', 'oil change']),
  prod('trans-p002', 'transport', 'trans-oil', 'Mafuta & Hydraulics', 'Gear Oil 90 1L', 'TRANS-GEAR-90-1', 'litre', 5000, 10000, ['gear oil', 'mafuta ya gia', 'transmission', 'gearbox']),
  prod('trans-p003', 'transport', 'trans-oil', 'Mafuta & Hydraulics', 'Brake Fluid DOT 3 500ml', 'TRANS-BRAKE-F', 'bottle', 5000, 10000, ['brake fluid', 'mafuta ya breki', 'DOT3', 'hydraulic']),
  prod('trans-p004', 'transport', 'trans-oil', 'Mafuta & Hydraulics', 'Coolant/Antifreeze 1L', 'TRANS-COOL-1', 'litre', 6000, 12000, ['coolant', 'antifreeze', 'radiator', 'maji ya injini']),
  prod('trans-p005', 'transport', 'trans-parts', 'Vipuri vya Gari', 'Air Filter (Universal)', 'TRANS-AF-UNI', 'pcs', 8000, 18000, ['air filter', 'filta ya hewa', 'engine', 'filter replacement']),
  prod('trans-p006', 'transport', 'trans-parts', 'Vipuri vya Gari', 'Oil Filter (Universal)', 'TRANS-OF-UNI', 'pcs', 5000, 12000, ['oil filter', 'filta ya mafuta', 'engine', 'filter']),
  prod('trans-p007', 'transport', 'trans-parts', 'Vipuri vya Gari', 'Fuel Filter (Universal)', 'TRANS-FF-UNI', 'pcs', 6000, 14000, ['fuel filter', 'filta ya mafuta ya gari', 'petrol', 'diesel filter']),
  prod('trans-p008', 'transport', 'trans-parts', 'Vipuri vya Gari', 'Spark Plugs (Set of 4)', 'TRANS-SPARK-4', 'set', 15000, 30000, ['spark plugs', 'mishumaa ya injini', 'ignition', 'engine']),
  prod('trans-p009', 'transport', 'trans-parts', 'Vipuri vya Gari', 'Brake Pads (Front Set)', 'TRANS-BPAD-F', 'set', 20000, 40000, ['brake pads', 'mabano ya breki', 'brakes', 'stopping']),
  prod('trans-p010', 'transport', 'trans-parts', 'Vipuri vya Gari', 'Fan Belt (V-Belt)', 'TRANS-FBELT', 'pcs', 8000, 18000, ['fan belt', 'ukanda wa feni', 'V-belt', 'engine belt']),
  prod('trans-p011', 'transport', 'trans-tyres', 'Matairi & Rims', 'Tyre 185/65R14', 'TRANS-TYRE-185', 'pcs', 80000, 130000, ['tyre', 'tairi', '14 inch', 'Toyota']),
  prod('trans-p012', 'transport', 'trans-tyres', 'Matairi & Rims', 'Tyre 195/65R15', 'TRANS-TYRE-195', 'pcs', 90000, 145000, ['tyre', 'tairi', '15 inch', 'saloon car']),
  prod('trans-p013', 'transport', 'trans-tyres', 'Matairi & Rims', 'Tyre 225/70R16 (SUV/4WD)', 'TRANS-TYRE-225', 'pcs', 130000, 200000, ['tyre', 'tairi', '16 inch', 'SUV', '4WD']),
  prod('trans-p014', 'transport', 'trans-battery', 'Betri za Gari', 'Car Battery 45Ah', 'TRANS-BAT-45', 'pcs', 90000, 140000, ['battery', 'betri', '45Ah', 'car battery', 'starting']),
  prod('trans-p015', 'transport', 'trans-battery', 'Betri za Gari', 'Car Battery 75Ah', 'TRANS-BAT-75', 'pcs', 130000, 200000, ['battery', 'betri', '75Ah', 'heavy duty', 'truck']),
  prod('trans-p016', 'transport', 'trans-tools', 'Vifaa vya Gari', 'Wiper Blades (Pair)', 'TRANS-WIPER-PR', 'pair', 10000, 20000, ['wiper', 'wipers', 'windscreen', 'rain']),
  prod('trans-p017', 'transport', 'trans-tools', 'Vifaa vya Gari', 'Jump Start Cables (4m)', 'TRANS-JUMP-4', 'pcs', 15000, 30000, ['jump cables', 'jumper cables', 'battery dead', 'starting']),
  prod('trans-p018', 'transport', 'trans-tools', 'Vifaa vya Gari', 'Car Jack (Hydraulic 2T)', 'TRANS-JACK-2T', 'pcs', 35000, 65000, ['car jack', 'jeki ya gari', 'hydraulic jack', 'tyre change']),
  prod('trans-p019', 'transport', 'trans-body', 'Mwili wa Gari', 'Car Headlight Bulb H4', 'TRANS-BULB-H4', 'pcs', 5000, 12000, ['headlight', 'taa ya mbele', 'H4 bulb', 'car light']),
  prod('trans-p020', 'transport', 'trans-body', 'Mwili wa Gari', 'Side Mirror (Universal)', 'TRANS-MIRROR', 'pcs', 20000, 40000, ['side mirror', 'kioo cha upande', 'wing mirror', 'car']),
  prod('trans-p021', 'transport', 'trans-parts', 'Vipuri vya Gari', 'Fuses Kit (Assorted)', 'TRANS-FUSE-KIT', 'kit', 5000, 12000, ['fuses', 'fyuzi', 'electrical', 'car fuses']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 11. CONSTRUCTION (ujenzi wa majengo)
// ─────────────────────────────────────────────────────────────────────────────

const constructionCategories = [
  cat('con-foundation', 'construction', 'Msingi & Muundo', 'Foundation and structural materials', '🏗️'),
  cat('con-floor', 'construction', 'Sakafu & Tiles', 'Floor and wall tiles', '🏠'),
  cat('con-roofing', 'construction', 'Paa & Dari', 'Roofing and ceiling materials', '🏚️'),
  cat('con-doors', 'construction', 'Madirisha & Milango', 'Windows and doors', '🚪'),
  cat('con-mep', 'construction', 'Umeme & Mabomba', 'MEP — electrical and plumbing', '🔌'),
  cat('con-finishing', 'construction', 'Ukamilishaji', 'Finishing materials and paints', '🎨'),
];

const constructionProducts = [
  prod('con-p001', 'construction', 'con-foundation', 'Msingi & Muundo', 'Reinforcing Bar (Rebar) 12mm x 6m', 'CON-REBAR-12', 'pcs', 38000, 55000, ['rebar', 'chuma', 'steel bar', 'reinforcement', 'foundation']),
  prod('con-p002', 'construction', 'con-foundation', 'Msingi & Muundo', 'Reinforcing Bar (Rebar) 8mm x 6m', 'CON-REBAR-8', 'pcs', 18000, 28000, ['rebar', 'chuma', '8mm', 'stirrups', 'slab']),
  prod('con-p003', 'construction', 'con-foundation', 'Msingi & Muundo', 'Binding Wire 1.6mm 1kg', 'CON-BWIRE-1', 'kg', 4000, 8000, ['binding wire', 'waya wa kufunga', 'construction', 'steel fixing']),
  prod('con-p004', 'construction', 'con-foundation', 'Msingi & Muundo', 'Timber Plank (2x4x12ft)', 'CON-TIMBER-244', 'pcs', 12000, 22000, ['timber', 'mbao', 'formwork', 'shuttering', 'wood']),
  prod('con-p005', 'construction', 'con-foundation', 'Msingi & Muundo', 'Plywood (4x8 ft, 18mm)', 'CON-PLY-18', 'sheet', 35000, 55000, ['plywood', 'bodi', 'formwork', 'shuttering']),
  prod('con-p006', 'construction', 'con-floor', 'Sakafu & Tiles', 'Ceramic Floor Tiles (30x30cm) m²', 'CON-TILE-30', 'm2', 30000, 50000, ['tiles', 'vigae', 'floor tiles', 'ceramic', 'sakafu']),
  prod('con-p007', 'construction', 'con-floor', 'Sakafu & Tiles', 'Ceramic Floor Tiles (60x60cm) m²', 'CON-TILE-60', 'm2', 50000, 80000, ['tiles', 'vigae', 'large tiles', '60x60', 'sakafu']),
  prod('con-p008', 'construction', 'con-floor', 'Sakafu & Tiles', 'Wall Tiles (20x30cm) m²', 'CON-WALL-TILE', 'm2', 28000, 45000, ['wall tiles', 'vigae vya ukuta', 'bathroom', 'kitchen tiles']),
  prod('con-p009', 'construction', 'con-floor', 'Sakafu & Tiles', 'Tile Adhesive 20kg', 'CON-TILE-ADH', 'bag', 18000, 28000, ['tile adhesive', 'gundi la vigae', 'tile fix', 'grout']),
  prod('con-p010', 'construction', 'con-floor', 'Sakafu & Tiles', 'Tile Grout 5kg (White)', 'CON-GROUT-5', 'bag', 8000, 15000, ['grout', 'saruji ya vigae', 'tile joints', 'white']),
  prod('con-p011', 'construction', 'con-roofing', 'Paa & Dari', 'Roofing Sheet (Mabati) 0.3mm 3m', 'CON-BATI-3M', 'sheet', 28000, 42000, ['roofing sheet', 'bati', 'mabati', 'roof', 'galvanized']),
  prod('con-p012', 'construction', 'con-roofing', 'Paa & Dari', 'Ceiling Board (Gyproc 4x8ft)', 'CON-CEIL-48', 'sheet', 20000, 35000, ['ceiling board', 'dari', 'gyproc', 'plasterboard']),
  prod('con-p013', 'construction', 'con-roofing', 'Paa & Dari', 'Roof Purlins (C-section 60x40mm 6m)', 'CON-PURLIN-6', 'pcs', 25000, 40000, ['purlin', 'steel purlin', 'roofing', 'frame']),
  prod('con-p014', 'construction', 'con-doors', 'Madirisha & Milango', 'Steel Door Frame (Standard)', 'CON-DOOR-FR', 'pcs', 60000, 100000, ['door frame', 'fremu ya mlango', 'steel frame', 'entry']),
  prod('con-p015', 'construction', 'con-doors', 'Madirisha & Milango', 'Window Frame (Aluminium 60x60cm)', 'CON-WIN-FR', 'pcs', 50000, 85000, ['window frame', 'fremu ya dirisha', 'aluminium window', 'glass']),
  prod('con-p016', 'construction', 'con-mep', 'Umeme & Mabomba', 'PVC Conduit Pipe 20mm (3m)', 'CON-COND-20', 'pcs', 4000, 8000, ['conduit', 'bomba la waya', 'electrical conduit', '20mm']),
  prod('con-p017', 'construction', 'con-mep', 'Umeme & Mabomba', 'PPR Pipe 20mm (4m)', 'CON-PPR-20', 'pcs', 6000, 12000, ['PPR pipe', 'bomba la maji ya moto', 'hot water', 'plumbing']),
  prod('con-p018', 'construction', 'con-finishing', 'Ukamilishaji', 'Wall Putty 20kg', 'CON-PUTTY-20', 'bag', 18000, 28000, ['putty', 'spackling', 'wall prep', 'smoothing']),
  prod('con-p019', 'construction', 'con-finishing', 'Ukamilishaji', 'Waterproofing Compound 20kg', 'CON-WATER-20', 'bucket', 35000, 55000, ['waterproofing', 'kuzuia maji', 'sealant', 'roof waterproofing']),
  prod('con-p020', 'construction', 'con-finishing', 'Ukamilishaji', 'Primer Coat 4L', 'CON-PRIMER-4', 'tin', 20000, 35000, ['primer', 'paint undercoat', 'wall primer', 'sealer']),
  prod('con-p021', 'construction', 'con-foundation', 'Msingi & Muundo', 'Hollow Blocks (Concrete 20cm)', 'CON-BLOCK-20', 'pcs', 2000, 3500, ['hollow blocks', 'matofali', 'concrete block', 'walling']),
];

// ─────────────────────────────────────────────────────────────────────────────
// 12. SERVICE (huduma za biashara)
// ─────────────────────────────────────────────────────────────────────────────

const serviceCategories = [
  cat('svc-office', 'service', 'Stationery & Ofisi', 'Office stationery and supplies', '📎'),
  cat('svc-tech', 'service', 'Teknolojia & IT', 'IT equipment and tech accessories', '💻'),
  cat('svc-security', 'service', 'Usalama & Ulinzi', 'Security equipment and supplies', '🔒'),
  cat('svc-cleaning', 'service', 'Usafi wa Ofisi', 'Office cleaning and hygiene', '🧹'),
  cat('svc-printing', 'service', 'Printing & Uchapishaji', 'Printing supplies and consumables', '🖨️'),
  cat('svc-branding', 'service', 'Branding & Marketing', 'Branding and marketing materials', '🏷️'),
];

const serviceProducts = [
  prod('svc-p001', 'service', 'svc-office', 'Stationery & Ofisi', 'A4 Paper Ream (500 sheets)', 'SVC-A4-REAM', 'ream', 10000, 16000, ['A4 paper', 'karatasi', 'ream', 'printer paper', 'stationery']),
  prod('svc-p002', 'service', 'svc-office', 'Stationery & Ofisi', 'Stapler (Heavy Duty)', 'SVC-STAPLE-HD', 'pcs', 10000, 22000, ['stapler', 'pambizo', 'binding', 'office tool']),
  prod('svc-p003', 'service', 'svc-office', 'Stationery & Ofisi', 'Staples (Box of 5000)', 'SVC-STAP-5000', 'box', 3000, 6000, ['staples', 'pambizo', 'stapler', 'stationery']),
  prod('svc-p004', 'service', 'svc-office', 'Stationery & Ofisi', 'Paper Clips (Box of 100)', 'SVC-CLIP-100', 'box', 1500, 3500, ['paper clips', 'klipsi', 'fastener', 'stationery']),
  prod('svc-p005', 'service', 'svc-office', 'Stationery & Ofisi', 'Ballpoint Pens (Box 50 pcs)', 'SVC-PEN-50', 'box', 8000, 18000, ['pens', 'kalamu', 'bic', 'ballpoint', 'stationery']),
  prod('svc-p006', 'service', 'svc-office', 'Stationery & Ofisi', 'Manila Folders (50 pcs)', 'SVC-FOLD-50', 'pack', 10000, 22000, ['folders', 'faili', 'document folder', 'stationery']),
  prod('svc-p007', 'service', 'svc-office', 'Stationery & Ofisi', 'Whiteboard Markers (Set of 4)', 'SVC-WB-MARK4', 'set', 5000, 12000, ['whiteboard marker', 'marker', 'board', 'presentation']),
  prod('svc-p008', 'service', 'svc-office', 'Stationery & Ofisi', 'Calculator (Desktop)', 'SVC-CALC-DT', 'pcs', 10000, 22000, ['calculator', 'kikokotoo', 'desktop', 'accounts']),
  prod('svc-p009', 'service', 'svc-office', 'Stationery & Ofisi', 'Receipt Book (50 pages Duplicate)', 'SVC-RCPT-50', 'book', 3000, 6000, ['receipt book', 'daftari la risiti', 'duplicate', 'invoicing']),
  prod('svc-p010', 'service', 'svc-office', 'Stationery & Ofisi', 'Invoice Book (50 pages Triplicate)', 'SVC-INV-50', 'book', 4000, 8000, ['invoice book', 'daftari la ankara', 'triplicate', 'billing']),
  prod('svc-p011', 'service', 'svc-printing', 'Printing & Uchapishaji', 'Printer Ink (Black, HP Compatible)', 'SVC-INK-BLK', 'cartridge', 15000, 30000, ['printer ink', 'wino wa printa', 'HP ink', 'black ink']),
  prod('svc-p012', 'service', 'svc-printing', 'Printing & Uchapishaji', 'Printer Ink (Colour, HP Compatible)', 'SVC-INK-COL', 'cartridge', 20000, 40000, ['colour ink', 'wino wa rangi', 'printer ink', 'colour printing']),
  prod('svc-p013', 'service', 'svc-printing', 'Printing & Uchapishaji', 'Toner Cartridge (Laser, Compatible)', 'SVC-TONER', 'cartridge', 60000, 100000, ['toner', 'laser printer', 'cartridge', 'printing']),
  prod('svc-p014', 'service', 'svc-security', 'Usalama & Ulinzi', 'CCTV Camera (Bullet, 2MP)', 'SVC-CCTV-2MP', 'pcs', 50000, 90000, ['CCTV', 'camera', 'surveillance', 'security camera', 'usalama']),
  prod('svc-p015', 'service', 'svc-security', 'Usalama & Ulinzi', 'Fire Extinguisher 2kg (Dry Powder)', 'SVC-FIRE-2KG', 'pcs', 45000, 80000, ['fire extinguisher', 'kizima moto', 'safety', 'fire safety']),
  prod('svc-p016', 'service', 'svc-security', 'Usalama & Ulinzi', 'Padlock (Heavy Duty 70mm)', 'SVC-LOCK-70', 'pcs', 15000, 30000, ['padlock', 'kufuli', 'security', 'lock', 'heavy duty']),
  prod('svc-p017', 'service', 'svc-cleaning', 'Usafi wa Ofisi', 'Trash Bags (Box of 50)', 'SVC-TRASH-50', 'box', 8000, 16000, ['trash bags', 'mifuko ya takataka', 'garbage bags', 'waste']),
  prod('svc-p018', 'service', 'svc-cleaning', 'Usafi wa Ofisi', 'Hand Sanitizer 500ml', 'SVC-SANIT-500', 'bottle', 6000, 12000, ['sanitizer', 'dawa ya mikono', 'hand sanitizer', 'hygiene']),
  prod('svc-p019', 'service', 'svc-branding', 'Branding & Marketing', 'Business Card Print (250 pcs)', 'SVC-BCARD-250', 'pack', 30000, 60000, ['business cards', 'kadi za biashara', 'branding', 'printing']),
  prod('svc-p020', 'service', 'svc-branding', 'Branding & Marketing', 'Rubber Stamp (Custom)', 'SVC-STAMP-CST', 'pcs', 15000, 35000, ['rubber stamp', 'muhuri', 'custom stamp', 'branding']),
  prod('svc-p021', 'service', 'svc-office', 'Stationery & Ofisi', 'Sticky Notes / Post-it (5 pads)', 'SVC-NOTE-5', 'pack', 5000, 12000, ['sticky notes', 'post-it', 'notes', 'reminder']),
  prod('svc-p022', 'service', 'svc-tech', 'Teknolojia & IT', 'USB Flash Drive 32GB', 'SVC-USB-32', 'pcs', 8000, 18000, ['flash drive', 'USB', 'memory', 'storage', 'data']),
  prod('svc-p023', 'service', 'svc-tech', 'Teknolojia & IT', 'Ethernet Cable Cat6 (5m)', 'SVC-ETH-5M', 'pcs', 8000, 18000, ['ethernet cable', 'network cable', 'LAN', 'internet', 'cat6']),
];

// ─────────────────────────────────────────────────────────────────────────────
// ASSEMBLE ALL DATA
// ─────────────────────────────────────────────────────────────────────────────

const allCategories = [
  ...pharmacyCategories,
  ...restaurantCategories,
  ...electronicsCategories,
  ...retailCategories,
  ...wholesaleCategories,
  ...salonCategories,
  ...hardwareCategories,
  ...agricultureCategories,
  ...tailoringCategories,
  ...transportCategories,
  ...constructionCategories,
  ...serviceCategories,
];

const allProducts = [
  ...pharmacyProducts,
  ...restaurantProducts,
  ...electronicsProducts,
  ...retailProducts,
  ...wholesaleProducts,
  ...salonProducts,
  ...hardwareProducts,
  ...agricultureProducts,
  ...tailoringProducts,
  ...transportProducts,
  ...constructionProducts,
  ...serviceProducts,
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  console.log('Mali Up — Master Catalog Seed Script');
  console.log('=====================================');
  console.log(`Categories to seed: ${allCategories.length}`);
  console.log(`Products to seed  : ${allProducts.length}`);
  console.log('');

  // Show breakdown
  const types = [
    'pharmacy', 'restaurant', 'electronics', 'retail', 'wholesale',
    'salon', 'hardware', 'agriculture', 'tailoring', 'transport',
    'construction', 'service',
  ];
  for (const t of types) {
    const c = allCategories.filter((x) => x.businessTypeId === t).length;
    const p = allProducts.filter((x) => x.businessTypeId === t).length;
    console.log(`  ${t.padEnd(14)} — ${c} categories, ${p} products`);
  }
  console.log('');

  console.log('Seeding master_categories...');
  await batchWrite('master_categories', allCategories);

  console.log('\nSeeding master_products...');
  await batchWrite('master_products', allProducts);

  console.log('\n✅ Seed complete!');
  console.log(`   ${allCategories.length} categories written`);
  console.log(`   ${allProducts.length} products written`);
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});
