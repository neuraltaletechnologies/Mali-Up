import { useTranslations } from '@/lib/i18n-utils';
import { formatCurrency, formatDate } from '@/lib/i18n-utils';

export const InvoiceDashboard = () => {
  const { t } = useTranslations('finance');
  const { t: tCommon } = useTranslations('common');

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">{t('invoiceList')}</h1>

      <div className="grid gap-4">
        {/* Invoice Card */}
        <div className="border rounded-lg p-4 hover:shadow-lg">
          <div className="flex justify-between items-center">
            <div>
              <h3 className="font-bold">INV-001</h3>
              <p className="text-sm text-gray-600">
                {formatDate(new Date())}
              </p>
            </div>
            <div className="text-right">
              <p className="text-lg font-bold">
                {formatCurrency(150000.00)}
              </p>
              <span className="text-xs bg-blue-100 px-2 py-1 rounded">
                {t('paid')}
              </span>
            </div>
          </div>
        </div>
      </div>

      <button className="mt-6 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
        {tCommon('add')}
      </button>
    </div>
  );
};
