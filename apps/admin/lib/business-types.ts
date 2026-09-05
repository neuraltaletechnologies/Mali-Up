// Business-type picker options for the admin "new user" form. Mirrors the
// mobile app's onboarding business-type list exactly (key + English label) —
// see _kBizTypes in
// apps/mobile-app/lib/features/onboarding/presentation/screens/business_details_screen.dart.
// `key` is what's stored as `businessCategory` on the business doc, same as
// the app stores `state.businessType`.

export interface BusinessType {
  key: string
  label: string
}

export const BUSINESS_TYPES: BusinessType[] = [
  { key: 'retail', label: 'Retail Shop' },
  { key: 'restaurant', label: 'Restaurant / Café' },
  { key: 'food_beverages', label: 'Food & Beverages' },
  { key: 'wholesale', label: 'Wholesale' },
  { key: 'salon', label: 'Salon & Beauty' },
  { key: 'pharmacy', label: 'Pharmacy' },
  { key: 'electronics', label: 'Electronics' },
  { key: 'hardware', label: 'Hardware & Building' },
  { key: 'tailoring', label: 'Tailoring & Fashion' },
  { key: 'agriculture', label: 'Agriculture & Farming' },
  { key: 'transport', label: 'Transport & Logistics' },
  { key: 'health', label: 'Health & Wellness' },
  { key: 'education', label: 'Education & Training' },
  { key: 'construction', label: 'Construction' },
  { key: 'real_estate', label: 'Real Estate' },
  { key: 'printing', label: 'Printing & Branding' },
  { key: 'cleaning', label: 'Cleaning Services' },
  { key: 'tech_services', label: 'IT & Tech Services' },
  { key: 'events', label: 'Events & Entertainment' },
  { key: 'freelance', label: 'Freelancing' },
  { key: 'consultancy', label: 'Consultancy' },
  { key: 'banking_finance', label: 'Banking & Finance' },
  { key: 'mobile_money', label: 'Mobile Money Agent' },
  { key: 'insurance', label: 'Insurance' },
  { key: 'photography', label: 'Photography & Video' },
  { key: 'media', label: 'Media & Marketing' },
  { key: 'legal', label: 'Legal Services' },
  { key: 'security_guard', label: 'Security Services' },
  { key: 'travel', label: 'Travel & Tourism' },
  { key: 'other', label: 'Other' },
]
