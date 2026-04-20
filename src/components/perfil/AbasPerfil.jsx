import React from "react";
import "./Abasperfil.css";

const ABAS = ["Galeria", "Equipamentos", "Locais Salvos"];

export default function AbasPerfil({ abaSelecionada, onTrocarAba }) {
  return (
    <div className="abas-perfil">
      {ABAS.map((aba) => (
        <button
          key={aba}
          className={`aba-btn ${abaSelecionada === aba ? "aba-ativa" : ""}`}
          onClick={() => onTrocarAba(aba)}
        >
          {aba}
        </button>
      ))}
    </div>
  );
}