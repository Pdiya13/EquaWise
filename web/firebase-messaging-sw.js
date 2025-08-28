importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');
// Initialize in web index with your config and enable messaging from app code.
// self.firebaseConfig = { /* populated by FlutterFire */ };
// firebase.initializeApp(self.firebaseConfig);
// const messaging = firebase.messaging();
self.addEventListener('notificationclick', (event) => { event.notification.close(); });
