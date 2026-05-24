# Mali Up - Tanzania Regulatory Compliance

## Executive Summary

Mali Up is a **business management and record-keeping platform**, not a payment processor or financial institution. This critical distinction significantly reduces our regulatory burden.

**Key Point:** We facilitate and record transactions; we do **not** hold, move, or clear money.

This document outlines Mali Up's compliance approach across all relevant Tanzanian regulatory authorities.

---

## 1. Regulatory Landscape & Authority Mappings

### 1.1 BRELA (Business Registration Authority)

| Item | Details |
|------|---------|
| **Relevance** | Business registration data validation |
| **Mali Up Role** | Verify business registration on signup |
| **Required Actions** | API integration for business verification (Phase 2) |
| **Frequency** | On signup + annual re-verification |
| **Escalation** | Alert users if registration lapses |

**Implementation Plan:**
- Build BRELA API integration service (NestJS)
- Validate business registration number during signup
- Cache verification results with 24-48 hour TTL
- Implement retry logic for failed validations
- Log all BRELA API interactions for audit

**Timeline:** Phase 2

---

### 1.2 Tanzania Revenue Authority (TRA)

| Item | Details |
|------|---------|
| **Relevance** | VAT tracking, tax reporting format compliance |
| **Mali Up Role** | Provide TRA-compliant reporting formats |
| **Required Actions** | VAT reports, EFD integration, PDPA adherence |
| **Reporting Period** | Monthly/Quarterly VAT submissions |
| **Escalation** | Support for compliance during TRA audits |

**Implementation Plan:**

**VAT Reporting (Phase 3):**
- Create TRA-compliant VAT report template
- Implement input VAT vs output VAT calculation
- Period-based VAT aggregation (monthly/quarterly)
- Export formats: CSV and PDF for TRA submission
- Ensure all calculations follow current TRA rates

**Electronic Fiscal Device (EFD) Integration (Phase 3):**
- Research current TRA EFD requirements and APIs
- Design EFD receipt submission workflow
- Implement EFD receipt format generation
- Pilot with 2-3 businesses before production
- Create audit trail for all EFD submissions

**Compliance Monitoring:**
- Track TRA regulatory updates quarterly
- Test reports against latest TRA format specifications
- Document required data fields in README

**Timeline:** Phase 3 (VAT/EFD features)

---

### 1.3 Bank of Tanzania (BoT)

| Item | Details |
|------|---------|
| **Relevance** | Payment institution licensing (conditional) |
| **Mali Up Role** | Currently NOT applicable |
| **Condition** | Only relevant if we hold customer funds or offer payment escrow |
| **Escalation** | Monitor if escrow features are planned |

**Status:** Not currently applicable. We do not hold customer funds.

**Monitoring:**
- If future roadmap includes payment escrow or fund holding, BoT licensing becomes **mandatory**
- Create alert mechanism for product team when escrow is considered
- Document licensing requirements as design constraint

---

### 1.4 TCRA (Tanzania Communications Regulatory Authority)

| Item | Details |
|------|---------|
| **Relevance** | Data protection, mobile app regulations, PDPA |
| **Mali Up Role** | Full PDPA compliance |
| **Required Actions** | Data residency, user consent, privacy policy, right to deletion |

**Implementation Plan:**

**PDPA Compliance (Phase 1):**
- ✅ Data residency: Firestore region set to Africa (or nearest GCP region)
- ✅ User consent framework: Granular privacy consent in onboarding
- ✅ Privacy policy: PDPA-compliant, published in-app and web
- ✅ Right to deletion: User-initiated data deletion via API/UI
- ✅ Right to export: Users can download all their data (JSON/CSV)
- ✅ Audit logging: All data access, exports, and deletions logged

**Data Protection Measures:**
- TLS 1.3 encryption in transit (Firebase default)
- No financial amounts logged to Analytics or crash reporting
- No individual financial data shared with third parties
- User controls for biometric and PIN app lock

**Timeline:** Phase 1 (foundational)

---

### 1.5 Safaricom / Vodacom (M-Pesa)

| Item | Details |
|------|---------|
| **Relevance** | Daraja API for M-Pesa business transaction import |
| **Mali Up Role** | Import and record M-Pesa transactions |
| **Required Actions** | Daraja API partnership registration, compliance with API terms |

**Implementation Plan (Phase 2):**
- Register Mali Up as Daraja API partner with Safaricom/Vodacom
- Implement M-Pesa transaction import service via Daraja API
- Secure token storage for API credentials (never log tokens)
- Transaction data retention: Follow Daraja API terms (typically 12-24 months)
- Create user UI to import and match M-Pesa transactions to invoices
- Implement error handling and retry logic for failed imports
- Audit log all M-Pesa API transactions

**API Compliance:**
- Honor rate limits and API quotas
- Encrypt all API communication (TLS 1.3)
- Store API credentials securely (environment variables, not in code)
- Log API errors without exposing sensitive data

**Timeline:** Phase 2

---

### 1.6 NBAA (National Board of Accountants and Auditors)

| Item | Details |
|------|---------|
| **Relevance** | Accounting standards for financial reports |
| **Mali Up Role** | Ensure P&L, Balance Sheet, Cash Flow comply with NBAA SME standards |
| **Required Actions** | Research standards, implement compliant reporting formats |

**Implementation Plan (Phase 3):**
- Research NBAA SME accounting standards and chart of accounts
- P&L Report: Align with NBAA format (Revenue - COGS - Operating Expenses = Net Income)
- Balance Sheet: Assets = Liabilities + Equity (NBAA structure)
- Cash Flow: Separate operating, investing, financing activities
- Reference NBAA standards in Finance Service documentation

**Timeline:** Phase 3 (financial reporting)

---

## 2. Data Protection & Privacy Commitments

### 2.1 Encryption & Data Residency

**In Transit:**
- All data encrypted via **TLS 1.3** (Firebase default)
- Verify configuration on setup and document in README

**At Rest:**
- Firestore data encrypted by Google Cloud
- Database backups encrypted by provider

**Data Residency:**
- Firestore region: **Africa** (or nearest GCP Africa region)
- No data stored outside Africa without explicit user consent
- Document region in deployment configuration

### 2.2 PDPA Compliance Framework

**User Rights:**
- **Data Ownership:** Users own all their business data
- **Right to Export:** Download all data as JSON/CSV (API + UI)
- **Right to Deletion:** Delete all data on request (PDPA Article 19)
- **Right to Access:** View all data Mali Up holds about them
- **Right to Correction:** Update incorrect data

**Consent Management:**
- Privacy policy acceptance required on signup
- Granular consent options (analytics, notifications, etc.)
- Users can withdraw consent at any time
- Consent state stored and auditable

**Financial Data Protection:**
- Never log individual financial amounts to Firebase Analytics
- Never include transaction details in crash reports
- Never share business financial data with third parties
- Anonymize aggregate data if used for internal analytics

### 2.3 App Security

**Biometric Lock:**
- Fingerprint and face recognition unlock
- Integrated with platform-specific security APIs
- Option to disable biometric (PIN fallback)

**PIN-Based Lock:**
- Optional 4-6 digit PIN code
- Stored securely in device keychain/keystore
- Failed attempts trigger delays/lockout

**Device-Level Encryption:**
- Users can enable encryption for local device storage
- Document encryption capabilities in privacy policy

---

## 3. VAT & Tax Compliance Roadmap

### 3.1 VAT Compliance (Phase 3)

Tanzania mandates **Electronic Fiscal Devices (EFD)** for VAT-registered businesses.

**VAT Return Preparation:**
- Input VAT (VAT paid on purchases) tracking
- Output VAT (VAT charged on sales) calculation
- VAT summary by period (monthly/quarterly)
- Automated VAT return generation
- Export formats: CSV for TRA e-filing, PDF for records

**TRA Format Compliance:**
- Research current TRA VAT return specifications
- Map Mali Up data to TRA required fields
- Validate calculations against TRA requirements
- Test with pilot businesses

**Timeline:** Phase 3

### 3.2 Electronic Fiscal Device (EFD) Integration (Phase 3)

**Research Phase:**
- Document current TRA EFD requirements
- Identify TRA APIs or submission protocols
- Understand EFD receipt format specifications
- Research exemptions and special cases

**Implementation:**
- EFD receipt format generation matching TRA spec
- Receipt signing/validation mechanism
- Submission workflow (manual or automated)
- Error handling and retry logic
- Audit trail for all submissions

**Pilot Testing:**
- Partner with 2-3 pilot businesses
- Test receipt generation and submission
- Gather feedback on workflow
- Fix issues before production
- Document lessons learned

**Timeline:** Phase 3

### 3.3 Financial Reporting (Phase 3)

**Income Statement (P&L):**
- Revenue (total sales)
- Cost of Goods Sold (COGS)
- Operating Expenses
- Net Income
- Align with NBAA SME standards
- Export as PDF and CSV

**Balance Sheet:**
- Assets (current and fixed)
- Liabilities (current and long-term)
- Equity (retained earnings, capital)
- Align with NBAA structure

**Cash Flow Statement:**
- Operating activities
- Investing activities
- Financing activities
- Helps business understand liquidity

**Export Formats:**
- PDF (formatted, printable)
- CSV (for further analysis)
- TRA-accepted formats

**Timeline:** Phase 3

---

## 4. Implementation Phases

### Phase 1: Data Security & Privacy (Foundation)
**Duration:** Weeks 1-4

- Verify TLS 1.3 encryption and data residency
- Create PDPA-compliant privacy policy
- Implement user consent framework
- Build data export and deletion features
- Add biometric and PIN app lock
- Implement audit logging for sensitive operations

**Deliverables:**
- Privacy Policy published
- Data export/deletion working
- App lock features available
- Audit logs capturing key events

---

### Phase 2: Regulatory Authority Integrations
**Duration:** Weeks 5-8

- BRELA: Business registration verification API
- M-Pesa Daraja: Transaction import integration
- TCRA: Compliance monitoring and documentation
- BoT: Monitoring mechanism for future licensing needs

**Deliverables:**
- BRELA integration tested with 5+ businesses
- M-Pesa Daraja API partner registration complete
- Transaction import working
- Regulatory compliance checklist updated

---

### Phase 3: VAT & Tax Compliance
**Duration:** Weeks 9-12

- VAT report generation (TRA-compliant format)
- EFD integration research and pilot
- Financial reporting (P&L, Balance Sheet, Cash Flow)
- NBAA-compliant accounting standards
- Report export (PDF and CSV)

**Deliverables:**
- VAT reports match TRA requirements
- EFD piloted with 2-3 businesses
- Financial reports NBAA-aligned
- Export functionality working

---

### Phase 4: Documentation & Audit (Ongoing)
**Parallel with all phases**

- Regulatory Compliance Summary (this document)
- Privacy Policy and Terms of Service
- Data Processing Agreement
- API integration guides
- PR compliance checklist
- Audit dashboard design (future)

**Deliverables:**
- All compliance docs published in repo
- Regulatory compliance guide accessible to team
- PR template includes compliance checklist

---

## 5. Risk Mitigation & Monitoring

### 5.1 Regulatory Change Management

**Quarterly Review:**
- Monitor TRA announcements for VAT/EFD changes
- Track TCRA PDPA guidance and updates
- Review Daraja API terms for changes
- Check BRELA API specifications

**Update Process:**
- Document changes in COMPLIANCE_UPDATES.md
- Create issues for required code changes
- Test updates with pilot businesses
- Communicate changes to customers

### 5.2 Compliance Auditing

**Monthly:**
- Verify data residency configuration
- Audit encryption certificate validity
- Review audit logs for access violations
- Test data export/deletion functions

**Quarterly:**
- Full compliance checklist review
- Test BRELA integration
- Validate VAT calculations
- Review audit logging coverage

**Annually:**
- Engage external compliance auditor
- Update privacy policy if needed
- Review all regulatory mappings
- Create compliance report for stakeholders

### 5.3 Escalation Procedures

**Data Breach:**
- Notify TCRA within 72 hours
- Contact affected users immediately
- Preserve evidence for investigation
- Conduct post-incident review

**Regulatory Violation:**
- Document the violation
- Create remediation plan
- Implement fix
- Test and verify compliance
- Report to regulatory body if required

---

## 6. Testing & Validation

### 6.1 Compliance Testing

**Unit Tests:**
- PDPA data export format validation
- BRELA integration error handling
- VAT calculation accuracy
- EFD receipt format generation

**Integration Tests:**
- End-to-end BRELA verification workflow
- M-Pesa transaction import flow
- VAT report generation and export
- Data deletion cascading logic

**Acceptance Criteria:**
- All regulatory requirements coded
- Tests passing for compliance features
- Documentation complete
- External audit passes

### 6.2 Pilot Testing

**BRELA Integration:**
- Test with 5+ real businesses
- Verify accuracy of business registration checks
- Gather feedback on user experience

**M-Pesa Daraja:**
- Test transaction import with real M-Pesa data
- Verify accuracy and timeliness
- Test error scenarios

**EFD Integration:**
- Pilot with 2-3 early adopter businesses
- Test receipt generation and submission
- Document real-world issues

---

## 7. Documentation & Communication

### 7.1 Developer Documentation

**REGULATORY_COMPLIANCE.md** (this file)
- Authority mappings
- Implementation plans
- Risk mitigation
- Compliance procedures

**API Integration Guides:**
- BRELA API integration guide
- M-Pesa Daraja integration guide
- TRA EFD integration guide
- NBAA accounting standards reference

**PR Compliance Checklist:**
- Required: Privacy impact assessment
- Required: Encryption and data handling review
- Required: Audit logging verification
- Recommended: Third-party compliance check

### 7.2 User Documentation

**Privacy Policy:**
- Data collection and usage
- User rights (export, deletion)
- Security measures
- Contact for privacy questions

**Terms of Service:**
- Regulatory clauses
- Data handling terms
- Payment terms (if applicable)
- Compliance responsibilities

### 7.3 Internal Documentation

**Compliance Procedures:**
- Data breach response
- Regulatory change process
- Audit procedures
- Escalation contacts

**Regulatory Updates Log:**
- Track all TRA/TCRA/BRELA updates
- Document Mali Up response
- Note code changes made
- Release notes for customers

---

## 8. Key Contacts & Resources

### Regulatory Authorities

| Authority | Contact | Notes |
|-----------|---------|-------|
| **BRELA** | brela.go.tz | Business registration verification |
| **TRA** | tra.go.tz | VAT and tax requirements |
| **TCRA** | tcra.go.tz | PDPA compliance and mobile regulations |
| **BoT** | bot.go.tz | Monitor for payment licensing |
| **NBAA** | nbaa.co.tz | Accounting standards reference |

### API Providers

| Provider | Portal | Docs |
|----------|--------|------|
| **Safaricom Daraja** | daraja.safaricom.co.ke | M-Pesa API documentation |
| **Vodacom Daraja** | vodacom-tz.daraja.co.ke | M-Pesa (TZ) API documentation |

### Internal Contacts

- **Product Manager:** [responsible for Phase roadmap]
- **Security Officer:** [responsible for data protection]
- **Finance Officer:** [responsible for VAT/tax compliance]
- **Legal Officer:** [responsible for ToS/Privacy Policy]

---

## 9. Appendix: Phase 1 Setup Checklist

Before Phase 1 launch, verify:

- [ ] Firebase console access
- [ ] Firestore region set to Africa
- [ ] TLS 1.3 enabled (verify in Firebase console)
- [ ] Privacy policy draft created
- [ ] Consent framework designed
- [ ] Data export API spec defined
- [ ] Data deletion API spec defined
- [ ] Biometric API research complete (Flutter packages)
- [ ] PIN storage approach decided (keychain/keystore)
- [ ] Audit log database schema designed

---

## 10. Appendix: Phase 2 Setup Checklist

Before Phase 2 launch, verify:

- [ ] BRELA API documentation obtained
- [ ] BRELA sandbox account created
- [ ] BRELA integration service structure designed
- [ ] M-Pesa Daraja registration plan created
- [ ] Daraja API documentation reviewed
- [ ] Daraja sandbox credentials obtained
- [ ] M-Pesa transaction data model designed
- [ ] TCRA compliance checklist prepared
- [ ] BoT monitoring process documented

---

## Document Version

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05-24 | Initial regulatory compliance plan for Mali Up Tanzania |

---

**Last Updated:** 2026-05-24  
**Owner:** Mali Up Security & Compliance Team  
**Status:** Active - Living Document
