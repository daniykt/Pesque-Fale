// src/components/confirmacao/Confirmacao.jsx
import React, { useEffect } from 'react';
import './confirmacao.css';

export default function Confirmacao({ aberto, onConfirmar, onCancelar }) {
  // Fecha com a tecla ESC
  useEffect(() => {
    const fecharComEsc = (e) => {
      if (e.key === 'Escape') onCancelar();
    };
    if (aberto) {
      document.addEventListener('keydown', fecharComEsc);
    }
    return () => document.removeEventListener('keydown', fecharComEsc);
  }, [aberto, onCancelar]);

  if (!aberto) return null;

  return (
    <div className="confirmacao-overlay" onClick={onCancelar}>
      <div
        className="confirmacao-card"
        onClick={(e) => e.stopPropagation()} // Impede fechar ao clicar no card
      >
        {/* Ícone de alerta */}
        <div className="confirmacao-icone">
          <span className="material-symbols-outlined">logout</span>
        </div>

        {/* Título e texto */}
        <div className="confirmacao-conteudo">
          <h3 className="confirmacao-titulo">Certeza que quer sair?</h3>
          <p className="confirmacao-texto">
            Você será desconectado da sua conta.
          </p>
        </div>

        {/* Botões */}
        <div className="confirmacao-acoes">
          <button className="confirmacao-btn-nao" onClick={onCancelar}>
            <span className="material-symbols-outlined">close</span>
            Não, ficar
          </button>
          <button className="confirmacao-btn-sim" onClick={onConfirmar}>
            <span className="material-symbols-outlined">logout</span>
            Sim, sair
          </button>
        </div>
      </div>
    </div>
  );
}