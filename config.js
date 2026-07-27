/* =====================================================================
   SAI KRIPA GROUP — connection settings

   YAHAN DO CHEEZEIN BHARNI HAIN:

   1) SUPABASE_ANON_KEY  ->  Supabase ki "anon" / "publishable" key
        Supabase  ->  Settings (gear icon)  ->  API Keys  ->  "anon" copy karein
        ZARURI: "service_role" / "secret" wali key YAHAN KABHI MAT DAALEIN.
        anon key public hai — ye safe hai, kyunki database ke rules (RLS)
        login kiye bina kuch dekhne nahi dete.

   2) CONTACT.whatsapp  ->  naya WhatsApp number
        Format: 91 ke saath, bina space aur bina + ka. Jaise 919887705993
        Ye number poori website + office panel + upload page, sab jagah
        apne aap badal jayega. Kisi dusri file me haath lagane ki zarurat
        nahi hai.
   ===================================================================== */

window.SKG = {
  SUPABASE_URL: 'https://cccqqjgcloltahaswgky.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_p0yOg-mOUxhyOZUa1nlidg_m7CA2ci7',

  CONTACT: {
    /* Jis number par WhatsApp jayega (91 + 10 digit, bina + aur space) */
    whatsapp: '919887705993',

    /* "Call now" wala number. Khali chhodein to whatsapp wala hi chalega. */
    call: '',

    /* Contact section me dikhne wale saare number. Pehla number hi
       WhatsApp/Call ke liye use hoga agar upar khali chhoda ho. */
    numbers: ['919887705993', '919214862726', '919261626392'],

    email: 'Kripasai2017@gmail.com',
    owner: 'Pramod Kumar Sharma',
    firm: 'Sai Kripa Group'
  },

  /* Customer ko kitne time me jawab milega — form submit hone par yahi
     message dikhta hai. Jo aap sach me nibha sakein wahi likhein. */
  RESPONSE_TIME: '24 working hours'
};

/* ---------------------------------------------------------------------
   Helpers — poori site inhe use karti hai, isse number ek hi jagah se
   control hota hai. Ise chhedne ki zarurat nahi.
   --------------------------------------------------------------------- */
(function () {
  var C = window.SKG.CONTACT;

  /* sirf digits, 91 ke saath */
  function digits(n) {
    var d = String(n || '').replace(/\D/g, '');
    if (d.length === 10) d = '91' + d;
    return d;
  }

  var primary = digits(C.whatsapp || (C.numbers && C.numbers[0]));

  window.SKG.WA_NUMBER = primary;
  window.SKG.CALL_NUMBER = digits(C.call) || primary;

  /* 919887705993 -> "98877 05993" (screen par dikhane ke liye) */
  window.SKG.pretty = function (n) {
    var d = digits(n).replace(/^91/, '');
    return d.length === 10 ? d.slice(0, 5) + ' ' + d.slice(5) : String(n || '');
  };

  window.SKG.waLink = function (text) {
    return 'https://wa.me/' + primary +
      (text ? '?text=' + encodeURIComponent(text) : '');
  };
})();
