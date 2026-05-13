import React, { useEffect, useState } from 'react';
import Sidebar from '../sidebar/sidebar';
import BottomNav from '../bottomNav/BottomNav';
import OnboardingTour from '../OnboardingTour/OnboardingTour';
import NotifToast from '../../components/NotifToast/NotifToast';
import { useNotifCount } from '../../hooks/useNotifCount';
import './layout.css';

export default function Layout({ children }) {
  const notifCount = useNotifCount();

  const [showTour, setShowTour] = useState(() => {
    const tourAtivo     = localStorage.getItem('tourAtivo');
    const tourConcluido = localStorage.getItem('tourConcluido');
    return tourAtivo === 'true' && tourConcluido !== 'true';
  });

  useEffect(() => {
    const checkTourStatus = () => {
      const tourAtivo     = localStorage.getItem('tourAtivo');
      const tourConcluido = localStorage.getItem('tourConcluido');
      setShowTour(tourAtivo === 'true' && tourConcluido !== 'true');
    };

    checkTourStatus();
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

      {/* Toast global — suprime automaticamente na tela /notificacao */}
      <NotifToast />

      {showTour && <OnboardingTour onFinalizar={finalizarTour} />}
    </>
  );
}