# Wiring up beta signups on the landing page

The landing page form currently just shows a confirmation message — it doesn't actually save the email anywhere. Here are the three options ranked from easiest to most flexible.

---

## Option A: Google Sheets (zero-code, ~10 min)

**Best for:** You want something working today and don't want to write code.

### Steps
1. Create a new Google Sheet. Add columns in row 1: `timestamp`, `email`, `source`
2. Go to **Extensions → Apps Script**
3. Paste this code, save, and deploy as web app:

```javascript
function doPost(e) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  const data = JSON.parse(e.postData.contents);
  sheet.appendRow([new Date(), data.email, data.source || 'landing']);
  return ContentService
    .createTextOutput(JSON.stringify({ ok: true }))
    .setMimeType(ContentService.MimeType.JSON);
}
```

4. Click **Deploy → New deployment → Web app**
   - Execute as: **Me**
   - Who has access: **Anyone**
5. Copy the deployment URL — looks like `https://script.google.com/macros/s/AKfyc.../exec`

### Wire it into the landing page
In `landing.html`, replace the form's `onsubmit` with:

```html
<form class="signup-form" onsubmit="handleSignup(event, this)">
  <input type="email" placeholder="you@stanford.edu" required name="email" />
  <button type="submit">Request invite</button>
</form>

<script>
async function handleSignup(e, form) {
  e.preventDefault();
  const btn = form.querySelector('button');
  const email = form.querySelector('input').value;
  btn.textContent = 'Sending…';
  try {
    await fetch('YOUR_GOOGLE_SCRIPT_URL_HERE', {
      method: 'POST',
      mode: 'no-cors',
      body: JSON.stringify({ email, source: 'landing' }),
    });
    btn.textContent = "You're on the list ✓";
    btn.disabled = true;
  } catch (err) {
    btn.textContent = 'Try again';
  }
}
</script>
```

That's it. You'll see signups appear in your Google Sheet in real time.

---

## Option B: Resend + a notification email (recommended for launch)

**Best for:** When you deploy to Vercel, you want emails to be confirmed AND you get a notification.

This requires a Vercel deployment with a serverless function. Save this as `api/signup.js` in your Next.js or Vercel project:

```javascript
// api/signup.js
export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).end();

  const { email } = req.body;
  if (!email || !email.includes('@')) return res.status(400).json({ error: 'Invalid email' });

  // Send confirmation to the signup
  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'GSB Closet <hello@gsbcloset.com>',
      to: email,
      subject: "You're on the list",
      html: `<p>Thanks — you're in line for the GSB Closet beta. We'll text you within 48 hours when your spot opens.</p>`,
    }),
  });

  // Notify yourself
  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'GSB Closet <hello@gsbcloset.com>',
      to: 'YOUR_EMAIL@gmail.com',
      subject: `New beta signup: ${email}`,
      html: `<p>${email} just signed up.</p>`,
    }),
  });

  res.status(200).json({ ok: true });
}
```

Add `RESEND_API_KEY` to your Vercel env vars. Wire the form to POST `/api/signup`.

---

## Option C: Supabase (when you build the real app)

When you're already running Supabase for the app, just `INSERT INTO waitlist (email, source) VALUES ($1, 'landing')`. No new infra needed.

---

## My recommendation for THIS WEEK

**Use Option A (Google Sheets).** Get the landing page live today on Vercel, start collecting emails, then migrate to Option B/C when the app exists. Don't let perfect be the enemy of getting 50 GSB friends on a list.

## How to deploy the landing page TODAY

1. Download this project
2. Make a new folder called `gsb-closet-landing`, put `landing.html` inside, rename it `index.html`
3. Go to **vercel.com** → **Add New Project** → **Import** → drag the folder in
4. Click Deploy. You'll get a URL like `gsb-closet-landing.vercel.app` in 30 seconds.
5. Buy `gsbcloset.com` on Namecheap (~$12), add it as a domain in Vercel.
