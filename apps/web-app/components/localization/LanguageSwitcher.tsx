import { useLanguage } from '@/lib/i18n-utils';

export const LanguageSwitcher = () => {
  const { locale, setLocale } = useLanguage();

  return (
    <div className="flex items-center gap-2">
      <label className="font-semibold">
        {locale === 'sw' ? 'Lugha' : 'Language'}
      </label>
      <select
        value={locale}
        onChange={(e) => setLocale(e.target.value)}
        className="px-3 py-2 border rounded-md"
      >
        <option value="en">English</option>
        <option value="sw">Kiswahili</option>
      </select>
    </div>
  );
};

export const LanguageSwitcherDropdown = () => {
  const { locale, setLocale, isSwahili } = useLanguage();

  return (
    <div className="relative group">
      <button className="px-4 py-2 hover:bg-gray-100 rounded-md">
        {isSwahili ? 'Kiswahili' : 'English'} ▼
      </button>
      <div className="hidden group-hover:block absolute right-0 bg-white border rounded-md shadow-lg">
        <button
          onClick={() => setLocale('en')}
          className={`block w-full text-left px-4 py-2 hover:bg-gray-100 ${
            locale === 'en' ? 'bg-blue-100' : ''
          }`}
        >
          English
        </button>
        <button
          onClick={() => setLocale('sw')}
          className={`block w-full text-left px-4 py-2 hover:bg-gray-100 ${
            locale === 'sw' ? 'bg-blue-100' : ''
          }`}
        >
          Kiswahili
        </button>
      </div>
    </div>
  );
};
