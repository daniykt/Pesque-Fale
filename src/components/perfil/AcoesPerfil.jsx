import React from "react";
import { useNavigate } from "react-router-dom";
import "./Acoesperfil.css";

export default function AcoesPerfil({ onPublicar }) {
  const navigate = useNavigate();

  return (
    <div className="acoes-perfil">
      <button className="btn-acao btn-publicar" onClick={onPublicar}>
        <span className="material-symbols-outlined">add_box</span>
        <span>Nova Publicação</span>
      </button>

      <button className="btn-acao btn-editar" onClick={() => navigate("/perfil/editar")}>
        <span className="material-symbols-outlined">edit</span>
        <span>Editar Perfil</span>
      </button>
    </div>
  );
}