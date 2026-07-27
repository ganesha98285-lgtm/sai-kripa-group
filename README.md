# Sai Kripa Group — Taxation & Consultancy

A premium, cinematic single-page website for **Sai Kripa Group** (**Pramod Kumar Sharma**) — all types of taxation & consultancy under one roof, with **21 years of experience**.

Built as a real-time WebGL 3D scroll experience: a luxurious London-style office exterior whose doors open as you scroll, revealing an interior hall and the firm's services on wall-mounted panels.

## Services
- Income Tax (ITR) — all types
- GST registration & returns
- **Income Tax & GST cases** — notice reply, scrutiny & appeals
- TDS / TCS
- **ESI & PF** — registration & compliance
- Accounting / bookkeeping & business account management
- **Pvt Ltd company registration** (Private Limited, LLP & firm setup)
- **Trademark registration**
- Loan consultancy, project report & CMA
- Legal advisory (LLB) · 50 Lakh+ case handling

## Tech
- Three.js (WebGL 3D scene, reflections, bloom)
- GSAP ScrollTrigger + Lenis (scroll-driven camera)
- Vanilla HTML/CSS/JS — a single `index.html`, no build step

## View locally
Open `index.html` in a modern browser (internet required — Three.js/GSAP load from CDN).

## Live site
Enable **Settings → Pages → Deploy from branch → `main` / root**, then visit:
`https://ganesha98285-lgtm.github.io/sai-kripa-group/`

## Service request forms
Clicking a service on the website no longer jumps to WhatsApp. It opens a
3-step form built for that specific service — only the questions that actually
matter for that job, plus the list of documents to get ready.

On submit the visitor gets a **reference number** (`SKG-2607-0041`) and a
private **document upload link**, and the request appears instantly in the
office panel under **Leads** with every answer, so the CA can call already
knowing the case.

Setup: run `supabase/03-requests.sql` once in Supabase → SQL Editor.

## Contact — change the number in ONE place
All phone numbers and the email live in **`config.js`** under `CONTACT`.
Edit `whatsapp` / `numbers` / `email` there and the whole site, the office
panel and the upload page pick it up automatically.

The AI chat assistant reads its copy from `wrangler.jsonc` → `vars`
(`WA_NUMBER`, `FIRM_EMAIL`, `FIRM_OWNER`), so changing the number means
editing **`config.js` and `wrangler.jsonc`** — two files, no code.

Current:
- Phone / WhatsApp: 98877 05993 · 92148 62726 · 92616 26392
- Email: Kripasai2017@gmail.com
- Proprietor: Pramod Kumar Sharma (21 years of experience)


---

## Office Panel (internal tool)

`office.html` — practice management panel for daily office work. Open at
`https://ganesha98285-lgtm.github.io/sai-kripa-group/office.html`

Covers the three points that were finalised:

**1. Client Database & Due Date Tracker**
Add a client once, tick which services you handle, and every statutory due date is generated automatically — ITR (31 Jul / 31 Oct for audit), tax audit report (30 Sep), advance tax (15 Jun/Sep/Dec/Mar), GSTR-1 (11th), GSTR-3B (20th), QRMP PMT-06 (25th) and quarterly returns, CMP-08 (18th), GSTR-9 (31 Dec), TDS payment (7th, 30 Apr for March) and quarterly TDS returns, PF & ESI (15th), ROC AOC-4 / MGT-7 / DPT-3 / DIR-3 KYC, LLP Form 11 & 8, and trademark renewal. One tap sends a ready-written Hinglish WhatsApp reminder.

**5. Case & Notice Tracking**
Income Tax / GST notices with section, DIN, AY, demand amount and reply-due date, moving through **Received → In Progress → Filed → Closed**. Reply due dates also show up in the due-date list so they can't be missed. Status history is logged, and closing a case offers to send a Google review request.

**6. Invoicing + Payment Reminder + Reviews**
Multi-line invoices with optional GST, printable A4 format, WhatsApp invoice delivery with payment link / UPI, payment reminders showing how long a bill has been pending, and an automatic Google review request prompt when a payment is marked received.

### Important notes
- **No server.** Data is stored only in the browser (localStorage) — nothing is uploaded anywhere. Use the **Backup** button regularly to save a JSON file, and **Restore** to move data to another device.
- **WhatsApp is one-tap, not fully automatic.** Messages are pre-written and open in WhatsApp ready to send. Truly hands-off sending needs a server plus the WhatsApp Business API.
- The passcode is a client-side check only — it discourages casual viewing, it is not real security. Client data is never in the page itself.
- Compliance dates follow the standard statutory calendar; always confirm against the latest CBDT/CBIC notifications, since government extensions are common.
