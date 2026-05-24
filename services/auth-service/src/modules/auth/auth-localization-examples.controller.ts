import { BadRequestException, Controller, Post, Get, Body, Req, Param, Delete } from '@nestjs/common';
import { Request } from 'express';
import { I18nService } from '../../../common/i18n/i18n.service';
import { LocalizedExceptionFactory } from '../../../common/i18n/localized-exception.factory';

/**
 * Example: Auth Controller with Localized Error Messages
 * Shows how to use i18n in all API responses
 */
@Controller('auth')
export class AuthController {
  constructor(
    private readonly i18nService: I18nService,
    private readonly exceptionFactory: LocalizedExceptionFactory,
  ) {}

  @Post('signup')
  async signup(@Req() req: Request, @Body() body: any) {
    const locale = (req as any).i18n?.locale || 'en';

    if (!body.email) {
      throw this.exceptionFactory.badRequest('errors.requiredField', locale);
    }

    if (!body.password) {
      throw this.exceptionFactory.badRequest('errors.requiredField', locale);
    }

    return {
      statusCode: 201,
      message: this.i18nService.t('messages.success', locale),
      locale,
    };
  }

  @Post('login')
  async login(@Req() req: Request, @Body() body: any) {
    const locale = (req as any).i18n?.locale || 'en';

    if (!body.email) {
      throw this.exceptionFactory.badRequest('errors.requiredField', locale);
    }

    if (!body.password) {
      throw this.exceptionFactory.badRequest('errors.requiredField', locale);
    }

    return {
      statusCode: 200,
      message: this.i18nService.t('messages.success', locale),
      locale,
    };
  }
}
