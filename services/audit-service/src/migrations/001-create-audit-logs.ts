/**
 * Database Migration: Create audit_logs table
 * Tracks all compliance-critical events
 * This table must never be cleaned up - permanent audit trail
 */

export async function createAuditLogsTable(db: any) {
  await db.query(`
    CREATE TABLE IF NOT EXISTS audit_logs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL,
      business_id UUID,
      action VARCHAR(50) NOT NULL,
      resource_type VARCHAR(50) NOT NULL,
      resource_id UUID,
      status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'failure')),
      timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      ip_address INET,
      user_agent TEXT,
      details JSONB,
      error_message TEXT,
      
      CONSTRAINT fk_audit_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_audit_user_timestamp 
      ON audit_logs(user_id, timestamp DESC);
    CREATE INDEX IF NOT EXISTS idx_audit_action ON audit_logs(action);
    CREATE INDEX IF NOT EXISTS idx_audit_business ON audit_logs(business_id);

    CREATE OR REPLACE VIEW audit_log_summary AS
    SELECT 
      user_id,
      DATE(timestamp) as date,
      action,
      COUNT(*) as count,
      SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as success_count,
      SUM(CASE WHEN status = 'failure' THEN 1 ELSE 0 END) as failure_count
    FROM audit_logs
    GROUP BY user_id, DATE(timestamp), action;
  `);

  console.log('✓ Audit logs table created');
}

export async function dropAuditLogsTable(db: any) {
  await db.query(`
    DROP VIEW IF EXISTS audit_log_summary;
    DROP TABLE IF EXISTS audit_logs;
  `);
  console.log('✓ Audit logs table dropped');
}
