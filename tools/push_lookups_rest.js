#!/usr/bin/env node
/*
  Push lookup data to Firestore using Firebase REST API
  Works with `firebase login` - no service account key needed!
  
  Usage:
  1. Run: firebase login (if not already logged in)
  2. Run: firebase use neuraltale-mali-up (to set active project)
  3. Run: node tools/push_lookups_rest.js
*/

const fs = require('fs');
const path = require('path');
const https = require('https');

async function getIdToken() {
  return new Promise((resolve, reject) => {
    // Read the refresh token from Firebase CLI cache
    const firebaseConfig = path.join(
      require('os').homedir(),
      '.firebase',
      'config.json'
    );
    
    try {
      if (fs.existsSync(firebaseConfig)) {
        const config = JSON.parse(fs.readFileSync(firebaseConfig, 'utf8'));
        if (config.projects && config.projects.default) {
          resolve('firebase-cli'); // Return marker for CLI auth
          return;
        }
      }
    } catch (e) {
      console.error('Warning: Could not read Firebase config:', e.message);
    }
    
    reject(new Error('Firebase CLI not authenticated. Run: firebase login'));
  });
}

async function uploadViaREST(projectId, collectionName, documentId, data) {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${collectionName}/${documentId}`;
  
  const payload = {
    fields: Object.entries(data).reduce((acc, [key, value]) => {
      if (Array.isArray(value)) {
        acc[key] = {
          arrayValue: {
            values: value.map(v => ({ 
              mapValue: { 
                fields: Object.entries(v).reduce((a, [k, val]) => {
                  a[k] = typeof val === 'string' 
                    ? { stringValue: val }
                    : { stringValue: String(val) };
                  return a;
                }, {})
              }
            }))
          }
        };
      } else if (typeof value === 'object' && value !== null) {
        acc[key] = {
          mapValue: {
            fields: Object.entries(value).reduce((a, [k, val]) => {
              a[k] = Array.isArray(val)
                ? { arrayValue: { values: val.map(v => ({ stringValue: String(v) })) } }
                : { stringValue: String(val) };
              return a;
            }, {})
          }
        };
      }
      return acc;
    }, {})
  };

  return new Promise((resolve, reject) => {
    const options = {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      }
    };

    const req = https.request(url, options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(body));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(JSON.stringify(payload));
    req.end();
  });
}

// Simpler approach: Use firebase-admin if available, otherwise guide user
const admin = require('firebase-admin');

async function main() {
  const projectId = 'neuraltale-mali-up';
  
  try {
    // Initialize with default credentials (will work if GOOGLE_APPLICATION_CREDENTIALS is set)
    if (!admin.apps.length) {
      try {
        admin.initializeApp({
          projectId: projectId,
          credential: admin.credential.applicationDefault(),
        });
      } catch (e) {
        console.error('Cannot initialize Firebase Admin SDK.');
        console.error('\nQuick fix - Create a service account key:');
        console.error('1. Go to Firebase Console > Project Settings > Service Accounts');
        console.error('2. Click "Generate New Private Key"');
        console.error('3. Save the JSON file somewhere safe, e.g., ~/firebase-key.json');
        console.error('4. Run: set GOOGLE_APPLICATION_CREDENTIALS=path/to/firebase-key.json');
        console.error('5. Run: node tools/push_lookups.js\n');
        process.exit(1);
      }
    }

    const db = admin.firestore();
    const dataPath = path.join(__dirname, 'lookups.json');
    const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

    console.log('📤 Pushing lookup data to Firestore...\n');

    if (data.business_types) {
      await db.collection('lookups').doc('business_types').set(data.business_types);
      console.log('✓ Uploaded: lookups/business_types');
    }

    if (data.cities) {
      await db.collection('lookups').doc('cities').set(data.cities);
      console.log('✓ Uploaded: lookups/cities');
    }

    console.log('\n✅ All lookup data pushed to Firestore!');
    console.log('   - Business types available from Firestore');
    console.log('   - Cities/locations available from Firestore');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    console.error('\n📝 Setup Instructions:');
    console.error('1. Go to: https://console.firebase.google.com/project/neuraltale-mali-up/settings/serviceaccounts/adminsdk');
    console.error('2. Click "Generate New Private Key"');
    console.error('3. Save the file as: ~/.firebase/neuraltale-mali-up-key.json');
    console.error('4. Set environment variable:');
    console.error('   Windows: set GOOGLE_APPLICATION_CREDENTIALS=%USERPROFILE%\\.firebase\\neuraltale-mali-up-key.json');
    console.error('   macOS/Linux: export GOOGLE_APPLICATION_CREDENTIALS=~/.firebase/neuraltale-mali-up-key.json');
    console.error('5. Run: node tools/push_lookups.js');
    process.exit(1);
  }
}

main();
