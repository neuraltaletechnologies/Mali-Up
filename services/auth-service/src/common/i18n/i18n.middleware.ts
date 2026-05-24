import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { I18nService, SupportedLocale } from './i18n.service';

/**
 * Middleware to detect and inject locale into requests
 * Detects locale from:
 * 1. URL parameter (e.g., /api/v1/sw/auth/login)
 * 2. Query parameter (e.g., ?locale=sw)
 * 3. Accept-Language header (e.g., Accept-Language: sw-TZ, en;q=0.9)
 * 4. Cookie (e.g., locale=sw)
 * 5. Default to 'en'
 */
@Injectable()
export class I18nMiddleware implements NestMiddleware {
  constructor(private readonly i18nService: I18nService) {}

  use(req: Request, _res: Response, next: NextFunction) {
    let locale: SupportedLocale = 'en';

    // 1. Check URL parameter (e.g., /api/v1/sw/...)
    const urlMatch = req.path.match(/^\/(?:api\/v\d\/)?([a-z]{2})(?:\/|$)/);
    if (urlMatch && this.i18nService.isSupportedLocale(urlMatch[1])) {
      locale = urlMatch[1] as SupportedLocale;
    }

    // 2. Check query parameter
    if (req.query.locale) {
      const queryLocale = String(req.query.locale);
      if (this.i18nService.isSupportedLocale(queryLocale)) {
        locale = queryLocale;
      }
    }

    // 3. Check Accept-Language header
    const acceptLanguage = req.headers['accept-language'];
    if (acceptLanguage) {
      const detectedLocale = this.i18nService.detectLocale(acceptLanguage);
      locale = detectedLocale;
    }

    // 4. Check cookie
    const cookieLocale = this.getCookieLocale(req);
    if (cookieLocale && this.i18nService.isSupportedLocale(cookieLocale)) {
      locale = cookieLocale;
    }

    // Attach locale to request object
    (req as any).i18n = {
      locale,
      t: (key: string, params?: Record<string, string | number>, defaultValue?: string) =>
        params
          ? this.i18nService.tp(key, params, locale)
          : this.i18nService.t(key, locale, defaultValue),
      tp: (key: string, params: Record<string, string | number>, defaultValue?: string) =>
        this.i18nService.tp(key, params, locale),
    };

    next();
  }

  private getCookieLocale(req: Request): string | null {
    if (!req.headers.cookie) {
      return null;
    }

    const cookies = req.headers.cookie.split(';');
    for (const cookie of cookies) {
      const [name, value] = cookie.trim().split('=');
      if (name === 'locale') {
        return value;
      }
    }

    return null;
  }
}
