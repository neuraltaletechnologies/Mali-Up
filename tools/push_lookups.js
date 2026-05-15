/*
  Usage:
  Option 1 (with service account):
  1. Install Firebase Admin: `npm install firebase-admin`
  2. Set `GOOGLE_APPLICATION_CREDENTIALS` to a service account JSON.
  3. Run: `node tools/push_lookups.js`

  Option 2 (with Firebase CLI):
  1. Run: `firebase login`
  2. Run: `node tools/push_lookups.js`

  This script will write the documents under `lookups/business_types` and `lookups/cities`.
*/
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const os = require('os');

let initialized = false;

// Try Option 1: Service account key via GOOGLE_APPLICATION_CREDENTIALS
const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || path.join(os.homedir(), '.firebase', 'neuraltale-key.json');
if (fs.existsSync(keyPath)) {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✓ Initialized with service account key');
    initialized = true;
  } catch (e) {
    console.error('Failed to load service account key:', e.message);
  }
}

// Try Option 2: Firebase CLI credentials
if (!initialized) {
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    console.log('✓ Initialized with application default credentials');
    initialized = true;
  } catch (e) {
    // Continue to try other methods
  }
}

// Try Option 3: Application Default Credentials (for CI/CD)
if (!initialized) {
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    console.log('✓ Initialized with application default credentials');
    initialized = true;
  } catch (e) {
    console.error('Failed to initialize Firebase Admin:', e.message);
    console.error('\nTo fix this:');
    console.error('1. Run: firebase login');
    console.error('2. Or set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON');
    process.exit(1);
  }
}


const db = admin.firestore();

async function main() {
  const dataPath = path.join(__dirname, 'lookups.json');
  const raw = fs.readFileSync(dataPath, 'utf8');
  const json = JSON.parse(raw);

  if (json.business_types) {
    await db.collection('lookups').doc('business_types').set(json.business_types);
    console.log('Wrote lookups/business_types');
  }
  if (json.cities) {
    await db.collection('lookups').doc('cities').set(json.cities);
    console.log('Wrote lookups/cities');
  }
  console.log('Done.');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
