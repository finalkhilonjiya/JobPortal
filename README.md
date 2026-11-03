# Housing

Rent, buy and sell flats, houses, villas, PGs, homestays, plots, shops and offices.
Flutter app + Supabase. Package id stays `com.khilonjiya.marketplace` so it replaces the existing Play Store app.

## One-time setup

### 1. Supabase (new empty project)
SQL Editor -> run these files **in this order** (paste, Run):
1. `supabase/schema.sql` (already done if you ran it before)
2. `supabase/migrations/002_full_platform.sql`
3. `supabase/seed_demo.sql` (optional demo listings, 4 fake users, guides - so the app is not empty)

Authentication -> Providers -> **Phone** -> enable, add **Test phone numbers and OTPs**
(for example `918822989693=123456`). No SMS is sent for these.
Before public launch connect a real SMS provider (Twilio / MessageBird / Vonage) and complete DLT registration.

### 2. Make yourself admin
Log in once in the app with your number, then in the SQL editor:
```
update public.profiles set role='admin' where phone='+918822989693';
```
Profile tab -> **Admin panel** appears (listings, reports, users, promotions, settings).

New listings go live immediately. To require approval, open Admin panel -> Settings and switch off *Auto-approve*.

### 3. GitHub secrets (repo -> Settings -> Secrets and variables -> Actions)
`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`

### 4. Build
GitHub -> Actions -> **Build Android (AAB + APK)** -> Run workflow. Download `housing-apk` (phone) or `housing-aab` (Play Store).

## Run locally
```
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## Removing demo data
```
delete from auth.users where email like '%@housing.local';
delete from public.articles where slug like 'demo-%';
```
Demo photos live in `assets/demo/` and are referenced as `asset:demo_*` in the database. Real listings upload their own photos.

## Features in this version
Search with full filters, saved searches with alerts, near me (device location), listing-ID search, compare, recently viewed,
property page (gallery, floor plans, video, 360 link, reviews, similar, locality insights, open in Google Maps),
6-step post/edit wizard, owner dashboard (stats, lead pipeline, visits), real-time chat with images, block/report,
in-app notifications, agent/builder profiles, admin panel, promotion requests, calculators (EMI, price check,
land converter, yield, stamp duty, total cost, appreciation), guides.

## Not built yet
Razorpay payments, push notifications (Firebase), real SMS/email provider, document/KYC verification, bulk upload,
duplicate detection, in-app 360 viewer, watermark/CDN, coupons, SEO website, iOS, Hindi/Assamese.

## Version codes
Each workflow run uses `1000 + run number` as the Play version code. If Play says the version code is already used,
set a repository variable `BUILD_NUMBER_OFFSET` to a higher number.
