import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

export interface TranslationKey {
  [key: string]: string | TranslationKey;
}

export type SupportedLocale = 'en' | 'sw';

@Injectable()
export class I18nService {
  private translations: Map<SupportedLocale, TranslationKey> = new Map();
  private readonly localesPath = path.join(__dirname, '../../../locales');
  private readonly supportedLocales: SupportedLocale[] = ['en', 'sw'];
  private readonly defaultLocale: SupportedLocale = 'en';

  constructor() {
    this.loadTranslations();
  }

  /**
   * Load all translation files
   */
  private loadTranslations(): void {
    for (const locale of this.supportedLocales) {
      try {
        const filePath = path.join(this.localesPath, `${locale}.json`);
        if (fs.existsSync(filePath)) {
          const content = fs.readFileSync(filePath, 'utf-8');
          this.translations.set(locale, JSON.parse(content));
        }
      } catch (error) {
        console.error(`Failed to load translations for locale ${locale}:`, error);
      }
    }
  }

  /**
   * Get translation by key and locale
   * @param key Dot-notation key (e.g., 'common.home')
   * @param locale Language locale
   * @param defaultValue Fallback value if translation not found
   * @returns Translated string or default value
   */
  t(key: string, locale?: SupportedLocale, defaultValue?: string): string {
    const targetLocale = locale || this.defaultLocale;
    const translations = this.translations.get(targetLocale);

    if (!translations) {
      return defaultValue || key;
    }

    const keys = key.split('.');
    let value: any = translations;

    for (const k of keys) {
      if (value && typeof value === 'object' && k in value) {
        value = value[k];
      } else {
        // Try fallback to English if not found in target locale
        if (targetLocale !== this.defaultLocale) {
          return this.t(key, this.defaultLocale, defaultValue || key);
        }
        return defaultValue || key;
      }
    }

    return typeof value === 'string' ? value : (defaultValue || key);
  }

  /**
   * Get translation with parameters substitution
   * @param key Translation key
   * @param params Object with values to substitute
   * @param locale Language locale
   * @returns Translated and interpolated string
   */
  tp(key: string, params: Record<string, string | number>, locale?: SupportedLocale): string {
    const translation = this.t(key, locale);
    let result = translation;

    for (const [param, value] of Object.entries(params)) {
      result = result.replace(`{${param}}`, String(value));
    }

    return result;
  }

  /**
   * Get all translations for a namespace
   * @param namespace Namespace (e.g., 'common', 'finance')
   * @param locale Language locale
   * @returns All translations in namespace
   */
  getNamespace(namespace: string, locale?: SupportedLocale): TranslationKey {
    const targetLocale = locale || this.defaultLocale;
    const translations = this.translations.get(targetLocale);
    return (translations?.[namespace] as TranslationKey) || {};
  }

  /**
   * Detect locale from Accept-Language header
   * @param acceptLanguage Accept-Language header value
   * @returns Best matching supported locale
   */
  detectLocale(acceptLanguage?: string): SupportedLocale {
    if (!acceptLanguage) {
      return this.defaultLocale;
    }

    // Parse Accept-Language header
    const locales = acceptLanguage
      .split(',')
      .map((lang) => {
        const [code, q = 'q=1'] = lang.split(';');
        const quality = parseFloat(q.replace('q=', ''));
        return { code: code.trim().split('-')[0], quality };
      })
      .sort((a, b) => b.quality - a.quality);

    // Find first supported locale
    for (const { code } of locales) {
      if (this.supportedLocales.includes(code as SupportedLocale)) {
        return code as SupportedLocale;
      }
    }

    return this.defaultLocale;
  }

  /**
   * Check if locale is supported
   * @param locale Language locale code
   * @returns True if locale is supported
   */
  isSupportedLocale(locale: string): locale is SupportedLocale {
    return this.supportedLocales.includes(locale as SupportedLocale);
  }

  /**
   * Get list of supported locales
   * @returns Array of supported locale codes
   */
  getSupportedLocales(): SupportedLocale[] {
    return [...this.supportedLocales];
  }
}
