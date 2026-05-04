# GSB Closet — Engineering Spec for Claude Code

> Hand this file (and the visual prototype in `/prototype`) to Claude Code. Tell it: **"Read CLAUDE.md and schema.sql, then scaffold the Next.js app per spec."**

## What this is

A private, invite-only dress-borrowing platform for the Stanford GSB community. Members upload formal dresses they own; friends-of-friends can request to borrow them in exchange for dry-cleaning + a small fee (paid out-of-app via Venmo).

Think: Pickle, but scoped to your trusted network and frictionless to upload.

## Tech stack (non-negotiable for v1)

| Layer | Choice | Why |
|---|---|---|
| Framework | **Next.js 15 (App Router)** | SSR for SEO on the marketing page, fast on mobile |
| Language | **TypeScript (strict)** | Catches bugs early, especially with database types |
| Styling | **Tailwind CSS** + a few custom CSS vars for the palette | Matches the prototype's utility-first feel |
| UI Components | **Radix UI primitives** (unstyled) + custom-styled with Tailwind | Accessible, no design baggage |
| Database | **Supabase Postgres** | Postgres + auth + storage in one |
| Auth | **Supabase Auth** (email magic link + phone OTP) | Free, handles Stanford email verification |
| Storage | **Supabase Storage** | Photos go here |
| Email | **Resend** | 3K free/month, clean API |
| SMS (invites) | **Twilio** | Pay-as-you-go, ~$0.01/text |
| Hosting | **Vercel** | One-click deploy from GitHub, free tier |
| Image optimization | `next/image` | Built-in |
| Forms | **react-hook-form** + **zod** | Standard combo |
| State | React Server Components + `useState` for client interactivity. **No Redux, no Zustand.** | Keep it simple |
| Analytics | **Vercel Analytics** + **PostHog** (free tier) | Track onboarding funnel |

## Project structure

```
gsb-closet/
├── app/
│   ├── (marketing)/              # public pages (no auth)
│   │   ├── page.tsx              # landing page
│   │   └── invite/[code]/page.tsx# invite landing page
│   ├── (app)/                    # authenticated app
│   │   ├── layout.tsx            # shell with bottom tab bar
│   │   ├── browse/page.tsx
│   │   ├── search/page.tsx
│   │   ├── upload/page.tsx
│   │   ├── saved/page.tsx
│   │   ├── profile/page.tsx
│   │   ├── closet/[friendId]/page.tsx
│   │   └── dress/[dressId]/page.tsx
│   ├── (auth)/
│   │   ├── welcome/page.tsx
│   │   ├── verify-email/page.tsx
│   │   └── verify-phone/page.tsx
│   ├── api/
│   │   ├── invites/route.ts      # POST: create invite, GET: lookup
│   │   ├── borrows/route.ts      # POST: request, PATCH: accept/decline
│   │   └── upload-photo/route.ts # signed URL generator
│   └── layout.tsx
├── components/
│   ├── ui/                       # primitives: Button, Card, Input, Avatar, DressCard
│   ├── browse/                   # BrowseGrid, FriendsRow, EventsStrip
│   ├── upload/                   # PhotoUploader, ListingForm
│   └── auth/                     # OnboardingFlow
├── lib/
│   ├── supabase/                 # server + client SDK setup
│   ├── twilio.ts
│   ├── resend.ts
│   └── types.ts                  # generated from supabase
├── styles/
│   └── globals.css               # palette tokens, font imports
├── public/
├── supabase/
│   ├── migrations/
│   │   └── 00001_init.sql        # see schema.sql
│   └── seed.sql                  # mock data for local dev
├── CLAUDE.md
├── README.md
└── package.json
```

## Design system (must match prototype)

### Typography
- Display: **Cormorant Garamond** 400/500 (Google Fonts)
- Sans: **Inter** 400/500/600
- Mono: **JetBrains Mono** 400/500 (for tiny labels & dates)

### Palette (Cream — primary)
```css
--bg:        #F5F0E8;
--surface:   #FBF8F3;
--card:      #FFFFFF;
--ink:       #1F1B16;
--ink-soft:  #5C544A;
--ink-muted: #9A9087;
--line:      rgba(31, 27, 22, 0.08);
--accent:    #3A2E22;
--tint:      oklch(0.95 0.02 60);
```

Also support Ivory and Blush palettes (see `prototype/theme.jsx`) as a future theme switcher — not v1.

### Visual rules
- **Square corners** on cards (`border-radius: 2-4px`), never rounded
- **Sharp 1px hairlines** for dividers (`var(--line)`)
- Generous whitespace — match prototype padding (20px gutters, 24px between sections)
- Buttons: full-width, square, 16px padding, 13px uppercase tracked text
- Section labels: 10px Inter 600, letter-spacing 1.6px, uppercase, ink-muted color
- Image placeholders: aspect-ratio 3/4, soft solid color w/ subtle vertical stripe overlay

### Components to build first
1. `<Button>` — primary (ink bg), secondary (transparent w/ line border)
2. `<DressCard>` — image + brand kicker + display-font name + fee
3. `<Avatar>` — initials disc, deterministic color from user id
4. `<Chip>` — pill, active/inactive states
5. `<TopBar>` — large editorial title variant + tight title variant
6. `<TabBar>` — 5 tabs (Browse / Search / Add / Saved / You)
7. `<DressImage>` — solid color + stripe overlay placeholder

## Core features for v1

### 1. Onboarding (3 paths converge)

**Path A: Stanford email**
- Enter email → must end in `@stanford.edu` or `@gsb.stanford.edu`
- Resend sends a 6-digit code (15 min expiry)
- User enters code → account created, marked `verified_via='stanford_email'`

**Path B: Invite code**
- User taps invite link `gsbcloset.com/invite/abc123`
- Shows the inviter's profile + their note
- Enter phone number → Twilio sends OTP
- On success: account created, marked `verified_via='invite'`, friendship row created with inviter

**Path C: After auth, request contacts permission**
- Web app uses native browser Contacts API (limited support — degrade gracefully)
- iOS app (later) uses `Contacts.framework`
- For v1 web: skip this. Just show "Friends will appear as they join."

### 2. Upload a dress (manual photos for v1)

- 3-photo upload via drag-drop or file picker
- Form: name, brand (autocomplete from a static list of ~200 brands), retail price, size (XS/S/M/L), length (mini/midi/maxi), occasion (wedding guest / black tie / cocktail / daytime), color (pick from palette), borrow fee, notes (textarea)
- Save to `dresses` table, photos to Supabase Storage

**Future:** Single-photo + AI angle generation. Stub behind feature flag `FEATURE_AI_PHOTOS=false` for v1.

### 3. Browse

- Top: 3 upcoming events (manually curated for v1, hardcoded for the GSB calendar)
- Friends-in-network row (horizontal scroll of avatars → friend's closet)
- Filter chips: occasion (all / wedding / black tie / cocktail)
- 2-column grid of available dresses from your network

**Network = direct friends + friends-of-friends** (2 hops via the `friendships` table).

### 4. Closet detail (one friend's closet)

- Friend header: avatar, name, GSB class, mutuals count, sizing note
- Stats strip: pieces / lent / borrowed / rating
- 2-col grid of their dresses
- "Message" button → opens iMessage/SMS via `sms:` link with their phone (no in-app chat for v1)

### 5. Dress detail

- Photo gallery (3 photos)
- Brand kicker, big display-font name
- Owner pill → links to their closet
- Details grid: size, length, color, occasion, retail, worn count
- Notes from owner (italic display font in a tinted box)
- Cost breakdown: borrow fee + $22 dry clean estimate = total
- "Request to borrow" CTA → creates `borrows` row with status='pending', sends owner an email + SMS

### 6. Borrow request flow

- Borrower taps "Request" → pick dates → confirm
- Owner gets email + SMS: "Sloane wants to borrow your Ivory Silk Slip for Jun 14"
- Owner taps email link → goes to `/borrows/[id]` → Approve / Decline
- If approved: borrower gets notified, both see Venmo handoff instructions

**No in-app payments.** Show: "Venmo @sloane-mitchell $57"

### 7. Profile / my closet

- Your dresses + Add new card
- Activity tab: recent requests, returns, likes

## Database schema

See **`schema.sql`** in this directory. Run it on Supabase via SQL editor or the migrations folder.

## Auth implementation notes

```ts
// Stanford email verification — server action
"use server";
import { createClient } from '@/lib/supabase/server';

export async function startEmailAuth(email: string) {
  const allowed = email.endsWith('@stanford.edu') || email.endsWith('@gsb.stanford.edu');
  if (!allowed) throw new Error('Must use a Stanford email.');

  const supabase = createClient();
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: { emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback` },
  });
  if (error) throw error;
}
```

## Environment variables

Put these in `.env.local` (and add to Vercel later):
```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_SITE_URL=http://localhost:3000

RESEND_API_KEY=
RESEND_FROM_EMAIL=hello@gsbcloset.com

TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_FROM_NUMBER=

FEATURE_AI_PHOTOS=false
```

## Build order (recommended)

1. **Day 1:** Scaffold Next.js + Tailwind + Supabase. Get auth working with a Stanford email. Deploy a "Hello, GSB" page to Vercel.
2. **Day 2:** Build the design system primitives (Button, Card, Avatar, DressCard, TopBar, TabBar). Make a Storybook-style demo route.
3. **Day 3:** Database schema + seed data. Build Browse page reading real data.
4. **Day 4:** Upload flow (manual 3-photo). Test end-to-end with one user.
5. **Day 5:** Dress detail + borrow request creation. Wire up Resend for owner notifications.
6. **Day 6:** Friend's closet view. Friendship logic (when does someone show up in your network?).
7. **Day 7:** Invite code flow + Twilio SMS verification.
8. **Day 8:** Profile / my closet / activity feed.
9. **Day 9:** Landing page (see `landing.html` in `/prototype`).
10. **Day 10:** Polish, beta-test with 5 friends, fix bugs, launch.

## Out of scope for v1 (do not build)

- ❌ In-app messaging (use SMS via `sms:` link)
- ❌ In-app payments (use Venmo handoff)
- ❌ AI photo generation
- ❌ Email parsing / Shop integration
- ❌ Native iOS app
- ❌ Calendar / availability beyond a single date
- ❌ Reviews & ratings (display-only stub OK)
- ❌ Push notifications

## Testing requirements

- Run `npm run typecheck` and `npm run lint` before committing
- Component tests for Button, DressCard, Avatar (Vitest)
- E2E test for the signup flow (Playwright) — `email auth → upload one dress → see it on browse`

## Deployment checklist

1. Push to GitHub
2. Import repo on Vercel
3. Add all env vars from `.env.local`
4. Buy `gsbcloset.com` on Namecheap (~$12/yr), point to Vercel
5. Set up Supabase production project (separate from dev)
6. Verify Resend domain (DNS records on Namecheap)
7. Provision Twilio number (~$1/mo) + verify
8. Smoke test: sign up with your real Stanford email on production, upload a dress, request from a second account.

## When stuck

- Type errors: regenerate types with `npx supabase gen types typescript --project-id XXX > lib/types.ts`
- Auth issues: check Supabase dashboard → Auth → Logs
- Email not sending: Resend dashboard → Logs → look for bounces
- Build failing on Vercel: run `npm run build` locally first
