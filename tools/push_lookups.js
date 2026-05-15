/*
  Usage:
  1. Install Firebase Admin: `npm install firebase-admin`
  2. Set `GOOGLE_APPLICATION_CREDENTIALS` to a service account JSON with Firestore access.
  3. Run: `node tools/push_lookups.js`

  This script will write the documents under `lookups/business_types` and `lookups/cities`.
*/
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!keyPath) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

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
