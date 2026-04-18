import React, { useRef } from "react";
import "./Cabecalhoperfil.css";

export default function CabecalhoPerfil({ fotoPerfil, onFotoChange, onBannerChange, banner, usuario, bio }) {
  const fileInputFotoRef = useRef(null);
  const fileInputBannerRef = useRef(null);

  const handleFotoClick = () => fileInputFotoRef.current.click();
  const handleBannerClick = () => fileInputBannerRef.current.click();

  const handleFotoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    onFotoChange(file);
  };

  const handleBannerChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    onBannerChange(file);
  };

  return (
    <div className="cabecalho-perfil">

      {/* BANNER */}
      <div
        className="banner-perfil"
        onClick={handleBannerClick}
        title="Clique para trocar a capa"
        style={{
          backgroundImage: banner ? `url(${banner})` : undefined,
        }}
      >
        {!banner && (
          <span className="banner-icone material-symbols-outlined">
            add_photo_alternate
          </span>
        )}
        <div className="banner-overlay">
          <span className="material-symbols-outlined">photo_camera</span>
          <p>Trocar capa</p>
        </div>
      </div>

      {/* LINHA ABAIXO DO BANNER: foto à esquerda */}
      <div className="cabecalho-inferior">

        {/* FOTO DE PERFIL */}
        <div className="foto-perfil-wrapper">
          <img
            src={fotoPerfil}
            alt="Foto de Perfil"
            className="foto-perfil"
            onClick={handleFotoClick}
            title="Clique para trocar a foto"
          />
          <div className="foto-perfil-overlay" onClick={handleFotoClick}>
            <span className="material-symbols-outlined">photo_camera</span>
          </div>
        </div>

      </div>

      {/* INPUT BANNER */}
      <input
        type="file"
        accept="image/*"
        ref={fileInputBannerRef}
        style={{ display: "none" }}
        onChange={handleBannerChange}
      />

      {/* INPUT FOTO */}
      <input
        type="file"
        accept="image/*"
        ref={fileInputFotoRef}
        style={{ display: "none" }}
        onChange={handleFotoChange}
      />

      {/* DADOS DO USUÁRIO */}
      <div className="usuario-data">
        <h2 className="username">
          {usuario?.displayName || usuario?.email || "Usuário"}
        </h2>
        <p className="bio-texto">{bio}</p>
      </div>

    </div>
  );
}