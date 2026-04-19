import React, { useRef } from "react";
import "./Cabecalhoperfil.css";

export default function CabecalhoPerfil({
  fotoPerfil,
  onFotoChange,
  onBannerChange,
  onPublicar,
  banner,
  usuario,
  bio,
  localizacao,
}) {
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
        style={{ backgroundImage: banner ? `url(${banner})` : undefined }}
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

      {/* LINHA ABAIXO DO BANNER: foto esquerda + botões direita */}
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

        {/* BOTÕES — canto direito, mesma linha da foto */}
        <div className="cabecalho-botoes">
          <button className="btn-cabecalho btn-editar" onClick={() => window.location.href = "/perfil/editar"}>
            <span className="material-symbols-outlined">edit</span>
            Editar Perfil
          </button>
          <button className="btn-cabecalho btn-publicar" onClick={onPublicar}>
            <span className="material-symbols-outlined">add</span>
            Nova Publicação
          </button>
        </div>

      </div>

      {/* INPUTS HIDDEN */}
      <input type="file" accept="image/*" ref={fileInputBannerRef} style={{ display: "none" }} onChange={handleBannerChange} />
      <input type="file" accept="image/*" ref={fileInputFotoRef} style={{ display: "none" }} onChange={handleFotoChange} />

      {/* INFORMAÇÕES DO USUÁRIO */}
      <div className="usuario-data">

        <h2 className="usuario-nome">
          {usuario?.displayName || localStorage.getItem("nome") || "Usuário"}
        </h2>

        {usuario?.email && (
          <div className="usuario-info-linha">
            <span className="material-symbols-outlined usuario-icone">mail</span>
            <span className="usuario-info-texto">{usuario.email}</span>
          </div>
        )}

        {localizacao && (
          <div className="usuario-info-linha">
            <span className="material-symbols-outlined usuario-icone">location_on</span>
            <span className="usuario-info-texto">{localizacao}</span>
          </div>
        )}

        {/* BIO — estilo Instagram, simples */}
        {bio && (
          <p className="usuario-bio">{bio}</p>
        )}

      </div>

    </div>
  );
}