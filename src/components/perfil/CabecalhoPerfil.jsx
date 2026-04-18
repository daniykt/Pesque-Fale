import React, { useRef } from "react";

export default function CabecalhoPerfil({ fotoPerfil, onFotoChange, usuario, bio }) {
  const fileInputRef = useRef(null);

  const handleFotoClick = () => {
    fileInputRef.current.click();
  };

  const handleFotoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    onFotoChange(file);
  };

  return (
    <div className="cabecalho-perfil">
      <img
        src={fotoPerfil}
        alt="Foto de Perfil"
        className="foto-perfil"
        onClick={handleFotoClick}
        title="Clique para trocar a foto"
      />

      <input
        type="file"
        accept="image/*"
        ref={fileInputRef}
        style={{ display: "none" }}
        onChange={handleFotoChange}
      />

      <div className="usuario-data">
        <h2 className="username">
          {usuario?.displayName || usuario?.email || "Usuário"}
        </h2>
        <p className="bio-texto">{bio}</p>
      </div>
    </div>
  );
}