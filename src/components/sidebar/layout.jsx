import React, { useEffect, useState } from 'react';
import Sidebar from '../sidebar/sidebar';
import BottomNav from '../bottomNav/BottomNav';
import OnboardingTour from '../OnboardingTour/OnboardingTour';
import './layout.css';

export default function Layout({ children }) {
  const [notifCount, setNotifCount] = useState(0);
  // Inicializa showTour diretamente do localStorage para evitar flicker
  const [showTour, setShowTour] = useState(() => {
    const tourAtivo = localStorage.getItem('tourAtivo');
    const tourConcluido = localStorage.getItem('tourConcluido');
    return tourAtivo === 'true' && tourConcluido !== 'true';
  });

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

  // Monitora o estado do tour através do localStorage
  useEffect(() => {
    const checkTourStatus = () => {
      const tourAtivo = localStorage.getItem('tourAtivo');
      const tourConcluido = localStorage.getItem('tourConcluido');
      
      if (tourAtivo === 'true' && tourConcluido !== 'true') {
        setShowTour(true);
      } else {
        setShowTour(false);
      }
    };

    checkTourStatus();
    
    // Monitora mudanças no localStorage
    window.addEventListener('storage', checkTourStatus);
    
    return () => window.removeEventListener('storage', checkTourStatus);
  }, []);

  const finalizarTour = () => {
    localStorage.setItem('tourConcluido', 'true');
    localStorage.removeItem('tourAtivo');
    localStorage.removeItem('tourCurrentStep');
    setShowTour(false);
  };

  return (
    <>
      <Sidebar />
      <div className="main-layout-content">
        {children}
      </div>
      <BottomNav notifCount={notifCount} />

      {/* Tour global que persiste através de navegações */}
      {showTour && <OnboardingTour onFinalizar={finalizarTour} />}
    </>
  );
}