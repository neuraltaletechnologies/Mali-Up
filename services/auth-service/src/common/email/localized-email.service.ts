import { Injectable } from '@nestjs/common';
import { MailerService } from '@nestjs-modules/mailer';
import { I18nService } from '../i18n/i18n.service';

interface EmailContext {
  userName?: string;
  userEmail: string;
  resetLink?: string;
  invoiceId?: string;
  invoiceAmount?: string;
  paymentAmount?: string;
  businessName?: string;
  locale?: string;
}

/**
 * Service for sending localized emails
 * All templates are sent in user's preferred language
 */
@Injectable()
export class LocalizedEmailService {
  constructor(
    private readonly mailerService: MailerService,
    private readonly i18nService: I18nService,
  ) {}

  /**
   * Send welcome email (signup)
   */
  async sendWelcomeEmail(userEmail: string, userName: string, locale?: string) {
    const subject = this.i18nService.t('email.welcome.subject', locale);
    const template = locale === 'sw' ? 'welcome-sw' : 'welcome-en';

    await this.mailerService.sendMail({
      to: userEmail,
      subject,
      template,
      context: {
        userName,
        greeting: this.i18nService.t('email.welcome.greeting', locale),
        message: this.i18nService.t('email.welcome.message', locale),
        cta: this.i18nService.t('email.welcome.cta', locale),
      },
    });
  }

  /**
   * Send password reset email
   */
  async sendPasswordResetEmail(
    userEmail: string,
    userName: string,
    resetLink: string,
    locale?: string,
  ) {
    const subject = this.i18nService.t('email.passwordReset.subject', locale);
    const template = locale === 'sw' ? 'password-reset-sw' : 'password-reset-en';

    await this.mailerService.sendMail({
      to: userEmail,
      subject,
      template,
      context: {
        userName,
        message: this.i18nService.t('email.passwordReset.message', locale),
        resetLink,
        linkText: this.i18nService.t('email.passwordReset.linkText', locale),
        expirationWarning: this.i18nService.t(
          'email.passwordReset.expirationWarning',
          locale,
        ),
        notRequested: this.i18nService.t('email.passwordReset.notRequested', locale),
      },
    });
  }

  /**
   * Send invoice notification
   */
  async sendInvoiceNotification(
    userEmail: string,
    userName: string,
    invoiceId: string,
    invoiceAmount: string,
    locale?: string,
  ) {
    const subject = this.i18nService.tp(
      'email.invoice.subject',
      { invoiceId },
      locale,
    );
    const template = locale === 'sw' ? 'invoice-sent-sw' : 'invoice-sent-en';

    await this.mailerService.sendMail({
      to: userEmail,
      subject,
      template,
      context: {
        userName,
        message: this.i18nService.t('email.invoice.message', locale),
        invoiceId,
        invoiceAmount,
        viewLink: this.i18nService.t('email.invoice.viewLink', locale),
        sendReminder: this.i18nService.t('email.invoice.sendReminder', locale),
      },
    });
  }

  /**
   * Send payment confirmation email
   */
  async sendPaymentConfirmation(
    userEmail: string,
    userName: string,
    paymentAmount: string,
    locale?: string,
  ) {
    const subject = this.i18nService.t('email.payment.subject', locale);
    const template = locale === 'sw' ? 'payment-received-sw' : 'payment-received-en';

    await this.mailerService.sendMail({
      to: userEmail,
      subject,
      template,
      context: {
        userName,
        message: this.i18nService.t('email.payment.message', locale),
        paymentAmount,
        thankYou: this.i18nService.t('email.payment.thankYou', locale),
        viewReceipt: this.i18nService.t('email.payment.viewReceipt', locale),
      },
    });
  }

  /**
   * Send account suspended alert
   */
  async sendAccountSuspendedAlert(
    userEmail: string,
    userName: string,
    reason: string,
    locale?: string,
  ) {
    const subject = this.i18nService.t('email.accountSuspended.subject', locale);
    const template = locale === 'sw' ? 'suspended-sw' : 'suspended-en';

    await this.mailerService.sendMail({
      to: userEmail,
      subject,
      template,
      context: {
        userName,
        alert: this.i18nService.t('email.accountSuspended.alert', locale),
        reason,
        contactSupport: this.i18nService.t(
          'email.accountSuspended.contactSupport',
          locale,
        ),
        supportEmail: 'support@maliup.com',
      },
    });
  }

  /**
   * Send low stock alert
   */
  async sendLowStockAlert(
    userEmail: string,
    businessName: string,
    productName: string,
    currentStock: number,
    locale?: string,
  ) {
    const subject = this.i18nService.t('email.lowStock.subject', locale);
    const template = locale === 'sw' ? 'low-stock-sw' : 'low-stock-en';

    await this.mailerService.sendMail({
      to: userEmail,
      subject,
      template,
      context: {
        businessName,
        message: this.i18nService.t('email.lowStock.message', locale),
        productName,
        currentStock,
        reorderNow: this.i18nService.t('email.lowStock.reorderNow', locale),
      },
    });
  }

  /**
   * Send daily summary email
   */
  async sendDailySummaryEmail(
    userEmail: string,
    businessName: string,
    summary: {
      totalSales: string;
      totalExpenses: string;
      netIncome: string;
      newCustomers: number;
    },
    locale?: string,
  ) {
    const subject = this.i18nService.t('email.summary.subject', locale);
    const template = locale === 'sw' ? 'daily-summary-sw' : 'daily-summary-en';

    await this.mailerService.sendMail({
      to: userEmail,
      subject,
      template,
      context: {
        businessName,
        greeting: this.i18nService.t('email.summary.greeting', locale),
        totalSalesLabel: this.i18nService.t('email.summary.totalSales', locale),
        totalSales: summary.totalSales,
        totalExpensesLabel: this.i18nService.t(
          'email.summary.totalExpenses',
          locale,
        ),
        totalExpenses: summary.totalExpenses,
        netIncomeLabel: this.i18nService.t('email.summary.netIncome', locale),
        netIncome: summary.netIncome,
        newCustomersLabel: this.i18nService.t(
          'email.summary.newCustomers',
          locale,
        ),
        newCustomers: summary.newCustomers,
        viewDetails: this.i18nService.t('email.summary.viewDetails', locale),
      },
    });
  }
}
