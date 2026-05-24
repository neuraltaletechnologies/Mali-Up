import { SupportedLocale } from './i18n.service';

declare global {
  namespace Express {
    interface Request {
      i18n?: {
        locale: SupportedLocale;
        t: (key: string, params?: Record<string, string | number>, defaultValue?: string) => string;
        tp: (key: string, params: Record<string, string | number>, defaultValue?: string) => string;
      };
    }
  }
}

export {};
