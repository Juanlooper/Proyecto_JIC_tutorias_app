importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyClKxWfapiFHqGsKyDqBZIpq3tGC118HMA",
  authDomain: "tutorias-jic.firebaseapp.com",
  projectId: "tutorias-jic",
  storageBucket: "tutorias-jic.firebasestorage.app",
  messagingSenderId: "11231825446",
  appId: "1:11231825446:web:be1b11b5eeddd8cb2fa0e7",
  measurementId: "G-HVTRC1H41Z"
});

const messaging = firebase.messaging();

// Este evento captura las notificaciones push cuando la pestaña de la web está cerrada o en segundo plano.
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Notificación recibida en segundo plano: ', payload);
  
  // Puedes personalizar la notificación web aquí si lo deseas
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
