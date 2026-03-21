import React from 'react';
import Sidebar from '../sidebar/sidebar';
import './layout.css'; // Mude de 'Layout.css' para 'layout.css' (minúsculo)

export default function Layout({ children }) {
  return (
    <>
      <Sidebar />
      <div className="main-layout-content">
        {children}
      </div>
    </>
  );
}