// 信徒管理 Service Worker — 外殼離線快取（同源 network-first）。改版時把 CACHE +1，手機才會拿到新版。
const CACHE = 'members-v26';
const SHELL = ['./', './index.html', './sync.js', './store.js', './manifest.webmanifest', './icon-192.png', './icon-512.png'];
self.addEventListener('install', e => e.waitUntil(caches.open(CACHE).then(c => Promise.allSettled(SHELL.map(u => c.add(u)))).then(() => self.skipWaiting())));
self.addEventListener('activate', e => e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())));
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;   // GitHub API / CDN 一律不快取
  e.respondWith(fetch(req).then(res => { if (res.ok) { const c = res.clone(); caches.open(CACHE).then(x => x.put(req, c)); } return res; })
    .catch(() => caches.match(req).then(r => r || caches.match('./index.html'))));
});
