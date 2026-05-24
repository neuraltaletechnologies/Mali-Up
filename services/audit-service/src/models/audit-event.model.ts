/**
 * Audit Event Model
 * Tracks all compliance-critical events (data access, export, deletion, etc)
 * Non-deletable for audit trail integrity
 */

export interface AuditEvent {
  id: string;
  userId: string;
  businessId?: string;
  action: 
    | 'DATA_EXPORT'
    | 'DATA_DELETE'
    | 'BRELA_CHECK'
    | 'MPESA_IMPORT'
    | 'LOGIN'
    | 'LOGOUT'
    | 'ACCOUNT_CREATED'
    | 'ACCOUNT_DELETED'
    | 'CONSENT_ACCEPTED'
    | 'CONSENT_WITHDRAWN'
    | 'PIN_SET'
    | 'BIOMETRIC_ENABLED'
    | 'BIOMETRIC_DISABLED';
  resourceType: 'user' | 'invoice' | 'customer' | 'expense' | 'inventory' | 'business';
  resourceId?: string;
  status: 'success' | 'failure';
  timestamp: Date;
  ipAddress?: string;
  userAgent?: string;
  details?: Record<string, any>;
  errorMessage?: string;
}

export interface AuditEventInput {
  userId: string;
  businessId?: string;
  action: AuditEvent['action'];
  resourceType: AuditEvent['resourceType'];
  resourceId?: string;
  status: 'success' | 'failure';
  ipAddress?: string;
  userAgent?: string;
  details?: Record<string, any>;
  errorMessage?: string;
}
