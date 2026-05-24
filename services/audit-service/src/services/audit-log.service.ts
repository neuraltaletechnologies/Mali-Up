/**
 * Audit Log Service
 * Core service for logging compliance events
 * Used by all other services to track sensitive operations
 */

import { Injectable } from '@nestjs/common';
import { Database } from 'src/database';
import { AuditEvent, AuditEventInput } from '../models/audit-event.model';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AuditLogService {
  constructor(private readonly db: Database) {}

  /**
   * Log a compliance event
   * Called whenever a sensitive operation occurs
   */
  async log(event: Omit<AuditEventInput, 'id' | 'timestamp'>): Promise<string> {
    const id = uuidv4();
    const timestamp = new Date();

    try {
      await this.db.query(
        `INSERT INTO audit_logs 
          (id, user_id, business_id, action, resource_type, resource_id, status, 
           timestamp, ip_address, user_agent, details, error_message)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
        [
          id,
          event.userId,
          event.businessId || null,
          event.action,
          event.resourceType,
          event.resourceId || null,
          event.status,
          timestamp,
          event.ipAddress || null,
          event.userAgent || null,
          event.details ? JSON.stringify(event.details) : null,
          event.errorMessage || null,
        ]
      );

      return id;
    } catch (error) {
      // Log service errors but don't throw - audit logging should not break the app
      console.error('[AuditLogService] Error logging event:', error);
      throw error;
    }
  }

  /**
   * Get audit log for a specific user
   * User can view their own audit trail (PDPA transparency)
   */
  async getUserAuditLog(
    userId: string,
    filters?: {
      action?: AuditEvent['action'];
      startDate?: Date;
      endDate?: Date;
      limit?: number;
    }
  ): Promise<AuditEvent[]> {
    let query = `SELECT * FROM audit_logs WHERE user_id = $1`;
    const params: any[] = [userId];
    let paramIndex = 2;

    if (filters?.action) {
      query += ` AND action = $${paramIndex}`;
      params.push(filters.action);
      paramIndex++;
    }

    if (filters?.startDate) {
      query += ` AND timestamp >= $${paramIndex}`;
      params.push(filters.startDate);
      paramIndex++;
    }

    if (filters?.endDate) {
      query += ` AND timestamp <= $${paramIndex}`;
      params.push(filters.endDate);
      paramIndex++;
    }

    query += ` ORDER BY timestamp DESC LIMIT $${paramIndex}`;
    params.push(filters?.limit || 1000);

    const result = await this.db.query(query, params);
    return result.rows.map(row => ({
      ...row,
      details: row.details ? JSON.parse(row.details) : undefined,
    }));
  }

  /**
   * Get audit log for data access (for compliance reviews)
   * Only accessible to admins
   */
  async getAuditLogByAction(
    action: AuditEvent['action'],
    filters?: {
      startDate?: Date;
      endDate?: Date;
      limit?: number;
    }
  ): Promise<AuditEvent[]> {
    let query = `SELECT * FROM audit_logs WHERE action = $1`;
    const params: any[] = [action];
    let paramIndex = 2;

    if (filters?.startDate) {
      query += ` AND timestamp >= $${paramIndex}`;
      params.push(filters.startDate);
      paramIndex++;
    }

    if (filters?.endDate) {
      query += ` AND timestamp <= $${paramIndex}`;
      params.push(filters.endDate);
      paramIndex++;
    }

    query += ` ORDER BY timestamp DESC LIMIT $${paramIndex}`;
    params.push(filters?.limit || 1000);

    const result = await this.db.query(query, params);
    return result.rows.map(row => ({
      ...row,
      details: row.details ? JSON.parse(row.details) : undefined,
    }));
  }

  /**
   * Verify audit log integrity (no missing entries for sensitive operations)
   * Used for compliance audits
   */
  async verifyAuditIntegrity(userId: string, timeRange: { start: Date; end: Date }): Promise<boolean> {
    const result = await this.db.query(
      `SELECT COUNT(*) as count FROM audit_logs 
       WHERE user_id = $1 AND timestamp BETWEEN $2 AND $3`,
      [userId, timeRange.start, timeRange.end]
    );

    return result.rows[0].count > 0;
  }
}
