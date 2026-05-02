// src/components/bottomnav/BottomNav.jsx
import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import './BottomNav.css';

export default function BottomNav({ notifCount = 0 }) {
  const location = useLocation();
  const [ripple, setRipple] = useState(null);

  const isActive = (path) => location.pathname.startsWith(path);

  const handleTap = (path) => {
    setRipple(path);
    setTimeout(() => setRipple(null), 400);
  };

  const navItems = [
    {
      path: '/home',
      icon: (active) => (
        <svg viewBox="0 0 24 24" fill={active ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth={active ? 0 : 2}>
          <path d="M3 12L12 3l9 9" strokeLinecap="round" strokeLinejoin="round" />
          <path d="M5 10v9a1 1 0 001 1h4v-5h4v5h4a1 1 0 001-1v-9" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      ),
      label: 'Início',
    },
    {
      path: '/pesquisar',
      icon: (active) => (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={active ? 2.5 : 2}>
          <circle cx="11" cy="11" r="7" />
          <path d="M21 21l-4.35-4.35" strokeLinecap="round" />
        </svg>
      ),
      label: 'Buscar',
    },
    {
      path: '/chat',
      icon: (active) => (
        <svg viewBox="0 0 24 24" fill={active ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth={active ? 0 : 2}>
          {active ? (
            <path d="M20 2H4a2 2 0 00-2 2v18l4-4h14a2 2 0 002-2V4a2 2 0 00-2-2z" />
          ) : (
            <path d="M20 2H4a2 2 0 00-2 2v18l4-4h14a2 2 0 002-2V4a2 2 0 00-2-2z" strokeLinecap="round" strokeLinejoin="round" />
          )}
        </svg>
      ),
      label: 'Chat',
    },
    {
      path: '/notificacao',
      icon: (active) => (
        <svg viewBox="0 0 24 24" fill={active ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth={active ? 0 : 2}>
          {active ? (
            <path d="M18 8a6 6 0 00-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0" />
          ) : (
            <path d="M18 8a6 6 0 00-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0" strokeLinecap="round" strokeLinejoin="round" />
          )}
        </svg>
      ),
      label: 'Notif.',
      badge: notifCount,
    },
    {
      path: '/perfil',
      icon: (active) => (
        <svg viewBox="0 0 24 24" fill={active ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth={active ? 0 : 2}>
          {active ? (
            <>
              <circle cx="12" cy="8" r="4" />
              <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
            </>
          ) : (
            <>
              <circle cx="12" cy="8" r="4" strokeLinecap="round" />
              <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" strokeLinecap="round" />
            </>
          )}
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
            className={`bottom-nav__item ${active ? 'bottom-nav__item--active' : ''} ${ripple === item.path ? 'bottom-nav__item--ripple' : ''}`}
            onClick={() => handleTap(item.path)}
            aria-label={item.label}
          >
            <span className="bottom-nav__icon-wrap">
              {item.badge > 0 && (
                <span className="bottom-nav__badge">{item.badge > 9 ? '9+' : item.badge}</span>
              )}
              <span className="bottom-nav__icon">
                {item.icon(active)}
              </span>
              {active && <span className="bottom-nav__dot" />}
            </span>
            <span className="bottom-nav__label">{item.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}