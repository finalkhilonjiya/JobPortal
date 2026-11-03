# Housing

Rent, buy, sell rooms, PGs, homestays, flats, houses, plots and commercial spaces.
Flutter app + Supabase (new, empty project).

Package id stays `com.khilonjiya.marketplace` so this replaces the existing Play Store app.

## One-time setup

### 1. Supabase (new empty project)
1. supabase.com -> New project.
2. SQL Editor -> paste all of `supabase/schema.sql` -> Run.
3. Authentication -> Providers -> **Phone** -> enable.
   - Add **Test phone numbers and OTPs** (e.g. `918486000001=123456`). No SMS is sent for these.
   - Before public launch, connect a real SMS provider (Twilio / MessageBird / Vonage) in the same screen.
4. Project Settings -> API -> copy the **Project URL** and the **anon public key**.

### 2. GitHub secrets (repo -> Settings -> Secrets and variables -> Actions -> Secrets)
| Secret | Value |
|---|---|
| `SUPABASE_URL` | Project URL |
| `SUPABASE_ANON_KEY` | anon public key |
| `KEYSTORE_BASE64` | your existing `.jks` converted to base64 (see below) |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | key alias |
| `KEY_PASSWORD` | key password |

Windows PowerShell, to make the base64 text (copies it to the clipboard):
```
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\your.jks")) | Set-Clipboard
```

### 3. Build
GitHub -> Actions -> **Build Android (AAB + APK)** -> Run workflow.
When it finishes, download `housing-aab` (upload to Play) or `housing-apk` (install on a phone).

## Run locally
```
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## Version codes
Each workflow run uses `1000 + run number` as the Play version code. If Play ever says
the version code is already used, set a repository variable `BUILD_NUMBER_OFFSET` to a higher number.

## Roadmap
- [x] Auth (phone OTP), browse, search + filters, detail, shortlist, post property, my listings, report, delete account
- [ ] Map view and "near me"
- [ ] In-app chat
- [ ] Push notifications
- [ ] Paid boosts / featured listings (Razorpay)
- [ ] Saved searches and alerts
- [ ] Agent / broker profiles
- [ ] EMI calculator, rent agreement helper, locality insights
- [ ] Admin panel for verification and reports
