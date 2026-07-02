# Mali Up Release Keystore

## Security Notice
⚠️ **CRITICAL**: This keystore file is used to sign all releases on Google Play Store. 
**DO NOT COMMIT THIS FOLDER TO GIT** — it's already in `.gitignore`.

## Keystore Details
- **File**: `mali-up-release.jks`
- **Alias**: `mali-up-key`
- **Store Password**: `MaliUp@2026Key`
- **Key Password**: `MaliUp@2026Key`
- **Validity**: 10,000 days (≈27 years)
- **Algorithm**: RSA 2048-bit

## Safe Storage
1. **Backup this keystore** to a secure location (e.g., encrypted USB, password manager, secure vault)
2. **Never share** the passwords
3. **Keep** this keystore in a safe place — losing it means you can't update your app on Google Play

## For CI/CD (GitHub Actions, etc.)
To avoid storing passwords in code:
```bash
# Set as GitHub Secrets:
KEYSTORE_PASSWORD=MaliUp@2026Key
KEYSTORE_FILE_BASE64=$(base64 -i mali-up-release.jks)
```

Then in your workflow, decode and use:
```yaml
echo ${{ secrets.KEYSTORE_FILE_BASE64 }} | base64 -d > keystore/mali-up-release.jks
flutter build appbundle --release
```
