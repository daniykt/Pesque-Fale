import React from "react";
import { useNavigate } from "react-router-dom";

export default function AcoesPerfil({ onPublicar }) {
  const navigate = useNavigate();

  return (
    <div className="botoes-acao">
      <button className="btn-publicar" onClick={onPublicar}>
        <span className="material-symbols-outlined">add_box</span>
        <span className="btn-text">Nova Publicação</span>
      </button>

      <button className="btn-editar" onClick={() => navigate("/perfil/editar")}>
        <span className="material-symbols-outlined">edit</span>
        <span className="btn-text">Editar Perfil</span>
      </button>
    </div>
  );
}