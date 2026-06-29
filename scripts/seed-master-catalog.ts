'use strict';
import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

// ─── Firebase init ─────────────────────────────────────────────────────────
const SA_PATHS = [
  path.join(__dirname, 'serviceAccountKey.json'),
  path.join(__dirname, '../service-account.json'),
];
let sa: Record<string, unknown> | null = null;
for (const p of SA_PATHS) { if (fs.existsSync(p)) { sa = require(p); break; } }
if (!sa) { console.error('❌ No service account found.\n' + SA_PATHS.join('\n')); process.exit(1); }
admin.initializeApp({ credential: admin.credential.cert(sa as admin.ServiceAccount) });
const db = admin.firestore();

// ─── CLI flags ─────────────────────────────────────────────────────────────
const FORCE   = process.argv.includes('--force');
const DRY_RUN = process.argv.includes('--dry-run');
const BATCH_SIZE = 400;

// ─── Interfaces ────────────────────────────────────────────────────────────
interface MasterCategory {
  businessType: string; categoryName: string; categoryNameSw: string;
  categorySlug: string; icon: string; displayOrder: number;
}
interface MasterProduct {
  businessType: string; categorySlug: string;
  productName: string; productNameSw: string; genericName: string;
  brandNames: string[]; unit: string; unitAlternatives: string[];
  commonBarcodes: string[]; searchKeywords: string[];
  prescriptionRequired: boolean; coldStorage: boolean;
  tags: string[]; productSlug: string;
}

// ─── Helpers ───────────────────────────────────────────────────────────────
function slug(t: string): string {
  return t.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}
function cat(bt: string, name: string, sw: string, icon: string, order: number): MasterCategory {
  return { businessType: bt, categoryName: name, categoryNameSw: sw, categorySlug: slug(name), icon, displayOrder: order };
}
interface O { generic?: string; brands?: string[]; alt?: string[]; rx?: boolean; cold?: boolean; tags?: string[]; }
function prod(bt: string, cs: string, name: string, sw: string, unit: string, kw: string[], o: O = {}): MasterProduct {
  return {
    businessType: bt, categorySlug: cs, productName: name, productNameSw: sw,
    genericName: o.generic ?? '', brandNames: o.brands ?? [], unit,
    unitAlternatives: o.alt ?? [], commonBarcodes: [], searchKeywords: kw,
    prescriptionRequired: o.rx ?? false, coldStorage: o.cold ?? false,
    tags: o.tags ?? [], productSlug: slug(name),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// 1·2·3·4 — RETAIL / WHOLESALE / SUPERMARKET / GROCERY & CONVENIENCE
// ═══════════════════════════════════════════════════════════════════════════
const FMCG_BTS = ['Retail', 'Wholesale', 'Supermarket', 'Grocery & Convenience'];

function fmcgCats(bt: string): MasterCategory[] { return [
  cat(bt, 'Grains & Staples',       'Nafaka na Vyakula Vikuu',  'grain_dashboard',    0),
  cat(bt, 'Cooking Essentials',     'Vifaa vya Kupikia',        'soup_kitchen',       1),
  cat(bt, 'Dairy & Eggs',           'Maziwa na Mayai',          'egg_alt',            2),
  cat(bt, 'Beverages',              'Vinywaji',                 'local_drink',        3),
  cat(bt, 'Bread & Baked Goods',    'Mkate na Mikate',          'bakery_dining',      4),
  cat(bt, 'Cleaning Products',      'Bidhaa za Kusafisha',      'cleaning_services',  5),
  cat(bt, 'Personal Care',          'Bidhaa za Usafi Binafsi',  'spa',                6),
  cat(bt, 'Snacks & Confectionery', 'Vitafunio na Pipi',        'cookie',             7),
  cat(bt, 'Canned & Preserved',     'Vyakula vya Makopo',       'inventory_2',        8),
  cat(bt, 'Baby Products',          'Bidhaa za Watoto Wachanga','child_care',         9),
]; }

function fmcgProds(bt: string): MasterProduct[] { return [
  // Grains & Staples
  prod(bt,'grains-staples','Sugar 1kg','Sukari 1kg','Packet',['sukari','sugar','sukari kilo','chakula','1kg'],{brands:['Kilombero','Mtibwa'],tags:['common','fmcg']}),
  prod(bt,'grains-staples','Sugar 2kg','Sukari 2kg','Packet',['sukari','sugar','2kg','sukari rejareja'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Sugar 5kg','Sukari 5kg','Bag',['sukari','sugar','mfuko','5kg','bulk sugar'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Rice (Mwea Pishori) 1kg','Mchele wa Pishori 1kg','Packet',['mchele','pishori','wali','rice','mwea pishori'],{brands:['Mwea Pishori'],tags:['common','fmcg']}),
  prod(bt,'grains-staples','Rice (Mwea Pishori) 5kg','Mchele wa Pishori 5kg','Bag',['mchele pishori','rice 5kg','wali','pishori'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Rice (Sindano) 1kg','Mchele wa Sindano 1kg','Packet',['mchele sindano','sindano','rice','wali'],{tags:['common','fmcg']}),
  prod(bt,'grains-staples','Rice (Sindano) 5kg','Mchele wa Sindano 5kg','Bag',['mchele sindano','sindano 5kg','rice bag'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Wheat Flour 1kg','Unga wa Ngano 1kg','Packet',['unga ngano','wheat flour','mkate','baking','flour'],{brands:['Ajab','Starehe'],tags:['common','fmcg']}),
  prod(bt,'grains-staples','Wheat Flour 2kg','Unga wa Ngano 2kg','Packet',['unga ngano','wheat flour 2kg','flour'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Maize Flour (Sembe) 1kg','Unga wa Sembe 1kg','Packet',['sembe','unga wa mahindi','ugali flour','maize flour'],{brands:['Sembe'],tags:['common','fmcg']}),
  prod(bt,'grains-staples','Maize Flour (Sembe) 2kg','Unga wa Sembe 2kg','Packet',['sembe','ugali flour 2kg','unga mahindi'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Ugali Flour 1kg','Unga wa Ugali 1kg','Packet',['ugali','unga ugali','ugali flour'],{tags:['common','fmcg']}),
  prod(bt,'grains-staples','Red Kidney Beans 500g','Maharage Mekundu 500g','Packet',['maharage','beans','kidney beans','mikunde'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Green Grams 500g','Dengu 500g','Packet',['dengu','green grams','kunde','mikunde'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Lentils 500g','Dengu Nyekundu 500g','Packet',['dengu nyekundu','lentils','chakula'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Black-eyed Beans 500g','Kunde 500g','Packet',['kunde','black-eyed beans','mikunde'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Chickpeas 500g','Dengu za Kichina 500g','Packet',['chickpeas','garbanzo','dengu'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Soya Chunks 200g','Soya 200g','Packet',['soya','soya chunks','protein'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Rolled Oats 500g','Oats 500g','Packet',['oats','porridge','kiamsha kinywa','breakfast'],{tags:['fmcg']}),
  prod(bt,'grains-staples','Semolina 500g','Semolina 500g','Packet',['semolina','uji wa semolina','breakfast'],{tags:['fmcg']}),
  // Cooking Essentials
  prod(bt,'cooking-essentials','Cooking Oil 500ml','Mafuta ya Kupikia 500ml','Bottle',['mafuta','cooking oil','sunflower oil','500ml'],{brands:['Sunflower','Korie','Rina'],tags:['common','fmcg']}),
  prod(bt,'cooking-essentials','Cooking Oil 1L','Mafuta ya Kupikia 1L','Bottle',['mafuta','cooking oil','lita moja'],{brands:['Sunflower','Korie'],tags:['common','fmcg']}),
  prod(bt,'cooking-essentials','Cooking Oil 2L','Mafuta ya Kupikia 2L','Bottle',['mafuta','cooking oil','2L'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Cooking Oil 5L','Mafuta ya Kupikia 5L','Jerrycan',['mafuta jerrycan','cooking oil 5L'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Salt 500g','Chumvi 500g','Packet',['chumvi','salt','iodized salt'],{brands:['Mwambao','Tatua'],tags:['common','fmcg']}),
  prod(bt,'cooking-essentials','Salt 1kg','Chumvi 1kg','Packet',['chumvi','salt','chumvi kilo'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Tomato Paste 70g','Tomato Puree 70g','Tin',['tomato paste','nyanya','mboga','70g'],{brands:['Kibo','Tropical Sun'],tags:['common','fmcg']}),
  prod(bt,'cooking-essentials','Tomato Paste 400g','Tomato Puree 400g','Tin',['tomato paste','nyanya','400g'],{brands:['Kibo'],tags:['fmcg']}),
  prod(bt,'cooking-essentials','Coconut Milk 400ml','Maziwa ya Nazi 400ml','Tin',['nazi','coconut milk','pwani'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Mchuzi Mix 100g','Mchuzi Mix 100g','Packet',['mchuzi mix','royco','seasoning','viungo'],{brands:['Royco','Bongo'],tags:['common','fmcg']}),
  prod(bt,'cooking-essentials','Salt Iodized 250g','Chumvi ya Madini 250g','Packet',['chumvi','iodized','salt','madini'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Turmeric 50g','Manjano 50g','Packet',['manjano','turmeric','viungo'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Chili Powder 50g','Pilipili 50g','Packet',['pilipili','chili powder','spice'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Ginger Powder 50g','Tangawizi Unga 50g','Packet',['tangawizi','ginger','viungo'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Coriander Powder 50g','Bizari 50g','Packet',['bizari','coriander','viungo'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Baking Powder 100g','Hamira ya Unga 100g','Tin',['baking powder','hamira','kuoka'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Vinegar 500ml','Siki 500ml','Bottle',['siki','vinegar','viungo'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Soy Sauce 150ml','Mchuzi wa Soya 150ml','Bottle',['soy sauce','soya','seasoning'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Corn Starch 100g','Wanga wa Mahindi 100g','Packet',['corn starch','wanga','thickener'],{tags:['fmcg']}),
  prod(bt,'cooking-essentials','Mixed Spices 50g','Viungo Mchanganyiko 50g','Packet',['viungo','spices','bizari mchanganyiko'],{tags:['fmcg']}),
  // Dairy & Eggs
  prod(bt,'dairy-eggs','Fresh Milk 500ml (Brookside)','Maziwa Safi 500ml','Packet',['maziwa','milk','fresh milk','brookside','500ml'],{brands:['Brookside'],cold:true,tags:['common','fmcg']}),
  prod(bt,'dairy-eggs','Fresh Milk 1L (Brookside)','Maziwa Safi 1L','Packet',['maziwa','milk','brookside','1L'],{brands:['Brookside'],cold:true,tags:['common','fmcg']}),
  prod(bt,'dairy-eggs','Fresh Milk 500ml (Azam)','Maziwa Safi Azam 500ml','Packet',['maziwa','milk','azam'],{brands:['Azam'],cold:true,tags:['fmcg']}),
  prod(bt,'dairy-eggs','UHT Milk 200ml','Maziwa ya Tetra 200ml','Packet',['maziwa UHT','milk','tetra pak'],{tags:['fmcg']}),
  prod(bt,'dairy-eggs','UHT Milk 500ml','Maziwa ya Tetra 500ml','Packet',['maziwa UHT','milk','tetra pak 500ml'],{brands:['Brookside','Azam'],tags:['common','fmcg']}),
  prod(bt,'dairy-eggs','UHT Milk 1L','Maziwa ya Tetra 1L','Packet',['maziwa UHT','milk 1L','lita moja'],{tags:['fmcg']}),
  prod(bt,'dairy-eggs','Yoghurt Plain 500g','Yogati ya Kawaida 500g','Cup',['yoghurt','maziwa mgando','plain yoghurt'],{cold:true,tags:['fmcg']}),
  prod(bt,'dairy-eggs','Yoghurt Flavoured 200g','Yogati ya Matunda 200g','Cup',['yoghurt','maziwa mgando','flavoured'],{cold:true,tags:['fmcg']}),
  prod(bt,'dairy-eggs','Butter 250g','Siagi 250g','Block',['butter','siagi','baking','bread'],{brands:['Blueband','Cowboy'],cold:true,tags:['fmcg']}),
  prod(bt,'dairy-eggs','Margarine 250g (Blueband)','Siagi ya Blueband 250g','Tub',['margarine','siagi','blueband','bread'],{brands:['Blueband'],tags:['common','fmcg']}),
  prod(bt,'dairy-eggs','Margarine 500g','Siagi 500g','Tub',['margarine','siagi','500g'],{tags:['fmcg']}),
  prod(bt,'dairy-eggs','Cheese 200g','Jibini 200g','Pack',['cheese','jibini','dairy'],{cold:true,tags:['fmcg']}),
  prod(bt,'dairy-eggs','Eggs Tray (30)','Mayai Trei 30','Tray',['mayai','eggs','tray','kuku','30 eggs'],{cold:true,tags:['common','fmcg']}),
  prod(bt,'dairy-eggs','Eggs Half Tray (15)','Mayai Nusu Trei','Tray',['mayai','eggs','nusu tray','15 eggs'],{cold:true,tags:['fmcg']}),
  prod(bt,'dairy-eggs','Eggs Single','Yai Moja','Piece',['mayai','egg','yai moja','kuku'],{cold:true,tags:['fmcg']}),
  prod(bt,'dairy-eggs','Sour Milk (Lala) 500ml','Maziwa ya Lala 500ml','Packet',['lala','sour milk','maziwa ya lala','mtindi'],{cold:true,tags:['fmcg']}),
  prod(bt,'dairy-eggs','Cream 200ml','Krimu 200ml','Pack',['cream','krimu','whipping cream'],{cold:true,tags:['fmcg']}),
  // Beverages
  prod(bt,'beverages','Coca-Cola 300ml (bottle)','Koka-Kola 300ml','Bottle',['coca cola','coke','soda','kinywaji baridi','300ml'],{brands:['Coca-Cola'],tags:['common','fmcg']}),
  prod(bt,'beverages','Coca-Cola 500ml','Koka-Kola 500ml','Bottle',['coca cola','coke','soda','500ml'],{brands:['Coca-Cola'],tags:['fmcg']}),
  prod(bt,'beverages','Coca-Cola 1L','Koka-Kola 1L','Bottle',['coca cola','soda','1L'],{brands:['Coca-Cola'],tags:['fmcg']}),
  prod(bt,'beverages','Pepsi 300ml','Pepsi 300ml','Bottle',['pepsi','soda','kinywaji'],{brands:['Pepsi'],tags:['fmcg']}),
  prod(bt,'beverages','Sprite 300ml','Sprite 300ml','Bottle',['sprite','soda','lemon soda'],{brands:['Sprite'],tags:['fmcg']}),
  prod(bt,'beverages','Fanta Orange 300ml','Fanta Chungwa 300ml','Bottle',['fanta','orange soda','chungwa soda'],{brands:['Fanta'],tags:['common','fmcg']}),
  prod(bt,'beverages','Fanta Pineapple 300ml','Fanta Nanasi 300ml','Bottle',['fanta','pineapple soda','nanasi'],{brands:['Fanta'],tags:['fmcg']}),
  prod(bt,'beverages','Water 500ml (Kilimanjaro)','Maji Kilimanjaro 500ml','Bottle',['maji','water','kilimanjaro','mineral water'],{brands:['Kilimanjaro'],tags:['common','fmcg']}),
  prod(bt,'beverages','Water 1L (Kilimanjaro)','Maji Kilimanjaro 1L','Bottle',['maji','water','kilimanjaro','1L'],{brands:['Kilimanjaro'],tags:['fmcg']}),
  prod(bt,'beverages','Water 5L','Maji 5L','Bottle',['maji','water','5L','galoni'],{tags:['fmcg']}),
  prod(bt,'beverages','Juice Mango 300ml','Juisi ya Embe 300ml','Pack',['juice','juisi','embe','mango juice'],{tags:['fmcg']}),
  prod(bt,'beverages','Juice Passion 300ml','Juisi ya Passionfruit 300ml','Pack',['juice','passion fruit','juisi'],{tags:['fmcg']}),
  prod(bt,'beverages','Energy Drink (Redbull) 250ml','Kinywaji cha Nguvu Redbull 250ml','Can',['redbull','energy drink','nguvu'],{brands:['Red Bull'],tags:['fmcg']}),
  prod(bt,'beverages','Tea (Ketepa) 25 bags','Chai Ketepa Vibebeo 25','Box',['chai','tea','ketepa','tea bags'],{brands:['Ketepa'],tags:['common','fmcg']}),
  prod(bt,'beverages','Coffee 50g','Kahawa 50g','Pack',['kahawa','coffee','instant coffee'],{tags:['fmcg']}),
  prod(bt,'beverages','Malt Drink (Milo) 200g','Milo 200g','Tin',['milo','malt drink','kakao','chocolate drink'],{brands:['Milo'],tags:['fmcg']}),
  prod(bt,'beverages','Tangawizi Drink 300ml','Kinywaji cha Tangawizi 300ml','Bottle',['tangawizi','ginger drink','soda'],{tags:['fmcg']}),
  prod(bt,'beverages','Cocoa Powder 200g','Poda ya Kakao 200g','Pack',['cocoa','kakao','chocolate','drinking cocoa'],{tags:['fmcg']}),
  // Bread & Baked Goods
  prod(bt,'bread-baked-goods','White Bread (sliced)','Mkate Mweupe wa Kata','Loaf',['mkate','bread','white bread','sliced bread'],{tags:['common','fmcg']}),
  prod(bt,'bread-baked-goods','Brown Bread (sliced)','Mkate wa Nafaka wa Kata','Loaf',['mkate','brown bread','whole wheat','nafaka'],{tags:['fmcg']}),
  prod(bt,'bread-baked-goods','Whole Wheat Bread','Mkate wa Ngano Nzima','Loaf',['whole wheat bread','mkate wa ngano','healthy bread'],{tags:['fmcg']}),
  prod(bt,'bread-baked-goods','Dinner Rolls 6-pack','Mikate Midogo 6-pack','Pack',['rolls','mikate midogo','buns','dinner rolls'],{tags:['fmcg']}),
  prod(bt,'bread-baked-goods','Buns 4-pack','Bani 4-pack','Pack',['bani','buns','mkate'],{tags:['common','fmcg']}),
  prod(bt,'bread-baked-goods','Chapati (ready-made) 3-pack','Chapati ya Tayari 3-pack','Pack',['chapati','mkate','ready chapati'],{tags:['fmcg']}),
  prod(bt,'bread-baked-goods','Mandazi 4-pack','Maandazi 4-pack','Pack',['mandazi','maandazi','vitafunio'],{tags:['common','fmcg']}),
  prod(bt,'bread-baked-goods','Biscuits (Digestive) 200g','Biskuti za Digestive 200g','Pack',['biskuti','biscuits','digestive','vitafunio'],{brands:['McVities'],tags:['fmcg']}),
  prod(bt,'bread-baked-goods','Biscuits (Cream) 200g','Biskuti za Krimu 200g','Pack',['biskuti','cream biscuits','vitafunio'],{tags:['fmcg']}),
  prod(bt,'bread-baked-goods','Swiss Roll 300g','Swiss Roll 300g','Pack',['swiss roll','cake roll','vitafunio'],{tags:['fmcg']}),
  prod(bt,'bread-baked-goods','Doughnuts 2-pack','Donati 2-pack','Pack',['donati','doughnuts','vitafunio'],{tags:['fmcg']}),
  prod(bt,'bread-baked-goods','Cookies 150g','Kuki 150g','Pack',['cookies','kuki','vitafunio','biskuti'],{tags:['fmcg']}),
  // Cleaning Products
  prod(bt,'cleaning-products','Detergent (Omo) 500g','Unga wa Kufulia Omo 500g','Packet',['omo','detergent','unga wa kufulia','washing powder'],{brands:['Omo'],tags:['common','fmcg']}),
  prod(bt,'cleaning-products','Detergent (Ariel) 500g','Unga wa Kufulia Ariel 500g','Packet',['ariel','detergent','washing powder'],{brands:['Ariel'],tags:['fmcg']}),
  prod(bt,'cleaning-products','Detergent 1kg','Unga wa Kufulia 1kg','Packet',['detergent','unga kufulia','1kg','washing'],{tags:['fmcg']}),
  prod(bt,'cleaning-products','Washing Bar Soap (Msafi) 800g','Sabuni ya Kufulia Msafi 800g','Bar',['sabuni','bar soap','washing soap','msafi'],{brands:['Msafi','Sunlight'],tags:['common','fmcg']}),
  prod(bt,'cleaning-products','Bleach 500ml','Blechi 500ml','Bottle',['bleach','blechi','safisha','disinfect'],{tags:['fmcg']}),
  prod(bt,'cleaning-products','Bleach 1L','Blechi 1L','Bottle',['bleach','blechi','disinfect','1L'],{tags:['fmcg']}),
  prod(bt,'cleaning-products','Dishwashing Liquid 500ml','Sabuni ya Vyombo 500ml','Bottle',['dishwashing','sabuni ya vyombo','sunlight','fairy'],{brands:['Sunlight','Fairy'],tags:['common','fmcg']}),
  prod(bt,'cleaning-products','Floor Cleaner 500ml','Dawa ya Sakafu 500ml','Bottle',['floor cleaner','dawa ya sakafu','usafi'],{tags:['fmcg']}),
  prod(bt,'cleaning-products','Toilet Cleaner 500ml','Dawa ya Choo 500ml','Bottle',['toilet cleaner','dawa ya choo','harpic','bathroom'],{brands:['Harpic'],tags:['fmcg']}),
  prod(bt,'cleaning-products','Air Freshener Spray 300ml','Dawa ya Harufu 300ml','Can',['air freshener','harufu','spray','glade'],{brands:['Glade'],tags:['fmcg']}),
  prod(bt,'cleaning-products','Fabric Softener 500ml','Laini ya Nguo 500ml','Bottle',['fabric softener','laini','comfort'],{brands:['Comfort'],tags:['fmcg']}),
  prod(bt,'cleaning-products','Scrubbing Brush','Burashi ya Kusugua','Piece',['brush','burashi','kusugua','cleaning tool'],{tags:['fmcg']}),
  prod(bt,'cleaning-products','Mop Head','Mfagilio wa Mvua','Piece',['mop','mfagilio','cleaning','floor'],{tags:['fmcg']}),
  prod(bt,'cleaning-products','Broom (Ufagio)','Ufagio','Piece',['ufagio','broom','fagia','kusafisha'],{tags:['common','fmcg']}),
  prod(bt,'cleaning-products','Toilet Blocks 2-pack','Vipande vya Choo 2-pack','Pack',['toilet block','dawa ya choo','cistern'],{tags:['fmcg']}),
  // Personal Care
  prod(bt,'personal-care','Toothpaste (Colgate) 100ml','Dawa ya Meno Colgate 100ml','Tube',['toothpaste','dawa ya meno','colgate','meno'],{brands:['Colgate'],tags:['common','fmcg']}),
  prod(bt,'personal-care','Toothpaste (Signal) 100ml','Dawa ya Meno Signal 100ml','Tube',['toothpaste','dawa ya meno','signal'],{brands:['Signal'],tags:['fmcg']}),
  prod(bt,'personal-care','Toothbrush (Oral-B)','Mswaki wa Oral-B','Piece',['mswaki','toothbrush','oral-b','meno'],{brands:['Oral-B'],tags:['common','fmcg']}),
  prod(bt,'personal-care','Shampoo (Head & Shoulders) 200ml','Shampoo ya Head & Shoulders 200ml','Bottle',['shampoo','nywele','head shoulders'],{brands:['Head & Shoulders'],tags:['fmcg']}),
  prod(bt,'personal-care','Body Lotion (Vaseline) 200ml','Krimu ya Mwili Vaseline 200ml','Bottle',['vaseline','body lotion','krimu ya mwili'],{brands:['Vaseline'],tags:['common','fmcg']}),
  prod(bt,'personal-care','Petroleum Jelly (Vaseline) 250g','Vaseline 250g','Tub',['vaseline','petroleum jelly','ngozi'],{brands:['Vaseline'],tags:['fmcg']}),
  prod(bt,'personal-care','Bathing Soap (Lux) 100g','Sabuni ya Mwili Lux 100g','Bar',['sabuni','lux','bathing soap','kuoga'],{brands:['Lux'],tags:['common','fmcg']}),
  prod(bt,'personal-care','Bathing Soap (Dove) 100g','Sabuni ya Mwili Dove 100g','Bar',['sabuni','dove','bathing soap'],{brands:['Dove'],tags:['fmcg']}),
  prod(bt,'personal-care','Deodorant Spray 150ml','Dawa ya Jasho 150ml','Can',['deodorant','dawa ya jasho','spray','axe'],{brands:['Axe','Sure'],tags:['fmcg']}),
  prod(bt,'personal-care','Roll-On Deodorant 50ml','Roll-On 50ml','Bottle',['roll-on','deodorant','jasho'],{tags:['fmcg']}),
  prod(bt,'personal-care','Sanitary Pads (Always) 8-pack','Pedi za Usafi 8-pack','Pack',['pedi','sanitary pads','always','hedhi','female hygiene'],{brands:['Always'],tags:['common','fmcg']}),
  prod(bt,'personal-care','Razor (Gillette) 2-pack','Wembe wa Gillette 2-pack','Pack',['razor','wembe','gillette','shaving'],{brands:['Gillette'],tags:['fmcg']}),
  prod(bt,'personal-care','Shaving Cream 100g','Krimu ya Kunyoa 100g','Tube',['shaving cream','krimu ya kunyoa','shave'],{tags:['fmcg']}),
  prod(bt,'personal-care','Nail Cutter','Mkato wa Kucha','Piece',['nail cutter','mkato wa kucha','kucha'],{tags:['fmcg']}),
  prod(bt,'personal-care','Cotton Wool 100g','Pamba 100g','Pack',['cotton wool','pamba','medical','hygiene'],{tags:['fmcg']}),
  prod(bt,'personal-care','Conditioner 200ml','Laini ya Nywele 200ml','Bottle',['conditioner','nywele','hair conditioner'],{tags:['fmcg']}),
  // Snacks & Confectionery
  prod(bt,'snacks-confectionery','Crisps (Pringles) 40g','Pringles 40g','Can',['pringles','crisps','vitafunio','chips'],{brands:['Pringles'],tags:['fmcg']}),
  prod(bt,'snacks-confectionery','Peanuts Roasted 200g','Karanga za Kukaanga 200g','Packet',['karanga','peanuts','roasted','vitafunio'],{tags:['common','fmcg']}),
  prod(bt,'snacks-confectionery','Popcorn 100g','Bisi la Kuchemsha 100g','Packet',['popcorn','bisi','vitafunio','snack'],{tags:['fmcg']}),
  prod(bt,'snacks-confectionery','Chocolate (Dairy Milk) 40g','Chokoleti 40g','Bar',['chocolate','chokoleti','dairy milk','cadbury'],{brands:['Cadbury'],tags:['fmcg']}),
  prod(bt,'snacks-confectionery','Candy Mix 200g','Peremende Mchanganyiko 200g','Packet',['peremende','candy','sweets','pipi'],{tags:['fmcg']}),
  prod(bt,'snacks-confectionery','Chewing Gum (Extra) 5-pack','Gamu 5-pack','Pack',['gamu','chewing gum','extra','spearmint'],{brands:['Extra'],tags:['fmcg']}),
  prod(bt,'snacks-confectionery','Lollipops 10-pack','Pipi za Stiki 10-pack','Pack',['lollipop','pipi','stiki','vitafunio'],{tags:['fmcg']}),
  prod(bt,'snacks-confectionery','Sesame Bar (Simsim) 50g','Mkate wa Simsim 50g','Bar',['simsim','sesame bar','vitafunio','local snack'],{tags:['common','fmcg']}),
  prod(bt,'snacks-confectionery','Groundnut Bar 50g','Mkate wa Karanga 50g','Bar',['groundnut bar','karanga','vitafunio'],{tags:['fmcg']}),
  prod(bt,'snacks-confectionery','Bongo Candy (local)','Peremende za Bongo','Pack',['bongo candy','peremende','local sweets'],{tags:['fmcg']}),
  prod(bt,'snacks-confectionery','Cheetos 50g','Cheetos 50g','Pack',['cheetos','crisps','vitafunio'],{brands:['Cheetos'],tags:['fmcg']}),
  // Canned & Preserved
  prod(bt,'canned-preserved','Canned Tomatoes 400g','Nyanya za Makopo 400g','Tin',['nyanya makopo','canned tomatoes','tinned tomatoes'],{tags:['common','fmcg']}),
  prod(bt,'canned-preserved','Sardines in Oil (Titus) 125g','Sardini ya Mafuta 125g','Tin',['sardines','titus','samaki ya makopo','fish'],{brands:['Titus'],tags:['common','fmcg']}),
  prod(bt,'canned-preserved','Sardines in Tomato (Lucky Star) 155g','Sardini ya Nyanya 155g','Tin',['sardines','lucky star','samaki makopo'],{brands:['Lucky Star'],tags:['fmcg']}),
  prod(bt,'canned-preserved','Corned Beef 200g','Nyama ya Ng\'ombe ya Makopo 200g','Tin',['corned beef','nyama makopo','bull brand'],{brands:['Bull Brand'],tags:['fmcg']}),
  prod(bt,'canned-preserved','Tuna in Water 170g','Tuna ya Maji 170g','Tin',['tuna','samaki','tuna fish','canned fish'],{tags:['fmcg']}),
  prod(bt,'canned-preserved','Canned Beans 400g','Maharage ya Makopo 400g','Tin',['maharage makopo','canned beans','beans'],{tags:['fmcg']}),
  prod(bt,'canned-preserved','Jam (Strawberry) 375g','Jamu ya Jordani 375g','Jar',['jam','jamu','strawberry','bread spread'],{tags:['fmcg']}),
  prod(bt,'canned-preserved','Honey 250g','Asali 250g','Jar',['asali','honey','natural honey'],{tags:['fmcg']}),
  prod(bt,'canned-preserved','Peanut Butter (smooth) 400g','Siagi ya Karanga Laini 400g','Jar',['peanut butter','siagi ya karanga','karanga'],{tags:['common','fmcg']}),
  prod(bt,'canned-preserved','Peanut Butter (crunchy) 400g','Siagi ya Karanga 400g','Jar',['peanut butter','crunchy','siagi ya karanga'],{tags:['fmcg']}),
  prod(bt,'canned-preserved','Nutella 200g','Nutella 200g','Jar',['nutella','chocolate spread','hazelnut'],{brands:['Nutella'],tags:['fmcg']}),
  prod(bt,'canned-preserved','Canned Peas 400g','Mbaazi za Makopo 400g','Tin',['peas','mbaazi makopo','canned peas'],{tags:['fmcg']}),
  // Baby Products
  prod(bt,'baby-products','Pampers Diapers Small (12-pack)','Nepi za Pampers S 12-pack','Pack',['nepi','pampers','diapers','small','mtoto'],{brands:['Pampers'],tags:['common','fmcg']}),
  prod(bt,'baby-products','Pampers Diapers Medium (10-pack)','Nepi za Pampers M 10-pack','Pack',['nepi','pampers','diapers','medium'],{brands:['Pampers'],tags:['fmcg']}),
  prod(bt,'baby-products','Huggies Diapers L (10-pack)','Nepi za Huggies L 10-pack','Pack',['nepi','huggies','diapers','large'],{brands:['Huggies'],tags:['fmcg']}),
  prod(bt,'baby-products','Baby Wipes 80-pack','Vitambaa vya Mtoto 80-pack','Pack',['baby wipes','vitambaa vya mtoto','wipes'],{tags:['fmcg']}),
  prod(bt,'baby-products','Baby Powder 200g','Poda ya Mtoto 200g','Bottle',['baby powder','poda ya mtoto','johnson'],{brands:["Johnson's"],tags:['fmcg']}),
  prod(bt,'baby-products','Baby Lotion 200ml','Krimu ya Mtoto 200ml','Bottle',['baby lotion','krimu ya mtoto','johnson'],{brands:["Johnson's"],tags:['fmcg']}),
  prod(bt,'baby-products','Baby Soap 75g','Sabuni ya Mtoto 75g','Bar',['baby soap','sabuni ya mtoto'],{tags:['fmcg']}),
  prod(bt,'baby-products','Baby Shampoo 200ml','Shampoo ya Mtoto 200ml','Bottle',['baby shampoo','nywele za mtoto'],{tags:['fmcg']}),
  prod(bt,'baby-products','Baby Oil 200ml','Mafuta ya Mtoto 200ml','Bottle',['baby oil','mafuta ya mtoto','massage'],{tags:['fmcg']}),
  prod(bt,'baby-products','Gripe Water 150ml','Dawa ya Tumbo la Mtoto 150ml','Bottle',['gripe water','tumbo la mtoto','woodwards'],{brands:["Woodward's"],tags:['fmcg']}),
  prod(bt,'baby-products','Cerelac Wheat 400g','Uji wa Cerelac 400g','Tin',['cerelac','baby food','uji wa mtoto','wheat'],{brands:['Nestlé Cerelac'],tags:['fmcg']}),
  prod(bt,'baby-products','NAN Formula 400g','Maziwa ya Mtoto NAN 400g','Tin',['nan','baby formula','maziwa ya mtoto','infant formula'],{brands:['NAN'],tags:['fmcg']}),
]; }

// Generate for all 4 FMCG business types
const fmcgCategories: MasterCategory[] = FMCG_BTS.flatMap(bt => fmcgCats(bt));
const fmcgProducts:   MasterProduct[]  = FMCG_BTS.flatMap(bt => fmcgProds(bt));

// ═══════════════════════════════════════════════════════════════════════════
// 5 — ELECTRONICS & MOBILE PHONES
// ═══════════════════════════════════════════════════════════════════════════
const BT5 = 'Electronics & Mobile Phones';
const electronicsCategories: MasterCategory[] = [
  cat(BT5,'Mobile Phones',         'Simu za Mkononi',      'smartphone',       0),
  cat(BT5,'Phone Accessories',     'Vifaa vya Simu',       'cable',            1),
  cat(BT5,'Computers & Laptops',   'Kompyuta na Laptop',   'laptop_mac',       2),
  cat(BT5,'Computer Accessories',  'Vifaa vya Kompyuta',   'mouse',            3),
  cat(BT5,'Audio & Sound',         'Sauti na Muziki',      'headphones',       4),
  cat(BT5,'TV & Entertainment',    'Televisheni na Burudani','tv',             5),
  cat(BT5,'Networking',            'Mtandao',              'wifi',             6),
  cat(BT5,'Solar & Power',         'Jua na Umeme',         'solar_power',      7),
  cat(BT5,'Small Electronics',     'Vifaa Vidogo vya Umeme','electrical_services',8),
];
const electronicsProducts: MasterProduct[] = [
  prod(BT5,'mobile-phones','Samsung Galaxy A05','Samsung Galaxy A05','Piece',['samsung','galaxy a05','android','simu','smartphone']),
  prod(BT5,'mobile-phones','Samsung Galaxy A15','Samsung Galaxy A15','Piece',['samsung','galaxy a15','android','simu']),
  prod(BT5,'mobile-phones','Samsung Galaxy A35','Samsung Galaxy A35','Piece',['samsung','galaxy a35','samsung a35','simu']),
  prod(BT5,'mobile-phones','Tecno Spark 20','Tecno Spark 20','Piece',['tecno','spark 20','android','simu']),
  prod(BT5,'mobile-phones','Tecno Pop 8','Tecno Pop 8','Piece',['tecno','pop 8','budget phone','simu']),
  prod(BT5,'mobile-phones','Infinix Hot 40','Infinix Hot 40','Piece',['infinix','hot 40','android','simu']),
  prod(BT5,'mobile-phones','Infinix Note 40','Infinix Note 40','Piece',['infinix','note 40','simu'],{tags:['common']}),
  prod(BT5,'mobile-phones','itel A70','itel A70','Piece',['itel','a70','budget phone','simu']),
  prod(BT5,'mobile-phones','itel P40','itel P40','Piece',['itel','p40','android','simu']),
  prod(BT5,'mobile-phones','iPhone 14','iPhone 14','Piece',['iphone','iphone 14','apple','smartphone'],{brands:['Apple'],tags:['common']}),
  prod(BT5,'mobile-phones','iPhone 15','iPhone 15','Piece',['iphone','iphone 15','apple'],{brands:['Apple']}),
  prod(BT5,'mobile-phones','Redmi 13C','Redmi 13C','Piece',['redmi','xiaomi','13c','android'],{brands:['Xiaomi']}),
  prod(BT5,'mobile-phones','Redmi Note 13','Redmi Note 13','Piece',['redmi note','xiaomi','note 13'],{brands:['Xiaomi']}),
  prod(BT5,'mobile-phones','Nokia C32','Nokia C32','Piece',['nokia','c32','android','simu'],{brands:['Nokia']}),
  prod(BT5,'mobile-phones','Nokia G22','Nokia G22','Piece',['nokia','g22','android'],{brands:['Nokia']}),
  prod(BT5,'phone-accessories','USB-C Cable 1m','Kebo ya USB-C 1m','Piece',['usb-c cable','kebo','charger cable','charging']),
  prod(BT5,'phone-accessories','USB-C Cable 2m','Kebo ya USB-C 2m','Piece',['usb-c','cable','kebo 2m']),
  prod(BT5,'phone-accessories','Micro-USB Cable 1m','Kebo ya Micro-USB 1m','Piece',['micro usb','kebo','android cable','charging']),
  prod(BT5,'phone-accessories','Lightning Cable 1m','Kebo ya iPhone 1m','Piece',['lightning cable','iphone cable','apple kebo']),
  prod(BT5,'phone-accessories','Phone Charger 33W','Chaja ya Simu 33W','Piece',['charger','chaja','fast charger','33w']),
  prod(BT5,'phone-accessories','Phone Charger 65W','Chaja ya Simu 65W','Piece',['charger','chaja','65w fast charger']),
  prod(BT5,'phone-accessories','Power Bank 10000mAh','Power Bank 10000mAh','Piece',['power bank','betri ya akiba','10000mah'],{tags:['common']}),
  prod(BT5,'phone-accessories','Power Bank 20000mAh','Power Bank 20000mAh','Piece',['power bank','betri ya akiba','20000mah']),
  prod(BT5,'phone-accessories','Screen Protector Tempered Glass','Kinga ya Skrini','Piece',['screen protector','kinga ya skrini','tempered glass']),
  prod(BT5,'phone-accessories','Phone Case Universal','Kifuniko cha Simu','Piece',['phone case','kifuniko','cover','kinga ya simu']),
  prod(BT5,'phone-accessories','Memory Card 32GB','Kadi ya Kumbukumbu 32GB','Piece',['memory card','sd card','32gb','kumbukumbu']),
  prod(BT5,'phone-accessories','Memory Card 64GB','Kadi ya Kumbukumbu 64GB','Piece',['memory card','64gb','sd card'],{tags:['common']}),
  prod(BT5,'phone-accessories','Memory Card 128GB','Kadi ya Kumbukumbu 128GB','Piece',['memory card','128gb','sd card']),
  prod(BT5,'phone-accessories','USB Flash Drive 32GB','Flash Disk 32GB','Piece',['flash drive','usb','32gb','storage']),
  prod(BT5,'phone-accessories','Selfie Stick','Fimbo ya Selfie','Piece',['selfie stick','tripod','picha','selfie']),
  prod(BT5,'phone-accessories','Phone Holder (car)','Kishikilia Simu cha Gari','Piece',['phone holder','car mount','gari','simu']),
  prod(BT5,'phone-accessories','OTG Adapter USB-C','OTG Adapta USB-C','Piece',['otg','adapter','usb-c','on the go']),
  prod(BT5,'computers-laptops','HP Laptop 15" i5','Laptop ya HP 15" i5','Piece',['laptop','hp','i5','kompyuta'],{brands:['HP'],tags:['common']}),
  prod(BT5,'computers-laptops','Dell Laptop 15" i5','Laptop ya Dell 15" i5','Piece',['laptop','dell','i5','kompyuta'],{brands:['Dell']}),
  prod(BT5,'computers-laptops','Lenovo IdeaPad i5','Lenovo IdeaPad i5','Piece',['lenovo','ideapad','laptop','i5'],{brands:['Lenovo']}),
  prod(BT5,'computers-laptops','Toshiba Laptop i3','Laptop ya Toshiba i3','Piece',['toshiba','laptop','i3'],{brands:['Toshiba']}),
  prod(BT5,'computers-laptops','HP Desktop i5','Desktop ya HP i5','Piece',['hp','desktop','kompyuta ya mezani'],{brands:['HP']}),
  prod(BT5,'computers-laptops','External Hard Drive 1TB','Hifadhi ya Nje 1TB','Piece',['hard drive','external hdd','1tb','storage'],{tags:['common']}),
  prod(BT5,'computers-laptops','SSD 256GB','SSD 256GB','Piece',['ssd','solid state drive','256gb','storage']),
  prod(BT5,'computer-accessories','Keyboard USB','Kibodi ya USB','Piece',['keyboard','kibodi','usb','kompyuta']),
  prod(BT5,'computer-accessories','Wireless Keyboard','Kibodi ya Wireless','Piece',['wireless keyboard','kibodi','bluetooth']),
  prod(BT5,'computer-accessories','Mouse USB','Panya ya USB','Piece',['mouse','panya','usb','kompyuta'],{tags:['common']}),
  prod(BT5,'computer-accessories','Wireless Mouse','Panya ya Wireless','Piece',['wireless mouse','panya','bluetooth']),
  prod(BT5,'computer-accessories','Laptop Bag 15"','Mfuko wa Laptop 15"','Piece',['laptop bag','mfuko wa laptop','backpack']),
  prod(BT5,'computer-accessories','Laptop Stand','Msimamo wa Laptop','Piece',['laptop stand','msimamo','cooling stand']),
  prod(BT5,'computer-accessories','USB Hub 4-port','USB Hub 4-port','Piece',['usb hub','hub','4 port','usb splitter']),
  prod(BT5,'audio-sound','Earphones (wired)','Vipokea Sauti vya Waya','Pair',['earphones','headphones','masikio','wired']),
  prod(BT5,'audio-sound','Earbuds Wireless TWS','Vipokea Sauti vya Bluetooth','Pair',['earbuds','tws','bluetooth','wireless earphones'],{tags:['common']}),
  prod(BT5,'audio-sound','Bluetooth Speaker small','Spika Ndogo ya Bluetooth','Piece',['bluetooth speaker','spika','wireless speaker','portable']),
  prod(BT5,'audio-sound','Bluetooth Speaker large','Spika Kubwa ya Bluetooth','Piece',['bluetooth speaker','spika kubwa','woofer','wireless']),
  prod(BT5,'audio-sound','Headphones (over-ear)','Vipokea Sauti Vikubwa','Piece',['headphones','over ear','masikio makubwa'],{tags:['common']}),
  prod(BT5,'audio-sound','Woofer (home)','Spika ya Nyumbani','Piece',['woofer','home speaker','spika ya nyumbani']),
  prod(BT5,'audio-sound','Car Stereo','Radio ya Gari','Piece',['car stereo','radio ya gari','car audio']),
  prod(BT5,'audio-sound','Microphone (dynamic)','Maikrofoni','Piece',['microphone','maikrofoni','mic','recording']),
  prod(BT5,'audio-sound','HDMI Cable 1.5m','Kebo ya HDMI 1.5m','Piece',['hdmi cable','kebo ya tv','hdmi','monitor']),
  prod(BT5,'tv-entertainment','Smart TV 32"','Televisheni Smart 32"','Piece',['smart tv','tv','televisheni','32 inch'],{tags:['common']}),
  prod(BT5,'tv-entertainment','Smart TV 43"','Televisheni Smart 43"','Piece',['smart tv','43 inch','televisheni']),
  prod(BT5,'tv-entertainment','Smart TV 55"','Televisheni Smart 55"','Piece',['smart tv','55 inch','televisheni']),
  prod(BT5,'tv-entertainment','DSTV Decoder + dish','DSTV Decoder na Kisahani','Set',['dstv','decoder','satellite tv','dish'],{brands:['DSTV'],tags:['common']}),
  prod(BT5,'tv-entertainment','OpenView Decoder','OpenView Decoder','Piece',['openview','decoder','free to air']),
  prod(BT5,'tv-entertainment','Digital TV Antenna','Antena ya TV','Piece',['antenna','antena','tv aerial','digital tv']),
  prod(BT5,'tv-entertainment','Universal Remote Control','Remokon ya Kawaida','Piece',['remote control','remokon','universal remote']),
  prod(BT5,'tv-entertainment','DVD Player','DVD Player','Piece',['dvd player','dvd','movie player']),
  prod(BT5,'tv-entertainment','Projector','Projekta','Piece',['projector','projekta','presentation']),
  prod(BT5,'networking','WiFi Router (TP-Link)','Ruta ya WiFi TP-Link','Piece',['wifi router','ruta','internet','tp-link'],{brands:['TP-Link'],tags:['common']}),
  prod(BT5,'networking','WiFi Router (Huawei)','Ruta ya WiFi Huawei','Piece',['wifi router','huawei','internet'],{brands:['Huawei']}),
  prod(BT5,'networking','WiFi Modem 4G','Modemu ya 4G','Piece',['4g modem','wifi modem','internet','airtel vodacom']),
  prod(BT5,'networking','LAN Cable Cat6 per metre','Kebo ya LAN Cat6 kwa Mita','Metre',['lan cable','ethernet','cat6','network cable']),
  prod(BT5,'networking','Network Switch 8-port','Swichi ya Mtandao 8-port','Piece',['network switch','switch','8 port','lan']),
  prod(BT5,'networking','WiFi Extender','Kipanua WiFi','Piece',['wifi extender','booster','wifi range']),
  prod(BT5,'solar-power','Solar Panel 50W','Paneli ya Jua 50W','Piece',['solar panel','jua','50w','umeme wa jua']),
  prod(BT5,'solar-power','Solar Panel 100W','Paneli ya Jua 100W','Piece',['solar panel','100w','jua','solar'],{tags:['common']}),
  prod(BT5,'solar-power','Solar Panel 200W','Paneli ya Jua 200W','Piece',['solar panel','200w','jua']),
  prod(BT5,'solar-power','Solar Battery 100AH','Betri ya Jua 100AH','Piece',['solar battery','betri','100ah','deep cycle']),
  prod(BT5,'solar-power','Solar Controller 20A','Kidhibiti cha Jua 20A','Piece',['solar controller','charge controller','20a','solar']),
  prod(BT5,'solar-power','Solar Inverter 1000W','Invata ya Jua 1000W','Piece',['inverter','invata','1000w','solar inverter']),
  prod(BT5,'solar-power','Solar Inverter 2000W','Invata ya Jua 2000W','Piece',['inverter','2000w','solar'],{tags:['common']}),
  prod(BT5,'solar-power','Solar Lantern','Taa ya Jua','Piece',['solar lantern','taa ya jua','solar light']),
  prod(BT5,'solar-power','Solar Street Light','Taa ya Barabara ya Jua','Piece',['solar street light','street light','outdoor solar']),
  prod(BT5,'small-electronics','LED Bulb 9W','Balbu ya LED 9W','Piece',['led bulb','balbu','9w','umeme','energy saving'],{tags:['common']}),
  prod(BT5,'small-electronics','LED Bulb 18W','Balbu ya LED 18W','Piece',['led bulb','balbu','18w','fluorescent replacement']),
  prod(BT5,'small-electronics','Extension Cord 5m','Kamba ya Extension 5m','Piece',['extension cord','kamba ya umeme','power strip','5m']),
  prod(BT5,'small-electronics','Extension Cord 3m','Kamba ya Extension 3m','Piece',['extension cord','3m','power strip']),
  prod(BT5,'small-electronics','AA Batteries (pack/4)','Betri AA 4-pack','Pack',['batteries','betri','aa','alkaline'],{brands:['Energizer','Duracell']}),
  prod(BT5,'small-electronics','AAA Batteries (pack/4)','Betri AAA 4-pack','Pack',['batteries','betri','aaa','alkaline']),
  prod(BT5,'small-electronics','Electric Kettle 1.5L','Kitetele cha Umeme 1.5L','Piece',['kettle','kitetele','boil water','umeme']),
  prod(BT5,'small-electronics','Electric Iron','Pasi ya Umeme','Piece',['iron','pasi','clothes iron','umeme'],{tags:['common']}),
  prod(BT5,'small-electronics','Fan (table)','Feni ya Meza','Piece',['fan','feni','cooling','air circulation']),
  prod(BT5,'small-electronics','Torch/Flashlight','Tochi','Piece',['torch','tochi','flashlight','light']),
];

// ═══════════════════════════════════════════════════════════════════════════
// 6 — FASHION & BOUTIQUE
// ═══════════════════════════════════════════════════════════════════════════
const BT6 = 'Fashion & Boutique';
const fashionCategories: MasterCategory[] = [
  cat(BT6,'Mens Clothing',   'Mavazi ya Wanaume',  'man',          0),
  cat(BT6,'Womens Clothing', 'Mavazi ya Wanawake', 'woman',        1),
  cat(BT6,'Childrens Clothing','Mavazi ya Watoto', 'child_care',   2),
  cat(BT6,'Footwear',        'Viatu',              'footprint',    3),
  cat(BT6,'Bags & Accessories','Mifuko na Vifaa',  'luggage',      4),
  cat(BT6,'Undergarments',   'Nguo za Ndani',      'dry_cleaning', 5),
  cat(BT6,'Sportswear',      'Mavazi ya Michezo',  'sports_soccer',6),
];
const fashionProducts: MasterProduct[] = [
  prod(BT6,'mens-clothing','T-shirt (plain)','Shati la Kawaida','Piece',['tshirt','shati','plain','mavazi ya wanaume'],{tags:['common']}),
  prod(BT6,'mens-clothing','T-shirt (printed)','Shati la Picha','Piece',['tshirt printed','shati la picha','graphic tee']),
  prod(BT6,'mens-clothing','Polo Shirt','Polo Shati','Piece',['polo shirt','polo','formal casual','mavazi'],{tags:['common']}),
  prod(BT6,'mens-clothing','Dress Shirt (formal)','Shati la Rasmi','Piece',['dress shirt','shati rasmi','formal','office']),
  prod(BT6,'mens-clothing','Casual Shirt','Shati la Starehe','Piece',['casual shirt','shati','mavazi']),
  prod(BT6,'mens-clothing','Jeans (slim fit)','Suruali ya Jeans Finyu','Piece',['jeans','slim fit','suruali','denim'],{tags:['common']}),
  prod(BT6,'mens-clothing','Jeans (regular)','Suruali ya Jeans Kawaida','Piece',['jeans','regular fit','suruali']),
  prod(BT6,'mens-clothing','Khaki Trousers','Suruali ya Khaki','Piece',['khaki','suruali','trousers','office wear']),
  prod(BT6,'mens-clothing','Shorts (casual)','Suruali Fupi ya Starehe','Piece',['shorts','suruali fupi','casual']),
  prod(BT6,'mens-clothing','Suit Jacket','Jaketi ya Suti','Piece',['suit jacket','suti','jaketi','formal'],{tags:['common']}),
  prod(BT6,'mens-clothing','Blazer','Blazer','Piece',['blazer','jaketi','formal','office']),
  prod(BT6,'mens-clothing','Sweater','Sweta','Piece',['sweater','sweta','baridi','knitwear']),
  prod(BT6,'mens-clothing','Hoodie','Huvudi','Piece',['hoodie','huvudi','casual','comfort']),
  prod(BT6,'mens-clothing','Jacket (denim)','Jaketi ya Denim','Piece',['jacket','denim jacket','jaketi']),
  prod(BT6,'mens-clothing','Belt (leather)','Mkanda wa Ngozi','Piece',['belt','mkanda','ngozi','fashion']),
  prod(BT6,'mens-clothing','Kofia ya Kitenge','Kofia ya Kitenge','Piece',['kofia','kitenge cap','african hat']),
  prod(BT6,'mens-clothing','Cap (baseball)','Kofia ya Baseball','Piece',['cap','kofia','baseball cap'],{tags:['common']}),
  prod(BT6,'womens-clothing','Dress (casual)','Gauni la Starehe','Piece',['dress','gauni','casual','wanawake'],{tags:['common']}),
  prod(BT6,'womens-clothing','Dress (formal)','Gauni la Rasmi','Piece',['formal dress','gauni rasmi','party dress']),
  prod(BT6,'womens-clothing','Dress (Kitenge)','Gauni la Kitenge','Piece',['kitenge dress','gauni la kitenge','african dress'],{tags:['common']}),
  prod(BT6,'womens-clothing','Blouse (plain)','Blauzi ya Kawaida','Piece',['blouse','blauzi','top','wanawake']),
  prod(BT6,'womens-clothing','Blouse (printed)','Blauzi ya Picha','Piece',['blouse','printed','blauzi']),
  prod(BT6,'womens-clothing','Skirt (midi)','Sketi ya Urefu wa Kati','Piece',['skirt','sketi','midi','wanawake']),
  prod(BT6,'womens-clothing','Skirt (maxi)','Sketi Ndefu','Piece',['maxi skirt','sketi ndefu','long skirt']),
  prod(BT6,'womens-clothing','Trousers (ladies)','Suruali ya Wanawake','Piece',['trousers','suruali','ladies pants']),
  prod(BT6,'womens-clothing','Jeans (ladies slim)','Jeans za Wanawake','Piece',['jeans','ladies jeans','suruali'],{tags:['common']}),
  prod(BT6,'womens-clothing','Jumpsuit','Vazi la Mwili Wote','Piece',['jumpsuit','romper','wanawake']),
  prod(BT6,'womens-clothing','Abaya','Abaya','Piece',['abaya','bui bui','wanawake wa kiislamu'],{tags:['common']}),
  prod(BT6,'womens-clothing','Hijab','Hijab','Piece',['hijab','hijabu','headscarf','uislamu'],{tags:['common']}),
  prod(BT6,'womens-clothing','Kanga (pair)','Kanga Jozi','Pair',['kanga','leso','kanga pair','mavazi ya asili'],{tags:['common']}),
  prod(BT6,'womens-clothing','Kitenge (2 yards)','Kitenge (Yadi 2)','Yards',['kitenge','african print','2 yards'],{tags:['common']}),
  prod(BT6,'womens-clothing','Leggings','Suruali ya Kubana','Piece',['leggings','suruali ya kubana','yoga pants']),
  prod(BT6,'womens-clothing','Cardigan','Kadigan','Piece',['cardigan','kadigan','knitwear','baridi']),
  prod(BT6,'womens-clothing','Handbag (ladies)','Mkoba wa Wanawake','Piece',['handbag','mkoba','ladies bag'],{tags:['common']}),
  prod(BT6,'childrens-clothing','Baby Onesie 0-3mo','Nguo ya Mtoto 0-3 miezi','Piece',['onesie','baby clothes','nguo ya mtoto','infant'],{tags:['common']}),
  prod(BT6,'childrens-clothing','Baby Onesie 3-6mo','Nguo ya Mtoto 3-6 miezi','Piece',['onesie','baby','nguo ya mtoto']),
  prod(BT6,'childrens-clothing','Baby Onesie 6-12mo','Nguo ya Mtoto 6-12 miezi','Piece',['onesie','nguo ya mtoto','infant']),
  prod(BT6,'childrens-clothing','Kids T-shirt age 2-4','Shati la Mtoto miaka 2-4','Piece',['kids tshirt','shati la mtoto','watoto'],{tags:['common']}),
  prod(BT6,'childrens-clothing','Kids T-shirt age 5-8','Shati la Mtoto miaka 5-8','Piece',['kids tshirt','shati','watoto']),
  prod(BT6,'childrens-clothing','Kids Dress girls 3-5','Gauni la Msichana miaka 3-5','Piece',['girls dress','gauni watoto','msichana']),
  prod(BT6,'childrens-clothing','School Uniform (shirt)','Sare ya Shule (Shati)','Piece',['school uniform','sare','shule'],{tags:['common']}),
  prod(BT6,'childrens-clothing','School Uniform (trousers)','Sare ya Shule (Suruali)','Piece',['school uniform','sare','suruali ya shule']),
  prod(BT6,'childrens-clothing','School Uniform (skirt)','Sare ya Shule (Sketi)','Piece',['school uniform','sketi ya shule','sare']),
  prod(BT6,'footwear','Mens Leather Shoes','Viatu vya Ngozi vya Wanaume','Pair',['leather shoes','viatu vya ngozi','formal shoes'],{tags:['common']}),
  prod(BT6,'footwear','Mens Casual Shoes','Viatu vya Starehe vya Wanaume','Pair',['casual shoes','viatu','sneakers','wanaume']),
  prod(BT6,'footwear','Mens Sandals','Viatu vya Pwani vya Wanaume','Pair',['sandals','viatu vya pwani','wanaume']),
  prod(BT6,'footwear','Womens Heels','Viatu vya Visigino','Pair',['heels','visigino','ladies shoes','formal'],{tags:['common']}),
  prod(BT6,'footwear','Womens Flat Shoes','Viatu Vifupi vya Wanawake','Pair',['flat shoes','viatu vifupi','ladies flats']),
  prod(BT6,'footwear','Womens Sandals','Viatu vya Pwani vya Wanawake','Pair',['sandals','viatu vya pwani','wanawake']),
  prod(BT6,'footwear','Sneakers (mens)','Viatu vya Michezo vya Wanaume','Pair',['sneakers','trainers','viatu vya michezo'],{tags:['common']}),
  prod(BT6,'footwear','Sneakers (womens)','Viatu vya Michezo vya Wanawake','Pair',['sneakers','trainers ladies','viatu']),
  prod(BT6,'footwear','School Shoes (childrens)','Viatu vya Shule','Pair',['school shoes','viatu vya shule','watoto'],{tags:['common']}),
  prod(BT6,'footwear','Rain Boots','Buti za Mvua','Pair',['rain boots','buti','mvua','rubber boots']),
  prod(BT6,'footwear','Mens Slippers','Slipa za Wanaume','Pair',['slippers','slipa','wanaume','bathroom'],{tags:['common']}),
  prod(BT6,'bags-accessories','Ladies Handbag','Mkoba wa Wanawake','Piece',['handbag','mkoba','ladies','fashion'],{tags:['common']}),
  prod(BT6,'bags-accessories','Ladies Clutch','Mfuko Mdogo wa Wanawake','Piece',['clutch','purse','mfuko mdogo']),
  prod(BT6,'bags-accessories','Backpack (school)','Mfuko wa Mgongoni wa Shule','Piece',['backpack','mfuko wa mgongoni','school bag'],{tags:['common']}),
  prod(BT6,'bags-accessories','Backpack (travel)','Mfuko wa Safari','Piece',['travel backpack','safari bag','travel']),
  prod(BT6,'bags-accessories','Laptop Bag','Mfuko wa Laptop','Piece',['laptop bag','office bag','mfuko wa ofisi']),
  prod(BT6,'bags-accessories','Suitcase (small)','Sanduku la Safari Dogo','Piece',['suitcase','sanduku la safari','luggage'],{tags:['common']}),
  prod(BT6,'bags-accessories','Suitcase (large)','Sanduku la Safari Kubwa','Piece',['suitcase','luggage','sanduku']),
  prod(BT6,'bags-accessories','Wallet (mens leather)','Mkoba wa Wanaume wa Ngozi','Piece',['wallet','mkoba','wanaume','leather wallet']),
  prod(BT6,'bags-accessories','Wallet (ladies)','Mkoba Mdogo wa Wanawake','Piece',['wallet','purse','mkoba wa wanawake']),
  prod(BT6,'undergarments','Mens Underwear (briefs)','Chupi ya Wanaume','Piece',['underwear','chupi','briefs','wanaume'],{tags:['common']}),
  prod(BT6,'undergarments','Mens Boxer Shorts','Boksa ya Wanaume','Piece',['boxer','boksa','underwear','wanaume']),
  prod(BT6,'undergarments','Ladies Underwear','Chupi ya Wanawake','Piece',['underwear','chupi','ladies','wanawake'],{tags:['common']}),
  prod(BT6,'undergarments','Ladies Bra','Sidiria ya Wanawake','Piece',['bra','sidiria','wanawake'],{tags:['common']}),
  prod(BT6,'undergarments','Vest (mens)','Ganjali la Wanaume','Piece',['vest','ganjali','singlet','wanaume']),
  prod(BT6,'undergarments','Socks (pair)','Soksi (jozi)','Pair',['socks','soksi','ankle socks'],{tags:['common']}),
  prod(BT6,'undergarments','Kids Underwear','Chupi ya Watoto','Piece',['kids underwear','chupi ya watoto','children']),
  prod(BT6,'sportswear','Sports T-shirt','Shati la Michezo','Piece',['sports shirt','jersey','michezo'],{tags:['common']}),
  prod(BT6,'sportswear','Shorts (sports)','Suruali Fupi ya Michezo','Piece',['sports shorts','suruali ya michezo','gym']),
  prod(BT6,'sportswear','Tracksuit (2-piece)','Suti ya Michezo','Set',['tracksuit','suti ya michezo','jogger'],{tags:['common']}),
  prod(BT6,'sportswear','Sports Shoes','Viatu vya Michezo','Pair',['sports shoes','running shoes','michezo']),
  prod(BT6,'sportswear','Football Jersey','Jezi ya Mpira','Piece',['football jersey','jezi','soccer','mpira'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 7 — TAILORING & TEXTILES
// ═══════════════════════════════════════════════════════════════════════════
const BT7 = 'Tailoring & Textiles';
const tailoringCategories: MasterCategory[] = [
  cat(BT7,'Fabrics',             'Vitambaa',            'texture',      0),
  cat(BT7,'Sewing Accessories',  'Vifaa vya Kushona',   'cut',          1),
  cat(BT7,'Lining & Interfacing','Vitambaa vya Ndani',  'layers',       2),
];
const tailoringProducts: MasterProduct[] = [
  prod(BT7,'fabrics','Kitenge (per yard)','Kitenge (kwa Yadi)','Yard',['kitenge','ankara','african print','fabric'],{tags:['common']}),
  prod(BT7,'fabrics','Ankara (per yard)','Ankara (kwa Yadi)','Yard',['ankara','kitenge','wax print','fabric'],{tags:['common']}),
  prod(BT7,'fabrics','Lace Fabric (per yard)','Lesi (kwa Yadi)','Yard',['lace','lesi','bridal fabric']),
  prod(BT7,'fabrics','Plain Cotton (per yard)','Pamba Safi (kwa Yadi)','Yard',['cotton','pamba','plain cotton'],{tags:['common']}),
  prod(BT7,'fabrics','Satin (per yard)','Satin (kwa Yadi)','Yard',['satin','vitambaa','formal wear']),
  prod(BT7,'fabrics','Chiffon (per yard)','Shiffoni (kwa Yadi)','Yard',['chiffon','shiffoni','lightweight fabric']),
  prod(BT7,'fabrics','Denim Fabric (per yard)','Denim (kwa Yadi)','Yard',['denim','jeans fabric','suruali']),
  prod(BT7,'fabrics','Polyester (per yard)','Polyesta (kwa Yadi)','Yard',['polyester','polyesta','synthetic']),
  prod(BT7,'fabrics','Wool Fabric (per yard)','Sufu (kwa Yadi)','Yard',['wool','sufu','baridi','winter fabric']),
  prod(BT7,'fabrics','Silk (per yard)','Hariri (kwa Yadi)','Yard',['silk','hariri','luxury fabric']),
  prod(BT7,'fabrics','Linen (per yard)','Kitani (kwa Yadi)','Yard',['linen','kitani','summer fabric']),
  prod(BT7,'fabrics','Canvas (per yard)','Kamba Nzito (kwa Yadi)','Yard',['canvas','heavy fabric','bags material']),
  prod(BT7,'fabrics','Brocade (per yard)','Brokedi (kwa Yadi)','Yard',['brocade','brokedi','special occasion']),
  prod(BT7,'fabrics','Velvet (per yard)','Velveti (kwa Yadi)','Yard',['velvet','velveti','soft fabric']),
  prod(BT7,'sewing-accessories','Thread (cotton, per reel)','Uzi wa Pamba (rili moja)','Reel',['thread','uzi','cotton thread','sewing'],{tags:['common']}),
  prod(BT7,'sewing-accessories','Thread (polyester, per reel)','Uzi wa Polyesta (rili moja)','Reel',['thread','uzi','polyester thread']),
  prod(BT7,'sewing-accessories','Zipper 20cm','Zipu ya 20cm','Piece',['zipper','zipu','zip','kushona'],{tags:['common']}),
  prod(BT7,'sewing-accessories','Zipper 30cm','Zipu ya 30cm','Piece',['zipper','zipu','30cm']),
  prod(BT7,'sewing-accessories','Buttons (dozen)','Vifungo (dazeni)','Dozen',['buttons','vifungo','dozen','sewing'],{tags:['common']}),
  prod(BT7,'sewing-accessories','Elastic Band 1m','Mkanda wa Mpira 1m','Metre',['elastic','mpira','elastic band','waistband']),
  prod(BT7,'sewing-accessories','Sewing Needle (pack)','Sindano za Kushona (pakiti)','Pack',['sindano','needles','sewing needles']),
  prod(BT7,'sewing-accessories','Pins (box)','Pini (sanduku)','Box',['pins','pini','safety pins','dressmaker pins']),
  prod(BT7,'sewing-accessories','Measuring Tape','Mkanda wa Kupima','Piece',['measuring tape','mkanda wa kupima','tape measure']),
  prod(BT7,'sewing-accessories','Scissors (fabric)','Mkasi wa Vitambaa','Piece',['scissors','mkasi','fabric scissors'],{tags:['common']}),
  prod(BT7,'sewing-accessories','Seam Ripper','Kibunji cha Uzi','Piece',['seam ripper','kifaa cha kushona','remove stitches']),
  prod(BT7,'sewing-accessories','Velcro Strip 1m','Velcro 1m','Metre',['velcro','strip','kushona']),
  prod(BT7,'sewing-accessories','Bias Tape (per metre)','Tepi ya Mpaka (kwa Mita)','Metre',['bias tape','tepi','binding']),
  prod(BT7,'sewing-accessories','Shoulder Pads (pair)','Mabega ya Kushona (jozi)','Pair',['shoulder pads','mabega','sewing notions']),
  prod(BT7,'lining-interfacing','Iron-on Interfacing (per yard)','Kinga ya Ndani (kwa Yadi)','Yard',['interfacing','fusible web','stiffener','collar'],{tags:['common']}),
  prod(BT7,'lining-interfacing','Lining Fabric (per yard)','Kitambaa cha Ndani (kwa Yadi)','Yard',['lining','kitambaa cha ndani','inner fabric'],{tags:['common']}),
  prod(BT7,'lining-interfacing','Woven Interfacing (per yard)','Kinga ya Kushona (kwa Yadi)','Yard',['woven interfacing','stiffener','collar','cuffs']),
  prod(BT7,'lining-interfacing','Felt Fabric (per yard)','Filisi (kwa Yadi)','Yard',['felt','filisi','craft fabric']),
  prod(BT7,'lining-interfacing','Wadding/Batting (per metre)','Pamba ya Kujaza (kwa Mita)','Metre',['wadding','batting','quilting','padding']),
];

// ═══════════════════════════════════════════════════════════════════════════
// 8 — BEAUTY & COSMETICS
// ═══════════════════════════════════════════════════════════════════════════
const BT8 = 'Beauty & Cosmetics';
const beautyCategories: MasterCategory[] = [
  cat(BT8,'Skincare',       'Utunzaji wa Ngozi',     'face',        0),
  cat(BT8,'Hair Care',      'Utunzaji wa Nywele',    'content_cut', 1),
  cat(BT8,'Makeup',         'Mapambo ya Uso',        'brush',       2),
  cat(BT8,'Fragrances',     'Manukato',              'air_freshener',3),
  cat(BT8,'Nail Care',      'Utunzaji wa Kucha',     'spa',         4),
];
const beautyProducts: MasterProduct[] = [
  prod(BT8,'skincare','Face Cream (Nivea) 50ml','Krimu ya Uso Nivea 50ml','Jar',['face cream','krimu ya uso','nivea','moisturiser'],{brands:['Nivea'],tags:['common']}),
  prod(BT8,'skincare','Face Cream (Ponds) 50ml','Krimu ya Uso Ponds 50ml','Jar',['face cream','krimu ya uso','ponds'],{brands:["Pond's"]}),
  prod(BT8,'skincare','Body Lotion (Vaseline) 400ml','Krimu ya Mwili Vaseline 400ml','Bottle',['body lotion','krimu ya mwili','vaseline'],{brands:['Vaseline'],tags:['common']}),
  prod(BT8,'skincare','Sunscreen SPF50 50ml','Dawa ya Jua SPF50 50ml','Tube',['sunscreen','dawa ya jua','spf50','sun protection']),
  prod(BT8,'skincare','Face Wash 100ml','Sabuni ya Uso 100ml','Tube',['face wash','sabuni ya uso','cleanser'],{brands:['Clean & Clear']}),
  prod(BT8,'skincare','Toner 150ml','Tona ya Uso 150ml','Bottle',['toner','tona','face toner','skincare']),
  prod(BT8,'skincare','Serum (Vitamin C) 30ml','Seramu ya Vitamini C 30ml','Bottle',['serum','vitamin c','seramu','brightening']),
  prod(BT8,'skincare','Aloe Vera Gel 200ml','Jeli ya Aloe Vera 200ml','Bottle',['aloe vera','jeli','natural skincare']),
  prod(BT8,'skincare','Kojic Acid Soap','Sabuni ya Kojic','Bar',['kojic','kojic soap','skin lightening','sabuni'],{tags:['common']}),
  prod(BT8,'skincare','Fair & Lovely Cream 50g','Krimu ya Kuangaza Ngozi 50g','Tube',['fair and lovely','krimu','skin cream','moisturiser'],{brands:['Fair & Lovely'],tags:['common']}),
  prod(BT8,'skincare','Whitening Lotion 200ml','Losho ya Kuangaza 200ml','Bottle',['whitening lotion','losho','skin care','lightening']),
  prod(BT8,'skincare','Eye Cream 15ml','Krimu ya Macho 15ml','Tube',['eye cream','macho','dark circles','skincare']),
  prod(BT8,'hair-care','Shampoo (TRESemmé) 400ml','Shampoo ya TRESemmé 400ml','Bottle',['shampoo','nywele','tresemme','hair wash'],{brands:['TRESemmé'],tags:['common']}),
  prod(BT8,'hair-care','Conditioner (TRESemmé) 400ml','Laini ya Nywele TRESemmé 400ml','Bottle',['conditioner','nywele','tresemme'],{brands:['TRESemmé']}),
  prod(BT8,'hair-care','Hair Oil (Dabur Amla) 200ml','Mafuta ya Nywele Amla 200ml','Bottle',['hair oil','mafuta ya nywele','amla','dabur'],{brands:['Dabur Amla']}),
  prod(BT8,'hair-care','Coconut Oil 200ml','Mafuta ya Nazi 200ml','Bottle',['coconut oil','mafuta ya nazi','nywele'],{tags:['common']}),
  prod(BT8,'hair-care','Castor Oil 100ml','Mafuta ya Msumbiji 100ml','Bottle',['castor oil','mafuta ya msumbiji','hair growth']),
  prod(BT8,'hair-care','Hair Relaxer (Dark & Lovely)','Laini ya Nywele','Box',['relaxer','dark and lovely','nywele laini'],{brands:['Dark & Lovely'],tags:['common']}),
  prod(BT8,'hair-care','Hair Dye (black)','Rangi ya Nywele Nyeusi','Box',['hair dye','rangi ya nywele','black dye'],{tags:['common']}),
  prod(BT8,'hair-care','Hair Dye (brown)','Rangi ya Nywele Kahawia','Box',['hair dye','rangi ya nywele','brown']),
  prod(BT8,'hair-care','Hair Wax 150g','Wax ya Nywele 150g','Jar',['hair wax','wax ya nywele','styling']),
  prod(BT8,'hair-care','Hair Gel 250ml','Jeli ya Nywele 250ml','Jar',['hair gel','jeli ya nywele','styling'],{tags:['common']}),
  prod(BT8,'hair-care','Edge Control 100g','Kidhibiti cha Nywele 100g','Jar',['edge control','baby hair','edges','nywele']),
  prod(BT8,'hair-care','Hair Extensions (pack)','Nywele Bandia (pakiti)','Pack',['hair extensions','nywele bandia','extension'],{tags:['common']}),
  prod(BT8,'hair-care','Braiding Hair (pack)','Nywele za Kusuka (pakiti)','Pack',['braiding hair','nywele za kusuka','braid'],{tags:['common']}),
  prod(BT8,'hair-care','Wig (lace front)','Wigi wa Lace','Piece',['wig','wigi','lace front','nywele']),
  prod(BT8,'makeup','Foundation','Msingi wa Uso','Bottle',['foundation','msingi','makeup','uso'],{tags:['common']}),
  prod(BT8,'makeup','Concealer','Kificha','Stick',['concealer','kificha','makeup','cover up']),
  prod(BT8,'makeup','Powder (compact)','Poda ya Uso','Compact',['powder','poda','compact','makeup'],{tags:['common']}),
  prod(BT8,'makeup','Eyeshadow Palette','Rangi za Jicho','Palette',['eyeshadow','rangi za macho','palette'],{tags:['common']}),
  prod(BT8,'makeup','Eyeliner (pencil)','Kalamu ya Jicho','Pencil',['eyeliner','liner','macho','makeup']),
  prod(BT8,'makeup','Mascara','Mascara','Tube',['mascara','nywele za macho','lashes','makeup'],{tags:['common']}),
  prod(BT8,'makeup','Lipstick (red)','Lipistiki Nyekundu','Bullet',['lipstick','lipistiki','mdomo','red lips'],{tags:['common']}),
  prod(BT8,'makeup','Lipstick (nude)','Lipistiki ya Asili','Bullet',['lipstick','nude','mdomo','makeup']),
  prod(BT8,'makeup','Lip Gloss','Glos ya Midomo','Tube',['lip gloss','glos','mdomo','shine']),
  prod(BT8,'makeup','Makeup Brush Set','Seti ya Brashi za Mapambo','Set',['makeup brushes','brashi za makeup','set']),
  prod(BT8,'makeup','Makeup Remover wipes 25-pack','Vitambaa vya Kuondoa Mapambo','Pack',['makeup remover','kuondoa makeup','wipes']),
  prod(BT8,'makeup','Setting Spray','Spray ya Kumaliza Mapambo','Bottle',['setting spray','makeup fixer','spray']),
  prod(BT8,'fragrances','Perfume (ladies) 50ml','Manukato ya Wanawake 50ml','Bottle',['perfume','manukato','ladies perfume'],{tags:['common']}),
  prod(BT8,'fragrances','Perfume (mens) 50ml','Manukato ya Wanaume 50ml','Bottle',['perfume','manukato','mens cologne'],{tags:['common']}),
  prod(BT8,'fragrances','Body Mist 200ml','Maji ya Mwili 200ml','Bottle',['body mist','body spray','manukato']),
  prod(BT8,'fragrances','Deodorant Body Spray (Axe) 150ml','Dawa ya Jasho Axe 150ml','Can',['axe','deodorant spray','body spray','jasho'],{brands:['Axe']}),
  prod(BT8,'fragrances','Oud Perfume Oil 10ml','Mafuta ya Oud 10ml','Bottle',['oud','oud oil','arabic perfume','manukato'],{tags:['common']}),
  prod(BT8,'fragrances','Attar 6ml','Attar 6ml','Bottle',['attar','itar','arabic scent','manukato']),
  prod(BT8,'nail-care','Nail Polish (assorted colors)','Rangi ya Kucha','Bottle',['nail polish','rangi ya kucha','manicure'],{tags:['common']}),
  prod(BT8,'nail-care','Nail Polish Remover 100ml','Kiondoa Rangi cha Kucha 100ml','Bottle',['nail remover','acetone','kucha'],{tags:['common']}),
  prod(BT8,'nail-care','Nail File','Faili ya Kucha','Piece',['nail file','faili ya kucha','manicure']),
  prod(BT8,'nail-care','Nail Cutter','Mkato wa Kucha','Piece',['nail cutter','mkato wa kucha','trim']),
  prod(BT8,'nail-care','Cuticle Pusher','Kikanda cha Kucha','Piece',['cuticle pusher','manicure tool','kucha']),
  prod(BT8,'nail-care','Acrylic Nail Set','Seti ya Acrylic Nail','Set',['acrylic nails','fake nails','gel nails','kucha'],{tags:['common']}),
  prod(BT8,'nail-care','Gel Nail Polish','Jeli ya Rangi ya Kucha','Bottle',['gel polish','nail gel','UV gel','kucha']),
  prod(BT8,'nail-care','Base Coat','Rangi ya Msingi ya Kucha','Bottle',['base coat','nail primer','manicure']),
];

// ═══════════════════════════════════════════════════════════════════════════
// 9 — SALON & BARBER
// ═══════════════════════════════════════════════════════════════════════════
const BT9 = 'Salon & Barber';
const salonCategories: MasterCategory[] = [
  cat(BT9,'Hair Products',          'Bidhaa za Nywele',           'content_cut',0),
  cat(BT9,'Cutting & Styling Tools','Vifaa vya Kukata na Kupamba','cut',         1),
  cat(BT9,'Salon Supplies',         'Vifaa vya Saluni',           'spa',         2),
  cat(BT9,'Skincare (Salon)',        'Utunzaji wa Ngozi',          'face',        3),
];
const salonProducts: MasterProduct[] = [
  prod(BT9,'hair-products','Hair Relaxer','Laini ya Nywele','Box',['relaxer','nywele laini','dark and lovely','cream'],{brands:['Dark & Lovely','ORS'],tags:['common']}),
  prod(BT9,'hair-products','Shampoo (salon size) 1L','Shampoo ya Saluni 1L','Bottle',['shampoo','salon shampoo','1L'],{tags:['common']}),
  prod(BT9,'hair-products','Conditioner (salon size) 1L','Laini ya Nywele ya Saluni 1L','Bottle',['conditioner','salon conditioner']),
  prod(BT9,'hair-products','Hair Dye (black)','Rangi ya Nywele Nyeusi','Box',['rangi','hair dye','black','wella'],{brands:['Wella','Revlon'],tags:['common']}),
  prod(BT9,'hair-products','Hair Dye (brown)','Rangi ya Nywele Kahawia','Box',['rangi','brown dye','nywele']),
  prod(BT9,'hair-products','Hair Bleach Powder 100g','Poda ya Kubleach Nywele','Pack',['bleach','hair bleach','lighten','nywele'],{tags:['common']}),
  prod(BT9,'hair-products','Hair Wax 250g','Wax ya Nywele 250g','Jar',['wax','hair wax','styling']),
  prod(BT9,'hair-products','Hair Gel 1kg','Jeli ya Nywele 1kg','Jar',['gel','hair gel','jeli','styling']),
  prod(BT9,'hair-products','Edge Control 100g','Kidhibiti cha Nywele','Jar',['edge control','baby hair','edges']),
  prod(BT9,'hair-products','Hair Extensions (pack)','Nywele Bandia (pakiti)','Pack',['hair extensions','nywele bandia','weave'],{tags:['common']}),
  prod(BT9,'hair-products','Braiding Hair (pack)','Nywele za Kusuka','Pack',['braiding hair','nywele za kusuka','braid'],{tags:['common']}),
  prod(BT9,'hair-products','Wig (lace front)','Wigi wa Lace','Piece',['wig','wigi','lace front']),
  prod(BT9,'hair-products','Hair Oil Coconut 200ml','Mafuta ya Nazi ya Nywele 200ml','Bottle',['coconut oil','mafuta ya nazi','nywele'],{tags:['common']}),
  prod(BT9,'hair-products','Castor Oil 100ml','Mafuta ya Msumbiji 100ml','Bottle',['castor oil','hair growth','nywele']),
  prod(BT9,'cutting-styling-tools','Hair Clippers (professional)','Mashine ya Kunyoa (ya Kitaalamu)','Piece',['clippers','mashine ya kunyoa','barber','professional'],{brands:['Wahl','Andis'],tags:['common']}),
  prod(BT9,'cutting-styling-tools','Hair Clipper Blades','Vipande vya Mashine ya Kunyoa','Piece',['clipper blades','vipande','replacement blades']),
  prod(BT9,'cutting-styling-tools','Scissors (barber)','Mkasi wa Kinyozi','Piece',['scissors','mkasi','barber scissors','hair cutting'],{tags:['common']}),
  prod(BT9,'cutting-styling-tools','Razor Blade (Gillette) 10-pack','Wembe wa Gillette 10-pack','Pack',['razor','wembe','gillette','shaving'],{brands:['Gillette']}),
  prod(BT9,'cutting-styling-tools','Comb (fine tooth)','Kitana cha Meno Mabwegere','Piece',['comb','kitana','fine tooth','hair']),
  prod(BT9,'cutting-styling-tools','Brush (paddle)','Brashi ya Nywele','Piece',['brush','brashi','paddle brush','detangle']),
  prod(BT9,'cutting-styling-tools','Hair Dryer 1000W','Kausha Nywele 1000W','Piece',['hair dryer','kausha nywele','blow dryer'],{tags:['common']}),
  prod(BT9,'cutting-styling-tools','Flat Iron (hair straightener)','Nyooshaji wa Nywele','Piece',['flat iron','straightener','nywele nyofu'],{tags:['common']}),
  prod(BT9,'cutting-styling-tools','Curling Iron','Zingatifu ya Nywele','Piece',['curling iron','curler','nywele za mviringo']),
  prod(BT9,'salon-supplies','Shaving Brush','Brashi ya Kunyoa','Piece',['shaving brush','brashi ya kunyoa','barber']),
  prod(BT9,'salon-supplies','Neck Strip (roll)','Ukanda wa Shingo (roli)','Roll',['neck strip','shingo','barber supply','salon'],{tags:['common']}),
  prod(BT9,'salon-supplies','Cape (barber/salon)','Vazi la Saluni','Piece',['cape','vazi la saluni','barber cape','apron'],{tags:['common']}),
  prod(BT9,'salon-supplies','Towels (salon pack)','Taulo za Saluni (pakiti)','Pack',['towels','taulo','salon supply']),
  prod(BT9,'salon-supplies','Salon Chair','Kiti cha Saluni','Piece',['salon chair','kiti','barber chair']),
  prod(BT9,'salon-supplies','Hair Clips (pack)','Vibanio vya Nywele (pakiti)','Pack',['hair clips','vibanio','sectioning clips']),
  prod(BT9,'salon-supplies','Foil Sheets (pack)','Foil ya Rangi (pakiti)','Pack',['foil','highlight foil','hair color']),
  prod(BT9,'salon-supplies','Mixing Bowl & Brush Set','Seti ya Bakuli na Brashi ya Rangi','Set',['mixing bowl','color bowl','hair dye']),
  prod(BT9,'skincare-salon','Face Cream (lightening) 100ml','Krimu ya Kuangaza Uso 100ml','Jar',['face cream','lightening','mwangaza','skincare'],{tags:['common']}),
  prod(BT9,'skincare-salon','Body Lotion 400ml','Losho ya Mwili 400ml','Bottle',['body lotion','losho','mwili'],{tags:['common']}),
  prod(BT9,'skincare-salon','Facial Mask','Barakoa ya Uso','Packet',['facial mask','face mask','skincare']),
  prod(BT9,'skincare-salon','Skin Scrub 200g','Skrub ya Ngozi 200g','Jar',['scrub','skin exfoliate','ngozi']),
];

// ═══════════════════════════════════════════════════════════════════════════
// 10 — RESTAURANT
// ═══════════════════════════════════════════════════════════════════════════
const BT10 = 'Restaurant';
const restaurantCategories: MasterCategory[] = [
  cat(BT10,'Proteins',          'Nyama na Samaki',     'set_meal',     0),
  cat(BT10,'Starches',          'Wanga',               'rice_bowl',    1),
  cat(BT10,'Vegetables',        'Mboga',               'eco',          2),
  cat(BT10,'Cooking Oils & Fats','Mafuta ya Kupikia',  'soup_kitchen', 3),
  cat(BT10,'Spices & Condiments','Viungo',             'local_dining', 4),
  cat(BT10,'Beverages (Restaurant)','Vinywaji',        'local_drink',  5),
  cat(BT10,'Dry Goods',         'Bidhaa Kavu',         'inventory_2',  6),
  cat(BT10,'Ready-to-Serve Items','Vyakula vya Tayari','restaurant',   7),
];
const restaurantProducts: MasterProduct[] = [
  prod(BT10,'proteins','Chicken Whole (per kg)','Kuku Mzima (kwa kg)','Kg',['kuku','chicken','nyama ya kuku','whole chicken'],{cold:true,tags:['common']}),
  prod(BT10,'proteins','Chicken Pieces (per kg)','Vipande vya Kuku (kwa kg)','Kg',['kuku','chicken pieces','vipande'],{cold:true,tags:['common']}),
  prod(BT10,'proteins','Chicken Wings (per kg)','Mbawa za Kuku (kwa kg)','Kg',['chicken wings','mbawa','kuku'],{cold:true}),
  prod(BT10,'proteins','Beef boneless (per kg)','Nyama ya Ng\'ombe (kwa kg)','Kg',['beef','nyama','nyama ya ng\'ombe','boneless'],{cold:true,tags:['common']}),
  prod(BT10,'proteins','Beef with bone (per kg)','Nyama ya Ng\'ombe na Mfupa (kwa kg)','Kg',['beef','nyama na mfupa'],{cold:true}),
  prod(BT10,'proteins','Goat Meat (per kg)','Nyama ya Mbuzi (kwa kg)','Kg',['mbuzi','goat meat','nyama ya mbuzi'],{cold:true,tags:['common']}),
  prod(BT10,'proteins','Minced Meat 500g','Nyama ya Kusaga 500g','Packet',['minced meat','nyama ya kusaga','mince'],{cold:true}),
  prod(BT10,'proteins','Fish Tilapia fresh (per kg)','Samaki Sange (kwa kg)','Kg',['samaki','tilapia','sange','fresh fish'],{cold:true,tags:['common']}),
  prod(BT10,'proteins','Fish Dagaa dried 500g','Dagaa Kavu 500g','Packet',['dagaa','dried fish','omena','small fish'],{tags:['common']}),
  prod(BT10,'proteins','Eggs (tray 30)','Mayai Trei 30','Tray',['mayai','eggs','tray 30'],{cold:true,tags:['common']}),
  prod(BT10,'proteins','Sausages 500g','Sosoji 500g','Packet',['sausages','sosoji','nyama'],{cold:true}),
  prod(BT10,'proteins','Liver beef (per kg)','Ini la Ng\'ombe (kwa kg)','Kg',['ini','liver','beef liver'],{cold:true}),
  prod(BT10,'starches','Rice (per kg)','Mchele (kwa kg)','Kg',['mchele','rice','wali'],{tags:['common']}),
  prod(BT10,'starches','Ugali Flour (per kg)','Unga wa Ugali (kwa kg)','Kg',['ugali','sembe','maize flour'],{tags:['common']}),
  prod(BT10,'starches','Wheat Flour (per kg)','Unga wa Ngano (kwa kg)','Kg',['wheat flour','unga ngano','chapati']),
  prod(BT10,'starches','Pasta spaghetti 500g','Tambi (Spageti) 500g','Packet',['spaghetti','tambi','pasta']),
  prod(BT10,'starches','Pasta macaroni 500g','Tambi (Makaroni) 500g','Packet',['macaroni','tambi','pasta']),
  prod(BT10,'starches','Potatoes (per kg)','Viazi (kwa kg)','Kg',['viazi','potatoes','chips','fries'],{tags:['common']}),
  prod(BT10,'starches','Sweet Potatoes (per kg)','Viazi Vitamu (kwa kg)','Kg',['viazi vitamu','sweet potato']),
  prod(BT10,'starches','Cassava (per kg)','Muhogo (kwa kg)','Kg',['muhogo','cassava'],{tags:['common']}),
  prod(BT10,'starches','Plantain Matoke (per kg)','Ndizi za Kupika (kwa kg)','Kg',['matoke','ndizi','plantain','cooking banana'],{tags:['common']}),
  prod(BT10,'starches','Frozen Chips 1kg','Chipsi za Barafu 1kg','Packet',['chipsi','chips','frozen','french fries'],{cold:true,tags:['common']}),
  prod(BT10,'vegetables','Tomatoes (per kg)','Nyanya (kwa kg)','Kg',['nyanya','tomatoes','mboga'],{tags:['common']}),
  prod(BT10,'vegetables','Onions (per kg)','Vitunguu (kwa kg)','Kg',['vitunguu','onions','mboga'],{tags:['common']}),
  prod(BT10,'vegetables','Garlic 100g','Kitunguu Saumu 100g','Piece',['garlic','kitunguu saumu','viungo'],{tags:['common']}),
  prod(BT10,'vegetables','Ginger 100g','Tangawizi 100g','Piece',['tangawizi','ginger','viungo']),
  prod(BT10,'vegetables','Cabbage (per head)','Kabichi (kichwa kimoja)','Piece',['kabichi','cabbage','mboga'],{tags:['common']}),
  prod(BT10,'vegetables','Spinach Mchicha (bunch)','Mchicha (fungu)','Bunch',['mchicha','spinach','mboga za majani'],{tags:['common']}),
  prod(BT10,'vegetables','Carrots (per kg)','Karoti (kwa kg)','Kg',['karoti','carrots','mboga']),
  prod(BT10,'vegetables','Green Peppers (per kg)','Pilipili Hoho (kwa kg)','Kg',['pilipili hoho','green pepper','mboga']),
  prod(BT10,'vegetables','Coriander Dhania (bunch)','Dhania (fungu)','Bunch',['dhania','coriander','herbs'],{tags:['common']}),
  prod(BT10,'vegetables','Spring Onions (bunch)','Vitunguu Maji (fungu)','Bunch',['spring onions','vitunguu maji','mboga']),
  prod(BT10,'vegetables','Eggplant Bilinganya (per kg)','Bilinganya (kwa kg)','Kg',['bilinganya','eggplant','aubergine','mboga']),
  prod(BT10,'vegetables','Pumpkin (per kg)','Boga (kwa kg)','Kg',['boga','pumpkin','mboga']),
  prod(BT10,'cooking-oils-fats','Cooking Oil 5L','Mafuta ya Kupikia 5L','Jerrycan',['mafuta','cooking oil','5L','kupika'],{tags:['common']}),
  prod(BT10,'cooking-oils-fats','Butter 500g','Siagi 500g','Block',['butter','siagi','baking']),
  prod(BT10,'cooking-oils-fats','Margarine 500g','Siagi Mbadala 500g','Tub',['margarine','siagi','kupika']),
  prod(BT10,'cooking-oils-fats','Coconut Oil 1L','Mafuta ya Nazi 1L','Bottle',['nazi','coconut oil','pwani food'],{tags:['common']}),
  prod(BT10,'spices-condiments','Mchuzi Mix 100g','Mchuzi Mix 100g','Packet',['mchuzi mix','royco','seasoning','viungo'],{brands:['Royco'],tags:['common']}),
  prod(BT10,'spices-condiments','Black Pepper 50g','Pilipili Manga 50g','Packet',['pilipili manga','black pepper','viungo']),
  prod(BT10,'spices-condiments','Chili powder 50g','Pilipili Kali 50g','Packet',['pilipili','chili','viungo'],{tags:['common']}),
  prod(BT10,'spices-condiments','Cumin Bizari 50g','Bizari 50g','Packet',['bizari','cumin','viungo']),
  prod(BT10,'spices-condiments','Cloves Karafuu 50g','Karafuu 50g','Packet',['karafuu','cloves','viungo']),
  prod(BT10,'spices-condiments','Salt coarse 1kg','Chumvi 1kg','Packet',['chumvi','salt','kupika'],{tags:['common']}),
  prod(BT10,'spices-condiments','Tomato Ketchup 500g','Sotsi ya Nyanya 500g','Bottle',['ketchup','tomato sauce','nyanya'],{brands:['Heinz'],tags:['common']}),
  prod(BT10,'spices-condiments','Chili Sauce 200g','Sotsi ya Pilipili 200g','Bottle',['chili sauce','pilipili','hot sauce']),
  prod(BT10,'spices-condiments','Coconut Milk 400ml','Maziwa ya Nazi 400ml','Tin',['coconut milk','nazi','pwani'],{tags:['common']}),
  prod(BT10,'spices-condiments','Vinegar 500ml','Siki 500ml','Bottle',['siki','vinegar','viungo']),
  prod(BT10,'beverages-restaurant','Soft Drinks (per bottle)','Soda (kwa chupa)','Bottle',['soda','cola','fanta','sprite'],{tags:['common']}),
  prod(BT10,'beverages-restaurant','Water 500ml','Maji 500ml','Bottle',['maji','water','mineral water']),
  prod(BT10,'beverages-restaurant','Tea Ketepa (per pack)','Chai Ketepa (kwa pakiti)','Pack',['chai','tea','ketepa'],{brands:['Ketepa'],tags:['common']}),
  prod(BT10,'beverages-restaurant','Coffee instant 50g','Kahawa 50g','Jar',['kahawa','coffee','nescafe'],{brands:['Nescafé']}),
  prod(BT10,'beverages-restaurant','Fresh Juice (mango/passion)','Juisi Safi (embe/pasiflo)','Glass',['juice','juisi','mango','passion fruit'],{tags:['common']}),
  prod(BT10,'dry-goods','Sugar 5kg','Sukari 5kg','Bag',['sukari','sugar','kupika'],{tags:['common']}),
  prod(BT10,'dry-goods','Red Kidney Beans 1kg','Maharage Mekundu 1kg','Packet',['maharage','beans','dengu'],{tags:['common']}),
  prod(BT10,'dry-goods','Lentils 1kg','Dengu 1kg','Packet',['dengu','lentils','maharagwe']),
  prod(BT10,'dry-goods','Bread (loaf)','Mkate (mkate mmoja)','Loaf',['mkate','bread'],{tags:['common']}),
  prod(BT10,'ready-to-serve-items','Ugali na Maharage (plate)','Ugali na Maharage','Plate',['ugali','maharage','chakula cha mchana'],{tags:['common']}),
  prod(BT10,'ready-to-serve-items','Wali na Nyama (plate)','Wali na Nyama','Plate',['wali','nyama','rice and beef'],{tags:['common']}),
  prod(BT10,'ready-to-serve-items','Pilau ya Nyama (plate)','Pilau ya Nyama','Plate',['pilau','nyama','rice','spiced rice'],{tags:['common']}),
  prod(BT10,'ready-to-serve-items','Nyama Choma (250g)','Nyama Choma 250g','Portion',['nyama choma','grilled meat','bbq'],{tags:['common']}),
  prod(BT10,'ready-to-serve-items','Kuku wa Kukaanga','Kuku wa Kukaanga','Portion',['kuku','fried chicken','kuku wa kukaanga'],{tags:['common']}),
  prod(BT10,'ready-to-serve-items','Chipsi Mayai','Chipsi Mayai','Plate',['chipsi mayai','chips eggs','street food'],{tags:['common']}),
  prod(BT10,'ready-to-serve-items','Mishkaki (5 pcs)','Mishkaki (5)','Order',['mishkaki','skewers','nyama','street food'],{tags:['common']}),
  prod(BT10,'ready-to-serve-items','Samosa (2 pcs)','Samosa (2)','Order',['samosa','vitafunio','snack'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 11 — CAFE & BAKERY
// ═══════════════════════════════════════════════════════════════════════════
const BT11 = 'Cafe & Bakery';
const cafeBakeryCategories: MasterCategory[] = [
  cat(BT11,'Baking Ingredients','Vifaa vya Kuoka',        'bakery_dining',0),
  cat(BT11,'Cafe Beverages',    'Vinywaji vya Kahawa',    'local_cafe',   1),
  cat(BT11,'Bakery Supplies',   'Vifaa vya Uchapishaji',  'box',          2),
  cat(BT11,'Fillings & Toppings','Vifaa vya Kujaza',      'cake',         3),
  cat(BT11,'Cafe Snacks',       'Vitafunio vya Kahawa',   'cookie',       4),
];
const cafeBakeryProducts: MasterProduct[] = [
  prod(BT11,'baking-ingredients','Butter baking 250g','Siagi ya Kuoka 250g','Block',['butter','siagi','baking'],{tags:['common']}),
  prod(BT11,'baking-ingredients','Vanilla Essence 50ml','Eseni ya Vanilla 50ml','Bottle',['vanilla','eseni','baking flavour']),
  prod(BT11,'baking-ingredients','Baking Powder 100g','Hamira ya Unga 100g','Tin',['baking powder','hamira','kuoka'],{tags:['common']}),
  prod(BT11,'baking-ingredients','Yeast dry 11g sachet','Chachu Kavu 11g','Sachet',['yeast','chachu','bread','ferment']),
  prod(BT11,'baking-ingredients','Icing Sugar 500g','Sukari ya Kupamba 500g','Packet',['icing sugar','sukari ya kupamba','cake decor']),
  prod(BT11,'baking-ingredients','Caster Sugar 500g','Sukari Laini 500g','Packet',['caster sugar','sukari','baking']),
  prod(BT11,'baking-ingredients','Cocoa Powder 200g','Poda ya Kakao 200g','Pack',['cocoa','kakao','chocolate baking'],{tags:['common']}),
  prod(BT11,'baking-ingredients','Chocolate Chips 200g','Vipande vya Chokoleti 200g','Pack',['chocolate chips','chokoleti','baking']),
  prod(BT11,'baking-ingredients','Desiccated Coconut 200g','Nazi ya Kukausha 200g','Pack',['coconut','nazi','baking']),
  prod(BT11,'baking-ingredients','Wheat Flour 2kg','Unga wa Ngano 2kg','Packet',['flour','unga ngano','baking'],{tags:['common']}),
  prod(BT11,'baking-ingredients','Whipping Cream 250ml','Krimu ya Kupiga 250ml','Pack',['whipping cream','krimu','cake'],{cold:true}),
  prod(BT11,'baking-ingredients','Cream Cheese 200g','Jibini la Krimu 200g','Pack',['cream cheese','jibini','cheesecake'],{cold:true}),
  prod(BT11,'baking-ingredients','Food Colouring set','Rangi za Chakula (seti)','Set',['food colouring','rangi za chakula','cake decor']),
  prod(BT11,'cafe-beverages','Coffee (espresso beans) 250g','Kahawa ya Espresso 250g','Pack',['coffee','kahawa','espresso','barista'],{tags:['common']}),
  prod(BT11,'cafe-beverages','Instant Coffee 100g','Kahawa ya Papo Hapo 100g','Jar',['instant coffee','nescafe','kahawa'],{brands:['Nescafé']}),
  prod(BT11,'cafe-beverages','Tea (Ketepa) 50 bags','Chai Ketepa 50 vibebeo','Box',['chai','tea','ketepa'],{brands:['Ketepa'],tags:['common']}),
  prod(BT11,'cafe-beverages','Hot Chocolate Mix 500g','Kakao ya Moto 500g','Pack',['hot chocolate','kakao','milo'],{brands:['Milo']}),
  prod(BT11,'cafe-beverages','Milk (UHT) 1L','Maziwa UHT 1L','Pack',['maziwa','milk','uht'],{tags:['common']}),
  prod(BT11,'cafe-beverages','Sugar (table) 500g','Sukari ya Meza 500g','Packet',['sukari','sugar','cafe'],{tags:['common']}),
  prod(BT11,'bakery-supplies','Cake Boxes (pack of 10)','Masanduku ya Keki (pakiti 10)','Pack',['cake box','sanduku la keki','packaging'],{tags:['common']}),
  prod(BT11,'bakery-supplies','Cupcake Liners (pack 50)','Vikombe vya Cupcake (50)','Pack',['cupcake liners','vikombe','baking trays']),
  prod(BT11,'bakery-supplies','Piping Bags (pack)','Mifuko ya Kupamba (pakiti)','Pack',['piping bag','mfuko wa kupamba','cake decor']),
  prod(BT11,'bakery-supplies','Baking Trays','Trei za Kuoka','Piece',['baking tray','trei','oven']),
  prod(BT11,'bakery-supplies','Greaseproof Paper (roll)','Karatasi ya Kuokea (roli)','Roll',['greaseproof','baking paper','parchment']),
  prod(BT11,'fillings-toppings','Strawberry Jam 375g','Jamu ya Jordani 375g','Jar',['jam','jamu','filling']),
  prod(BT11,'fillings-toppings','Nutella 200g','Nutella 200g','Jar',['nutella','hazelnut','filling'],{brands:['Nutella']}),
  prod(BT11,'fillings-toppings','Sprinkles (cake decor)','Vipande vya Mapambo','Jar',['sprinkles','decor','cake']),
  prod(BT11,'fillings-toppings','Fondant Icing 500g','Fondanti 500g','Pack',['fondant','icing','cake decor']),
  prod(BT11,'cafe-snacks','Croissant','Kroasani','Piece',['croissant','kroasani','pastry','cafe'],{tags:['common']}),
  prod(BT11,'cafe-snacks','Muffin','Mafini','Piece',['muffin','mafini','pastry','cafe'],{tags:['common']}),
  prod(BT11,'cafe-snacks','Sandwich','Sandwichi','Piece',['sandwich','sandwichi','cafe food'],{tags:['common']}),
  prod(BT11,'cafe-snacks','Mandazi (2 pcs)','Maandazi (2)','Piece',['mandazi','chai','breakfast'],{tags:['common']}),
  prod(BT11,'cafe-snacks','Scone','Skoni','Piece',['scone','skoni','chai','pastry']),
];

// ═══════════════════════════════════════════════════════════════════════════
// 12 — STREET FOOD
// ═══════════════════════════════════════════════════════════════════════════
const BT12 = 'Street Food';
const streetFoodCategories: MasterCategory[] = [
  cat(BT12,'Fried & Grilled',  'Kukaanga na Kuchoma', 'outdoor_grill', 0),
  cat(BT12,'Snacks & Bites',   'Vitafunio',           'fastfood',      1),
  cat(BT12,'Grains & Drinks',  'Nafaka na Vinywaji',  'local_drink',   2),
  cat(BT12,'Ingredients',      'Vifaa vya Kupikia',   'soup_kitchen',  3),
];
const streetFoodProducts: MasterProduct[] = [
  prod(BT12,'fried-grilled','Chipsi (portion)','Chipsi','Plate',['chipsi','chips','viazi kaanga'],{tags:['common']}),
  prod(BT12,'fried-grilled','Chipsi Mayai','Chipsi Mayai','Plate',['chipsi mayai','chips eggs','omelette chips'],{tags:['common']}),
  prod(BT12,'fried-grilled','Nyama Choma (250g)','Nyama Choma 250g','Portion',['nyama choma','grilled meat','bbq'],{tags:['common']}),
  prod(BT12,'fried-grilled','Mishkaki (5 pcs)','Mishkaki (5)','Order',['mishkaki','skewers','nyama'],{tags:['common']}),
  prod(BT12,'fried-grilled','Kuku wa Kukaanga','Kuku wa Kukaanga','Portion',['kuku','fried chicken'],{tags:['common']}),
  prod(BT12,'fried-grilled','Samaki wa Kukaanga','Samaki wa Kukaanga','Piece',['samaki','fried fish','tilapia'],{tags:['common']}),
  prod(BT12,'fried-grilled','Mahindi ya Kuchoma','Mahindi ya Kuchoma','Piece',['mahindi','roasted corn','corn on cob'],{tags:['common']}),
  prod(BT12,'fried-grilled','Ndizi Kaanga','Ndizi Kaanga','Plate',['ndizi','fried banana','plantain']),
  prod(BT12,'snacks-bites','Mandazi (3 pcs)','Maandazi (3)','Order',['mandazi','maandazi','chai'],{tags:['common']}),
  prod(BT12,'snacks-bites','Samosa (2 pcs)','Samosa (2)','Order',['samosa','vitafunio'],{tags:['common']}),
  prod(BT12,'snacks-bites','Mkate wa Mayai','Mkate wa Mayai','Piece',['mkate wa mayai','egg bread','street food'],{tags:['common']}),
  prod(BT12,'snacks-bites','Viazi vya Kuchemsha','Viazi Boiled','Plate',['viazi','boiled potatoes','viazi vya kuchemsha']),
  prod(BT12,'snacks-bites','Bagia (fritters)','Bagia','Order',['bagia','fritters','vitafunio'],{tags:['common']}),
  prod(BT12,'snacks-bites','Vitumbua (3 pcs)','Vitumbua (3)','Order',['vitumbua','rice cakes','street food']),
  prod(BT12,'snacks-bites','Mkate wa Kumimina','Mkate wa Kumimina','Piece',['mkate wa kumimina','pancake','baazi']),
  prod(BT12,'grains-drinks','Uji wa Mahindi (cup)','Uji wa Mahindi','Cup',['uji','porridge','mahindi','breakfast'],{tags:['common']}),
  prod(BT12,'grains-drinks','Chai ya Maziwa (cup)','Chai ya Maziwa','Cup',['chai','tea','maziwa','milk tea'],{tags:['common']}),
  prod(BT12,'grains-drinks','Soda 300ml','Soda 300ml','Bottle',['soda','coca cola','fanta'],{tags:['common']}),
  prod(BT12,'grains-drinks','Maji ya Kunywa 500ml','Maji 500ml','Bottle',['maji','water'],{tags:['common']}),
  prod(BT12,'ingredients','Cooking Oil (daily use) 1L','Mafuta ya Kupikia 1L','Bottle',['mafuta','cooking oil'],{tags:['common']}),
  prod(BT12,'ingredients','Charcoal (mkaa) 5kg','Mkaa 5kg','Bag',['mkaa','charcoal','fuel','cooking'],{tags:['common']}),
  prod(BT12,'ingredients','Salt 500g','Chumvi 500g','Packet',['chumvi','salt']),
  prod(BT12,'ingredients','Tomatoes (per kg)','Nyanya (kwa kg)','Kg',['nyanya','tomatoes'],{tags:['common']}),
  prod(BT12,'ingredients','Onions (per kg)','Vitunguu (kwa kg)','Kg',['vitunguu','onions'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 13 — CATERING
// ═══════════════════════════════════════════════════════════════════════════
const BT13 = 'Catering';
const cateringCategories: MasterCategory[] = [
  cat(BT13,'Bulk Proteins',   'Nyama kwa Wingi',    'set_meal',   0),
  cat(BT13,'Bulk Starches',   'Wanga kwa Wingi',    'rice_bowl',  1),
  cat(BT13,'Bulk Vegetables', 'Mboga kwa Wingi',    'eco',        2),
  cat(BT13,'Event Supplies',  'Vifaa vya Sherehe',  'celebration',3),
];
const cateringProducts: MasterProduct[] = [
  prod(BT13,'bulk-proteins','Whole Chicken (per bird)','Kuku Mzima (kwa ndege)','Piece',['kuku','chicken','catering'],{cold:true,tags:['common']}),
  prod(BT13,'bulk-proteins','Beef boneless (5kg pack)','Nyama ya Ng\'ombe 5kg','Pack',['beef','nyama','5kg'],{cold:true,tags:['common']}),
  prod(BT13,'bulk-proteins','Goat Meat (per kg)','Nyama ya Mbuzi (kwa kg)','Kg',['mbuzi','goat','catering'],{cold:true}),
  prod(BT13,'bulk-proteins','Fish Tilapia (per kg)','Samaki (kwa kg)','Kg',['samaki','tilapia','fish'],{cold:true,tags:['common']}),
  prod(BT13,'bulk-proteins','Eggs (tray 30)','Mayai Trei 30','Tray',['mayai','eggs','tray'],{cold:true}),
  prod(BT13,'bulk-proteins','Sausages 1kg','Sosoji 1kg','Packet',['sausages','sosoji'],{cold:true}),
  prod(BT13,'bulk-proteins','Liver (beef) per kg','Ini la Ng\'ombe kwa kg','Kg',['ini','liver'],{cold:true}),
  prod(BT13,'bulk-proteins','Prawns (per kg)','Kamba (kwa kg)','Kg',['kamba','prawns','seafood'],{cold:true,tags:['common']}),
  prod(BT13,'bulk-starches','Rice 25kg bag','Mchele Mfuko 25kg','Bag',['mchele','rice','bulk','jumla'],{tags:['common']}),
  prod(BT13,'bulk-starches','Ugali Flour 10kg','Unga wa Ugali 10kg','Bag',['ugali','sembe','bulk'],{tags:['common']}),
  prod(BT13,'bulk-starches','Potatoes (per 20kg bag)','Viazi Mfuko 20kg','Bag',['viazi','potatoes','bulk'],{tags:['common']}),
  prod(BT13,'bulk-starches','Pasta spaghetti 1kg','Tambi 1kg','Pack',['spaghetti','tambi','pasta']),
  prod(BT13,'bulk-vegetables','Tomatoes (20kg crate)','Nyanya (gari la 20kg)','Crate',['nyanya','tomatoes','bulk'],{tags:['common']}),
  prod(BT13,'bulk-vegetables','Onions (15kg bag)','Vitunguu Mfuko 15kg','Bag',['vitunguu','onions','bulk'],{tags:['common']}),
  prod(BT13,'bulk-vegetables','Cabbage (per head)','Kabichi','Piece',['kabichi','cabbage','mboga'],{tags:['common']}),
  prod(BT13,'bulk-vegetables','Cooking Oil 20L jerrycan','Mafuta 20L','Jerrycan',['mafuta','cooking oil','20L','bulk'],{tags:['common']}),
  prod(BT13,'event-supplies','Disposable Plates (pack 50)','Sahani za Plastiki 50-pack','Pack',['disposable plates','sahani za plastiki','event'],{tags:['common']}),
  prod(BT13,'event-supplies','Disposable Cups (pack 50)','Vikombe vya Plastiki 50-pack','Pack',['disposable cups','vikombe','event']),
  prod(BT13,'event-supplies','Plastic Forks & Spoons (pack 50)','Nyembe za Plastiki 50-pack','Pack',['plastic cutlery','nyembe','event']),
  prod(BT13,'event-supplies','Foil Trays (pack 10)','Trei za Foil 10-pack','Pack',['foil tray','trei ya foil','event catering'],{tags:['common']}),
  prod(BT13,'event-supplies','Serving Gloves (pack 100)','Glavu za Kuhudumia 100-pack','Pack',['gloves','glavu','food service','catering']),
  prod(BT13,'event-supplies','Tent (3x6m)','Hema (3x6m)','Piece',['tent','hema','event','outdoor'],{tags:['common']}),
  prod(BT13,'event-supplies','Gas Cylinder 15kg','Silinda ya Gesi 15kg','Cylinder',['gas','gesi','cylinder','cooking fuel'],{tags:['common']}),
  prod(BT13,'event-supplies','Charcoal 20kg bag','Mkaa 20kg','Bag',['mkaa','charcoal','grilling','nyama choma'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 14 — AGRICULTURE
// ═══════════════════════════════════════════════════════════════════════════
const BT14 = 'Agriculture';
const agricultureCategories: MasterCategory[] = [
  cat(BT14,'Seeds',                  'Mbegu',                   'grass',      0),
  cat(BT14,'Fertilisers',            'Mbolea',                  'compost',    1),
  cat(BT14,'Pesticides & Herbicides','Dawa za Wadudu na Magugu','pest_control',2),
  cat(BT14,'Harvested Crops',        'Mazao',                   'agriculture',3),
];
const agricultureProducts: MasterProduct[] = [
  prod(BT14,'seeds','Maize Seeds hybrid 2kg','Mbegu ya Mahindi (Mseto) 2kg','Packet',['mbegu ya mahindi','corn seeds','hybrid','kilimo'],{tags:['common']}),
  prod(BT14,'seeds','Maize Seeds open pollinated 2kg','Mbegu ya Mahindi (Kawaida) 2kg','Packet',['mbegu ya mahindi','open pollinated','kilimo']),
  prod(BT14,'seeds','Tomato Seeds 10g','Mbegu ya Nyanya 10g','Packet',['mbegu ya nyanya','tomato seeds','kilimo'],{tags:['common']}),
  prod(BT14,'seeds','Onion Seeds 10g','Mbegu ya Vitunguu 10g','Packet',['mbegu ya vitunguu','onion seeds'],{tags:['common']}),
  prod(BT14,'seeds','Cabbage Seeds 10g','Mbegu ya Kabichi 10g','Packet',['mbegu ya kabichi','cabbage seeds']),
  prod(BT14,'seeds','Sukuma Wiki Seeds 10g','Mbegu ya Sukuma Wiki 10g','Packet',['sukuma wiki','kale seeds','mbegu'],{tags:['common']}),
  prod(BT14,'seeds','Bean Seeds 1kg','Mbegu ya Maharage 1kg','Packet',['mbegu ya maharage','bean seeds','kilimo']),
  prod(BT14,'seeds','Soya Bean Seeds 1kg','Mbegu ya Soya 1kg','Packet',['soya bean seeds','mbegu ya soya']),
  prod(BT14,'seeds','Sunflower Seeds 1kg','Mbegu ya Alizeti 1kg','Packet',['alizeti','sunflower seeds','kilimo'],{tags:['common']}),
  prod(BT14,'seeds','Sorghum Seeds 1kg','Mbegu ya Mtama 1kg','Packet',['mtama','sorghum seeds','kilimo']),
  prod(BT14,'seeds','Sweet Potato Cuttings (bundle)','Machipukizi ya Viazi Vitamu','Bundle',['viazi vitamu','sweet potato cuttings','kilimo']),
  prod(BT14,'fertilisers','CAN 50kg','CAN (Calcium Ammonium Nitrate) 50kg','Bag',['CAN','mbolea','calcium ammonium nitrate','fertilizer'],{tags:['common']}),
  prod(BT14,'fertilisers','DAP 50kg','DAP (Diamonium Phosphate) 50kg','Bag',['DAP','mbolea','fertilizer','phosphate'],{tags:['common']}),
  prod(BT14,'fertilisers','Urea 50kg','Urea 50kg','Bag',['urea','mbolea','nitrogen fertilizer'],{tags:['common']}),
  prod(BT14,'fertilisers','NPK 17:17:17 50kg','NPK 17:17:17 50kg','Bag',['NPK','mbolea','compound fertilizer'],{tags:['common']}),
  prod(BT14,'fertilisers','Compost per bag','Mbolea Asili (mfuko)','Bag',['compost','mbolea asili','organic fertilizer']),
  prod(BT14,'fertilisers','Top Dressing Fertiliser 25kg','Mbolea ya Juu 25kg','Bag',['top dressing','mbolea ya juu','urea']),
  prod(BT14,'fertilisers','Foliar Fertiliser 1L','Mbolea ya Majani 1L','Bottle',['foliar','mbolea ya majani','spray fertilizer']),
  prod(BT14,'pesticides-herbicides','Herbicide glyphosate 1L','Dawa ya Magugu 1L','Bottle',['herbicide','magugu','glyphosate','roundup'],{brands:['Roundup'],tags:['common']}),
  prod(BT14,'pesticides-herbicides','Insecticide Dimethoate 1L','Dawa ya Wadudu 1L','Bottle',['insecticide','dawa ya wadudu','dimethoate'],{tags:['common']}),
  prod(BT14,'pesticides-herbicides','Fungicide Mancozeb 1kg','Dawa ya Kuvu 1kg','Pack',['fungicide','ukungu','mancozeb']),
  prod(BT14,'pesticides-herbicides','Rodenticide Ratex 50g','Dawa ya Panya 50g','Packet',['ratex','panya','rodent killer'],{brands:['Ratex']}),
  prod(BT14,'pesticides-herbicides','Neem Oil 500ml','Mafuta ya Mwarobaini 500ml','Bottle',['neem oil','mwarobaini','organic pesticide']),
  prod(BT14,'harvested-crops','Maize (per 90kg bag)','Mahindi (mfuko 90kg)','Bag',['mahindi','maize','corn','kilimo'],{tags:['common']}),
  prod(BT14,'harvested-crops','Rice paddy (per 100kg bag)','Mpunga (mfuko 100kg)','Bag',['mpunga','paddy rice','kilimo'],{tags:['common']}),
  prod(BT14,'harvested-crops','Sunflower (per 100kg bag)','Alizeti (mfuko 100kg)','Bag',['alizeti','sunflower seeds','harvest'],{tags:['common']}),
  prod(BT14,'harvested-crops','Beans (per 90kg bag)','Maharage (mfuko 90kg)','Bag',['maharage','beans','harvest']),
  prod(BT14,'harvested-crops','Soya beans (per 100kg bag)','Soya (mfuko 100kg)','Bag',['soya','soya beans','harvest']),
  prod(BT14,'harvested-crops','PP Sack 50kg (empty)','Gunia la PP 50kg (tupu)','Piece',['gunia','sack','harvest bag'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 15 — AGRIBUSINESS
// ═══════════════════════════════════════════════════════════════════════════
const BT15 = 'Agribusiness';
const agribusinessCategories: MasterCategory[] = [
  cat(BT15,'Bulk Grains',        'Nafaka kwa Wingi',         'agriculture',  0),
  cat(BT15,'Processed Products', 'Bidhaa Zilizosindikwa',    'factory',      1),
  cat(BT15,'Agricultural Equipment','Vifaa vya Kilimo',      'construction', 2),
  cat(BT15,'Packaging & Storage','Vifaa vya Kuhifadhi',      'inventory_2',  3),
];
const agribusinessProducts: MasterProduct[] = [
  prod(BT15,'bulk-grains','Maize (metric ton)','Mahindi (tani)','Ton',['mahindi','maize','bulk','metric ton'],{tags:['common']}),
  prod(BT15,'bulk-grains','Rice paddy (metric ton)','Mpunga (tani)','Ton',['mpunga','paddy','rice','tani'],{tags:['common']}),
  prod(BT15,'bulk-grains','Sunflower Seeds (metric ton)','Alizeti (tani)','Ton',['alizeti','sunflower','bulk']),
  prod(BT15,'bulk-grains','Soya Beans (metric ton)','Soya (tani)','Ton',['soya','soya beans','bulk']),
  prod(BT15,'bulk-grains','Wheat (metric ton)','Ngano (tani)','Ton',['ngano','wheat','bulk']),
  prod(BT15,'bulk-grains','Cassava (metric ton)','Muhogo (tani)','Ton',['muhogo','cassava','bulk']),
  prod(BT15,'bulk-grains','Beans (metric ton)','Maharage (tani)','Ton',['maharage','beans','legumes','bulk'],{tags:['common']}),
  prod(BT15,'bulk-grains','Sesame (per 100kg)','Simsim (kwa 100kg)','Bag',['simsim','sesame','export crop'],{tags:['common']}),
  prod(BT15,'processed-products','Maize Flour (milled) 50kg','Unga wa Mahindi (Sembe) 50kg','Bag',['sembe','maize flour','milled','bulk'],{tags:['common']}),
  prod(BT15,'processed-products','Sunflower Oil (crude) 20L','Mafuta ya Alizeti (ghafi) 20L','Jerrycan',['sunflower oil','mafuta','crude oil','bulk'],{tags:['common']}),
  prod(BT15,'processed-products','Rice (milled) 50kg','Mchele (Safi) 50kg','Bag',['mchele','milled rice','processed'],{tags:['common']}),
  prod(BT15,'processed-products','Soya Chunks bulk 5kg','Soya Vikoni 5kg','Pack',['soya chunks','protein','bulk']),
  prod(BT15,'agricultural-equipment','Maize Sheller (manual)','Mashine ya Kupiga Mahindi (ya Mikono)','Piece',['maize sheller','kupiga mahindi','thresher'],{tags:['common']}),
  prod(BT15,'agricultural-equipment','Grain Moisture Meter','Kipimo cha Unyevu wa Nafaka','Piece',['moisture meter','unyevu','grain quality']),
  prod(BT15,'agricultural-equipment','Weighing Scale 100kg','Mizani ya 100kg','Piece',['scale','mizani','100kg','weighing'],{tags:['common']}),
  prod(BT15,'agricultural-equipment','Tarpaulin 6x8m','Sanda 6x8m','Piece',['tarpaulin','sanda','drying crop','waterproof'],{tags:['common']}),
  prod(BT15,'packaging-storage','Polypropylene Sack 50kg (bale)','Gunia la PP 50kg (gunda)','Bale',['gunia','sack','packaging','bulk'],{tags:['common']}),
  prod(BT15,'packaging-storage','Woven Sack 100kg','Gunia Nzito 100kg','Piece',['gunia nzito','heavy sack','storage']),
  prod(BT15,'packaging-storage','Metal Silo 1 ton','Silo ya Chuma (tani 1)','Piece',['silo','grain storage','metal silo'],{tags:['common']}),
  prod(BT15,'packaging-storage','Fumigation Tablets (pack)','Dawa ya Kufukiza (pakiti)','Pack',['fumigation','dawa ya nafaka','grain storage pest'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 16 — LIVESTOCK & POULTRY
// ═══════════════════════════════════════════════════════════════════════════
const BT16 = 'Livestock & Poultry';
const livestockCategories: MasterCategory[] = [
  cat(BT16,'Animal Feed',      'Chakula cha Mifugo', 'pets',         0),
  cat(BT16,'Veterinary Supplies','Dawa za Mifugo',   'vaccines',     1),
  cat(BT16,'Poultry Supplies', 'Vifaa vya Kuku',     'egg_alt',      2),
  cat(BT16,'Livestock Products','Mazao ya Mifugo',   'agriculture',  3),
];
const livestockProducts: MasterProduct[] = [
  prod(BT16,'animal-feed','Broiler Starter 50kg','Chakula cha Kuku Wadogo 50kg','Bag',['broiler starter','kuku','feed','chakula cha kuku'],{tags:['common']}),
  prod(BT16,'animal-feed','Broiler Finisher 50kg','Chakula cha Kuku Wakubwa 50kg','Bag',['broiler finisher','kuku','chakula'],{tags:['common']}),
  prod(BT16,'animal-feed','Layer Mash 50kg','Chakula cha Kuku wa Mayai 50kg','Bag',['layer mash','kuku wa mayai','chakula'],{tags:['common']}),
  prod(BT16,'animal-feed','Chick Mash 50kg','Chakula cha Vifaranga 50kg','Bag',['chick mash','vifaranga','chakula'],{tags:['common']}),
  prod(BT16,'animal-feed','Dairy Meal 50kg','Chakula cha Ng\'ombe wa Maziwa 50kg','Bag',['dairy meal','ng\'ombe','maziwa','chakula'],{tags:['common']}),
  prod(BT16,'animal-feed','Pig Feed grower 50kg','Chakula cha Nguruwe 50kg','Bag',['nguruwe','pig feed','grower']),
  prod(BT16,'animal-feed','Goat & Sheep Pellets 50kg','Peleti za Mbuzi na Kondoo 50kg','Bag',['mbuzi','kondoo','pellets','chakula']),
  prod(BT16,'animal-feed','Fish Meal 25kg','Unga wa Samaki 25kg','Bag',['fish meal','unga wa samaki','protein'],{tags:['common']}),
  prod(BT16,'animal-feed','Hay bale','Nyasi (bale)','Bale',['hay','nyasi','fodder','cattle feed'],{tags:['common']}),
  prod(BT16,'animal-feed','Molasses 5L','Molasi 5L','Jerrycan',['molasses','molasi','feed supplement']),
  prod(BT16,'veterinary-supplies','Vaccine Newcastle Disease vial','Chanjo ya Ugonjwa wa Newcastle','Vial',['vaccine','chanjo','newcastle','poultry'],{cold:true,tags:['common']}),
  prod(BT16,'veterinary-supplies','Vitamin & Mineral Mix 500g','Vitamini na Madini ya Mifugo 500g','Pack',['vitamini','minerals','supplement','mifugo'],{tags:['common']}),
  prod(BT16,'veterinary-supplies','Dewormer Albendazole 10 tablets','Dawa ya Minyoo (Albendazole) 10 vidonge','Pack',['dewormer','minyoo','albendazole','mifugo'],{tags:['common']}),
  prod(BT16,'veterinary-supplies','Antibiotic Oxytetracycline 100ml','Antibiotiki ya Mifugo 100ml','Bottle',['oxytetracycline','antibiotic','mifugo','dawa'],{rx:true,tags:['common']}),
  prod(BT16,'veterinary-supplies','Acaricide tick dip 1L','Dawa ya Kupe 1L','Bottle',['acaricide','kupe','tick dip','mifugo'],{tags:['common']}),
  prod(BT16,'veterinary-supplies','Wound Spray 250ml','Dawa ya Jeraha 250ml','Can',['wound spray','jeraha','antiseptic','mifugo']),
  prod(BT16,'veterinary-supplies','Ear Tags (pack 10)','Alama za Masikio (pakiti 10)','Pack',['ear tags','alama','identification','mifugo']),
  prod(BT16,'veterinary-supplies','Syringe 20ml (pack 10)','Sindano ya Mifugo 20ml (pakiti 10)','Pack',['syringe','sindano','injection','mifugo']),
  prod(BT16,'poultry-supplies','Drinker (poultry) 5L','Chombo cha Maji cha Kuku 5L','Piece',['drinker','maji ya kuku','poultry equipment'],{tags:['common']}),
  prod(BT16,'poultry-supplies','Feeder trough (poultry)','Chombo cha Chakula cha Kuku','Piece',['feeder','chakula cha kuku','poultry trough'],{tags:['common']}),
  prod(BT16,'poultry-supplies','Incubator 100-egg','Jokofu la Kuatamia Mayai 100','Piece',['incubator','kuatamia','mayai','poultry']),
  prod(BT16,'poultry-supplies','Heat Lamp (brooder)','Taa ya Joto (bruda)','Piece',['heat lamp','bruda','chick brooding']),
  prod(BT16,'livestock-products','Fresh Milk (per litre)','Maziwa Safi (kwa lita)','Litre',['maziwa safi','fresh milk','cow milk'],{cold:true,tags:['common']}),
  prod(BT16,'livestock-products','Eggs (tray 30)','Mayai Trei 30','Tray',['mayai','eggs tray','layer eggs'],{cold:true,tags:['common']}),
  prod(BT16,'livestock-products','Dressed Chicken (per bird)','Kuku Safi (kwa ndege)','Piece',['kuku safi','dressed chicken','broiler'],{cold:true,tags:['common']}),
  prod(BT16,'livestock-products','Goat (live, per head)','Mbuzi (hai, kwa kichwa)','Head',['mbuzi','goat','livestock'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 17 — FISHING
// ═══════════════════════════════════════════════════════════════════════════
const BT17 = 'Fishing';
const fishingCategories: MasterCategory[] = [
  cat(BT17,'Fishing Equipment','Vifaa vya Uvuvi',  'sailing',     0),
  cat(BT17,'Fish Products',    'Bidhaa za Samaki', 'set_meal',    1),
];
const fishingProducts: MasterProduct[] = [
  prod(BT17,'fishing-equipment','Fishing Net (per metre)','Nyavu ya Uvuvi (kwa mita)','Metre',['nyavu','fishing net','uvuvi'],{tags:['common']}),
  prod(BT17,'fishing-equipment','Fishing Line (spool)','Uzi wa Uvuvi (spool)','Spool',['fishing line','uzi wa uvuvi','hook and line'],{tags:['common']}),
  prod(BT17,'fishing-equipment','Fish Hooks (pack 20)','Ndoano za Samaki (pakiti 20)','Pack',['ndoano','fish hooks','uvuvi'],{tags:['common']}),
  prod(BT17,'fishing-equipment','Fishing Rope (per metre)','Kamba ya Uvuvi (kwa mita)','Metre',['kamba','rope','uvuvi']),
  prod(BT17,'fishing-equipment','Ice Box (portable)','Sanduku la Barafu','Piece',['ice box','sanduku la barafu','fish cool'],{tags:['common']}),
  prod(BT17,'fishing-equipment','Fish Crate','Sanduku la Samaki','Piece',['fish crate','sanduku','samaki']),
  prod(BT17,'fishing-equipment','Bait (worms/squid)','Chambo','Pack',['bait','chambo','fishing']),
  prod(BT17,'fishing-equipment','Fishing Boat Oar','Kasia la Boti','Piece',['kasia','oar','boti ya uvuvi']),
  prod(BT17,'fishing-equipment','Outboard Motor Oil 1L','Mafuta ya Injini ya Boti 1L','Bottle',['motor oil','injini','boti','uvuvi'],{tags:['common']}),
  prod(BT17,'fishing-equipment','Life Jacket','Jaketi ya Usalama','Piece',['life jacket','usalama','uvuvi'],{tags:['common']}),
  prod(BT17,'fish-products','Fresh Tilapia (per kg)','Samaki Sange Safi (kwa kg)','Kg',['tilapia','sange','samaki safi'],{cold:true,tags:['common']}),
  prod(BT17,'fish-products','Fresh Perch Sangara (per kg)','Sangara Safi (kwa kg)','Kg',['sangara','perch','samaki'],{cold:true,tags:['common']}),
  prod(BT17,'fish-products','Dried Dagaa 500g','Dagaa Kavu 500g','Packet',['dagaa','omena','dried fish'],{tags:['common']}),
  prod(BT17,'fish-products','Smoked Fish (per kg)','Samaki wa Kuvuta Moshi (kwa kg)','Kg',['smoked fish','kuvuta moshi','samaki'],{tags:['common']}),
  prod(BT17,'fish-products','Frozen Fish (per kg)','Samaki Baridi (kwa kg)','Kg',['frozen fish','samaki baridi'],{cold:true,tags:['common']}),
  prod(BT17,'fish-products','Prawns (per kg)','Kamba (kwa kg)','Kg',['kamba','prawns','seafood'],{cold:true}),
  prod(BT17,'fish-products','Octopus (per kg)','Pweza (kwa kg)','Kg',['pweza','octopus','seafood'],{cold:true}),
  prod(BT17,'fish-products','Crab (per kg)','Kaa (kwa kg)','Kg',['kaa','crab','seafood'],{cold:true}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 18 — MANUFACTURING
// ═══════════════════════════════════════════════════════════════════════════
const BT18 = 'Manufacturing';
const manufacturingCategories: MasterCategory[] = [
  cat(BT18,'Raw Materials',        'Malighafi',                'inventory_2',  0),
  cat(BT18,'Packaging Materials',  'Vifaa vya Kufunga',        'box',          1),
  cat(BT18,'Chemicals & Inputs',   'Kemikali na Vifaa',        'science',      2),
  cat(BT18,'Machinery & Parts',    'Mashine na Vipuri',        'precision_manufacturing',3),
];
const manufacturingProducts: MasterProduct[] = [
  prod(BT18,'raw-materials','Steel Sheet (per metre)','Bati la Chuma (kwa mita)','Metre',['steel sheet','bati','chuma','raw material'],{tags:['common']}),
  prod(BT18,'raw-materials','Aluminium Sheet (per metre)','Aluminium (kwa mita)','Metre',['aluminium','sheet metal','raw material']),
  prod(BT18,'raw-materials','Iron Rod 12mm (per metre)','Fimbo ya Chuma 12mm','Metre',['iron rod','fimbo ya chuma','steel'],{tags:['common']}),
  prod(BT18,'raw-materials','Copper Wire 2.5mm (per metre)','Waya wa Shaba 2.5mm','Metre',['copper wire','waya wa shaba','electrical']),
  prod(BT18,'raw-materials','Timber (per metre)','Mbao (kwa mita)','Metre',['mbao','timber','wood'],{tags:['common']}),
  prod(BT18,'raw-materials','Plastic Pellets (per kg)','Chembe za Plastiki (kwa kg)','Kg',['plastic pellets','raw plastic','manufacturing']),
  prod(BT18,'raw-materials','Rubber Sheet (per metre)','Mpira wa Karatasi','Metre',['rubber','mpira','gasket material']),
  prod(BT18,'raw-materials','Fibre Glass (per metre)','Nyuzi za Glasi','Metre',['fibre glass','nyuzi za glasi','composite']),
  prod(BT18,'packaging-materials','Cardboard Box (pack 20)','Sanduku la Kadibodi (pakiti 20)','Pack',['cardboard box','sanduku','packaging'],{tags:['common']}),
  prod(BT18,'packaging-materials','Shrink Wrap Roll','Roli ya Shrink Wrap','Roll',['shrink wrap','packaging','plastic wrap'],{tags:['common']}),
  prod(BT18,'packaging-materials','Packing Tape 50mm (roll)','Tepi ya Kufunga (roli)','Roll',['packing tape','tepi','packaging']),
  prod(BT18,'packaging-materials','Polythene Bags (bundle 500)','Mifuko ya Polyethylene (bundle 500)','Bundle',['polythene','plastic bags','packaging'],{tags:['common']}),
  prod(BT18,'packaging-materials','Bubble Wrap (roll)','Roli ya Bubble Wrap','Roll',['bubble wrap','packaging','protective']),
  prod(BT18,'packaging-materials','Pallet (wooden)','Pali ya Mbao','Piece',['pallet','pali','storage'],{tags:['common']}),
  prod(BT18,'chemicals-inputs','Industrial Adhesive 5L','Gundi ya Viwanda 5L','Can',['adhesive','gundi','bonding','industrial'],{tags:['common']}),
  prod(BT18,'chemicals-inputs','Industrial Paint 20L','Rangi ya Viwanda 20L','Bucket',['paint','rangi','industrial'],{tags:['common']}),
  prod(BT18,'chemicals-inputs','Lubricating Oil 5L','Mafuta ya Kulainisha 5L','Can',['lubricant','mafuta','machine oil'],{tags:['common']}),
  prod(BT18,'chemicals-inputs','Solvent (thinner) 5L','Kiondoa Rangi 5L','Can',['thinner','solvent','paint thinner'],{tags:['common']}),
  prod(BT18,'machinery-parts','Drive Belt (universal)','Ukanda wa Mashine','Piece',['drive belt','ukanda','machine belt'],{tags:['common']}),
  prod(BT18,'machinery-parts','Bearing (assorted)','Bering (mchanganyiko)','Piece',['bearing','bering','machine parts'],{tags:['common']}),
  prod(BT18,'machinery-parts','Welding Electrodes (pack)','Nondo za Kulehemu (pakiti)','Pack',['welding','kulehemu','electrodes'],{tags:['common']}),
  prod(BT18,'machinery-parts','Grinding Disc 115mm','Diski ya Kusaga 115mm','Piece',['grinding disc','angle grinder','kusaga'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 19 — CONSTRUCTION
// ═══════════════════════════════════════════════════════════════════════════
const BT19 = 'Construction';
const constructionCategories: MasterCategory[] = [
  cat(BT19,'Foundation & Structure','Msingi na Muundo',        'foundation',   0),
  cat(BT19,'Roofing',              'Vifaa vya Paa',            'roofing',      1),
  cat(BT19,'Flooring & Tiles',     'Vigae na Sakafu',          'floor_lamp',   2),
  cat(BT19,'Doors & Windows',      'Milango na Madirisha',     'door_front',   3),
  cat(BT19,'Electrical & Plumbing','Umeme na Mabomba',         'electrical_services',4),
];
const constructionProducts: MasterProduct[] = [
  prod(BT19,'foundation-structure','Reinforcing Bar 12mm x 6m','Fimbo ya Chuma 12mm x 6m','Piece',['rebar','chuma','12mm','reinforcement','foundation'],{tags:['common']}),
  prod(BT19,'foundation-structure','Reinforcing Bar 8mm x 6m','Fimbo ya Chuma 8mm x 6m','Piece',['rebar','8mm','stirrups','slab']),
  prod(BT19,'foundation-structure','Binding Wire 1kg','Waya wa Kufunga 1kg','Kg',['binding wire','waya','construction'],{tags:['common']}),
  prod(BT19,'foundation-structure','Timber Plank 2x4x12ft','Ubao wa Mbao 2x4x12ft','Piece',['timber','mbao','formwork','shuttering'],{tags:['common']}),
  prod(BT19,'foundation-structure','Plywood 4x8ft 18mm','Plywood 4x8ft 18mm','Sheet',['plywood','bodi','formwork'],{tags:['common']}),
  prod(BT19,'foundation-structure','Hollow Blocks 20cm','Matofali ya Saruji 20cm','Piece',['hollow blocks','matofali','concrete block','walling'],{tags:['common']}),
  prod(BT19,'foundation-structure','Sand (per load)','Mchanga (kwa mzigo)','Load',['mchanga','sand','building materials'],{tags:['common']}),
  prod(BT19,'foundation-structure','Ballast (per load)','Kokoto (kwa mzigo)','Load',['kokoto','ballast','aggregate','concrete'],{tags:['common']}),
  prod(BT19,'roofing','Roofing Sheet Mabati 0.3mm 3m','Bati la Paa 0.3mm 3m','Sheet',['bati','roofing sheet','mabati','galvanized'],{tags:['common']}),
  prod(BT19,'roofing','Roofing Nails 2" 1kg','Misumari ya Bati 2" 1kg','Kg',['roofing nails','misumari ya bati','nails'],{tags:['common']}),
  prod(BT19,'roofing','Ridge Cap (per metre)','Kichwa cha Paa (kwa mita)','Metre',['ridge cap','kichwa cha paa','roofing']),
  prod(BT19,'roofing','Ceiling Board Gyproc 4x8ft','Bodi ya Dari 4x8ft','Sheet',['ceiling board','dari','gyproc','plasterboard'],{tags:['common']}),
  prod(BT19,'roofing','Roof Purlin C-section 6m','Purlin ya Chuma 6m','Piece',['purlin','steel purlin','roofing frame'],{tags:['common']}),
  prod(BT19,'roofing','Bitumen Sheet 1m²','Bitumeni 1m²','Sheet',['bitumen','waterproof sheet','damp proof']),
  prod(BT19,'flooring-tiles','Ceramic Floor Tiles 30x30cm m²','Vigae vya Sakafu 30x30cm','m²',['tiles','vigae','floor tiles','30x30'],{tags:['common']}),
  prod(BT19,'flooring-tiles','Ceramic Floor Tiles 60x60cm m²','Vigae vya Sakafu 60x60cm','m²',['tiles','vigae','60x60','large tiles'],{tags:['common']}),
  prod(BT19,'flooring-tiles','Wall Tiles 20x30cm m²','Vigae vya Ukuta 20x30cm','m²',['wall tiles','vigae vya ukuta','bathroom'],{tags:['common']}),
  prod(BT19,'flooring-tiles','Tile Adhesive 20kg','Gundi la Vigae 20kg','Bag',['tile adhesive','gundi','tile fix'],{tags:['common']}),
  prod(BT19,'flooring-tiles','Tile Grout 5kg White','Saruji ya Vigae 5kg','Bag',['grout','saruji ya vigae','joints'],{tags:['common']}),
  prod(BT19,'doors-windows','Steel Door Frame (standard)','Fremu ya Chuma ya Mlango','Piece',['door frame','fremu','steel door'],{tags:['common']}),
  prod(BT19,'doors-windows','Aluminium Window Frame 60x60cm','Fremu ya Aluminium ya Dirisha','Piece',['window frame','aluminium','dirisha'],{tags:['common']}),
  prod(BT19,'doors-windows','Door Lock (mortice)','Kufuli ya Mlango','Piece',['door lock','kufuli','security'],{tags:['common']}),
  prod(BT19,'doors-windows','Door Hinges (pair)','Bangili za Mlango (jozi)','Pair',['hinges','bangili','door fitting']),
  prod(BT19,'electrical-plumbing','PVC Conduit 20mm 3m','Bomba la Waya 20mm 3m','Piece',['conduit','bomba la waya','electrical'],{tags:['common']}),
  prod(BT19,'electrical-plumbing','PPR Pipe 20mm 4m','Bomba la PPR 20mm 4m','Piece',['PPR pipe','maji ya moto','plumbing'],{tags:['common']}),
  prod(BT19,'electrical-plumbing','Wall Putty 20kg','Putty ya Ukuta 20kg','Bag',['putty','wall prep','smoothing'],{tags:['common']}),
  prod(BT19,'electrical-plumbing','Waterproofing Compound 20kg','Dawa ya Kuzuia Maji 20kg','Bucket',['waterproofing','kuzuia maji','sealant'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 20 — HARDWARE & BUILDING MATERIALS
// ═══════════════════════════════════════════════════════════════════════════
const BT20 = 'Hardware & Building Materials';
const hardwareCategories: MasterCategory[] = [
  cat(BT20,'Cement & Aggregates', 'Saruji na Vifaa vya Ujenzi','foundation',    0),
  cat(BT20,'Steel & Metal',       'Chuma na Madini',           'hardware',      1),
  cat(BT20,'Timber & Wood',       'Mbao na Miti',              'forest',        2),
  cat(BT20,'Plumbing',            'Mabomba na Vifaa vya Maji', 'plumbing',      3),
  cat(BT20,'Electrical',          'Vifaa vya Umeme',           'electrical_services',4),
  cat(BT20,'Paint & Finishing',   'Rangi na Mapambo',          'format_paint',  5),
  cat(BT20,'Roofing',             'Vifaa vya Paa',             'roofing',       6),
  cat(BT20,'Tools',               'Zana',                      'hardware',      7),
  cat(BT20,'Sanitary Ware',       'Vifaa vya Choo na Bafu',    'bathroom',      8),
  cat(BT20,'Tiles & Flooring',    'Vigae na Sakafu',           'floor_lamp',    9),
];
const hardwareProducts: MasterProduct[] = [
  // Cement & Aggregates
  prod(BT20,'cement-aggregates','Twiga Cement 50kg','Saruji ya Twiga 50kg','Bag',['saruji','cement','twiga','ujenzi'],{brands:['Twiga'],tags:['common']}),
  prod(BT20,'cement-aggregates','Simba Cement 50kg','Saruji ya Simba 50kg','Bag',['saruji','simba','cement'],{brands:['Simba'],tags:['common']}),
  prod(BT20,'cement-aggregates','Sand (per load)','Mchanga (kwa mzigo)','Load',['mchanga','sand'],{tags:['common']}),
  prod(BT20,'cement-aggregates','Aggregate ballast per ton','Kokoto (kwa tani)','Ton',['kokoto','ballast','gravel','concrete'],{tags:['common']}),
  prod(BT20,'cement-aggregates','Red Soil murram per load','Udongo Mwekundu','Load',['murram','udongo','construction']),
  // Steel & Metal
  prod(BT20,'steel-metal','Steel Rod 8mm x 12m','Fimbo ya Chuma 8mm x 12m','Piece',['steel rod','chuma','8mm','rebar'],{tags:['common']}),
  prod(BT20,'steel-metal','Steel Rod 10mm x 12m','Fimbo ya Chuma 10mm x 12m','Piece',['steel rod','10mm','rebar'],{tags:['common']}),
  prod(BT20,'steel-metal','Steel Rod 12mm x 12m','Fimbo ya Chuma 12mm x 12m','Piece',['steel rod','12mm','rebar','concrete'],{tags:['common']}),
  prod(BT20,'steel-metal','Steel Rod 16mm x 12m','Fimbo ya Chuma 16mm x 12m','Piece',['steel rod','16mm','heavy rebar']),
  prod(BT20,'steel-metal','Binding Wire roll','Waya wa Kufunga (roli)','Roll',['binding wire','waya','construction'],{tags:['common']}),
  prod(BT20,'steel-metal','Iron Sheet gauge 28 3m','Bati Nzito (gauge 28) 3m','Sheet',['iron sheet','bati','gauge 28','roofing'],{tags:['common']}),
  prod(BT20,'steel-metal','Iron Sheet gauge 30 3m','Bati Nyepesi (gauge 30) 3m','Sheet',['iron sheet','bati','gauge 30'],{tags:['common']}),
  prod(BT20,'steel-metal','Steel Angle Bar 40x40x3mm','Kona ya Chuma 40x40x3mm','Piece',['angle bar','kona','steel','fabrication']),
  // Timber & Wood
  prod(BT20,'timber-wood','Timber 2x4" per metre','Mbao 2x4" kwa Mita','Metre',['mbao','timber','2x4','wood'],{tags:['common']}),
  prod(BT20,'timber-wood','Timber 2x6" per metre','Mbao 2x6" kwa Mita','Metre',['mbao','timber','2x6'],{tags:['common']}),
  prod(BT20,'timber-wood','Plywood 4x8" 6mm','Plywood 4x8" 6mm','Sheet',['plywood','bodi','6mm'],{tags:['common']}),
  prod(BT20,'timber-wood','Plywood 4x8" 12mm','Plywood 4x8" 12mm','Sheet',['plywood','bodi','12mm'],{tags:['common']}),
  prod(BT20,'timber-wood','Chipboard 4x8"','Chipboard 4x8"','Sheet',['chipboard','particleboard'],{tags:['common']}),
  prod(BT20,'timber-wood','MDF Board 4x8"','MDF Board 4x8"','Sheet',['mdf','board','furniture']),
  prod(BT20,'timber-wood','Door Frame complete','Fremu ya Mlango (kamili)','Set',['door frame','fremu','mlango'],{tags:['common']}),
  // Plumbing
  prod(BT20,'plumbing','PVC Pipe 1/2" x 3m','Bomba la PVC 1/2" x 3m','Piece',['pvc pipe','bomba','maji','half inch'],{tags:['common']}),
  prod(BT20,'plumbing','PVC Pipe 3/4" x 3m','Bomba la PVC 3/4" x 3m','Piece',['pvc pipe','bomba','3/4 inch'],{tags:['common']}),
  prod(BT20,'plumbing','PVC Pipe 1" x 3m','Bomba la PVC 1" x 3m','Piece',['pvc pipe','bomba','1 inch'],{tags:['common']}),
  prod(BT20,'plumbing','PVC Pipe 2" x 3m','Bomba la PVC 2" x 3m','Piece',['pvc pipe','bomba','2 inch'],{tags:['common']}),
  prod(BT20,'plumbing','PVC Pipe 4" x 3m','Bomba la PVC 4" x 3m','Piece',['pvc pipe','drain pipe','4 inch'],{tags:['common']}),
  prod(BT20,'plumbing','Elbow 1/2" (pack 10)','Kono la PVC 1/2" (pakiti 10)','Pack',['elbow','kono','fitting','plumbing'],{tags:['common']}),
  prod(BT20,'plumbing','Ball Valve 1/2"','Bomba la Kukatia Maji 1/2"','Piece',['ball valve','valve','maji'],{tags:['common']}),
  prod(BT20,'plumbing','Water Tank 500L','Tanki la Maji 500L','Piece',['water tank','tanki','storage'],{tags:['common']}),
  prod(BT20,'plumbing','Water Tank 1000L','Tanki la Maji 1000L','Piece',['water tank','tanki 1000L'],{tags:['common']}),
  prod(BT20,'plumbing','Submersible Pump 0.5HP','Pampu ya Maji 0.5HP','Piece',['pump','pampu','submersible','maji'],{tags:['common']}),
  prod(BT20,'plumbing','Tap single lever','Bomba la Maji (lever)','Piece',['tap','bomba la maji','faucet'],{tags:['common']}),
  prod(BT20,'plumbing','Shower Head','Kichwa cha Shower','Piece',['shower','kichwa cha shower','bathroom']),
  prod(BT20,'plumbing','Geyser 100L','Heater ya Maji 100L','Piece',['geyser','water heater','maji ya moto'],{tags:['common']}),
  // Electrical
  prod(BT20,'electrical','Cable Wire 1.5mm per metre','Waya wa 1.5mm kwa Mita','Metre',['cable','waya','1.5mm','electrical'],{tags:['common']}),
  prod(BT20,'electrical','Cable Wire 2.5mm per metre','Waya wa 2.5mm kwa Mita','Metre',['cable','waya','2.5mm'],{tags:['common']}),
  prod(BT20,'electrical','Cable Wire 4mm per metre','Waya wa 4mm kwa Mita','Metre',['cable','waya','4mm']),
  prod(BT20,'electrical','MCB 20A','MCB 20A','Piece',['mcb','circuit breaker','20A','umeme'],{tags:['common']}),
  prod(BT20,'electrical','MCB 32A','MCB 32A','Piece',['mcb','circuit breaker','32A'],{tags:['common']}),
  prod(BT20,'electrical','Consumer Unit 8-way','Bodi ya Umeme 8-way','Piece',['consumer unit','distribution board','8-way'],{tags:['common']}),
  prod(BT20,'electrical','Socket (double)','Soketi ya Kuchomeka (double)','Piece',['socket','soketi','power point'],{tags:['common']}),
  prod(BT20,'electrical','Switch (single)','Swichi ya Umeme (single)','Piece',['switch','swichi','light switch'],{tags:['common']}),
  prod(BT20,'electrical','LED Bulb 9W','Balbu ya LED 9W','Piece',['led bulb','balbu','9w','energy saving'],{tags:['common']}),
  prod(BT20,'electrical','LED Bulb 18W','Balbu ya LED 18W','Piece',['led bulb','balbu','18w'],{tags:['common']}),
  prod(BT20,'electrical','Conduit 20mm x 2m','Bomba la Waya 20mm x 2m','Piece',['conduit','bomba la waya','electrical pipe'],{tags:['common']}),
  // Paint & Finishing
  prod(BT20,'paint-finishing','Sadolin Silk Paint 4L white','Rangi ya Sadolin Nyeupe 4L','Tin',['sadolin','paint','rangi','interior'],{brands:['Sadolin'],tags:['common']}),
  prod(BT20,'paint-finishing','Sadolin Silk Paint 4L colour','Rangi ya Sadolin (Rangi) 4L','Tin',['sadolin','paint','rangi ya rangi'],{brands:['Sadolin'],tags:['common']}),
  prod(BT20,'paint-finishing','Crown Emulsion 4L','Rangi ya Crown 4L','Tin',['crown','emulsion','paint','rangi'],{brands:['Crown'],tags:['common']}),
  prod(BT20,'paint-finishing','Roof Paint 4L','Rangi ya Paa 4L','Tin',['roof paint','rangi ya paa'],{tags:['common']}),
  prod(BT20,'paint-finishing','Undercoat 4L','Rangi ya Msingi 4L','Tin',['undercoat','primer','rangi ya msingi'],{tags:['common']}),
  prod(BT20,'paint-finishing','Varnish gloss 1L','Varnish 1L','Tin',['varnish','gloss','wood finish'],{tags:['common']}),
  prod(BT20,'paint-finishing','Paint Brush 2"','Burashi ya Rangi 2"','Piece',['paint brush','burashi','2 inch'],{tags:['common']}),
  prod(BT20,'paint-finishing','Paint Roller set','Seti ya Roller ya Rangi','Set',['paint roller','roller','kupaka rangi'],{tags:['common']}),
  prod(BT20,'paint-finishing','Sandpaper 80 grit (sheet)','Karatasi ya Kusaga 80 grit','Sheet',['sandpaper','grit','surface prep']),
  prod(BT20,'paint-finishing','Masking Tape 25mm','Tepi ya Kufunika 25mm','Roll',['masking tape','tepi','painting'],{tags:['common']}),
  // Roofing
  prod(BT20,'roofing','Roofing Nails 2" 1kg','Misumari ya Bati 2" 1kg','Kg',['roofing nails','misumari ya bati'],{tags:['common']}),
  prod(BT20,'roofing','Box Gutter per metre','Mfereji wa Mvua (kwa mita)','Metre',['gutter','mfereji','rainwater'],{tags:['common']}),
  prod(BT20,'roofing','Downpipe 3m','Bomba la Chini ya Mfereji 3m','Piece',['downpipe','bomba','mvua'],{tags:['common']}),
  prod(BT20,'roofing','Ridge Cap per metre','Kichwa cha Paa kwa Mita','Metre',['ridge cap','paa','roofing'],{tags:['common']}),
  // Tools
  prod(BT20,'tools','Hammer claw','Nyundo ya Msumari','Piece',['hammer','nyundo','tool'],{tags:['common']}),
  prod(BT20,'tools','Hammer sledge','Nyundo Kubwa','Piece',['sledge hammer','nyundo kubwa'],{tags:['common']}),
  prod(BT20,'tools','Spade','Koleo','Piece',['spade','koleo','digging'],{tags:['common']}),
  prod(BT20,'tools','Wheelbarrow','Mkokoteni wa Mikono','Piece',['wheelbarrow','mkokoteni','construction'],{tags:['common']}),
  prod(BT20,'tools','Tape Measure 5m','Mkanda wa Kupima 5m','Piece',['tape measure','mkanda','5m'],{tags:['common']}),
  prod(BT20,'tools','Spirit Level 1m','Kipimo cha Usawa 1m','Piece',['spirit level','level','usawa'],{tags:['common']}),
  prod(BT20,'tools','Pliers combination','Plaia (Kombineshan)','Piece',['pliers','plaia','tool'],{tags:['common']}),
  prod(BT20,'tools','Screwdriver flat','Scrudi (Flat)','Piece',['screwdriver','scrudi','flat'],{tags:['common']}),
  prod(BT20,'tools','Angle Grinder 115mm','Grinda 115mm','Piece',['angle grinder','grinda','cutting tool'],{tags:['common']}),
  prod(BT20,'tools','Hacksaw frame + blades','Msumeno wa Chuma','Set',['hacksaw','msumeno','cutting'],{tags:['common']}),
  // Sanitary Ware
  prod(BT20,'sanitary-ware','Toilet close-coupled','Choo (Close-Coupled)','Piece',['toilet','choo','bathroom'],{tags:['common']}),
  prod(BT20,'sanitary-ware','Washbasin pedestal','Beseni ya Kuosha Mikono','Piece',['washbasin','beseni','bathroom'],{tags:['common']}),
  prod(BT20,'sanitary-ware','Shower Tray','Tray ya Kuoga','Piece',['shower tray','shower','bathroom']),
  prod(BT20,'sanitary-ware','Toilet Seat','Kiti cha Choo','Piece',['toilet seat','kiti cha choo','bathroom'],{tags:['common']}),
  prod(BT20,'sanitary-ware','Floor Drain','Drenaji ya Sakafu','Piece',['floor drain','drenaji','bathroom']),
  // Tiles & Flooring
  prod(BT20,'tiles-flooring','Ceramic Floor Tiles 30x30cm m²','Vigae vya Sakafu 30x30cm m²','m²',['vigae','tiles','ceramic','30x30'],{tags:['common']}),
  prod(BT20,'tiles-flooring','Ceramic Floor Tiles 60x60cm m²','Vigae vya Sakafu 60x60cm m²','m²',['vigae','60x60','large tiles'],{tags:['common']}),
  prod(BT20,'tiles-flooring','Tile Adhesive 20kg','Gundi la Vigae 20kg','Bag',['tile adhesive','gundi la vigae'],{tags:['common']}),
  prod(BT20,'tiles-flooring','Tile Grout 5kg','Saruji ya Vigae 5kg','Bag',['grout','vigae joints'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 21 — TRANSPORTATION & LOGISTICS
// ═══════════════════════════════════════════════════════════════════════════
const BT21 = 'Transportation & Logistics';
const transportCategories: MasterCategory[] = [
  cat(BT21,'Fleet Supplies',          'Vifaa vya Magari',         'local_shipping',0),
  cat(BT21,'Packaging Materials',     'Vifaa vya Kufunga Mizigo', 'box',           1),
  cat(BT21,'Office Supplies Logistics','Vifaa vya Ofisi',         'inventory_2',   2),
];
const transportProducts: MasterProduct[] = [
  prod(BT21,'fleet-supplies','Engine Oil 5W-30 4L','Mafuta ya Injini 5W-30 4L','Can',['engine oil','mafuta ya injini','5W-30','lubricant'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Engine Oil 15W-40 4L','Mafuta ya Injini 15W-40 4L','Can',['engine oil','15W-40','diesel engine'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Gear Oil 90 1L','Mafuta ya Gia 1L','Bottle',['gear oil','mafuta ya gia','gearbox'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Brake Fluid 500ml','Mafuta ya Breki 500ml','Bottle',['brake fluid','breki','DOT3'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Coolant 1L','Kinyoyaji cha Injini 1L','Bottle',['coolant','antifreeze','radiator'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Oil Filter universal','Filta ya Mafuta','Piece',['oil filter','filta','engine'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Air Filter universal','Filta ya Hewa','Piece',['air filter','filta ya hewa'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Fuel Filter','Filta ya Petroli','Piece',['fuel filter','filta ya petrol'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Wiper Blades pair','Wiper za Gari (jozi)','Pair',['wipers','wiper blades','windscreen'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Tyre 185/65 R15','Tairi 185/65 R15','Piece',['tyre','tairi','185','R15'],{tags:['common']}),
  prod(BT21,'fleet-supplies','Battery 55AH 12V','Betri 55AH 12V','Piece',['battery','betri','55AH'],{tags:['common']}),
  prod(BT21,'packaging-materials','Stretch Wrap Roll','Roli ya Stretch Wrap','Roll',['stretch wrap','plastic wrap','packaging'],{tags:['common']}),
  prod(BT21,'packaging-materials','Packing Tape roll','Tepi ya Kufunga (roli)','Roll',['packing tape','tape','packaging'],{tags:['common']}),
  prod(BT21,'packaging-materials','Cardboard Boxes (pack 10)','Masanduku ya Kadibodi (pakiti 10)','Pack',['cardboard','boxes','packaging'],{tags:['common']}),
  prod(BT21,'packaging-materials','Pallet wooden','Pali ya Mbao','Piece',['pallet','storage','logistics'],{tags:['common']}),
  prod(BT21,'packaging-materials','Rope 10m','Kamba 10m','Roll',['kamba','rope','securing load'],{tags:['common']}),
  prod(BT21,'office-supplies-logistics','Waybill Book','Daftari la Waybill','Book',['waybill','delivery note','logistics'],{tags:['common']}),
  prod(BT21,'office-supplies-logistics','A4 Paper Ream','Karatasi A4 (rimi)','Ream',['A4 paper','karatasi','office'],{tags:['common']}),
  prod(BT21,'office-supplies-logistics','Ballpoint Pens Box 50','Kalamu (sanduku 50)','Box',['pens','kalamu','office']),
  prod(BT21,'office-supplies-logistics','Delivery Stamp custom','Muhuri wa Delivery','Piece',['stamp','muhuri','delivery'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 22 — TRAVEL & TOURS
// ═══════════════════════════════════════════════════════════════════════════
const BT22 = 'Travel & Tours';
const travelCategories: MasterCategory[] = [
  cat(BT22,'Travel Essentials',  'Vifaa vya Safari',       'luggage',      0),
  cat(BT22,'Tour Supplies',      'Vifaa vya Utalii',       'travel_explore',1),
  cat(BT22,'Office Supplies (Travel)','Vifaa vya Ofisi',   'inventory_2',  2),
];
const travelProducts: MasterProduct[] = [
  prod(BT22,'travel-essentials','Travel Backpack','Mfuko wa Safari','Piece',['backpack','mfuko wa safari','travel'],{tags:['common']}),
  prod(BT22,'travel-essentials','Suitcase (small)','Sanduku la Safari Dogo','Piece',['suitcase','sanduku','luggage'],{tags:['common']}),
  prod(BT22,'travel-essentials','Suitcase (large)','Sanduku la Safari Kubwa','Piece',['suitcase','luggage large'],{tags:['common']}),
  prod(BT22,'travel-essentials','Travel Pillow','Mto wa Safari','Piece',['travel pillow','mto','comfort']),
  prod(BT22,'travel-essentials','Padlock (luggage)','Kufuli ya Mfuko','Piece',['padlock','kufuli','security'],{tags:['common']}),
  prod(BT22,'travel-essentials','Sunscreen SPF50 50ml','Dawa ya Jua SPF50','Tube',['sunscreen','dawa ya jua','outdoor'],{tags:['common']}),
  prod(BT22,'travel-essentials','Insect Repellent spray','Dawa ya Mbu (Spray)','Can',['insect repellent','mbu','mosquito','spray'],{tags:['common']}),
  prod(BT22,'travel-essentials','First Aid Kit','Kifurushi cha Msaada wa Kwanza','Kit',['first aid','msaada wa kwanza','emergency'],{tags:['common']}),
  prod(BT22,'tour-supplies','Tourist Map Tanzania','Ramani ya Tanzania','Piece',['map','ramani','tourist'],{tags:['common']}),
  prod(BT22,'tour-supplies','Binoculars','Darubini','Piece',['binoculars','darubini','game viewing','safari'],{tags:['common']}),
  prod(BT22,'tour-supplies','Safari Hat','Kofia ya Safari','Piece',['safari hat','kofia','sun protection'],{tags:['common']}),
  prod(BT22,'tour-supplies','Bottled Water 500ml case','Maji ya Chupa (kesi)','Case',['maji','water','bottled water'],{tags:['common']}),
  prod(BT22,'office-supplies-travel','Booking Receipt Book','Daftari la Risiti za Booking','Book',['receipt book','risiti','booking'],{tags:['common']}),
  prod(BT22,'office-supplies-travel','Tour Itinerary Paper A4','Karatasi ya Ratiba','Ream',['itinerary','ratiba','tour program']),
  prod(BT22,'office-supplies-travel','Printer Ink Black','Wino wa Printa Nyeusi','Cartridge',['printer ink','wino','printing'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 23 — HOTEL & ACCOMMODATION
// ═══════════════════════════════════════════════════════════════════════════
const BT23 = 'Hotel & Accommodation';
const hotelCategories: MasterCategory[] = [
  cat(BT23,'Room Supplies',          'Vifaa vya Chumba',          'hotel',        0),
  cat(BT23,'Housekeeping',           'Vifaa vya Usafi',           'cleaning_services',1),
  cat(BT23,'Linen & Bedding',        'Vitanda na Nguo',           'bed',          2),
  cat(BT23,'Restaurant & Bar Supplies','Vifaa vya Mkahawa',       'restaurant',   3),
];
const hotelProducts: MasterProduct[] = [
  prod(BT23,'room-supplies','Soap bars hotel mini box/100','Sabuni Ndogo (sanduku 100)','Box',['hotel soap','sabuni ndogo','guest'],{tags:['common']}),
  prod(BT23,'room-supplies','Shampoo sachets box/100','Shampoo Sachet (sanduku 100)','Box',['shampoo sachet','guest amenities'],{tags:['common']}),
  prod(BT23,'room-supplies','Conditioner sachets box/100','Kondishona Sachet (sanduku 100)','Box',['conditioner sachet','amenities']),
  prod(BT23,'room-supplies','Lotion sachets box/100','Losho Sachet (sanduku 100)','Box',['lotion sachet','body lotion','amenities']),
  prod(BT23,'room-supplies','Toilet Paper double roll pack/12','Karatasi ya Choo (pakiti 12)','Pack',['toilet paper','karatasi ya choo'],{tags:['common']}),
  prod(BT23,'room-supplies','Tissue box pack/12','Tishu (pakiti 12)','Pack',['tissue','tishu','facial tissue'],{tags:['common']}),
  prod(BT23,'room-supplies','Shower Caps pack/100','Vifu vya Kuoga (pakiti 100)','Pack',['shower cap','vifu','guest'],{tags:['common']}),
  prod(BT23,'room-supplies','Toothbrush kit pack/50','Seti ya Mswaki (pakiti 50)','Pack',['toothbrush kit','mswaki','guest amenities'],{tags:['common']}),
  prod(BT23,'room-supplies','Sewing Kit pack/50','Seti ya Kushona (pakiti 50)','Pack',['sewing kit','needle thread','guest service'],{tags:['common']}),
  prod(BT23,'room-supplies','Shoe Shine Cloth pack/50','Kitambaa cha Viatu (pakiti 50)','Pack',['shoe shine','viatu','polish'],{tags:['common']}),
  prod(BT23,'linen-bedding','Single Sheet pair','Shuka la Kitanda Kimoja (jozi)','Pair',['sheet','shuka','linen'],{tags:['common']}),
  prod(BT23,'linen-bedding','Double Sheet pair','Shuka la Kitanda Kikubwa (jozi)','Pair',['double sheet','shuka','linen'],{tags:['common']}),
  prod(BT23,'linen-bedding','Pillow hollow fibre','Mto wa Nyuzi','Piece',['pillow','mto','bedding'],{tags:['common']}),
  prod(BT23,'linen-bedding','Pillow Case pair','Foronya (jozi)','Pair',['pillow case','foronya'],{tags:['common']}),
  prod(BT23,'linen-bedding','Duvet Single','Blanketi ya Duvet (Single)','Piece',['duvet','blanketi','bedding'],{tags:['common']}),
  prod(BT23,'linen-bedding','Duvet Double','Blanketi ya Duvet (Double)','Piece',['duvet double','blanketi'],{tags:['common']}),
  prod(BT23,'linen-bedding','Bath Towel','Taulo la Kuogea','Piece',['bath towel','taulo','linen'],{tags:['common']}),
  prod(BT23,'linen-bedding','Hand Towel','Taulo la Mikono','Piece',['hand towel','taulo la mikono'],{tags:['common']}),
  prod(BT23,'linen-bedding','Face Cloth','Kitambaa cha Uso','Piece',['face cloth','kitambaa'],{tags:['common']}),
  prod(BT23,'linen-bedding','Bath Mat','Mat ya Bafu','Piece',['bath mat','mat ya bafu'],{tags:['common']}),
  prod(BT23,'housekeeping','Floor Cleaner 5L','Dawa ya Sakafu 5L','Can',['floor cleaner','dawa ya sakafu'],{tags:['common']}),
  prod(BT23,'housekeeping','Bathroom Cleaner 5L','Dawa ya Choo 5L','Can',['bathroom cleaner','dawa ya choo'],{tags:['common']}),
  prod(BT23,'housekeeping','Glass Cleaner 5L','Dawa ya Kioo 5L','Can',['glass cleaner','dawa ya kioo','windows'],{tags:['common']}),
  prod(BT23,'housekeeping','Bleach 5L','Blechi 5L','Can',['bleach','blechi','disinfect'],{tags:['common']}),
  prod(BT23,'housekeeping','Mop & Bucket set','Mop na Ndoo','Set',['mop','ndoo','cleaning'],{tags:['common']}),
  prod(BT23,'housekeeping','Laundry Detergent 5kg','Unga wa Kufulia 5kg','Bag',['laundry','detergent','unga wa kufulia'],{tags:['common']}),
  prod(BT23,'housekeeping','Fabric Softener 5L','Laini ya Nguo 5L','Can',['fabric softener','laini','comfort'],{tags:['common']}),
  prod(BT23,'restaurant-bar-supplies','Disposable Cups pack/50','Vikombe vya Plastiki (pakiti 50)','Pack',['disposable cups','vikombe'],{tags:['common']}),
  prod(BT23,'restaurant-bar-supplies','Napkins pack/100','Napkini (pakiti 100)','Pack',['napkins','napkini','restaurant'],{tags:['common']}),
  prod(BT23,'restaurant-bar-supplies','Cooking Oil 5L','Mafuta ya Kupikia 5L','Jerrycan',['cooking oil','mafuta'],{tags:['common']}),
  prod(BT23,'restaurant-bar-supplies','Tea Bags Ketepa box/100','Chai Ketepa (sanduku 100)','Box',['chai','tea bags','ketepa'],{tags:['common']}),
  prod(BT23,'restaurant-bar-supplies','Sugar 5kg','Sukari 5kg','Bag',['sukari','sugar','restaurant'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 24 — PHARMACY & HEALTHCARE
// ═══════════════════════════════════════════════════════════════════════════
const BT24 = 'Pharmacy & Healthcare';
const pharmacyCategories: MasterCategory[] = [
  cat(BT24,'Painkillers & Antipyretics','Dawa za Maumivu na Homa',    'medication',     0),
  cat(BT24,'Antibiotics',              'Antibiotiki',                  'vaccines',       1),
  cat(BT24,'Anti-malarials',           'Dawa za Malaria',              'bug_report',     2),
  cat(BT24,'GI & Stomach',             'Dawa za Tumbo',                'gastroenterology',3),
  cat(BT24,'Respiratory',              'Dawa za Kupumua',              'air',            4),
  cat(BT24,'Vitamins & Supplements',   'Vitamini na Virutubisho',      'nutrition',      5),
  cat(BT24,'Diabetes Management',      'Dawa za Kisukari',             'monitor_heart',  6),
  cat(BT24,'Cardiovascular',           'Dawa za Moyo na Shinikizo',    'favorite',       7),
  cat(BT24,'Antifungals & Antiparasitics','Dawa za Ugonjwa wa Kuvu',  'science',        8),
  cat(BT24,'Skincare Medical',         'Utunzaji wa Ngozi (Dawa)',     'face',           9),
  cat(BT24,'Eye & Ear',               'Dawa za Macho na Masikio',     'visibility',     10),
  cat(BT24,'Medical Supplies',         'Vifaa vya Matibabu',           'medical_services',11),
  cat(BT24,'Family Planning',          'Uzazi wa Mpango',              'family_restroom',12),
  cat(BT24,'HIV & STI',               'VVU na Magonjwa ya Zinaa',     'health_and_safety',13),
];
const pharmacyProducts: MasterProduct[] = [
  // Painkillers
  prod(BT24,'painkillers-antipyretics','Paracetamol 500mg tabs box/10','Paracetamol 500mg (vidonge 10)','Box',['paracetamol','panadol','maumivu','homa','fever'],{generic:'Acetaminophen',brands:['Panadol','Calpol'],tags:['common']}),
  prod(BT24,'painkillers-antipyretics','Paracetamol 250mg syrup 100ml','Paracetamol Syrup 250mg 100ml','Bottle',['paracetamol syrup','watoto','homa','fever'],{generic:'Acetaminophen',brands:['Calpol'],tags:['common']}),
  prod(BT24,'painkillers-antipyretics','Ibuprofen 400mg tabs box/10','Ibuprofen 400mg (vidonge 10)','Box',['ibuprofen','maumivu','uvimbe','brufen'],{generic:'Ibuprofen',brands:['Brufen'],tags:['common']}),
  prod(BT24,'painkillers-antipyretics','Diclofenac 50mg tabs box/10','Diclofenac 50mg (vidonge 10)','Box',['diclofenac','voltaren','maumivu','arthritis'],{generic:'Diclofenac',brands:['Voltaren'],tags:['common']}),
  prod(BT24,'painkillers-antipyretics','Aspirin 75mg tabs box/28','Aspirin 75mg (vidonge 28)','Box',['aspirin','blood thinner','moyo','damu'],{generic:'Aspirin',tags:['common']}),
  prod(BT24,'painkillers-antipyretics','Tramadol 50mg caps box/10','Tramadol 50mg (kapsuli 10)','Box',['tramadol','maumivu makali','pain killer'],{generic:'Tramadol',rx:true,tags:['common']}),
  prod(BT24,'painkillers-antipyretics','Panadol Extra 500mg','Panadol Extra 500mg','Box',['panadol extra','paracetamol','caffeine','maumivu'],{brands:['Panadol'],tags:['common']}),
  prod(BT24,'painkillers-antipyretics','Calpol 120mg/5ml syrup 100ml','Calpol Syrup 120mg 100ml','Bottle',['calpol','watoto','homa','fever syrup'],{brands:['Calpol'],tags:['common']}),
  // Antibiotics (all Rx)
  prod(BT24,'antibiotics','Amoxicillin 250mg caps box/10','Amoxicillin 250mg (kapsuli 10)','Box',['amoxicillin','antibiotiki','infection','maambukizi'],{generic:'Amoxicillin',rx:true,tags:['common']}),
  prod(BT24,'antibiotics','Amoxicillin 500mg caps box/10','Amoxicillin 500mg (kapsuli 10)','Box',['amoxicillin 500','antibiotiki','infection'],{generic:'Amoxicillin',rx:true,tags:['common']}),
  prod(BT24,'antibiotics','Amoxicillin syrup 125mg/5ml','Amoxicillin Syrup 125mg','Bottle',['amoxicillin syrup','watoto','antibiotiki'],{generic:'Amoxicillin',rx:true,tags:['common']}),
  prod(BT24,'antibiotics','Metronidazole 200mg tabs','Metronidazole 200mg (vidonge)','Box',['metronidazole','flagyl','tumbo','amoeba'],{generic:'Metronidazole',brands:['Flagyl'],rx:true,tags:['common']}),
  prod(BT24,'antibiotics','Metronidazole 400mg tabs','Metronidazole 400mg (vidonge)','Box',['metronidazole 400','flagyl','parasites'],{generic:'Metronidazole',rx:true,tags:['common']}),
  prod(BT24,'antibiotics','Ciprofloxacin 500mg tabs box/10','Ciprofloxacin 500mg (vidonge 10)','Box',['ciprofloxacin','cipro','UTI','mkojo'],{generic:'Ciprofloxacin',rx:true,tags:['common']}),
  prod(BT24,'antibiotics','Doxycycline 100mg caps','Doxycycline 100mg (kapsuli)','Box',['doxycycline','antibiotiki','chlamydia'],{generic:'Doxycycline',rx:true,tags:['common']}),
  prod(BT24,'antibiotics','Erythromycin 500mg tabs','Erythromycin 500mg (vidonge)','Box',['erythromycin','macrolide','strep'],{generic:'Erythromycin',rx:true}),
  prod(BT24,'antibiotics','Co-trimoxazole 480mg tabs','Co-trimoxazole 480mg (vidonge)','Box',['cotrimoxazole','bactrim','UTI','septra'],{generic:'Sulfamethoxazole/Trimethoprim',brands:['Bactrim'],rx:true,tags:['common']}),
  prod(BT24,'antibiotics','Azithromycin 250mg tabs','Azithromycin 250mg (vidonge)','Box',['azithromycin','zithromax','antibiotiki'],{generic:'Azithromycin',rx:true,tags:['common']}),
  prod(BT24,'antibiotics','Cloxacillin 250mg caps','Cloxacillin 250mg (kapsuli)','Box',['cloxacillin','skin infection','staphylococcus'],{generic:'Cloxacillin',rx:true}),
  // Anti-malarials
  prod(BT24,'anti-malarials','Artemether-Lumefantrine 6-dose (Coartem)','Coartem (dozi 6)','Pack',['malaria','coartem','ALu','artemether','lumefantrine'],{generic:'Artemether/Lumefantrine',brands:['Coartem'],rx:true,tags:['common']}),
  prod(BT24,'anti-malarials','ALu 4-dose pediatric','Coartem Watoto (dozi 4)','Pack',['malaria watoto','pediatric','ALu','coartem'],{generic:'Artemether/Lumefantrine',rx:true,tags:['common']}),
  prod(BT24,'anti-malarials','Quinine 300mg tabs','Quinine 300mg (vidonge)','Box',['quinine','malaria','kina'],{generic:'Quinine',rx:true,tags:['common']}),
  prod(BT24,'anti-malarials','SP Fansidar','SP (Fansidar)','Pack',['fansidar','SP','malaria','prophylaxis'],{generic:'Sulfadoxine/Pyrimethamine',brands:['Fansidar'],rx:true,tags:['common']}),
  prod(BT24,'anti-malarials','Chloroquine 250mg tabs','Chloroquine 250mg (vidonge)','Box',['chloroquine','malaria','prophylaxis'],{generic:'Chloroquine',rx:true}),
  // GI & Stomach
  prod(BT24,'gi-stomach','Omeprazole 20mg caps','Omeprazole 20mg (kapsuli)','Box',['omeprazole','acidity','tumbo','gastric'],{generic:'Omeprazole',tags:['common']}),
  prod(BT24,'gi-stomach','Oral Rehydration Salts (ORS) sachet','ORS Sachet','Sachet',['ORS','kuhara','maji','rehydration','diarrhoea'],{generic:'ORS',tags:['common']}),
  prod(BT24,'gi-stomach','Loperamide 2mg caps','Loperamide 2mg (kapsuli)','Box',['loperamide','imodium','kuhara','diarrhoea'],{generic:'Loperamide',brands:['Imodium'],tags:['common']}),
  prod(BT24,'gi-stomach','Metoclopramide 10mg tabs','Metoclopramide 10mg (vidonge)','Box',['metoclopramide','kichefuchefu','nausea','vomiting'],{generic:'Metoclopramide',tags:['common']}),
  prod(BT24,'gi-stomach','Antacid suspension 200ml','Antasidi Syrup 200ml','Bottle',['antacid','antasidi','heartburn','tumbo'],{tags:['common']}),
  prod(BT24,'gi-stomach','Buscopan 10mg tabs','Buscopan 10mg (vidonge)','Box',['buscopan','stomach cramps','maumivu ya tumbo'],{generic:'Hyoscine',brands:['Buscopan'],tags:['common']}),
  prod(BT24,'gi-stomach','Albendazole 400mg tab','Albendazole 400mg (kidonge)','Tablet',['albendazole','minyoo','worms','deworming'],{generic:'Albendazole',tags:['common']}),
  prod(BT24,'gi-stomach','Mebendazole 500mg tab','Mebendazole 500mg (kidonge)','Tablet',['mebendazole','vermox','minyoo','worms'],{generic:'Mebendazole',brands:['Vermox'],tags:['common']}),
  // Respiratory
  prod(BT24,'respiratory','Salbutamol Inhaler 100mcg (Ventolin)','Punga la Pumzi 100mcg','Inhaler',['salbutamol','ventolin','asthma','pumzi'],{generic:'Salbutamol',brands:['Ventolin'],rx:true,tags:['common']}),
  prod(BT24,'respiratory','Ambroxol syrup 30mg/5ml 100ml','Ambroxol Syrup 100ml','Bottle',['ambroxol','kikohozi','cough','expectorant'],{generic:'Ambroxol',tags:['common']}),
  prod(BT24,'respiratory','Loratadine 10mg tabs','Loratadine 10mg (vidonge)','Box',['loratadine','allergy','mzio','antihistamine'],{generic:'Loratadine',tags:['common']}),
  prod(BT24,'respiratory','Cetirizine 10mg tabs','Cetirizine 10mg (vidonge)','Box',['cetirizine','allergy','mzio','antihistamine'],{generic:'Cetirizine',tags:['common']}),
  prod(BT24,'respiratory','Prednisolone 5mg tabs','Prednisolone 5mg (vidonge)','Box',['prednisolone','steroid','asthma','allergy'],{generic:'Prednisolone',rx:true,tags:['common']}),
  prod(BT24,'respiratory','Nasal Drops saline 10ml','Tone za Pua 10ml','Bottle',['nasal drops','pua','saline','decongestant'],{tags:['common']}),
  prod(BT24,'respiratory','Dextromethorphan syrup 100ml','Syrup ya Kikohozi 100ml','Bottle',['cough syrup','kikohozi','dextromethorphan'],{tags:['common']}),
  // Vitamins & Supplements
  prod(BT24,'vitamins-supplements','Vitamin C 500mg tabs box/10','Vitamini C 500mg (vidonge 10)','Box',['vitamin c','vitamini','kinga','immunity'],{tags:['common']}),
  prod(BT24,'vitamins-supplements','Vitamin B Complex tabs box/10','Vitamini B Complex (vidonge 10)','Box',['vitamin b','b complex','vitamini','nguvu'],{tags:['common']}),
  prod(BT24,'vitamins-supplements','Folic Acid 5mg tabs','Folic Acid 5mg (vidonge)','Box',['folic acid','folate','mimba','ujauzito'],{tags:['common']}),
  prod(BT24,'vitamins-supplements','Ferrous Sulphate 200mg tabs','Ferrous Sulphate 200mg (vidonge)','Box',['iron tablets','chuma','damu','anaemia'],{tags:['common']}),
  prod(BT24,'vitamins-supplements','Zinc 20mg tabs','Zinc 20mg (vidonge)','Box',['zinc','zinki','kinga','immunity'],{tags:['common']}),
  prod(BT24,'vitamins-supplements','Multi-vitamin tabs','Vitamini Mchanganyiko (vidonge)','Box',['multivitamin','vitamini','nguvu','afya'],{tags:['common']}),
  prod(BT24,'vitamins-supplements','Omega-3 Fish Oil caps','Omega-3 (kapsuli)','Box',['omega 3','fish oil','moyo','cholesterol']),
  prod(BT24,'vitamins-supplements','Calcium + D3 tabs','Calcium na D3 (vidonge)','Box',['calcium','vitamin d','mifupa','bones'],{tags:['common']}),
  prod(BT24,'vitamins-supplements','Iron Syrup 200ml (pediatric)','Syrup ya Chuma 200ml (watoto)','Bottle',['iron syrup','damu','anaemia watoto'],{tags:['common']}),
  // Diabetes (Rx)
  prod(BT24,'diabetes-management','Metformin 500mg tabs','Metformin 500mg (vidonge)','Box',['metformin','kisukari','diabetes','glucose'],{generic:'Metformin',rx:true,tags:['common']}),
  prod(BT24,'diabetes-management','Metformin 850mg tabs','Metformin 850mg (vidonge)','Box',['metformin 850','kisukari','diabetes'],{generic:'Metformin',rx:true,tags:['common']}),
  prod(BT24,'diabetes-management','Glibenclamide 5mg tabs','Glibenclamide 5mg (vidonge)','Box',['glibenclamide','kisukari','diabetes'],{generic:'Glibenclamide',rx:true,tags:['common']}),
  prod(BT24,'diabetes-management','Insulin Regular 10ml vial','Insulini ya Kawaida 10ml','Vial',['insulin','insulini','diabetes','injection'],{generic:'Regular Insulin',rx:true,cold:true,tags:['common']}),
  prod(BT24,'diabetes-management','Insulin NPH 10ml vial','Insulini ya NPH 10ml','Vial',['insulin NPH','insulini','long acting'],{generic:'NPH Insulin',rx:true,cold:true,tags:['common']}),
  prod(BT24,'diabetes-management','Glucometer Test Strips box/25','Vijiti vya Kupima Sukari (sanduku 25)','Box',['glucometer strips','sukari','blood sugar','test strips'],{tags:['common']}),
  prod(BT24,'diabetes-management','Lancets box/100','Sindano Ndogo za Glucometer (sanduku 100)','Box',['lancets','sindano','glucose test'],{tags:['common']}),
  prod(BT24,'diabetes-management','Glucometer device','Kifaa cha Kupima Sukari','Piece',['glucometer','kipima sukari','diabetes device'],{tags:['common']}),
  prod(BT24,'diabetes-management','Insulin Syringes 1ml box/10','Sindano za Insulini 1ml (sanduku 10)','Box',['insulin syringe','sindano ya insulini'],{tags:['common']}),
  // Medical Supplies
  prod(BT24,'medical-supplies','Examination Gloves Latex M box/100','Glavu za Uchunguzi Latex M (sanduku 100)','Box',['gloves','glavu','latex','medical'],{tags:['common']}),
  prod(BT24,'medical-supplies','Examination Gloves Nitrile M box/100','Glavu za Nitrile M (sanduku 100)','Box',['nitrile gloves','glavu','medical'],{tags:['common']}),
  prod(BT24,'medical-supplies','Syringes 2ml box/10','Sindano 2ml (sanduku 10)','Box',['syringes','sindano','2ml','injection'],{tags:['common']}),
  prod(BT24,'medical-supplies','Syringes 5ml box/10','Sindano 5ml (sanduku 10)','Box',['syringes','sindano','5ml'],{tags:['common']}),
  prod(BT24,'medical-supplies','IV Cannula 18G box/10','IV Cannula 18G (sanduku 10)','Box',['cannula','IV','drip','injection'],{tags:['common']}),
  prod(BT24,'medical-supplies','Gauze 10x10cm pack/5','Gauzi 10x10cm (pakiti 5)','Pack',['gauze','gauzi','wound','dressing'],{tags:['common']}),
  prod(BT24,'medical-supplies','Bandage crepe 5cm','Bendeji 5cm','Roll',['bandage','bendeji','wound','dressing'],{tags:['common']}),
  prod(BT24,'medical-supplies','Cotton Wool 100g','Pamba 100g','Pack',['cotton wool','pamba','wound care'],{tags:['common']}),
  prod(BT24,'medical-supplies','Plaster Elastoplast assorted','Plasta (mchanganyiko)','Pack',['plaster','elastoplast','wound','dressing'],{tags:['common']}),
  prod(BT24,'medical-supplies','Digital Thermometer','Kipima Joto','Piece',['thermometer','kipima joto','homa','fever'],{tags:['common']}),
  prod(BT24,'medical-supplies','Blood Pressure Monitor digital','Kipima Shinikizo la Damu','Piece',['blood pressure','BP machine','shinikizo'],{tags:['common']}),
  prod(BT24,'medical-supplies','Malaria RDT Kit','Kipimo cha Malaria','Piece',['malaria RDT','malaria test','diagnostic'],{tags:['common']}),
  prod(BT24,'medical-supplies','Pregnancy Test Kit','Kipimo cha Ujauzito','Piece',['pregnancy test','mimba','ujauzito'],{tags:['common']}),
  prod(BT24,'medical-supplies','Urine Test Strips box/50','Vijiti vya Kupima Mkojo (sanduku 50)','Box',['urine test','mkojo','urinalysis'],{tags:['common']}),
  // Family Planning
  prod(BT24,'family-planning','Condoms box/12','Kondomu (sanduku 12)','Box',['condoms','mpira','uzazi wa mpango','family planning'],{tags:['common']}),
  prod(BT24,'family-planning','Oral Contraceptive Pills (COC)','Vidonge vya Uzazi wa Mpango','Pack',['contraceptive','pill','uzazi wa mpango','family planning'],{rx:true,tags:['common']}),
  prod(BT24,'family-planning','Emergency Contraceptive Pill','Kidonge cha Dharura','Tablet',['emergency pill','morning after','uzazi wa mpango'],{rx:true,tags:['common']}),
  prod(BT24,'family-planning','Pregnancy Test Kit (strip)','Kipimo cha Ujauzito (fimbo)','Piece',['pregnancy test','mimba test','strip'],{tags:['common']}),
  // HIV & STI
  prod(BT24,'hiv-sti','HIV Rapid Test Kit','Kipimo cha Haraka cha VVU','Kit',['HIV test','VVU test','HIV rapid','diagnostic'],{tags:['common']}),
  prod(BT24,'hiv-sti','Doxycycline 100mg (STI treatment)','Doxycycline 100mg','Box',['doxycycline','STI','chlamydia','gonorrhoea'],{generic:'Doxycycline',rx:true,tags:['common']}),
  prod(BT24,'hiv-sti','Acyclovir 200mg tabs','Acyclovir 200mg (vidonge)','Box',['acyclovir','herpes','virusi','antiviral'],{generic:'Acyclovir',rx:true,tags:['common']}),
  prod(BT24,'hiv-sti','Condoms box/12 (premium)','Kondomu Bora (sanduku 12)','Box',['condoms','prevention','HIV','VVU'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 25 — CLINIC & LABORATORY
// ═══════════════════════════════════════════════════════════════════════════
const BT25 = 'Clinic & Laboratory';
const clinicCategories: MasterCategory[] = [
  cat(BT25,'Diagnostic Supplies',  'Vifaa vya Uchunguzi',    'biotech',      0),
  cat(BT25,'Medical Consumables',  'Vifaa vya Matibabu',     'medical_services',1),
  cat(BT25,'Lab Reagents',         'Kemikali za Maabara',    'science',      2),
  cat(BT25,'Clinic Medicines',     'Dawa za Kliniki',        'medication',   3),
];
const clinicProducts: MasterProduct[] = [
  prod(BT25,'diagnostic-supplies','Malaria RDT Kit (box/25)','Vipimo vya Malaria (sanduku 25)','Box',['malaria RDT','malaria test','diagnostic','kipimo'],{tags:['common']}),
  prod(BT25,'diagnostic-supplies','HIV Rapid Test (box/25)','Vipimo vya VVU (sanduku 25)','Box',['HIV test','VVU','kipimo','rapid test'],{tags:['common']}),
  prod(BT25,'diagnostic-supplies','Pregnancy Test Strips (box/50)','Vipimo vya Ujauzito (sanduku 50)','Box',['pregnancy test','mimba','ujauzito'],{tags:['common']}),
  prod(BT25,'diagnostic-supplies','Blood Glucose Test Strips (box/50)','Vijiti vya Sukari (sanduku 50)','Box',['glucose strips','sukari','diabetes','kipimo'],{tags:['common']}),
  prod(BT25,'diagnostic-supplies','Urine Dipstick box/100','Vijiti vya Mkojo (sanduku 100)','Box',['urine test','mkojo','urinalysis'],{tags:['common']}),
  prod(BT25,'diagnostic-supplies','Typhoid Test Kit box/25','Kipimo cha Typhoid (sanduku 25)','Box',['typhoid test','homa ya matumbo','diagnostic'],{tags:['common']}),
  prod(BT25,'diagnostic-supplies','Hepatitis B RDT box/25','Kipimo cha Hepatitis B','Box',['hepatitis B','ini','jaundice','kipimo'],{tags:['common']}),
  prod(BT25,'medical-consumables','Examination Gloves box/100','Glavu za Uchunguzi (sanduku 100)','Box',['gloves','glavu','examination','medical'],{tags:['common']}),
  prod(BT25,'medical-consumables','Syringes 2ml box/100','Sindano 2ml (sanduku 100)','Box',['syringes','sindano','injection'],{tags:['common']}),
  prod(BT25,'medical-consumables','Syringes 5ml box/100','Sindano 5ml (sanduku 100)','Box',['syringes','sindano','5ml'],{tags:['common']}),
  prod(BT25,'medical-consumables','IV Giving Set box/10','IV Drip Set (sanduku 10)','Box',['IV drip','drip set','infusion'],{tags:['common']}),
  prod(BT25,'medical-consumables','IV Cannula 18G box/50','IV Cannula 18G (sanduku 50)','Box',['cannula','IV line','venous access'],{tags:['common']}),
  prod(BT25,'medical-consumables','Gauze 10x10cm box/100','Gauzi 10x10cm (sanduku 100)','Box',['gauze','gauzi','wound dressing'],{tags:['common']}),
  prod(BT25,'medical-consumables','Cotton Wool 500g','Pamba 500g','Pack',['cotton wool','pamba','antiseptic'],{tags:['common']}),
  prod(BT25,'medical-consumables','Spirit 70% 500ml','Spiriti 70% 500ml','Bottle',['spirit','spiriti','antiseptic','alcohol'],{tags:['common']}),
  prod(BT25,'medical-consumables','Hydrogen Peroxide 3% 500ml','Oksijeni ya Maji 3% 500ml','Bottle',['hydrogen peroxide','antiseptic','wound care'],{tags:['common']}),
  prod(BT25,'lab-reagents','Giemsa Stain 500ml','Rangi ya Giemsa 500ml','Bottle',['giemsa','malaria stain','lab reagent'],{tags:['common']}),
  prod(BT25,'lab-reagents','Leishman Stain 500ml','Rangi ya Leishman 500ml','Bottle',['leishman','blood smear','lab'],{tags:['common']}),
  prod(BT25,'lab-reagents','Ziehl-Neelsen Stain kit','Rangi ya ZN','Kit',['ZN stain','TB','AFB','tuberculosis'],{tags:['common']}),
  prod(BT25,'lab-reagents','EDTA Blood Collection Tubes box/100','Mirija ya Damu EDTA (sanduku 100)','Box',['blood tubes','EDTA','sample collection'],{tags:['common']}),
  prod(BT25,'clinic-medicines','Amoxicillin 500mg caps','Amoxicillin 500mg (kapsuli)','Box',['amoxicillin','antibiotiki','infection'],{generic:'Amoxicillin',rx:true,tags:['common']}),
  prod(BT25,'clinic-medicines','Paracetamol 500mg tabs','Paracetamol 500mg (vidonge)','Box',['paracetamol','homa','maumivu'],{generic:'Acetaminophen',tags:['common']}),
  prod(BT25,'clinic-medicines','Artemether-Lumefantrine (Coartem)','Coartem (dozi 6)','Pack',['coartem','malaria','artemether'],{generic:'Artemether/Lumefantrine',rx:true,tags:['common']}),
  prod(BT25,'clinic-medicines','ORS sachets','ORS Sachet','Pack',['ORS','rehydration','kuhara','diarrhoea'],{generic:'ORS',tags:['common']}),
  prod(BT25,'clinic-medicines','Metronidazole 400mg tabs','Metronidazole 400mg (vidonge)','Box',['metronidazole','flagyl','tumbo'],{generic:'Metronidazole',rx:true,tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 26 — EDUCATION & TRAINING
// ═══════════════════════════════════════════════════════════════════════════
const BT26 = 'Education & Training';
const educationCategories: MasterCategory[] = [
  cat(BT26,'Stationery',        'Vifaa vya Ofisi na Shule','edit',          0),
  cat(BT26,'Teaching Aids',     'Vifaa vya Kufundishia',   'school',        1),
  cat(BT26,'Technology (Edu)', 'Teknolojia ya Elimu',     'computer',      2),
];
const educationProducts: MasterProduct[] = [
  prod(BT26,'stationery','A4 Paper Ream 80gsm','Karatasi A4 Rimi','Ream',['A4 paper','karatasi','ream','office'],{tags:['common']}),
  prod(BT26,'stationery','Exercise Books pack/10','Daftari za Shule (pakiti 10)','Pack',['exercise books','daftari','shule'],{tags:['common']}),
  prod(BT26,'stationery','Ballpoint Pens box/50','Kalamu (sanduku 50)','Box',['pens','kalamu','biro'],{tags:['common']}),
  prod(BT26,'stationery','Markers whiteboard pack/5','Kalamu za Ubao (pakiti 5)','Pack',['markers','ubao','whiteboard'],{tags:['common']}),
  prod(BT26,'stationery','Pencils box/12','Penseli (sanduku 12)','Box',['pencils','penseli','drawing'],{tags:['common']}),
  prod(BT26,'stationery','Ruler 30cm pack/10','Rula 30cm (pakiti 10)','Pack',['ruler','rula','measurement'],{tags:['common']}),
  prod(BT26,'stationery','Eraser pack/10','Raba (pakiti 10)','Pack',['eraser','raba','pencil eraser'],{tags:['common']}),
  prod(BT26,'stationery','Stapler + staples set','Stapla na Vipande','Set',['stapler','stapla','binding'],{tags:['common']}),
  prod(BT26,'stationery','Scissors pack/10','Mkasi (pakiti 10)','Pack',['scissors','mkasi','cutting'],{tags:['common']}),
  prod(BT26,'stationery','Correction Fluid Tipp-Ex','Tipp-Ex','Bottle',['tipp-ex','correction','white out'],{tags:['common']}),
  prod(BT26,'stationery','Folders A4 pack/10','Folda A4 (pakiti 10)','Pack',['folders','folda','filing'],{tags:['common']}),
  prod(BT26,'teaching-aids','Whiteboard 90x120cm','Ubao Mweupe 90x120cm','Piece',['whiteboard','ubao','classroom'],{tags:['common']}),
  prod(BT26,'teaching-aids','Whiteboard Eraser','Kifutio cha Ubao','Piece',['eraser','ubao','whiteboard'],{tags:['common']}),
  prod(BT26,'teaching-aids','Globe 30cm','Dunia 30cm','Piece',['globe','dunia','geography'],{tags:['common']}),
  prod(BT26,'teaching-aids','Chart Paper pack/10','Karatasi za Chati (pakiti 10)','Pack',['chart paper','chati','teaching'],{tags:['common']}),
  prod(BT26,'teaching-aids','Drawing Pins box/100','Pini za Kupachika (sanduku 100)','Box',['drawing pins','pini','noticeboard'],{tags:['common']}),
  prod(BT26,'technology-edu','Projector LCD','Projekta ya LCD','Piece',['projector','projekta','presentation'],{tags:['common']}),
  prod(BT26,'technology-edu','Projector Screen roll-up','Skrini ya Projekta','Piece',['projector screen','skrini'],{tags:['common']}),
  prod(BT26,'technology-edu','Laptop computer','Laptop ya Kompyuta','Piece',['laptop','kompyuta','computer'],{tags:['common']}),
  prod(BT26,'technology-edu','HDMI Cable 3m','Kebo ya HDMI 3m','Piece',['HDMI','cable','projection'],{tags:['common']}),
  prod(BT26,'technology-edu','Printer A4 inkjet','Printa ya Kawaida','Piece',['printer','printa','inkjet'],{tags:['common']}),
  prod(BT26,'technology-edu','Printer Ink Black','Wino wa Printa Nyeusi','Cartridge',['ink','wino','printer'],{tags:['common']}),
  prod(BT26,'technology-edu','USB Flash Drive 32GB','USB 32GB','Piece',['usb','flash drive','storage'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 27 — REAL ESTATE
// ═══════════════════════════════════════════════════════════════════════════
const BT27 = 'Real Estate';
const realEstateCategories: MasterCategory[] = [
  cat(BT27,'Office Supplies',     'Vifaa vya Ofisi',         'inventory_2',  0),
  cat(BT27,'Marketing Materials', 'Vifaa vya Masoko',        'campaign',     1),
  cat(BT27,'Property Maintenance','Matengenezo ya Mali',     'home_repair_service',2),
];
const realEstateProducts: MasterProduct[] = [
  prod(BT27,'office-supplies','A4 Paper Ream','Karatasi A4','Ream',['karatasi','paper','office','A4'],{tags:['common']}),
  prod(BT27,'office-supplies','Folders A4 pack/10','Folda A4 (pakiti 10)','Pack',['folders','folda','filing'],{tags:['common']}),
  prod(BT27,'office-supplies','Ballpoint Pens box/50','Kalamu (sanduku 50)','Box',['pens','kalamu','office'],{tags:['common']}),
  prod(BT27,'office-supplies','Stamp and Ink Pad','Muhuri na Wino','Set',['stamp','muhuri','official'],{tags:['common']}),
  prod(BT27,'office-supplies','Printer A4 Laser','Printa ya Laser A4','Piece',['printer','laser','office'],{tags:['common']}),
  prod(BT27,'office-supplies','Printer Toner Black','Wino wa Printa Toner','Cartridge',['toner','printer toner','laser'],{tags:['common']}),
  prod(BT27,'marketing-materials','For Sale Rent Boards','Bango la Kuuza/Kukodisha','Piece',['signboard','bango','for sale','property'],{tags:['common']}),
  prod(BT27,'marketing-materials','Business Cards box/500','Kadi za Biashara (sanduku 500)','Box',['business cards','kadi','marketing'],{tags:['common']}),
  prod(BT27,'marketing-materials','Leaflets printing A5','Vijitabu vya Matangazo','Pack',['leaflets','flyers','marketing'],{tags:['common']}),
  prod(BT27,'marketing-materials','Brochures A4 fold','Vipeperushi vya Biashara','Pack',['brochures','vipeperushi','property listing'],{tags:['common']}),
  prod(BT27,'property-maintenance','Paint Sadolin Silk 4L','Rangi ya Sadolin 4L','Tin',['paint','rangi','property'],{brands:['Sadolin'],tags:['common']}),
  prod(BT27,'property-maintenance','Floor Tiles 60x60cm','Vigae vya Sakafu 60x60cm','m²',['tiles','vigae','flooring'],{tags:['common']}),
  prod(BT27,'property-maintenance','LED Bulb 9W','Balbu ya LED 9W','Piece',['LED bulb','balbu','lighting'],{tags:['common']}),
  prod(BT27,'property-maintenance','Padlock security','Kufuli ya Usalama','Piece',['padlock','kufuli','security'],{tags:['common']}),
  prod(BT27,'property-maintenance','Electrical Socket double','Soketi ya Kuchomeka','Piece',['socket','soketi','electrical'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 28 — FINANCIAL SERVICES
// ═══════════════════════════════════════════════════════════════════════════
const BT28 = 'Financial Services';
const financeCategories: MasterCategory[] = [
  cat(BT28,'Office Consumables',   'Vifaa vya Ofisi',        'inventory_2',  0),
  cat(BT28,'Cash Handling',        'Vifaa vya Fedha',        'payments',     1),
  cat(BT28,'Security',             'Usalama',                'security',     2),
];
const financeProducts: MasterProduct[] = [
  prod(BT28,'office-consumables','A4 Paper Ream','Karatasi A4','Ream',['A4','karatasi','office'],{tags:['common']}),
  prod(BT28,'office-consumables','Receipt Books NCR pack/10','Daftari za Risiti NCR (pakiti 10)','Pack',['receipt books','risiti','NCR'],{tags:['common']}),
  prod(BT28,'office-consumables','Ballpoint Pens box/50','Kalamu (sanduku 50)','Box',['pens','kalamu'],{tags:['common']}),
  prod(BT28,'office-consumables','Stapler and staples','Stapla na Vipande','Set',['stapler','stapla','binding'],{tags:['common']}),
  prod(BT28,'office-consumables','Stamp and Ink Pad official','Muhuri Rasmi na Wino','Set',['stamp','muhuri','official'],{tags:['common']}),
  prod(BT28,'office-consumables','Printer Toner Cartridge','Toner ya Printa','Cartridge',['toner','wino','printer'],{tags:['common']}),
  prod(BT28,'office-consumables','Printer Paper A4 Ream','Karatasi ya Printa A4','Ream',['printer paper','A4','office'],{tags:['common']}),
  prod(BT28,'cash-handling','Cash Counting Machine','Mashine ya Kuhesabu Pesa','Piece',['cash counter','pesa','counting machine'],{tags:['common']}),
  prod(BT28,'cash-handling','Cash Money Tray','Trei ya Pesa','Piece',['cash tray','pesa','till'],{tags:['common']}),
  prod(BT28,'cash-handling','Banknote UV Detector','Kipimo cha Noti Bandia','Piece',['UV detector','fake notes','noti bandia','currency'],{tags:['common']}),
  prod(BT28,'cash-handling','Rubber Bands box','Mpira wa Kufungia (sanduku)','Box',['rubber bands','mpira','cash bundle'],{tags:['common']}),
  prod(BT28,'cash-handling','POS Receipt Rolls box/10','Roli za Receipt ya POS (sanduku 10)','Box',['POS roll','thermal paper','receipt'],{tags:['common']}),
  prod(BT28,'security','Security Safe box','Sanduku la Usalama la Pesa','Piece',['safe box','sanduku la pesa','vault'],{tags:['common']}),
  prod(BT28,'security','CCTV Camera','Kamera ya Usalama','Piece',['CCTV','kamera','security camera'],{tags:['common']}),
  prod(BT28,'security','Security Guard Logbook','Daftari la Usalama','Book',['logbook','daftari','security'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 29 — ICT & SOFTWARE
// ═══════════════════════════════════════════════════════════════════════════
const BT29 = 'ICT & Software';
const ictCategories: MasterCategory[] = [
  cat(BT29,'Computer Hardware',   'Vifaa vya Kompyuta',    'computer',     0),
  cat(BT29,'Networking',          'Mtandao',               'wifi',         1),
  cat(BT29,'Consumables ICT',     'Vifaa vya Matumizi',    'inventory_2',  2),
];
const ictProducts: MasterProduct[] = [
  prod(BT29,'computer-hardware','Desktop PC i5','Kompyuta ya Mezani i5','Piece',['desktop','kompyuta','i5','PC'],{tags:['common']}),
  prod(BT29,'computer-hardware','Laptop i5 15in','Laptop i5 15in','Piece',['laptop','i5','kompyuta'],{tags:['common']}),
  prod(BT29,'computer-hardware','Monitor 21.5in','Skrini 21.5in','Piece',['monitor','skrini','display'],{tags:['common']}),
  prod(BT29,'computer-hardware','Keyboard and Mouse set','Kibodi na Panya','Set',['keyboard','mouse','kibodi','panya'],{tags:['common']}),
  prod(BT29,'computer-hardware','External Hard Drive 1TB','Diski la Nje 1TB','Piece',['external hard drive','storage','1TB'],{tags:['common']}),
  prod(BT29,'computer-hardware','USB Flash Drive 64GB','USB 64GB','Piece',['USB','flash drive','64GB'],{tags:['common']}),
  prod(BT29,'computer-hardware','Printer A4 Laser','Printa ya Laser','Piece',['printer','laser','A4'],{tags:['common']}),
  prod(BT29,'computer-hardware','UPS 650VA','UPS 650VA','Piece',['UPS','power backup','umeme'],{tags:['common']}),
  prod(BT29,'networking','WiFi Router dual band','Ruta ya WiFi Dual Band','Piece',['router','wifi','internet'],{tags:['common']}),
  prod(BT29,'networking','Network Switch 8-port','Swichi ya Mtandao 8-port','Piece',['network switch','swichi','ethernet'],{tags:['common']}),
  prod(BT29,'networking','Ethernet Cable Cat6 10m','Kebo ya Mtandao Cat6 10m','Piece',['ethernet','network cable','Cat6'],{tags:['common']}),
  prod(BT29,'networking','WiFi Extender','Kipanua cha WiFi','Piece',['wifi extender','signal booster','mtandao'],{tags:['common']}),
  prod(BT29,'consumables-ict','Printer Ink Black inkjet','Wino wa Printa Nyeusi','Cartridge',['ink','wino','inkjet'],{tags:['common']}),
  prod(BT29,'consumables-ict','Printer Ink Colour set','Wino wa Rangi (seti)','Set',['colour ink','wino wa rangi','printer'],{tags:['common']}),
  prod(BT29,'consumables-ict','A4 Paper Ream','Karatasi A4','Ream',['A4','karatasi','ream'],{tags:['common']}),
  prod(BT29,'consumables-ict','Thermal Paper Rolls POS box/10','Roli za Thermal POS (sanduku 10)','Box',['thermal paper','POS','receipt'],{tags:['common']}),
  prod(BT29,'consumables-ict','Cleaning Wipes screen pack/20','Taulo za Kusafisha Skrini','Pack',['screen wipes','cleaning','monitor'],{tags:['common']}),
  prod(BT29,'consumables-ict','HDMI Cable 3m','Kebo ya HDMI 3m','Piece',['HDMI','cable','display'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 30 — PRINTING & STATIONERY
// ═══════════════════════════════════════════════════════════════════════════
const BT30 = 'Printing & Stationery';
const printingCategories: MasterCategory[] = [
  cat(BT30,'Printing Supplies',   'Vifaa vya Uchapishaji',  'print',        0),
  cat(BT30,'Office Stationery',   'Vifaa vya Ofisi',        'inventory_2',  1),
  cat(BT30,'Binding and Finishing','Kuweka Vitabu',          'book',         2),
];
const printingProducts: MasterProduct[] = [
  prod(BT30,'printing-supplies','A4 Paper Ream 80gsm','Karatasi A4 Rimi 80gsm','Ream',['A4 paper','karatasi','ream','printing'],{tags:['common']}),
  prod(BT30,'printing-supplies','A3 Paper Ream','Karatasi A3 Rimi','Ream',['A3','large paper','karatasi'],{tags:['common']}),
  prod(BT30,'printing-supplies','Printer Toner HP Black','Toner ya HP Nyeusi','Cartridge',['toner','HP','laser'],{brands:['HP'],tags:['common']}),
  prod(BT30,'printing-supplies','Printer Ink Canon Black','Wino wa Canon Nyeusi','Cartridge',['ink','Canon','inkjet'],{brands:['Canon'],tags:['common']}),
  prod(BT30,'printing-supplies','Inkjet Photo Paper A4 pack/20','Karatasi ya Picha A4 (pakiti 20)','Pack',['photo paper','glossy','picha'],{tags:['common']}),
  prod(BT30,'printing-supplies','Vinyl Banner Material per sqm','Vinyl ya Mabango kwa m2','m²',['vinyl','banner','mabango','flex'],{tags:['common']}),
  prod(BT30,'printing-supplies','Lamination Pouches A4 box/100','Lamiwa A4 (sanduku 100)','Box',['lamination','lamiwa','ID card'],{tags:['common']}),
  prod(BT30,'printing-supplies','Lamination Film roll A4','Roli ya Lamiwa A4','Roll',['lamination film','plastiki','protective'],{tags:['common']}),
  prod(BT30,'office-stationery','Ballpoint Pens box/50','Kalamu (sanduku 50)','Box',['pens','kalamu','biro'],{tags:['common']}),
  prod(BT30,'office-stationery','Stapler heavy duty','Stapla Nzito','Piece',['stapler','stapla','binding'],{tags:['common']}),
  prod(BT30,'office-stationery','Staples box/5000','Vipande vya Stapla (sanduku)','Box',['staples','vipande','stapla'],{tags:['common']}),
  prod(BT30,'office-stationery','Scissors','Mkasi','Piece',['scissors','mkasi'],{tags:['common']}),
  prod(BT30,'office-stationery','Tape dispenser and rolls','Tepi na Kisanduku','Set',['tape','tepi','office'],{tags:['common']}),
  prod(BT30,'office-stationery','Folders A4 pack/10','Folda A4 (pakiti 10)','Pack',['folders','folda','filing'],{tags:['common']}),
  prod(BT30,'binding-and-finishing','Spiral Binding Coils A4 box/100','Koili za Kupiga Vitabu (sanduku 100)','Box',['binding coils','spiral','vitabu'],{tags:['common']}),
  prod(BT30,'binding-and-finishing','Comb Binding Coils A4 box/100','Koili za Comb (sanduku 100)','Box',['comb binding','koili','book binding'],{tags:['common']}),
  prod(BT30,'binding-and-finishing','Thermal Binding Covers pack/100','Vifuniko vya Thermal (pakiti 100)','Pack',['thermal binding','covers','binding'],{tags:['common']}),
  prod(BT30,'binding-and-finishing','Clear Cover A4 pack/100','Jalada la Wazi A4 (pakiti 100)','Pack',['clear cover','jalada','binding'],{tags:['common']}),
  prod(BT30,'binding-and-finishing','Card Board A4 pack/100','Kadibodi A4 (pakiti 100)','Pack',['cardboard','back cover','binding'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 31 — AUTOMOTIVE & SPARE PARTS
// ═══════════════════════════════════════════════════════════════════════════
const BT31 = 'Automotive & Spare Parts';
const autoPartsCategories: MasterCategory[] = [
  cat(BT31,'Engine Parts',       'Vipuri vya Injini',       'engineering',  0),
  cat(BT31,'Electrical Auto',    'Vipuri vya Umeme wa Gari','electrical_services',1),
  cat(BT31,'Body and Suspension','Vipuri vya Mwili na Msimamo','directions_car',2),
  cat(BT31,'Oils and Fluids',    'Mafuta na Maji ya Gari',  'local_gas_station',3),
  cat(BT31,'Tyres and Batteries','Tairi na Betri',          'tire_repair',  4),
  cat(BT31,'Tools Auto',         'Zana za Magari',          'hardware',     5),
];
const autoPartsProducts: MasterProduct[] = [
  prod(BT31,'engine-parts','Piston Ring Set universal','Pete ya Pistoni (mchanganyiko)','Set',['piston rings','pete','engine'],{tags:['common']}),
  prod(BT31,'engine-parts','Crankshaft Bearing set','Bering ya Crankshaft','Set',['crankshaft bearing','bering','main bearing'],{tags:['common']}),
  prod(BT31,'engine-parts','Cylinder Head Gasket','Gasket ya Kichwa cha Injini','Piece',['head gasket','gasket','injini'],{tags:['common']}),
  prod(BT31,'engine-parts','Timing Belt','Ukanda wa Wakati','Piece',['timing belt','ukanda','cambelt'],{tags:['common']}),
  prod(BT31,'engine-parts','Air Filter','Filta ya Hewa','Piece',['air filter','filta ya hewa'],{tags:['common']}),
  prod(BT31,'engine-parts','Oil Filter','Filta ya Mafuta','Piece',['oil filter','filta','engine'],{tags:['common']}),
  prod(BT31,'engine-parts','Fuel Filter','Filta ya Mafuta ya Gari','Piece',['fuel filter','filta ya petrol'],{tags:['common']}),
  prod(BT31,'engine-parts','Spark Plugs set 4','Plagi za Gari (seti 4)','Set',['spark plugs','plagi','ignition'],{tags:['common']}),
  prod(BT31,'engine-parts','Clutch Plate universal','Pleti ya Clutch','Piece',['clutch','gari','transmission'],{tags:['common']}),
  prod(BT31,'engine-parts','Fan Belt','Ukanda wa Feni','Piece',['fan belt','alternator belt','V-belt'],{tags:['common']}),
  prod(BT31,'electrical-auto','Car Battery 45AH','Betri ya Gari 45AH','Piece',['battery','betri','car battery','45AH'],{tags:['common']}),
  prod(BT31,'electrical-auto','Car Battery 60AH','Betri ya Gari 60AH','Piece',['battery','betri','60AH'],{tags:['common']}),
  prod(BT31,'electrical-auto','Alternator universal','Alterneta ya Gari','Piece',['alternator','alterneta','charging'],{tags:['common']}),
  prod(BT31,'electrical-auto','Starter Motor universal','Mota ya Kuanzisha Gari','Piece',['starter motor','starter','ignition'],{tags:['common']}),
  prod(BT31,'electrical-auto','Bulbs H4 pair','Balbu H4 (jozi)','Pair',['headlight bulb','H4','balbu','lights'],{tags:['common']}),
  prod(BT31,'electrical-auto','Wiper Blades pair','Wiper za Gari (jozi)','Pair',['wipers','wiper blades','windscreen'],{tags:['common']}),
  prod(BT31,'electrical-auto','Fuses assorted box','Fyuzi Mchanganyiko (sanduku)','Box',['fuses','fyuzi','electrical'],{tags:['common']}),
  prod(BT31,'body-and-suspension','Shock Absorber front universal','Shoki ya Mbele','Piece',['shock absorber','shoki','suspension'],{tags:['common']}),
  prod(BT31,'body-and-suspension','Shock Absorber rear universal','Shoki ya Nyuma','Piece',['shock absorber rear','shoki ya nyuma'],{tags:['common']}),
  prod(BT31,'body-and-suspension','Ball Joint universal','Ball Joint ya Gari','Piece',['ball joint','suspension','steering'],{tags:['common']}),
  prod(BT31,'body-and-suspension','Tie Rod End universal','Tie Rod ya Gari','Piece',['tie rod','steering','suspension'],{tags:['common']}),
  prod(BT31,'body-and-suspension','Brake Pads set universal','Pedi za Breki (seti)','Set',['brake pads','breki','stopping'],{tags:['common']}),
  prod(BT31,'body-and-suspension','Brake Disc universal','Diski ya Breki','Piece',['brake disc','rotors','breki'],{tags:['common']}),
  prod(BT31,'oils-and-fluids','Engine Oil 5W-30 4L','Mafuta ya Injini 5W-30 4L','Can',['engine oil','5W-30','mafuta'],{tags:['common']}),
  prod(BT31,'oils-and-fluids','Engine Oil 15W-40 4L','Mafuta ya Injini 15W-40 4L','Can',['engine oil','15W-40','diesel'],{tags:['common']}),
  prod(BT31,'oils-and-fluids','Gear Oil 90 1L','Mafuta ya Gia 1L','Bottle',['gear oil','90','gearbox'],{tags:['common']}),
  prod(BT31,'oils-and-fluids','Brake Fluid DOT3 500ml','Mafuta ya Breki DOT3 500ml','Bottle',['brake fluid','DOT3','breki'],{tags:['common']}),
  prod(BT31,'oils-and-fluids','Coolant 1L','Kinyoyaji 1L','Bottle',['coolant','radiator'],{tags:['common']}),
  prod(BT31,'tyres-and-batteries','Tyre 175/65 R14','Tairi 175/65 R14','Piece',['tyre','tairi','175/65 R14'],{tags:['common']}),
  prod(BT31,'tyres-and-batteries','Tyre 185/65 R15','Tairi 185/65 R15','Piece',['tyre','tairi','185/65 R15'],{tags:['common']}),
  prod(BT31,'tyres-and-batteries','Tyre 195/65 R15','Tairi 195/65 R15','Piece',['tyre','tairi','195/65 R15'],{tags:['common']}),
  prod(BT31,'tyres-and-batteries','Tyre Tube 185R','Tiuba ya Tairi 185R','Piece',['inner tube','tiuba','tyre'],{tags:['common']}),
  prod(BT31,'tools-auto','Jack hydraulic 2T','Jeki ya Maji 2T','Piece',['hydraulic jack','jeki','lifting'],{tags:['common']}),
  prod(BT31,'tools-auto','Torque Wrench 1/2in','Spana ya Torque 1/2in','Piece',['torque wrench','spana','tightening'],{tags:['common']}),
  prod(BT31,'tools-auto','Socket Set 1/2in','Seti ya Spana za Soketi','Set',['socket set','spana','tools'],{tags:['common']}),
  prod(BT31,'tools-auto','Combination Spanner set','Seti ya Spana za Kawaida','Set',['spanner set','spana','tools'],{tags:['common']}),
  prod(BT31,'tools-auto','Multimeter digital','Mita ya Umeme','Piece',['multimeter','mita','electrical testing'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 32 — FUEL & LUBRICANTS
// ═══════════════════════════════════════════════════════════════════════════
const BT32 = 'Fuel & Lubricants';
const fuelCategories: MasterCategory[] = [
  cat(BT32,'Lubricants',       'Mafuta ya Kulainisha', 'local_gas_station',0),
  cat(BT32,'Fuel Products',    'Bidhaa za Mafuta',     'local_gas_station',1),
];
const fuelProducts: MasterProduct[] = [
  prod(BT32,'lubricants','Engine Oil 5W-30 4L','Mafuta ya Injini 5W-30 4L','Can',['engine oil','5W-30','lubricant'],{tags:['common']}),
  prod(BT32,'lubricants','Engine Oil 15W-40 4L','Mafuta ya Injini 15W-40 4L','Can',['engine oil','15W-40','diesel'],{tags:['common']}),
  prod(BT32,'lubricants','Engine Oil 20W-50 4L','Mafuta ya Injini 20W-50 4L','Can',['engine oil','20W-50','petrol'],{tags:['common']}),
  prod(BT32,'lubricants','Gear Oil SAE 90 1L','Mafuta ya Gia SAE 90 1L','Bottle',['gear oil','gia','90'],{tags:['common']}),
  prod(BT32,'lubricants','Grease 500g','Grisi 500g','Tin',['grease','grisi','bearing lubricant'],{tags:['common']}),
  prod(BT32,'lubricants','Hydraulic Oil 20L','Mafuta ya Majimaji 20L','Can',['hydraulic oil','majimaji'],{tags:['common']}),
  prod(BT32,'lubricants','Chain Lube spray 400ml','Dawa ya Chain Spray','Can',['chain lube','chain oil','lubricant spray'],{tags:['common']}),
  prod(BT32,'fuel-products','Jerry Can 20L','Ndoo ya Mafuta 20L','Piece',['jerry can','ndoo','fuel storage'],{tags:['common']}),
  prod(BT32,'fuel-products','Jerry Can 5L','Ndoo ya Mafuta 5L','Piece',['jerry can','5L','fuel'],{tags:['common']}),
  prod(BT32,'fuel-products','Funnel plastic','Faneli ya Plastiki','Piece',['funnel','faneli','pouring'],{tags:['common']}),
  prod(BT32,'fuel-products','Fuel Pump hand manual','Pampu ya Mafuta ya Mikono','Piece',['fuel pump','pampu','transfer pump'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 33 — E-COMMERCE
// ═══════════════════════════════════════════════════════════════════════════
const BT33 = 'E-Commerce';
const ecommerceCategories: MasterCategory[] = [
  cat(BT33,'Packaging and Shipping','Vifaa vya Kufunga na Kutuma','box',   0),
  cat(BT33,'Office Tech',           'Teknolojia ya Ofisi',        'computer',1),
];
const ecommerceProducts: MasterProduct[] = [
  prod(BT33,'packaging-and-shipping','Bubble Mailers A4 pack/50','Bahasha za Bubble (pakiti 50)','Pack',['bubble mailer','packaging','postal'],{tags:['common']}),
  prod(BT33,'packaging-and-shipping','Cardboard Boxes pack/10','Masanduku (pakiti 10)','Pack',['boxes','masanduku','shipping'],{tags:['common']}),
  prod(BT33,'packaging-and-shipping','Packing Tape roll','Tepi ya Kufunga','Roll',['packing tape','tepi'],{tags:['common']}),
  prod(BT33,'packaging-and-shipping','Stretch Wrap roll','Stretch Wrap (roli)','Roll',['stretch wrap','plastic wrap'],{tags:['common']}),
  prod(BT33,'packaging-and-shipping','Thermal Label Roll 100x150mm','Roli ya Lebo ya Thermal','Roll',['thermal label','lebo','shipping label'],{tags:['common']}),
  prod(BT33,'packaging-and-shipping','Thermal Barcode Printer','Printa ya Lebo','Piece',['barcode printer','label printer','printa'],{tags:['common']}),
  prod(BT33,'packaging-and-shipping','Weighing Scale 30kg','Mizani 30kg','Piece',['scale','mizani','weight','shipping'],{tags:['common']}),
  prod(BT33,'packaging-and-shipping','Bubble Wrap roll','Roli ya Bubble Wrap','Roll',['bubble wrap','packaging','protective'],{tags:['common']}),
  prod(BT33,'office-tech','Laptop i5','Laptop i5','Piece',['laptop','computer','ecommerce'],{tags:['common']}),
  prod(BT33,'office-tech','Smartphone Android','Simu ya Android','Piece',['smartphone','simu','android','business'],{tags:['common']}),
  prod(BT33,'office-tech','WiFi Router','Ruta ya WiFi','Piece',['wifi','router','internet'],{tags:['common']}),
  prod(BT33,'office-tech','Power Bank 20000mAh','Chaja ya Portable 20000mAh','Piece',['power bank','chaja','backup power'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 34 — ENTERTAINMENT & EVENTS
// ═══════════════════════════════════════════════════════════════════════════
const BT34 = 'Entertainment & Events';
const entertainmentCategories: MasterCategory[] = [
  cat(BT34,'Sound and AV Equipment','Vifaa vya Sauti na Video','music_note',  0),
  cat(BT34,'Decorations',           'Mapambo',                 'celebration', 1),
  cat(BT34,'Event Supplies',        'Vifaa vya Sherehe',       'event',       2),
];
const entertainmentProducts: MasterProduct[] = [
  prod(BT34,'sound-and-av-equipment','PA Speaker 15in','Spika ya 15in','Piece',['speaker','spika','PA system','sound'],{tags:['common']}),
  prod(BT34,'sound-and-av-equipment','PA Speaker 12in','Spika ya 12in','Piece',['speaker','spika','12 inch'],{tags:['common']}),
  prod(BT34,'sound-and-av-equipment','Amplifier 1000W','Amplifier 1000W','Piece',['amplifier','amplifa','sound'],{tags:['common']}),
  prod(BT34,'sound-and-av-equipment','Microphone dynamic','Maikrofoni wa Kawaida','Piece',['microphone','maikrofoni','mic'],{tags:['common']}),
  prod(BT34,'sound-and-av-equipment','Mixer 4-channel','Miksa ya Sauti 4-channel','Piece',['mixer','miksa','sound mixing'],{tags:['common']}),
  prod(BT34,'sound-and-av-equipment','Projector LCD 3000 lumens','Projekta ya LCD','Piece',['projector','projekta','display'],{tags:['common']}),
  prod(BT34,'sound-and-av-equipment','Projector Screen 100in','Skrini ya Projekta 100in','Piece',['screen','skrini','projector'],{tags:['common']}),
  prod(BT34,'sound-and-av-equipment','XLR Cable 5m','Kebo ya XLR 5m','Piece',['XLR cable','kebo','microphone cable'],{tags:['common']}),
  prod(BT34,'decorations','Balloon pack/100','Puto (pakiti 100)','Pack',['balloon','puto','decoration'],{tags:['common']}),
  prod(BT34,'decorations','Bunting Flags 10m','Bendera za Mapambo 10m','Roll',['bunting','flags','decoration'],{tags:['common']}),
  prod(BT34,'decorations','Table Cloth set/10','Kitambaa cha Meza (seti 10)','Set',['tablecloth','kitambaa cha meza','events'],{tags:['common']}),
  prod(BT34,'decorations','Backdrop Fabric 3x6m','Kitambaa cha Nyuma 3x6m','Piece',['backdrop','decoration','events'],{tags:['common']}),
  prod(BT34,'event-supplies','Disposable Cups pack/100','Vikombe vya Plastiki (pakiti 100)','Pack',['disposable cups','vikombe','events'],{tags:['common']}),
  prod(BT34,'event-supplies','Disposable Plates pack/50','Sahani za Plastiki (pakiti 50)','Pack',['disposable plates','sahani','events'],{tags:['common']}),
  prod(BT34,'event-supplies','Napkins pack/200','Napkini (pakiti 200)','Pack',['napkins','napkini','events'],{tags:['common']}),
  prod(BT34,'event-supplies','Plastic Chairs event','Kiti cha Plastiki','Piece',['plastic chair','kiti','events'],{tags:['common']}),
  prod(BT34,'event-supplies','Folding Tables 6ft','Meza ya Kukunjwa 6ft','Piece',['folding table','meza','events'],{tags:['common']}),
  prod(BT34,'event-supplies','Extension Lead 4-way 5m','Kebo ya Extension 4-way 5m','Piece',['extension lead','kebo','power strip'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 35 — CLEANING SERVICES
// ═══════════════════════════════════════════════════════════════════════════
const BT35 = 'Cleaning Services';
const cleaningCategories: MasterCategory[] = [
  cat(BT35,'Cleaning Chemicals',  'Kemikali za Usafi',    'cleaning_services',0),
  cat(BT35,'Cleaning Equipment',  'Vifaa vya Usafi',      'mop',             1),
  cat(BT35,'Consumables Cleaning','Vifaa vya Matumizi',   'inventory_2',     2),
];
const cleaningProducts: MasterProduct[] = [
  prod(BT35,'cleaning-chemicals','Floor Cleaner 5L','Dawa ya Sakafu 5L','Can',['floor cleaner','dawa ya sakafu','cleaning'],{tags:['common']}),
  prod(BT35,'cleaning-chemicals','Toilet Cleaner 5L','Dawa ya Choo 5L','Can',['toilet cleaner','dawa ya choo','bathroom'],{tags:['common']}),
  prod(BT35,'cleaning-chemicals','Glass Cleaner 5L','Dawa ya Kioo 5L','Can',['glass cleaner','dawa ya kioo'],{tags:['common']}),
  prod(BT35,'cleaning-chemicals','Bleach 20L','Blechi 20L','Can',['bleach','blechi','disinfect'],{tags:['common']}),
  prod(BT35,'cleaning-chemicals','Multi-Surface Spray 5L','Dawa ya Uso Wote 5L','Can',['multi surface','cleaning spray'],{tags:['common']}),
  prod(BT35,'cleaning-chemicals','Dishwashing Liquid 5L','Sabuni ya Vyombo 5L','Can',['dish soap','vyombo','dishwash'],{tags:['common']}),
  prod(BT35,'cleaning-chemicals','Hand Soap liquid 5L','Sabuni ya Mikono 5L','Can',['hand soap','sabuni ya mikono'],{tags:['common']}),
  prod(BT35,'cleaning-chemicals','Air Freshener 300ml','Dawa ya Harufu 300ml','Can',['air freshener','harufu','freshener'],{tags:['common']}),
  prod(BT35,'cleaning-equipment','Mop and Bucket set','Mop na Ndoo','Set',['mop','ndoo','cleaning'],{tags:['common']}),
  prod(BT35,'cleaning-equipment','Broom indoor','Fagio la Ndani','Piece',['broom','fagio','sweeping'],{tags:['common']}),
  prod(BT35,'cleaning-equipment','Broom outdoor stiff','Fagio la Nje','Piece',['broom outdoor','fagio la nje','sweeping'],{tags:['common']}),
  prod(BT35,'cleaning-equipment','Dustpan and Brush set','Pana na Brashi','Set',['dustpan','pana','sweeping'],{tags:['common']}),
  prod(BT35,'cleaning-equipment','Vacuum Cleaner 1200W','Kisasi Vumbi 1200W','Piece',['vacuum cleaner','kisasi','vumbi'],{tags:['common']}),
  prod(BT35,'cleaning-equipment','Pressure Washer 1800W','Mashine ya Kuosha na Maji','Piece',['pressure washer','kuosha','cleaning machine'],{tags:['common']}),
  prod(BT35,'cleaning-equipment','Squeegee window','Kifaa cha Kuosha Madirisha','Piece',['squeegee','window cleaning','kioo'],{tags:['common']}),
  prod(BT35,'consumables-cleaning','Microfibre Cloths pack/10','Vitambaa vya Msafi (pakiti 10)','Pack',['microfibre','vitambaa','cleaning'],{tags:['common']}),
  prod(BT35,'consumables-cleaning','Rubber Gloves pair','Glavu za Mpira (jozi)','Pair',['rubber gloves','glavu','cleaning protection'],{tags:['common']}),
  prod(BT35,'consumables-cleaning','Garbage Bags 60L pack/25','Mifuko ya Takataka 60L (pakiti 25)','Pack',['garbage bags','mifuko','waste'],{tags:['common']}),
  prod(BT35,'consumables-cleaning','Toilet Brush set','Brashi ya Choo','Set',['toilet brush','choo','cleaning'],{tags:['common']}),
  prod(BT35,'consumables-cleaning','Scouring Pad pack/10','Pedi za Kusafisha (pakiti 10)','Pack',['scouring pad','scrub','cleaning'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 36 — SECURITY SERVICES
// ═══════════════════════════════════════════════════════════════════════════
const BT36 = 'Security Services';
const securityCategories: MasterCategory[] = [
  cat(BT36,'Security Equipment',  'Vifaa vya Usalama',     'security',     0),
  cat(BT36,'Uniforms and PPE',     'Sare na Vifaa vya Kinga','safety',      1),
  cat(BT36,'Office Supplies Sec', 'Vifaa vya Ofisi',       'inventory_2',  2),
];
const securityProducts: MasterProduct[] = [
  prod(BT36,'security-equipment','CCTV Camera IP','Kamera ya CCTV IP','Piece',['CCTV','kamera','surveillance','security'],{tags:['common']}),
  prod(BT36,'security-equipment','DVR 4-channel','DVR 4-channel','Piece',['DVR','CCTV recorder','video recorder'],{tags:['common']}),
  prod(BT36,'security-equipment','Security Alarm Siren','Msasa wa Tahadhari','Piece',['alarm','siren','security'],{tags:['common']}),
  prod(BT36,'security-equipment','Metal Detector handheld','Kipima Chuma cha Mkononi','Piece',['metal detector','security','scanner'],{tags:['common']}),
  prod(BT36,'security-equipment','Walkie-Talkie pair','Walkie-Talkie (jozi)','Pair',['walkie talkie','radio','communication'],{tags:['common']}),
  prod(BT36,'security-equipment','Torch rechargeable','Tochi ya Kuchaji','Piece',['torch','tochi','flashlight'],{tags:['common']}),
  prod(BT36,'security-equipment','Padlock heavy duty','Kufuli Nzito','Piece',['padlock','kufuli','lock'],{tags:['common']}),
  prod(BT36,'security-equipment','Security Baton','Rungu la Usalama','Piece',['baton','rungu','security'],{tags:['common']}),
  prod(BT36,'uniforms-and-ppe','Security Uniform shirt','Shati ya Sare ya Usalama','Piece',['uniform','sare','security shirt'],{tags:['common']}),
  prod(BT36,'uniforms-and-ppe','Security Uniform trousers','Suruali ya Sare ya Usalama','Piece',['uniform trousers','suruali','security'],{tags:['common']}),
  prod(BT36,'uniforms-and-ppe','Security Boots','Buti za Usalama','Pair',['boots','buti','security shoes'],{tags:['common']}),
  prod(BT36,'uniforms-and-ppe','Safety Vest reflective','Koti la Kuangaza','Piece',['safety vest','reflective','hi-vis'],{tags:['common']}),
  prod(BT36,'uniforms-and-ppe','Peaked Cap security','Kofia ya Usalama','Piece',['cap','kofia','uniform'],{tags:['common']}),
  prod(BT36,'uniforms-and-ppe','Handcuffs','Pingu','Piece',['handcuffs','pingu','security'],{tags:['common']}),
  prod(BT36,'office-supplies-sec','Guard Duty Register','Daftari la Zamu','Book',['duty register','daftari','zamu'],{tags:['common']}),
  prod(BT36,'office-supplies-sec','Incident Report Book','Daftari la Taarifa','Book',['incident report','taarifa','log book'],{tags:['common']}),
  prod(BT36,'office-supplies-sec','Ballpoint Pens box/50','Kalamu (sanduku 50)','Box',['pens','kalamu'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 37 — NGO & COMMUNITY SERVICES
// ═══════════════════════════════════════════════════════════════════════════
const BT37 = 'NGO & Community Services';
const ngoCategories: MasterCategory[] = [
  cat(BT37,'Office Supplies NGO',  'Vifaa vya Ofisi',       'inventory_2', 0),
  cat(BT37,'Health and Hygiene Kits','Vifaa vya Afya na Usafi','health_and_safety',1),
  cat(BT37,'Training Materials',   'Vifaa vya Mafunzo',     'school',      2),
];
const ngoProducts: MasterProduct[] = [
  prod(BT37,'office-supplies-ngo','A4 Paper Ream','Karatasi A4 Rimi','Ream',['karatasi','A4','office'],{tags:['common']}),
  prod(BT37,'office-supplies-ngo','Notebooks bulk pack/100','Daftari (pakiti 100)','Pack',['notebooks','daftari','stationery'],{tags:['common']}),
  prod(BT37,'office-supplies-ngo','Ballpoint Pens box/100','Kalamu (sanduku 100)','Box',['pens','kalamu'],{tags:['common']}),
  prod(BT37,'office-supplies-ngo','Folders A4 pack/10','Folda A4 (pakiti 10)','Pack',['folders','folda','filing'],{tags:['common']}),
  prod(BT37,'office-supplies-ngo','Stamp and Ink Pad','Muhuri na Wino','Set',['stamp','muhuri'],{tags:['common']}),
  prod(BT37,'health-and-hygiene-kits','Soap bars pack/12','Sabuni (pakiti 12)','Pack',['soap','sabuni','hygiene'],{tags:['common']}),
  prod(BT37,'health-and-hygiene-kits','Sanitary Pads pack/8','Taulo za Hedhi (pakiti 8)','Pack',['sanitary pads','taulo','mwanawake'],{tags:['common']}),
  prod(BT37,'health-and-hygiene-kits','Mosquito Net LLIN','Chandarua cha Mbu','Piece',['mosquito net','chandarua','malaria prevention'],{tags:['common']}),
  prod(BT37,'health-and-hygiene-kits','ORS Sachets bulk/100','ORS Sachet (pakiti 100)','Pack',['ORS','rehydration','diarrhoea'],{tags:['common']}),
  prod(BT37,'health-and-hygiene-kits','Condoms pack/100','Kondomu (pakiti 100)','Pack',['condoms','HIV prevention','uzazi wa mpango'],{tags:['common']}),
  prod(BT37,'training-materials','Flipchart paper pack/20','Karatasi za Flipchart (pakiti 20)','Pack',['flipchart','training','mafunzo'],{tags:['common']}),
  prod(BT37,'training-materials','Markers pack/10','Kalamu za Chati (pakiti 10)','Pack',['markers','training','flipchart'],{tags:['common']}),
  prod(BT37,'training-materials','Whiteboard 90x120cm','Ubao Mweupe 90x120cm','Piece',['whiteboard','ubao','training'],{tags:['common']}),
  prod(BT37,'training-materials','Projector LCD','Projekta ya LCD','Piece',['projector','projekta','training'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 38 — EXPORT & IMPORT
// ═══════════════════════════════════════════════════════════════════════════
const BT38 = 'Export & Import';
const exportImportCategories: MasterCategory[] = [
  cat(BT38,'Logistics Supplies',   'Vifaa vya Usafirishaji', 'local_shipping',0),
  cat(BT38,'Office Supplies Trade','Vifaa vya Ofisi',        'inventory_2',   1),
];
const exportImportProducts: MasterProduct[] = [
  prod(BT38,'logistics-supplies','Pallets wooden pack/5','Pali za Mbao (pakiti 5)','Pack',['pallets','pali','shipping'],{tags:['common']}),
  prod(BT38,'logistics-supplies','Stretch Wrap roll','Stretch Wrap (roli)','Roll',['stretch wrap','plastic wrap'],{tags:['common']}),
  prod(BT38,'logistics-supplies','Packing Tape roll','Tepi ya Kufunga','Roll',['packing tape','tepi'],{tags:['common']}),
  prod(BT38,'logistics-supplies','Cardboard Boxes pack/20','Masanduku (pakiti 20)','Pack',['boxes','masanduku'],{tags:['common']}),
  prod(BT38,'logistics-supplies','Rope 50m','Kamba 50m','Roll',['kamba','rope','securing'],{tags:['common']}),
  prod(BT38,'logistics-supplies','Weighing Scale 300kg','Mizani 300kg','Piece',['scale','mizani','weight'],{tags:['common']}),
  prod(BT38,'logistics-supplies','Tarpaulin 6x9m','Mfuniko wa Mzigo 6x9m','Piece',['tarpaulin','mfuniko','waterproof cover'],{tags:['common']}),
  prod(BT38,'logistics-supplies','Barcode Scanner','Skena ya Msimbo','Piece',['barcode scanner','skena','inventory'],{tags:['common']}),
  prod(BT38,'office-supplies-trade','A4 Paper Ream','Karatasi A4 Rimi','Ream',['A4','karatasi','office'],{tags:['common']}),
  prod(BT38,'office-supplies-trade','Receipt Books NCR pack/10','Daftari za Risiti NCR','Pack',['receipt','risiti','delivery note'],{tags:['common']}),
  prod(BT38,'office-supplies-trade','Customs Declaration Forms','Fomu za Forodha','Pack',['customs form','forodha','declaration'],{tags:['common']}),
  prod(BT38,'office-supplies-trade','Stamp and Ink Pad','Muhuri na Wino','Set',['stamp','muhuri','official'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 39 — AGRICULTURAL INPUTS
// ═══════════════════════════════════════════════════════════════════════════
const BT39 = 'Agricultural Inputs';
const agriInputCategories: MasterCategory[] = [
  cat(BT39,'Seeds',        'Mbegu',           'grass',       0),
  cat(BT39,'Fertilizers',  'Mbolea',          'compost',     1),
  cat(BT39,'Agrochemicals','Dawa za Kilimo',  'science',     2),
  cat(BT39,'Farm Tools',   'Zana za Kilimo',  'agriculture', 3),
  cat(BT39,'Irrigation',   'Umwagiliaji',     'water_drop',  4),
];
const agriInputProducts: MasterProduct[] = [
  prod(BT39,'seeds','Maize Seed SC403 2kg','Mbegu ya Mahindi SC403 (2kg)','Bag',['maize seed','mbegu ya mahindi','SC403'],{tags:['common']}),
  prod(BT39,'seeds','Maize Seed SC627 2kg','Mbegu ya Mahindi SC627 (2kg)','Bag',['maize seed','SC627','hybrid'],{tags:['common']}),
  prod(BT39,'seeds','Rice Seed SARO 5kg','Mbegu ya Mpunga SARO (5kg)','Bag',['rice seed','mbegu ya mpunga','SARO'],{tags:['common']}),
  prod(BT39,'seeds','Bean Seed Jesca 1kg','Mbegu ya Maharagwe Jesca (1kg)','Bag',['bean seed','maharagwe','jesca'],{tags:['common']}),
  prod(BT39,'seeds','Sunflower Seed 1kg','Mbegu ya Alizeti (1kg)','Bag',['sunflower','alizeti','oilseed'],{tags:['common']}),
  prod(BT39,'seeds','Tomato Seed F1 sachet','Mbegu ya Nyanya F1 (sachet)','Sachet',['tomato seed','nyanya','F1'],{tags:['common']}),
  prod(BT39,'seeds','Onion Seed Red sachet','Mbegu ya Vitunguu Nyekundu','Sachet',['onion seed','vitunguu','red onion'],{tags:['common']}),
  prod(BT39,'fertilizers','CAN 50kg','CAN 50kg','Bag',['CAN','calcium ammonium nitrate','mbolea'],{tags:['common']}),
  prod(BT39,'fertilizers','Urea 50kg','Urea 50kg','Bag',['urea','mbolea','nitrogen'],{tags:['common']}),
  prod(BT39,'fertilizers','DAP 50kg','DAP 50kg','Bag',['DAP','diammonium phosphate','mbolea'],{tags:['common']}),
  prod(BT39,'fertilizers','NPK 17:17:17 50kg','NPK 17:17:17 50kg','Bag',['NPK','mbolea','compound fertilizer'],{tags:['common']}),
  prod(BT39,'fertilizers','Organic Compost 50kg','Mboji 50kg','Bag',['compost','mboji','organic','manure'],{tags:['common']}),
  prod(BT39,'agrochemicals','Actellic 50EC 500ml','Dawa ya Actellic 500ml','Bottle',['actellic','pest control','insecticide'],{tags:['common']}),
  prod(BT39,'agrochemicals','Dimethoate 40EC 500ml','Dawa ya Dimethoate 500ml','Bottle',['dimethoate','aphids','insecticide'],{tags:['common']}),
  prod(BT39,'agrochemicals','Mancozeb 80WP 500g','Dawa ya Kuvu Mancozeb 500g','Packet',['mancozeb','fungicide','kuvu'],{tags:['common']}),
  prod(BT39,'agrochemicals','Glyphosate 1L','Dawa ya Magugu Glyphosate 1L','Bottle',['glyphosate','roundup','herbicide','magugu'],{tags:['common']}),
  prod(BT39,'agrochemicals','2,4-D 500ml','Dawa ya 2,4-D 500ml','Bottle',['2,4-D','herbicide','magugu'],{tags:['common']}),
  prod(BT39,'agrochemicals','Lambda-cyhalothrin 25EC 500ml','Lambda 500ml','Bottle',['lambda','insecticide','pest control'],{tags:['common']}),
  prod(BT39,'farm-tools','Hoe jembe','Jembe','Piece',['jembe','hoe','digging'],{tags:['common']}),
  prod(BT39,'farm-tools','Panga machete','Panga','Piece',['panga','machete','clearing'],{tags:['common']}),
  prod(BT39,'farm-tools','Watering Can 10L','Birika la Kumwagilia 10L','Piece',['watering can','birika','irrigation'],{tags:['common']}),
  prod(BT39,'farm-tools','Knapsack Sprayer 16L','Dawa Nyunyizia 16L','Piece',['sprayer','dawa nyunyizia','pumping'],{tags:['common']}),
  prod(BT39,'farm-tools','Garden Fork','Uma wa Bustani','Piece',['fork','uma','digging'],{tags:['common']}),
  prod(BT39,'irrigation','Drip Irrigation Kit per acre','Mfumo wa Matone kwa Ekari','Kit',['drip irrigation','matone','maji'],{tags:['common']}),
  prod(BT39,'irrigation','Irrigation Pipe 16mm per metre','Bomba la Umwagiliaji 16mm','Metre',['irrigation pipe','bomba','drip'],{tags:['common']}),
  prod(BT39,'irrigation','Water Pump 1HP','Pampu ya Maji 1HP','Piece',['water pump','pampu','irrigation'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 40 — MEDIA & COMMUNICATIONS
// ═══════════════════════════════════════════════════════════════════════════
const BT40 = 'Media & Communications';
const mediaCategories: MasterCategory[] = [
  cat(BT40,'Production Equipment', 'Vifaa vya Uzalishaji', 'videocam',  0),
  cat(BT40,'Printing and Publishing','Uchapishaji',         'print',     1),
  cat(BT40,'Office Tech Media',    'Teknolojia ya Ofisi',  'computer',  2),
];
const mediaProducts: MasterProduct[] = [
  prod(BT40,'production-equipment','Camera DSLR','Kamera ya DSLR','Piece',['camera','DSLR','photography','picha'],{tags:['common']}),
  prod(BT40,'production-equipment','Tripod camera stand','Stendi ya Kamera','Piece',['tripod','stendi','camera stand'],{tags:['common']}),
  prod(BT40,'production-equipment','Microphone condenser','Maikrofoni wa Studio','Piece',['microphone','maikrofoni','studio'],{tags:['common']}),
  prod(BT40,'production-equipment','Ring Light 18in','Mwanga wa Duara 18in','Piece',['ring light','mwanga','lighting','studio'],{tags:['common']}),
  prod(BT40,'production-equipment','Video Camera 4K','Kamera ya Video 4K','Piece',['video camera','4K','kamera'],{tags:['common']}),
  prod(BT40,'production-equipment','SD Card 64GB Class 10','Kadi ya Kuhifadhi 64GB','Piece',['SD card','64GB','memory','storage'],{tags:['common']}),
  prod(BT40,'production-equipment','Drone camera DJI','Ndege Ndogo ya Picha','Piece',['drone','picha za angani','aerial'],{tags:['common']}),
  prod(BT40,'printing-and-publishing','A4 Paper Ream','Karatasi A4 Rimi','Ream',['A4','karatasi','printing'],{tags:['common']}),
  prod(BT40,'printing-and-publishing','Vinyl Flex Banner sqm','Vinyl ya Mabango kwa m2','m²',['vinyl','banner','flex print'],{tags:['common']}),
  prod(BT40,'printing-and-publishing','Printer Ink set colour','Seti ya Wino wa Rangi','Set',['ink','wino','printer colour'],{tags:['common']}),
  prod(BT40,'office-tech-media','Laptop i7 Creator','Laptop i7 ya Kubuni','Piece',['laptop','i7','creative','editing'],{tags:['common']}),
  prod(BT40,'office-tech-media','External Hard Drive 2TB','Diski la Nje 2TB','Piece',['hard drive','2TB','storage','backup'],{tags:['common']}),
  prod(BT40,'office-tech-media','USB Hub 7-port','USB Hub 7-port','Piece',['USB hub','multi-port','peripherals'],{tags:['common']}),
  prod(BT40,'office-tech-media','HDMI Cable 3m','Kebo ya HDMI 3m','Piece',['HDMI','cable','video'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 41 — JEWELRY & CRAFTS
// ═══════════════════════════════════════════════════════════════════════════
const BT41 = 'Jewelry & Crafts';
const jewelryCraftsCategories: MasterCategory[] = [
  cat(BT41,'Jewelry Making','Utengenezaji wa Vito', 'diamond', 0),
  cat(BT41,'Craft Supplies','Vifaa vya Ufundi',     'brush',   1),
];
const jewelryCraftsProducts: MasterProduct[] = [
  prod(BT41,'jewelry-making','Gold Wire 22ct per gram','Waya wa Dhahabu 22ct kwa Gramu','Gram',['gold','dhahabu','jewelry','vito'],{tags:['common']}),
  prod(BT41,'jewelry-making','Silver Wire per gram','Waya wa Fedha kwa Gramu','Gram',['silver','fedha','jewelry'],{tags:['common']}),
  prod(BT41,'jewelry-making','Beads mixed pack','Shanga Mchanganyiko','Pack',['beads','shanga','jewelry making'],{tags:['common']}),
  prod(BT41,'jewelry-making','Jewelry Pliers set','Plaia za Utengenezaji wa Vito','Set',['jewelry pliers','plaia','tools'],{tags:['common']}),
  prod(BT41,'jewelry-making','Jewelers Torch','Tochi ya Kuyeyusha Madini','Piece',['torch','soldering','jewelry'],{tags:['common']}),
  prod(BT41,'jewelry-making','Polishing Compound 100g','Unga wa Kuangaza Vito 100g','Tin',['polish','compound','jewelry finish'],{tags:['common']}),
  prod(BT41,'jewelry-making','Display Stand velvet','Stendi ya Maonyesho','Piece',['display','stendi','jewelry display'],{tags:['common']}),
  prod(BT41,'craft-supplies','Canvas 30x40cm','Canvas ya Uchoraji 30x40cm','Piece',['canvas','painting','art'],{tags:['common']}),
  prod(BT41,'craft-supplies','Acrylic Paint set 12 colours','Rangi za Acrylic (seti 12)','Set',['acrylic','paint','art'],{tags:['common']}),
  prod(BT41,'craft-supplies','Paint Brushes set','Brashi za Uchoraji (seti)','Set',['brushes','brashi','art'],{tags:['common']}),
  prod(BT41,'craft-supplies','Hot Glue Gun','Bunduki ya Gundi','Piece',['glue gun','gundi','crafts'],{tags:['common']}),
  prod(BT41,'craft-supplies','Glue Sticks pack/20','Fimbo za Gundi (pakiti 20)','Pack',['glue sticks','gundi','crafts'],{tags:['common']}),
  prod(BT41,'craft-supplies','Scissors craft','Mkasi wa Ufundi','Piece',['scissors','mkasi','craft'],{tags:['common']}),
  prod(BT41,'craft-supplies','Crochet Hooks set','Ndoano za Kushona (seti)','Set',['crochet','knitting','handcraft'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 42 — FURNITURE & CARPENTRY
// ═══════════════════════════════════════════════════════════════════════════
const BT42 = 'Furniture & Carpentry';
const furnitureCategories: MasterCategory[] = [
  cat(BT42,'Timber and Boards',   'Mbao na Mabodi',         'forest',   0),
  cat(BT42,'Hardware and Fittings','Vifaa vya Kupachika',   'hardware', 1),
  cat(BT42,'Finishing',           'Mapambo ya Fanicha',     'brush',    2),
  cat(BT42,'Tools Carpentry',     'Zana za Useremala',      'hardware', 3),
];
const furnitureProducts: MasterProduct[] = [
  prod(BT42,'timber-and-boards','Hardwood Timber per metre','Mbao ya Mti Ngumu kwa Mita','Metre',['hardwood','mbao','timber'],{tags:['common']}),
  prod(BT42,'timber-and-boards','Softwood Timber per metre','Mbao ya Mti Laini kwa Mita','Metre',['softwood','mbao','pine'],{tags:['common']}),
  prod(BT42,'timber-and-boards','Plywood 4x8in 12mm','Plywood 4x8in 12mm','Sheet',['plywood','bodi','furniture'],{tags:['common']}),
  prod(BT42,'timber-and-boards','Plywood 4x8in 6mm','Plywood 4x8in 6mm','Sheet',['plywood','6mm','backing board'],{tags:['common']}),
  prod(BT42,'timber-and-boards','MDF Board 4x8in','MDF Board 4x8in','Sheet',['MDF','medium density','furniture'],{tags:['common']}),
  prod(BT42,'timber-and-boards','Chipboard 4x8in','Chipboard 4x8in','Sheet',['chipboard','particleboard','cabinet'],{tags:['common']}),
  prod(BT42,'hardware-and-fittings','Piano Hinge per metre','Bangili ya Piano kwa Mita','Metre',['piano hinge','bangili','fitting'],{tags:['common']}),
  prod(BT42,'hardware-and-fittings','Cabinet Hinges pair','Bangili za Kabati (jozi)','Pair',['cabinet hinges','bangili','door'],{tags:['common']}),
  prod(BT42,'hardware-and-fittings','Drawer Runners pair 300mm','Reli za Droo (jozi) 300mm','Pair',['drawer runners','reli','slide'],{tags:['common']}),
  prod(BT42,'hardware-and-fittings','Cabinet Lock','Kufuli ya Kabati','Piece',['lock','kufuli','cabinet'],{tags:['common']}),
  prod(BT42,'hardware-and-fittings','Wood Screws box/200','Skrubu za Mbao (sanduku 200)','Box',['screws','skrubu','wood screw'],{tags:['common']}),
  prod(BT42,'hardware-and-fittings','Corner Brackets pack/10','Kona za Chuma (pakiti 10)','Pack',['corner bracket','kona','support'],{tags:['common']}),
  prod(BT42,'finishing','Varnish gloss 1L','Varnish 1L','Tin',['varnish','wood finish','polish'],{tags:['common']}),
  prod(BT42,'finishing','Varnish satin 1L','Varnish Satin 1L','Tin',['varnish satin','wood finish'],{tags:['common']}),
  prod(BT42,'finishing','Wood Stain Brown 1L','Rangi ya Mbao Kahawia 1L','Tin',['wood stain','mahogany','finish'],{tags:['common']}),
  prod(BT42,'finishing','Wood Filler 500g','Kituo cha Mbao 500g','Tin',['wood filler','putty','repair'],{tags:['common']}),
  prod(BT42,'finishing','Sandpaper 80 grit pack/10','Karatasi ya Kusaga 80 (pakiti 10)','Pack',['sandpaper','kusaga','wood prep'],{tags:['common']}),
  prod(BT42,'finishing','Paint Brush 2in','Burashi ya Rangi 2in','Piece',['paint brush','burashi','varnish'],{tags:['common']}),
  prod(BT42,'tools-carpentry','Circular Saw 185mm','Msumeno wa Duara 185mm','Piece',['circular saw','msumeno','cutting'],{tags:['common']}),
  prod(BT42,'tools-carpentry','Jigsaw electric','Jigsaw ya Umeme','Piece',['jigsaw','msumeno','curved cut'],{tags:['common']}),
  prod(BT42,'tools-carpentry','Router electric','Router ya Mbao','Piece',['router','wood carving','shaping'],{tags:['common']}),
  prod(BT42,'tools-carpentry','Orbital Sander','Sander ya Duara','Piece',['sander','orbital','smoothing'],{tags:['common']}),
  prod(BT42,'tools-carpentry','Drill electric 13mm','Drili ya Umeme 13mm','Piece',['drill','drili','boring'],{tags:['common']}),
  prod(BT42,'tools-carpentry','Tape Measure 5m','Mkanda wa Kupima 5m','Piece',['tape measure','mkanda','measuring'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 43 — WATER & BEVERAGES
// ═══════════════════════════════════════════════════════════════════════════
const BT43 = 'Water & Beverages';
const waterBevCategories: MasterCategory[] = [
  cat(BT43,'Bottled Water',      'Maji ya Chupa',          'water_drop', 0),
  cat(BT43,'Soft Drinks',        'Vinywaji Baridi',        'local_bar',  1),
  cat(BT43,'Juices',             'Juisi',                  'local_drink',2),
  cat(BT43,'Production Supplies','Vifaa vya Uzalishaji',   'factory',    3),
];
const waterBevProducts: MasterProduct[] = [
  prod(BT43,'bottled-water','Water 500ml case/24','Maji 500ml (kesi 24)','Case',['maji','water','500ml','bottled water'],{tags:['common','fmcg']}),
  prod(BT43,'bottled-water','Water 1.5L case/12','Maji 1.5L (kesi 12)','Case',['maji','water','1.5L'],{tags:['common','fmcg']}),
  prod(BT43,'bottled-water','Water 5L bottle','Maji 5L (chupa)','Bottle',['maji','water','5L'],{tags:['common','fmcg']}),
  prod(BT43,'bottled-water','Water 20L dispenser bottle','Maji 20L (chupa ya dispenser)','Bottle',['maji','water cooler','20L'],{tags:['common','fmcg']}),
  prod(BT43,'soft-drinks','Coca-Cola 500ml case/24','Coca-Cola 500ml (kesi 24)','Case',['coca cola','soda','cold drink'],{brands:['Coca-Cola'],tags:['common','fmcg']}),
  prod(BT43,'soft-drinks','Pepsi 500ml case/24','Pepsi 500ml (kesi 24)','Case',['pepsi','soda','cold drink'],{brands:['Pepsi'],tags:['common','fmcg']}),
  prod(BT43,'soft-drinks','Fanta Orange 500ml case/24','Fanta Orange 500ml (kesi 24)','Case',['fanta','orange','soda'],{brands:['Fanta'],tags:['common','fmcg']}),
  prod(BT43,'soft-drinks','Sprite 500ml case/24','Sprite 500ml (kesi 24)','Case',['sprite','lemon soda','cold drink'],{brands:['Sprite'],tags:['common','fmcg']}),
  prod(BT43,'juices','Minute Maid Mango 500ml case/24','Minute Maid Embe 500ml','Case',['minute maid','juice','mango','embe'],{brands:['Minute Maid'],tags:['common','fmcg']}),
  prod(BT43,'juices','Viju Orange 350ml case/24','Viju Orange 350ml (kesi 24)','Case',['viju','juice','orange','Tanzania'],{brands:['Viju'],tags:['common','fmcg']}),
  prod(BT43,'juices','Azam Juice 350ml case/24','Azam Juisi 350ml (kesi 24)','Case',['azam','juice','Tanzania','fruity'],{brands:['Azam'],tags:['common','fmcg']}),
  prod(BT43,'production-supplies','PET Preforms 500ml box/1000','Preform za PET (sanduku 1000)','Box',['PET preform','bottle making','production'],{tags:['common']}),
  prod(BT43,'production-supplies','Bottle Caps 28mm box/5000','Vifuniko vya Chupa (sanduku 5000)','Box',['bottle caps','vifuniko','production'],{tags:['common']}),
  prod(BT43,'production-supplies','Shrink Labels roll','Lebo za Shrink (roli)','Roll',['shrink label','lebo','branding'],{tags:['common']}),
  prod(BT43,'production-supplies','Chlorine for water treatment 1kg','Klorini ya Maji 1kg','Kg',['chlorine','water treatment','sanitize'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 44 — AUTO REPAIR
// ═══════════════════════════════════════════════════════════════════════════
const BT44 = 'Auto Repair';
const autoRepairCategories: MasterCategory[] = [
  cat(BT44,'Oils and Fluids',      'Mafuta na Maji ya Gari',  'local_gas_station',0),
  cat(BT44,'Spare Parts',          'Vipuri vya Gari',         'engineering',    1),
  cat(BT44,'Workshop Consumables', 'Vifaa vya Karakana',      'inventory_2',    2),
  cat(BT44,'Tools Workshop',       'Zana za Karakana',        'hardware',       3),
];
const autoRepairProducts: MasterProduct[] = [
  prod(BT44,'oils-and-fluids','Engine Oil 5W-30 4L','Mafuta ya Injini 5W-30 4L','Can',['engine oil','5W-30','mafuta'],{tags:['common']}),
  prod(BT44,'oils-and-fluids','Engine Oil 15W-40 4L','Mafuta ya Injini 15W-40 4L','Can',['engine oil','15W-40','diesel'],{tags:['common']}),
  prod(BT44,'oils-and-fluids','Engine Oil 20W-50 4L','Mafuta ya Injini 20W-50 4L','Can',['engine oil','20W-50'],{tags:['common']}),
  prod(BT44,'oils-and-fluids','Gear Oil SAE 90 1L','Mafuta ya Gia SAE 90 1L','Bottle',['gear oil','90','gearbox'],{tags:['common']}),
  prod(BT44,'oils-and-fluids','Brake Fluid DOT3 500ml','Mafuta ya Breki 500ml','Bottle',['brake fluid','DOT3'],{tags:['common']}),
  prod(BT44,'oils-and-fluids','Coolant 1L','Kinyoyaji 1L','Bottle',['coolant','radiator'],{tags:['common']}),
  prod(BT44,'oils-and-fluids','Power Steering Fluid 1L','Mafuta ya Steering 1L','Bottle',['power steering','fluid'],{tags:['common']}),
  prod(BT44,'spare-parts','Oil Filter universal','Filta ya Mafuta','Piece',['oil filter','filta','engine'],{tags:['common']}),
  prod(BT44,'spare-parts','Air Filter universal','Filta ya Hewa','Piece',['air filter','filta ya hewa'],{tags:['common']}),
  prod(BT44,'spare-parts','Spark Plugs set/4','Plagi za Gari (seti 4)','Set',['spark plugs','plagi'],{tags:['common']}),
  prod(BT44,'spare-parts','Brake Pads set universal','Pedi za Breki (seti)','Set',['brake pads','breki'],{tags:['common']}),
  prod(BT44,'spare-parts','Fan Belt universal','Ukanda wa Feni','Piece',['fan belt','V-belt'],{tags:['common']}),
  prod(BT44,'spare-parts','Timing Belt universal','Ukanda wa Wakati','Piece',['timing belt','cambelt'],{tags:['common']}),
  prod(BT44,'spare-parts','Wiper Blades pair','Wiper za Gari (jozi)','Pair',['wipers','wiper blades'],{tags:['common']}),
  prod(BT44,'spare-parts','Battery 55AH','Betri 55AH','Piece',['battery','betri','car battery'],{tags:['common']}),
  prod(BT44,'workshop-consumables','Engine Degreaser 5L','Dawa ya Kusafisha Injini 5L','Can',['degreaser','injini','cleaning'],{tags:['common']}),
  prod(BT44,'workshop-consumables','WD-40 450ml','WD-40 450ml','Can',['WD-40','lubricant spray','rust remover'],{brands:['WD-40'],tags:['common']}),
  prod(BT44,'workshop-consumables','Rags Workshop Towels pack','Vitambaa vya Karakana','Pack',['rags','vitambaa','workshop'],{tags:['common']}),
  prod(BT44,'workshop-consumables','Sandpaper assorted pack','Karatasi za Kusaga (mchanganyiko)','Pack',['sandpaper','sanding','bodywork'],{tags:['common']}),
  prod(BT44,'workshop-consumables','Car Body Filler 1kg','Fila ya Mwili wa Gari 1kg','Tin',['body filler','fila','bodywork'],{tags:['common']}),
  prod(BT44,'workshop-consumables','Masking Tape 25mm roll','Tepi ya Kufunika 25mm','Roll',['masking tape','painting'],{tags:['common']}),
  prod(BT44,'tools-workshop','Hydraulic Jack 2T','Jeki 2T','Piece',['jack','jeki','lifting'],{tags:['common']}),
  prod(BT44,'tools-workshop','Socket Set 1/2in','Seti ya Spana za Soketi','Set',['socket set','spana'],{tags:['common']}),
  prod(BT44,'tools-workshop','Torque Wrench 1/2in','Spana ya Torque 1/2in','Piece',['torque wrench','spana'],{tags:['common']}),
  prod(BT44,'tools-workshop','Multimeter digital','Mita ya Umeme','Piece',['multimeter','electrical test'],{tags:['common']}),
  prod(BT44,'tools-workshop','Tyre Pressure Gauge','Kipima Shinikizo la Tairi','Piece',['tyre gauge','tairi','pressure'],{tags:['common']}),
  prod(BT44,'tools-workshop','Angle Grinder 115mm','Grinda 115mm','Piece',['grinder','cutting','grinding'],{tags:['common']}),
  prod(BT44,'tools-workshop','Welding Machine arc','Mashine ya Kulehemu','Piece',['welding','kulehemu','arc welder'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// 45 — OTHER
// ═══════════════════════════════════════════════════════════════════════════
const BT45 = 'Other';
const otherCategories: MasterCategory[] = [
  cat(BT45,'General Supplies','Vifaa vya Kawaida','inventory_2',0),
  cat(BT45,'Office Supplies', 'Vifaa vya Ofisi',  'inventory_2',1),
];
const otherProducts: MasterProduct[] = [
  prod(BT45,'general-supplies','A4 Paper Ream','Karatasi A4 Rimi','Ream',['karatasi','A4','office','paper'],{tags:['common']}),
  prod(BT45,'general-supplies','Ballpoint Pens box/50','Kalamu (sanduku 50)','Box',['pens','kalamu','biro'],{tags:['common']}),
  prod(BT45,'general-supplies','Receipt Books pack/5','Daftari za Risiti (pakiti 5)','Pack',['receipt','risiti','daftari'],{tags:['common']}),
  prod(BT45,'general-supplies','Stapler and staples','Stapla na Vipande','Set',['stapler','stapla','binding'],{tags:['common']}),
  prod(BT45,'general-supplies','Scissors','Mkasi','Piece',['scissors','mkasi','cutting'],{tags:['common']}),
  prod(BT45,'general-supplies','Tape clear roll','Tepi Wazi (roli)','Roll',['tape','tepi','clear tape'],{tags:['common']}),
  prod(BT45,'office-supplies','USB Flash Drive 32GB','USB 32GB','Piece',['USB','flash drive','storage'],{tags:['common']}),
  prod(BT45,'office-supplies','Printer Ink Black','Wino wa Printa Nyeusi','Cartridge',['ink','wino','printer'],{tags:['common']}),
  prod(BT45,'office-supplies','Stamp and Ink Pad','Muhuri na Wino','Set',['stamp','muhuri'],{tags:['common']}),
  prod(BT45,'office-supplies','Folders A4 pack/10','Folda A4 (pakiti 10)','Pack',['folders','folda','filing'],{tags:['common']}),
];

// ═══════════════════════════════════════════════════════════════════════════
// MASTER ARRAYS
// ═══════════════════════════════════════════════════════════════════════════
const ALL_CATEGORIES: MasterCategory[] = [
  ...FMCG_BTS.flatMap(bt => fmcgCats(bt)),
  ...electronicsCategories, ...fashionCategories, ...tailoringCategories, ...beautyCategories,
  ...salonCategories, ...restaurantCategories, ...cafeBakeryCategories, ...streetFoodCategories,
  ...cateringCategories, ...agricultureCategories, ...agribusinessCategories, ...livestockCategories,
  ...fishingCategories,
  ...manufacturingCategories, ...constructionCategories, ...hardwareCategories,
  ...transportCategories, ...travelCategories, ...hotelCategories, ...pharmacyCategories,
  ...clinicCategories, ...educationCategories, ...realEstateCategories,
  ...financeCategories, ...ictCategories, ...printingCategories,
  ...autoPartsCategories, ...fuelCategories, ...ecommerceCategories,
  ...entertainmentCategories, ...cleaningCategories, ...securityCategories,
  ...ngoCategories, ...exportImportCategories, ...agriInputCategories,
  ...mediaCategories, ...jewelryCraftsCategories, ...furnitureCategories,
  ...waterBevCategories, ...autoRepairCategories, ...otherCategories,
];

const ALL_PRODUCTS: MasterProduct[] = [
  ...FMCG_BTS.flatMap(bt => fmcgProds(bt)),
  ...electronicsProducts, ...fashionProducts, ...tailoringProducts, ...beautyProducts,
  ...salonProducts, ...restaurantProducts, ...cafeBakeryProducts, ...streetFoodProducts,
  ...cateringProducts, ...agricultureProducts, ...agribusinessProducts, ...livestockProducts,
  ...fishingProducts,
  ...manufacturingProducts, ...constructionProducts, ...hardwareProducts,
  ...transportProducts, ...travelProducts, ...hotelProducts, ...pharmacyProducts,
  ...clinicProducts, ...educationProducts, ...realEstateProducts,
  ...financeProducts, ...ictProducts, ...printingProducts,
  ...autoPartsProducts, ...fuelProducts, ...ecommerceProducts,
  ...entertainmentProducts, ...cleaningProducts, ...securityProducts,
  ...ngoProducts, ...exportImportProducts, ...agriInputProducts,
  ...mediaProducts, ...jewelryCraftsProducts, ...furnitureProducts,
  ...waterBevProducts, ...autoRepairProducts, ...otherProducts,
];

// ═══════════════════════════════════════════════════════════════════════════
// MAIN FUNCTION
// ═══════════════════════════════════════════════════════════════════════════
async function main(): Promise<void> {
  const db = admin.firestore();

  if (!DRY_RUN) {
    const snap = await db.collection('master_categories').limit(1).get();
    if (!snap.empty && !FORCE) {
      console.error(
        '⚠  master_categories is not empty.\n' +
        '   Re-run with --force to overwrite, or --dry-run to preview.'
      );
      process.exit(1);
    }
  }

  if (DRY_RUN) {
    console.log('=== DRY RUN — no writes ===');
    console.log(`Categories: ${ALL_CATEGORIES.length}`);
    console.log(`Products:   ${ALL_PRODUCTS.length}`);
    const btSet = new Set([...ALL_CATEGORIES.map(c => c.businessType)]);
    console.log(`Business Types: ${btSet.size}`);
    btSet.forEach(bt => {
      const cats = ALL_CATEGORIES.filter(c => c.businessType === bt).length;
      const prods = ALL_PRODUCTS.filter(p => p.businessType === bt).length;
      console.log(`  ${bt}: ${cats} cats, ${prods} products`);
    });
    return;
  }

  async function writeBatches<T extends object>(
    collection: string,
    docs: { id: string; data: T }[]
  ): Promise<number> {
    let written = 0;
    let batch = db.batch();
    let batchCount = 0;
    for (const { id, data } of docs) {
      batch.set(db.collection(collection).doc(id), data);
      batchCount++;
      written++;
      if (batchCount >= BATCH_SIZE) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
    if (batchCount > 0) await batch.commit();
    return written;
  }

  console.log(`\n📂 Pushing ${ALL_CATEGORIES.length} categories...`);
  const catDocs = ALL_CATEGORIES.map(c => ({
    id: `${slug(c.businessType)}_${c.categorySlug}`,
    data: c,
  }));
  const catsWritten = await writeBatches('master_categories', catDocs);

  console.log(`\n📦 Pushing ${ALL_PRODUCTS.length} products...`);
  const btList = [...new Set(ALL_PRODUCTS.map(p => p.businessType))];
  let totalProdsWritten = 0;
  let errors = 0;

  for (const bt of btList) {
    const btProds = ALL_PRODUCTS.filter(p => p.businessType === bt);
    try {
      const prodDocs = btProds.map(p => ({
        id: `${slug(p.businessType)}_${p.productSlug}`,
        data: p,
      }));
      const n = await writeBatches('master_products', prodDocs);
      console.log(`  ✓ ${bt} — ${n} products`);
      totalProdsWritten += n;
    } catch (err) {
      console.error(`  ✗ ${bt}: ${(err as Error).message}`);
      errors++;
    }
  }

  const btCount = btList.length;
  console.log('\n═══════════════════════════════════');
  console.log('✅ Seed Complete');
  console.log(`   Business Types : ${btCount}`);
  console.log(`   Categories     : ${catsWritten}`);
  console.log(`   Products       : ${totalProdsWritten}`);
  if (errors) console.log(`   Errors         : ${errors}`);
  console.log('═══════════════════════════════════\n');
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
