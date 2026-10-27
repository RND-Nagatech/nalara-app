/* Firebase Messaging service worker for NALARA Web Push. */
importScripts(
  'https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js',
  'https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyAYTIAmif-ipHfGguuNCnENsixW3lVd6YE',
  authDomain: 'nalara-gia.firebaseapp.com',
  projectId: 'nalara-gia',
  storageBucket: 'nalara-gia.firebasestorage.app',
  messagingSenderId: '177575580722',
  appId: '1:177575580722:web:eeb34b5b74ed48f16cd82b',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const data = payload.data || {};

  self.registration.showNotification(notification.title || 'NALARA', {
    body: notification.body || 'Ada informasi baru di NALARA.',
    icon: '/icons/Icon-192.png?v=nalara-1',
    badge: '/icons/Icon-192.png?v=nalara-1',
    data: {
      notificationId: data.notificationId || '',
      route: data.route || '/',
    },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const route = event.notification?.data?.route || '/';
  const targetUrl = `${self.location.origin}/#${route}`;

  event.waitUntil(
    self.clients
      .matchAll({type: 'window', includeUncontrolled: true})
      .then((clientList) => {
        const existing = clientList.find((client) => 'focus' in client);
        if (existing) {
          existing.navigate(targetUrl);
          return existing.focus();
        }
        return self.clients.openWindow(targetUrl);
      }),
  );
});
