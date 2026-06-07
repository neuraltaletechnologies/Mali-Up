import { z } from 'zod';

export const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(8),
  tenant_id: z.string().uuid(),
  role: z.enum(['ADMIN', 'MANAGER', 'USER']).default('USER'),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

export const lookupSchema = z.object({
  phone: z.string().regex(/^\+?[1-9]\d{1,14}$/, 'Invalid phone number format'),
});

export const recoverySchema = z.object({
  phone: z.string().regex(/^\+?[1-9]\d{1,14}$/, 'Invalid phone number format'),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type LookupInput = z.infer<typeof lookupSchema>;
export type RecoveryInput = z.infer<typeof recoverySchema>;
