import React, { useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import './Cabecalhoperfil.css';
import './Profilemenu.css';
import ProfileMenu from './Profilemenu';

export default function CabecalhoPerfil({
  fotoPerfil,
  onFotoChange,
  onBannerChange,
  banner,
  usuario,
  bio,
  localizacao,
  isOwnProfile,
  isFollowing,
  chatLiberado,
  onSeguir,
  onDeixarDeSeguir,
  onMensagem,
}) {
  const navigate = useNavigate();
  const fileInputFotoRef = useRef(null);
  const fileInputBannerRef = useRef(null);

  const [menuAberto, setMenuAberto] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(() => {
    return localStorage.getItem('theme') === 'dark';
  });
  const [mostrarLogout, setMostrarLogout] = useState(false);

  const toggleDark = () => {
    setIsDarkMode(prev => {
      const next = !prev;
      if (next) {
        document.body.classList.add('dark-mode');
        localStorage.setItem('theme', 'dark');
      } else {
        document.body.classList.remove('dark-mode');
        localStorage.setItem('theme', 'light');
      }
      return next;
    });
  };

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
    if (typeof onFotoChange === 'function') onFotoChange(file);
  };

  const handleBannerChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (typeof onBannerChange === 'function') onBannerChange(file);
  };

  const renderizarBotoes = () => {
    if (isOwnProfile) {
      return (
        <>
          <button className="btn-cabecalho btn-editar" onClick={() => navigate('/perfil/editar')}>
            <span className="material-symbols-outlined">edit</span>
            <span className="btn-texto">Editar Perfil</span>
          </button>
          <button className="btn-cabecalho btn-publicar" onClick={() => navigate('/publicar')}>
            <span className="material-symbols-outlined">add</span>
            <span className="btn-texto">Nova Publicação</span>
          </button>
        </>
      );
    }

    if (isFollowing) {
      return (
        <>
          <button className="btn-cabecalho btn-deixar-seguir" onClick={onDeixarDeSeguir}>
            <span className="material-symbols-outlined">person_remove</span>
            <span className="btn-texto">Seguindo</span>
          </button>
          {chatLiberado && (
            <button className="btn-cabecalho btn-mensagem" onClick={onMensagem}>
              <span className="material-symbols-outlined">chat</span>
              <span className="btn-texto">Mensagem</span>
            </button>
          )}
        </>
      );
    }

    return (
      <button className="btn-cabecalho btn-seguir" onClick={onSeguir}>
        <span className="material-symbols-outlined">person_add</span>
        <span className="btn-texto">Seguir</span>
      </button>
    );
  };

  return (
    <div className="cabecalho-perfil">
      {/* BANNER */}
      <div
        className="banner-perfil"
        onClick={handleBannerClick}
        title={isOwnProfile ? 'Clique para trocar a capa' : ''}
        style={{ backgroundImage: banner ? `url(${banner})` : undefined }}
      >
        {!banner && isOwnProfile && (
          <span className="banner-icone material-symbols-outlined">add_photo_alternate</span>
        )}
        {isOwnProfile && (
          <div className="banner-overlay">
            <span className="material-symbols-outlined">photo_camera</span>
            <p>Trocar capa</p>
          </div>
        )}
        {isOwnProfile && (
          <button
            className="pmenu-trigger"
            onClick={(e) => { e.stopPropagation(); setMenuAberto(true); }}
            aria-label="Abrir menu de opções"
          >
            <span className="material-symbols-outlined">more_horiz</span>
          </button>
        )}
      </div>

      {/* LINHA INFERIOR */}
      <div className="cabecalho-inferior">
        <div className="foto-perfil-wrapper">
          <img
            src={fotoPerfil || null}
            alt="Foto de Perfil"
            className="foto-perfil"
            onClick={handleFotoClick}
            title={isOwnProfile ? 'Clique para trocar a foto' : ''}
          />
          {isOwnProfile && (
            <div className="foto-perfil-overlay" onClick={handleFotoClick}>
              <span className="material-symbols-outlined">photo_camera</span>
            </div>
          )}
        </div>

        {/* Botões desktop */}
        <div className="cabecalho-botoes">
          {renderizarBotoes()}
        </div>
      </div>

      {/* Inputs ocultos */}
      {isOwnProfile && (
        <>
          <input type="file" accept="image/*" ref={fileInputBannerRef} style={{ display: 'none' }} onChange={handleBannerChange} />
          <input type="file" accept="image/*" ref={fileInputFotoRef} style={{ display: 'none' }} onChange={handleFotoChange} />
        </>
      )}

      {/* INFO USUÁRIO – NOME + USERNAME */}
      <div className="usuario-data">
        <h2 className="usuario-nome">
          {usuario?.nome || 'Usuário'}
          {usuario?.username && (
            <span className="usuario-username"> @{usuario.username}</span>
          )}
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
        {bio && <p className="usuario-bio">{bio}</p>}
      </div>

      {/* Botões mobile */}
      <div className="cabecalho-botoes-mobile">
        {renderizarBotoes()}
      </div>

      {/* Menu */}
      <ProfileMenu
        isOpen={menuAberto}
        onClose={() => setMenuAberto(false)}
        isDarkMode={isDarkMode}
        onToggleDark={toggleDark}
        mostrarConfirmacao={mostrarLogout}
        onAbrirLogout={() => setMostrarLogout(true)}
        onCancelarLogout={() => setMostrarLogout(false)}
      />
    </div>
  );
}