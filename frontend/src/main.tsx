import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';
// @ts-expect-error CSS is handled by the bundler.
import './styles/style.css';

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {
      // ignore service worker registration errors in dev
    });
  });
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
