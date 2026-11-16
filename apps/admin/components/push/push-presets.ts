import type { BroadcastCategory } from '@/types'

/**
 * Push notification templates for the admin "Push Notifications" composer —
 * the push counterpart of the Beem SMS `campaign-presets.ts`. Picking one
 * fills the EN/SW title + body, category, tap destination and whether it is
 * kept in the in-app notifications list; everything stays editable after.
 *
 * Limits mirror the composer inputs: title ≤ 80 chars, body ≤ 200 chars.
 * No {name} placeholders — topic pushes are one message for every device.
 */
export interface PushPreset {
  id: string
  icon: string
  title: string
  subtitle: string
  category: BroadcastCategory
  /** In-app route opened on tap ('' = just opens the app). */
  route: string
  saveToInbox: boolean
  /** Billing/plan messages go to owners only, never team members. */
  ownersOnly?: boolean
  titleEn: string
  bodyEn: string
  titleSw: string
  bodySw: string
}

/** Tap destinations offered in the composer. Must be real AppRoutes paths. */
export const PUSH_ROUTES: { value: string; label: string }[] = [
  { value: '',              label: 'Just open the app' },
  { value: '/',             label: 'Dashboard' },
  { value: '/sales',        label: 'Sales' },
  { value: '/inventory',    label: 'Inventory' },
  { value: '/debt',         label: 'Debts' },
  { value: '/expenses',     label: 'Expenses' },
  { value: '/reports',      label: 'Reports' },
  { value: '/subscription', label: 'Subscription / Plans' },
  { value: '/notifications', label: 'Notifications' },
  { value: '/settings',     label: 'Settings' },
]

export const PUSH_PRESETS: PushPreset[] = [
  {
    id: 'app_update',
    icon: '⬆️',
    title: 'App Update',
    subtitle: 'New version available — ask users to update',
    category: 'update',
    route: '',
    saveToInbox: true,
    titleEn: 'A new Mali Up update is here',
    bodyEn: 'Update Mali Up from the Play Store to get the latest improvements and fixes.',
    titleSw: 'Toleo jipya la Mali Up limefika',
    bodySw: 'Sasisha Mali Up kupitia Play Store upate maboresho na marekebisho mapya.',
  },
  {
    id: 'feature_update',
    icon: '🚀',
    title: 'New Feature',
    subtitle: 'Announce a new tool in the app',
    category: 'update',
    route: '/',
    saveToInbox: true,
    titleEn: 'New in Mali Up 🚀',
    bodyEn: 'We added new tools to help you track profit and manage your business faster. Open the app to try them.',
    titleSw: 'Mpya kwenye Mali Up 🚀',
    bodySw: 'Tumeongeza vipengele vipya vya kufuatilia faida na kusimamia biashara yako haraka. Fungua app ujaribu.',
  },
  {
    id: 'daily_reminder',
    icon: '⏰',
    title: 'Record Sales Reminder',
    subtitle: 'Nudge users to log today’s sales',
    category: 'reminder',
    route: '/sales',
    saveToInbox: false,
    titleEn: 'Have you recorded today’s sales?',
    bodyEn: 'Take a minute to record today’s sales and expenses so your reports stay accurate.',
    titleSw: 'Umerekodi mauzo ya leo?',
    bodySw: 'Chukua dakika moja kurekodi mauzo na matumizi ya leo ili ripoti zako ziwe sahihi.',
  },
  {
    id: 'debt_reminder',
    icon: '💰',
    title: 'Collect Debts',
    subtitle: 'Remind owners to follow up on customer debts',
    category: 'reminder',
    route: '/debt',
    saveToInbox: false,
    titleEn: 'Follow up on your customer debts',
    bodyEn: 'Check who still owes you and send them a reminder from Mali Up.',
    titleSw: 'Fuatilia madeni ya wateja wako',
    bodySw: 'Angalia nani bado anadaiwa na umtumie ukumbusho kupitia Mali Up.',
  },
  {
    id: 'upgrade_offer',
    icon: '🎁',
    title: 'Upgrade Offer',
    subtitle: 'Plan upgrade or discount (owners only)',
    category: 'promotion',
    route: '/subscription',
    saveToInbox: true,
    ownersOnly: true,
    titleEn: 'Special offer: upgrade your plan',
    bodyEn: 'Unlock unlimited invoices, full reports and customer SMS reminders. Upgrade today in the app.',
    titleSw: 'Ofa maalum: boresha kifurushi chako',
    bodySw: 'Pata ankara bila kikomo, ripoti kamili na SMS za kukumbusha wateja. Boresha leo kwenye app.',
  },
  {
    id: 'maintenance',
    icon: '🛠️',
    title: 'Maintenance',
    subtitle: 'Planned downtime or service notice',
    category: 'general',
    route: '',
    saveToInbox: true,
    titleEn: 'Scheduled maintenance',
    bodyEn: 'Syncing may be slow for a short while today. Keep working — your data is saved on your phone and will sync after.',
    titleSw: 'Matengenezo yaliyopangwa',
    bodySw: 'Usawazishaji unaweza kuchelewa kwa muda mfupi leo. Endelea kufanya kazi — data yako imehifadhiwa kwenye simu na itasawazishwa baadaye.',
  },
  {
    id: 'christmas',
    icon: '🎄',
    title: 'Christmas',
    subtitle: 'Holiday greetings',
    category: 'general',
    route: '',
    saveToInbox: false,
    titleEn: 'Merry Christmas from Mali Up 🎄',
    bodyEn: 'Wishing you and your business joy and prosperity this season.',
    titleSw: 'Heri ya Krismasi kutoka Mali Up 🎄',
    bodySw: 'Tunakutakia wewe na biashara yako furaha na mafanikio tele msimu huu.',
  },
  {
    id: 'new_year',
    icon: '🎆',
    title: 'New Year',
    subtitle: 'New Year wishes',
    category: 'general',
    route: '',
    saveToInbox: false,
    titleEn: 'Happy New Year! 🎆',
    bodyEn: 'Start the year strong — track every sale and grow your profits with Mali Up.',
    titleSw: 'Heri ya Mwaka Mpya! 🎆',
    bodySw: 'Anza mwaka kwa nguvu — rekodi kila mauzo na ukuze faida yako na Mali Up.',
  },
  {
    id: 'eid',
    icon: '🌙',
    title: 'Eid Mubarak',
    subtitle: 'Festive greetings',
    category: 'general',
    route: '',
    saveToInbox: false,
    titleEn: 'Eid Mubarak 🌙',
    bodyEn: 'May this blessed season bring peace, joy and growth to you and your business.',
    titleSw: 'Eid Mubarak 🌙',
    bodySw: 'Sikukuu hii ikuletee amani, furaha na mafanikio wewe na biashara yako.',
  },
  {
    id: 'custom',
    icon: '✍️',
    title: 'Custom',
    subtitle: 'Write your own message',
    category: 'general',
    route: '',
    saveToInbox: true,
    titleEn: '',
    bodyEn: '',
    titleSw: '',
    bodySw: '',
  },
]
