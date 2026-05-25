# Mali Up Swahili-First UX Implementation

**Status:** 🎯 **PLANNED - Ready to Implement**  
**Scope:** Full stack (Flutter mobile + Next.js web + NestJS backend)  
**Timeline:** 6 weeks, 220 hours  
**Language:** Kiswahili primary (+ English fallback)  
**Phases:** All (Phase 1-4 features will have Kiswahili-first UX)

---

## Executive Summary

Mali Up will implement **Kiswahili-first UX** — not translation, but cultural redesign. Every user flow, label, error message, notification, and empty state will be written in **natural business Kiswahili by native speakers** who understand Tanzania's business context.

### Why This Matters

**Translation** = English software → Translated to Kiswahili (feels adapted)  
**Kiswahili-First UX** = Built in Kiswahili from the ground up (feels native)

Tanzanian users will feel: **"This was made FOR me, not adapted for me"**

---

## What Will Be Localized

### Phase 1: Foundation (Weeks 1-2)

✅ **i18n Infrastructure**
- Flutter: `intl` package + Riverpod provider
- Next.js: `next-i18next` with SSR support
- Backend: NestJS middleware + locale detection

✅ **Terminology Dictionary**
- 100+ business terms (invoice, customer, expense, etc.)
- Common UI labels (save, cancel, delete, etc.)
- Error messages (not literal translation)
- Formatting rules (dates, currency, decimals)

✅ **Translation Files**
- JSON structure for all 9 domains
- Kiswahili complete translations
- English fallback translations
- Build pipeline for extraction

### Phase 2: Mobile App (Weeks 2-3)

✅ **6 Compliance Screens**
- ConsentScreen (PDPA consent)
- DataExportScreen (data portability)
- DeleteAccountScreen (right to deletion)
- BiometricSetupScreen (device security)
- PINLockSetupScreen (device security)
- AuditLogScreen (activity transparency)

✅ **Core Flows**
- Authentication (login, signup, password reset)
- Onboarding (welcome, tutorial, setup)
- Business operations (invoices, customers, inventory)
- Navigation & settings

✅ **All Notifications**
- Push notifications
- In-app toasts (success/error/warning)
- Dialog confirmations
- Empty state messages

### Phase 3: Web Dashboard (Weeks 3-4)

✅ **All Next.js Pages**
- Dashboard & overview
- Business screens (invoices, customers, inventory)
- Reports & analytics
- Settings & profile
- Admin audit dashboard

✅ **All UI Elements**
- Form labels & placeholders
- Data table headers
- Chart/graph labels
- Menu items & navigation
- Help text & tooltips
- Error messages

### Phase 4: Backend & Email (Week 4)

✅ **API Localization**
- Error responses in Kiswahili
- Validation messages in Kiswahili
- Permission denied messages
- API documentation (Swagger)

✅ **Email Templates**
- Welcome email
- Data export complete
- Account deletion confirmation
- Password reset
- Weekly/monthly reports

---

## Implementation Architecture

### Flutter i18n

```
lib/
├── features/
│   └── settings/
│       └── locale/
│           ├── locale_provider.dart       # Riverpod provider
│           └── locale_service.dart        # Load translations
│
├── l10n/
│   ├── sw/                                # Kiswahili translations
│   │   ├── common.json
│   │   ├── auth.json
│   │   ├── business.json
│   │   └── ...
│   └── en/                                # English fallback
│       ├── common.json
│       └── ...
│
└── widgets/
    └── translation_provider.dart          # Global i18n widget
```

**Usage:**
```dart
final t = ref.watch(translationsProvider);
Text(t['common']['save'])  // Returns "Hifadhi" in Kiswahili
```

### Next.js i18n

```
public/locales/
├── sw/
│   ├── common.json
│   ├── auth.json
│   ├── business.json
│   └── ...
└── en/
    ├── common.json
    └── ...

pages/
├── [locale]/
│   ├── index.tsx          # Route /sw or /en
│   ├── login.tsx
│   └── ...
└── _app.tsx
```

**Usage:**
```jsx
import { useTranslation } from 'next-i18next';

export default function Page() {
  const { t } = useTranslation('common');
  return <button>{t('buttons.save')}</button>  // "Hifadhi"
}
```

### NestJS i18n

```
src/
├── i18n/
│   ├── i18n.module.ts
│   ├── i18n.middleware.ts    # Detect locale from headers
│   ├── i18n.service.ts       # Load & provide translations
│   └── translations/
│       ├── sw/
│       │   ├── common.json
│       │   ├── errors.json
│       │   └── ...
│       └── en/
│           └── ...
└── controllers/
    └── auth.controller.ts    # Use i18n in responses
```

**Usage:**
```typescript
constructor(private i18n: I18nService) {}

getTranslation(locale: string, key: string) {
  return this.i18n.t(locale, key);  // Returns translation
}
```

---

## Terminology Examples

### Business Terms

| English | Kiswahili | Example in Sentence |
|---------|-----------|-------------------|
| Invoice | Ankara | "Hadithi ya Ankara" = Invoice History |
| Customer | Mteja | "Orodha ya Wateja" = Customer List |
| Expense | Matumizi | "Muhtasari wa Matumizi" = Expense Report |
| Inventory | Hesabu ya Bidhaaa | "Idara ya Hesabu ya Bidhaaa" = Inventory Section |
| Sale | Mauzo | "Jmlah Mauzo" = Total Sales |
| Report | Ripoti | "Ripoti ya Kila Mwezi" = Monthly Report |

### Error Messages (NOT literal translation)

**Scenario: Email validation**

❌ **Translation Approach:**
- English: "Invalid email format"
- Literal translation: "Muundo wa barua pepe si sahihi"
- Problem: Technical jargon, not user-friendly

✅ **Kiswahili-First UX:**
- "Tafadhali ingiza barua pepe sahihi (mfano: jina@example.com)"
- Translation: "Please enter a valid email (example: name@example.com)"
- Better: Natural guidance, shows example

**Scenario: Network error**

❌ **Translation:**
- "Network error occurred" → "Kosa la mtandao lilitokea"

✅ **Kiswahili-First:**
- "Hakuna muunganisho. Tafadhali angalia WiFi au data yako"
- Translation: "No connection. Please check your WiFi or data"
- Better: Actionable, context-aware guidance

---

## Translation File Structure

### common.json (UI labels)

```json
{
  "navigation": {
    "home": "Nyumbani",
    "invoices": "Ankara",
    "customers": "Wateja",
    "reports": "Ripoti",
    "settings": "Mipango"
  },
  "buttons": {
    "save": "Hifadhi",
    "cancel": "Ghairi",
    "delete": "Futa",
    "confirm": "Thibitisha",
    "next": "Inayofuata",
    "back": "Rudi Nyuma"
  },
  "labels": {
    "email": "Barua Pepe",
    "password": "Neno Siri",
    "phone": "Namba ya Simu",
    "name": "Jina",
    "business": "Biashara"
  },
  "placeholders": {
    "enterEmail": "Ingiza barua pepe yako",
    "enterPassword": "Ingiza neno siri yako",
    "search": "Tafuta..."
  }
}
```

### errors.json (Error messages)

```json
{
  "validation": {
    "emailRequired": "Tafadhali ingiza barua pepe",
    "emailInvalid": "Tafadhali ingiza barua pepe sahihi",
    "passwordRequired": "Tafadhali ingiza neno siri",
    "passwordTooShort": "Neno siri lazima liwe na herufi 8 au zaidi",
    "passwordMismatch": "Neno siri haumaanishi. Tafadhali jaribu tena"
  },
  "network": {
    "noConnection": "Hakuna muunganisho. Tafadhali angalia WiFi au data yako",
    "timeout": "Serikali inachukua muda mrefu. Tafadhali jaribu tena",
    "serverError": "Kosa la serikali. Tafadhali jaribu baadaye"
  },
  "auth": {
    "invalidCredentials": "Barua pepe au neno siri si sahihi",
    "userNotFound": "Akaunti haipo. Tafadhali jandali sasa",
    "accountLocked": "Akaunti imefungwa kwa sababu ya jaribio nyingi"
  }
}
```

### formatting.json (Localized formatting)

```json
{
  "date": {
    "format": "dd/MM/yyyy",
    "example": "24/05/2026"
  },
  "time": {
    "format": "HH:mm",
    "example": "14:30"
  },
  "currency": {
    "symbol": "TSh",
    "format": "TSh #,###.##",
    "example": "TSh 150,000.00"
  },
  "number": {
    "decimal": ",",
    "thousand": " ",
    "format": "#,### ,##",
    "example": "1 000 ,50"
  }
}
```

---

## Implementation Steps

### Week 1-2: Foundation

```
Day 1-3: Infrastructure Setup
  ✅ Create Flutter i18n with intl + Riverpod
  ✅ Create Next.js i18n with next-i18next
  ✅ Create NestJS i18n middleware

Day 4-7: Terminology & Translations
  ✅ Meet with native speaker
  ✅ Create comprehensive terminology dictionary
  ✅ Create all JSON translation files
  ✅ Set up translation file validation

Day 8-14: Polish & Approval
  ✅ Native speaker review of terminology
  ✅ Refine unclear translations
  ✅ Create developer style guide
  ✅ Document translation process
```

### Week 2-3: Mobile App

```
Day 1-3: Integration
  ✅ Wire up i18n in Flutter
  ✅ Implement language switcher
  ✅ Add locale persistence

Day 4-7: Translation
  ✅ Translate Phase 1 screens (6 screens)
  ✅ Translate auth flow
  ✅ Translate business flows
  ✅ Translate notifications

Day 8-10: Testing
  ✅ QA on various screen sizes
  ✅ Verify no text truncation
  ✅ Test locale switching
  ✅ Native speaker review
```

### Week 3-4: Web Dashboard

```
Day 1-2: Integration
  ✅ Configure next-i18next
  ✅ Set up locale routing
  ✅ Implement language switcher

Day 3-7: Translation
  ✅ Translate all pages & screens
  ✅ Translate forms & data tables
  ✅ Translate charts & graphs

Day 8-10: Testing
  ✅ QA responsive design
  ✅ Test locale routing
  ✅ Verify date/time/currency formatting
  ✅ Native speaker spot check
```

### Week 4: Backend & Email

```
Day 1-3: API Localization
  ✅ Create i18n middleware
  ✅ Localize error responses
  ✅ Localize validation messages

Day 4-5: Email Templates
  ✅ Create Kiswahili email templates
  ✅ Set up email locale detection

Day 6-7: Documentation
  ✅ Update Swagger docs (Kiswahili)
  ✅ Create API documentation
```

### Week 5-6: Testing & Refinement

```
Day 1-3: Comprehensive QA
  ✅ Mobile QA (all screens, devices)
  ✅ Web QA (desktop, tablet, mobile)
  ✅ API QA (error messages, validation)

Day 4-5: Native Speaker Review
  ✅ Full app review
  ✅ Terminology consistency check
  ✅ Tone & formality review
  ✅ Cultural appropriateness check

Day 6-7: Final Polish
  ✅ Fix any QA issues
  ✅ Apply reviewer feedback
  ✅ Performance testing
  ✅ Prepare for production
```

---

## Quality Checklist

### ✅ Translation Quality

- [ ] All UI text in Kiswahili (not English)
- [ ] Business terminology consistent throughout
- [ ] Natural, contextual phrasing (not literal translation)
- [ ] Error messages are user-friendly (not technical)
- [ ] Tone is consistent (semi-formal, businesslike)
- [ ] Politeness maintained (using "tafadhali" appropriately)
- [ ] No cultural insensitivity or offensive terms

### ✅ Technical Quality

- [ ] No text truncation on mobile
- [ ] Proper date/time/currency formatting
- [ ] Language switching works seamlessly
- [ ] Fallback to English works
- [ ] Performance not degraded
- [ ] Bundle size acceptable
- [ ] All platforms (mobile, web, API) consistent

### ✅ Compliance

- [ ] Native speaker approval
- [ ] Terminology dictionary complete
- [ ] Translation guidelines documented
- [ ] All platforms translated
- [ ] Documentation updated
- [ ] QA testing completed

---

## Success Metrics

| Metric | Target | Status |
|--------|--------|--------|
| % of UI in Kiswahili | 100% | ⏳ Pending |
| Native speaker approval | Yes | ⏳ Pending |
| Text truncation issues | 0 | ⏳ Pending |
| Tone consistency | 100% | ⏳ Pending |
| Performance regression | <5% | ⏳ Pending |
| Language switching latency | <500ms | ⏳ Pending |
| QA pass rate | 100% | ⏳ Pending |

---

## Ongoing: Phase 2-4 Features

When Phase 2-4 features are built, apply Kiswahili-first UX immediately:

**Phase 2 (BRELA, M-Pesa):**
- Business verification screens in Kiswahili
- Transaction import flows in Kiswahili
- Compliance messages in Kiswahili

**Phase 3 (VAT, Tax, Financial):**
- VAT report screens in Kiswahili
- Tax return helpers in Kiswahili
- Financial statements in Kiswahili

**Phase 4 (Audit, Certification):**
- Audit dashboard in Kiswahili
- Compliance docs in Kiswahili
- Regulatory guides in Kiswahili

---

## Key Principles

1. **No Machine Translation:** All translations done by native Kiswahili speakers
2. **Business Context:** Terminology reflects how Tanzanian business owners speak
3. **User-Friendly Errors:** Error messages guide users, don't confuse them
4. **Consistent Tone:** Same formality and friendliness across all platforms
5. **Cultural Appropriateness:** Reviewed for sensitivity and relevance
6. **Performance First:** i18n overhead minimized, app speed maintained
7. **Easy Maintenance:** Translation files simple to update and manage
8. **Future-Ready:** System designed to support additional languages later

---

## Team Roles

**Native Kiswahili Speaker(s):**
- Validate terminology
- Review translations
- Ensure cultural appropriateness
- Approve tone & consistency

**Developers:**
- Implement i18n infrastructure
- Integrate translations into code
- Handle technical edge cases
- Optimize performance

**QA/Testing:**
- Test text truncation
- Verify locale switching
- Check formatting
- Test all platforms

**Product Manager:**
- Prioritize screens
- Coordinate timeline
- Ensure consistency across teams

---

## Timeline Summary

| Phase | Duration | Effort | Deliverables |
|-------|----------|--------|--------------|
| **1. Foundation** | 2 wks | 40 hrs | i18n setup, terminology dict, translation files |
| **2. Mobile** | 1 wk | 60 hrs | All screens, flows, notifications in Kiswahili |
| **3. Web** | 1 wk | 40 hrs | All pages & UI in Kiswahili |
| **4. Backend** | 1 wk | 30 hrs | API errors, emails in Kiswahili |
| **5. Testing** | 1 wk | 50 hrs | QA, cultural review, refinement |
| **6. Ongoing** | Ongoing | - | Apply to future features |
| **Total** | **6 wks** | **220 hrs** | **Full Kiswahili-first UX** |

---

## Next Steps

1. ✅ **Plan created** (this document)
2. ⏳ **Get native speaker confirmation** - Discuss terminology approach
3. ⏳ **Create terminology dictionary** - Work session with native speaker
4. ⏳ **Set up i18n infrastructure** - Flutter, Next.js, NestJS
5. ⏳ **Build translation files** - All 9 domains
6. ⏳ **Integrate into Flutter** - Start with Phase 1 screens
7. ⏳ **Translate all screens** - Mobile, web, backend
8. ⏳ **QA & testing** - All platforms
9. ⏳ **Native speaker final review** - Approve for production
10. ⏳ **Deploy** - Go live with Kiswahili-first UX
11. ⏳ **Apply to Phase 2-4** - All future features

---

## Resources

**Packages Needed:**
- Flutter: `intl: ^0.18.0`, `riverpod: ^2.4.0`
- Next.js: `next-i18next: ^13.0.0`
- NestJS: `@nestjs/i18n: ^10.0.0`

**Documentation:**
- [Flutter Intl](https://pub.dev/packages/intl)
- [next-i18next](https://github.com/i18next/next-i18next)
- [NestJS i18n](https://docs.nestjs.com/techniques/i18n-module)

---

**Status:** 🎯 **READY TO IMPLEMENT**

**Prepared by:** Copilot  
**Date:** May 24, 2026  
**Native Speaker:** Available for validation

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
