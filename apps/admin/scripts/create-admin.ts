import 'dotenv/config'
import admin from 'firebase-admin'

const projectId     = process.env.FIREBASE_PROJECT_ID ?? 'neuraltale-mali-up'
const clientEmail   = process.env.FIREBASE_CLIENT_EMAIL!
const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY!

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey: rawPrivateKey.replace(/\\n/g, '\n'),
    }),
    projectId,
  })
}

const authClient = admin.auth()
const db         = admin.firestore()

const EMAIL = 'juliusntale@neuraltale.com'
const PASS  = 'MaliUp@Admin2026!'

async function run() {
  let uid: string

  try {
    const existing = await authClient.getUserByEmail(EMAIL)
    uid = existing.uid
    console.log('User already exists, uid:', uid)
  } catch {
    const created = await authClient.createUser({
      email:         EMAIL,
      password:      PASS,
      displayName:   'Julius Ntale',
      emailVerified: true,
    })
    uid = created.uid
    console.log('Created user, uid:', uid)
  }

  const existing = await authClient.getUser(uid)
  const claims   = (existing.customClaims ?? {}) as Record<string, unknown>
  await authClient.setCustomUserClaims(uid, { ...claims, admin: true })

  await db.collection('platform_admins').doc(uid).set({
    uid,
    email:       EMAIL,
    displayName: 'Julius Ntale',
    grantedAt:   admin.firestore.FieldValue.serverTimestamp(),
    grantedBy:   'create-admin-script',
  }, { merge: true })

  console.log('\n✓ Admin access granted')
  console.log('  Email:    ', EMAIL)
  console.log('  Password: ', PASS)
  console.log('  UID:      ', uid)
  console.log('\nSign in at http://localhost:3001/login\n')
}

run().catch((err) => {
  console.error('Failed:', err.message)
  process.exit(1)
})
