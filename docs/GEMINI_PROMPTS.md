# Housing - Gemini prompt pack (icons, banners, photos)

Paste the **STYLE LOCK** at the start of every prompt so all images look like one brand.

## STYLE LOCK (copy this first, every time)

> Modern Indian real-estate app visual style. Clean, bright, premium, friendly. Brand colors: deep emerald green #0E7C66 (primary), soft mint #E6F4F0, warm coral #FF7A59 (accent), near-black ink #101828, off-white #F7F8FA. Soft natural daylight, gentle shadows, rounded shapes, no text, no watermark, no logos, no people's faces unless asked.

Save every image with the exact file name given. Put them in `assets/images/` (photos/banners) or `assets/icons/` (icons) and tell me - I will wire them into the app.

---

## 1. App icon and logo

**1.1 `app_icon.png` - 1024x1024, square, no transparency**
> [STYLE LOCK] App icon for a property app named Housing. A simple geometric white house silhouette with a small coral location-pin dot at the roof peak, centered on a smooth emerald green gradient rounded-square background. Flat vector style, minimal, bold, readable at 48px. No text.

**1.2 `app_icon_foreground.png` - 1024x1024, transparent background**
> Same white house with coral dot, on a fully transparent background, centered with 25% empty padding on every side, flat vector, no shadow.

**1.3 `logo_wordmark.png` - 1600x500, transparent background**
> [STYLE LOCK] Horizontal logo: the house icon on the left and the word "Housing" in a modern rounded geometric sans-serif (Poppins style), dark ink color, tight clean kerning, transparent background.

## 2. Home screen category icons (8 icons, 256x256, transparent, same style)

Use this base for each, changing only the subject:
> [STYLE LOCK] Single flat 3D-ish icon, emerald green and mint with one small coral accent, thick rounded edges, soft shadow beneath, transparent background, 256x256. Subject: ...

| File | Subject |
|---|---|
| `cat_rent.png` | a house key with a small tag |
| `cat_buy.png` | a house with a "sold" style price tag hanging from the roof (no text) |
| `cat_pg.png` | a single bed with a pillow and a small bedside lamp |
| `cat_homestay.png` | a cozy cottage with a pitched roof and a tree |
| `cat_room.png` | an open door showing a cozy room |
| `cat_flat.png` | a modern apartment building with balconies |
| `cat_plot.png` | a land plot with a fence and a small "for sale" sign (no text) |
| `cat_commercial.png` | a shop front with an awning |

## 3. Banners and heroes

**3.1 `hero_home.jpg` - 1080x720**
> [STYLE LOCK] Wide photo-realistic evening shot of a modern two-storey Indian home with warm lit windows, neat garden, a clear gradient sky from teal to soft orange. Leave the lower third calm and uncluttered for overlay text. No people.

**3.2 `banner_post_property.png` - 900x420, transparent background**
> [STYLE LOCK] Flat illustration of a smiling home owner (faceless, simple shapes) handing over house keys, with a mini house, a "+" badge and a price tag floating beside. Emerald, mint and coral palette.

**3.3 `banner_verified.png` - 900x420**
> [STYLE LOCK] Flat illustration of a house with a big green verified check-badge shield, small sparkles, calm mint background.

**3.4 `onboarding_1.png`, `onboarding_2.png`, `onboarding_3.png` - 1080x1350 each**
> [STYLE LOCK] Onboarding illustration, portrait, flat modern vector with soft depth.
> 1. A smartphone showing a map with many location pins above a small town skyline (search homes near you).
> 2. A hand holding a heart that contains a house (shortlist the ones you love).
> 3. Two hands exchanging house keys with a phone call icon above (talk directly to owners).

## 4. Empty and error states (each 800x800, transparent)

> [STYLE LOCK] Friendly flat illustration, transparent background, centered, lots of breathing room. Subject: ...

| File | Subject |
|---|---|
| `empty_search.png` | a magnifying glass over an empty street with a small house outline |
| `empty_shortlist.png` | a large empty heart outline next to a tiny house |
| `empty_listings.png` | an empty signboard with a house and a plus sign |
| `error_offline.png` | a house with a wifi symbol crossed out, gentle not scary |

## 5. Property photos (for demo/sample content and category placeholders)

Landscape, **1600x1200**, photo-realistic, natural light, wide-angle real-estate photography, no people, no text, no watermark, no brand logos. Indian context (furnishings, tiles, switches, window grills).

| File | Prompt subject |
|---|---|
| `demo_room_1.jpg` | A tidy single room in an Indian city: bed with light bedsheet, study table, window with soft curtains, tiled floor |
| `demo_pg_1.jpg` | A twin-sharing PG room with two single beds, wardrobe, wall shelves, bright and clean |
| `demo_pg_2.jpg` | A PG common dining area with a long table and benches, clean kitchen counter in the background |
| `demo_homestay_1.jpg` | A cozy homestay bedroom in Northeast India with bamboo and wood accents, woven bedspread, hills visible through the window |
| `demo_homestay_2.jpg` | Front view of a traditional Assam-type homestay with a veranda, green garden and tea plants |
| `demo_flat_1.jpg` | A 2 BHK living room with a sofa, TV unit, dining set, balcony door, light walls |
| `demo_flat_2.jpg` | A modular kitchen in an apartment, white and wood finish, clean counters |
| `demo_flat_3.jpg` | A bright master bedroom with wardrobe and attached bathroom door |
| `demo_house_1.jpg` | Exterior of a modern independent 2-storey Indian house with a small lawn and gate, daytime |
| `demo_house_2.jpg` | A spacious drawing room of an independent house with a sofa set and a wooden ceiling |
| `demo_plot_1.jpg` | A flat residential plot with boundary pillars and a road at the edge, greenery in the background, clear sky |
| `demo_commercial_1.jpg` | An empty ground-floor shop space with large glass front, tiled floor, ceiling lights |
| `demo_bathroom_1.jpg` | A clean modern Indian bathroom with white tiles, shower and wash basin |

> Important: AI photos are fine for banners and demo content, but real listings must use the owner's own photos. Showing AI images as real properties would mislead users and can get the app flagged by Google Play.

## 6. Small UI assets

| File | Size | Prompt |
|---|---|---|
| `map_pin.png` | 256x256, transparent | [STYLE LOCK] Glossy emerald map pin with a tiny white house inside, soft shadow |
| `avatar_placeholder.png` | 512x512 | [STYLE LOCK] Neutral friendly person silhouette in mint circle, flat |
| `badge_verified.png` | 256x256, transparent | [STYLE LOCK] Round emerald badge with white check mark and subtle shine |
| `badge_featured.png` | 256x256, transparent | [STYLE LOCK] Round coral badge with a white star and subtle shine |

## 7. Play Store graphics (later)

| File | Size | Prompt |
|---|---|---|
| `playstore_icon.png` | 512x512 | Same as 1.1 |
| `feature_graphic.png` | 1024x500 | [STYLE LOCK] Wide banner: left side empty mint space for text, right side a smartphone showing a clean property app and a floating house and key, emerald and coral accents |
| `shot_*.png` | 1080x1920 | I will generate real screenshots from the running app and frame them |

---

### Tips for best results in Gemini
1. Generate 3-4 variations of 1.1 first. Pick one and say "keep exactly this style" for every other asset.
2. If an image has text in it, add: "Remove all text and letters completely."
3. For transparent PNGs ask for "plain white background", then remove it with remove.bg or Photoshop Express (Gemini often cannot output true transparency).
