// Service Worker - Mozzafiato Compras
const CACHE = 'mozzafiato-v3';
const STATIC = ['./manifest.json', './icon-192.png', './icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(STATIC))
  );
  self.skipWaiting(); // Toma control inmediatamente sin esperar
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim()) // Toma control de todas las pestañas/instancias abiertas
      .then(() => self.clients.matchAll({ type: 'window', includeUncontrolled: true }))
      .then(clients => {
        // Avisa a todos los clientes que recarguen para obtener la versión fresca
        clients.forEach(client => client.postMessage({ type: 'SW_UPDATED' }));
      })
  );
});

self.addEventListener('fetch', e => {
  const url = e.request.url;

  // Peticiones al Script URL o googleapis siempre a red directa
  if (url.includes('script.google.com') || url.includes('googleapis.com')) {
    return;
  }

  // index.html — network first: siempre intenta la red para captar actualizaciones
  // Si falla (sin conexión), usa el cache como respaldo
  if (url.endsWith('/') || url.includes('index.html') || e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request)
        .then(res => {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
          return res;
        })
        .catch(() => caches.match(e.request))
    );
    return;
  }

  // Recursos estáticos (íconos, manifest) — cache first
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});

// Recibe señal de la página para activarse inmediatamente
self.addEventListener('message', function(e) {
  if (e.data && e.data.type === 'SKIP_WAITING') self.skipWaiting();
});
