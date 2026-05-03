import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import './BottomNav.css';

export default function BottomNav({ notifCount = 0 }) {
  const location = useLocation();
  const isActive = (path) => location.pathname.startsWith(path);

  const navItems = [
    {
      path: '/home',
      icon: () => (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 12L12 3l9 9" />
          <path d="M5 10v9a1 1 0 001 1h4v-5h4v5h4a1 1 0 001-1v-9" />
        </svg>
      ),
      label: 'Início',
    },
    {
      path: '/pesquisar',
      icon: () => (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
          <circle cx="11" cy="11" r="7" />
          <path d="M21 21l-4.35-4.35" />
        </svg>
      ),
      label: 'Pesquisa',
    },
    {
      path: '/chat',
      icon: () => (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
          <path d="M20 2H4a2 2 0 00-2 2v18l4-4h14a2 2 0 002-2V4a2 2 0 00-2-2z" />
        </svg>
      ),
      label: 'Chat',
    },
    {
      path: '/notificacao',
      icon: () => (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
          <path d="M18 8a6 6 0 00-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
          <path d="M13.73 21a2 2 0 01-3.46 0" />
        </svg>
      ),
      label: 'Alertas',
      badge: notifCount,
    },
    {
      path: '/perfil',
      icon: () => (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
          <circle cx="12" cy="8" r="4" />
          <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
        </svg>
      ),
      label: 'Perfil',
    },
  ];

  return (
    <nav className="bottom-nav" role="navigation" aria-label="Navegação principal">
      {navItems.map((item) => {
        const active = isActive(item.path);
        return (
          <Link
            key={item.path}
            to={item.path}
            className={`bottom-nav__item ${active ? 'bottom-nav__item--active' : ''}`}
            aria-label={item.label}
          >
            <span className="bottom-nav__icon-wrap">
              {item.badge > 0 && (
                <span className="bottom-nav__badge">{item.badge > 9 ? '9+' : item.badge}</span>
              )}
              <span className="bottom-nav__icon">
                {item.icon()}
              </span>
            </span>
            <span className="bottom-nav__label">{item.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}