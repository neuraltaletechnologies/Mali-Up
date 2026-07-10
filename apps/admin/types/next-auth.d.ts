import type { DefaultSession } from 'next-auth'

declare module 'next-auth' {
  interface Session {
    user: {
      isAdmin: boolean
    } & DefaultSession['user']
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    uid?: string
    isAdmin?: boolean
    adminCheckedAt?: number
  }
}
