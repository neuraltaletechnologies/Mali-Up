import { useTranslation } from 'next-i18next';
import { useRouter } from 'next/router';
import { useCallback } from 'react';

/**
 * Hook for accessing translations in Next.js components
 * Usage:
 *   const { t } = useTranslations('common');
 *   return <button>{t('add')}</button>
 */
export const useTranslations = (namespace: string = 'common') => {
  const { t } = useTranslation(namespace);
  return { t };
};

/**
 * Hook for accessing multiple namespaces
 * Usage:
 *   const { t: tCommon, t: tFinance } = useTranslationsMultiple(['common', 'finance']);
 */
export const useTranslationsMultiple = (namespaces: string[]) => {
  const translations: Record<string, (key: string) => string> = {};
  
  namespaces.forEach((namespace) => {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    const { t } = useTranslation(namespace);
    translations[namespace] = t;
  });
  
  return translations;
};

/**
 * Hook for language switching
 * Usage:
 *   const { locale, toggleLocale, setLocale } = useLanguage();
 */
export const useLanguage = () => {
  const router = useRouter();
  const { locale, defaultLocale } = router;

  const setLocale = useCallback(
    (newLocale: string) => {
      const { pathname, query, asPath } = router;
      
      // Keep the same path, just change locale
      router.push(
        { pathname, query },
        asPath.replace(`/${locale || defaultLocale}`, `/${newLocale}`),
        { locale: newLocale }
      );
      
      // Save to cookie
      document.cookie = `locale=${newLocale};path=/;max-age=31536000`;
    },
    [router, locale, defaultLocale]
  );

  const toggleLocale = useCallback(() => {
    const newLocale = locale === 'sw' ? 'en' : 'sw';
    setLocale(newLocale);
  }, [locale, setLocale]);

  return {
    locale: locale || defaultLocale,
    setLocale,
    toggleLocale,
    isSwahili: locale === 'sw',
    isEnglish: locale === 'en',
  };
};

/**
 * Format currency for display (TSh with proper formatting)
 * Usage:
 *   const formatted = formatCurrency(15000.50);
 *   // Output: "TSh 15,000.50"
 */
export const formatCurrency = (amount: number, _locale?: string): string => {
  const formatter = new Intl.NumberFormat('sw-TZ', {
    style: 'currency',
    currency: 'TZS',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  
  return formatter.format(amount);
};

/**
 * Format date in DD/MM/YYYY (Tanzanian standard)
 * Usage:
 *   const formatted = formatDate(new Date());
 *   // Output: "24/05/2026"
 */
export const formatDate = (date: Date, _locale?: string): string => {
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();
  
  return `${day}/${month}/${year}`;
};

/**
 * Format date with month name (Kiswahili)
 * Usage:
 *   const formatted = formatDateWithMonth(new Date(), 'sw');
 *   // Output: "24 Mei 2026"
 */
export const formatDateWithMonth = (date: Date, locale: string = 'sw'): string => {
  const months = {
    sw: [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ],
    en: [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ],
  };

  const day = date.getDate();
  const monthName = (months[locale as keyof typeof months] || months.en)[date.getMonth()];
  const year = date.getFullYear();

  return `${day} ${monthName} ${year}`;
};

/**
 * Format relative date (Leo, Jana, Kesho)
 * Usage:
 *   const formatted = formatRelativeDate(yesterday, 'sw');
 *   // Output: "Jana"
 */
export const formatRelativeDate = (date: Date, locale: string = 'sw'): string => {
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const dateStr = formatDate(date);
  const todayStr = formatDate(today);
  const yesterdayStr = formatDate(yesterday);
  const tomorrowStr = formatDate(tomorrow);

  const relativeDates = {
    sw: {
      today: 'Leo',
      yesterday: 'Jana',
      tomorrow: 'Kesho',
    },
    en: {
      today: 'Today',
      yesterday: 'Yesterday',
      tomorrow: 'Tomorrow',
    },
  };

  const rel = relativeDates[locale as keyof typeof relativeDates] || relativeDates.en;

  if (dateStr === todayStr) return rel.today;
  if (dateStr === yesterdayStr) return rel.yesterday;
  if (dateStr === tomorrowStr) return rel.tomorrow;

  return formatDate(date);
};

/**
 * Format time (24-hour format)
 * Usage:
 *   const formatted = formatTime(new Date());
 *   // Output: "14:30"
 */
export const formatTime = (date: Date): string => {
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  
  return `${hours}:${minutes}`;
};

/**
 * Format number with thousand separators (space)
 * Usage:
 *   const formatted = formatNumber(1000000);
 *   // Output: "1 000 000"
 */
export const formatNumber = (num: number): string => {
  return new Intl.NumberFormat('sw-TZ', {
    useGrouping: true,
  }).format(num);
};

/**
 * Parse currency string to number
 * Usage:
 *   const num = parseCurrency("TSh 15,000.50");
 *   // Output: 15000.50
 */
export const parseCurrency = (value: string): number | null => {
  try {
    const cleaned = value.replace(/[^\d.]/g, '');
    return parseFloat(cleaned);
  } catch (error) {
    return null;
  }
};

/**
 * Get supported locales
 */
export const getSupportedLocales = (): Array<{ code: string; name: string }> => {
  return [
    { code: 'en', name: 'English' },
    { code: 'sw', name: 'Kiswahili' },
  ];
};

/**
 * Get locale display name
 */
export const getLocaleDisplayName = (locale: string): string => {
  const localeMap: Record<string, string> = {
    en: 'English',
    sw: 'Kiswahili',
  };
  
  return localeMap[locale] || locale;
};
