import type { Config } from 'next-i18next';
import path from 'path';

const config: Config = {
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'sw'],
  },
  ns: [
    'common',
    'finance',
    'inventory',
    'reporting',
    'compliance',
    'business',
    'errors',
    'emptyStates',
    'dates',
    'auth',
    'messages',
  ],
  defaultNS: 'common',
  backend: {
    loadPath: path.join(process.cwd(), 'public/locales/{{lng}}/{{ns}}.json'),
  },
  localePath: path.resolve('./public/locales'),
  nsSeparator: ':',
  keySeparator: '.',
  interpolation: {
    escapeValue: false,
  },
  detection: {
    order: ['path', 'cookie', 'header'],
    caches: ['cookie'],
  },
  react: {
    bindI18n: 'languageChanged loaded',
    bindI18nStore: 'added removed',
    transSupportBasicHtmlNodes: true,
    transKeepBasicHtmlNodesFor: ['br', 'strong', 'i', 'p'],
    useSuspense: false,
  },
};

export default config;
