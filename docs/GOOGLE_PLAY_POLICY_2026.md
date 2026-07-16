# Google Play policy readiness (2026)

Last reviewed: 2026-07-17

App: Mali Up  
Package: `com.neuraltale.maliup`

This is a release checklist, not a substitute for the declarations shown in Play Console. Console answers must match the production build and production data handling.

## July 15, 2026 update

| Requirement | Mali Up status | Required action |
| --- | --- | --- |
| Anonymous/random chat restrictions (effective 2026-08-26) | Not applicable. Mali Up has no anonymous or random chat. | Keep the target audience set to adults and revisit if any user-to-user chat is added. |
| Families prohibition on anonymous chat | Not applicable. Mali Up is an adult SME business tool. | In Target audience and content, do not select children as a target audience. |
| Child Safety Standards for chat apps | Not applicable to the current feature set. | Reassess before adding social, chat, matching, or user-generated public content. |
| `READ_CALL_LOG` no longer allowed for phone-call verification (effective 2027-01-27) | Compliant. The release manifest has no SMS or Call Log permission. Firebase OTP/manual code entry does not require them. | Do not add `READ_CALL_LOG`, `READ_SMS`, or `RECEIVE_SMS` for account verification. |
| Android developer/package registration (deadline 2026-09-30) | Cannot be verified from source control. | Open Play Console → Android developer verification and confirm `com.neuraltale.maliup` is registered. Complete any ownership/signing-key challenge shown there. |

Official deadlines: <https://support.google.com/googleplay/android-developer/table/12921780>

## Target API

- `compileSdk` and `targetSdk` are pinned to API 36 in `android/app/build.gradle.kts`.
- Google Play requires new apps and app updates to target Android 16 / API 36 from 2026-08-31.
- The generated release manifest was verified with `android:targetSdkVersion="36"`.

Official requirement: <https://support.google.com/googleplay/android-developer/answer/11926878>

## Release manifest permissions

The generated release manifest currently contains:

- `CAMERA`: barcode/QR scanning and user-initiated receipt or logo capture.
- `READ_CONTACTS`: user-initiated customer import. A prominent bilingual disclosure is shown immediately before the runtime request. Only selected contacts are saved and synced.
- `USE_BIOMETRIC` / `USE_FINGERPRINT`: optional local app lock.
- `POST_NOTIFICATIONS`: notifications. Keep the runtime request tied to a user-facing notification feature.
- Network, wake-lock, and Firebase messaging permissions supplied by dependencies.

It does **not** contain location, SMS, Call Log, phone-state, microphone, all-files access, package-install, or broad app-visibility permissions.

### Contacts policy follow-up

The broad Contacts Permissions policy becomes enforceable for apps targeting Android 17 / API 37 on 2026-10-28. Mali Up currently targets API 36. Before moving to API 37:

1. Prefer Android 17's permissionless system Contact Picker and remove `READ_CONTACTS`; or
2. Submit the Contacts declaration as a genuine CRM use case and explain why the system picker is technically insufficient.

A custom contact picker alone is not accepted as justification. Track this as a release blocker for the first API 37 build.

Official guidance: <https://support.google.com/googleplay/android-developer/answer/16935362>

## User Data and privacy

Repository changes made for policy readiness:

- Public privacy policy: `https://maliup.neuraltale.com/privacy`
- External deletion resource: `https://maliup.neuraltale.com/delete-account`
- The in-app delete action now calls the authenticated `deleteAccountData` Cloud Function instead of displaying a simulated success state.
- Remote owned-business data, personal profile/access records, user-owned uploads, and Firebase Auth identity are deleted; the device's Drift account data, security PIN, and preferences are then cleared.
- Financial amounts are no longer sent as Sentry metrics.
- Sentry default PII, profiling, and replay capture are disabled. The privacy policy discloses limited diagnostics.
- The privacy policy states that there is no current third-party AI integration. Reassess disclosure, consent, limited use, retention, and Data safety answers before adding one.

Before releasing these changes, deploy both the Cloud Function and public site. The mobile button must not ship before `deleteAccountData` is deployed.

## Play Console checklist

Complete or verify these manually:

- [ ] Android developer verification shows `com.neuraltale.maliup` as registered by 2026-09-30.
- [ ] App content → Target audience: adults only; the store listing does not target children.
- [ ] App content → Content rating: complete and submit the IARC questionnaire. Unrated apps are not permitted.
- [ ] App content → Privacy policy: use `https://maliup.neuraltale.com/privacy`.
- [ ] App content → Data safety → Account deletion: declare both the in-app route and `https://maliup.neuraltale.com/delete-account`.
- [ ] Data safety reflects all production SDKs and flows, including Firebase, Google Play Integrity, optional Sentry diagnostics, selected customer contacts, receipt/logo images, account identifiers, business/financial records, and security/diagnostic data.
- [ ] Data safety location answers are **No** unless a future release adds a location SDK or permission. Neither precise nor approximate location is in the current manifest.
- [ ] No SMS/Call Log Permissions Declaration is needed for the current bundle. Investigate if Play Console shows one, because it would indicate an old active artifact or an unexpected dependency manifest.
- [ ] Upload the final AAB to a test track and re-check App content warnings against the exact uploaded artifact.
- [ ] Confirm the privacy and deletion URLs are publicly reachable without login and return successful HTTPS responses.
- [ ] Test deletion in the Firebase production project with both an owner account and a team-member account before production rollout.

## Clarifications assessed

- Personal loans/Earned Wage Access: not applicable. Mali Up records receivables/payables but does not originate, broker, or service loans or EWA.
- Third-party AI: no mobile AI integration was found. The admin application's Anthropic dependency is not part of the mobile app; any user-data flow through it must still be separately assessed.
- Content ratings: a current IARC rating is required in Play Console.
- Location disclosures: the current Android build requests no location permission and code review found no location collection.

