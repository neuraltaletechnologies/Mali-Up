import NextAuth from 'next-auth'
import Credentials from 'next-auth/providers/credentials'
import { verifyIdToken, isAdminUser } from './firebase-admin'
import { z } from 'zod'

// The login page signs the user in via the Firebase client SDK, gets an
// ID token, then sends it here. We never receive or store passwords.
const credentialsSchema = z.object({
  idToken: z.string().min(1, 'ID token is required'),
})

export const { handlers, signIn, signOut, auth } = NextAuth({
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
        } catch {
          // Token invalid, expired, or revoked
          return null
        }

        const hasAdminAccess = await isAdminUser(decoded.uid)
        if (!hasAdminAccess) {
          // Valid Firebase user, but not a platform admin
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

  session: { strategy: 'jwt' },

  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.uid   = user.id
        token.email = user.email
        token.name  = user.name
      }
      return token
    },
    async session({ session, token }) {
      if (session.user) {
        session.user.id    = token.uid as string
        session.user.email = token.email as string
        session.user.name  = token.name as string
      }
      return session
    },
  },
})
