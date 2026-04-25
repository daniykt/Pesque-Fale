import React, { useRef } from "react";
import { useNavigate } from "react-router-dom";
import "./Cabecalhoperfil.css";

export default function CabecalhoPerfil({
  fotoPerfil,
  onFotoChange,
  onBannerChange,
  banner,
  usuario,
  bio,
  localizacao,
  isOwnProfile,

  // 🔥 NOVAS PROPS
  isFollowing,
  onSeguir,
  onDeixarDeSeguir,
  onMensagem,
}) {
  const navigate = useNavigate();
  const fileInputFotoRef = useRef(null);
  const fileInputBannerRef = useRef(null);

  const handleFotoClick = () => {
    if (!isOwnProfile) return;
    fileInputFotoRef.current?.click();
  };

  const handleBannerClick = () => {
    if (!isOwnProfile) return;
    fileInputBannerRef.current?.click();
  };

  const handleFotoChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (typeof onFotoChange === "function") {
      onFotoChange(file);
    }
  };

  const handleBannerChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (typeof onBannerChange === "function") {
      onBannerChange(file);
    }
  };

  return (
    <div className="cabecalho-perfil">

      {/* BANNER */}
      <div
        className="banner-perfil"
        onClick={handleBannerClick}
        title={isOwnProfile ? "Clique para trocar a capa" : ""}
        style={{ backgroundImage: banner ? `url(${banner})` : undefined }}
      >
        {!banner && isOwnProfile && (
          <span className="banner-icone material-symbols-outlined">
            add_photo_alternate
          </span>
        )}

        {isOwnProfile && (
          <div className="banner-overlay">
            <span className="material-symbols-outlined">photo_camera</span>
            <p>Trocar capa</p>
          </div>
        )}
      </div>

      <div className="cabecalho-inferior">

        {/* FOTO */}
        <div className="foto-perfil-wrapper">
          <img
            src={fotoPerfil}
            alt="Foto de Perfil"
            className="foto-perfil"
            onClick={handleFotoClick}
            title={isOwnProfile ? "Clique para trocar a foto" : ""}
          />

          {isOwnProfile && (
            <div className="foto-perfil-overlay" onClick={handleFotoClick}>
              <span className="material-symbols-outlined">photo_camera</span>
            </div>
          )}
        </div>

        {/* BOTÕES DESKTOP */}
        <div className="cabecalho-botoes">
          {isOwnProfile ? (
            <>
              <button
                className="btn-cabecalho btn-editar"
                onClick={() => navigate("/perfil/editar")}
              >
                <span className="material-symbols-outlined">edit</span>
                <span className="btn-texto">Editar Perfil</span>
              </button>

              <button
                className="btn-cabecalho btn-publicar"
                onClick={() => navigate("/publicar")}
              >
                <span className="material-symbols-outlined">add</span>
                <span className="btn-texto">Nova Publicação</span>
              </button>
            </>
          ) : (
            <>
              {!isFollowing ? (
                <button
                  className="btn-cabecalho btn-seguir"
                  onClick={onSeguir}
                >
                  Seguir
                </button>
              ) : (
                <>
                  <button
                    className="btn-cabecalho"
                    onClick={onDeixarDeSeguir}
                  >
                    Deixar de seguir
                  </button>

                  <button
                    className="btn-cabecalho"
                    onClick={onMensagem}
                  >
                    Mensagem
                  </button>
                </>
              )}
            </>
          )}
        </div>
      </div>

      {/* INPUTS */}
      {isOwnProfile && (
        <>
          <input
            type="file"
            accept="image/*"
            ref={fileInputBannerRef}
            style={{ display: "none" }}
            onChange={handleBannerChange}
          />

          <input
            type="file"
            accept="image/*"
            ref={fileInputFotoRef}
            style={{ display: "none" }}
            onChange={handleFotoChange}
          />
        </>
      )}

      {/* INFO */}
      <div className="usuario-data">
        <h2 className="usuario-nome">
          {usuario?.nome || "Usuário"}
        </h2>

        {usuario?.email && (
          <div className="usuario-info-linha">
            <span className="material-symbols-outlined usuario-icone">mail</span>
            <span className="usuario-info-texto">{usuario.email}</span>
          </div>
        )}

        {localizacao && (
          <div className="usuario-info-linha">
            <span className="material-symbols-outlined usuario-icone">
              location_on
            </span>
            <span className="usuario-info-texto">{localizacao}</span>
          </div>
        )}

        {bio && <p className="usuario-bio">{bio}</p>}
      </div>

      {/* BOTÕES MOBILE */}
      <div className="cabecalho-botoes-mobile">
        {isOwnProfile ? (
          <>
            <button
              className="btn-cabecalho btn-editar"
              onClick={() => navigate("/perfil/editar")}
            >
              Editar Perfil
            </button>

            <button
              className="btn-cabecalho btn-publicar"
              onClick={() => navigate("/publicar")}
            >
              Nova Publicação
            </button>
          </>
        ) : (
          <>
            {!isFollowing ? (
              <button className="btn-cabecalho" onClick={onSeguir}>
                Seguir
              </button>
            ) : (
              <>
                <button className="btn-cabecalho" onClick={onDeixarDeSeguir}>
                  Deixar de seguir
                </button>
                <button className="btn-cabecalho" onClick={onMensagem}>
                  Mensagem
                </button>
              </>
            )}
          </>
        )}
      </div>
    </div>
  );
}