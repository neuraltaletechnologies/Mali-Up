# ClickPesa Payment Gateway Integration

## Overview
This document describes the ClickPesa payment gateway integration for Mali Up plan upgrades.

## Configuration

### Required Environment Variables (dart-define)

The ClickPesa credentials must be passed at build time using `--dart-define` flags for security. **Never commit API keys to source control.**

```bash
flutter build apk \
  --dart-define=CLICKPESA_CLIENT_ID=IDB9DctYJ72nQWspfp5Ty2cl8ihOrNn3 \
  --dart-define=CLICKPESA_API_KEY=SKbclwDOjhXsGnuYIOQsLxx1sLa2PKn95yEshGsq91
```

For iOS:
```bash
flutter build ios \
  --dart-define=CLICKPESA_CLIENT_ID=IDB9DctYJ72nQWspfp5Ty2cl8ihOrNn3 \
  --dart-define=CLICKPESA_API_KEY=SKbclwDOjhXsGnuYIOQsLxx1sLa2PKn95yEshGsq91
```

### Local Development

Create a `clickpesa.local.json` file (gitignored) with your credentials:
```json
{
  "CLICKPESA_CLIENT_ID": "your-client-id",
  "CLICKPESA_API_KEY": "your-api-key"
}
```

Then run:
```bash
flutter run --dart-define-from-file=clickpesa.local.json
```

## Architecture

### Files
- `lib/core/services/clickpesa_service.dart` - Core service for payment operations
- `lib/shared/widgets/upgrade_sheet.dart` - Updated to use ClickPesa for plan upgrades

### Payment Flow

1. **User selects plan** (Growth/Business) in upgrade sheet
2. **User taps "Upgrade"** button
3. **App creates ClickPesa payment** via API:
   - Amount: Plan price (TZS)
   - Reference: Unique payment reference (MALIUP-{TIER}-{TIMESTAMP})
   - Customer info: Phone, email from user profile
4. **App launches ClickPesa payment URL** in external browser
5. **User completes payment** on ClickPesa page (M-Pesa, Card, etc.)
6. **App polls for payment status** (every 3 seconds, max 30 attempts)
7. **On success**: Plan activated in Firestore immediately
8. **On failure**: Error shown, user can retry

### Security

- API keys injected at build time via `--dart-define` (not in source control)
- Payment verification done server-side via ClickPesa API
- Plan activation only after confirmed payment
- All payment metadata stored in Firestore for audit trail

### ClickPesa API Endpoints Used

- `POST /v2/payments` - Create payment
- `GET /v2/payments/{id}` - Verify payment status
- `GET /v2/payments?reference={ref}` - Check by reference

## Testing

### Sandbox Mode
Use ClickPesa sandbox credentials for testing:
- Client ID: (provided by ClickPesa sandbox)
- API Key: (provided by ClickPesa sandbox)

### Test Payment Flow
1. Run app with sandbox credentials
2. Open upgrade sheet
3. Select plan and tap upgrade
4. Complete test payment in sandbox
5. Verify plan activates

## Troubleshooting

### Common Issues

1. **"CLICKPESA_CLIENT_ID not configured"**
   - Ensure `--dart-define` flags are passed at build time
   - Check `flutter build` command includes both flags

2. **Payment URL doesn't open**
   - Check `url_launcher` permissions in AndroidManifest.xml / Info.plist
   - Ensure ClickPesa returns valid `paymentUrl`

3. **Payment verification timeout**
   - Increase `maxAttempts` in `waitForPayment()`
   - Check ClickPesa webhook configuration

4. **Plan not activating after payment**
   - Check Firestore rules allow user document write
   - Verify `processSuccessfulPayment()` completes without error

### Debug Logging
Enable debug logging by checking console output:
```
[ClickPesa] Creating payment for growth: 30000 TZS
[ClickPesa] Payment created: pay_xxx
[ClickPesa] Plan activated for user uid: growth
```

## Compliance

### ClickPesa Terms & Conditions
- API keys must be kept secure and rotated periodically
- Payment data handled per PCI DSS requirements
- Customer consent obtained before payment initiation
- Refund policy aligned with ClickPesa terms

### Data Privacy
- Only necessary customer data sent to ClickPesa (phone, email, name)
- Payment references stored for audit, not full card details
- GDPR/PDPA compliant data handling

## Support

For ClickPesa integration issues:
- ClickPesa API docs: https://docs.clickpesa.com
- ClickPesa support: support@clickpesa.com
- Mali Up internal: Check Sentry for payment errors