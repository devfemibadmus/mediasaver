<!-- @format -->

# iOS Deployment Setup - Complete Guide

> ✅ **Works 100% from Windows!** No Mac needed after initial setup.

This workflow automatically builds your iOS app and uploads it to TestFlight every time you push to GitHub.

---

## 📋 What You Need Before Starting

1. **Apple Developer Account** (paid $99/year)
2. **Windows PC with PowerShell** (no Mac needed!)
3. **OpenSSL installed** on Windows: `winget install -e --id ShiningLight.OpenSSL`
4. **GitHub repository** with your Flutter project

---

## 🔑 Step 1: Create App Store Connect API Key

This lets GitHub upload your app automatically.

1. Go to: https://appstoreconnect.apple.com
2. Click **Users and Access** → **Keys** tab (under Integrations)
3. Click the **"+"** button
4. Name it: `GitHub Actions`
5. Role: **App Manager**
6. Click **Generate**
7. **Download the `.p8` file** (you can ONLY download this once!)
8. **Save these 3 values:**
    - **Key ID** (e.g., `MPG2DHFTMF`) - shown in the filename `AuthKey_MPG2DHFTMF.p8`
    - **Issuer ID** (a UUID) - shown at the top of the Keys page
    - The `.p8` file itself

---

## 🎫 Step 2: Create Apple Distribution Certificate

This signs your app so Apple trusts it.

### 2a. Generate Certificate Request (Windows PowerShell)

```powershell
# Run this in your project folder
openssl req -nodes -newkey rsa:2048 -keyout mediasaver.key -out mediasaver.csr
```

Just press Enter for all the questions (name, organization, etc. don't matter).

### 2b. Upload to Apple Developer Portal

1. Go to: https://developer.apple.com/account/resources/certificates/list
2. Click **"+"** button
3. Select **"Apple Distribution"**
4. Click **Continue**
5. **Upload** the `mediasaver.csr` file
6. Click **Continue** → **Download**
7. Save it as `distribution.cer` in your project folder

### 2c. Convert to P12 Format (Windows PowerShell)

```powershell
# Convert .cer to .pem
openssl x509 -in distribution.cer -inform DER -out mediasaver.pem -outform PEM

# Create P12 file (YOU MUST SET A PASSWORD WHEN ASKED!)
openssl pkcs12 -export -out mediasaver.p12 -inkey mediasaver.key -in mediasaver.pem
```

**IMPORTANT:** Remember the password you set! You'll need it for GitHub Secrets.

---

## 📦 Step 3: Create App ID

This identifies your app to Apple.

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click **"+"** button
3. Select **App IDs** → **Continue**
4. Select **App** → **Continue**
5. Fill in:
    - **Description:** `Media Saver`
    - **Bundle ID:** Select **Explicit** and enter: `com.blackstackhub.mediasaver`
6. Click **Continue** → **Register**

---

## 📱 Step 4: Create Provisioning Profile

This links your app, certificate, and Apple account together.

1. Go to: https://developer.apple.com/account/resources/profiles/list
2. Click **"+"** button
3. Select **App Store** (under Distribution) → **Continue**
4. Select your **App ID** (`com.blackstackhub.mediasaver`) → **Continue**
5. Select the **certificate** you just created → **Continue**
6. Name it: `MediaSaver AppStore Profile` → **Generate**
7. **Download** the `.mobileprovision` file to your project folder

---

## 🔐 Step 5: Convert Everything to Base64

GitHub needs these files encoded in Base64 format.

**Run these in PowerShell (in your project folder):**

```powershell
# 1. P12 Certificate
[Convert]::ToBase64String([IO.File]::ReadAllBytes("mediasaver.p12")) | Set-Clipboard
# Now paste into a text file and label it "P12"

# 2. Provisioning Profile (replace with your actual filename)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("MediaSaver_AppStore_Profile.mobileprovision")) | Set-Clipboard
# Paste into text file and label it "PROFILE"

# 3. API Key (replace with your actual filename)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_MPG2DHFTMF.p8")) | Set-Clipboard
# Paste into text file and label it "API_KEY"
```

Each command copies the Base64 string to your clipboard - paste it somewhere safe immediately!

---

## 🔒 Step 6: Add Secrets to GitHub

Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`

Click **"New repository secret"** and add these **7 secrets** one by one:

| Secret Name                        | Where to Get the Value                               |
| ---------------------------------- | ---------------------------------------------------- |
| `BUILD_CERTIFICATE_BASE64`         | Paste the P12 Base64 from your text file             |
| `P12_PASSWORD`                     | The password you set when creating the P12           |
| `BUILD_PROVISION_PROFILE_BASE64`   | Paste the PROFILE Base64 from your text file         |
| `KEYCHAIN_PASSWORD`                | Make up ANY strong password (e.g., `SecurePass123!`) |
| `APP_STORE_CONNECT_API_KEY_ID`     | Your Key ID (e.g., `MPG2DHFTMF`)                     |
| `APP_STORE_CONNECT_ISSUER_ID`      | The Issuer ID from App Store Connect (UUID format)   |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Paste the API_KEY Base64 from your text file         |

---

## 🎯 Step 7: Update Your Team ID

1. Get your Team ID from: https://developer.apple.com/account/#/membership/
2. Open `ios/ExportOptions.plist`
3. Replace `YOUR_TEAM_ID` with your actual Team ID

---

## 🚀 Step 8: Push to GitHub!

```powershell
git add .
git commit -m "Add iOS deployment workflow"
git push
```

**That's it!** The workflow will automatically:

- Build your iOS app on macOS runners (in the cloud)
- Sign it with your certificates
- Upload it to TestFlight

---

## 📊 Step 9: Watch the Build

Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/actions`

The build takes about 10-15 minutes. You'll see:

- ✅ Build completes
- ✅ App uploaded to TestFlight

---

## 🎉 Step 10: Test Your App

1. Go to: https://appstoreconnect.apple.com
2. Select your app
3. Go to **TestFlight** tab
4. Add internal testers
5. They'll get an email to download via TestFlight app

---

## 🔄 Future Deployments

Every time you push to `main` or `release` branch, the workflow automatically:

1. Builds the app
2. Uploads to TestFlight

**OR** manually trigger it:

1. Go to **Actions** tab on GitHub
2. Select "iOS Build and Deploy to App Store"
3. Click **"Run workflow"**

---

## 🛡️ Security Best Practices

All your certificate files are now in `.gitignore` and won't be committed.

**Backup these files safely** (NOT in the repo):

- `AuthKey_MPG2DHFTMF.p8` - Can NEVER be re-downloaded!
- `mediasaver.p12` - Your certificate
- `mediasaver.key` - Private key
- The P12 password you created

---

## 🆘 Troubleshooting

### ❌ "No matching provisioning profile"

- Check that your Bundle ID is exactly: `com.blackstackhub.mediasaver`
- Make sure you selected the correct certificate when creating the provisioning profile

### ❌ "Unable to validate your application"

- Double-check your 3 API key values in GitHub Secrets
- Make sure you copied the full Base64 strings (no spaces or line breaks)

### ❌ Build fails immediately

- Check that all 7 GitHub Secrets are added correctly
- Make sure your Team ID is updated in `ExportOptions.plist`

### ❌ Certificate expired

- Certificates last 1 year
- Generate a new one following Step 2 again
- Update the `BUILD_CERTIFICATE_BASE64` secret in GitHub

---

## ✅ Success Checklist

- [x] Downloaded `.p8` API key from App Store Connect
- [x] Created Apple Distribution certificate
- [x] Created App ID: `com.blackstackhub.mediasaver`
- [x] Created Provisioning Profile
- [x] Converted all files to Base64
- [x] Added all 7 secrets to GitHub
- [x] Updated Team ID in `ExportOptions.plist`
- [ ] Pushed to GitHub
- [ ] Workflow ran successfully
- [ ] App appeared in TestFlight

---

## 🎊 You're Done!

Your iOS app now deploys automatically to TestFlight every time you push to GitHub. No Mac required! 🎉
