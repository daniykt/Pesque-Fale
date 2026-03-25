// src/components/sidebar/sidebar.jsx
import React, { useEffect, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import './sidebar.css';

import logo from '../../assets/image/logo/logo.jpg'; 


export default function Sidebar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(() => {
    const saved = localStorage.getItem('theme');
    return saved === 'dark';
  });
  const location = useLocation();

  // Alternar tema
  useEffect(() => {
    if (isDarkMode) {
      document.body.classList.add('dark-mode');
      localStorage.setItem('theme', 'dark');
    } else {
      document.body.classList.remove('dark-mode');
      localStorage.setItem('theme', 'light');
    }
  }, [isDarkMode]);

  // Fechar menu ao redimensionar para desktop
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth >= 769 && isMenuOpen) {
        setIsMenuOpen(false);
      }
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [isMenuOpen]);

  // Bloquear scroll quando menu aberto
  useEffect(() => {
    if (isMenuOpen) {
      document.body.classList.add('no-scroll');
    } else {
      document.body.classList.remove('no-scroll');
    }
    return () => document.body.classList.remove('no-scroll');
  }, [isMenuOpen]);

  // Marcar link ativo com base na rota atual
  const isActive = (path) => location.pathname === path;

  const toggleMenu = () => setIsMenuOpen(!isMenuOpen);
  const toggleTheme = () => setIsDarkMode(prev => !prev);

  return (
    <>
      <aside className={`sidebar ${isMenuOpen ? 'open' : ''}`}>
        <div className="sidebar-header">
          {/* Logo corrigida: usando a variável importada */}
          <div className="logo">
             <img src={logo} alt="Pesque & Fale"/>
          </div>

          {/* Botão hambúrguer para Mobile */}
          <button
            className="mobile-menu-btn"
            onClick={toggleMenu}
            aria-label="Menu"
          >
            <span className="line1"></span>
            <span className="line2"></span>
            <span className="line3"></span>
          </button>
        </div>

        <nav className="nav-menu">
          <ul className="nav-links">
            <li>
              <Link
                to="/home"
                className={`nav-item ${isActive('/home') ? 'active' : ''}`}
                onClick={() => setIsMenuOpen(false)}
              >
                <span className="material-symbols-outlined">home</span>
                <span className="nav-text">Página Inicial</span>
              </Link>
            </li>

            <li>
              <Link
                to="/pesquisa"
                className={`nav-item ${isActive('/pesquisa') ? 'active' : ''}`}
                onClick={() => setIsMenuOpen(false)}
              >
                <span className="material-symbols-outlined">search</span>
                <span className="nav-text">Pesquisa</span>
              </Link>
            </li>

            <li>
              <Link
                to="/locais"
                className={`nav-item ${isActive('/locais') ? 'active' : ''}`}
                onClick={() => setIsMenuOpen(false)}
              >
                <span className="material-symbols-outlined">location_on</span>
                <span className="nav-text">Melhores Locais</span>
              </Link>
            </li>

            <li>
              <Link
                to="/notificacao"
                className={`nav-item ${isActive('/notificacao') ? 'active' : ''}`}
                onClick={() => setIsMenuOpen(false)}
              >
                <span className="material-symbols-outlined">
                  notifications
                  <span className="badge">3</span>
                </span>
                <span className="nav-text">Notificações</span>
              </Link>
            </li>

            <li>
              <Link
                to="/sobre"
                className={`nav-item ${isActive('/sobre') ? 'active' : ''}`}
                onClick={() => setIsMenuOpen(false)}
              >
                <span className="material-symbols-outlined">school</span>
                <span className="nav-text">Sobre Nós</span>
              </Link>
            </li>

            <li>
              <Link
                to="/perfil"
                className={`nav-item ${isActive('/perfil') ? 'active' : ''}`}
                onClick={() => setIsMenuOpen(false)}
              >
                <span className="material-symbols-outlined">person</span>
                <span className="nav-text">Perfil</span>
              </Link>
            </li>
          </ul>
        </nav>

        <div className="sidebar-footer">
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

      {/* Overlay para fechar menu ao clicar fora */}
      {isMenuOpen && <div className="sidebar-overlay" onClick={toggleMenu}></div>}
    </>
  );
}