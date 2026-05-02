// src/components/sidebar/sidebar.jsx
import React, { useEffect, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import './sidebar.css';
import { getAuth, signOut } from 'firebase/auth';
import logo from '../../assets/image/logo/logo.jpg';
import Confirmacao from '../confirmacao/confirmacao';

export default function Sidebar() {
  const [isDarkMode, setIsDarkMode] = useState(() => {
    return localStorage.getItem('theme') === 'dark';
  });
  const [notifCount, setNotifCount] = useState(0);
  const [mostrarConfirmacao, setMostrarConfirmacao] = useState(false);

  const location = useLocation();
  const navigate = useNavigate();
  const auth = getAuth();

  const handleLogout = async () => {
    try {
      await signOut(auth);
      navigate('/');
    } catch (error) {
      console.error('Erro ao sair:', error);
    }
  };

  useEffect(() => {
    const stored = localStorage.getItem('notificacoes');
    if (!stored) {
      const notificacoesIniciais = Array.from({ length: 6 }, (_, i) => ({
        id: i + 1,
        data: '05/05/2025 10:35',
        usuario: 'Reginaldosilva',
        texto: `Lugarzinho da hora pra pescar! (Notif ${i + 1})`,
        lida: false,
        curtida: null,
        favorito: false,
      }));
      localStorage.setItem('notificacoes', JSON.stringify(notificacoesIniciais));
      setNotifCount(6);
    } else {
      const parsed = JSON.parse(stored);
      setNotifCount(parsed.filter(n => !n.lida).length);
    }
  }, []);

  const syncNotifCount = () => {
    const stored = localStorage.getItem('notificacoes');
    if (stored) {
      const parsed = JSON.parse(stored);
      setNotifCount(parsed.filter(n => !n.lida).length);
    }
  };

  useEffect(() => {
    const handleNotifUpdate = (e) => setNotifCount(e.detail);
    window.addEventListener('notificacoesAtualizadas', handleNotifUpdate);
    return () => window.removeEventListener('notificacoesAtualizadas', handleNotifUpdate);
  }, []);

  useEffect(() => {
    window.addEventListener('focus', syncNotifCount);
    return () => window.removeEventListener('focus', syncNotifCount);
  }, []);

  useEffect(() => { syncNotifCount(); }, [location]);

  useEffect(() => {
    if (isDarkMode) {
      document.body.classList.add('dark-mode');
      localStorage.setItem('theme', 'dark');
    } else {
      document.body.classList.remove('dark-mode');
      localStorage.setItem('theme', 'light');
    }
  }, [isDarkMode]);

  const isActive = (path) => location.pathname.startsWith(path);
  const toggleTheme = () => setIsDarkMode(prev => !prev);

  return (
    <>
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="logo">
            <img src={logo} alt="Pesque & Fale" />
          </div>
        </div>

        <nav className="nav-menu">
          <ul className="nav-links">
            <li>
              <Link to="/home" className={`nav-item ${isActive('/home') ? 'active' : ''}`}>
                <span className="material-symbols-outlined">home</span>
                <span className="nav-text">Página Inicial</span>
              </Link>
            </li>
            <li>
              <Link to="/pesquisar" className={`nav-item ${isActive('/pesquisar') ? 'active' : ''}`}>
                <span className="material-symbols-outlined">search</span>
                <span className="nav-text">Pesquisa</span>
              </Link>
            </li>
            <li>
              <Link to="/chat" className={`nav-item ${isActive('/chat') ? 'active' : ''}`}>
                <span className="material-symbols-outlined">chat</span>
                <span className="nav-text">Chat</span>
              </Link>
            </li>
            <li>
              <Link to="/notificacao" className={`nav-item ${isActive('/notificacao') ? 'active' : ''}`}>
                <span className="material-symbols-outlined" style={{ position: 'relative' }}>
                  notifications
                  {notifCount > 0 && <span className="badge">{notifCount}</span>}
                </span>
                <span className="nav-text">Notificações</span>
              </Link>
            </li>
            <li>
              <Link to="/sobre" className={`nav-item ${isActive('/sobre') ? 'active' : ''}`}>
                <span className="material-symbols-outlined">school</span>
                <span className="nav-text">Sobre Nós</span>
              </Link>
            </li>
            <li>
              <Link to="/perfil" className={`nav-item ${isActive('/perfil') ? 'active' : ''}`}>
                <span className="material-symbols-outlined">person</span>
                <span className="nav-text">Perfil</span>
              </Link>
            </li>
          </ul>
        </nav>

        <div className="sidebar-footer">
          <button
            className="nav-item logout-btn"
            onClick={() => setMostrarConfirmacao(true)}
          >
            <span className="material-symbols-outlined">logout</span>
            <span className="nav-text">Sair</span>
          </button>

          <button className="theme-btn" onClick={toggleTheme}>
            <span className="material-symbols-outlined">
              {isDarkMode ? 'light_mode' : 'dark_mode'}
            </span>
            <span className="nav-text">
              {isDarkMode ? 'Modo Claro' : 'Modo Escuro'}
            </span>
          </button>
        </div>
      </aside>

      <Confirmacao
        aberto={mostrarConfirmacao}
        onConfirmar={handleLogout}
        onCancelar={() => setMostrarConfirmacao(false)}
      />
    </>
  );
}