# Firebase Lookup Data Upload Guide

## Quick Setup (2 minutes)

### Step 1: Download Service Account Key
1. Open Firebase Console: https://console.firebase.google.com/project/neuraltale-mali-up/settings/serviceaccounts/adminsdk
2. Click the **"Generate New Private Key"** button
3. Save the JSON file to a safe location, e.g., `C:\Users\YourUsername\.firebase\neuraltale-key.json`

### Step 2: Set Environment Variable (Windows PowerShell)
```powershell
# Run this command (replace path as needed):
$env:GOOGLE_APPLICATION_CREDENTIALS = "$env:USERPROFILE\.firebase\neuraltale-key.json"

# Verify it's set:
$env:GOOGLE_APPLICATION_CREDENTIALS
```

### Step 3: Upload Lookup Data
```powershell
# Change to project root
cd C:\SIDE\GIT\Maliapp

# Run the upload script
node tools/push_lookups.js
```

Expected output:
```
✓ Initialized with service account key
✓ Uploaded: lookups/business_types
✓ Uploaded: lookups/cities
✅ All lookup data pushed to Firestore!
```

---

## What Gets Uploaded

The script uploads to Firestore under the `lookups` collection:

**Document 1: `lookups/business_types`**
- Contains: 6 business types (Retail, Wholesale, Service, Manufacturing, Food & Beverage, Other)
- Each with icon names for the Flutter app

**Document 2: `lookups/cities`**
- Contains: 6 Tanzania cities
- Each with English and Swahili names

---

## Troubleshooting

### "Module not found: firebase-admin"
```powershell
npm install firebase-admin
```

### "Set GOOGLE_APPLICATION_CREDENTIALS..."
The environment variable is not set. Follow Step 1-2 above.

### "Permission denied" error
Make sure your service account key has Firestore write permissions (it should by default).

### Still having issues?
Run this to verify your setup:
```powershell
firebase projects:list
firebase firestore:indexes
```
