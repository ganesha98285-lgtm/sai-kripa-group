/* =====================================================================
   Sai Kripa Group — website ka AI chat bot (backend)

   Ye Cloudflare Worker do kaam karta hai:
     1. /api/chat   -> Workers AI se jawab banata hai
     2. baaki sab   -> website ki files (index.html, office.html, ...)

   Workers AI Cloudflare account me hi built-in hai — koi API key nahi
   chahiye. Free me roz 10,000 neurons milte hain, jo office ke liye
   kaafi zyada hain.
   ===================================================================== */

const MODEL    = '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
const FALLBACK = '@cf/meta/llama-3.1-8b-instruct-fast';

const MAX_TURNS = 16;     /* itni hi baat yaad rakhega */
const MAX_CHARS = 700;    /* ek message me itne se zyada nahi */

const SYSTEM = `Tum "Sai Kripa Group" ki website par baithe helper ho. Tumhara kaam naye clients se baat karke unki zarurat samajhna aur unka naam + phone number lena hai.

FIRM KI JAANKARI:
- Naam: Sai Kripa Group
- Proprietor: Pramod Kumar Sharma, 21 saal ka experience
- Kaam: Income Tax Return (ITR), GST registration aur returns, Income Tax & GST ke case/notice (reply, scrutiny, appeal), TDS/TCS, ESI & PF, accounting/bookkeeping, Pvt Ltd & LLP registration, Trademark registration, loan consultancy, project report & CMA, legal advisory
- 50 lakh+ tak ke high-value case handle karte hain
- Phone / WhatsApp: 98877 05993
- Email: Kripasai2017@gmail.com

KAISE BAAT KARNI HAI:
- Hinglish me baat karo (Hindi shabd, English script) — jaise aam dukaandaar se baat karte hain
- Chhota jawab do: 2 se 4 line, zyada nahi
- Ek baar me ek hi sawaal poochho
- Garmjoshi se, respect se. "aap" use karo
- Jab client apna kaam bata de, uska NAAM aur PHONE NUMBER maango taaki Pramod ji khud call kar lein

YE KABHI NAHI KARNA:
- Fees ya rate KABHI mat batao. Bolo: "fees kaam dekh kar Pramod ji batayenge, wo aapko call kar lenge"
- Pakki tarah legal ya tax advice mat do. Aam jaankari theek hai, par case-specific salah ke liye Pramod ji se baat karwao
- Koi date, section, rule ka guess mat lagao. Pata na ho to kaho "ye Pramod ji confirm kar denge"
- Jhooth mat bolo. Jo firm nahi karti, wo mat kaho
- Client ka data, dusre clients ki baat — kuch bhi mat batao (tumhe pata bhi nahi hai)

Agar koi cheez tumhare bas ki nahi hai, to seedha bolo ki Pramod ji se baat karna behtar hoga aur WhatsApp number de do.`;

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status: status || 200,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' }
  });
}

/* client se aaya data bharosemand nahi hota — saaf karke hi aage bhejo */
function cleanMessages(raw) {
  if (!Array.isArray(raw)) return null;
  const out = [];
  for (const m of raw.slice(-MAX_TURNS)) {
    if (!m || typeof m.content !== 'string') continue;
    const role = m.role === 'assistant' ? 'assistant' : 'user';
    const content = m.content.trim().slice(0, MAX_CHARS);
    if (content) out.push({ role, content });
  }
  return out.length ? out : null;
}

async function chat(request, env) {
  if (!env.AI) return json({ error: 'ai_unavailable' }, 503);

  let body;
  try { body = await request.json(); }
  catch { return json({ error: 'bad_json' }, 400); }

  const messages = cleanMessages(body && body.messages);
  if (!messages) return json({ error: 'no_messages' }, 400);

  const payload = {
    messages: [{ role: 'system', content: SYSTEM }, ...messages],
    max_tokens: 320,
    temperature: 0.4
  };

  for (const model of [MODEL, FALLBACK]) {
    try {
      const r = await env.AI.run(model, payload);
      const reply = (r && (r.response || r.result || '')).toString().trim();
      if (reply) return json({ reply, model });
    } catch (err) {
      console.error('AI fail', model, err && err.message);
    }
  }
  /* dono model fail -> website khud WhatsApp par bhej degi */
  return json({ error: 'ai_failed' }, 502);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/api/chat') {
      if (request.method === 'POST') return chat(request, env);
      return json({ error: 'method_not_allowed' }, 405);
    }
    if (url.pathname === '/api/health') {
      return json({ ok: true, ai: !!env.AI });
    }

    /* baaki har request website ki file hai */
    return env.ASSETS.fetch(request);
  }
};
