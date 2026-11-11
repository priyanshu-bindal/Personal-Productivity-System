# FocusFlow — Android Release Signing & Publishing

## 1. Create the Release Keystore

Run this command **once** to generate the keystore. Store it **outside** the repo.

### Windows (PowerShell)

```powershell
# Create the directory
mkdir -Force "$HOME\keystores"

# Generate the keystore (you will be prompted for passwords interactively)
keytool -genkeypair `
  -v `
  -keystore "$HOME\keystores\focusflow-release.jks" `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias focusflow `
  -storepass "iamarobot1621@A" `
  -keypass "iamarobot1621@A" `
  -dname "CN=FocusFlow, OU=Mobile, O=FocusFlow, L=Unknown, ST=Unknown, C=IN"
```

### macOS / Linux (Bash)

```bash
mkdir -p ~/keystores

keytool -genkeypair \
  -v \
  -keystore ~/keystores/focusflow-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias focusflow \
  -storepass 'iamarobot1621@A' \
  -keypass 'iamarobot1621@A' \
  -dname "CN=FocusFlow, OU=Mobile, O=FocusFlow, L=Unknown, ST=Unknown, C=IN"
```

---

## 2. Configure Local Signing

1. Copy the example file:
   ```bash
   cp mobile/android/key.properties.example mobile/android/key.properties
   ```

2. Fill in your values (this file is git-ignored):
   ```properties
   storeFile=C:/Users/princ/keystores/focusflow-release.jks
   storePassword=iamarobot1621@A
   keyAlias=focusflow
   keyPassword=iamarobot1621@A
   ```

---

## 3. Build the Release APK

```bash
cd mobile
flutter build apk --release
```

The signed APK is produced at:
```
mobile/build/app/outputs/flutter-apk/FocusFlow.apk
```

---

## 4. Verify the APK Signature

### Check the signing certificate
```bash
# Using apksigner (from Android SDK build-tools)
apksigner verify --print-certs mobile/build/app/outputs/flutter-apk/FocusFlow.apk
```

### Print the SHA-256 fingerprint
```bash
keytool -list -v -keystore ~/keystores/focusflow-release.jks -alias focusflow
# (Enter keystore password when prompted)
```

Or on Windows:
```powershell
keytool -list -v -keystore "$HOME\keystores\focusflow-release.jks" -alias focusflow
```

---

## 5. GitHub Actions — CI Signing

### 5.1 Base64-Encode the Keystore

**Linux / macOS:**
```bash
base64 -w 0 ~/keystores/focusflow-release.jks | pbcopy  # macOS
# or
base64 -w 0 ~/keystores/focusflow-release.jks           # Linux (copy output)
```

**Windows PowerShell:**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\keystores\focusflow-release.jks")) | Set-Clipboard
# The base64 string is now in your clipboard
```

### 5.2 Add GitHub Secrets

Go to your repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**, and add:

| Secret Name          | Value                                         |
|----------------------|-----------------------------------------------|
| `KEYSTORE_BASE64`    | Base64-encoded contents of `focusflow-release.jks` |
| `KEYSTORE_PASSWORD`  | Your keystore password                        |
| `KEY_ALIAS`          | `focusflow`                                   |
| `KEY_PASSWORD`       | Your key password                             |

### 5.3 Workflow

The CI workflow is at `.github/workflows/build-android.yml`. It:

1. Decodes `KEYSTORE_BASE64` into a temp file at `$RUNNER_TEMP/keystore/focusflow-release.jks`
2. Passes `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` as env vars to `flutter build apk --release`
3. **Always** securely shreds the temp keystore after the build (even on failure)
4. Uploads the signed APK as a GitHub Actions artifact

---

## 6. Security Notes

> [!CAUTION]
> **Losing the keystore = losing the ability to update the app.**
>
> If the `focusflow-release.jks` file or its passwords are lost, you will **never** be able to push updates to users who have the current version installed (they would need to uninstall and reinstall).

### Backup Checklist

- [ ] **Keystore file** backed up in **two separate secure locations**
  - A password manager vault (e.g. 1Password, Bitwarden)
  - An encrypted external drive or secure cloud storage
- [ ] **Passwords** stored separately from the keystore file
  - Never in the same location as the `.jks` file
  - In a password manager with a separate master password
- [ ] **SHA-256 fingerprint** recorded (printed from step 4 above)
  - Useful for Firebase, Google Play, and API key restrictions
- [ ] **Git-ignored** — Confirm `*.jks`, `*.keystore`, `key.properties` are all in `.gitignore`
- [ ] **No passwords in committed code** — The `build.gradle.kts` reads from env vars or `key.properties` only

### What's git-ignored

The following files should **never** appear in version control:

```
*.jks
*.keystore
key.properties
keystore.properties
```

These patterns are set in both the root `.gitignore` and `mobile/.gitignore`.
