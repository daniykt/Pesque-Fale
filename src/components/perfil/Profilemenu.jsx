import React, { useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { getAuth, signOut } from 'firebase/auth';
import './Profilemenu.css';
import Confirmacao from '../confirmacao/confirmacao';

export default function ProfileMenu({
  isOpen,
  onClose,
  isDarkMode,
  onToggleDark,
  mostrarConfirmacao,
  onAbrirLogout,
  onCancelarLogout,
}) {
  const navigate = useNavigate();
  const auth = getAuth();

  // Trava scroll do body quando sheet aberto
  useEffect(() => {
    if (isOpen) document.body.classList.add('no-scroll');
    else document.body.classList.remove('no-scroll');
    return () => document.body.classList.remove('no-scroll');
  }, [isOpen]);

  const handleLogout = async () => {
    try {
      await signOut(auth);
      navigate('/');
    } catch (err) {
      console.error('Erro ao sair:', err);
    }
  };

  const reiniciarTour = () => {
    localStorage.setItem('tourAtivo', 'true');
    localStorage.setItem('tourStartStep', '1');
    localStorage.removeItem('tourConcluido');
    localStorage.removeItem('tourCurrentStep');
    window.dispatchEvent(new Event('storage'));
    onClose();
  };

  return (
    <>
      {/* Overlay escurecido */}
      <div
        className={`pmenu-overlay ${isOpen ? 'pmenu-overlay--visible' : ''}`}
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Bottom Sheet */}
      <div
        className={`pmenu-sheet ${isOpen ? 'pmenu-sheet--open' : ''}`}
        role="dialog"
        aria-modal="true"
        aria-label="Menu de opções"
      >
        {/* Alça */}
        <div className="pmenu-handle" />

        <div className="pmenu-list">

          {/* Modo escuro */}
          <button className="pmenu-item" onClick={onToggleDark}>
            <span className={`pmenu-icon pmenu-icon--${isDarkMode ? 'amber' : 'indigo'}`}>
              <span className="material-symbols-outlined">
                {isDarkMode ? 'light_mode' : 'dark_mode'}
              </span>
            </span>
            <span className="pmenu-item-text">
              {isDarkMode ? 'Modo Claro' : 'Modo Escuro'}
            </span>
            {/* Toggle visual */}
            <span className={`pmenu-toggle ${isDarkMode ? 'pmenu-toggle--on' : ''}`} aria-hidden="true">
              <span className="pmenu-toggle-thumb" />
            </span>
          </button>

          <div className="pmenu-divider" />

          {/* Sobre nós */}
          <Link to="/sobre" className="pmenu-item" onClick={onClose}>
            <span className="pmenu-icon pmenu-icon--blue">
              <span className="material-symbols-outlined">info</span>
            </span>
            <span className="pmenu-item-text">Sobre Nós</span>
            <span className="material-symbols-outlined pmenu-chevron">chevron_right</span>
          </Link>

          <div className="pmenu-divider" />

          <div className="pmenu-divider" />

{/* Reiniciar Tour */}
<button className="pmenu-item" onClick={reiniciarTour}>
  <span className="pmenu-icon pmenu-icon--green">
    <span className="material-symbols-outlined">restart_alt</span>
  </span>
  <span className="pmenu-item-text">Reiniciar Tour</span>
  <span className="material-symbols-outlined pmenu-chevron">chevron_right</span>
</button>

<div className="pmenu-divider" />

{/* Sair — já existia */}

          {/* Sair */}
          <button
            className="pmenu-item pmenu-item--danger"
            onClick={() => { onClose(); onAbrirLogout(); }}
          >
            <span className="pmenu-icon pmenu-icon--red">
              <span className="material-symbols-outlined">logout</span>
            </span>
            <span className="pmenu-item-text">Sair da conta</span>
            <span className="material-symbols-outlined pmenu-chevron">chevron_right</span>
          </button>

        </div>

        {/* Botão cancelar */}
        <button className="pmenu-cancel" onClick={onClose}>
          Cancelar
        </button>
      </div>

      <Confirmacao
        aberto={mostrarConfirmacao}
        onConfirmar={handleLogout}
        onCancelar={onCancelarLogout}
      />
    </>
  );
}