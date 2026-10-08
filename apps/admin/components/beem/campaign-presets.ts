import type { SmsCampaignType } from '@/types'

export interface CampaignPreset {
  id: SmsCampaignType
  icon: string
  title: string
  subtitle: string
  defaultName: string
  templateEn: string
  templateSw: string
}

export const CAMPAIGN_PRESETS: CampaignPreset[] = [
  {
    id: 'christmas',
    icon: '🎄',
    title: 'Christmas (Krismasi)',
    subtitle: 'Holiday greetings & special year-end discounts',
    defaultName: 'Xmas Holiday Greetings & Promo',
    templateEn:
      'Merry Christmas {name}! Wishing you and your business joy and prosperity. Take advantage of our holiday offers on Mali Up: https://maliup.neuraltale.com',
    templateSw:
      'Heri ya Krismasi {name}! Mali Up inakutakia wewe na biashara yako furaha na mafanikio tele. Furahia ofa za sikukuu leo kupitia App: https://maliup.neuraltale.com',
  },
  {
    id: 'new_year',
    icon: '🎆',
    title: 'New Year (Mwaka Mpya)',
    subtitle: 'New Year wishes & business growth momentum',
    defaultName: 'Happy New Year Celebration',
    templateEn:
      'Happy New Year {name}! Elevate your business this year with Mali Up. Manage sales, track inventory, and grow profits effortlessly. Cheers to great success!',
    templateSw:
      'Heri ya Mwaka Mpya {name}! Anza mwaka kwa kukuza biashara yako na Mali Up. Simamia mauzo, stoo na fedha zako kiurahisi. Tunakutakia mafanikio tele mwaka huu!',
  },
  {
    id: 'eid',
    icon: '🌙',
    title: 'Eid Mubarak (Sikukuu)',
    subtitle: 'Festive greetings for religious holidays',
    defaultName: 'Eid Mubarak Wishes',
    templateEn:
      'Eid Mubarak to {name} and your family from Mali Up! May this blessed season bring abundant blessings, growth, and joy to your business.',
    templateSw:
      'Eid Mubarak {name}! Mali Up inakutakia wewe na familia yako sikukuu yenye amani, furaha na mafanikio tele katika biashara yako.',
  },
  {
    id: 'promotion',
    icon: '🎁',
    title: 'Special Promotion / Upgrade',
    subtitle: 'Plan upgrades, seasonal discounts & special offers',
    defaultName: 'Special Plan Upgrade Offer',
    templateEn:
      'Special Offer for {name}! Upgrade to Mali Up Growth Plan today and unlock unlimited invoices, detailed reports & customer SMS reminders. Upgrade now in the app!',
    templateSw:
      'Habari {name}! Boresha biashara yako leo kwa kujiunga na kifurushi cha Mali Up Growth upate ankara bila kikomo, ripoti kamili na SMS za wateja. Fungua App uanze!',
  },
  {
    id: 'retention',
    icon: '💬',
    title: 'Retention / We Miss You',
    subtitle: 'Re-engage inactive business owners & offer support',
    defaultName: 'Customer Care & Support Check-in',
    templateEn:
      'Hello {name}, need assistance organizing your business transactions on Mali Up? Our support team is here to help! Call or WhatsApp us: +255 653 520 829',
    templateSw:
      'Habari {name}, unahitaji msaada wowote kuweka hesabu na stoo yako sawa kwenye Mali Up? Tupo hapa kukusaidia! Tupigie au WhatsApp: +255 653 520 829',
  },
  {
    id: 'feature_update',
    icon: '🚀',
    title: 'New Feature / App Update',
    subtitle: 'Announce new app capabilities and tools',
    defaultName: 'New App Features Announcement',
    templateEn:
      'Exciting news {name}! Mali Up has introduced powerful new features to help you track profits and manage staff faster. Update your app today!',
    templateSw:
      'Habari {name}! Mali Up imeongeza vipengele vipya vya kurahisisha hesabu za faida na usimamizi wa biashara yako. Fungua app sasa uone mabadiliko!',
  },
  {
    id: 'custom',
    icon: '✍️',
    title: 'Custom Message',
    subtitle: 'Draft a completely tailored SMS broadcast',
    defaultName: 'Custom SMS Broadcast',
    templateEn: 'Habari {name}, ujumbe kutoka Mali Up...',
    templateSw: 'Habari {name}, ujumbe kutoka Mali Up...',
  },
]
