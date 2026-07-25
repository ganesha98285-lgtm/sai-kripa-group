/* =====================================================================
   Sai Kripa Group — service worker (PWA)

   Kaam:
     - phone/laptop pe app ki tarah install ho sake
     - icon, manifest jaise files turant khulein (cache se)
     - page ka HTML pehle internet se, na mile to cache se (offline)

   Jaan-boojh kar cache NAHI karte:
     - /api/*        -> chat bot ka jawab hamesha taaza
     - Supabase      -> client ka data kabhi stale nahi dikhna chahiye
     - config.js     -> key badle to turant lagni chahiye
   ===================================================================== */

const VERSION = 'skg-v1';
const SHELL   = 'shell-' + VERSION;

/* offline me bhi khulne wali cheezein */
const PRECACHE = [
  '/',
  '/index.html',
  '/office.html',
  '/upload.html',
  '/manifest.webmanifest',
  '/office.webmanifest',
  '/icons/favicon.svg',
  '/icons/favicon-32.png',
  '/icons/icon-192.png',
  '/icons/icon-512.png',
  '/icons/apple-touch-icon.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(SHELL)
      /* ek file na mile to poora install fail na ho */
      .then(cache => Promise.allSettled(PRECACHE.map(u => cache.add(u))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== SHELL).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

function isAsset(pathname) {
  return pathname.startsWith('/icons/') ||
         pathname.endsWith('.webmanifest') ||
         pathname.endsWith('.svg') ||
         pathname.endsWith('.png');
}

self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  /* dusri site (Supabase, fonts, CDN) -> seedha network, hum beech me nahi aate */
  if (url.origin !== self.location.origin) return;

  /* chat bot aur config -> hamesha taaza */
  if (url.pathname.startsWith('/api/') || url.pathname === '/config.js') return;

  /* icon/manifest -> cache se turant, saath me chupke se update */
  if (isAsset(url.pathname)) {
    event.respondWith(
      caches.match(req).then(hit => {
        const net = fetch(req).then(res => {
          if (res && res.ok) caches.open(SHELL).then(c => c.put(req, res.clone()));
          return res;
        }).catch(() => hit);
        return hit || net;
      })
    );
    return;
  }

  /* page -> pehle network, net na ho to cache (offline me khul jaye) */
  event.respondWith(
    fetch(req).then(res => {
      if (res && res.ok && res.type === 'basic') {
        const copy = res.clone();
        caches.open(SHELL).then(c => c.put(req, copy));
      }
      return res;
    }).catch(() =>
      caches.match(req).then(hit => hit || caches.match('/index.html'))
    )
  );
});
