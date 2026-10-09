# BiyaheBuddy PH — Design System

An offline AI co-pilot for Filipino drivers: legal Q&A, traffic fines,
emergency SOS. This file is the source of truth for the UI. Code lives in
`lib/core/theme/` (tokens, `ThemeData`, `AppPalette`) and
`lib/features/shared/widgets/` (components). Screens never hardcode colors,
sizes or durations — they use these tokens.

## 1. Personality

**Calm, trustworthy, premium co-pilot.** It sits in the car with you at night,
after a scare at a checkpoint or a crash. It never shouts, never clutters,
always shows where its answer comes from.

| Reference | What we take from it |
|---|---|
| Apple Maps (night) | Near-black canvas, glass panels over content, big legible type, one accent |
| iOS Emergency SOS | One unmistakable red control; nothing else is red; slide/hold to confirm when needed |
| iMessage | Blue user bubbles right, grey assistant bubbles left, typing dots |
| Apple Wallet | Rich colored cards with a big number, a clear "present this" action |

Design principles, in priority order:

1. **Safety first.** SOS is always one tap from Home, always red, nothing else is.
2. **Glanceable.** Key facts (coding today, fine amount, the law) readable in
   one look at arm's length, in a moving car, at night.
3. **Grounded.** Every legal statement shows its citation as a law pill.
4. **Calm motion.** One animated element per screen at most; respects reduce motion.
5. **One thumb.** Primary actions in the lower half; targets ≥ 48dp.

Sources: the `ui-ux-pro-max` skill's verified matches — product "Emergency
SOS & Safety" (Accessible & Ethical + Flat, with Dark Mode OLED and
Minimalism as secondary styles; alert red + safety blue + location green +
high contrast), style "Dark Mode (OLED)" (deep near-black, minimal glow,
7:1 text), Flutter stack rules (ThemeData + darkTheme, `Theme.of(context)`,
dispose controllers, implicit animations), UX rules (contrast 4.5:1, touch
48dp + 8dp gaps, reduced motion, 1–2 animated elements per view) and its
Pre-Delivery Checklist. Its suggested red primary and Garamond/Lato fonts
were rejected: red is SOS-only here and the font is bundled Plus Jakarta Sans.

## 2. Color tokens

Dark is the default design target (night driving); light is equally
polished. All values are semantic — features use the role, never the hex.
Contrast ratios are measured (WCAG 2.x) against the surface they sit on.

### Neutrals

| Token | Dark | Light | Use |
|---|---|---|---|
| `bg` | `#0B0D12` | `#F2F3F7` | Canvas (near-black: OLED-friendly, less glare than pure white text on #000) |
| `surface` | `#161A22` | `#FFFFFF` | Cards, grouped lists, tiles |
| `surfaceElevated` | `#202530` | `#F7F8FA` | Raised elements on a card: Buddy bubble, fields, pressed rows |
| `surfaceSunken` | `#0F1218` | `#E9EBF0` | Inset wells, segmented-control track |
| `glass` | `#161A22` @ 72% + blur 24 | `#FFFFFF` @ 72% + blur 24 | Tab bar, chat input, sticky headers |
| `separator` | `#343B49` | `#C9CED8` | Hairline (0.5dp) dividers — decorative only |
| `controlOutline` | `#6B7486` (3.7:1) | `#7C8595` (3.7:1) | Input/control boundaries — meets 3:1 non-text contrast |
| `textPrimary` | `#F2F4F8` (15.8:1 on surface) | `#0B0D12` (17.5:1 on bg) | Body, titles |
| `textSecondary` | `#A7AFBD` (7.9:1) | `#5A6372` (6.1:1 on white, 5.5:1 on bg) | Subtitles, metadata |
| `textTertiary` | `#6B7486` | `#8A93A3` | Disabled, placeholders — **never** for information |

### Accents (each has one meaning)

| Token | Dark | Light | Meaning | Text on it |
|---|---|---|---|---|
| `primary` (trust blue) | text `#4D9BFF` (6.2:1); fill `#1F6FE5` | text/fill `#0064D6` (5.5:1) | Links, primary buttons, selection, user chat bubble, location | white: 4.7:1 dark, 5.5:1 light |
| `success` (go green) | `#30D158` (8.6:1) | `#1F7A35` (5.4:1) | Safe states: "Hindi ka coding", "Offline-ready ✓", call buttons | dark: `#0B0D12`; light: white |
| `caution` (amber) | `#FFB020` (9.5:1) | `#9A5B00` text (5.4:1); fill `#FFB020` | Coding badge, law pills/citations, validation errors | `#0B0D12` (10.6:1) |
| **`sos` (red)** | `#FF3B30` → `#D70015` | same | **SOS / emergency only.** Never errors, never delete, never badges | white: big label 3.6:1 (large text OK); small text only on `#D70015` (5.4:1) |

Tinted chip backgrounds (verified with their text color):
`success.tint` dark `#14281B` / light `#E3F5E8` (7.7:1 / 4.8:1),
`caution.tint` dark `#2E2410` / light `#FFF1D6` (8.4:1 / 5.7:1, light text `#8A5200`),
`primary.tint` dark `#14223A` / light `#E2EEFF` (5.6:1 / 4.7:1).

### Agency colors (Wallet fine card only)

Brand-neutral gradients — **not** official agency colors or logos (we never imply
endorsement). White text on every stop ≥ 5.6:1.

| Agency | Gradient (top-left → bottom-right) |
|---|---|
| LTO | `#2450C8` → `#1E3A8A` (indigo) |
| MMDA | `#14727A` → `#0F5257` (teal) |
| City | `#6A35C9` → `#4C1D95` (violet) |

Rules: color is never the only signal (chips also have an icon + word);
red appears only on SOS surfaces; both themes are checked independently.

## 3. Typography — Plus Jakarta Sans (bundled, `assets/fonts/`)

Sized up from iOS for in-car reading. Weights bundled: 400/500/600/700/800.
Numbers that matter (fines, plates, times) use tabular figures
(`FontFeature.tabularFigures()`).

| Style | Size / line | Weight | Tracking | Use |
|---|---|---|---|---|
| `display` | 44 / 48 | 800 | −1.0 | Fine amount on Wallet card, IPAKITA message |
| `largeTitle` | 34 / 40 | 800 | −0.6 | Screen titles (Home greeting) |
| `title1` | 28 / 34 | 700 | −0.4 | Section heroes ("Ligtas ka ba?") |
| `title2` | 22 / 28 | 700 | −0.2 | Card titles |
| `headline` | 18 / 24 | 700 | 0 | Row titles, button labels (large-text contrast tier) |
| `body` | 17 / 25 | 500 | 0 | Chat text, explanations (minimum for reading) |
| `callout` | 16 / 22 | 500 | 0 | Secondary body, list subtitles |
| `subhead` | 15 / 20 | 600 | 0 | Metadata, chip labels |
| `footnote` | 13 / 18 | 500 | 0 | Timestamps, legal-basis fine print (never sole info) |
| `caption` | 12 / 16 | 700 | +0.6, UPPERCASE | Section headers in grouped lists |

Dynamic Type: everything scales with the system up to 2.0×. Compact chrome
is clamped so layout survives: status chips/badges 1.3×, tab bar 1.3×, law
pills 1.4×, SOS label scales down to fit its circle. No text below 12.

## 4. Spacing, layout, radii

**4dp grid.** Tokens: `xxs 4 · xs 8 · sm 12 · md 16 · lg 20 · xl 24 · 2xl 32 · 3xl 40 · 4xl 56`.

- Gutters: 16 (phone < 400dp), 20 (large phone), 32 (tablet). Content max
  width 640dp, centered (tablets, landscape).
- Section rhythm: 8 within a component · 16 between related items · 24
  between groups · 32 between sections.
- Touch targets ≥ 48×48dp (visual may be smaller with expanded hit area),
  ≥ 8dp between adjacent targets.
- Layouts fill the screen: flexible regions (`Expanded`/`Spacer`) absorb extra
  height; content scrolls only when it truly doesn't fit (large font, small
  phone). Bottom content always clears the floating tab bar + safe area.

**Radii:** `xs 8` (icon squares, small badges) · `sm 12` (icon tiles,
inputs inner) · `md 18` (buttons, fields, chat bubbles) · `lg 24` (cards,
action tiles, grouped lists) · `xl 32` (Wallet card, sheets, tab bar) ·
`full` (chips, pills, SOS).

## 5. Elevation & glass

| Level | Dark | Light | Use |
|---|---|---|---|
| 0 Canvas | `bg` | `bg` | Screen |
| 1 Card | `surface` + 0.5dp top highlight `#FFFFFF` @ 6% | `surface` + shadow `0 1 2 / 6%` | Lists, tiles |
| 2 Raised | `surfaceElevated` | `surface` + shadow `0 8 24 / 8%` | Wallet card, bubbles, chips over content |
| Glass | blur 24 + `glass` + hairline `separator` | same | Tab bar, chat input, sticky header |
| Glow | SOS only: `sos` @ 35–55% blur 28–44 | same | Hero SOS button |

Dark mode separates layers with **surface steps, not shadows** (shadows are
invisible on near-black). No 3D effects, no heavy/multi-layer shadows.

## 6. Icons

- **One family: CupertinoIcons**, SF-Symbol-like.
- **Filled** = primary/active/selected; **outline** = secondary/inactive.
  Never mix at the same hierarchy level.
- Size tokens: `iconSm 16` (inline with footnote) · `iconMd 22` (rows,
  chips) · `iconLg 28` (tiles, tab bar) · `iconXl 40` (hero states).
- Tile icons sit in a 44dp rounded square (`radius sm`) tinted with the
  action's accent at 16%.
- Icons beside a visible label are decorative (excluded from semantics);
  icon-only controls get a label + tooltip. No emoji as icons — the "✓" in
  "Offline-ready" is an icon (`checkmark_seal_fill`), not a character.

## 7. Motion

| Token | Duration | Curve | Use |
|---|---|---|---|
| `press` | 100ms | easeOut | Press scale 0.97 + highlight (no layout shift) |
| `quick` | 180ms | easeOutCubic | Toggles, chips, segmented controls |
| `standard` | 260ms | easeOutCubic | Content enter, expand/collapse |
| `emphasized` | 380ms | easeOutQuart | Sheets, Wallet card reveal |
| exits | 0.75× of enter | easeInCubic | Leaving elements |
| `sosBreath` | 2400ms loop | easeInOutSine | SOS glow pulse |
| `typing` | 1200ms loop, 150ms stagger | easeInOut | Chat typing dots |

- Page transitions: Cupertino (slide + parallax), back-swipe works everywhere.
- **At most one looping animation per screen** (SOS glow on Home, typing
  dots in chat).
- **Reduce motion:** loops stop and show their resting state (static glow,
  static "…"), transitions become crossfades ≤ 150ms. Every
  `AnimationController` is disposed.
- Haptics: light on taps, selection on toggles/tabs, medium on primary
  actions (IPAKITA, text contacts), heavy on SOS.

## 8. Components

Each lives in `lib/features/shared/widgets/` and takes no colors as
parameters — it reads tokens.

### Status chip
Compact fact pill on Home: icon (`iconMd`, filled) + `subhead` label.
Height 36, radius full, padding 12/8. Variants by meaning:
`coding` (caution tint, "Coding ka ngayon" / success tint "Hindi ka coding"),
`offline` (success tint), `location` (primary tint, "Makati · GPS ✓" or
"Walang GPS"). Never red. Text clamp 1.3×. Wraps to a second line of chips,
never truncates the meaning word.

### "Offline-ready ✓" badge
Trust signal that the AI runs on-device. `success` icon `checkmark_seal_fill`
+ "Offline-ready" in `subhead`, success tint, radius full, height 28 (header
size) or 36 (chip size). States: ready (green), downloading (primary tint +
progress %), missing (caution tint "I-download si Buddy"). Tapping explains
"Gumagana kahit walang signal".

### Action tile (2×2 grid)
Square-ish card (`surface`, radius lg, min height 120): accent icon square
top-left, `headline` title, `footnote` subtitle (1 line, hides at 2.0× font).
Whole tile is one button; press = scale 0.97 + light haptic. Grid gap 12.
Fills its row height; never fixed-height.

### List row
iOS grouped row: leading icon square (32, radius xs) or avatar, title
`headline`, optional subtitle `callout`/`textSecondary`, trailing value or
chevron (`textTertiary`). Min height 56; separators inset to text start.
Destructive actions are **not** red (red = SOS): they use `textSecondary`
icon + confirmation sheet.

### Wallet-style fine card
The result of "Na-flag ako". Aspect ≈ 1.6:1 (credit-card proportion) up to
width 420, radius xl, agency gradient, Raised level.
- Top row: agency mark (text "LTO"/"MMDA"/"LUNGSOD" in a white-15% rounded
  square — no official logos) · offense chip ("1st offense").
- Middle: violation `title2` white, 2 lines max.
- Bottom-left: amount `display` with tabular figures ("₱1,000").
- Bottom-right: law pill (white-20% background, white text).
- Footer (outside card): legal basis `footnote` + "Humingi ng official ticket"
  note (caution tint), then the primary **IPAKITA** button.
Enter: emphasized slide-up + fade; reduce motion: fade only.

### Chat bubble (iMessage)
- User: right, `primary` fill, white `body`, radius md with 6dp tail corner
  bottom-right, max width 80% (520dp).
- Buddy: left, `surfaceElevated`, avatar 28dp (Buddy glyph on primary
  circle) aligned to bottom, radius md with tail bottom-left, max width 92%.
- Typing indicator: Buddy bubble with three 8dp dots, `typing` loop;
  reduce motion → static "…".
- Consecutive messages from the same sender group with 4dp gaps; 16dp between
  senders.

### Answer section card
Inside a Buddy bubble, one per section (Kalma muna / Ano ang sinasabi ng
batas / Pagsusuri / Ano ang gagawin). `surface`, radius md, padding 14.
Header: 24dp tinted icon square + `headline` label. Section colors (icon tint
only): Kalma = success, Batas = caution, Pagsusuri = primary, Gagawin =
primary. "Ano ang gagawin" renders numbered steps with 24dp number circles.

### Law pill
Citation chip for "RA 4136 Sec. 44" etc. `caution` fill, `#0B0D12` text,
`footnote`/`subhead` weight 700 with `book_fill` 14dp icon, radius full,
height 26, tabular figures. Inline in text (baseline-aligned), wraps as a
unit. Tappable → sheet with the section's full text and source URL.

### SOS hero button
- Circle, diameter = available height / width (Home layout decides), min 120,
  max 60% of content width. Radial gradient `#FF3B30` → `#D70015`.
- Label "SOS" `display` white (scales down to fit), sublabel
  "Pindutin kapag naaksidente" **below** the circle in `callout`
  `textSecondary` (small text never sits on bright red).
- Glow: soft red shadow breathing on `sosBreath` (opacity 35%→55%, blur
  28→44); one loop only, no expanding rings. Reduce motion → static 45%.
- One tap → Emergency (no confirm dialog); heavy haptic; press scale 0.95.
- Semantics: button, "SOS. Pindutin kapag naaksidente".

## 9. Screen blueprints (Phase 2 order)

1. **Home = car dashboard.** Profile card (avatar with initials in a gradient
   ring · time-based greeting · name · PH license-plate badge + vehicle ·
   one row of chips: coding / Offline / GPS icon-only; tap → Profile) · SOS
   hero, ~68% of the screen width (max 380dp), shrinking gracefully on short
   phones · 2×2 actions with short labels (Buddy, Na-flag ako, QR, Lokasyon;
   subtitles only if all fit) · "Tip ng araw" only when SOS keeps its size
   (tablets). Greeting: 4:00–11:59 umaga, 12:00–5:59 PM hapon, otherwise gabi.
2. **Buddy chat.** Glass header with avatar, "Buddy", Offline-ready badge;
   iMessage bubbles; typing indicator; answer section cards; law pills;
   glass input with mic/send; Tanong / Dalawang panig segmented control.
3. **Na-flag ako.** Agency picker (3 large rows with agency color dots) →
   search + mic → results list → Wallet fine card → IPAKITA (full-screen,
   always dark).
4. **Emergency.** iOS-Emergency-SOS feel: red-tinted header band, big
   "Ligtas ka ba?" two-choice, contacts with call/text, hotlines, checklist,
   medical ID card, QR.
5. **Profile + Onboarding.** Medical-ID-style profile header, grouped
   settings rows, appearance switch; onboarding download card with the
   Offline-ready badge states.

## 10. Accessibility & QA checklist (per screen)

From the skill's Pre-Delivery Checklist, adapted to this app:

- [ ] Text ≥ 4.5:1 (normal) / 3:1 (≥ 18.7dp bold) in **both** themes; icons
      and control outlines ≥ 3:1
- [ ] Color never the only signal (icon + word on every status)
- [ ] Touch targets ≥ 48dp, ≥ 8dp apart; pressed feedback within 100ms
      without layout shift
- [ ] Largest font (2.0×) on 360×640, phones and tablets (portrait +
      landscape): no overflow, no dead space — `test/screens_matrix_test.dart`
- [ ] Reduce motion: loops static, no motion-only meaning
- [ ] Safe areas: nothing under the status bar, tab bar or gesture area
- [ ] Screen-reader labels on icon-only controls; decorative icons excluded;
      reading order = visual order
- [ ] Red only on SOS surfaces
- [ ] All tokens from `lib/core/theme/`; no hex in `lib/features/`
      (exceptions: QR black-on-white, IPAKITA forced dark)
