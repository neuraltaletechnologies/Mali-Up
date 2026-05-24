/**
 * Audit Log Controller
 * API endpoints for audit log access (user and admin)
 */

import { Controller, Get, Query, UseGuards, Request, BadRequestException } from '@nestjs/common';
import { JwtAuthGuard } from 'src/guards/jwt-auth.guard';
import { AuditLogService } from '../services/audit-log.service';
import { AuditEvent } from '../models/audit-event.model';

@Controller('api/audit-logs')
@UseGuards(JwtAuthGuard)
export class AuditLogController {
  constructor(private readonly auditLogService: AuditLogService) {}

  /**
   * GET /api/audit-logs
   * Get user's own audit log
   * Shows history of sensitive actions (exports, deletions, logins, etc)
   * PDPA compliance: Users can view their own activity
   */
  @Get('/')
  async getUserAuditLog(
    @Request() req: any,
    @Query('action') action?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('limit') limit?: string
  ): Promise<AuditEvent[]> {
    const userId = req.user?.id;
    if (!userId) {
      throw new BadRequestException('User not authenticated');
    }

    const filters = {
      action: action as any,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      limit: limit ? parseInt(limit) : 100,
    };

    // Validate dates
    if (filters.startDate && filters.endDate && filters.startDate > filters.endDate) {
      throw new BadRequestException('Start date must be before end date');
    }

    return this.auditLogService.getUserAuditLog(userId, filters);
  }

  /**
   * GET /api/audit-logs/summary
   * Get summary of audit log activity
   * Shows count by action type
   */
  @Get('/summary')
  async getAuditSummary(@Request() req: any) {
    const userId = req.user?.id;
    if (!userId) {
      throw new BadRequestException('User not authenticated');
    }

    const logs = await this.auditLogService.getUserAuditLog(userId, { limit: 10000 });

    const summary = {
      total: logs.length,
      byAction: {} as Record<string, number>,
      byStatus: { success: 0, failure: 0 } as Record<string, number>,
      lastActivity: logs[0]?.timestamp,
      firstActivity: logs[logs.length - 1]?.timestamp,
    };

    logs.forEach(log => {
      summary.byAction[log.action] = (summary.byAction[log.action] || 0) + 1;
      summary.byStatus[log.status] = (summary.byStatus[log.status] || 0) + 1;
    });

    return summary;
  }
}
