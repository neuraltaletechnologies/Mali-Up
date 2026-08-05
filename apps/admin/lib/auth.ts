import NextAuth from 'next-auth'
import Credentials from 'next-auth/providers/credentials'
import { verifyIdToken, isAdminUser } from './firebase-admin'
import { z } from 'zod'

// The login page signs the user in via the Firebase client SDK, gets an
// ID token, then sends it here. We never receive or store passwords.
const credentialsSchema = z.object({
  idToken: z.string().min(1, 'ID token is required'),
})

// How often to re-verify the admin claim against Firebase Auth + Firestore
// for an already-signed-in session. Every `auth()` call used to do this
// unconditionally (2 sequential network round trips per API request); now
// it's cached in the JWT and only re-checked once this interval elapses.
const ADMIN_RECHECK_INTERVAL_MS = 5 * 60 * 1000

function resolveAuthSecret() {
  const explicitSecret = process.env.AUTH_SECRET ?? process.env.NEXTAUTH_SECRET
  if (explicitSecret) return explicitSecret

  const projectId = process.env.FIREBASE_PROJECT_ID
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL
  const privateKey = process.env.FIREBASE_PRIVATE_KEY

  // Cloudflare runtime secrets are sometimes wired for Firebase admin only.
  // Reuse those same credentials as a stable fallback so Auth.js can still
  // sign sessions even when a dedicated NextAuth secret was not provisioned.
  if (projectId && clientEmail && privateKey) {
    return [projectId, clientEmail, privateKey].join(':')
  }

  return undefined
}

export const { handlers, signIn, signOut, auth } = NextAuth({
  secret: resolveAuthSecret(),
  trustHost: true,
  providers: [
    Credentials({
      id: 'firebase',
      name: 'Firebase',
      credentials: {
        // The raw password is never sent here — only the Firebase ID token.
        idToken: { label: 'Firebase ID Token', type: 'text' },
      },
      async authorize(credentials) {
        const parsed = credentialsSchema.safeParse(credentials)
        if (!parsed.success) return null

        let decoded
        try {
          decoded = await verifyIdToken(parsed.data.idToken)
        } catch (err: any) {
          console.error(
            '[Auth Error] verifyIdToken failed on server:',
            err?.code ?? 'NO_CODE',
            err?.message ?? err
          )
          return null
        }

        let hasAdminAccess = false
        try {
          hasAdminAccess = await isAdminUser(decoded.uid)
        } catch (err) {
          console.error('[Auth Error] isAdminUser check failed on server:', err)
          return null
        }

        if (!hasAdminAccess) {
          return null
        }

        return {
          id:    decoded.uid,
          email: decoded.email ?? '',
          name:  decoded.name ?? decoded.email ?? '',
        }
      },
    }),
  ],

  pages: {
    signIn: '/admin/login',
  },

  // Default NextAuth session lifetime is 30 days — too long for an admin
  // portal. Cap the cookie itself at 1 day; isAdmin is still rechecked
  // against Firebase/Firestore every ADMIN_RECHECK_INTERVAL_MS regardless.
  session: { strategy: 'jwt', maxAge: 24 * 60 * 60 },

  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        // Fresh sign-in: authorize() above already verified admin access.
        token.uid           = user.id
        token.email         = user.email
        token.name          = user.name
        token.isAdmin       = true
        token.adminCheckedAt = Date.now()
        return token
      }

      // Existing session: only hit Firebase Auth + Firestore again once the
      // recheck interval has elapsed, so most requests stay cache-only.
      const checkedAt = typeof token.adminCheckedAt === 'number' ? token.adminCheckedAt : 0
      if (Date.now() - checkedAt > ADMIN_RECHECK_INTERVAL_MS) {
        token.isAdmin        = token.uid ? await isAdminUser(token.uid as string) : false
        token.adminCheckedAt = Date.now()
      }
      return token
    },
    async session({ session, token }) {
      if (session.user) {
        session.user.id      = token.uid as string
        session.user.email   = token.email as string
        session.user.name    = token.name as string
        session.user.isAdmin = token.isAdmin === true
      }
      return session
    },
  },
})
