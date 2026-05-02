import React, { useEffect, useState } from 'react';
import Sidebar from '../sidebar/sidebar';
import BottomNav from '../bottomNav/BottomNav';
import './layout.css';

export default function Layout({ children }) {
  const [notifCount, setNotifCount] = useState(0);

  useEffect(() => {
    const stored = localStorage.getItem('notificacoes');
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        setNotifCount(parsed.filter(n => !n.lida).length);
      } catch {}
    }
  }, []);

  useEffect(() => {
    const handleNotifUpdate = (e) => setNotifCount(e.detail);
    window.addEventListener('notificacoesAtualizadas', handleNotifUpdate);
    return () => window.removeEventListener('notificacoesAtualizadas', handleNotifUpdate);
  }, []);

  return (
    <>
      <Sidebar />
      <div className="main-layout-content">
        {children}
      </div>
      <BottomNav notifCount={notifCount} />
    </>
  );
}