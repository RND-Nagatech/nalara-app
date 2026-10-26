/* Firebase Messaging service worker for NALARA Web Push. */
importScripts(
  'https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js',
  'https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyCIXGBwByUApP3MMMZK8A9DhRLlTxGqiYU',
  authDomain: 'nalara-749db.firebaseapp.com',
  projectId: 'nalara-749db',
  storageBucket: 'nalara-749db.firebasestorage.app',
  messagingSenderId: '1009544957636',
  appId: '1:1009544957636:web:e9c52d4971683e880f4391',
  measurementId: 'G-20JJK23SMW',
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
