import React, { useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../../components/sidebar/layout";
import "./Editarperfil.css";

export default function EditarPerfil() {
  const navigate = useNavigate();

  const [nome, setNome] = useState(
    localStorage.getItem("nome") || ""
  );
  const [bio, setBio] = useState(
    localStorage.getItem("bio") || ""
  );
  const [localizacao, setLocalizacao] = useState(
    localStorage.getItem("localizacao") || ""
  );
  const [fotoPerfil, setFotoPerfil] = useState(
    localStorage.getItem("fotoPerfil") || ""
  );
  const [banner, setBanner] = useState(
    localStorage.getItem("banner") || ""
  );

  const [salvando, setSalvando] = useState(false);
  const [salvo, setSalvo] = useState(false);

  const fotoInputRef = useRef(null);
  const bannerInputRef = useRef(null);

  const handleFotoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => setFotoPerfil(reader.result);
    reader.readAsDataURL(file);
  };

  const handleBannerChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => setBanner(reader.result);
    reader.readAsDataURL(file);
  };

  const handleSalvar = () => {
    if (!nome.trim()) {
      alert("O nome não pode ficar vazio.");
      return;
    }

    setSalvando(true);

    // Simula um pequeno delay para o usuário perceber que salvou
    setTimeout(() => {
      localStorage.setItem("nome", nome);
      localStorage.setItem("bio", bio);
      localStorage.setItem("localizacao", localizacao);
      if (fotoPerfil) localStorage.setItem("fotoPerfil", fotoPerfil);
      if (banner) localStorage.setItem("banner", banner);

      setSalvando(false);
      setSalvo(true);

      setTimeout(() => {
        navigate("/perfil");
      }, 1000);
    }, 800);
  };

  return (
    <Layout>
      <div className="editar-perfil-container">

        {/* CABEÇALHO DA TELA */}
        <div className="editar-perfil-header">
          <button className="btn-voltar" onClick={() => navigate("/perfil")}>
            <span className="material-symbols-outlined">arrow_back</span>
            Voltar
          </button>
          <h1 className="editar-perfil-titulo">Editar Perfil</h1>
        </div>

        <div className="editar-perfil-card">

          {/* SEÇÃO — FOTO DE CAPA */}
          <div className="editar-secao">
            <label className="editar-label">Foto de Capa</label>
            <div
              className="editar-banner-preview"
              onClick={() => bannerInputRef.current.click()}
              style={{
                backgroundImage: banner ? `url(${banner})` : undefined,
              }}
            >
              {!banner && (
                <div className="editar-banner-vazio">
                  <span className="material-symbols-outlined">add_photo_alternate</span>
                  <p>Clique para adicionar uma capa</p>
                </div>
              )}
              <div className="editar-banner-overlay">
                <span className="material-symbols-outlined">photo_camera</span>
                <p>Trocar capa</p>
              </div>
            </div>
            <input
              type="file"
              accept="image/*"
              ref={bannerInputRef}
              style={{ display: "none" }}
              onChange={handleBannerChange}
            />
          </div>

          {/* SEÇÃO — FOTO DE PERFIL */}
          <div className="editar-secao editar-secao-foto">
            <label className="editar-label">Foto de Perfil</label>
            <div className="editar-foto-wrapper" onClick={() => fotoInputRef.current.click()}>
              {fotoPerfil ? (
                <img src={fotoPerfil} alt="Foto de perfil" className="editar-foto-preview" />
              ) : (
                <div className="editar-foto-vazio">
                  <span className="material-symbols-outlined">person</span>
                </div>
              )}
              <div className="editar-foto-overlay">
                <span className="material-symbols-outlined">photo_camera</span>
              </div>
            </div>
            <input
              type="file"
              accept="image/*"
              ref={fotoInputRef}
              style={{ display: "none" }}
              onChange={handleFotoChange}
            />
            <p className="editar-dica">Clique na foto para trocar</p>
          </div>

          {/* SEÇÃO — NOME */}
          <div className="editar-secao">
            <label className="editar-label" htmlFor="campo-nome">
              Nome completo <span className="editar-obrigatorio">*</span>
            </label>
            <input
              id="campo-nome"
              type="text"
              className="editar-input"
              placeholder="Seu nome completo"
              value={nome}
              onChange={(e) => setNome(e.target.value)}
              maxLength={60}
            />
            <p className="editar-contador">{nome.length}/60</p>
          </div>

          {/* SEÇÃO — LOCALIZAÇÃO */}
          <div className="editar-secao">
            <label className="editar-label" htmlFor="campo-localizacao">
              Localização
            </label>
            <div className="editar-input-icone">
              <span className="material-symbols-outlined editar-input-icone-symbol">location_on</span>
              <input
                id="campo-localizacao"
                type="text"
                className="editar-input editar-input-com-icone"
                placeholder="Ex: Matão, SP"
                value={localizacao}
                onChange={(e) => setLocalizacao(e.target.value)}
                maxLength={60}
              />
            </div>
          </div>

          {/* SEÇÃO — BIO */}
          <div className="editar-secao">
            <label className="editar-label" htmlFor="campo-bio">
              Bio
            </label>
            <textarea
              id="campo-bio"
              className="editar-textarea"
              placeholder="Conte um pouco sobre você e sua paixão pela pesca..."
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              maxLength={150}
              rows={4}
            />
            <p className="editar-contador">{bio.length}/150</p>
          </div>

          {/* BOTÃO SALVAR */}
          <button
            className={`btn-salvar ${salvando ? "btn-salvando" : ""} ${salvo ? "btn-salvo" : ""}`}
            onClick={handleSalvar}
            disabled={salvando || salvo}
          >
            {salvo ? (
              <>
                <span className="material-symbols-outlined">check_circle</span>
                Salvo com sucesso!
              </>
            ) : salvando ? (
              <>
                <span className="material-symbols-outlined">hourglass_top</span>
                Salvando...
              </>
            ) : (
              <>
                <span className="material-symbols-outlined">save</span>
                Salvar Alterações
              </>
            )}
          </button>

        </div>
      </div>
    </Layout>
  );
}